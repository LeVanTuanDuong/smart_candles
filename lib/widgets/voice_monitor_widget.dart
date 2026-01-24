import 'package:flutter/material.dart';
import '../services/bluetooth_service.dart';

import '../models/mood_type.dart';

class VoiceMonitorWidget extends StatelessWidget {
  final BluetoothService bluetoothService;

  const VoiceMonitorWidget({
    super.key,
    required this.bluetoothService,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: bluetoothService,
      builder: (context, child) {
        if (!bluetoothService.isConnected) return const SizedBox.shrink();

        final userText = bluetoothService.lastUserText;
        final aiText = bluetoothService.lastAiResponse;
        final emotionKey = bluetoothService.lastDetectedEmotion;

        if (userText.isEmpty && aiText.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
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
            border: Border.all(
              color: Colors.blue.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.record_voice_over, color: Colors.blue[600]),
                  const SizedBox(width: 8),
                  const Text(
                    'Hội thoại trực tiếp',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (emotionKey.isNotEmpty) _buildEmotionBadge(emotionKey),
                ],
              ),
              const Divider(height: 24),
              if (userText.isNotEmpty) ...[
                const Text(
                  'Bạn nói:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ), // User Text
                const SizedBox(height: 4),
                Text(
                  userText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (aiText.isNotEmpty) ...[
                const Text(
                  'Nến trả lời:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  aiText,
                  style: TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: Colors.blue[800],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmotionBadge(String emotionKey) {
    final mood = _mapEmotionKeyToMoodType(emotionKey);
    Color color;
    IconData icon;
    String label;

    switch (mood) {
      case MoodType.sad:
        color = Colors.blue;
        icon = Icons.sentiment_dissatisfied;
        label = 'Buồn';
        break;
      case MoodType.stressed:
        color = Colors.orange;
        icon = Icons.sentiment_very_dissatisfied;
        label = 'Căng thẳng';
        break;
      case MoodType.tired:
        color = Colors.grey;
        icon = Icons.battery_alert;
        label = 'Mệt mỏi';
        break;
      case MoodType.insomnia:
        color = Colors.indigo;
        icon = Icons.nightlight_round;
        label = 'Mất ngủ';
        break;
      case MoodType.normal:
        color = Colors.green;
        icon = Icons.sentiment_satisfied;
        label = 'Ổn định';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label, // Should ideally map emotionKey directly if it's more descriptive
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  MoodType _mapEmotionKeyToMoodType(String emotionKey) {
    // Map keys from AiInferenceService
    // 'buồn', 'vui', 'hạnh phúc', 'tức_giận', 'lo_âu', 'ngạc_nhiên'

    final key = emotionKey.toLowerCase().trim();
    if (key.contains('buồn')) return MoodType.sad;
    if (key.contains('tức_giận') ||
        key.contains('lo_âu') ||
        key.contains('căng thẳng')) return MoodType.stressed;
    if (key.contains('mệt')) return MoodType.tired;
    if (key.contains('khó ngủ')) return MoodType.insomnia;

    // Default to normal for happy/surprise/etc
    return MoodType.normal;
  }
}
