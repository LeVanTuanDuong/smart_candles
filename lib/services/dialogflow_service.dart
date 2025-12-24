import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';
import '../models/mood_type.dart';
import 'chatbot_flow_service.dart';

class DialogflowService {
  // Dialogflow configuration
  // TODO: Replace with your Dialogflow project credentials
  static const String _projectId = 'arched-forest-466908-e1';
  static const String _sessionId = 'smart-candles-session';
  static const String _languageCode = 'vi'; // Vietnamese

  // For authentication, you can use:
  // 1. Service Account JSON (recommended for production)
  // 2. Access Token (for testing)
  static String? _accessToken;

  // Base URL for Dialogflow API
  static String get _baseUrl =>
      'https://dialogflow.googleapis.com/v2/projects/$_projectId/agent/sessions/$_sessionId:detectIntent';

  // Verify configuration
  static bool _isConfigured() {
    return _projectId.isNotEmpty &&
        _projectId != 'YOUR_PROJECT_ID' &&
        (_accessToken != null || _hasServiceAccount());
  }

  // Service account credentials
  static Map<String, dynamic>? _serviceAccount;
  static AutoRefreshingAuthClient? _authClient;
  static bool _isOffline =
      false; // Track offline state to avoid repeated attempts

  // Check if service account is configured
  static bool _hasServiceAccount() {
    return _serviceAccount != null || _authClient != null;
  }

  // Load service account from assets
  static Future<void> loadServiceAccount() async {
    try {
      print('🔵 Dialogflow: Loading service account...');
      final String jsonString = await rootBundle.loadString(
        'assets/arched-forest-466908-e1-fa53be0999ef.json',
      );
      _serviceAccount = jsonDecode(jsonString) as Map<String, dynamic>;
      print('✅ Dialogflow: Service account loaded');

      // Initialize auth client
      await _initializeAuthClient();
    } catch (e, stackTrace) {
      print('❌ Error loading service account: $e');
      print('Stack trace: $stackTrace');
      _serviceAccount = null;
    }
  }

  // Initialize authentication client
  static Future<void> _initializeAuthClient() async {
    if (_serviceAccount == null) return;

    // Skip if we know we're offline
    if (_isOffline) {
      return;
    }

    try {
      print('🔵 Dialogflow: Initializing auth client...');

      final credentials = ServiceAccountCredentials.fromJson(_serviceAccount!);
      final scopes = ['https://www.googleapis.com/auth/dialogflow'];

      _authClient = await clientViaServiceAccount(credentials, scopes);

      print('✅ Dialogflow: Auth client initialized');
      _isOffline = false; // Reset offline flag on success
    } catch (e, stackTrace) {
      // Check if it's a network error
      final errorStr = e.toString().toLowerCase();
      final isNetworkError =
          errorStr.contains('socketexception') ||
          errorStr.contains('failed host lookup') ||
          errorStr.contains('network') ||
          errorStr.contains('connection');

      if (isNetworkError) {
        if (!_isOffline) {
          // Only log once when first detecting offline
          print(
            '⚠️ Network error detected - device is offline. Dialogflow will use fallback responses.',
          );
          _isOffline = true;
        }
        // Don't print full error stack when offline to reduce log noise
      } else {
        // Log non-network errors normally
        print('❌ Error initializing auth client: $e');
        print('Stack trace: $stackTrace');
      }

      _authClient = null;
    }
  }

  // Get access token from service account
  static Future<String?> _getAccessToken() async {
    if (_authClient != null) {
      return _authClient!.credentials.accessToken.data;
    }

    // Skip if offline to avoid repeated failed attempts
    if (_isOffline) {
      return null;
    }

    // Try to initialize if not already done
    if (_serviceAccount != null && _authClient == null) {
      await _initializeAuthClient();
      if (_authClient != null) {
        return _authClient!.credentials.accessToken.data;
      }
    }

    return null;
  }

  // Set access token (for testing)
  static void setAccessToken(String token) {
    _accessToken = token;
  }

