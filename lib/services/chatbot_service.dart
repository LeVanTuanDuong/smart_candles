import 'ai_inference_service.dart';

class ChatbotService {
  /// Main entry point for processing user messages
  static Future<Map<String, dynamic>> processUserMessage(String input) async {
    // 1. Determine Intent (Control)
    final intent = await AiInferenceService().determineIntent(input);

    if (intent != null) {
      // If intent found, return Action
      return {
        'type': 'action',
        'intent': intent,
        'message': _getIntentConfirmationMessage(intent),
      };
    }

    // 2. Analyze Emotion (for context)
    // We assume timeOfDay is 'afternoon' for now or pass it in.
    // Ideally ChatbotService/Screen handles this context.
    // For simplicity, we just use the text.
    final emotionAnalysis =
        await AiInferenceService().analyzeTextEmotion(input);
    final topEmotion = _getTopEmotion(emotionAnalysis);

    // 3. Generate Conversational Response (Gemma)
    String response;
    try {
      // Build prompt with context
      String prompt = "User says: \"$input\". ";
      if (topEmotion != null) {
        prompt += "User seems $topEmotion. ";
      }
      prompt += "Respond kindly and briefly in Vietnamese.";

      response = await AiInferenceService().generateGemmaResponse(prompt);

      // Fallback if model not ready
      if (response == "Model chưa sẵn sàng.") {
        response =
            "Mình đang tải dữ liệu để nói chuyện với bạn. Bạn chờ chút nhé.";
      }
    } catch (e) {
      response =
          "Xin lỗi, mình đang gặp chút trục trặc. Bạn nói lại được không?";
    }

    return {
      'type': 'text',
      'message': response,
    };
  }

  static String? _getTopEmotion(Map<String, double> scores) {
    if (scores.isEmpty) return null;
    var sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  static String _getIntentConfirmationMessage(String intent) {
    switch (intent) {
      case 'LIGHT_ON':
        return "Ok, mình bật đèn cho bạn ngay.";
      case 'LIGHT_OFF':
        return "Được rồi, mình tắt đèn nhé.";
      case 'LIGHT_COLOR':
        return "Ok, mình sẽ đổi màu đèn.";
      case 'MUSIC_ON':
        return "Mình bật nhạc ngay đây.";
      case 'MUSIC_OFF':
        return "Ok, mình tắt nhạc nhé.";
      case 'MUSIC_CHANGE':
        return "Mình đổi bài khác nhé.";
      default:
        return "Được rồi.";
    }
  }

  static String getCheckInGreeting() {
    return "Chào bạn! Hôm nay bạn cảm thấy thế nào? Mình ở đây để lắng nghe và hỗ trợ bạn.";
  }
}
