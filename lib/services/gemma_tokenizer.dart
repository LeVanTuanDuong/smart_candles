import 'dart:convert';
import 'package:flutter/services.dart';

class GemmaTokenizer {
  Map<String, int> _vocab = {};
  Map<int, String> _decoderVocab = {};
  List<String> _merges = [];
  Map<String, int> _mergeRanks = {};

  // Special tokens
  static const String sepToken = '<sep>';
  static const String clsToken = '<cls>'; // or <bos>
  static const String unkToken = '<unk>';
  static const String padToken = '<pad>';
  static const String maskToken = '<mask>';

  bool _isLoaded = false;

  Future<void> loadFromAsset(String assetPath) async {
    if (_isLoaded) return;
    try {
      final jsonString = await rootBundle.loadString(assetPath);
      loadFromJsonString(jsonString);
    } catch (e) {
      print('Error loading Gemma Tokenizer: $e');
      rethrow;
    }
  }

  void loadFromJsonString(String jsonString) {
    if (_isLoaded) return;
    try {
      final jsonMap = json.decode(jsonString);

      // Parse Model
      final model = jsonMap['model'];
      if (model != null) {
        // Vocab
        final vocabMap = model['vocab'] as Map<String, dynamic>;
        _vocab = vocabMap.map((key, value) => MapEntry(key, value as int));
        _decoderVocab = _vocab.map((key, value) => MapEntry(value, key));

        // Merges
        if (model['merges'] != null) {
          final mergesList = model['merges'] as List;
          _merges = mergesList.map((e) => e.toString()).toList();

          for (int i = 0; i < _merges.length; i++) {
            _mergeRanks[_merges[i]] = i;
          }
        }
      }

      _isLoaded = true;
      print(
          'Gemma Tokenizer Loaded: ${_vocab.length} tokens, ${_merges.length} merges');
    } catch (e) {
      print('Error loading Gemma Tokenizer: $e');
      rethrow;
    }
  }

  List<int> tokenize(String text) {
    if (!_isLoaded) return [];

    // 1. Normalization (replace spaces with U+2581)
    // Gemma uses SPIECE_UNDERLINE ( ) for spaces
    String cleaned = text.replaceAll(' ', ' ');
    if (!cleaned.startsWith(' ')) {
      cleaned = ' ' + cleaned;
    }

    // 2. Pre-tokenization (Split roughly)
    // This is a simplification. BPE usually handles the whole string,
    // but splitting by generic boundaries helps performance.
    // For Gemma, we treat the whole string as one block usually,
    // or split by whitespace which we just replaced.
    // Let's stick to a simple BPE applied to the whole string (or words).

    // Simplest approach: Split by non-alphanumeric if needed, but Gemma handles raw bytes.
    // Let's implement Byte-Level BPE or Character-Level BPE.
    // Given the 'vocab' usually has characters, we start with char list.

    // Since implementing full Byte-Level BPE is complex (requires mapping bytes to unicode chars),
    // we will assume the input is standard UTF-8 text and vocab supports it.

    List<String> wordTokens = [];
    // Split by spaces (which are now  ) is a decent heuristic for BPE
    final words = cleaned.split(RegExp(r'(?= )'));

    for (var word in words) {
      if (word.isEmpty) continue;
      wordTokens.addAll(_bpe(word));
    }

    // Map to IDs
    return wordTokens.map((t) => _vocab[t] ?? _vocab[unkToken] ?? 0).toList();
  }

  List<String> _bpe(String token) {
    if (token.length <= 1) return [token];

    // Initial split into chars
    List<String> word = token.split('');

    // Iteratively merge
    while (word.length > 1) {
      int minRank = 999999999;
      int bestIdx = -1;
      String? bestPair;

      // Find best pair
      for (int i = 0; i < word.length - 1; i++) {
        final pair = '${word[i]} ${word[i + 1]}';
        final rank = _mergeRanks[pair];

        if (rank != null && rank < minRank) {
          minRank = rank;
          bestIdx = i;
          bestPair = pair;
        }
      }

      // If no pair found in merges, stop
      if (bestIdx == -1) break;

      // Merge
      final mergedToken = word[bestIdx] + word[bestIdx + 1];

      // Update word list
      word[bestIdx] = mergedToken;
      word.removeAt(bestIdx + 1);
    }

    return word;
  }

  String decode(List<int> ids) {
    if (!_isLoaded) return "";

    final buffer = StringBuffer();
    for (var id in ids) {
      final token = _decoderVocab[id];
      if (token != null) {
        buffer.write(token);
      }
    }
    return buffer.toString().replaceAll(' ', ' ').trim();
  }
}
