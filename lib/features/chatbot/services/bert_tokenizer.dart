import 'package:flutter/services.dart';

class BertTokenizer {
  final Map<String, int> _vocab;
  final bool doLowerCase;

  BertTokenizer(this._vocab, {this.doLowerCase = true});

  static Future<BertTokenizer> fromAsset(String assetPath,
      {bool doLowerCase = true}) async {
    final vocabContent = await rootBundle.loadString(assetPath);
    final vocab = <String, int>{};
    final lines = vocabContent.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final token = lines[i].trim();
      if (token.isNotEmpty) {
        vocab[token] = i;
      }
    }
    return BertTokenizer(vocab, doLowerCase: doLowerCase);
  }

  List<int> tokenize(String text, {int maxLen = 128}) {
    if (doLowerCase) {
      text = text.toLowerCase();
    }

    // Basic whitespace tokenization
    // A real BERT tokenizer is more complex (WordPiece), but for many languages
    // and basic usage, splitting by space and punctuation is a decent start.
    // However, checking the vocab for "##" subwords is crucial for OOV handling.

    final tokens = <String>['[CLS]'];
    // Naive split (improve with regex for punctuation)
    // Splitting by space and keeping punctuation
    // This is a simplified implementation.

    final words = text.split(RegExp(r'\s+'));

    for (final word in words) {
      _tokenizeWord(word, tokens);
    }

    tokens.add('[SEP]');

    final ids = tokens.map((t) => _vocab[t] ?? _vocab['[UNK]'] ?? 100).toList();

    // Padding/Truncating
    if (ids.length > maxLen) {
      return ids.sublist(0, maxLen);
    } else {
      return List<int>.from(ids)
        ..addAll(List.filled(maxLen - ids.length, 0)); // 0 is usually [PAD]
    }
  }

  void _tokenizeWord(String word, List<String> tokens) {
    if (word.isEmpty) return;

    if (_vocab.containsKey(word)) {
      tokens.add(word);
      return;
    }

    // Greedy longest-match-first strategy for WordPiece
    int start = 0;
    bool isBad = false;
    final subTokens = <String>[];

    while (start < word.length) {
      int end = word.length;
      String? curSubStr;

      while (start < end) {
        String subStr = word.substring(start, end);
        if (start > 0) {
          subStr = '##$subStr';
        }

        if (_vocab.containsKey(subStr)) {
          curSubStr = subStr;
          break;
        }
        end--;
      }

      if (curSubStr == null) {
        isBad = true;
        break;
      }

      subTokens.add(curSubStr);
      start = end;
    }

    if (isBad) {
      tokens.add('[UNK]');
    } else {
      tokens.addAll(subTokens);
    }
  }
}
