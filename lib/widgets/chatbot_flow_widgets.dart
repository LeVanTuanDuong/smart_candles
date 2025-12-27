import 'package:flutter/material.dart';
import '../models/mood_type.dart';
import '../services/chatbot_flow_service.dart';

/// Widget for mood selection chips (Flow 2: Check-in)
class MoodChipsWidget extends StatelessWidget {
  final Function(MoodType) onMoodSelected;

  const MoodChipsWidget({
    super.key,
    required this.onMoodSelected,
  });

  @override
  Widget build(BuildContext context) {
    final moods = [
      MoodType.stressed,
      MoodType.sad,
      MoodType.tired,
      MoodType.insomnia,
      MoodType.normal,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: moods.map((mood) {
          return ChoiceChip(
            label: Text('${mood.emoji} ${mood.label}'),
            selected: false,
            onSelected: (_) => onMoodSelected(mood),
            selectedColor: Colors.lightBlue[200],
            labelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Widget for intensity scale (0-10) (Flow 2: Check-in)
class IntensityScaleWidget extends StatelessWidget {
  final Function(int) onIntensitySelected;

  const IntensityScaleWidget({
    super.key,
    required this.onIntensitySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chấm theo thang 0–10:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(11, (index) {
              Color chipColor;
              if (index <= 3) {
                chipColor = Colors.green[300]!;
              } else if (index >= 4 && index <= 6) {
                chipColor = Colors.orange[300]!;
              } else {
                chipColor = Colors.red[300]!;
              }

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: ChoiceChip(
                    label: Text('$index'),
                    selected: false,
                    onSelected: (_) => onIntensitySelected(index),
                    selectedColor: chipColor,
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '0-3: Nhẹ',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green[700],
                ),
              ),
              Text(
                '4-6: Vừa',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange[700],
                ),
              ),
              Text(
                '7-10: Nặng',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Widget for context selection (Flow 2: Check-in)
class ContextChipsWidget extends StatelessWidget {
  final Function(String) onContextSelected;

  const ContextChipsWidget({
    super.key,
    required this.onContextSelected,
  });

  @override
  Widget build(BuildContext context) {
    final contexts = [
      {'label': 'Công việc/Học tập', 'value': 'work'},
      {'label': 'Mối quan hệ', 'value': 'relationship'},
      {'label': 'Sức khỏe', 'value': 'health'},
      {'label': 'Tài chính', 'value': 'finance'},
      {'label': 'Khác', 'value': 'other'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: contexts.map((ctx) {
          return ChoiceChip(
            label: Text(ctx['label']!),
            selected: false,
            onSelected: (_) => onContextSelected(ctx['value']!),
            selectedColor: Colors.lightBlue[200],
            labelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Widget for breathing exercise with timer (Flow 3: Grounding)
class BreathingExerciseWidget extends StatefulWidget {
  final Function() onComplete;
  final Function() onSkip;

  const BreathingExerciseWidget({
    super.key,
    required this.onComplete,
    required this.onSkip,
  });

  @override
  State<BreathingExerciseWidget> createState() =>
      _BreathingExerciseWidgetState();
}

class _BreathingExerciseWidgetState extends State<BreathingExerciseWidget>
    with TickerProviderStateMixin {
  int _currentRound = 0;
  int _totalRounds = 3;
  bool _isRunning = false;
  String _currentPhase = 'Chuẩn bị';
  int _countdown = 0;

  late AnimationController _breathController;
  late Animation<double> _breathAnimation;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12), // 4s in + 2s hold + 6s out
    );
    _breathAnimation = Tween<double>(begin: 0.5, end: 1.5).animate(
      CurvedAnimation(
        parent: _breathController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _startBreathing() {
    setState(() {
      _isRunning = true;
      _currentRound = 1;
      _currentPhase = 'Hít vào...';
      _countdown = 4;
    });

    _breathController.repeat(reverse: true);
    _runBreathingCycle();
  }

  void _runBreathingCycle() {
    if (_currentRound > _totalRounds) {
      _stopBreathing();
      widget.onComplete();
      return;
    }

    // Inhale: 4 seconds
    setState(() {
      _currentPhase = 'Hít vào...';
      _countdown = 4;
    });

    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      // Hold: 2 seconds
      setState(() {
        _currentPhase = 'Giữ...';
        _countdown = 2;
      });

      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        // Exhale: 6 seconds
        setState(() {
          _currentPhase = 'Thở ra...';
          _countdown = 6;
        });

        Future.delayed(const Duration(seconds: 6), () {
          if (!mounted) return;
          setState(() {
            _currentRound++;
          });
          _runBreathingCycle();
        });
      });
    });
  }

  void _stopBreathing() {
    setState(() {
      _isRunning = false;
      _currentPhase = 'Hoàn thành';
      _countdown = 0;
    });
    _breathController.stop();
    _breathController.reset();
  }

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.lightBlue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.lightBlue[200]!),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_isRunning)
            Text(
              'Hít vào 4 giây… giữ 2 giây… thở ra 6 giây.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
          if (_isRunning) ...[
            AnimatedBuilder(
              animation: _breathAnimation,
              builder: (context, child) {
                return Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.lightBlue[300]!.withOpacity(
                      0.3 + (_breathAnimation.value - 0.5) * 0.4,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$_countdown',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.lightBlue[800],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              _currentPhase,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.lightBlue[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Lần $_currentRound/$_totalRounds',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_isRunning)
                ElevatedButton.icon(
                  onPressed: _startBreathing,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Bắt đầu'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlue[400],
                    foregroundColor: Colors.white,
                  ),
                ),
              if (_isRunning)
                TextButton.icon(
                  onPressed: () {
                    _stopBreathing();
                    widget.onSkip();
                  },
                  icon: const Icon(Icons.skip_next),
                  label: const Text('Bỏ qua'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Widget for essential oil suggestions with buttons (Flow 4)
class EssentialOilSuggestionsWidget extends StatelessWidget {
  final MoodType mood;
  final Function(String) onOilSelected;

  const EssentialOilSuggestionsWidget({
    super.key,
    required this.mood,
    required this.onOilSelected,
  });

  @override
  Widget build(BuildContext context) {
    final suggestions = ChatbotFlowService.getEssentialOilSuggestions(mood);
    final oils = suggestions['primary']!;
    final descriptions = suggestions['descriptions']!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...List.generate(oils.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ElevatedButton(
                onPressed: () => onOilSelected(oils[index]),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlue[100],
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        descriptions[index],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Widget for music suggestions with play buttons (Flow 4)
class MusicSuggestionsWidget extends StatelessWidget {
  final MoodType mood;
  final Function(String, int) onMusicSelected; // music type, duration in minutes

  const MusicSuggestionsWidget({
    super.key,
    required this.mood,
    required this.onMusicSelected,
  });

  @override
  Widget build(BuildContext context) {
    final suggestions = ChatbotFlowService.getMusicSuggestions(mood);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...suggestions.map((suggestion) {
            final duration = int.tryParse(
                  suggestion['duration']!.replaceAll(RegExp(r'[^0-9]'), ''),
                ) ??
                10;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ElevatedButton.icon(
                onPressed: () => onMusicSelected(
                  suggestion['type']!,
                  duration,
                ),
                icon: const Icon(Icons.music_note),
                label: Expanded(
                  child: Text(
                    'Phát ${suggestion['type']} ${suggestion['duration']}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple[100],
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Widget for light suggestion with on/off button (Flow 4)
class LightSuggestionWidget extends StatelessWidget {
  final MoodType mood;
  final int? intensity;
  final Function(String, double) onLightSelected; // mode, brightness

  const LightSuggestionWidget({
    super.key,
    required this.mood,
    this.intensity,
    required this.onLightSelected,
  });

  @override
  Widget build(BuildContext context) {
    final suggestion = ChatbotFlowService.getLightSuggestion(mood, intensity);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            suggestion['message'] as String,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => onLightSelected(
                    suggestion['mode'] as String,
                    suggestion['brightness'] as double,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[400],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Bật đèn'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Không'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Widget for common thoughts selection (Flow 6: CBT)
class CommonThoughtsWidget extends StatelessWidget {
  final Function(String) onThoughtSelected;

  const CommonThoughtsWidget({
    super.key,
    required this.onThoughtSelected,
  });

  @override
  Widget build(BuildContext context) {
    final thoughts = ChatbotFlowService.getCommonThoughts();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: thoughts.map((thought) {
          return ChoiceChip(
            label: Text(thought),
            selected: false,
            onSelected: (_) => onThoughtSelected(thought),
            selectedColor: Colors.lightBlue[200],
            labelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Widget for small actions selection (Flow 6: CBT)
class SmallActionsWidget extends StatelessWidget {
  final Function(String) onActionSelected;

  const SmallActionsWidget({
    super.key,
    required this.onActionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final actions = ChatbotFlowService.getSmallActions();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ChatbotFlowService.getSmallActionMessage(),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          ...actions.map((action) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ElevatedButton(
                onPressed: () => onActionSelected(action['action']!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[100],
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      action['action']!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      action['time']!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

