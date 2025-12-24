import '../models/message.dart';
import '../models/mood_type.dart';

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
        analysis = 'Mình thấy bạn đang khá căng thẳng. Điều này hoàn toàn bình thường sau một ngày dài. Hãy hít thở sâu cùng mình nhé.';
        break;
      case MoodType.sad:
        analysis = 'Mình hiểu bạn đang cảm thấy buồn. Những cảm xúc này là điều tự nhiên. Hãy để mình giúp bạn cảm thấy tốt hơn.';
        break;
      case MoodType.tired:
        analysis = 'Bạn trông mệt mỏi rồi. Hãy thư giãn và để cơ thể được nghỉ ngơi nhé.';
        break;
      case MoodType.insomnia:
        analysis = 'Khó ngủ có thể khiến bạn căng thẳng. Hãy để mình giúp bạn thư giãn và chuẩn bị cho giấc ngủ ngon.';
        break;
      case MoodType.normal:
        analysis = 'Thật tuyệt khi bạn đang cảm thấy tốt! Hãy duy trì cảm xúc tích cực này nhé.';
        break;
    }
    
    messages.add(ChatMessage(
      text: analysis,
      isBot: true,
      timestamp: DateTime.now(),
    ));

    // Gợi ý tinh dầu
    messages.add(ChatMessage(
      text: 'Mình đề xuất bạn dùng tinh dầu ${mood.essentialOil} để ${mood.effect.toLowerCase()}. Hãy thắp nến trong 20–30 phút.',
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
      text: 'Mình sẽ điều chỉnh ánh sáng ${getLightLabel(lightMode)} để tạo không gian thư giãn cho bạn.',
      isBot: true,
      timestamp: DateTime.now(),
      suggestionType: 'light',
    ));

    return messages;
  }

  static ChatMessage getGreetingMessage() {
    return ChatMessage(
      text: 'Xin chào! Hôm nay bạn cảm thấy thế nào? Bạn đang mệt, buồn hay căng thẳng?',
      isBot: true,
      timestamp: DateTime.now(),
    );
  }
}

