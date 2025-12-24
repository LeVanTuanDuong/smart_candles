import '../models/mood_type.dart';

/// Service to manage chatbot conversation flows
class ChatbotFlowService {
  static final ChatbotFlowService _instance = ChatbotFlowService._internal();
  factory ChatbotFlowService() => _instance;
  ChatbotFlowService._internal();

  // Flow states
  bool _hasCompletedOnboarding = false;
  bool _isInCheckIn = false;
  bool _isInGrounding = false;
  bool _isInCBT = false;
  int? _currentIntensity; // 0-10
  MoodType? _currentMood;
  String? _currentContext; // work, relationship, health, finance, other

  // Getters
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  bool get isInCheckIn => _isInCheckIn;
  bool get isInGrounding => _isInGrounding;
  bool get isInCBT => _isInCBT;
  int? get currentIntensity => _currentIntensity;
  MoodType? get currentMood => _currentMood;
  String? get currentContext => _currentContext;

  // Flow 0: Safety & Tone Rules
  static String getSafetyMessage() {
    return 'Mình rất tiếc vì bạn đang phải chịu điều này. '
        'Nếu bạn có ý định làm hại bản thân hoặc cảm thấy không an toàn, '
        'hãy gọi người thân ngay hoặc liên hệ dịch vụ khẩn cấp tại nơi bạn sống. '
        'Nếu bạn muốn, mình vẫn có thể ở đây để cùng bạn thở chậm và tìm bước nhỏ tiếp theo.';
  }

  // Flow 1: Onboarding
  static String getOnboardingGreeting() {
    return 'Chào bạn, mình là trợ lý thư giãn của bạn 🌿\n\n'
        'Mình có thể lắng nghe tâm trạng và gợi ý tinh dầu + nhạc + ánh sáng để bạn dễ chịu hơn.\n\n'
        'Bạn muốn bắt đầu bằng việc kết nối đèn nến thông minh chứ?';
  }

  static String getDeviceConnectionInstructions() {
    return 'Ok. Mình sẽ tìm thiết bị gần bạn.\n\n'
        '• Bật Bluetooth trên điện thoại\n'
        '• Bật nguồn đế đèn (ESP32)\n'
        '• Chọn thiết bị có tên: CandleHub-xxxx';
  }

  static String getDeviceConnectedMessage() {
    return 'Kết nối đèn nến xong rồi ✅\n\n'
        'Tiếp theo, bạn muốn ghép loa Bluetooth để phát nhạc không?';
  }

  static String getSpeakerConnectedMessage() {
    return 'Tuyệt! Từ giờ khi mình gợi ý nhạc, ESP32 sẽ điều khiển phát qua loa của bạn 🎵';
  }

  static String getPreferencesSetupMessage() {
    return 'Mình hỏi nhanh 3 câu để gợi ý đúng hơn nhé:\n\n'
        '1. Bạn thích mùi nào? (hoa/cam chanh/gỗ/herbal)\n'
        '2. Bạn thích nhạc kiểu gì? (piano/ambient/nature/lofi)\n'
        '3. Bạn nhạy cảm mùi mạnh không? (nhẹ/vừa/mạnh)';
  }

  // Flow 2: Check-in
  static String getCheckInGreeting() {
    return 'Hôm nay bạn đang thấy thế nào? Chọn nhanh 1 ý gần nhất nhé.';
  }

  static String getIntensityQuestion() {
    return 'Nếu chấm theo thang 0–10, cảm giác này đang ở mức mấy?';
  }

  static String getContextQuestion() {
    return 'Mình hiểu. Điều gì đang ảnh hưởng bạn nhiều nhất lúc này?';
  }

  // Flow 3: Grounding
  static String getGroundingMessage(int intensity) {
    if (intensity >= 4) {
      return 'Mình ở đây với bạn. Mình làm 1 bước nhỏ trước nhé:\n\n'
          'Hít vào 4 giây… giữ 2 giây… thở ra 6 giây.\n\n'
          'Mình làm cùng bạn 3 lần.';
    }
    return 'Hãy cùng mình thở chậm một chút nhé:\n\n'
        'Hít vào 4 giây… giữ 2 giây… thở ra 6 giây.';
  }

