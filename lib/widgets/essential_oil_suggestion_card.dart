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

  String _getDescription() {
    if (suggestedOil != null && suggestedOil!.description.isNotEmpty) {
      return suggestedOil!.description;
    }

    return '';
  }

  Widget _buildOilImage() {
    if (suggestedOil == null) {
      return const SizedBox(width: 80, height: 80);
    }

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
          // If asset image fails, return empty container (no fallback icon)
          return const SizedBox(width: 80, height: 80);
        },
      );
    }

    // If no image available, return empty container (no fallback icon)
    return const SizedBox(width: 80, height: 80);
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
            // Essential oil image
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
                    _getDescription(),
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
