import 'package:flutter/material.dart';
import 'dart:io';
import 'package:smart_candles/features/essential_oil/models/essential_oil.dart';

class EssentialOilDetailScreen extends StatelessWidget {
  final EssentialOil oil;

  const EssentialOilDetailScreen({
    super.key,
    required this.oil,
  });

  // Get detailed content for each oil type
  Map<String, String> _getOilDetailContent(String oilId) {
    switch (oilId) {
      case 'lavender':
        return {
          'title': 'Tinh dầu Oải Hương (Lavender)',
          'description':
              'Một trong những loại tinh dầu quốc dân phải kể đến tinh dầu oải hương. Mùi hương được chiết xuất từ hoa Lavender rất dễ chịu, nhẹ nhàng gần giống như mùi thảo mộc tạo cảm giác thoải mái, thư giãn cho người dùng.',
          'highlights':
              '• Giúp thư giãn đầu óc, giảm căng thẳng, stress, tạo cảm giác thoải mái.\n'
                  '• Mùi hương nhẹ nhàng, dễ ngửi, giúp đi sâu vào giấc ngủ.\n'
                  '• Khử mùi tốt, hỗ trợ kháng khuẩn, kháng viêm.\n'
                  '• Hỗ trợ xua đuổi muỗi, giúp giảm nguy cơ bị muỗi đốt.',
        };
      case 'huong_tram':
        return {
          'title': 'Tinh dầu Hương Trầm (Frankincense)',
          'description':
              'Tinh dầu hương trầm (Frankincense) được sử dụng khá phổ biến vì hương thơm thảo mộc đặc trưng. Hương trầm được chiết xuất từ nhựa cây trầm Châu Phi. Loại tinh dầu này có khả năng giúp trấn an tinh thần, xoa dịu và xua tan cảm xúc tiêu cực thường được dùng trong các bộ môn như thiền, yoga,...',
          'highlights': '• Hương thơm giúp tạo cảm giác thư giãn, dễ chịu hơn.\n'
              '• Đem lại cảm giác thoải mái cho tinh thần, tạo năng lượng tích cực.\n'
              '• Giảm căng thẳng mệt mỏi, dễ ngủ.\n'
              '• Khử mùi, tạo hương thơm nhẹ nhàng, giúp tinh thần thoải mái.',
        };
      case 'bac_ha':
        return {
          'title': 'Tinh dầu Bạc Hà (Peppermint)',
          'description':
              'Mùi bạc hà là mùi hương quen thuộc được rất nhiều gia đình yêu thích và sử dụng. Trong các loại kẹo, thuốc, nước hoa,... thường có tinh dầu bạc hà the mát. Tinh dầu được chiết xuất từ cây bạc hà, thường được dùng nhiều trong y học.',
          'highlights': '• Hỗ trợ đường hô hấp, làm dịu cảm giác ho, đau họng,...\n'
              '• Giảm các triệu chứng đầy bụng, khó tiêu, kích thích đường ruột.\n'
              '• Xua đuổi côn trùng, phòng muỗi đốt, cảm cúm, đau nhức cơ thể.\n'
              '• Khử mùi và góp phần làm sạch không khí trong không gian sống.',
        };
      case 'khuynh_diep':
        return {
          'title': 'Tinh dầu Khuynh Diệp (Eucalyptus)',
          'description':
              'Tinh dầu Khuynh Diệp là loại tinh dầu được các mẹ rất yêu thích và tin dùng cho các bé và gia đình. Với chiết xuất từ lá cây khuynh diệp nên an toàn cho trẻ em và cả mẹ bầu. Sản phẩm thường có trong dầu gió, cao thoa,...',
          'highlights':
              '• Cần tham khảo ý kiến chuyên gia trước khi dùng cho phụ nữ có thai, cho con bú và người có bệnh nền như hen suyễn, huyết áp cao.\n'
                  '• Hỗ trợ làm giảm các triệu chứng cảm cúm, sổ mũi, ho, đau đầu,...\n'
                  '• Góp phần làm sạch không khí, khử mùi phòng ở, hạn chế mùi hôi trong phòng kín hay mùa nồm,...',
        };
      case 'tram_tra':
        return {
          'title': 'Tinh dầu Tràm Trà (Tea Tree)',
          'description':
              'Với nhiều công dụng nổi bật đặc biệt kháng viêm tốt, tinh dầu tràm trà được ứng dụng nhiều trong ngành làm đẹp, mỹ phẩm. Tinh dầu được chưng cất hơi nước từ lá cây tràm trà, có màu trong suốt mang mùi hương đặc trưng của loại cây này.',
          'highlights':
              '• Tinh dầu tràm trà có đặc tính hỗ trợ kháng khuẩn, chống viêm, góp phần làm sạch không khí.\n'
                  '• Hỗ trợ giảm sưng, viêm mụn trứng cá, mụn bọc,...\n'
                  '• Đẩy nhanh quá trình lên da non, làm mờ thâm, nám.\n'
                  '• Hỗ trợ làm dịu và mang lại cảm giác dễ chịu khi gặp các triệu chứng cảm cúm, ho,...',
        };
      case 'buoi':
        return {
          'title': 'Tinh dầu Bưởi (Grapefruit)',
          'description':
              'Tinh dầu bưởi có nhiều công dụng cho tóc, hỗ trợ phục hồi tóc hư tổn. Tinh dầu được chiết xuất bằng phương pháp ép lạnh vỏ bưởi có hương thơm tươi mát, có thể không có màu hoặc màu vàng nhạt.',
          'highlights':
              '• Hỗ trợ phục hồi tóc hư tổn do thường xuyên tiếp xúc với hóa chất, kích thích mọc tóc nhanh,...\n'
                  '• Khử mùi hôi, góp phần thanh lọc không khí và hỗ trợ kháng khuẩn.\n'
                  '• Làm chậm quá trình lão hóa da, tạo cảm giác thư giãn, thoải mái tinh thần.',
        };
      case 'cam_ngot':
        return {
          'title': 'Tinh dầu Cam Ngọt',
          'description':
              'Tinh dầu Cam Ngọt là một trong những loại tinh dầu rất được ưa chuộng. Mùi hương của cam rất dễ chịu nên được ứng dụng trong nhiều sản phẩm như kẹo, thuốc, nước tẩy rửa, nước hoa,... Tinh dầu được chiết xuất từ vỏ cam hoàn toàn từ thiên nhiên nên có mùi hương rất dễ chịu.',
          'highlights':
              '• Cam ngọt giúp giảm căng thẳng, thư giãn, dễ đi vào giấc ngủ.\n'
                  '• Hỗ trợ kháng khuẩn, khử mùi cho không gian sống, tạo cảm giác dễ chịu.',
        };
      case 'sa_chanh':
        return {
          'title': 'Tinh dầu Sả Chanh',
          'description':
              'Đây là một trong những loại tinh dầu thường có mặt trong các gia đình đặc biệt là vào mùa mưa hay khi thời tiết thay đổi. Loại tinh dầu này khá phổ biến, dễ mua và được chiết xuất bằng phương pháp chưng cất hơi nước. Tinh dầu có mùi thơm nồng, nhưng mang lại cảm giác dễ chịu và thoải mái cho người dùng.',
          'highlights':
              '• Khử mùi, góp phần thanh lọc và làm sạch không khí trong phòng ngủ và không gian sống.\n'
                  '• Giảm các triệu chứng cảm cúm, nghẹt mũi, ho, đau đầu.\n'
                  '• Tạo cảm giác thư giãn, thoải mái.',
        };
      case 'gung':
        return {
          'title': 'Tinh dầu Gừng',
          'description':
              'Gừng là một loại cây quen thuộc hàng ngày, được dùng nhiều trong ẩm thực. Tinh dầu được chiết xuất từ củ của cây gừng, có mùi thơm đặc trưng. Loại tinh dầu này thường sử dụng để cải thiện tình trạng cảm cúm, làm ấm người một cách hiệu quả.',
          'highlights': '• Hỗ trợ làm dịu các cơn đau đầu, đau mỏi người.\n'
              '• Làm ấm cơ thể vào mùa lạnh, giảm các triệu chứng cảm cúm.\n'
              '• Giảm say xe, mệt mỏi, giúp người dùng ngủ ngon hơn.',
        };
      case 'ngoc_lan_tay':
        return {
          'title': 'Tinh dầu Ngọc Lan Tây',
          'description':
              'Tinh dầu Ngọc Lan Tây từ lâu đã được biết đến là sản phẩm có khả năng chống trầm cảm, giúp thư giãn, thoải mái vô cùng hiệu quả. Loại tinh dầu này còn được dùng nhiều trong việc sản xuất mỹ phẩm, làm đẹp.',
          'highlights':
              '• Giảm stress, lo lắng, căng thẳng, giúp tinh thần thoải mái và ngủ ngon hơn.\n'
                  '• Dưỡng ẩm cho làn da, giảm tình trạng nhờn rít trên da.\n'
                  '• Hương thơm thư giãn giúp mang lại cảm giác dễ chịu khi bị hồi hộp.',
        };
      case 'hoa_nhai':
        return {
          'title': 'Tinh dầu Hoa Nhài',
          'description':
              'Hoa nhài là loài hoa có mùi thơm nhẹ nhàng, thanh khiết nên rất được ưa chuộng sử dụng trong nước hoa hay các sản phẩm tẩy rửa. Tinh dầu được chiết xuất từ hoa của cây hoa nhài có màu trắng, mùi hương dễ chịu.',
          'highlights':
              '• Hỗ trợ kháng khuẩn và làm dịu da. Không bôi trực tiếp lên vết thương hở.\n'
                  '• Tạo cảm giác thư giãn, giảm mệt mỏi.\n'
                  '• Hương thơm giúp thư giãn, hỗ trợ cải thiện tâm trạng.',
        };
      case 'chanh':
        return {
          'title': 'Tinh dầu Chanh',
          'description':
              'Chanh là loại quả cùng họ với cam, có mùi hương rất dễ chịu, tươi mát. Tinh dầu chanh được chiết xuất từ vỏ quả chanh, có nhiều công dụng tốt cho sức khỏe.',
          'highlights': '• Tạo mùi hương dễ chịu, đem lại cảm giác thoải mái.\n'
              '• Khử mùi tốt, đem lại không gian thơm tho.\n'
              '• Giúp giảm ho, đau họng một cách hiệu quả.',
        };
      default:
        return {
          'title': oil.name,
          'description': oil.description,
          'highlights': '',
        };
    }
  }