  static String getEmotionValidationMessage(String moodSummary) {
    return 'Cảm ơn bạn đã chia sẻ. Nghe như bạn đang $moodSummary. Điều đó thật sự không dễ.';
  }

  // Flow 4: Suggestions by Mood
  static Map<String, List<String>> getEssentialOilSuggestions(MoodType mood) {
    switch (mood) {
      case MoodType.stressed:
        return {
          'primary': ['Lavender', 'Bergamot', 'Frankincense'],
          'descriptions': [
            'Lavender (dịu thần kinh, dễ ngủ)',
            'Bergamot (nhẹ đầu, bớt lo)',
            'Frankincense (thiền, tĩnh tâm)',
          ],
        };
      case MoodType.sad:
        return {
          'primary': ['Sweet Orange', 'Grapefruit', 'Ylang-ylang'],
          'descriptions': [
            'Sweet Orange (ấm áp, dễ chịu)',
            'Grapefruit (tươi, nhẹ)',
            'Ylang-ylang (ôm ấp, dịu)',
          ],
        };
      case MoodType.tired:
        return {
          'primary': ['Peppermint', 'Rosemary', 'Lemon'],
          'descriptions': [
            'Peppermint (tỉnh táo)',
            'Rosemary (tập trung)',
            'Lemon (sạch, sáng)',
          ],
        };
      case MoodType.insomnia:
        return {
          'primary': ['Chamomile', 'Lavender', 'Sandalwood'],
          'descriptions': [
            'Chamomile (êm, giảm kích thích)',
            'Lavender (dịu thần kinh)',
            'Sandalwood (trầm, bình ổn)',
          ],
        };
      default:
        return {
          'primary': ['Chamomile', 'Lavender'],
          'descriptions': [
            'Chamomile (duy trì cảm xúc tích cực)',
            'Lavender (thư giãn nhẹ)',
          ],
        };
    }
  }

  static String getEssentialOilMessage(MoodType mood) {
    final suggestions = getEssentialOilSuggestions(mood);
    final oils = suggestions['primary']!;
    final descriptions = suggestions['descriptions']!;

    String moodContext = '';
    switch (mood) {
      case MoodType.stressed:
        moodContext = 'Với căng thẳng, mình gợi ý mùi giúp "thả lỏng":';
        break;
      case MoodType.sad:
        moodContext = 'Khi buồn, mình chọn mùi "nâng tinh thần" nhưng vẫn êm:';
        break;
      case MoodType.tired:
        moodContext = 'Khi mệt, mình chọn mùi "đánh thức" nhưng không gắt:';
        break;
      case MoodType.insomnia:
        moodContext = 'Khi khó ngủ, mục tiêu là "an thần":';
        break;
      default:
        moodContext = 'Mình gợi ý mùi thư giãn:';
    }

    String message = '$moodContext\n\n';
    for (int i = 0; i < oils.length; i++) {
      message += '• ${descriptions[i]}\n';
    }
    message += '\nBạn muốn thử mùi nào?';

    return message;
  }

