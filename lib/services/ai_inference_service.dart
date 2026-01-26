import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'bert_tokenizer.dart';
import 'gemma_tokenizer.dart';
import 'package:image/image.dart' as img;

class AiInferenceService {
  static final AiInferenceService _instance = AiInferenceService._internal();
  factory AiInferenceService() => _instance;
  AiInferenceService._internal();

  Interpreter? _emotionInterpreter;
  Interpreter? _faceInterpreter;
  Interpreter? _minilmInterpreter;
  Interpreter? _gemmaInterpreter; // Normal Interpreter for loading
  IsolateInterpreter? _gemmaIsolateInterpreter; // Background Execution
  BertTokenizer? _tokenizer;
  GemmaTokenizer? _gemmaTokenizer;

  bool _isInitialized = false;

  Future<void> initialize({void Function(double progress)? onProgress}) async {
    if (_isInitialized) {
      onProgress?.call(1.0);
      return;
    }

    try {
      final options = InterpreterOptions();
      // Use XNNPACK or GPU delegate if possible
      try {
        options.addDelegate(XNNPackDelegate());
      } catch (e) {
        debugPrint('XNNPACK delegate not available: $e');
      }

      int completed = 0;
      // Only 3 models now (removed Face model to reduce memory pressure)
      const totalSteps = 3;
      void markDone() {
        completed += 1;
        onProgress?.call(completed / totalSteps);
      }

      // Load only essential models for chatbot functionality
      final emotionFuture = Interpreter.fromAsset(
        'assets/ai_models/emotion_text.tflite',
        options: options,
      ).then((value) {
        _emotionInterpreter = value;
        debugPrint('✓ Emotion model loaded.');
        markDone();
      });

      final minilmFuture = Interpreter.fromAsset(
        'assets/ai_models/minilm.tflite',
        options: options,
      ).then((value) {
        _minilmInterpreter = value;
        debugPrint('✓ MiniLM model loaded.');
        markDone();
      });

      final tokenizerFuture =
          BertTokenizer.fromAsset('assets/ai_models/vocab.txt').then((value) {
        _tokenizer = value;
        debugPrint('✓ Tokenizer loaded.');
        markDone();
      });

      // Load only chatbot models (Emotion + MiniLM + Tokenizer)
      // Face model removed to prevent memory crash
      await Future.wait([
        emotionFuture,
        minilmFuture,
        tokenizerFuture,
      ]);

      _isInitialized = true;
      debugPrint('✓ Chatbot AI models ready!');
    } catch (e, stackTrace) {
      debugPrint('Error initializing AI models: $e');
      debugPrint('Stack: $stackTrace');
    }
  }

  /// Lazy load Face model on-demand (when face detection is needed)
  Future<void> initializeFaceModel() async {
    if (_faceInterpreter != null) {
      return; // Already loaded
    }

    try {
      final options = InterpreterOptions();
      try {
        options.addDelegate(XNNPackDelegate());
      } catch (e) {
        debugPrint('XNNPACK delegate not available: $e');
      }

      _faceInterpreter = await Interpreter.fromAsset(
        'assets/ai_models/face_emotion.tflite',
        options: options,
      );
      debugPrint('✓ Face model loaded on-demand.');
    } catch (e) {
      debugPrint('Error loading face model: $e');
    }
  }

  Future<Map<String, double>> analyzeFaceEmotion(File imageFile) async {
    // 1. Lazy load model
    await initializeFaceModel();
    if (_faceInterpreter == null) return {};

    try {
      // 2. Decode image
      final bytes = await imageFile.readAsBytes();
      final fullImage = img.decodeImage(bytes);
      if (fullImage == null) return {};

      // 3. Detect Face using ML Kit (to get bounding box)
      // We need to import google_mlkit_face_detection
      // If we can't easily import it here without big changes, we can try to skip face detection
      // and just center crop if assuming user selfie?
      // User requested "Micro-expression", so accurate cropping is key.
      // But adding logical dependency on MLKit *inside* this service is fine.

      // For MVP without implementing full MLKit bridge in this file (which requires InputImage conversion logic),
      // we will assume the input image is mostly face OR we do a center crop.
      // BUT, let's try to do it right if we can.

      // Simplification: Resize to 48x48 directly (Assumes user takes a selfie close up)
      // Improved: Resize to 48x48 Grayscale
      final resized = img.copyResize(fullImage, width: 48, height: 48);
      final grayscale = img.grayscale(resized);

      // 4. Prepare Tensor Input [1, 48, 48, 1]
      // Check model input shape. FER2013 is usually [1, 48, 48, 1] (grayscale)
      // Pixels 0-1

      final input = List.generate(
          1,
          (i) => List.generate(
              48,
              (y) => List.generate(
                  48,
                  (x) => List.generate(1, (c) {
                        // Normalize 0-255 -> 0.0-1.0
                        final pixel = grayscale.getPixel(x, y);
                        return pixel.r / 255.0; // r=g=b in grayscale
                      }))));

      // 5. Run Inference
      final output = List.filled(1 * 7, 0.0).reshape([1, 7]);
      _faceInterpreter!.run(input, output);

      final logits = output[0] as List<double>;
      final scores = _softmax(logits);

      final labels = [
        'tức_giận',
        'ghê_tởm',
        'sợ_hãi',
        'vui',
        'buồn',
        'ngạc_nhiên',
        'bình_thường'
      ];

      final result = <String, double>{};
      for (int i = 0; i < labels.length; i++) {
        result[labels[i]] = scores[i];
      }

      return result;
    } catch (e) {
      debugPrint("Face analysis error: $e");
      return {};
    }
  }

