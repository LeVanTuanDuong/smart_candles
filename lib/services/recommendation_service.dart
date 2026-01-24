import 'dart:math';
import 'ai_inference_service.dart';

class RecommendationService {
  static final RecommendationService _instance =
      RecommendationService._internal();
  factory RecommendationService() => _instance;
  RecommendationService._internal();

  /// Calculate cosine similarity between two vectors
  double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) return 0.0;

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    if (normA == 0 || normB == 0) return 0.0;

    return dotProduct / (sqrt(normA) * sqrt(normB));
  }

  /// Get relevant past activity based on current mood description
  /// [currentMoodText] description of how user feels
  /// [history] list of past entries { 'text': '...', 'activity': '...' }
  Future<Map<String, dynamic>?> getPersonalizedSuggestion(
      String currentMoodText, List<Map<String, dynamic>> history) async {
    if (history.isEmpty) return null;

    // Get embedding for current mood
    final currentEmbedding =
        await AiInferenceService().getRecommendationEmbedding(currentMoodText);
    if (currentEmbedding.isEmpty) return null;

    double maxSim = -1.0;
    Map<String, dynamic>? bestMatch;

    for (final entry in history) {
      if (entry['text'] == null) continue;

      // Assume we computed embedding for history items or compute on fly (expensive if many)
      // For optimization, history should have 'embedding' field pre-calculated.
      // If not, we calculate it here (slow for large list).
      List<double> entryEmbedding;

      if (entry['embedding'] != null) {
        entryEmbedding = (entry['embedding'] as List).cast<double>();
      } else {
        entryEmbedding = await AiInferenceService()
            .getRecommendationEmbedding(entry['text']);
      }

      if (entryEmbedding.isEmpty) continue;

      final sim = _cosineSimilarity(currentEmbedding, entryEmbedding);
      if (sim > maxSim) {
        maxSim = sim;
        bestMatch = entry;
      }
    }

    // Threshold
    if (maxSim > 0.5) {
      return bestMatch;
    }

    return null;
  }
}
