import '../models/mood_type.dart';

/// Service to analyze user emotions using 6-layer logic system
/// Based on: Keywords, Sentiment, Intensity, Classification, Severity, Context
class EmotionAnalysisService {
  // LỚP 1: DỮ LIỆU ĐẦU VÀO
  
  /// Emotion keywords with weights
  static final Map<String, Map<String, int>> _emotionKeywords = {
    'buồn': {
      'buồn': 2,
      'chán': 2,
      'trống rỗng': 4,
      'cô đơn': 3,
      'tuyệt vọng': 6,
      'chỉ muốn biến mất': 8, // Risk flag
      'không muốn sống': 10, // High risk
      'muốn chết': 10, // High risk
      'trầm cảm': 5,
      'chán nản': 3,
      'thất vọng': 3,
      'đau khổ': 5,
    },
    'lo_âu': {
      'lo': 2,
      'sợ': 3,
      'căng thẳng': 3,
      'bất an': 3,
      'lo lắng': 2,
      'hoảng sợ': 6,
      'sợ hãi': 4,
      'bồn chồn': 2,
      'không yên': 2,
    },
    'mệt': {
      'mệt': 2,
      'kiệt sức': 4,
      'quá tải': 3,
      'mệt mỏi': 2,
      'cạn kiệt': 4,
      'không còn sức': 3,
      'burnout': 4,
    },
    'tức_giận': {
      'bực': 2,
      'cáu': 2,
      'tức': 3,
      'tức giận': 3,
      'phẫn nộ': 5,
      'khó chịu': 2,
    },
    'vui': {
      'vui': 2,
      'hạnh phúc': 3,
      'ổn': 1,
      'nhẹ nhõm': 2,
      'tốt': 1,
      'tuyệt vời': 3,
      'hài lòng': 2,
    },
  };

  /// Intensity modifiers
  static final Map<String, double> _intensityModifiers = {
    'rất': 1.5,
    'quá': 1.5,
    'cực kỳ': 2.0,
    'vô cùng': 2.0,
    'hơi': 0.7,
    'chút': 0.7,
    'một chút': 0.7,
    'khá': 1.2,
    'khá nhiều': 1.3,
  };

  /// Analyze emotion keywords from text
  static Map<String, double> _analyzeEmotionKeywords(String text) {
    final textLower = text.toLowerCase();
    final scores = <String, double>{};
    
    for (final emotionGroup in _emotionKeywords.entries) {
      double groupScore = 0;
      for (final keywordEntry in emotionGroup.value.entries) {
        final keyword = keywordEntry.key;
        final weight = keywordEntry.value;
        
        if (textLower.contains(keyword)) {
          // Check for intensity modifiers
          double modifier = 1.0;
          for (final modEntry in _intensityModifiers.entries) {
            if (textLower.contains('${modEntry.key} $keyword') ||
                textLower.contains('$keyword ${modEntry.key}')) {
              modifier = modEntry.value;
              break;
            }
          }
          
          groupScore += weight * modifier;
        }
      }
      
      if (groupScore > 0) {
        scores[emotionGroup.key] = groupScore;
      }
    }
    
    return scores;
  }

  /// Analyze sentiment polarity
  static int _analyzeSentiment(String text) {
    final textLower = text.toLowerCase();
    int score = 0;
    
    // Positive indicators
    final positiveWords = ['tốt', 'vui', 'hạnh phúc', 'ổn', 'tuyệt', 'tuyệt vời', 'hài lòng'];
    for (final word in positiveWords) {
      if (textLower.contains(word)) {
        score += 1;
      }
    }
    
    // Negative indicators
    final negativeWords = ['không tốt', 'chẳng', 'không có', 'không muốn', 'mệt', 'buồn'];
    for (final word in negativeWords) {
      if (textLower.contains(word)) {
        score -= 2;
      }
    }
    
    // Strong negative
    if (textLower.contains('quá') || textLower.contains('rất')) {
      score -= 1;
    }
    
    return score;
  }

  /// Analyze behavioral signals
  static double _analyzeBehavioralSignals({
    required int messageLength,
    required int responseTime, // seconds
    required String timeOfDay, // 'morning', 'afternoon', 'evening', 'night'
  }) {
    double score = 0;
    
    // Short messages might indicate fatigue or unwillingness to talk
    if (messageLength < 10) {
      score += 0.5;
    }
    
    // Night time might indicate stress or insomnia
    if (timeOfDay == 'night') {
      score += 0.3;
    }
    
    return score;
  }

  // LỚP 2: PHÂN LOẠI CẢM XÚC
  