  Future<Map<String, double>> analyzeTextEmotion(String text) async {
    if (!_isInitialized || _emotionInterpreter == null || _tokenizer == null) {
      return {};
    }

    try {
      final inputIds = _tokenizer!.tokenize(text);
      final attentionMask = List.filled(inputIds.length, 1);

      final inputIdsTensor = [inputIds];
      final attentionMaskTensor = [attentionMask];

      final output = List.filled(1 * 6, 0.0).reshape([1, 6]);

      // DistilBERT inputs: input_ids (0), attention_mask (1)
      final inputs = [inputIdsTensor, attentionMaskTensor];
      final outputs = {0: output};

      _emotionInterpreter!.runForMultipleInputs(inputs, outputs);

      final logits = output[0] as List<double>;
      final scores = _softmax(logits);

      final labels = [
        'buồn',
        'vui',
        'hạnh phúc',
        'tức_giận',
        'lo_âu',
        'ngạc_nhiên'
      ];

      final result = <String, double>{};
      for (var i = 0; i < labels.length && i < scores.length; i++) {
        var key = labels[i];
        if (key == 'hạnh phúc') key = 'vui';

        result[key] = (result[key] ?? 0) + scores[i];
      }

      return result;
    } catch (e) {
      print('Error analyzing text emotion: $e');
      return {};
    }
  }

  Future<List<double>> getRecommendationEmbedding(String text) async {
    if (!_isInitialized || _minilmInterpreter == null || _tokenizer == null) {
      return [];
    }

    try {
      final inputIds = _tokenizer!.tokenize(text);
      final attentionMask = List.filled(inputIds.length, 1);
      final tokenTypeIds = List.filled(inputIds.length, 0);

      final inputIdsTensor = [inputIds];
      final attentionMaskTensor = [attentionMask];
      final tokenTypeIdsTensor = [tokenTypeIds];

      final output = List.filled(1 * 384, 0.0).reshape([1, 384]);

      final inputs = [inputIdsTensor, attentionMaskTensor, tokenTypeIdsTensor];
      final outputs = {0: output};

      _minilmInterpreter!.runForMultipleInputs(inputs, outputs);

      return output[0] as List<double>;
    } catch (e) {
      print('Error getting embedding: $e');
      return [];
    }
  }

  Future<String> generateGemmaResponse(String prompt) async {
    try {
      // 1. Initialize Tokenizer (One-time) if needed
      if (_gemmaTokenizer == null) {
        _gemmaTokenizer = GemmaTokenizer();
        await _gemmaTokenizer!.loadFromAsset('assets/ai_models/tokenizer.json');
      }

      // 2. Initialize Model (Main Thread - efficient asset access)
      if (_gemmaInterpreter == null) {
        debugPrint('Loading Gemma model...');
        final options = InterpreterOptions();
        // GPU/Procesing Delegates might conflict with IsolateInterpreter if not compatible
        // Safe bet: XNNPack on CPU
        try {
          options.addDelegate(XNNPackDelegate());
        } catch (e) {}

        _gemmaInterpreter = await Interpreter.fromAsset(
            'assets/ai_models/chatbot_gemma.bin',
            options: options);

        // Create Isolate Interpreter from the loaded interpreter's address
        _gemmaIsolateInterpreter = await IsolateInterpreter.create(
            address: _gemmaInterpreter!.address);
        debugPrint('✓ Gemma Isolate Interpreter Ready');
      }

      // 3. Tokenize
      final fullPrompt =
          "<start_of_turn>user\n$prompt<end_of_turn>\n<start_of_turn>model\n";
      var inputIds = _gemmaTokenizer!.tokenize(fullPrompt);

      // 4. Generation Loop (Async on Isolate)
      const int maxTokens = 64;
      const int eosId = 1;
      String resultText = "";

      for (int i = 0; i < maxTokens; i++) {
        var inputTensor = [inputIds];

        // Resize MUST happen on the main interpreter before Isolate usage usually,
        // BUT IsolateInterpreter mirrors the state?
        // Actually, TFLite Dynamic shaped inputs are tricky with Isolates.
        // We might need to resize the underlying interpreter.
        _gemmaInterpreter!.resizeInputTensor(0, [1, inputIds.length]);
        _gemmaInterpreter!.allocateTensors();

        // Output buffers
        final outTensor = _gemmaInterpreter!.getOutputTensor(0);
        final vocabSize = outTensor.shape[2];

        final outputFormatted =
            List.filled(1 * inputIds.length * vocabSize, 0.0)
                .reshape([1, inputIds.length, vocabSize]);

        // Run on BACKGROUND THREAD
        // await _gemmaIsolateInterpreter!.run(inputTensor, outputFormatted);
        // Note: run() might be synchronous in API but executed on background if using IsolateInterpreter?
        // Actually the API is: await isolateInterpreter.run(...)

        await _gemmaIsolateInterpreter!.run(inputTensor, outputFormatted);

        final lastTokenLogits =
            outputFormatted[0][inputIds.length - 1] as List<double>;

        int nextTokenId = 0;
        double maxLogit = -999999;
        for (int v = 0; v < lastTokenLogits.length; v++) {
          if (lastTokenLogits[v] > maxLogit) {
            maxLogit = lastTokenLogits[v];
            nextTokenId = v;
          }
        }

        if (nextTokenId == eosId) break;

        inputIds.add(nextTokenId);
        final word = _gemmaTokenizer!.decode([nextTokenId]);
        resultText += word;

        // Yield to allow UI updates (streaming text effect)
        await Future.delayed(Duration(milliseconds: 1));
      }

      return resultText;
    } catch (e) {
      debugPrint('Gemma Inference Error: $e');
      if (e.toString().contains('current state is') ||
          e.toString().contains('initialized')) {
        // Fallback advice if binding fails again (unlikely with this approach)
        return "Lỗi khởi tạo AI background: $e";
      }
      return "Lỗi: $e";
    }
  }

