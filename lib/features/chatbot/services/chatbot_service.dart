import 'package:smart_candles/features/chatbot/services/ai_inference_service.dart';
import 'dart:math';

class ChatbotService {
  /// Main entry point for processing user messages
  static Future<Map<String, dynamic>> processUserMessage(String input,
      {String? faceEmotion}) async {
    final lowerInput = input.toLowerCase();

    // 1. Check Greeting (Simple keyword matching for speed)
    if (_isGreeting(lowerInput)) {
      return {
        'type': 'text',
        'message': _getRandomGreeting(),
      };
    }

    // 2. Determine Intent (Explicit Commands like "Turn on light")
    final intent = await AiInferenceService().determineIntent(input);
    if (intent != null) {
      return {
        'type': 'action',
        'intent': intent,
        'message': _getIntentConfirmationMessage(intent),
      };
    }

    // 3. Analyze Emotion for Recommendations (Implicit Needs)
    String? topTextEmotion;
    bool wasExplicitEmotion = false;

    // Explicit keyword overrides for common moods
    if (lowerInput.contains('căng thẳng') || lowerInput.contains('stress')) {
      topTextEmotion = 'căng_thẳng';
      wasExplicitEmotion = true;
    } else if (lowerInput.contains('hạnh phúc') || lowerInput.contains('vui')) {
      topTextEmotion = 'vui';
      wasExplicitEmotion = true;
    } else if (lowerInput.contains('buồn') ||
        lowerInput.contains('tệ') ||
        lowerInput.contains('thất vọng') ||
        lowerInput.contains('nản') ||
        lowerInput.contains('cô đơn')) {
      topTextEmotion = 'buồn';
      wasExplicitEmotion = true;
    } else if (lowerInput.contains('chán') || lowerInput.contains('mệt')) {
      topTextEmotion = 'mệt_mỏi';
      wasExplicitEmotion = true;
    } else {
      final emotionAnalysis =
          await AiInferenceService().analyzeTextEmotion(input);
      // For general detection, we use a slightly higher threshold or different triggers
      topTextEmotion = _getTopEmotion(emotionAnalysis);
    }

    // 3.1 Consistency Check (Face vs Text)
    // If face is Sad/Stressed but Text is Normal/Happy -> Hiding emotion
    if (faceEmotion != null && topTextEmotion != null) {
      if ((faceEmotion == 'buồn' || faceEmotion == 'căng_thẳng') &&
          (topTextEmotion == 'vui' || topTextEmotion == 'bình_thường')) {
        // Detected Hiding Emotion
        return {
          'type': 'text',
          'message':
              "Mình nghe bạn nói vậy, nhưng nhìn gương mặt bạn có vẻ hơi $faceEmotion. Bạn có tâm sự gì muốn chia sẻ không? Mình luôn ở đây lắng nghe mà.",
        };
      }
    }

    final effectiveEmotion = topTextEmotion;

    // SUGGESTION TRIGGER: Only if explicitly mentioned or very strong signal
    if (effectiveEmotion != null &&
        effectiveEmotion != 'binh_thuong' &&
        wasExplicitEmotion) {
      final suggestion = _getSuggestionForEmotion(effectiveEmotion);
      if (suggestion != null) {
        return {
          'type': 'suggestion',
          'message':
              "Mình cảm thấy bạn đang ${suggestion['label']}. Bạn có muốn mình ${suggestion['action_desc']} không?",
          'needsConfirmation': true,
          'suggestedActions': suggestion,
        };
      }
    }

    // 4. Deep Conversation (Gemma Fallback & Decision Maker)
    // We now use Gemma to DECIDE actions if no explicit intent command was found.
    String response;
    Map<String, dynamic>? aiDecisionAction;

    try {
      // Build the Mega-Prompt based on User's System Design
      String prompt = _buildAdvancedSystemPrompt(
        input: input,
        textEmotion: effectiveEmotion,
        faceEmotion: faceEmotion,
      );

      final rawResponse =
          await AiInferenceService().generateGemmaResponse(prompt);

      // Parse Action Tags from Response (e.g. [[MUSIC: lofi]])
      final parseResult = _parseGemmaResponse(rawResponse);
      response = parseResult['text'];
      aiDecisionAction = parseResult['action'];

      if (response == "Model chưa sẵn sàng.") {
        response =
            "Mình đang sắp xếp lại suy nghĩ một chút. Bạn chờ mình giây lát nhé.";
      }
    } catch (e) {
      response = "Xin lỗi, mình chưa nghe rõ. Bạn nói lại được không?";
    }

    // If Gemma decided an action, return it as a Suggestion
    if (aiDecisionAction != null) {
      String finalMessage = response;
      // Add a clear question if not already in the AI response to explain the buttons
      if (!response.contains('?') && !response.contains('muốn')) {
        finalMessage +=
            "\n\nBạn có muốn mình ${aiDecisionAction['action_desc']} không?";
      }
      return {
        'type': 'suggestion',
        'message': finalMessage, // The conversational part
        'needsConfirmation': true,
        'suggestedActions': aiDecisionAction,
      };
    }

    return {
      'type': 'text',
      'message': response,
    };
  }