  /// Classify emotions (multi-emotion support)
  static Map<String, double> classifyEmotions(Map<String, double> keywordScores) {
    // Normalize scores to 0-1 range
    final total = keywordScores.values.fold(0.0, (a, b) => a + b);
    if (total == 0) return {};
    
    final normalized = <String, double>{};
    for (final entry in keywordScores.entries) {
      normalized[entry.key] = entry.value / total;
    }
    
    // Sort by score
    final sorted = normalized.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Return top emotions
    final result = <String, double>{};
    for (final entry in sorted.take(3)) {
      result[entry.key] = entry.value;
    }
    
    return result;
  }

  // LỚP 3: ĐÁNH GIÁ MỨC ĐỘ
  
  /// Calculate Emotional Severity Score (ESS) 0-100
  static int calculateESS({
    required int? selfReport, // 0-10
    required Map<String, double> keywordScores,
    required int sentimentScore,
    required double behavioralScore,
  }) {
    // Self-report weight: 40%
    final selfReportScore = (selfReport ?? 5) * 10 * 0.4;
    
    // Keyword intensity weight: 30%
    final maxKeywordScore = keywordScores.values.isEmpty 
        ? 0 
        : keywordScores.values.reduce((a, b) => a > b ? a : b);
    final keywordScore = (maxKeywordScore / 10) * 100 * 0.3;
    
    // Sentiment score weight: 20%
    // Normalize sentiment (-10 to +10) to 0-100
    final sentimentNormalized = ((sentimentScore + 10) / 20) * 100;
    final sentimentWeighted = sentimentNormalized * 0.2;
    
    // Behavioral signal weight: 10%
    final behavioralWeighted = (behavioralScore / 1.0) * 100 * 0.1;
    
    final ess = (selfReportScore + keywordScore + sentimentWeighted + behavioralWeighted).round();
    
    // Clamp to 0-100
    return ess.clamp(0, 100);
  }

  /// Get severity level from ESS
  static String getSeverityLevel(int ess) {
    if (ess <= 20) return 'ổn';
    if (ess <= 40) return 'nhẹ';
    if (ess <= 60) return 'vừa';
    if (ess <= 80) return 'nặng';
    return 'nguy_cao';
  }

  // LỚP 4: NGỮ CẢNH
  
  /// Analyze context
  static Map<String, dynamic> analyzeContext({
    required String timeOfDay,
    required List<MoodType> recentMoods, // Last 3 days
    required bool isCandleOn,
    required bool isMusicPlaying,
  }) {
    final context = <String, dynamic>{};
    
    // Time context
    if (timeOfDay == 'night') {
      context['time_weight'] = 1.2; // Increase sadness/anxiety weight
    } else if (timeOfDay == 'morning') {
      context['time_weight'] = 1.1; // Increase fatigue weight
    } else {
      context['time_weight'] = 1.0;
    }
    
    // History context
    if (recentMoods.length >= 3) {
      final allSame = recentMoods.every((m) => m == recentMoods.first);
      if (allSame && recentMoods.first != MoodType.normal) {
        context['consecutive_days'] = true;
        context['alert_level'] = 'increased';
      }
    }
    
    // Device context
    context['candle_on'] = isCandleOn;
    context['music_playing'] = isMusicPlaying;
    
    return context;
  }

  // LỚP 5: SINH TRẮC HỌC (OPTIONAL)
  
  /// Analyze biometric data
  static Map<String, dynamic> analyzeBiometrics({
    int? heartRate,
    double? hrv,
    double? bodyTemperature,
  }) {
    final biometrics = <String, dynamic>{};
    
    if (heartRate != null) {
      // Normal resting HR: 60-100
      if (heartRate > 90) {
        biometrics['anxiety_indicators'] = (biometrics['anxiety_indicators'] ?? 0) + 1;
      }
    }
    
    if (hrv != null && hrv < 30) {
      // Low HRV indicates stress
      biometrics['stress_indicators'] = (biometrics['stress_indicators'] ?? 0) + 1;
    }
    
    if (bodyTemperature != null && bodyTemperature > 37.5) {
      // High body temp - avoid stimulating music
      biometrics['avoid_stimulating'] = true;
    }
    
    return biometrics;
  }

  // LỚP 6: DECISION ENGINE
  
