import 'package:flutter/material.dart';
import '../models/mood_type.dart';
import '../screens/essential_oil_library_screen.dart';

class EssentialOilSuggestionCard extends StatelessWidget {
  final MoodType mood;
  final String? customEssentialOil; // Gợi ý tinh dầu cụ thể từ chatbot

  const EssentialOilSuggestionCard({
    super.key,
    required this.mood,
    this.customEssentialOil,
  });


  String _getEssentialOilName() {
    return customEssentialOil ?? mood.essentialOil;
  }

  String _getEffect() {
    // Use custom oil effect if provided, otherwise use mood effect
    final oilName = _getEssentialOilName();
    switch (oilName) {
      case 'Lavender':
        return 'Thư giãn, giảm lo âu.';
      case 'Sweet Orange':
        return 'Nâng cao tinh thần.';
      case 'Peppermint':
        return 'Tỉnh táo, tập trung.';
      case 'Chamomile':
        return 'An thần, hỗ trợ giấc ngủ.';
      default:
        return _getEffectFromMood();
    }
  }

  String _getEffectFromMood() {
    switch (mood) {
      case MoodType.stressed:
        return 'Thư giãn, giảm lo âu.';
      case MoodType.sad:
        return 'Nâng cao tinh thần.';
      case MoodType.tired:
        return 'Tỉnh táo, tập trung.';
      case MoodType.insomnia:
        return 'An thần, hỗ trợ giấc ngủ.';
      case MoodType.normal:
        return 'Duy trì cảm xúc tích cực.';
    }
  }

  Color _getOilColor() {
    final oilName = _getEssentialOilName();
    switch (oilName) {
      case 'Lavender':
        return Colors.purple[300]!;
      case 'Sweet Orange':
        return Colors.orange[300]!;
      case 'Peppermint':
        return Colors.green[300]!;
      case 'Chamomile':
        return Colors.yellow[300]!;
      default:
        return Colors.amber[300]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const EssentialOilLibraryScreen(),
          ),
        );
      },
      child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Essential oil bottle icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _getOilColor(),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                // Bottle body
                Positioned(
                  bottom: 10,
                  left: 20,
                  child: Container(
                    width: 40,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.brown[700],
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                  ),
                ),
                // Label
                Positioned(
                  bottom: 25,
                  left: 22,
                  child: Container(
                    width: 36,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.purple[400],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        _getEssentialOilName().split(' ').first,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                // Dropper cap
                Positioned(
                  top: 10,
                  left: 28,
                  child: Container(
                    width: 24,
                    height: 15,
                    decoration: BoxDecoration(
                      color: Colors.brown[800],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(2),
                        topRight: Radius.circular(2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gợi ý tinh dầu:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getEssentialOilName(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getEffect(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Thắp 20-30 phút.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }
}

