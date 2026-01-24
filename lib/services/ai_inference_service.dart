import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'bert_tokenizer.dart';
import 'package:image/image.dart' as img;
import 'model_manager_service.dart';

class AiInferenceService {
  static final AiInferenceService _instance = AiInferenceService._internal();
  factory AiInferenceService() => _instance;
  AiInferenceService._internal();

  Interpreter? _emotionInterpreter;
  Interpreter? _faceInterpreter;
  Interpreter? _minilmInterpreter;
  BertTokenizer? _tokenizer;

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
        print('XNNPACK delegate not available: $e');
      }

      int completed = 0;
      const totalSteps = 4;
      void markDone() {
        completed += 1;
        onProgress?.call(completed / totalSteps);
      }

      final emotionFuture = Interpreter.fromAsset(
        'assets/ai_models/emotion_text.tflite',
        options: options,
      ).then((value) {
        _emotionInterpreter = value;
        print('Emotion model loaded.');
        markDone();
      });

      final faceFuture = Interpreter.fromAsset(
        'assets/ai_models/face_emotion.tflite',
        options: options,
      ).then((value) {
        _faceInterpreter = value;
        print('Face model loaded.');
        markDone();
      });

      final minilmFuture = Interpreter.fromAsset(
        'assets/ai_models/minilm.tflite',
        options: options,
      ).then((value) {
        _minilmInterpreter = value;
        print('MiniLM model loaded.');
        markDone();
      });

      final tokenizerFuture =
          BertTokenizer.fromAsset('assets/ai_models/vocab.txt').then((value) {
        _tokenizer = value;
        print('Tokenizer loaded.');
        markDone();
      });

      await Future.wait([
        emotionFuture,
        faceFuture,
        minilmFuture,
        tokenizerFuture,
      ]);

      _isInitialized = true;
    } catch (e) {
      print('Error initializing AI models: $e');
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
    if (!await ModelManagerService().isGemmaModelReady()) {
      return "Model chưa sẵn sàng.";
    }

    try {
      final modelPath = await ModelManagerService().getModelPath();
      final modelFile = File('$modelPath/chatbot_gemma.bin');
      final interpreter = Interpreter.fromFile(modelFile);

      interpreter.close();

      return "Xin chào! Mình là Gemma (đang thử nghiệm). Mình nhận được: \"$prompt\"";
    } catch (e) {
      print('Gemma Inference Error: $e');
      return "Lỗi khi chạy Gemma: $e";
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

        if (sim > maxSim) {
          maxSim = sim;
          bestIntent = intent;
        }
      }

      // Threshold for intent (e.g. 0.6)
      if (maxSim > 0.6) {
        return bestIntent;
      }
      return null;
    } catch (e) {
      print('Intent determination error: $e');
      return null;
    }
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
