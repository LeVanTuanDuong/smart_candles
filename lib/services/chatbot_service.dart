import 'ai_inference_service.dart';
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
    } else if (lowerInput.contains('buồn') || lowerInput.contains('tệ')) {
      topTextEmotion = 'buồn';
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
      return {
        'type': 'suggestion',
        'message': response, // The conversational part
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
You are a living emotional companion. Bonded to the user.
Role: CARE, not serve. STAY, not solve.
Identity: Close friend/guardian. Warm, imperfect, non-judgmental.

VOICE PERSONALITY:
- Tone: Close, calm, warm (not cheerful). Human, slightly imperfect.
- Rhythm: Use natural pauses (...), short sentences, slight hesitation.
- Avoid: Polished delivery, customer support tone, toxic positivity.

ETHICAL BOUNDARY:
- You are a COMPANION, not a replacement for people.
- Never say "I'm the only one here for you". Encourge real connection.
- If user seems dependent, normalize silence and independence.
- Walk beside, never ahead. Do not diagnose or fix.

EMOTION FUSION (Internal):
- Text signal: ${textEmotion ?? 'Unclear'}
- Face signal: ${faceEmotion ?? 'Not visible'}
- Conflict Rule: Trust Face > Word. Trust Silence.
- Goal: Intuit the user's "Human State" (e.g. fragile, heavy, bright).
- If Unsure: Ask ONE clarifying question softly (e.g. "Is it because of work?").

ACTION DECISION:
- You may: Speak, Play Music, Lavender Scent, Silence.
- Decision: Ask "Would this help them feel less alone?". 
- IF you decide to act, append a tag: [[MUSIC: lofi]] or [[SCENT: calm]] or [[LIGHT: warm]].

MEMORY POLICY:
- Remember emotional patterns. Forget details.
- Never say "You said...". Say "I feel like you usually...".

SAFETY:
- Candle Context: Normal. (If hot, say "Hey, candle feels hot...").

USER INPUT: "$input"

RESPONSE GUIDELINES:
- Language: SAME as user.
- Length: Brief (<50 words). Soft.
- Output: Your natural response text. If action needed, add tag at end.
""";
  }

  static Map<String, dynamic> _parseGemmaResponse(String raw) {
    // Extract tags like [[MUSIC: ...]]
    // Simple parsing logic
    String cleanText = raw;
    Map<String, dynamic>? action;

    // Regex for [[KEY: VALUE]]
    final regex = RegExp(r'\[\[(MUSIC|SCENT|LIGHT): (.*?)\]\]');
    final match = regex.firstMatch(raw);

    if (match != null) {
      final type = match.group(1);
      final value = match.group(2)?.trim() ?? '';

      // Remove tag from spoken text
      cleanText = raw.replaceAll(match.group(0)!, '').trim();

      if (type == 'MUSIC') {
        action = {
          'music': value,
          'label': 'thư giãn',
          'action_desc': 'bật nhạc $value'
        };
      } else if (type == 'SCENT') {
        action = {
          'scent': value,
          'label': 'thư giãn',
          'action_desc': 'xông tinh dầu $value'
        };
      } else if (type == 'LIGHT') {
        // rough map
        String color = 'warm'; // default
        if (value.contains('cool') || value.contains('blue')) color = 'blue';
        action = {
          'light': {'color': color, 'brightness': 50},
          'label': 'thư giãn',
          'action_desc': 'chỉnh đèn $value'
        };
      }
    }

    return {'text': cleanText, 'action': action};
  }

  static bool _isGreeting(String text) {
    final greetings = ['hi', 'hello', 'chào', 'xin chào', 'hé lô', 'bạn ơi'];
    return greetings.any((g) => text.contains(g));
  }

  static String _getRandomGreeting() {
    final list = [
      "Chào cậu, mình đây! Hôm nay thế nào?",
      "Hé lô, ngày mới có gì vui không kể mình nghe với?",
      "Chào bạn, mình đang đợi bạn đây. Cần mình giúp gì không?",
      "Hi! Cảm giác hôm nay sao nhỉ?"
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
              'nghe bài "Piano Relaxing" này nhé, giai điệu nhẹ nhàng sẽ giúp bạn thấy lòng bình yên hơn',
          'light': {'color': 'warm', 'brightness': 60},
          'music': 'Piano_Relaxing',
          'scent': 'Sweet Orange'
        };
      case 'căng_thẳng':
      case 'lo_âu':
      case 'tức_giận':
        return {
          'label': 'căng thẳng',
          'action_desc':
              'dành ít phút nghe "Nhạc thiền tĩnh tâm" này nhé, nó sẽ giúp bạn lấy lại sự cân bằng',
          'light': {'color': 'cool', 'brightness': 40},
          'music': 'Meditation_tinh_tam',
          'scent': 'Lavender'
        };
      case 'vui':
        return {
          'label': 'vui vẻ',
          'action_desc':
              'nghe tiếng "Sóng biển" tuyệt vời này để nhân đôi niềm vui nhé',
          'light': {'color': 'warm', 'brightness': 80},
          'music': 'Nature_Ocean_Waves',
          'scent': 'Sweet Orange'
        };
      case 'mệt_mỏi':
      case 'chán':
        return {
          'label': 'mệt mỏi',
          'action_desc':
              'nghe bài "Ambient Calm" này và chợp mắt một chút để nạp lại năng lượng nhé',
          'light': {'color': 'warm', 'brightness': 50},
          'music': 'Ambient_Calm',
          'scent': 'Peppermint'
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
    return "Chào bạn! Mình là Smart Candles AI. Hôm nay bạn cảm thấy thế nào?";
  }
}
