import 'package:beehive/features/students/modules/hexagon_homepage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:beehive/utils/hexagonal.dart'; // Import your clipper
import 'lesson_list_tile.dart'; // <-- Import the new tile

class ViewUnitsLayout extends StatelessWidget {
  final String moduleTitle;
  final String unitTitle;
  final String lessonTitle;
  final List<DocumentSnapshot> lessons;
  final int selectedIndex;
  final ValueChanged<int> onLessonTap; // Callback function

  const ViewUnitsLayout({
    Key? key,
    required this.moduleTitle,
    required this.unitTitle,
    required this.lessonTitle,
    required this.lessons,
    required this.selectedIndex,
    required this.onLessonTap,
  }) : super(key: key);

  // Helper function to get an icon based on category
  IconData? _getIconForCategory(String? category) {
    switch (category) {
      case 'reading':
        return Icons.menu_book_outlined; // Book icon
      case 'video':
        return Icons.play_circle_outlined; // Play icon
      case 'quiz':
        return Icons.quiz_outlined; // Quiz icon
      case 'code':
        return Icons.code_outlined;
      case 'game':
        return Icons.gamepad_outlined; // Controller icon
      case 'bulb':
        return Icons.lightbulb_outline; // Bulb icon
      default:
        return null;
    }
  }

  // Central navigation function
  void _navigateToLesson(BuildContext context, DocumentSnapshot lesson) {
    final lessonData = lesson.data() as Map<String, dynamic>? ?? {};
    final lessonTitle = lessonData['title'] ?? 'Lesson';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(lessonTitle),
        content: Text(
            "Showing lesson content for: ${lessonData['description'] ?? '...'}"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color.fromARGB(255, 255, 241, 198), Color.fromARGB(106, 251, 189, 4), Color.fromARGB(255, 255, 241, 198), Colors.white, Colors.white,],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // --- TOP HIVE DISPLAY ---
              _buildHiveDisplay(
                context,
                moduleTitle,
                lessonTitle,
                lessons,
                selectedIndex,
              ),
          
              // --- BOTTOM LESSON LIST ---
              _buildLessonList(context, lessons),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget for the top hive display
  Widget _buildHiveDisplay(
    BuildContext context,
    String moduleTitle,
    String lessonTitle,
    List<DocumentSnapshot> lessons,
    int selectedIndex,
  ) {
    const double hiveSize = 100.0;
    final double verticalSpacingFactor = 0.64;
    final double ySeparation = hiveSize * 0.72 * verticalSpacingFactor;
    final double xSeparation = hiveSize * 0.80;

    final List<Offset> hivePositions = [
      Offset(0, -ySeparation * 2), // Topmost
      Offset(-xSeparation, -ySeparation), // Top-Left
      Offset(xSeparation, -ySeparation), // Top-Right
      Offset(0, 0), // Center
      Offset(-xSeparation, ySeparation), // Bottom-Left
      Offset(xSeparation, ySeparation), // Bottom-Right
      Offset(0, ySeparation * 2), // Bottommost
    ];
    
    final double stackHeight = (ySeparation * 4) + hiveSize;

    return Container(
      height: stackHeight + 100,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Text(
            moduleTitle,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            lessonTitle.toUpperCase(),
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: xSeparation * 2.5,
            height: stackHeight,
            child: Stack(
              alignment: Alignment.center,
              children: List.generate(
                lessons.length > 7 ? 7 : lessons.length,
                (index) {
                  final lesson = lessons[index];
                  final lessonData = lesson.data() as Map<String, dynamic>? ?? {};
                  final bool isSelected = index == selectedIndex;
                  final IconData? iconForThisHive =
                      _getIconForCategory(lessonData['category']);

                  return Transform.translate(
                    offset: hivePositions[index],
                    child: GestureDetector(
                      onTap: () {
                        if (isSelected) {
                          _navigateToLesson(context, lesson);
                        } else {
                          onLessonTap(index);
                        }
                      },
                      child: HexagonWidget(
                        isSelected: isSelected,
                        size: hiveSize,
                        child: iconForThisHive != null
                            ? Icon(
                                iconForThisHive,
                                color: isSelected ? Colors.white : Colors.white70,
                                size: hiveSize * 0.5,
                              )
                            : const SizedBox.shrink(),
                        selectedColor: Color(0xFFFBBC04),
                        unselectedColor: Color(0xFFA27221)!,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for the bottom draggable-style sheet
  Widget _buildLessonList(BuildContext context, List<DocumentSnapshot> lessons) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          margin: const EdgeInsets.only(top: 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12, 
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag Handle
              Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              // The List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: lessons.length,
                  itemBuilder: (context, index) {
                    final lesson = lessons[index];
                    final lessonData =
                        lesson.data() as Map<String, dynamic>? ?? {};
                    final lessonTitle = lessonData['title'] ?? 'Lesson';
                    final category = lessonData['category'];
                    final icon = _getIconForCategory(category);
                    final isSelected = index == selectedIndex;

                    return LessonListTile(
                      title: lessonTitle,
                      icon: icon,
                      isSelected: isSelected,
                      onTap: () {
                        onLessonTap(index);
                        _navigateToLesson(context, lesson);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}