  // Get asset path for image
  String? _getAssetPathForImageType(String imageType) {
    final imageTypeLower = imageType.toLowerCase().trim();

    switch (imageTypeLower) {
      case 'lavender':
        return 'assets/images/tinh_dau/lavender.png';
      case 'huong tram':
      case 'huongtram':
      case 'frankincense':
        return 'assets/images/tinh_dau/huong_tram.png';
      case 'bac ha':
      case 'bacha':
      case 'peppermint':
        return 'assets/images/tinh_dau/bac_ha.png';
      case 'khuynh diep':
      case 'khuynhdiep':
      case 'eucalyptus':
        return 'assets/images/tinh_dau/khuynh_diep.png';
      case 'tram tra':
      case 'tramtra':
      case 'tea tree':
        return 'assets/images/tinh_dau/tram_tra.png';
      case 'buoi':
      case 'grapefruit':
        return 'assets/images/tinh_dau/buoi.png';
      case 'cam ngot':
      case 'camngot':
      case 'orange':
      case 'sweet orange':
        return 'assets/images/tinh_dau/cam_ngot.png';
      case 'sa chanh':
      case 'sachanh':
      case 'lemongrass':
        return 'assets/images/tinh_dau/sa_chanh.png';
      case 'gung':
      case 'ginger':
        return 'assets/images/tinh_dau/gung.png';
      case 'ngoc lan tay':
      case 'ngoclantay':
      case 'ylang-ylang':
      case 'ylang ylang':
        return 'assets/images/tinh_dau/ngoc_lan_tay.png';
      case 'hoa nhai':
      case 'hoanhai':
      case 'jasmine':
        return 'assets/images/tinh_dau/hoa_nhai.png';
      case 'chanh':
      case 'lemon':
        return 'assets/images/tinh_dau/chanh.png';
      default:
        return null;
    }
  }

  Widget _buildOilImage(String imageType, String? imagePath) {
    // Use custom image if available
    if (imagePath != null && File(imagePath).existsSync()) {
      return Image.file(
        File(imagePath),
        width: double.infinity,
        height: 300,
        fit: BoxFit.cover,
      );
    }

    // Use asset image
    final assetPath = _getAssetPathForImageType(imageType);
    if (assetPath != null) {
      return Image.asset(
        assetPath,
        width: double.infinity,
        height: 300,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 300,
            color: Colors.grey[200],
            child: const Center(
              child: Icon(Icons.image, size: 64, color: Colors.grey),
            ),
          );
        },
      );
    }

    // Fallback
    return Container(
      height: 300,
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.image, size: 64, color: Colors.grey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = _getOilDetailContent(oil.id);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Chi tiết tinh dầu',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[600],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            _buildOilImage(oil.imageType, oil.imagePath),
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    content['title'] ?? oil.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Description
                  Text(
                    content['description'] ?? oil.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Highlights
                  if (content['highlights'] != null &&
                      content['highlights']!.isNotEmpty) ...[
                    const Text(
                      'Đặc điểm nổi bật:',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      content['highlights']!,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                        height: 1.8,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
