import 'package:flutter/material.dart';
import '../models/mood_type.dart';
import '../models/essential_oil.dart';
import '../screens/essential_oil_library_screen.dart';
import 'dart:io';

class EssentialOilSuggestionCard extends StatelessWidget {
  final MoodType mood;
  final String? customEssentialOil; // Gợi ý tinh dầu cụ thể từ chatbot (tên)
  final EssentialOil? suggestedOil; // EssentialOil object từ thư viện

  const EssentialOilSuggestionCard({
    super.key,
    required this.mood,
    this.customEssentialOil,
    this.suggestedOil,
  });

  String _getEssentialOilName() {
    return suggestedOil?.name ?? customEssentialOil ?? mood.essentialOil;
  }

  String _getEffect() {
    // Use description from suggestedOil if available
    if (suggestedOil != null && suggestedOil!.description.isNotEmpty) {
      return suggestedOil!.description;
    }
    
    // Use custom oil effect if provided, otherwise use mood effect
    final oilName = _getEssentialOilName();
    switch (oilName) {
      case 'Lavender':
      case 'Tinh dầu Oải Hương':
        return 'Thư giãn, giảm lo âu.';
      case 'Sweet Orange':
      case 'Tinh dầu Hương Cam':
        return 'Nâng cao tinh thần.';
      case 'Peppermint':
      case 'Tinh dầu Bạc Hà':
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
      case 'Tinh dầu Oải Hương':
        return Colors.purple[300]!;
      case 'Sweet Orange':
      case 'Tinh dầu Hương Cam':
        return Colors.orange[300]!;
      case 'Peppermint':
      case 'Tinh dầu Bạc Hà':
        return Colors.green[300]!;
      case 'Chamomile':
      case 'Tinh dầu Hương Trầm':
        return Colors.yellow[300]!;
      case 'Tinh dầu Khuynh Diệp':
        return Colors.green[200]!;
      case 'Tinh dầu Tràm Trà':
        return Colors.teal[300]!;
      case 'Tinh dầu Bưởi':
        return Colors.orange[200]!;
      case 'Tinh dầu Sả Chanh':
        return Colors.lime[300]!;
      case 'Tinh dầu Gừng':
        return Colors.orange[700]!;
      case 'Tinh dầu Ngọc Lan Tây':
        return Colors.yellow[200]!;
      case 'Tinh dầu Hoa Nhài':
        return Colors.pink[200]!;
      case 'Tinh dầu Chanh':
        return Colors.yellow[100]!;
      default:
        return Colors.amber[300]!;
    }
  }

  String? _getAssetPathForImageType(String imageType) {
    final imageTypeLower = imageType.toLowerCase().trim();

    switch (imageTypeLower) {
      case 'lavender':
        return 'assets/images/tinh dau/lavender.png';
      case 'huong tram':
      case 'huongtram':
      case 'frankincense':
        return 'assets/images/tinh dau/huong tram.png';
      case 'bac ha':
      case 'bacha':
      case 'peppermint':
        return 'assets/images/tinh dau/bac ha.png';
      case 'khuynh diep':
      case 'khuynhdiep':
      case 'eucalyptus':
        return 'assets/images/tinh dau/khuynh diep.png';
      case 'tram tra':
      case 'tramtra':
      case 'tea tree':
        return 'assets/images/tinh dau/tram tra.png';
      case 'buoi':
      case 'grapefruit':
        return 'assets/images/tinh dau/buoi.png';
      case 'cam ngot':
      case 'camngot':
      case 'orange':
      case 'sweet orange':
        return 'assets/images/tinh dau/cam ngot.png';
      case 'sa chanh':
      case 'sachanh':
      case 'lemongrass':
        return 'assets/images/tinh dau/sa chanh.png';
      case 'gung':
      case 'ginger':
        return 'assets/images/tinh dau/gung.png';
      case 'ngoc lan tay':
      case 'ngoclantay':
      case 'ylang-ylang':
      case 'ylang ylang':
        return 'assets/images/tinh dau/ngoc lan tay.png';
      case 'hoa nhai':
      case 'hoanhai':
      case 'jasmine':
        return 'assets/images/tinh dau/hoa nhai.png';
      case 'chanh':
      case 'lemon':
        return 'assets/images/tinh dau/chanh.png';
      default:
        return null;
    }
  }

  Widget _buildOilImage() {
    // Use image from suggestedOil if available
    if (suggestedOil != null) {
      // Check if custom image path exists
      if (suggestedOil!.imagePath != null && 
          File(suggestedOil!.imagePath!).existsSync()) {
        return Image.file(
          File(suggestedOil!.imagePath!),
          width: 80,
          height: 80,
          fit: BoxFit.cover,
        );
      }
      
      // Use asset image based on imageType
      final assetPath = _getAssetPathForImageType(suggestedOil!.imageType);
      if (assetPath != null) {
        return Image.asset(
          assetPath,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _getOilColor(),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _buildBottleIcon(),
            );
          },
        );
      }
    }
    
    // Fallback to colored container with bottle icon
    return Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
        color: _getOilColor(),
              borderRadius: BorderRadius.circular(12),
            ),
      child: _buildBottleIcon(),
    );
  }

  Widget _buildBottleIcon() {
    return Stack(
      alignment: Alignment.center,
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
                _getEssentialOilName().split(' ').last.length > 4 
                    ? _getEssentialOilName().split(' ').last.substring(0, 4)
                    : _getEssentialOilName().split(' ').last,
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
    );
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
          // Essential oil image or icon
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildOilImage(),
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

