import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/mood_type.dart';

class GeminiService {
  // API Key for Gemini
  // Note: In production, this should be stored securely (e.g., environment variables)
  static const String _apiKey = 'AIzaSyD1lq4IJogT-uUU40HveoC_aIKL1qkQ5JY';
  static GenerativeModel? _model;
  
  // Verify API key format
  static bool _isValidApiKey() {
    return _apiKey.isNotEmpty && _apiKey.length > 20;
  }

  static GenerativeModel get _getModel {
    if (!_isValidApiKey()) {
      throw Exception('Invalid API key format');
    }
    
    _model ??= GenerativeModel(
      model: 'gemini-1.5-flash', // Updated to use latest model
      apiKey: _apiKey,
    );
    return _model!;
  }

  // Get greeting message from Gemini
  static Future<String> getGreetingMessage() async {
    try {
      print('🔵 Gemini: Getting greeting message...');
      final model = _getModel;
      final prompt = '''
Bạn là một chatbot tâm lý thân thiện và đồng cảm. 
Hãy chào hỏi người dùng một cách ấm áp và hỏi về cảm xúc của họ hôm nay.
Hãy hỏi họ đang cảm thấy thế nào: mệt mỏi, buồn, căng thẳng, hay bình thường?
Trả lời ngắn gọn, thân thiện, bằng tiếng Việt.
''';

      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text;
      
      if (text != null && text.isNotEmpty) {
        print('✅ Gemini: Greeting received successfully');
        return text;
      } else {
        print('⚠️ Gemini: Empty response, using fallback');
        return 'Xin chào! Hôm nay bạn cảm thấy thế nào? Bạn đang mệt, buồn hay căng thẳng?';
      }
    } catch (e, stackTrace) {
      print('❌ Error getting greeting from Gemini: $e');
      print('Stack trace: $stackTrace');
      
      // Check for specific error types
      if (e.toString().contains('API_KEY_INVALID') || 
          e.toString().contains('API key')) {
        print('⚠️ API Key issue detected');
      }
      if (e.toString().contains('quota') || e.toString().contains('limit')) {
        print('⚠️ API quota/limit issue detected');
      }
      
      return 'Xin chào! Hôm nay bạn cảm thấy thế nào? Bạn đang mệt, buồn hay căng thẳng?';
    }
  }

