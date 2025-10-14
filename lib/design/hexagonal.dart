import 'package:flutter/material.dart';
import 'dart:math';

class HexFloatingButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Color color;
  final Widget child;
  final double size;

  const HexFloatingButton({
    required this.onPressed,
    this.color = Colors.blue,
    required this.child,
    this.size = 70,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: HexClipper(),
      child: Material(
        color: color,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: size,
            height: size,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

class HexClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final double w = size.width;
    final double h = size.height;
    final double side = w / 2;

    Path path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (pi / 3 * i) - pi / 6;
      final x = w / 2 + side * cos(angle);
      final y = h / 2 + side * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
