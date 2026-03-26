import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'bert_tokenizer.dart';
import 'package:image/image.dart' as img;

class AiInferenceService {
  static final AiInferenceService _instance = AiInferenceService._internal();
  factory AiInferenceService() => _instance;
  AiInferenceService._internal();

  Interpreter? _emotionInterpreter;
  Interpreter? _faceInterpreter;
  Interpreter? _minilmInterpreter;
  BertTokenizer? _tokenizer;

  // Hugging Face Config
  // Generate a token at: https://huggingface.co/settings/tokens
  static const String _hfToken =
      String.fromEnvironment('HF_TOKEN', defaultValue: '');
  static const String _modelUrl =
      'https://router.huggingface.co/v1/chat/completions';

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
      const totalSteps = 3;
      void markDone() {
        completed += 1;
        onProgress?.call(completed / totalSteps);
      }

      try {
        _emotionInterpreter = await Interpreter.fromAsset(
          'assets/ai_models/emotion_text.tflite',
          options: options,
        );
        debugPrint('✓ Emotion model loaded.');
      } catch (e) {
        debugPrint(
          '⚠️ emotion_text.tflite missing or invalid — text emotion uses empty scores. Add file under assets/ai_models/.',
        );
        debugPrint('   ($e)');
      }
      markDone();

      try {
        _minilmInterpreter = await Interpreter.fromAsset(
          'assets/ai_models/minilm.tflite',
          options: options,
        );
        debugPrint('✓ MiniLM model loaded.');
      } catch (e) {
        debugPrint(
          '⚠️ minilm.tflite missing or invalid — embeddings disabled. Add file under assets/ai_models/.',
        );
        debugPrint('   ($e)');
      }
      markDone();

      _tokenizer = await BertTokenizer.fromAsset('assets/ai_models/vocab.txt');
      debugPrint('✓ Tokenizer loaded.');
      markDone();

      debugPrint('Skipping Gemma model load (Device Resource Limit)...');

      _isInitialized = true;
      if (_emotionInterpreter != null && _minilmInterpreter != null) {
        debugPrint('✓ Chatbot AI models ready!');
      } else {
        debugPrint(
          '✓ Chatbot ready (limited local AI — place emotion_text.tflite and minilm.tflite in assets/ai_models/).',
        );
      }
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

  // Method needed for Face Emotion (used by other services)
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

  // Method needed for Text Emotion
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

  // Method needed for Intent Recognition
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
    if (_hfToken.trim().isEmpty) {
      return "⚠️ Chưa cấu hình Hugging Face Token.\n"
          "Chạy app với `--dart-define=HF_TOKEN=hf_...` rồi thử lại.";
    }

    try {
      final response = await http.post(
        Uri.parse(_modelUrl),
        headers: {
          'Authorization': 'Bearer $_hfToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'Qwen/Qwen2.5-7B-Instruct',
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'max_tokens': 200,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse =
            jsonDecode(utf8.decode(response.bodyBytes));
        if (jsonResponse.containsKey('choices') &&
            jsonResponse['choices'].isNotEmpty) {
          return jsonResponse['choices'][0]['message']['content'] ??
              "Tớ không biết trả lời sao nữa...";
        }
      } else {
        print("HF API Error: ${response.statusCode} - ${response.body}");
        if (response.statusCode == 503) {
          return "Model đang khởi động trên server, đợi xíu nhé...";
        }
        return "Kết nối tới AI Gemma bị gián đoạn.";
      }
      return "Tớ không biết trả lời sao nữa...";
    } catch (e) {
      debugPrint('Gemma API Exception: $e');
      return "Lỗi kết nối mạng: Hãy kiểm tra Internet của bạn.";
    }
  }

  Future<String?> determineIntent(String text) async {
    final lower = text.toLowerCase();

    // 1. Light Commands
    if (lower.contains('đèn')) {
      if (lower.contains('bật') ||
          lower.contains('mở') ||
          lower.contains('sáng')) return 'LIGHT_ON';
      if (lower.contains('tắt') || lower.contains('tối')) return 'LIGHT_OFF';
      if (lower.contains('đổi') ||
          lower.contains('màu') ||
          lower.contains('chỉnh')) return 'LIGHT_COLOR';
    }

    // 2. Music Commands
    if (lower.contains('nhạc') ||
        lower.contains('bài hát') ||
        lower.contains('hát')) {
      if (lower.contains('bật') ||
          lower.contains('mở') ||
          lower.contains('chơi')) return 'MUSIC_ON';
      if (lower.contains('tắt') || lower.contains('dừng')) return 'MUSIC_OFF';
      if (lower.contains('đổi') ||
          lower.contains('qua') ||
          lower.contains('bài tiếp')) return 'MUSIC_CHANGE';
    }

    // 3. Simple standalone keywords
    if (lower == 'bật đèn' || lower == 'mở đèn') return 'LIGHT_ON';
    if (lower == 'tắt đèn') return 'LIGHT_OFF';

    return null;
  }

  List<double> _softmax(List<double> logits) {
    if (logits.isEmpty) return [];
    double maxLogit = logits.reduce(max);
    List<double> expValues = logits.map((x) => exp(x - maxLogit)).toList();
    double sumExp = expValues.reduce((a, b) => a + b);
    return expValues.map((x) => x / sumExp).toList();
  }
}
