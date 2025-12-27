import 'package:flutter/material.dart';

class EssentialOilGuideScreen extends StatelessWidget {
  const EssentialOilGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Hướng dẫn sử dụng',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[600],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Text(
              '4 Cách sử dụng tinh dầu và những lưu ý khi dùng',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 30),
            // Section 1
            _buildSection(
              number: '1',
              title: 'Dùng tinh dầu ra sao để có tác dụng tốt nhất?',
              content:
                  'Để tinh dầu đạt được hiệu quả tốt nhất và an toàn cho sức khỏe người sử dụng, bạn chỉ nên ngửi tinh dầu trong khoảng từ 15 - 60 phút. Nếu bạn đang điều trị các bệnh mãn tính hay dùng thuốc, thì nên tham khảo ý kiến của bác sĩ trước khi dùng tinh dầu.\n\n'
                  'Bạn có thể sử dụng máy xông tinh dầu để xông tinh dầu, hoặc một tô nước nóng để giúp tinh dầu khuếch tán trên diện rộng, phát huy hiệu quả cao nhất. Mỗi lần xông chỉ nên nhỏ 2 đến 3 giọt trong thời gian hợp lý, sau đó mở cửa phòng để phòng được thông thoáng.\n\n'
                  'Nếu không tiện sử dụng cách trên thì bạn có thể dùng bông gòn, thấm 1 giọt tinh dầu và đưa lên mũi ngửi. Cách này có thể hạn chế say xe khi đi đường.',
            ),
            const SizedBox(height: 30),
            // Section 2
            _buildSection(
              number: '2',
              title: 'Hướng dẫn mua tinh dầu thật tốt cho sức khỏe',
              content:
                  'Để mua được các loại tinh dầu tốt cho sức khỏe, tránh mua phải hàng kém chất lượng, bạn cần chú ý:\n\n'
                  '• Đọc kỹ bao bì sản phẩm, chú ý thông tin về hương liệu, thành phần để hạn chế tình trạng kích ứng.\n\n'
                  '• Hãy ưu tiên những loại tinh dầu 100% tinh khiết hay dầu hữu cơ, không chứa các chất diệt côn trùng, hóa chất,...\n\n'
                  '• Ưu tiên các loại tinh dầu có ghi đạt mức độ trị liệu, được chưng cất bằng phương pháp hơi nước.\n\n'
                  '• Chọn mua các sản phẩm của thương hiệu uy tín, chất lượng, rõ nguồn gốc xuất xứ.',
            ),
            const SizedBox(height: 30),
            // Section 3
            _buildSection(
              number: '3',
              title: 'Lưu ý khi dùng tinh dầu',
              content:
                  'Tinh dầu khi không sử dụng đúng cách có thể làm giảm tác dụng của loại thuốc mà bạn đang sử dụng. Vì vậy cần hỏi ý kiến bác sĩ trước khi dùng nếu bạn đang điều trị bệnh nhé!\n\n'
                  'Với những người bị huyết áp cao cần chú ý tránh chất kích thích như hương thảo. Hay người bệnh có khối u vú, ở buồng trứng có phụ thuộc vào estrogen thì nên tránh thì là, cây xô thơm.\n\n'
                  'Ngoài ra có một vài loại dầu có khả năng gây độc tố cho gan, thận khi dùng trực tiếp qua đường uống. Vì thế nên tránh nuốt trực tiếp tinh dầu, đặc biệt nên để xa tầm tay trẻ em. Bạn nên bảo quản tinh dầu ở nhiệt độ phòng, nơi thoáng mát để đảm bảo chất lượng.',
            ),
            const SizedBox(height: 30),
            // Section 4
            _buildSection(
              number: '4',
              title: 'Những đối tượng cần lưu ý khi dùng tinh dầu',
              content:
                  'Không phải ai cũng có thể sử dụng tinh dầu hay phù hợp với mọi loại tinh dầu. Những bệnh nhân bị dị ứng, bị chàm, vảy nến, hen suyễn cần phải chú ý trước khi sử dụng để tránh làm tình trạng bệnh nặng hơn, tốt nhất nên hỏi ý kiến chuyên gia trước khi dùng.\n\n'
                  'Đặc biệt, với những người bị bệnh động kinh, bị tăng huyết áp sẽ rất nguy hiểm nếu như dùng tinh dầu sai cách. Bên cạnh đó mẹ bầu, phụ nữ đang cho con bú không được khuyến khích sử dụng tinh dầu vì thế cần phải tìm hiểu kỹ sản phẩm, hỏi ý kiến bác sĩ trước khi dùng để không làm ảnh hưởng đến sức khỏe.',
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String number,
    required String title,
    required String content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Number and title row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.blue[600],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Content
        Padding(
          padding: const EdgeInsets.only(left: 44), // Align with title
          child: Text(
            content,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}

