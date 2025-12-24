import 'dart:math';
import '../models/mood_type.dart';

/// Service to provide varied, non-repetitive chatbot responses
class ChatbotResponseVariations {
  static final Random _random = Random();
  static final Map<String, int> _responseCounts = {}; // Track response usage

  // PHẦN A: Responses khi người dùng BUỒN
  static List<String> getSadResponsesLight() {
    return [
      'Có những ngày mình buồn mà cũng không biết vì sao.\n\n'
          'Điều đó không có nghĩa là bạn yếu đuối, chỉ là cảm xúc đang cần được nghỉ ngơi.',
      'Nghe như bạn đã phải cố gắng khá lâu rồi.\n\n'
          'Khi cơ thể mệt, tâm trí cũng dễ buồn theo. Điều đó rất tự nhiên.',
      'Buồn như vậy mệt lắm. Cảm ơn bạn đã nói ra.',
    ];
  }

  static List<String> getSadResponsesMedium() {
    return [
      'Mình nghe bạn đang buồn vì mọi thứ không diễn ra như mong đợi.\n\n'
          'Điều đó đau thật, và bất kỳ ai trong hoàn cảnh này cũng sẽ buồn.',
      'Khi liên quan đến người mình quan tâm, nỗi buồn thường sâu hơn.\n\n'
          'Bạn buồn như vậy cho thấy bạn là người biết yêu thương.',
      'Cảm giác cô đơn không phải lúc nào cũng vì thiếu người xung quanh,\n\n'
          'mà vì chưa có ai thực sự hiểu mình lúc này.',
    ];
  }

  static List<String> getSadResponsesHeavy() {
    return [
      'Khi bạn không còn cảm thấy gì, điều đó không phải là "không sao cả",\n\n'
          'mà thường là bạn đã mệt quá lâu rồi.',
      'Nghe như bạn đang thấy mọi thứ rất nặng nề.\n\n'
          'Mình thật sự tôn trọng việc bạn vẫn mở app và nói ra điều này.',
      'Ngay cả khi bạn chưa thấy lối ra,\n\n'
          'việc bạn còn ở đây đã là một bước rồi.',
    ];
  }

  // PHẦN B: Responses khi người dùng VUI
  static List<String> getHappyResponsesLight() {
    return [
      'Nghe vui đó 😊\n\n'
          'Không phải ngày nào cũng phải có thành tựu lớn,\n'
          'một ngày dễ chịu cũng rất đáng trân trọng.',
      'Cảm giác "ổn" đôi khi chính là dấu hiệu cho thấy\n\n'
          'bạn đang cân bằng lại rất tốt.',
    ];
  }

  static List<String> getHappyResponsesMedium() {
    return [
      'Chúc mừng bạn 🎉\n\n'
          'Việc này không dễ, và bạn đã làm được.\n'
          'Hãy dành một chút để ghi nhận chính mình nhé.',
      'Tiến bộ nhỏ vẫn là tiến bộ.\n\n'
          'Rất nhiều thay đổi lớn bắt đầu từ những bước như thế này.',
    ];
  }

  static List<String> getHappyResponsesHeavy() {
    return [
      'Năng lượng của bạn đang rất tốt đó!\n\n'
          'Mình rất vui khi được chia sẻ khoảnh khắc này cùng bạn 🌟',
      'Chúc mừng bạn thật nhiều 🎊\n\n'
          'Khoảnh khắc này rất đáng nhớ.\n'
          'Sau này khi mệt, bạn có thể quay lại đọc chính cảm xúc hôm nay.',
    ];
  }

  // PHẦN C: Câu nói vàng (golden phrases) để tránh lặp
  static List<String> getGoldenPhrasesSad() {
    return [
      'Bạn không cần phải ổn ngay bây giờ.',
      'Cảm xúc này không định nghĩa con người bạn.',
      'Mình tin bạn đã cố gắng nhiều hơn bạn nghĩ.',
      'Bạn không cần phải mạnh mẽ thêm lúc này đâu.',
      'Việc này đau, nhưng bạn không sai vì đã có cảm xúc.',
      'Ít nhất trong khoảnh khắc này, mình đang ở đây cùng bạn.',
    ];
  }

