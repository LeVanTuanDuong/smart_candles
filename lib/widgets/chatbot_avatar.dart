import 'package:flutter/material.dart';

class ChatbotAvatar extends StatelessWidget {
  final double size;

  const ChatbotAvatar({
    super.key,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.lightBlue[300],
        shape: BoxShape.circle,
      ),
      child: Stack(
        children: [
          // Face (white circle)
          Positioned(
            left: size * 0.2,
            top: size * 0.2,
            child: Container(
              width: size * 0.6,
              height: size * 0.6,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Left cheek (pink)
          Positioned(
            left: size * 0.15,
            top: size * 0.4,
            child: Container(
              width: size * 0.15,
              height: size * 0.15,
              decoration: BoxDecoration(
                color: Colors.pink[200],
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Right cheek (pink)
          Positioned(
            right: size * 0.15,
            top: size * 0.4,
            child: Container(
              width: size * 0.15,
              height: size * 0.15,
              decoration: BoxDecoration(
                color: Colors.pink[200],
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Eyes
          Positioned(
            left: size * 0.3,
            top: size * 0.35,
            child: Container(
              width: size * 0.08,
              height: size * 0.08,
              decoration: const BoxDecoration(
                color: Colors.black87,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: size * 0.3,
            top: size * 0.35,
            child: Container(
              width: size * 0.08,
              height: size * 0.08,
              decoration: const BoxDecoration(
                color: Colors.black87,
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Mouth (smile - using clip path)
          Positioned(
            left: size * 0.35,
            top: size * 0.52,
            child: SizedBox(
              width: size * 0.3,
              height: size * 0.15,
              child: CustomPaint(
                painter: _SmilePainter(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmilePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height * 0.3);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height,
      size.width,
      size.height * 0.3,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