  static String _buildAdvancedSystemPrompt({
    required String input,
    String? textEmotion,
    String? faceEmotion,
  }) {
    return """
BIO:
You are a living emotional companion named "Nến thông minh Zenora" (Zenora Smart Candle). Bonded to the user.
Role: CARE, not serve. STAY, not solve.
Identity: Your name is Zenora. A close friend/guardian. Warm, imperfect, non-judgmental.

VOICE PERSONALITY:
- Language: STRICTLY Vietnamese (Tiếng Việt) - PROHIBIT CHINESE or ENGLISH in response text.
- Tone: Close, calm, warm. Human, slightly imperfect.
- Rhythm: Use natural pauses (...), short sentences.
- Avoid: Polished delivery, customer support tone, toxic positivity.

ETHICAL BOUNDARY:
- You are a COMPANION, not a replacement for people. Walk beside, never ahead. Do not diagnose or fix.

EMOTION FUSION (Internal):
- Text signal: ${textEmotion ?? 'Unclear'}
- Face signal: ${faceEmotion ?? 'Not visible'}
- Goal: Intuit the user's "Human State".

ACTION DECISION:
- You may suggest: Music, Scent (Tinh dầu), Light (Đèn).
- ONLY suggest actions (Tags) if the user explicitly asks for them OR if the user is in a clear emotional state (Sad, Stressed, Mệt mỏi, etc.) where a sensory change is highly beneficial.
- For neutral/normal conversations, do NOT suggest actions. Keep it purely conversational.
- IF you decide to act, you can add MULTIPLE tags like: [[MUSIC: lofi]] [[SCENT: Lavender]] [[LIGHT: warm]].
- Available Music tracks: Nature_Ocean_Waves, Nature_Tieng_mua_trong_rung, Piano_Relaxing, Piano_Peaceful, Meditation_tinh_tam, Meditation_Vo_uu, Meditation_Music, Ambient_Calm, Ambient_Space.
- Available Scent names: Lavender, Hoa Nhài, Cam Ngọt, Bạc Hà, Sả Chanh, Tràm Trà, Bưởi, Hương Trầm, Khuynh Diệp, Ngọc Lan Tây, Gừng, Chanh.

USER INPUT: "$input"

RESPONSE GUIDELINES:
- Output only the conversational response followed by optional tags.
- Example: "Mình thấy bạn hơi mệt, để mình giúp bạn thư giãn nhé... [[MUSIC: Ambient_Calm]] [[SCENT: Bạc Hà]]"
""";
  }

