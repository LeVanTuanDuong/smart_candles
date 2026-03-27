import 'dart:math' as math;

import 'package:flutter/material.dart';

class LightingQuickMode {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const LightingQuickMode({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class SmartsunControlPanel extends StatefulWidget {
  static const double _dialStart = -math.pi * 0.85;
  static const double _dialSweep = math.pi * 1.7;

  final bool isLightOn;
  final bool isBluetoothConnected;
  final String lightMode;
  final double brightness;
  final VoidCallback onTogglePower;
  final ValueChanged<double>? onBrightnessChanged;
  final ValueChanged<double>? onBrightnessChangeEnd;
  final List<LightingQuickMode> quickModes;

  const SmartsunControlPanel({
    super.key,
    required this.isLightOn,
    required this.isBluetoothConnected,
    required this.lightMode,
    required this.brightness,
    required this.onTogglePower,
    this.onBrightnessChanged,
    this.onBrightnessChangeEnd,
    required this.quickModes,
  });

  @override
  State<SmartsunControlPanel> createState() => _SmartsunControlPanelState();
}

class _SmartsunControlPanelState extends State<SmartsunControlPanel> {
  bool _isAdjustingFromDial = false;

  Color _modeColor() {
    switch (widget.lightMode) {
      case 'amber':
        return const Color(0xFFFFC35A);
      case 'blue':
        return const Color(0xFF7AB8FF);
      default:
        return const Color(0xFFFFD98A);
    }
  }

  @override
  Widget build(BuildContext context) {
    final modeColor = _modeColor();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.grey),
              const SizedBox(width: 6),
              const Text(
                'SmartSun Lighting',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                'Save',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: 250,
            height: 250,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanDown: (details) {
                if (widget.onBrightnessChanged == null) return;
                final value = _brightnessFromLocalPosition(details.localPosition);
                if (value == null) {
                  _isAdjustingFromDial = false;
                  return;
                }
                _isAdjustingFromDial = true;
                widget.onBrightnessChanged!(value);
              },
              onPanUpdate: (details) {
                if (!_isAdjustingFromDial || widget.onBrightnessChanged == null) {
                  return;
                }
                final value = _brightnessFromLocalPosition(details.localPosition);
                if (value != null) {
                  widget.onBrightnessChanged!(value);
                }
              },
              onPanEnd: (_) {
                if (!_isAdjustingFromDial || widget.onBrightnessChangeEnd == null) {
                  _isAdjustingFromDial = false;
                  return;
                }
                _isAdjustingFromDial = false;
                widget.onBrightnessChangeEnd!(widget.brightness.clamp(0.05, 1.0));
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(250, 250),
                    painter: _DialRingPainter(
                      progress: widget.brightness.clamp(0.05, 1.0),
                      activeColor: modeColor,
                    ),
                  ),
                  ..._buildRingQuickModeIcons(),
                  Container(
                    width: 132,
                    height: 132,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: modeColor.withValues(alpha: 0.35),
                          blurRadius: 16,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        InkWell(
                          onTap: widget.onTogglePower,
                          borderRadius: BorderRadius.circular(32),
                          child: Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: widget.isLightOn ? modeColor : Colors.grey[300],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.power_settings_new,
                                color: Colors.white, size: 26),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(widget.brightness.clamp(0.05, 1.0) * 100).round()}%',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: widget.isLightOn ? Colors.black87 : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.isBluetoothConnected
                ? 'Bluetooth connected'
                : 'Bluetooth disconnected',
            style: TextStyle(
              fontSize: 12,
              color: widget.isBluetoothConnected
                  ? Colors.green[700]
                  : Colors.orange[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _dot(const Color(0xFF2957A4)),
                _dot(const Color(0xFF264AA1)),
                _dot(const Color(0xFF1F3A8A)),
                _dot(const Color(0xFF19306E)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.quickModes.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.8,
            ),
            itemBuilder: (context, index) {
              final mode = widget.quickModes[index];
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: mode.onTap,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE3E7EE)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(mode.icon, size: 14, color: mode.color),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          mode.title,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _dot(Color color) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _tinyAction(IconData icon) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: null,
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
              ),
            ],
          ),
          child: Icon(icon, color: Colors.blueGrey, size: 15),
        ),
      ),
    );
  }

  List<Widget> _buildRingQuickModeIcons() {
    final items = widget.quickModes.take(6).toList();
    if (items.isEmpty) return const <Widget>[];

    // Place up to 6 preset icons around dial, aligned with preset grid below.
    const angles = <double>[
      -2.95, // left
      -2.2, // top-left
      -1.35, // top-right
      -0.05, // right
      0.95, // bottom-right
      2.05, // bottom-left
    ];
    const radius = 112.0;
    const center = Offset(125, 125);
    const iconSize = 28.0;

    final widgets = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      final mode = items[i];
      final angle = angles[i % angles.length];
      final x = center.dx + radius * math.cos(angle) - iconSize / 2;
      final y = center.dy + radius * math.sin(angle) - iconSize / 2;
      widgets.add(
        Positioned(
          left: x,
          top: y,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: mode.onTap,
            child: _tinyAction(mode.icon),
          ),
        ),
      );
    }
    return widgets;
  }

  double? _brightnessFromLocalPosition(Offset local) {
    const size = 250.0;
    final center = const Offset(size / 2, size / 2);
    final distance = (local - center).distance;
    if (distance < 86 || distance > 124) {
      return null;
    }
    final angle = math.atan2(local.dy - center.dy, local.dx - center.dx);
    final normalized = (angle - SmartsunControlPanel._dialStart) % (math.pi * 2);
    final clamped = normalized.clamp(0.0, SmartsunControlPanel._dialSweep);
    final progress = clamped / SmartsunControlPanel._dialSweep;
    return progress.clamp(0.05, 1.0);
  }
}

class _DialRingPainter extends CustomPainter {
  final double progress;
  final Color activeColor;

  _DialRingPainter({required this.progress, required this.activeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 16;
    const start = SmartsunControlPanel._dialStart;
    const sweep = SmartsunControlPanel._dialSweep;

    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..color = const Color(0xFFE7EDF8)
      ..strokeCap = StrokeCap.round;
    final activePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..shader = SweepGradient(
        startAngle: start,
        endAngle: start + sweep,
        colors: [
          activeColor.withValues(alpha: 0.45),
          activeColor,
          const Color(0xFF29216D),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      sweep,
      false,
      bgPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      sweep * progress,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DialRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.activeColor != activeColor;
  }
}
