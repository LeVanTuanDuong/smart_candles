import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Về ứng dụng'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // App Logo/Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.purple[600],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.spa,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            // App Name
            const Text(
              'Smart Candles',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Nến Thông Minh',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            // Version
            const Text(
              'Phiên bản 1.0.0',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 40),
            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Ứng dụng quản lý nến thông minh với chatbot tâm lý, gợi ý tinh dầu và nhạc phù hợp với tâm trạng của bạn.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 40),
            // Features
            _buildFeatureItem(
              Icons.psychology,
              'Chatbot tâm lý',
              'Phân tích tâm trạng và đưa ra lời khuyên',
            ),
            _buildFeatureItem(
              Icons.spa,
              'Gợi ý tinh dầu',
              'Tinh dầu phù hợp với tâm trạng của bạn',
            ),
            _buildFeatureItem(
              Icons.music_note,
              'Thư viện nhạc',
              'Nhạc thư giãn và thiền định',
            ),
            _buildFeatureItem(
              Icons.book_outlined,
              'Nhật ký tâm trạng',
              'Ghi lại và theo dõi tâm trạng hàng ngày',
            ),
            _buildFeatureItem(
              Icons.thermostat,
              'Giám sát nhiệt độ',
              'Theo dõi nhiệt độ nến để đảm bảo an toàn',
            ),
            const SizedBox(height: 40),
            // Links
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.description, color: Colors.purple[600]),
                    title: const Text('Điều khoản sử dụng'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Show terms of service
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tính năng đang phát triển'),
                        ),
                      );
                    },
                  ),
                  Divider(color: Colors.grey[300]),
                  ListTile(
                    leading: Icon(Icons.privacy_tip, color: Colors.purple[600]),
                    title: const Text('Chính sách bảo mật'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Show privacy policy
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tính năng đang phát triển'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // Copyright
            Text(
              '© 2024 Smart Candles',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Made with ❤️ for your well-being',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.purple[600]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

