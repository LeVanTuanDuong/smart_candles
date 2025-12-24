/// Service to manage conversation flow and prevent repetitive responses
/// Acts like a butler/butler - remembers context and avoids repetition
class ConversationManager {
  static final ConversationManager _instance = ConversationManager._internal();
  factory ConversationManager() => _instance;
  ConversationManager._internal();

  // Track recent responses to avoid repetition
  final List<String> _recentResponses = [];
  final int _maxRecentResponses = 10;
  
  // Track conversation context
  String? _lastTopic;
  int _repetitionCount = 0;
  final Map<String, int> _topicMentions = {};

  /// Check if a response is too similar to recent ones
  bool isResponseRepetitive(String response) {
    if (_recentResponses.isEmpty) return false;
    
    final responseLower = response.toLowerCase().trim();
    
    // Check exact match
    for (final recent in _recentResponses) {
      if (recent.toLowerCase().trim() == responseLower) {
        return true;
      }
    }
    
    // Check for high similarity (same first sentence)
    final firstSentence = _getFirstSentence(responseLower);
    if (firstSentence.length > 20) {
      for (final recent in _recentResponses) {
        final recentFirst = _getFirstSentence(recent.toLowerCase().trim());
        if (recentFirst.length > 20 && 
            _calculateSimilarity(firstSentence, recentFirst) > 0.8) {
          return true;
        }
      }
    }
    
    return false;
  }

  /// Add response to recent history
  void addResponse(String response) {
    _recentResponses.add(response);
    if (_recentResponses.length > _maxRecentResponses) {
      _recentResponses.removeAt(0);
    }
    
    // Track topic
    _updateTopicTracking(response);
  }

  /// Update topic tracking
  void _updateTopicTracking(String response) {
    final responseLower = response.toLowerCase();
    
    // Detect topic
    String? currentTopic;
    if (responseLower.contains('ngủ') || responseLower.contains('sleep')) {
      currentTopic = 'sleep';
    } else if (responseLower.contains('nhạc') || responseLower.contains('music')) {
      currentTopic = 'music';
    } else if (responseLower.contains('đèn') || responseLower.contains('light')) {
      currentTopic = 'light';
    } else if (responseLower.contains('tinh dầu') || responseLower.contains('oil')) {
      currentTopic = 'oil';
    }
    
    if (currentTopic != null) {
      if (currentTopic == _lastTopic) {
        _repetitionCount++;
      } else {
        _repetitionCount = 1;
        _lastTopic = currentTopic;
      }
      
      _topicMentions[currentTopic] = (_topicMentions[currentTopic] ?? 0) + 1;
    }
  }

  /// Get first sentence from text
  String _getFirstSentence(String text) {
    final sentences = text.split(RegExp(r'[.!?。！？\n]'));
    return sentences.isNotEmpty ? sentences[0].trim() : text;
  }

  /// Calculate similarity between two strings (simple Jaccard similarity)
  double _calculateSimilarity(String s1, String s2) {
    if (s1.isEmpty || s2.isEmpty) return 0.0;
    
    final words1 = s1.split(RegExp(r'\s+')).toSet();
    final words2 = s2.split(RegExp(r'\s+')).toSet();
    
    final intersection = words1.intersection(words2).length;
    final union = words1.union(words2).length;
    
    return union > 0 ? intersection / union : 0.0;
  }

  /// Check if we're repeating the same topic too much
  bool isTopicRepeated(String topic) {
    final count = _topicMentions[topic] ?? 0;
    return count >= 2 && _repetitionCount >= 2;
  }

  /// Get a variation of response to avoid repetition
  String getVariation(String originalResponse, {String? context}) {
    if (!isResponseRepetitive(originalResponse)) {
      return originalResponse;
    }
    
    // Generate variation based on context
    final responseLower = originalResponse.toLowerCase();
    
    // If talking about sleep mode - butler-like variations
    if (responseLower.contains('chế độ ngủ') || responseLower.contains('ngủ')) {
      final variations = [
        'Để mình chuẩn bị không gian ngủ cho bạn nhé. Mình sẽ điều chỉnh ánh sáng và nhạc phù hợp.',
        'Mình sẽ điều chỉnh mọi thứ để bạn dễ ngủ hơn. Bạn cứ thả lỏng nhé.',
        'Hãy để mình giúp bạn thư giãn và chuẩn bị cho giấc ngủ. Mình đang ở đây với bạn.',
        'Mình sẽ tạo môi trường yên tĩnh để bạn nghỉ ngơi. Bạn muốn mình bật nhạc nhẹ không?',
        'Mình hiểu bạn cần nghỉ ngơi. Để mình chuẩn bị mọi thứ cho bạn ngay.',
        'Mình sẽ giúp bạn chuyển sang chế độ ngủ một cách nhẹ nhàng. Bạn cứ thư giãn nhé.',
      ];
      
      // Check which variation hasn't been used
      for (final variation in variations) {
        if (!isResponseRepetitive(variation)) {
          return variation;
        }
      }
      
      // If all variations used, acknowledge and move forward
      return 'Mình đã chuẩn bị mọi thứ cho bạn rồi. Bạn muốn mình làm gì tiếp theo không?';
    }
    
    // Generic variation - butler-like responses
    final butlerVariations = [
      'Mình hiểu bạn. Bạn muốn mình làm gì tiếp theo?',
      'Mình đang ở đây với bạn. Bạn cần mình giúp gì không?',
      'Mình lắng nghe bạn. Hãy cho mình biết bạn muốn gì nhé.',
      'Mình hiểu rồi. Bạn muốn thử cách khác không?',
    ];
    
    if (context != null && context.isNotEmpty) {
      // Use context-aware variation
      return 'Mình hiểu. $context\n\n${butlerVariations[DateTime.now().millisecond % butlerVariations.length]}';
    }
    
    return butlerVariations[DateTime.now().millisecond % butlerVariations.length];
  }

  /// Reset conversation (when starting new session)
  void reset() {
    _recentResponses.clear();
    _lastTopic = null;
    _repetitionCount = 0;
    _topicMentions.clear();
  }

  /// Get conversation summary for context
  String getConversationSummary() {
    if (_recentResponses.isEmpty) return '';
    
    final summary = StringBuffer();
    summary.write('Trong cuộc trò chuyện gần đây, ');
    
    if (_topicMentions.isNotEmpty) {
      final topics = _topicMentions.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      final topTopic = topics.first.key;
      switch (topTopic) {
        case 'sleep':
          summary.write('chúng ta đã nói về việc chuẩn bị ngủ. ');
          break;
        case 'music':
          summary.write('chúng ta đã nói về nhạc. ');
          break;
        case 'light':
          summary.write('chúng ta đã nói về ánh sáng. ');
          break;
        case 'oil':
          summary.write('chúng ta đã nói về tinh dầu. ');
          break;
      }
    }
    
    return summary.toString();
  }
}

