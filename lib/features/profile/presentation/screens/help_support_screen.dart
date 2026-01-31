import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final List<FAQItem> _faqs = [
    FAQItem(
      question: 'Làm thế nào để kết nối với nến thông minh?',
      answer:
          'Vào Cài đặt > Kết nối, bật Bluetooth và nhấn "Kết nối thiết bị". Đảm bảo nến thông minh đã được bật và ở gần điện thoại của bạn.',
    ),
    FAQItem(
      question: 'Làm thế nào để thêm tinh dầu vào thư viện?',
      answer:
          'Vào Thư viện Tinh dầu, nhấn nút "+" để thêm tinh dầu mới. Bạn có thể chọn từ danh sách tinh dầu có sẵn hoặc thêm tinh dầu tùy chỉnh của bạn.',
    ),
    FAQItem(
      question: 'Làm thế nào để tải nhạc lên?',
      answer:
          'Vào Thư viện Nhạc > Tab "Tải lên", nhấn nút "+" và chọn file nhạc từ thiết bị của bạn. Bạn có thể thêm tên, mô tả và hình ảnh cho bài nhạc.',
    ),
    FAQItem(
      question: 'Chatbot hoạt động như thế nào?',
      answer:
          'Chatbot sẽ phân tích tâm trạng của bạn và đưa ra gợi ý về tinh dầu, nhạc và màu đèn phù hợp. Bạn có thể chọn tâm trạng từ các nút hoặc mô tả bằng lời.',
    ),
    FAQItem(
      question: 'Làm thế nào để ghi nhật ký tâm trạng?',
      answer:
          'Nhấn vào icon lịch ở góc trên bên phải màn hình chính, chọn tâm trạng và viết ghi chú (nếu muốn), sau đó nhấn "Lưu".',
    ),
    FAQItem(
      question: 'Nhiệt độ nào được coi là nguy hiểm?',
      answer:
          'Nhiệt độ trên 50°C được coi là nguy hiểm. Bạn có thể điều chỉnh ngưỡng cảnh báo trong Cài đặt > An toàn.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(title: const Text('Trợ giúp & Hỗ trợ')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Contact Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: Colors.purple[50],
              child: Column(
                children: [
                  Icon(
                    Icons.support_agent,
                    size: 64,
                    color: Colors.purple[600],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Cần hỗ trợ?',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Liên hệ với chúng tôi',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _sendSupportEmail(context),
                    icon: const Icon(Icons.email),
                    label: const Text('Gửi email hỗ trợ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // FAQ Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Câu hỏi thường gặp',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ..._faqs.map((faq) => _buildFAQCard(faq)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQCard(FAQItem faq) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          faq.question,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              faq.answer,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendSupportEmail(BuildContext context) async {
    const String supportEmail = 'lephinam260224@gmail.com';
    const String subject = 'Yêu cầu hỗ trợ - Smart Candles';
    const String body =
        'Xin chào,\n\nTôi cần hỗ trợ về ứng dụng Smart Candles.\n\n';

    // Create mailto URL
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: supportEmail,
      queryParameters: {'subject': subject, 'body': body},
    );

    try {
      // Try to launch the email client
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: Show dialog with email address
        if (context.mounted) {
          _showEmailDialog(context, supportEmail);
        }
      }
    } catch (e) {
      // Removed print statement: 'Error launching email: $e');
      // If launching fails, show dialog with email address
      if (context.mounted) {
        _showEmailDialog(context, supportEmail);
      }
    }
  }

  void _showEmailDialog(BuildContext context, String email) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gửi email hỗ trợ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vui lòng gửi email đến địa chỉ:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            SelectableText(
              email,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                // Copy email to clipboard
                await Clipboard.setData(ClipboardData(text: email));
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã sao chép email vào clipboard'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Sao chép email'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[600],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}

class FAQItem {
  final String question;
  final String answer;

  FAQItem({required this.question, required this.answer});
}