  /// Main analysis function - combines all layers
  static EmotionAnalysisResult analyze({
    required String userMessage,
    required int? selfReport, // 0-10
    required String timeOfDay,
    List<MoodType> recentMoods = const [],
    bool isCandleOn = false,
    bool isMusicPlaying = false,
    Map<String, dynamic>? biometrics,
  }) {
    // Layer 1: Input signals
    final keywordScores = _analyzeEmotionKeywords(userMessage);
    final sentimentScore = _analyzeSentiment(userMessage);
    final behavioralScore = _analyzeBehavioralSignals(
      messageLength: userMessage.length,
      responseTime: 0, // Would need to track this
      timeOfDay: timeOfDay,
    );
    
    // Layer 2: Emotion classification
    final emotionClassification = classifyEmotions(keywordScores);
    
    // Layer 3: Severity scoring
    final ess = calculateESS(
      selfReport: selfReport,
      keywordScores: keywordScores,
      sentimentScore: sentimentScore,
      behavioralScore: behavioralScore,
    );
    final severityLevel = getSeverityLevel(ess);
    
    // Layer 4: Context
    final context = analyzeContext(
      timeOfDay: timeOfDay,
      recentMoods: recentMoods,
      isCandleOn: isCandleOn,
      isMusicPlaying: isMusicPlaying,
    );
    
    // Layer 5: Biometrics (if available)
    final biometricAnalysis = biometrics != null 
        ? analyzeBiometrics(
            heartRate: biometrics['heartRate'] as int?,
            hrv: biometrics['hrv'] as double?,
            bodyTemperature: biometrics['bodyTemperature'] as double?,
          )
        : <String, dynamic>{};
    
    // Layer 6: Decision
    final primaryEmotion = _getPrimaryEmotion(emotionClassification);
    final secondaryEmotion = _getSecondaryEmotion(emotionClassification);
    
    // Check for risk flags
    final hasRiskFlag = keywordScores.values.any((score) => score >= 8);
    
    return EmotionAnalysisResult(
      primaryEmotion: primaryEmotion,
      secondaryEmotion: secondaryEmotion,
      emotionScores: emotionClassification,
      ess: ess,
      severityLevel: severityLevel,
      shouldAskMore: ess < 40,
      shouldLimitQuestions: ess > 60,
      shouldActivateSafety: ess > 80 || hasRiskFlag,
      tone: _getTone(ess),
      context: context,
      biometrics: biometricAnalysis,
    );
  }

  /// Get primary emotion from classification
  static MoodType? _getPrimaryEmotion(Map<String, double> emotionClassification) {
    if (emotionClassification.isEmpty) return null;
    
    final sorted = emotionClassification.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final topEmotion = sorted.first.key;
    
    return mapEmotionKeyToMoodType(topEmotion);
  }

  /// Get secondary emotion
  static MoodType? _getSecondaryEmotion(Map<String, double> emotionClassification) {
    if (emotionClassification.length < 2) return null;
    
    final sorted = emotionClassification.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    if (sorted.length >= 2) {
      return mapEmotionKeyToMoodType(sorted[1].key);
    }
    
    return null;
  }

  /// Map emotion key to MoodType
  static MoodType? mapEmotionKeyToMoodType(String emotionKey) {
    switch (emotionKey) {
      case 'buồn':
        return MoodType.sad;
      case 'lo_âu':
        return MoodType.stressed;
      case 'mệt':
        return MoodType.tired;
      case 'tức_giận':
        return MoodType.stressed; // Anger maps to stressed
      case 'vui':
        return MoodType.normal;
      default:
        return null;
    }
  }

  /// Get tone based on ESS
  static String _getTone(int ess) {
    if (ess <= 40) return 'conversational';
    if (ess <= 60) return 'listening_guiding';
    return 'minimal_safe_grounding';
  }
}

/// Result of emotion analysis
class EmotionAnalysisResult {
  final MoodType? primaryEmotion;
  final MoodType? secondaryEmotion;
  final Map<String, double> emotionScores;
  final int ess; // Emotional Severity Score 0-100
  final String severityLevel; // 'ổn', 'nhẹ', 'vừa', 'nặng', 'nguy_cao'
  final bool shouldAskMore;
  final bool shouldLimitQuestions;
  final bool shouldActivateSafety;
  final String tone; // 'conversational', 'listening_guiding', 'minimal_safe_grounding'
  final Map<String, dynamic> context;
  final Map<String, dynamic> biometrics;

  EmotionAnalysisResult({
    required this.primaryEmotion,
    required this.secondaryEmotion,
    required this.emotionScores,
    required this.ess,
    required this.severityLevel,
    required this.shouldAskMore,
    required this.shouldLimitQuestions,
    required this.shouldActivateSafety,
    required this.tone,
    required this.context,
    required this.biometrics,
  });

  /// Get intensity level (0-10) from ESS
  int get intensityLevel {
    return (ess / 10).round().clamp(0, 10);
  }

  /// Check if risk flags are present
  bool get hasRiskFlags {
    return shouldActivateSafety;
  }
}

