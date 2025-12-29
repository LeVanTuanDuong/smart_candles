import '../models/message.dart';
import '../models/mood_type.dart';
import 'chatbot_flow_service.dart';

class ChatbotService {
  static List<String> getMusicSuggestions(MoodType mood) {
    switch (mood) {
      case MoodType.stressed:
        return ['Piano chậm', 'Nature sound', 'Meditation music'];
      case MoodType.sad:
        return ['Ambient', 'Piano chậm', 'Nature sound'];
      case MoodType.tired:
        return ['Ambient', 'Nature sound'];
      case MoodType.insomnia:
        return ['Meditation music', 'Nature sound', 'Ambient'];
      case MoodType.normal:
        return ['Ambient', 'Piano chậm'];
    }
  }

  static String getLightSuggestion(MoodType mood) {
    switch (mood) {
      case MoodType.stressed:
        return 'warm';
      case MoodType.sad:
        return 'amber';
      case MoodType.tired:
        return 'amber';
      case MoodType.insomnia:
        return 'blue';
      case MoodType.normal:
        return 'warm';
    }
  }

  static String getLightLabel(String mode) {
    switch (mode) {
      case 'warm':
        return 'Warm white - Thư giãn';
      case 'amber':
        return 'Amber - Hỗ trợ giấc ngủ';
      case 'blue':
        return 'Soft blue - Bình tĩnh, thiền';
      default:
        return 'Warm white';
    }
  }

  static List<ChatMessage> analyzeMoodAndSuggest(MoodType mood) {
    final messages = <ChatMessage>[];

    // Message phân tích tâm trạng
    String analysis = '';
    switch (mood) {
      case MoodType.stressed:
        analysis =
            'Mình thấy bạn đang khá căng thẳng. Điều này hoàn toàn bình thường sau một ngày dài. Hãy hít thở sâu cùng mình nhé.';
        break;
      case MoodType.sad:
        analysis =
            'Mình hiểu bạn đang cảm thấy buồn. Những cảm xúc này là điều tự nhiên. Hãy để mình giúp bạn cảm thấy tốt hơn.';
        break;
      case MoodType.tired:
        analysis =
            'Bạn trông mệt mỏi rồi. Hãy thư giãn và để cơ thể được nghỉ ngơi nhé.';
        break;
      case MoodType.insomnia:
        analysis =
            'Khó ngủ có thể khiến bạn căng thẳng. Hãy để mình giúp bạn thư giãn và chuẩn bị cho giấc ngủ ngon.';
        break;
      case MoodType.normal:
        analysis =
            'Thật tuyệt khi bạn đang cảm thấy tốt! Hãy duy trì cảm xúc tích cực này nhé.';
        break;
    }

    messages.add(ChatMessage(
      text: analysis,
      isBot: true,
      timestamp: DateTime.now(),
    ));

    // Gợi ý tinh dầu
    messages.add(ChatMessage(
      text:
          'Mình đề xuất bạn dùng tinh dầu ${mood.essentialOil} để ${mood.effect.toLowerCase()}. Hãy thắp nến trong 20–30 phút.',
      isBot: true,
      timestamp: DateTime.now(),
      suggestionType: 'essential_oil',
    ));

    // Gợi ý nhạc
    final music = getMusicSuggestions(mood).first;
    messages.add(ChatMessage(
      text: 'Mình sẽ bật nhạc $music nhẹ nhàng giúp bạn bình tĩnh hơn nhé.',
      isBot: true,
      timestamp: DateTime.now(),
      suggestionType: 'music',
    ));

    // Gợi ý ánh sáng
    final lightMode = getLightSuggestion(mood);
    messages.add(ChatMessage(
      text:
          'Mình sẽ điều chỉnh ánh sáng ${getLightLabel(lightMode)} để tạo không gian thư giãn cho bạn.',
      isBot: true,
      timestamp: DateTime.now(),
      suggestionType: 'light',
    ));

    return messages;
  }

  static ChatMessage getGreetingMessage() {
    return ChatMessage(
      text:
          'Xin chào! Hôm nay bạn cảm thấy thế nào? Bạn đang mệt, buồn hay căng thẳng?',
      isBot: true,
      timestamp: DateTime.now(),
    );
  }

  // Get fallback response based on user message (replaces DialogflowService)
  static String getFallbackResponse(String userMessage) {
    final userLower = userMessage.toLowerCase();

    // Use ChatbotFlowService for mood detection and responses
    MoodType? detectedMood;

    // Check for stress/anxiety
    if (userLower.contains('căng thẳng') ||
        userLower.contains('stressed') ||
        userLower.contains('lo âu') ||
        userLower.contains('lo lắng') ||
        userLower.contains('anxiety') ||
        userLower.contains('bực bội') ||
        userLower.contains('cáu')) {
      detectedMood = MoodType.stressed;
    } else if (userLower.contains('buồn') ||
        userLower.contains('sad') ||
        userLower.contains('trầm') ||
        userLower.contains('chán nản') ||
        userLower.contains('trống rỗng')) {
      detectedMood = MoodType.sad;
    } else if (userLower.contains('mệt') ||
        userLower.contains('tired') ||
        userLower.contains('mệt mỏi') ||
        userLower.contains('kiệt sức')) {
      detectedMood = MoodType.tired;
    } else if (userLower.contains('khó ngủ') ||
        userLower.contains('mất ngủ') ||
        userLower.contains('insomnia') ||
        userLower.contains('không ngủ được')) {
      detectedMood = MoodType.insomnia;
    } else if (userLower.contains('tốt') ||
        userLower.contains('bình thường') ||
        userLower.contains('ok') ||
        userLower.contains('good') ||
        userLower.contains('vui') ||
        userLower.contains('ổn')) {
      detectedMood = MoodType.normal;
    }

    if (detectedMood != null) {
      // Use ChatbotFlowService for mood-specific responses
      return ChatbotFlowService.getMoodResponse(detectedMood, null);
    }

    return 'Mình hiểu bạn. Hãy cho mình biết thêm về cảm xúc của bạn nhé. Bạn đang cảm thấy thế nào?';
  }

  // Get suggestions map (replaces DialogflowService.getSuggestions)
  static Future<Map<String, String>> getSuggestions(MoodType mood) async {
    final essentialOilSuggestions =
        ChatbotFlowService.getEssentialOilSuggestions(mood);
    final primaryOil =
        essentialOilSuggestions['primary']?.first ?? mood.essentialOil;

    final musicSuggestions = ChatbotFlowService.getMusicSuggestions(mood);
    final primaryMusic = musicSuggestions.isNotEmpty
        ? musicSuggestions.first['type'] ?? 'Thiền'
        : 'Thiền';

    final lightSuggestion = ChatbotFlowService.getLightSuggestion(mood, null);
    final lightMode = lightSuggestion['mode'] as String? ?? 'warm';

    return {
      'essential_oil': primaryOil,
      'music': primaryMusic,
      'light': lightMode,
    };
  }
}
