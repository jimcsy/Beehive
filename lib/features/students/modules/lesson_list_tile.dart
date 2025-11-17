import 'package:beehive/features/students/modules/hexagon_homepage.dart';
import 'package:flutter/material.dart';

class LessonListTile extends StatelessWidget {
  final String title;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  const LessonListTile({
    Key? key,
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color cardColor = isSelected ? Colors.blue : const Color(0xFFF0F0F0);
    final Color textColor = isSelected ? Colors.white : Colors.black;

    return Card(
      color: cardColor,
      elevation: isSelected ? 2 : 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        leading: HexagonWidget(
          icon: icon, // Pass specific icon
          isSelected: isSelected,
          size: 50,
          selectedColor: Colors.white,
          unselectedColor: const Color(0xFFFBBC04),
          iconSelectedColor: Colors.blue,
          iconUnselectedColor: Colors.white,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: textColor,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}