  // Get authentication header
  static Future<Map<String, String>> _getHeaders() async {
    final headers = <String, String>{'Content-Type': 'application/json'};

    // Try to get access token from service account first
    String? token = _accessToken;
    if (token == null && _hasServiceAccount()) {
      token = await _getAccessToken();
    }

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // Send request to Dialogflow
  static Future<Map<String, dynamic>> _sendRequest(
    String queryText, {
    Map<String, dynamic>? context,
  }) async {
    if (!_isConfigured()) {
      throw Exception(
        'Dialogflow is not configured. Please set project ID and access token.',
      );
    }

    try {
      print('🔵 Dialogflow: Sending request: "$queryText"');

      final body = {
        'queryInput': {
          'text': {'text': queryText, 'languageCode': _languageCode},
        },
        'queryParams': {'timeZone': 'Asia/Ho_Chi_Minh'},
      };

      if (context != null) {
        body['queryParams'] = {
          ...body['queryParams'] as Map,
          'contexts': [context],
        };
      }

      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: headers,
        body: jsonEncode(body),
      );

      print('📊 Dialogflow: Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        print('✅ Dialogflow: Request successful');
        return data;
      } else {
        print('❌ Dialogflow: Error response: ${response.body}');
        throw Exception(
          'Dialogflow API error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e, stackTrace) {
      print('❌ Error sending request to Dialogflow: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Extract fulfillment text from Dialogflow response
  static String _extractFulfillmentText(Map<String, dynamic> response) {
    try {
      final queryResult = response['queryResult'] as Map<String, dynamic>?;
      if (queryResult != null) {
        final fulfillmentText = queryResult['fulfillmentText'] as String?;
        if (fulfillmentText != null && fulfillmentText.isNotEmpty) {
          return fulfillmentText;
        }

        // Try to get from fulfillment messages
        final fulfillmentMessages = queryResult['fulfillmentMessages'] as List?;
        if (fulfillmentMessages != null && fulfillmentMessages.isNotEmpty) {
          final firstMessage = fulfillmentMessages[0] as Map<String, dynamic>;
          final text = firstMessage['text'] as Map<String, dynamic>?;
          if (text != null) {
            final textValues = text['text'] as List?;
            if (textValues != null && textValues.isNotEmpty) {
              return textValues[0] as String;
            }
          }
        }
      }

      return 'Xin lỗi, mình không hiểu. Bạn có thể nói rõ hơn không?';
    } catch (e) {
      print('⚠️ Error extracting fulfillment text: $e');
      return 'Xin lỗi, có lỗi xảy ra khi xử lý phản hồi.';
    }
  }

  // Extract intent from Dialogflow response
  static String? _extractIntent(Map<String, dynamic> response) {
    try {
      final queryResult = response['queryResult'] as Map<String, dynamic>?;
      if (queryResult != null) {
        final intent = queryResult['intent'] as Map<String, dynamic>?;
        if (intent != null) {
          return intent['displayName'] as String?;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Extract parameters from Dialogflow response
  static Map<String, dynamic> _extractParameters(
    Map<String, dynamic> response,
  ) {
    try {
      final queryResult = response['queryResult'] as Map<String, dynamic>?;
      if (queryResult != null) {
        final parameters = queryResult['parameters'] as Map<String, dynamic>?;
        return parameters ?? {};
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  // Get greeting message from Dialogflow
  static Future<String> getGreetingMessage({bool isFirstTime = false}) async {
    try {
      print('🔵 Dialogflow: Getting greeting message...');

      // Use ChatbotFlowService for structured greetings
      if (isFirstTime) {
        return ChatbotFlowService.getOnboardingGreeting();
      }

      if (!_isConfigured()) {
        print('⚠️ Dialogflow not configured, using fallback');
        return ChatbotFlowService.getCheckInGreeting();
      }

      final response = await _sendRequest('Xin chào');
      final text = _extractFulfillmentText(response);

      if (text.isNotEmpty) {
        print('✅ Dialogflow: Greeting received successfully');
        return text;
      } else {
        print('⚠️ Dialogflow: Empty response, using fallback');
        return ChatbotFlowService.getCheckInGreeting();
      }
    } catch (e, stackTrace) {
      // Check if it's a network error
      final errorStr = e.toString().toLowerCase();
      final isNetworkError =
          errorStr.contains('socketexception') ||
          errorStr.contains('failed host lookup') ||
          errorStr.contains('network') ||
          errorStr.contains('connection') ||
          errorStr.contains('offline');

      if (isNetworkError) {
        if (!_isOffline) {
          print('⚠️ Network error - using offline fallback');
          _isOffline = true;
        }
        // Don't print full error when offline
      } else {
        print('❌ Error getting greeting from Dialogflow: $e');
        print('Stack trace: $stackTrace');
      }

      return 'Xin chào! Hôm nay bạn cảm thấy thế nào? Bạn đang mệt, buồn hay căng thẳng?';
    }
  }

  // Get response from Dialogflow
  static Future<String> getResponse(
    String userMessage, {
    List<String>? conversationHistory,
  }) async {
    try {
      print('🔵 Dialogflow: Getting response for: "$userMessage"');

      if (!_isConfigured()) {
        print('⚠️ Dialogflow not configured, using fallback');
        return _getFallbackResponse(userMessage);
      }

      // Add context to help Dialogflow understand this is a psychological chatbot
      final context = {
        'name': 'chatbot_context',
        'lifespanCount': 5,
        'parameters': {
          'bot_type': 'psychological_chatbot',
          'app_name': 'Smart Candles',
          'purpose': 'help_user_relax_and_improve_mood',
        },
      };

      // Dialogflow handles conversation context automatically via session
      final response = await _sendRequest(userMessage, context: context);
      var text = _extractFulfillmentText(response);

      // Filter and improve response
      text = _filterAndImproveResponse(text, userMessage);

      if (text.isNotEmpty) {
        print(
          '✅ Dialogflow: Response received: ${text.substring(0, text.length > 50 ? 50 : text.length)}...',
        );
        return text;
      } else {
        print('⚠️ Dialogflow: Empty response');
        return _getFallbackResponse(userMessage);
      }
    } catch (e, stackTrace) {
      // Check if it's a network error
      final errorStr = e.toString().toLowerCase();
      final isNetworkError =
          errorStr.contains('socketexception') ||
          errorStr.contains('failed host lookup') ||
          errorStr.contains('network') ||
          errorStr.contains('connection') ||
          errorStr.contains('offline');

      if (isNetworkError) {
        if (!_isOffline) {
          print('⚠️ Network error - device is offline, using fallback');
          _isOffline = true;
        }
        // Use fallback response instead of error message
        return _getFallbackResponse(userMessage);
      }

      // Log non-network errors
      print('❌ Error getting response from Dialogflow: $e');
      print('Stack trace: $stackTrace');

      // Always use fallback response instead of showing technical errors to users
      return _getFallbackResponse(userMessage);
    }
  }

  // Filter and improve response to be more appropriate
  static String _filterAndImproveResponse(String response, String userMessage) {
    if (response.isEmpty) return response;

    var improvedResponse = response;

    // Remove inappropriate phrases for text chatbot
    final inappropriatePhrases = [
      'Tôi chưa nghe rõ',
      'chưa nghe rõ',
      'không nghe rõ',
      'bạn có thể nhắc lại',
      'bạn có thể nói lại',
      'tôi không nghe được',
    ];

    for (var phrase in inappropriatePhrases) {
      if (improvedResponse.toLowerCase().contains(phrase.toLowerCase())) {
        // Replace with more appropriate response
        improvedResponse =
            'Mình hiểu bạn đang muốn chia sẻ. Bạn có thể nói rõ hơn về cảm xúc của mình không?';
        break;
      }
    }

    // Ensure response is appropriate for psychological chatbot
    if (improvedResponse.length < 10) {
      // If response is too short, provide a more helpful response
      final userLower = userMessage.toLowerCase();
      if (userLower.contains('buồn') || userLower.contains('sad')) {
        improvedResponse =
            'Mình hiểu bạn đang cảm thấy buồn. Hãy để mình giúp bạn cảm thấy tốt hơn nhé.';
      } else if (userLower.contains('mệt') || userLower.contains('tired')) {
        improvedResponse =
            'Bạn trông mệt mỏi rồi. Hãy thư giãn và để cơ thể được nghỉ ngơi nhé.';
      } else if (userLower.contains('căng thẳng') ||
          userLower.contains('stressed')) {
        improvedResponse =
            'Mình thấy bạn đang khá căng thẳng. Điều này hoàn toàn bình thường. Hãy hít thở sâu cùng mình nhé.';
      } else if (userLower.contains('khó ngủ') ||
          userLower.contains('mất ngủ') ||
          userLower.contains('insomnia')) {
        improvedResponse =
            'Khó ngủ có thể khiến bạn căng thẳng. Hãy để mình giúp bạn thư giãn và chuẩn bị cho giấc ngủ ngon.';
      } else {
        improvedResponse =
            'Mình hiểu bạn. Hãy cho mình biết thêm về cảm xúc của bạn nhé.';
      }
    }

    return improvedResponse;
  }

  // Get fallback response based on user message (public for use in error handling)
  static String getFallbackResponse(String userMessage) {
    return _getFallbackResponse(userMessage);
  }

  // Get fallback response based on user message
  static String _getFallbackResponse(String userMessage) {
    final userLower = userMessage.toLowerCase();

    // Use ChatbotFlowService for mood detection and responses
    MoodType? detectedMood;

    // Check for stress/anxiety (including variations with /)
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

  // Analyze mood from user message
  static Future<MoodType?> analyzeMood(String userMessage) async {
    try {
      print('🔵 Dialogflow: Analyzing mood from: "$userMessage"');

      if (!_isConfigured()) {
        print('⚠️ Dialogflow not configured, using fallback');
        return _analyzeMoodFallback(userMessage);
      }

      // Create a specific intent for mood detection
      final response = await _sendRequest(userMessage);
      final intent = _extractIntent(response);
      final parameters = _extractParameters(response);

      print('📊 Dialogflow: Intent: $intent, Parameters: $parameters');

      // Map Dialogflow intent to MoodType
      MoodType? mood;
      if (intent != null) {
        final intentLower = intent.toLowerCase();
        if (intentLower.contains('stressed') ||
            intentLower.contains('căng thẳng') ||
            intentLower.contains('lo âu')) {
          mood = MoodType.stressed;
        } else if (intentLower.contains('sad') ||
            intentLower.contains('buồn') ||
            intentLower.contains('trầm cảm')) {
          mood = MoodType.sad;
        } else if (intentLower.contains('tired') ||
            intentLower.contains('mệt')) {
          mood = MoodType.tired;
        } else if (intentLower.contains('insomnia') ||
            intentLower.contains('khó ngủ') ||
            intentLower.contains('mất ngủ')) {
          mood = MoodType.insomnia;
        } else if (intentLower.contains('normal') ||
            intentLower.contains('bình thường') ||
            intentLower.contains('tốt')) {
          mood = MoodType.normal;
        }
      }

      // Also check parameters for mood
      if (mood == null) {
        final moodParam = parameters['mood'] as String?;
        if (moodParam != null) {
          mood = _parseMoodFromString(moodParam);
        }
      }

      // Fallback to text analysis if intent/parameters don't provide mood
      if (mood == null) {
        mood = _analyzeMoodFallback(userMessage);
      }

      if (mood != null) {
        print('✅ Dialogflow: Mood detected: ${mood.label}');
      } else {
        print('⚠️ Dialogflow: Could not detect mood');
      }

      return mood;
    } catch (e, stackTrace) {
      print('❌ Error analyzing mood from Dialogflow: $e');
      print('Stack trace: $stackTrace');
      return _analyzeMoodFallback(userMessage);
    }
  }

  // Fallback mood analysis using text matching
  static MoodType? _analyzeMoodFallback(String userMessage) {
    final messageLower = userMessage.toLowerCase();

    if (messageLower.contains('căng thẳng') ||
        messageLower.contains('lo âu') ||
        messageLower.contains('stressed') ||
        messageLower.contains('anxious')) {
      return MoodType.stressed;
    } else if (messageLower.contains('buồn') ||
        messageLower.contains('trầm cảm') ||
        messageLower.contains('sad') ||
        messageLower.contains('depressed')) {
      return MoodType.sad;
    } else if (messageLower.contains('mệt') ||
        messageLower.contains('tired') ||
        messageLower.contains('exhausted')) {
      return MoodType.tired;
    } else if (messageLower.contains('khó ngủ') ||
        messageLower.contains('mất ngủ') ||
        messageLower.contains('insomnia') ||
        messageLower.contains('sleepless')) {
      return MoodType.insomnia;
    } else if (messageLower.contains('bình thường') ||
        messageLower.contains('tốt') ||
        messageLower.contains('normal') ||
        messageLower.contains('good') ||
        messageLower.contains('ok')) {
      return MoodType.normal;
    }

    return null;
  }

  // Parse mood from string
  static MoodType? _parseMoodFromString(String moodStr) {
    final moodLower = moodStr.toLowerCase();
    switch (moodLower) {
      case 'stressed':
      case 'căng thẳng':
      case 'lo âu':
        return MoodType.stressed;
      case 'sad':
      case 'buồn':
      case 'trầm cảm':
        return MoodType.sad;
      case 'tired':
      case 'mệt':
      case 'mệt mỏi':
        return MoodType.tired;
      case 'insomnia':
      case 'khó ngủ':
      case 'mất ngủ':
        return MoodType.insomnia;
      case 'normal':
      case 'bình thường':
      case 'tốt':
        return MoodType.normal;
      default:
        return null;
    }
  }

  // Get suggestions based on mood
  static Future<Map<String, String>> getSuggestions(MoodType mood) async {
    try {
      print('🔵 Dialogflow: Getting suggestions for mood: ${mood.label}');

      if (!_isConfigured()) {
        print('⚠️ Dialogflow not configured, using fallback');
        return _getFallbackSuggestions(mood);
      }

      // Query Dialogflow for suggestions based on mood
      final query = 'Gợi ý cho tâm trạng ${mood.label.toLowerCase()}';
      final response = await _sendRequest(query);
      final fulfillmentText = _extractFulfillmentText(response);
      final parameters = _extractParameters(response);

      // Extract suggestions from parameters or fulfillment text
      String? essentialOil = parameters['essential_oil'] as String?;
      String? music = parameters['music'] as String?;
      String? light = parameters['light'] as String?;

      // If not in parameters, try to parse from fulfillment text
      if (essentialOil == null || music == null) {
        final parsed = _parseSuggestionsFromText(fulfillmentText, mood);
        essentialOil ??= parsed['essential_oil'];
        music ??= parsed['music'];
        light ??= parsed['light'];
      }

      // If still not found, use defaults based on mood
      essentialOil ??= mood.essentialOil;
      music ??= _getDefaultMusicForMood(mood);
      light ??= _getDefaultLightForMood(mood);

      print(
        '✅ Dialogflow: Parsed suggestions - Oil: $essentialOil, Music: $music, Light: $light',
      );

      return {
        'essential_oil': essentialOil,
        'music': music,
        'light': light,
        'reason': fulfillmentText,
      };
    } catch (e, stackTrace) {
      print('❌ Error getting suggestions from Dialogflow: $e');
      print('Stack trace: $stackTrace');
      print('Using fallback suggestions');
      return _getFallbackSuggestions(mood);
    }
  }

  // Parse suggestions from fulfillment text
  static Map<String, String> _parseSuggestionsFromText(
    String text,
    MoodType mood,
  ) {
    final textLower = text.toLowerCase();
    final result = <String, String>{};

    // Parse essential oil
    final oilKeywords = {
      'lavender': 'Lavender',
      'sweet orange': 'Sweet Orange',
      'peppermint': 'Peppermint',
      'chamomile': 'Chamomile',
    };
    for (var entry in oilKeywords.entries) {
      if (textLower.contains(entry.key)) {
        result['essential_oil'] = entry.value;
        break;
      }
    }

    // Parse music type
    final musicKeywords = {
      'thiền': 'Thiền',
      'meditation': 'Thiền',
      'piano': 'Nhạc Piano',
      'piano chậm': 'Nhạc Piano',
      'thiên nhiên': 'Thiên nhiên',
      'nature': 'Thiên nhiên',
      'ambient': 'Ambient',
    };
    for (var entry in musicKeywords.entries) {
      if (textLower.contains(entry.key)) {
        result['music'] = entry.value;
        break;
      }
    }

    // Parse light mode
    if (textLower.contains('warm') || textLower.contains('ấm')) {
      result['light'] = 'warm';
    } else if (textLower.contains('amber') || textLower.contains('vàng')) {
      result['light'] = 'amber';
    } else if (textLower.contains('blue') || textLower.contains('xanh')) {
      result['light'] = 'blue';
    }

    return result;
  }

  // Get default music for mood
  static String _getDefaultMusicForMood(MoodType mood) {
    switch (mood) {
      case MoodType.stressed:
        return 'Thiền';
      case MoodType.sad:
        return 'Nhạc Piano';
      case MoodType.tired:
        return 'Thiên nhiên';
      case MoodType.insomnia:
        return 'Thiền';
      case MoodType.normal:
        return 'Ambient';
    }
  }

  // Get default light for mood
  static String _getDefaultLightForMood(MoodType mood) {
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

  // Fallback suggestions
  static Map<String, String> _getFallbackSuggestions(MoodType mood) {
    return {
      'essential_oil': mood.essentialOil,
      'music': _getDefaultMusicForMood(mood),
      'light': _getDefaultLightForMood(mood),
      'reason': '',
    };
  }
}