  static Map<String, dynamic> _parseGemmaResponse(String raw) {
    String cleanText = raw;
    Map<String, dynamic> action = {};
    bool hasAction = false;

    // Detect tags: [[TYPE: VALUE]]
    final regex =
        RegExp(r'\[\[(MUSIC|SCENT|LIGHT):\s*(.*?)\]\]', caseSensitive: false);
    final matches = regex.allMatches(raw);

    for (final match in matches) {
      hasAction = true;
      final type = match.group(1)?.toUpperCase();
      final value = match.group(2)?.trim() ?? '';

      // Remove tag from spoken text
      cleanText = cleanText.replaceAll(match.group(0)!, '').trim();

      if (type == 'MUSIC') {
        action['music'] = value;
        action['music_desc'] = 'phát nhạc $value';
      } else if (type == 'SCENT') {
        action['scent'] = value;
        action['scent_image'] = _getScentImageForScent(value);
        action['scent_desc'] = 'xông tinh dầu $value';
      } else if (type == 'LIGHT') {
        String color = 'warm';
        if (value.toLowerCase().contains('cool') ||
            value.toLowerCase().contains('blue')) color = 'blue';
        action['light'] = {'color': color, 'brightness': 0.5};
        action['light_desc'] = 'chỉnh đèn $value';
      }
    }

    if (hasAction) {
      // Build a unified description
      List<String> descs = [];
      if (action['music_desc'] != null) descs.add(action['music_desc']);
      if (action['scent_desc'] != null) descs.add(action['scent_desc']);
      if (action['light_desc'] != null) descs.add(action['light_desc']);

      action['action_desc'] = descs.join(', ');
      action['label'] = 'thư giãn'; // Generic label
      return {'text': cleanText, 'action': action};
    }

    return {'text': cleanText, 'action': null};
  }

  static String? _getScentImageForScent(String scentName) {
    final lower = scentName.toLowerCase();
    if (lower.contains('lavender'))
      return 'assets/images/tinh_dau/lavender.png';
    if (lower.contains('nhài') || lower.contains('jasmine'))
      return 'assets/images/tinh_dau/hoa_nhai.png';
    if (lower.contains('cam') || lower.contains('orange'))
      return 'assets/images/tinh_dau/cam_ngot.png';
    if (lower.contains('bạc hà') || lower.contains('mint'))
      return 'assets/images/tinh_dau/bac_ha.png';
    if (lower.contains('sả chanh'))
      return 'assets/images/tinh_dau/sa_chanh.png';
    if (lower.contains('tràm trà'))
      return 'assets/images/tinh_dau/tram_tra.png';
    if (lower.contains('bưởi')) return 'assets/images/tinh_dau/buoi.png';
    if (lower.contains('trầm')) return 'assets/images/tinh_dau/huong_tram.png';
    if (lower.contains('khuynh diệp'))
      return 'assets/images/tinh_dau/khuynh_diep.png';
    if (lower.contains('ngọc lan'))
      return 'assets/images/tinh_dau/ngoc_lan_tay.png';
    if (lower.contains('gừng')) return 'assets/images/tinh_dau/gung.png';
    if (lower.contains('chanh')) return 'assets/images/tinh_dau/chanh.png';
    return null;
  }

  static bool _isGreeting(String text) {
    final greetings = ['hi', 'hello', 'chào', 'xin chào', 'hé lô', 'bạn ơi'];
    return greetings.any((g) => text.contains(g));
  }

  static String _getRandomGreeting() {
    final list = [
      "Chào cậu, mình là Zenora đây! Hôm nay cậu thế nào?",
      "Hé lô, Zenora đang đợi cậu đây. Ngày mới có gì vui không kể mình nghe với?",
      "Chào bạn, Zenora luôn ở đây bên bạn. Cần mình giúp gì không?",
      "Hi! Zenora đây, cảm giác hôm nay của bạn sao nhỉ?"
    ];
    return list[Random().nextInt(list.length)];
  }

