import 'package:flutter/material.dart';
import 'package:beehive/utils/hexagonal.dart'; // Uses your HexClipper

// --- REPLACE YOUR OLD HEXAGONWIDGET WITH THIS ---
class HexagonWidget extends StatelessWidget {
  final IconData? icon;
  final Widget? child; // Can be an Icon or Text
  final bool isSelected;
  final double size;
  final Color? selectedColor;
  final Color? unselectedColor;
  final Color? iconSelectedColor;
  final Color? iconUnselectedColor;

  const HexagonWidget({
    Key? key,
    this.icon,
    this.child,
    required this.isSelected,
    this.size = 60.0,
    this.selectedColor,
    this.unselectedColor,
    this.iconSelectedColor,
    this.iconUnselectedColor,
  })  : assert(icon == null || child == null,
            'Cannot provide both an icon and a child'),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color bgColor = isSelected
        ? (selectedColor ?? const Color(0xFFFBBC04))
        : (unselectedColor ?? Colors.brown[700]!.withOpacity(0.6));

    final Color effectiveIconColor = isSelected
        ? (iconSelectedColor ?? Colors.white)
        : (iconUnselectedColor ?? Colors.white70);

    // Get the path from the clipper
    final Path path = HexClipper().getClip(Size(size, size));

    return CustomPaint(
      // 1. The Painter draws the shadow and the color
      painter: HexPainter(
        path: path,
        color: bgColor,
        shadowColor: Colors.white.withOpacity(0.8), // Your white shadow
        shadowBlur: 10.0, // Adjust the glow intensity here
      ),
      // 2. The child (Icon/Widget) is placed on top
      child: Container(
        width: size,
        height: size,
        child: Center(
          child: child ?? // Use child if provided
              (icon == null
                  ? const SizedBox.shrink()
                  : Icon(
                      icon,
                      color: effectiveIconColor,
                      size: size * 0.5,
                    )),
        ),
      ),
    );
  }
}

// --- ADD THIS HELPER CLASS ---
class HexPainter extends CustomPainter {
  final Path path;
  final Color color;
  final Color shadowColor;
  final double shadowBlur;

  HexPainter({
    required this.path,
    required this.color,
    required this.shadowColor,
    this.shadowBlur = 8.0, // Adjust the blur (glow) radius here
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw the shadow
    final Paint shadowPaint = Paint()
      ..color = shadowColor
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadowBlur);
    
    canvas.drawPath(path, shadowPaint);

    // 2. Draw the hexagon color on top
    final Paint colorPaint = Paint()..color = color;
    
    canvas.drawPath(path, colorPaint);
  }

  @override
  bool shouldRepaint(covariant HexPainter oldDelegate) {
    return oldDelegate.path != path ||
        oldDelegate.color != color ||
        oldDelegate.shadowColor != shadowColor ||
        oldDelegate.shadowBlur != shadowBlur;
  }
}