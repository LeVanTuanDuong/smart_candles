import 'package:flutter/material.dart';
import 'dart:async';

class MeditationGuideScreen extends StatefulWidget {
  final String? currentTrack;
  final bool isPlaying;
  
  const MeditationGuideScreen({
    super.key,
    this.currentTrack,
    this.isPlaying = false,
  });

  @override
  State<MeditationGuideScreen> createState() => _MeditationGuideScreenState();
}

class _MeditationGuideScreenState extends State<MeditationGuideScreen>
    with SingleTickerProviderStateMixin {
  bool _isPlaying = false;
  Duration _currentPosition = const Duration(seconds: 1);
  Duration _totalDuration = const Duration(seconds: 31);
  Timer? _timer;
  late AnimationController _waveformController;

  final List<MeditationTrack> _suggestedTracks = [
    MeditationTrack(
      title: 'Hơi thở Chánh niệm',
      subtitle: 'Hơi thở thiền gợi ý',
      imageType: 'forest',
    ),
    MeditationTrack(
      title: 'Hơi thở Thiền',
      subtitle: 'Hơi thở thiền gợi ý',
      imageType: 'meditation',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _isPlaying = widget.isPlaying;
    _waveformController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
    
    if (_isPlaying) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _waveformController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_currentPosition < _totalDuration) {
            _currentPosition = Duration(seconds: _currentPosition.inSeconds + 1);
          } else {
            _currentPosition = _totalDuration;
            _isPlaying = false;
            timer.cancel();
          }
        });
      }
    });
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _startTimer();
        _waveformController.repeat();
      } else {
        _timer?.cancel();
        _waveformController.stop();
      }
    });
  }

  void _seekTo(Duration position) {
    setState(() {
      _currentPosition = position;
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final currentTrackTitle = widget.currentTrack ?? 'Hơi thở Chánh niệm';
    
    return Scaffold(
      backgroundColor: Colors.amber[50],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Hướng dẫn Thiền',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // Track Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                currentTrackTitle,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Audio Visualizer
            Center(
              child: _buildAudioVisualizer(),
            ),
            const SizedBox(height: 40),
            // Playback Controls
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildControlButton(Icons.skip_previous),
                  const SizedBox(width: 20),
                  _buildPlayPauseButton(),
                  const SizedBox(width: 20),
                  _buildControlButton(Icons.skip_next),
                ],
              ),
            ),
            const SizedBox(height: 30),
            // Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.blue[700],
                      inactiveTrackColor: Colors.grey[300],
                      thumbColor: Colors.white,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 8,
                      ),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: _currentPosition.inSeconds.toDouble(),
                      min: 0,
                      max: _totalDuration.inSeconds.toDouble(),
                      onChanged: (value) {
                        _seekTo(Duration(seconds: value.toInt()));
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(_currentPosition),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        '-${_formatDuration(_totalDuration - _currentPosition)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // Suggestions Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Gợi ý',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Suggestion Cards
            ..._suggestedTracks.map((track) => _buildSuggestionCard(track)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioVisualizer() {
    return AnimatedBuilder(
      animation: _waveformController,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left waveform
            _buildWaveform(isLeft: true),
            const SizedBox(width: 20),
            // Center meditation icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.orange[200],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.self_improvement,
                size: 60,
                color: Colors.blue[900],
              ),
            ),
            const SizedBox(width: 20),
            // Right waveform
            _buildWaveform(isLeft: false),
          ],
        );
      },
    );
  }

  Widget _buildWaveform({required bool isLeft}) {
    final bars = List.generate(8, (index) {
      final delay = index * 0.1;
      final animationValue = (_waveformController.value + delay) % 1.0;
      final height = _isPlaying
          ? 20 + (animationValue * 40)
          : 20.0;
      
      return Container(
        width: 4,
        height: height,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: Colors.blue[900],
          borderRadius: BorderRadius.circular(2),
        ),
      );
    });
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: bars,
    );
  }

  Widget _buildControlButton(IconData icon) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.blue[700],
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: () {
          // Handle previous/next
        },
      ),
    );
  }

  Widget _buildPlayPauseButton() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.blue[700],
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(
          _isPlaying ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
          size: 32,
        ),
        onPressed: _togglePlayPause,
      ),
    );
  }

  Widget _buildSuggestionCard(MeditationTrack track) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: track.imageType == 'forest'
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.green[400]!,
                        Colors.green[600]!,
                      ],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.orange[300]!,
                        Colors.pink[300]!,
                      ],
                    ),
            ),
            child: track.imageType == 'forest'
                ? Stack(
                    children: [
                      // Tree trunk
                      Positioned(
                        bottom: 10,
                        left: 30,
                        child: Container(
                          width: 20,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.brown[700],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      // Tree leaves
                      Positioned(
                        top: 15,
                        left: 25,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.green[800],
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      // Sun rays
                      Positioned(
                        top: 5,
                        right: 5,
                        child: Icon(
                          Icons.wb_sunny,
                          color: Colors.yellow[300],
                          size: 20,
                        ),
                      ),
                    ],
                  )
                : Icon(
                    Icons.self_improvement,
                    size: 50,
                    color: Colors.blue[900],
                  ),
          ),
          const SizedBox(width: 16),
          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  track.subtitle,
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

class MeditationTrack {
  final String title;
  final String subtitle;
  final String imageType; // 'forest' or 'meditation'

  MeditationTrack({
    required this.title,
    required this.subtitle,
    required this.imageType,
  });
}