  // Analyze user message and get response from Gemini
  static Future<String> getResponse(String userMessage, {List<String>? conversationHistory}) async {
    try {
      print('🔵 Gemini: Getting response for: "$userMessage"');
      final model = _getModel;
      
      // Build conversation context
      final systemPrompt = '''
Bạn là một chatbot tâm lý thân thiện và đồng cảm trong ứng dụng Smart Candles - một ứng dụng giúp người dùng thư giãn và cải thiện tâm trạng.

Nhiệm vụ của bạn:
1. Lắng nghe và đồng cảm với cảm xúc của người dùng
2. Phân tích tâm trạng của họ (căng thẳng, buồn, mệt mỏi, khó ngủ, hoặc bình thường)
3. Đưa ra lời khuyên và gợi ý phù hợp
4. Gợi ý sử dụng các tính năng của app như:
   - Tinh dầu thư giãn (Lavender, Sweet Orange, Chamomile, Peppermint)
   - Nhạc thiền, nhạc piano, âm thanh thiên nhiên
   - Điều chỉnh ánh sáng nến thông minh

Hãy trả lời ngắn gọn, thân thiện, đồng cảm, bằng tiếng Việt.
Nếu người dùng nói về cảm xúc tiêu cực, hãy an ủi và đưa ra giải pháp cụ thể.
''';

      // Build conversation history
      final contents = <Content>[
        Content.text(systemPrompt),
      ];

      // Add conversation history if available
      if (conversationHistory != null && conversationHistory.isNotEmpty) {
        print('📝 Gemini: Using conversation history (${conversationHistory.length} messages)');
        for (int i = 0; i < conversationHistory.length; i += 2) {
          if (i + 1 < conversationHistory.length) {
            contents.add(Content.text(conversationHistory[i])); // User message
            contents.add(Content.text(conversationHistory[i + 1])); // Bot response
          }
        }
      }

      // Add current user message
      contents.add(Content.text(userMessage));

      print('📤 Gemini: Sending request with ${contents.length} content items');
      final response = await model.generateContent(contents);
      final text = response.text;
      
      if (text != null && text.isNotEmpty) {
        print('✅ Gemini: Response received: ${text.substring(0, text.length > 50 ? 50 : text.length)}...');
        return text;
      } else {
        print('⚠️ Gemini: Empty response');
        return 'Xin lỗi, mình không hiểu. Bạn có thể nói rõ hơn không?';
      }
    } catch (e, stackTrace) {
      print('❌ Error getting response from Gemini: $e');
      print('Stack trace: $stackTrace');
      
      // Check for specific error types
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('api_key') || errorStr.contains('invalid')) {
        print('⚠️ API Key issue detected');
        return 'Xin lỗi, có lỗi xảy ra với API. Vui lòng kiểm tra cấu hình.';
      }
      if (errorStr.contains('quota') || errorStr.contains('limit') || errorStr.contains('rate')) {
        print('⚠️ API quota/limit issue detected');
        return 'Xin lỗi, API đã đạt giới hạn. Vui lòng thử lại sau.';
      }
      if (errorStr.contains('network') || errorStr.contains('connection')) {
        print('⚠️ Network issue detected');
        return 'Xin lỗi, không thể kết nối đến server. Vui lòng kiểm tra kết nối internet.';
      }
      
      return 'Xin lỗi, có lỗi xảy ra. Vui lòng thử lại sau.';
    }
  }

  // Analyze mood from user message
  static Future<MoodType?> analyzeMood(String userMessage) async {
    try {
      print('🔵 Gemini: Analyzing mood from: "$userMessage"');
      final model = _getModel;
      
      final prompt = '''
Phân tích tâm trạng của người dùng từ tin nhắn sau và trả lời CHỈ một trong các từ khóa sau:
- "stressed" nếu họ căng thẳng, lo âu
- "sad" nếu họ buồn, trầm cảm
- "tired" nếu họ mệt mỏi
- "insomnia" nếu họ khó ngủ, mất ngủ
- "normal" nếu họ bình thường, tích cực
- "unknown" nếu không xác định được

Tin nhắn: "$userMessage"

Trả lời CHỈ một từ khóa, không có giải thích gì khác:
''';

      final response = await model.generateContent([Content.text(prompt)]);
      final moodText = response.text?.toLowerCase().trim() ?? 'unknown';
      print('📊 Gemini: Detected mood: $moodText');

      // Extract mood from response (might contain extra text)
      MoodType? mood;
      if (moodText.contains('stressed')) {
        mood = MoodType.stressed;
      } else if (moodText.contains('sad')) {
        mood = MoodType.sad;
      } else if (moodText.contains('tired')) {
        mood = MoodType.tired;
      } else if (moodText.contains('insomnia')) {
        mood = MoodType.insomnia;
      } else if (moodText.contains('normal')) {
        mood = MoodType.normal;
      }

      if (mood != null) {
        print('✅ Gemini: Mood detected: ${mood.label}');
      } else {
        print('⚠️ Gemini: Could not detect mood');
      }
      
      return mood;
    } catch (e, stackTrace) {
      print('❌ Error analyzing mood from Gemini: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  // Get suggestions based on mood
  static Future<Map<String, String>> getSuggestions(MoodType mood) async {
    try {
      print('🔵 Gemini: Getting suggestions for mood: ${mood.label}');
      final model = _getModel;
      
      final prompt = '''
Dựa trên tâm trạng "${mood.label}" của người dùng, hãy đưa ra gợi ý cụ thể về:
1. Tinh dầu phù hợp (Lavender, Sweet Orange, Chamomile, Peppermint)
2. Loại nhạc (Thiền, Piano, Thiên nhiên, Ambient)
3. Chế độ ánh sáng (warm, amber, blue)

Trả lời theo format JSON:
{
  "essential_oil": "tên tinh dầu",
  "music": "loại nhạc",
  "light": "chế độ ánh sáng",
  "reason": "lý do ngắn gọn"
}
''';

      final response = await model.generateContent([Content.text(prompt)]);
      final responseText = response.text ?? '';
      print('📝 Gemini: Suggestions response: $responseText');

      // Try to parse JSON from response
      try {
        // Extract JSON from response (might have markdown code blocks)
        String jsonText = responseText;
        if (jsonText.contains('```json')) {
          jsonText = jsonText.split('```json')[1].split('```')[0].trim();
        } else if (jsonText.contains('```')) {
          jsonText = jsonText.split('```')[1].split('```')[0].trim();
        }

        // Simple JSON parsing (for basic structure)
        final essentialOil = _extractJsonValue(jsonText, 'essential_oil') ?? mood.essentialOil;
        final music = _extractJsonValue(jsonText, 'music') ?? 'Thiền';
        final light = _extractJsonValue(jsonText, 'light') ?? 'warm';
        final reason = _extractJsonValue(jsonText, 'reason') ?? '';

        print('✅ Gemini: Parsed suggestions - Oil: $essentialOil, Music: $music, Light: $light');
        
        return {
          'essential_oil': essentialOil,
          'music': music,
          'light': light,
          'reason': reason,
        };
      } catch (e) {
        print('⚠️ Error parsing JSON from Gemini: $e');
        print('Using fallback suggestions');
        // Fallback to default suggestions
        return {
          'essential_oil': mood.essentialOil,
          'music': 'Thiền',
          'light': 'warm',
          'reason': '',
        };
      }
    } catch (e, stackTrace) {
      print('❌ Error getting suggestions from Gemini: $e');
      print('Stack trace: $stackTrace');
      print('Using fallback suggestions');
      return {
        'essential_oil': mood.essentialOil,
        'music': 'Thiền',
        'light': 'warm',
        'reason': '',
      };
    }
  }

  // Helper to extract value from JSON-like string
  static String? _extractJsonValue(String jsonText, String key) {
    try {
      final pattern = RegExp('"$key"\\s*:\\s*"([^"]+)"');
      final match = pattern.firstMatch(jsonText);
      return match?.group(1);
    } catch (e) {
      return null;
    }
  }
}

