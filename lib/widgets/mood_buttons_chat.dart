import 'package:flutter/material.dart';
import '../models/mood_type.dart';

class MoodButtonsChat extends StatelessWidget {
  final Function(MoodType) onMoodSelected;

  const MoodButtonsChat({
    super.key,
    required this.onMoodSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _buildMoodButton(MoodType.stressed),
            const SizedBox(width: 8),
            _buildMoodButton(MoodType.sad),
            const SizedBox(width: 8),
            _buildMoodButton(MoodType.tired),
            const SizedBox(width: 8),
            _buildMoodButton(MoodType.insomnia),
            const SizedBox(width: 8),
            _buildMoodButton(MoodType.normal),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodButton(MoodType mood) {
    return InkWell(
      onTap: () => onMoodSelected(mood),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.lightBlue[300]!,
            width: 1,
          ),
        ),
        child: Text(
          mood.label,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