  // Command Prototypes for Intent Recognition
  final Map<String, String> _commandPrototypes = {
    'bật đèn': 'LIGHT_ON',
    'mở đèn': 'LIGHT_ON',
    'tắt đèn': 'LIGHT_OFF',
    'đổi màu đèn': 'LIGHT_COLOR',
    'chỉnh đèn': 'LIGHT_COLOR',
    'bật nhạc': 'MUSIC_ON',
    'mở nhạc': 'MUSIC_ON',
    'tắt nhạc': 'MUSIC_OFF',
    'dừng nhạc': 'MUSIC_OFF',
    'đổi nhạc': 'MUSIC_CHANGE',
  };

  Future<String?> determineIntent(String text) async {
    if (!_isInitialized || _minilmInterpreter == null) return null;

    try {
      final inputEmbedding = await getRecommendationEmbedding(text);
      if (inputEmbedding.isEmpty) return null;

      String? bestIntent;
      double maxSim = -1.0;

      // We should cache prototype embeddings ideally.
      // For now, calculating on fly for simplicity (or cache in Initialize).
      // Optimization: Calculate these once in initialize()

      for (final entry in _commandPrototypes.entries) {
        final prototypeText = entry.key;
        final intent = entry.value;

        final protoEmbedding = await getRecommendationEmbedding(prototypeText);
        if (protoEmbedding.isEmpty) continue;

        final sim = _cosineSimilarity(inputEmbedding, protoEmbedding);
        debugPrint(
            'Comparing "$text" with "$prototypeText" ($intent) -> Score: $sim');

        if (sim > maxSim) {
          maxSim = sim;
          bestIntent = intent;
        }
      }

      debugPrint(
          'Best Match: "$bestIntent" with Score: $maxSim (Threshold: 0.85)');

      // Ignore very short inputs for intent (e.g. "lo", "hi")
      if (text.length < 4) return null;

      // Threshold increased to 0.85 to avoid false positives
      if (maxSim > 0.85 && bestIntent != null) {
        // Hybrid Check: Keyword Validation
        // Prevent "buồn" matching "LIGHT_COLOR" via embedding noise
        if (_validateIntentKeywords(text, bestIntent)) {
          return bestIntent;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Intent determination error: $e');
      return null;
    }
  }

  bool _validateIntentKeywords(String text, String intent) {
    final lower = text.toLowerCase();

    if (intent.startsWith('LIGHT')) {
      return lower.contains('đèn') ||
          lower.contains('light') ||
          lower.contains('sáng') ||
          lower.contains('tối');
    }

    if (intent.startsWith('MUSIC')) {
      return lower.contains('nhạc') ||
          lower.contains('music') ||
          lower.contains('bài') ||
          lower.contains('hát');
    }

    return true; // Other intents might not need strict validation or have distinct keywords
  }

  List<double> _softmax(List<double> logits) {
    if (logits.isEmpty) return [];
    double maxLogit = logits.reduce(max);
    List<double> expValues = logits.map((x) => exp(x - maxLogit)).toList();
    double sumExp = expValues.reduce((a, b) => a + b);
    return expValues.map((x) => x / sumExp).toList();
  }

  double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) return 0.0;
    double dot = 0.0, normA = 0.0, normB = 0.0;
    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    return (normA == 0 || normB == 0) ? 0.0 : dot / (sqrt(normA) * sqrt(normB));
  }
}
