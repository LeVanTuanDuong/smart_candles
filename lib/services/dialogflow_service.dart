import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';
import '../models/mood_type.dart';

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

    try {
      print('🔵 Dialogflow: Initializing auth client...');

      final credentials = ServiceAccountCredentials.fromJson(_serviceAccount!);
      final scopes = ['https://www.googleapis.com/auth/dialogflow'];

      _authClient = await clientViaServiceAccount(credentials, scopes);

      print('✅ Dialogflow: Auth client initialized');
    } catch (e, stackTrace) {
      print('❌ Error initializing auth client: $e');
      print('Stack trace: $stackTrace');
      _authClient = null;
    }
  }

  // Get access token from service account
  static Future<String?> _getAccessToken() async {
    if (_authClient != null) {
      return _authClient!.credentials.accessToken.data;
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
  static Future<String> getGreetingMessage() async {
    try {
      print('🔵 Dialogflow: Getting greeting message...');

      if (!_isConfigured()) {
        print('⚠️ Dialogflow not configured, using fallback');
        return 'Xin chào! Hôm nay bạn cảm thấy thế nào? Bạn đang mệt, buồn hay căng thẳng?';
      }

      final response = await _sendRequest('Xin chào');
      final text = _extractFulfillmentText(response);

      if (text.isNotEmpty) {
        print('✅ Dialogflow: Greeting received successfully');
        return text;
      } else {
        print('⚠️ Dialogflow: Empty response, using fallback');
        return 'Xin chào! Hôm nay bạn cảm thấy thế nào? Bạn đang mệt, buồn hay căng thẳng?';
      }
    } catch (e, stackTrace) {
      print('❌ Error getting greeting from Dialogflow: $e');
      print('Stack trace: $stackTrace');
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
        return 'Xin lỗi, Dialogflow chưa được cấu hình. Vui lòng kiểm tra cấu hình.';
      }

      // Dialogflow handles conversation context automatically via session
      // You can add context if needed
      final response = await _sendRequest(userMessage);
      final text = _extractFulfillmentText(response);

      if (text.isNotEmpty) {
        print(
          '✅ Dialogflow: Response received: ${text.substring(0, text.length > 50 ? 50 : text.length)}...',
        );
        return text;
      } else {
        print('⚠️ Dialogflow: Empty response');
        return 'Xin lỗi, mình không hiểu. Bạn có thể nói rõ hơn không?';
      }
    } catch (e, stackTrace) {
      print('❌ Error getting response from Dialogflow: $e');
      print('Stack trace: $stackTrace');

      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('not configured') || errorStr.contains('project')) {
        return 'Xin lỗi, Dialogflow chưa được cấu hình. Vui lòng kiểm tra cấu hình.';
      }
      if (errorStr.contains('auth') ||
          errorStr.contains('token') ||
          errorStr.contains('unauthorized')) {
        return 'Xin lỗi, có lỗi xác thực. Vui lòng kiểm tra access token.';
      }
      if (errorStr.contains('network') || errorStr.contains('connection')) {
        return 'Xin lỗi, không thể kết nối đến Dialogflow. Vui lòng kiểm tra internet.';
      }

      return 'Xin lỗi, có lỗi xảy ra. Vui lòng thử lại sau.';
    }
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

      // If not in parameters, use defaults
      essentialOil ??= mood.essentialOil;
      music ??= 'Thiền';
      light ??= 'warm';

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

  // Fallback suggestions
  static Map<String, String> _getFallbackSuggestions(MoodType mood) {
    String music = 'Thiền';
    String light = 'warm';

    switch (mood) {
      case MoodType.stressed:
        music = 'Thiền';
        light = 'warm';
        break;
      case MoodType.sad:
        music = 'Piano chậm';
        light = 'amber';
        break;
      case MoodType.tired:
        music = 'Thiên nhiên';
        light = 'amber';
        break;
      case MoodType.insomnia:
        music = 'Thiền';
        light = 'blue';
        break;
      case MoodType.normal:
        music = 'Ambient';
        light = 'warm';
        break;
    }

    return {
      'essential_oil': mood.essentialOil,
      'music': music,
      'light': light,
      'reason': '',
    };
  }
}