  static List<Map<String, String>> getMusicSuggestions(MoodType mood) {
    switch (mood) {
      case MoodType.stressed:
        return [
          {
            'type': 'Ambient nhẹ',
            'reason': 'giảm nhịp thở',
            'duration': '10 phút',
          },
          {
            'type': 'Piano chậm',
            'reason': 'êm và dễ tập trung',
            'duration': '10 phút',
          },
          {
            'type': 'Nature sound: mưa nhẹ',
            'reason': 'dễ ngủ',
            'duration': '10 phút',
          },
        ];
      case MoodType.sad:
        return [
          {
            'type': 'Piano ấm',
            'reason': 'nâng tinh thần nhẹ',
            'duration': '10 phút',
          },
          {
            'type': 'Lo-fi nhẹ',
            'reason': 'dễ chịu, không buồn thêm',
            'duration': '10 phút',
          },
        ];
      case MoodType.tired:
        return [
          {
            'type': 'Lo-fi nhẹ',
            'reason': 'tỉnh táo nhưng không gắt',
            'duration': '10 phút',
          },
          {
            'type': 'Nature sound',
            'reason': 'nghỉ ngơi',
            'duration': '10 phút',
          },
        ];
      case MoodType.insomnia:
        return [
          {
            'type': 'Mưa nhẹ',
            'reason': 'dễ ngủ',
            'duration': '15 phút',
          },
          {
            'type': 'Ambient tối',
            'reason': 'thiền sâu',
            'duration': '15 phút',
          },
        ];
      default:
        return [
          {
            'type': 'Piano nhẹ',
            'reason': 'duy trì cảm xúc tích cực',
            'duration': '10 phút',
          },
        ];
    }
  }

  static String getMusicMessage(MoodType mood) {
    final suggestions = getMusicSuggestions(mood);
    String message = 'Mình gợi ý ${suggestions.length} kiểu nhạc:\n\n';

    for (var suggestion in suggestions) {
      message += '${suggestion['type']} (${suggestion['reason']})\n';
    }

    message += '\nBạn muốn mình bật kiểu nào?';
    return message;
  }

  static Map<String, dynamic> getLightSuggestion(MoodType mood, int? intensity, {int? ess}) {
    // Use ESS to fine-tune brightness if available
    double brightnessMultiplier = 1.0;
    if (ess != null) {
      if (ess > 80) {
        // High severity - lower brightness for calming
        brightnessMultiplier = 0.7;
      } else if (ess > 60) {
        brightnessMultiplier = 0.85;
      } else if (ess < 30) {
        // Low severity - can be slightly brighter
        brightnessMultiplier = 1.1;
      }
    }
    
    switch (mood) {
      case MoodType.stressed:
        final brightness = (0.35 * brightnessMultiplier).clamp(0.2, 0.5);
        return {
          'mode': 'warm',
          'brightness': brightness,
          'message': 'Mình đề xuất bật đèn ở mức ${(brightness * 100).toInt()}% – warm để mắt bạn dịu hơn. Bạn muốn bật không?',
        };
      case MoodType.sad:
        final brightness = (0.5 * brightnessMultiplier).clamp(0.3, 0.6);
        return {
          'mode': 'warm',
          'brightness': brightness,
          'message': 'Mình đề xuất bật đèn warm ${(brightness * 100).toInt()}% để tạo không gian ấm áp. Bạn muốn bật không?',
        };
      case MoodType.tired:
        final brightness = (0.6 * brightnessMultiplier).clamp(0.4, 0.7);
        return {
          'mode': 'white',
          'brightness': brightness,
          'message': 'Mình đề xuất bật đèn trắng ${(brightness * 100).toInt()}% (không chói) để tỉnh táo hơn. Bạn muốn bật không?',
        };
      case MoodType.insomnia:
        final brightness = (0.15 * brightnessMultiplier).clamp(0.1, 0.2);
        return {
          'mode': 'amber',
          'brightness': brightness,
          'message': 'Mình đề xuất bật đèn amber ${(brightness * 100).toInt()}% để chuẩn bị ngủ. Bạn muốn bật không?',
        };
      default:
        final brightness = (0.4 * brightnessMultiplier).clamp(0.3, 0.5);
        return {
          'mode': 'warm',
          'brightness': brightness,
          'message': 'Mình đề xuất bật đèn warm ${(brightness * 100).toInt()}% để thư giãn. Bạn muốn bật không?',
        };
    }
  }

  // Flow 5: Temperature warnings
  static String getTemperatureSafeMessage() {
    return 'Nhiệt độ an toàn ✅';
  }