  static List<String> getGoldenPhrasesHappy() {
    return [
      'Giữ lại khoảnh khắc này nhé.',
      'Niềm vui của bạn cũng quan trọng như nỗi buồn.',
      'Bạn xứng đáng với cảm giác tốt này.',
    ];
  }

  // Get response with variation based on mood and intensity
  static String getResponseForMood(
    MoodType mood,
    int? intensity,
    String? context,
  ) {
    // Determine intensity level
    int level = 0; // 0=light, 1=medium, 2=heavy
    if (intensity != null) {
      if (intensity >= 7) {
        level = 2; // heavy
      } else if (intensity >= 4) {
        level = 1; // medium
      } else {
        level = 0; // light
      }
    }

    List<String> responses;
    String baseResponse;

    switch (mood) {
      case MoodType.sad:
        if (level == 2) {
          responses = getSadResponsesHeavy();
        } else if (level == 1) {
          responses = getSadResponsesMedium();
        } else {
          responses = getSadResponsesLight();
        }
        baseResponse = _getRandomResponse(responses, 'sad_$level');
        
        // Add context-specific follow-up
        if (context != null) {
          if (context.contains('thất bại') || context.contains('tự trách')) {
            baseResponse += '\n\nCó vẻ bạn đang trách bản thân khá nhiều.\n'
                'Nếu hôm nay chưa thành công, điều đó chỉ nói rằng hôm nay khó,\n'
                'không nói lên giá trị con người bạn.';
          } else if (context.contains('quan hệ') || context.contains('người')) {
            baseResponse += '\n\nViệc này đau, nhưng bạn không sai vì đã có cảm xúc.';
          } else if (context.contains('cô đơn')) {
            baseResponse += '\n\nÍt nhất trong khoảnh khắc này, mình đang ở đây cùng bạn.';
          }
        }
        
        // Add golden phrase randomly
        if (_random.nextDouble() < 0.3) {
          final phrase = getGoldenPhrasesSad()[_random.nextInt(getGoldenPhrasesSad().length)];
          baseResponse += '\n\n$phrase';
        }
        break;

      case MoodType.normal:
        if (level == 2) {
          responses = getHappyResponsesHeavy();
        } else if (level == 1) {
          responses = getHappyResponsesMedium();
        } else {
          responses = getHappyResponsesLight();
        }
        baseResponse = _getRandomResponse(responses, 'happy_$level');
        
        // Add golden phrase randomly
        if (_random.nextDouble() < 0.3) {
          final phrase = getGoldenPhrasesHappy()[_random.nextInt(getGoldenPhrasesHappy().length)];
          baseResponse += '\n\n$phrase';
        }
        break;

      default:
        // For other moods, use default response
        baseResponse = _getDefaultResponseForMood(mood, intensity);
    }

    return baseResponse;
  }

  // Get suggestion message with interactive options
  static String getSuggestionMessageWithOptions({
    required MoodType mood,
    required String essentialOil,
    required String music,
    required String lightMode,
    required double lightBrightness,
    String? encouragementMessage,
  }) {
    final brightnessPercent = (lightBrightness * 100).toInt();
    
    // Get encouragement message based on mood if not provided
    String encouragement = encouragementMessage ?? '';
    if (encouragement.isEmpty) {
      switch (mood) {
        case MoodType.stressed:
          encouragement = 'Mình hiểu bạn đang căng thẳng. Hãy để mình giúp bạn thư giãn nhé.';
          break;
        case MoodType.sad:
          encouragement = 'Mình hiểu bạn đang buồn. Hãy để mình giúp bạn cảm thấy tốt hơn nhé.';
          break;
        case MoodType.tired:
          encouragement = 'Bạn trông mệt mỏi rồi. Hãy để mình giúp bạn thư giãn và nghỉ ngơi nhé.';
          break;
        case MoodType.insomnia:
          encouragement = 'Khó ngủ có thể khiến bạn căng thẳng. Hãy để mình giúp bạn thư giãn và chuẩn bị cho giấc ngủ ngon nhé.';
          break;
        case MoodType.normal:
          encouragement = 'Thật tuyệt khi bạn đang cảm thấy tốt! Hãy duy trì cảm xúc tích cực này nhé.';
          break;
      }
    }
    
    String message = encouragement;
    message += '\n\nMình đề xuất:\n';
    message += '• Tinh dầu $essentialOil cho nến\n';
    message += '• Nhạc $music 10 phút\n';
    message += '• Đèn $lightMode $brightnessPercent%\n\n';
    message += 'Bạn muốn mình tự động bật nhạc và đèn ngay không?';
    
    return message;
  }

