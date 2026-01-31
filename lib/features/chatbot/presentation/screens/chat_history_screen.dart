import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_candles/features/chatbot/models/message.dart';
import 'package:smart_candles/features/chatbot/services/chat_history_service.dart';

class ChatHistoryScreen extends StatefulWidget {
  const ChatHistoryScreen({super.key});

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  List<ChatMessage> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final history = await ChatHistoryService.getHistory();
    setState(() {
      _history = history.reversed.toList(); // Newest first
      _isLoading = false;
    });
  }

  Future<void> _clearHistory() async {
    await ChatHistoryService.clearHistory();
    _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử tin nhắn'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                        title: const Text("Xoá lịch sử?"),
                        content: const Text(
                            "Bạn có chắc muốn xoá toàn bộ tin nhắn đã lưu?"),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text("Huỷ")),
                          TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _clearHistory();
                              },
                              child: const Text("Xoá")),
                        ],
                      ));
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularCircularProgressIndicator())
          : _history.isEmpty
              ? const Center(child: Text("Chưa có lịch sử nhắn tin nào."))
              : ListView.builder(
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final msg = _history[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            msg.isBot ? Colors.blue[100] : Colors.green[100],
                        child: Icon(msg.isBot ? Icons.smart_toy : Icons.person,
                            size: 20, color: Colors.grey[800]),
                      ),
                      title: Text(msg.text),
                      subtitle: Text(
                          DateFormat('HH:mm dd/MM/yyyy').format(msg.timestamp)),
                    );
                  },
                ),
    );
  }
}

// Note: CircularCircularProgressIndicator typo correction
class CircularCircularProgressIndicator extends StatelessWidget {
  const CircularCircularProgressIndicator({super.key});
  @override
  Widget build(BuildContext context) {
    return const CircularProgressIndicator();
  }
}