  static String getTemperatureWarningMessage(double temp) {
    return 'Mình thấy nhiệt độ đang tăng (khoảng ${temp.toStringAsFixed(0)}°C).\n\n'
        'Bạn giúp mình đặt đèn ở nơi thoáng hơn và tránh chạm tay vào phần khay nhé.';
  }

  static String getTemperatureDangerMessage(double temp) {
    return '⚠️ Nhiệt độ đang quá cao (${temp.toStringAsFixed(0)}°C). '
        'Mình đã chuyển LED sang đỏ để cảnh báo.\n\n'
        'Bạn hãy tắt nến / nhấc nến ra khỏi khay và để hệ thống nguội nhé.';
  }

  static String getTemperatureResolvedMessage() {
    return 'Cảm ơn bạn. Mình sẽ theo dõi đến khi nhiệt độ xuống mức an toàn.';
  }

  // Flow 6: CBT
  static String getCBTReflectionQuestion() {
    return 'Nếu bạn cho mình 1 câu mô tả suy nghĩ đang lặp lại trong đầu bạn, nó sẽ là câu gì?';
  }

  static List<String> getCommonThoughts() {
    return [
      'Mình không đủ tốt',
      'Mình sợ mọi thứ tệ hơn',
      'Mình bị kẹt',
      'Mình mệt quá rồi',
    ];
  }

  static String getReframeMessage(String thought) {
    if (thought.contains('không đủ tốt')) {
      return 'Mình nghe bạn đang tự gây áp lực.\n\n'
          'Thử đổi câu đó thành phiên bản công bằng hơn nhé:\n\n'
          '"Mình đang cố gắng trong điều kiện hiện tại, và mình có thể cải thiện từng chút."\n\n'
          'Câu này có đúng với bạn hơn không?';
    } else if (thought.contains('sợ') || thought.contains('tệ')) {
      return 'Mình hiểu nỗi sợ đó.\n\n'
          'Thử đổi thành:\n\n'
          '"Mình đang lo lắng về tương lai, nhưng mình có thể tập trung vào điều mình kiểm soát được ngay bây giờ."\n\n'
          'Câu này có đúng với bạn hơn không?';
    } else if (thought.contains('kẹt')) {
      return 'Mình nghe bạn cảm thấy bị kẹt.\n\n'
          'Thử đổi thành:\n\n'
          '"Hiện tại có vẻ khó khăn, nhưng mình có thể tìm cách nhỏ để di chuyển."\n\n'
          'Câu này có đúng với bạn hơn không?';
    } else if (thought.contains('mệt')) {
      return 'Mình hiểu bạn đang mệt.\n\n'
          'Thử đổi thành:\n\n'
          '"Mình đang cần nghỉ ngơi, và mình xứng đáng được nghỉ."\n\n'
          'Câu này có đúng với bạn hơn không?';
    }
    return 'Mình hiểu suy nghĩ đó.\n\n'
        'Hãy thử đổi thành câu tích cực hơn, công bằng hơn với bản thân bạn nhé.';
  }

  static List<Map<String, String>> getSmallActions() {
    return [
      {
        'action': 'Uống 1 ly nước',
        'time': '2 phút',
      },
      {
        'action': 'Rửa mặt nước ấm',
        'time': '3 phút',
      },
      {
        'action': 'Dọn 1 góc bàn',
        'time': '5 phút',
      },
      {
        'action': 'Viết 3 dòng điều mình đang lo',
        'time': '5 phút',
      },
    ];
  }

  static String getSmallActionMessage() {
    return 'Mình chọn 1 việc nhỏ 5 phút để bạn "lấy lại quyền kiểm soát":';
  }

  static String getActionCompletedMessage() {
    return 'Tốt lắm. Cơ thể bạn vừa nhận tín hiệu: "mình vẫn làm được điều nhỏ".';
  }

  // Flow 7: Session summary
  static String getSessionRatingQuestion() {
    return 'Trước khi kết thúc, bạn thấy mình giúp được khoảng mấy điểm? (0–10)';
  }