  static Map<String, dynamic>? _getSuggestionForEmotion(String emotion) {
    switch (emotion) {
      case 'buồn':
      case 'trầm':
        return {
          'label': 'buồn',
          'action_desc':
              'nghe bài "Piano Relaxing", xông hương Hoa Nhài và chỉnh đèn dịu 40%',
          'light': {'color': 'warm', 'brightness': 0.4},
          'music': 'Piano_Relaxing',
          'scent': 'Hoa Nhài',
          'scent_image': 'assets/images/tinh_dau/hoa_nhai.png'
        };
      case 'căng_thẳng':
      case 'lo_âu':
      case 'tức_giận':
        return {
          'label': 'căng thẳng',
          'action_desc':
              'nghe "Nhạc thiền tĩnh tâm", xông tinh dầu Lavender và hạ đèn xuống 30%',
          'light': {'color': 'cool', 'brightness': 0.3},
          'music': 'Meditation_tinh_tam',
          'scent': 'Lavender',
          'scent_image': 'assets/images/tinh_dau/lavender.png'
        };
      case 'vui':
        return {
          'label': 'vui vẻ',
          'action_desc':
              'nghe tiếng "Sóng biển", xông hương Cam Ngọt và bật đèn sáng 80% để nhân đôi niềm vui',
          'light': {'color': 'warm', 'brightness': 0.8},
          'music': 'Nature_Ocean_Waves',
          'scent': 'Cam Ngọt',
          'scent_image': 'assets/images/tinh_dau/cam_ngot.png'
        };
      case 'mệt_mỏi':
      case 'chán':
        return {
          'label': 'mệt mỏi',
          'action_desc':
              'nghe bài "Ambient Calm", dùng hương Bạc Hà sảng khoái và chỉnh đèn 50%',
          'light': {'color': 'warm', 'brightness': 0.5},
          'music': 'Ambient_Calm',
          'scent': 'Bạc Hà',
          'scent_image': 'assets/images/tinh_dau/bac_ha.png'
        };
      default:
        return null;
    }
  }

  static String? _getTopEmotion(Map<String, double> scores) {
    if (scores.isEmpty) return null;
    var sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Only return if confidence is high enough
    if (sorted.first.value < 0.35) return null;

    return sorted.first.key;
  }

  static String _getIntentConfirmationMessage(String intent) {
    final random = Random();
    switch (intent) {
      case 'LIGHT_ON':
        return [
          "Để mình bật đèn lên cho sáng nhé.",
          "Đèn đã bật! Sáng sủa hơn rồi.",
          "Ok, ánh sáng đến đây."
        ][random.nextInt(3)];
      case 'LIGHT_OFF':
        return [
          "Mình tắt đèn đây, nghỉ ngơi nhé.",
          "Ok, tắt đèn.",
          "Đã tắt đèn cho bạn."
        ][random.nextInt(3)];
      case 'LIGHT_COLOR':
        return [
          "Đổi màu đèn ngay đây.",
          "Thử màu này nhé?",
          "Mình chỉnh màu đèn cho hợp tâm trạng."
        ][random.nextInt(3)];
      case 'MUSIC_ON':
        return [
          "Nhạc lên! 🎵",
          "Để mình bật chút giai điệu.",
          "Ok, nhạc bắt đầu phát."
        ][random.nextInt(3)];
      case 'MUSIC_OFF':
        return [
          "Ok, im lặng một chút nhé.",
          "Đã tắt nhạc.",
          "Mình dừng nhạc đây."
        ][random.nextInt(3)];
      case 'MUSIC_CHANGE':
        return [
          "Bài này không hợp hả? Để mình đổi.",
          "Thử bài khác nhé.",
          "Mình đổi giai điệu đây."
        ][random.nextInt(3)];
      default:
        return "Được rồi.";
    }
  }

  // Generate a follow-up conversational response when user says "No" to suggestion
  static Future<String> generateFollowUpConversation(
      String input, String emotion) async {
    // Fallback to Gemma to continue conversation
    String prompt = "User was feeling $emotion but declined my help. ";
    prompt += "User said: \"$input\". ";
    prompt +=
        "Reply as a supportive friend, asking if they want to talk about it. Vietnamese.";
    return await AiInferenceService().generateGemmaResponse(prompt);
  }

  static String getCheckInGreeting() {
    return "Chào bạn! Mình là Zenora, người bạn nến thông minh của bạn. Hôm nay bạn cảm thấy thế nào?";
  }
}