  // Get closing message for sad mood
  static String getClosingMessageSad() {
    return '\n\nBạn không cần phải giải quyết cả cuộc đời hôm nay.\n'
        'Chỉ cần chăm sóc bản thân trong 10 phút tiếp theo là đủ.';
  }

  // Get closing message for happy mood
  static String getClosingMessageHappy() {
    return '\n\nMình sẽ lưu lại cảm xúc vui này cho bạn.\n'
        'Những ngày buồn, mình có thể nhắc bạn rằng:\n'
        '"Đã từng có ngày bạn cảm thấy như thế này."';
  }

  // Helper to get random response and avoid repetition
  static String _getRandomResponse(List<String> responses, String category) {
    if (responses.isEmpty) return '';
    
    // Track usage
    final key = '$category';
    _responseCounts[key] = (_responseCounts[key] ?? 0) + 1;
    
    // If we've used all responses, reset
    if (_responseCounts[key]! >= responses.length) {
      _responseCounts[key] = 0;
    }
    
    // Get response that hasn't been used recently
    int index;
    if (_responseCounts[key]! < responses.length) {
      index = _responseCounts[key]!;
    } else {
      index = _random.nextInt(responses.length);
    }
    
    return responses[index];
  }

  // Default response for other moods with variations
  static String _getDefaultResponseForMood(MoodType mood, int? intensity) {
    switch (mood) {
      case MoodType.stressed:
        final responses = [
          'Mình nghe bạn đang rất căng. Bạn không cần phải gồng một mình.',
          'Căng thẳng như vậy mệt lắm. Hãy để mình giúp bạn thư giãn nhé.',
          'Mình thấy bạn đang lo lắng nhiều. Điều này hoàn toàn bình thường.',
        ];
        return responses[_random.nextInt(responses.length)];
      case MoodType.tired:
        final responses = [
          'Nghe như bạn đang cạn pin. Mình sẽ giúp bạn hồi lại một chút.',
          'Bạn trông mệt mỏi rồi. Hãy để mình chăm sóc bạn nhé.',
          'Mệt như vậy cần được nghỉ ngơi. Mình sẽ tạo không gian yên tĩnh cho bạn.',
        ];
        return responses[_random.nextInt(responses.length)];
      case MoodType.insomnia:
        final responses = [
          'Để mình chuẩn bị không gian ngủ cho bạn nhé.',
          'Mình sẽ điều chỉnh mọi thứ để bạn dễ ngủ hơn.',
          'Hãy để mình giúp bạn thư giãn và chuẩn bị cho giấc ngủ.',
          'Mình sẽ tạo môi trường yên tĩnh để bạn nghỉ ngơi.',
          'Để mình giúp bạn chuyển sang chế độ ngủ một cách nhẹ nhàng.',
        ];
        return responses[_random.nextInt(responses.length)];
      default:
        final responses = [
          'Mình hiểu bạn. Hãy để mình giúp bạn thư giãn nhé.',
          'Mình đang ở đây với bạn. Bạn muốn mình làm gì?',
          'Cảm ơn bạn đã chia sẻ. Mình sẽ giúp bạn cảm thấy tốt hơn.',
        ];
        return responses[_random.nextInt(responses.length)];
    }
  }

  // Reset response counts (call when conversation resets)
  static void resetCounts() {
    _responseCounts.clear();
  }
}