  static String getSessionSummary({
    required MoodType mood,
    required int intensity,
    required String essentialOil,
    required String music,
    required String light,
    required List<String> actions,
  }) {
    return 'Hôm nay chúng ta đã:\n\n'
        '• Nhận diện cảm xúc: ${mood.label} mức $intensity/10\n'
        '• Gợi ý: $essentialOil + $music + $light\n'
        '• Bước nhỏ: ${actions.join(" + ")}\n\n'
        'Mình lưu lại để lần sau gợi ý nhanh hơn nhé.';
  }

  // Mood-specific detailed responses
  static String getMoodResponse(MoodType mood, int? intensity) {
    final intensityText = intensity != null ? ' mức ${intensity}/10' : '';
    
    switch (mood) {
      case MoodType.stressed:
        return 'Mình nghe bạn đang rất căng$intensityText. Bạn không cần phải gồng một mình.\n\n'
            'Mình đề xuất: Lavender + Ambient nhẹ 10 phút + đèn warm 35%.\n\n'
            'Bạn muốn mình bật nhạc luôn chứ?';
      case MoodType.sad:
        return 'Buồn như vậy mệt lắm. Cảm ơn bạn đã nói ra.\n\n'
            'Mình đề xuất: Sweet Orange + Piano 10 phút + đèn warm 50%.\n\n'
            'Nếu bạn muốn, bạn có thể kể 1 điều khiến bạn buồn nhất hôm nay.';
      case MoodType.tired:
        return 'Nghe như bạn đang cạn pin. Mình sẽ giúp bạn hồi lại một chút.\n\n'
            'Mình đề xuất: Lemon/Rosemary + Lo-fi nhẹ 10 phút + đèn trắng 60%.\n\n'
            'Bạn muốn ưu tiên "tỉnh táo" hay "nghỉ ngơi"?';
      case MoodType.insomnia:
        // Use variations to avoid repetition
        final sleepVariations = [
          'Để mình chuẩn bị không gian ngủ cho bạn nhé.\n\n'
              'Mình đề xuất: Chamomile + mưa nhẹ 15 phút + đèn amber 15%.\n\n'
              'Bạn muốn mình bật timer tắt nhạc sau 15 phút không?',
          'Mình sẽ điều chỉnh mọi thứ để bạn dễ ngủ hơn.\n\n'
              'Mình đề xuất: Chamomile + mưa nhẹ 15 phút + đèn amber 15%.\n\n'
              'Bạn muốn mình bật timer tắt nhạc sau 15 phút không?',
          'Hãy để mình giúp bạn thư giãn và chuẩn bị cho giấc ngủ.\n\n'
              'Mình đề xuất: Chamomile + mưa nhẹ 15 phút + đèn amber 15%.\n\n'
              'Bạn muốn mình bật timer tắt nhạc sau 15 phút không?',
        ];
        // Use a simple hash of current time to pick variation
        final index = DateTime.now().millisecond % sleepVariations.length;
        return sleepVariations[index];
      default:
        return 'Mình hiểu bạn. Hãy để mình giúp bạn thư giãn nhé.';
    }
  }

  // Setters
  void setOnboardingCompleted(bool value) {
    _hasCompletedOnboarding = value;
  }

  void setCheckInState(bool value) {
    _isInCheckIn = value;
  }

  void setGroundingState(bool value) {
    _isInGrounding = value;
  }

  void setCBTState(bool value) {
    _isInCBT = value;
  }

  void setIntensity(int? value) {
    _currentIntensity = value;
  }

  void setMood(MoodType? value) {
    _currentMood = value;
  }

  void setContext(String? value) {
    _currentContext = value;
  }

  void reset() {
    _isInCheckIn = false;
    _isInGrounding = false;
    _isInCBT = false;
    _currentIntensity = null;
    _currentMood = null;
    _currentContext = null;
  }
}

