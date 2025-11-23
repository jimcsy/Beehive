import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:beehive/utils/hexagonal.dart';

// Import your screen files here so navigation works
import 'package:beehive/features/students/modules/supabase_code_screen.dart';
import 'package:beehive/features/students/modules/supabase_game_screen.dart';
import 'package:beehive/features/students/modules/supabase_quiz_screen.dart';
import 'package:beehive/features/students/modules/supabase_reading_screen.dart';
import 'package:beehive/features/students/modules/supabase_video_screen.dart';

class ViewUnitsLayout extends StatelessWidget {
  final String moduleTitle;
  final String unitTitle;
  final String lessonTitle;
  final List<DocumentSnapshot> lessons;
  final int selectedIndex;
  final ValueChanged<int> onLessonTap;
  final Map<String, dynamic> lessonProgressMap;
  final String moduleId;
  final String roomId;
  final String userId;

  const ViewUnitsLayout({
    Key? key,
    required this.moduleTitle,
    required this.unitTitle,
    required this.lessonTitle,
    required this.lessons,
    required this.selectedIndex,
    required this.onLessonTap,
    required this.lessonProgressMap,
    required this.moduleId,
    required this.roomId,
    required this.userId,
  }) : super(key: key);

  // Robust category matching for Images
  String _getImageAssetForCategory(String? category) {
    final cat = category?.toLowerCase().trim() ?? '';

    if (cat.contains('read')) return 'assets/icons/images/reading.png';
    if (cat.contains('video')) return 'assets/icons/images/vid_tutorial.png';
    if (cat.contains('quiz')) return 'assets/icons/images/quiz.png';
    if (cat.contains('code') || cat.contains('practice')) {
      return 'assets/icons/images/ide_practice.png';
    }
    if (cat.contains('activity') ||
        cat.contains('bulb') ||
        cat.contains('game')) {
      return 'assets/icons/images/activity.png';
    }

    return 'assets/icons/images/reading.png'; // Fallback
  }

  void _navigateToLesson(BuildContext context, DocumentSnapshot lesson) {
    final lessonData = lesson.data() as Map<String, dynamic>? ?? {};
    final String rawCategory = lessonData['category'] ?? 'unknown';
    final String category = rawCategory.toLowerCase().trim();
    final String newLessonTitle = lessonData['title'] ?? 'Lesson';

    if (category.contains('read')) {
      final List<String> contentIDs =
          List<String>.from(lessonData['contentBlockIds'] ?? []);
      if (contentIDs.isNotEmpty) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => PagedReadingScreen(
                      lessonTitle: newLessonTitle,
                      contentIDs: contentIDs,
                      moduleId: moduleId,
                      roomId: roomId,
                      lessonId: lesson.id,
                    )));
      }
    } else if (category.contains('video')) {
      final List<String> contentIDs =
          List<String>.from(lessonData['contentBlockIds'] ?? []);
      if (contentIDs.isNotEmpty) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => VideoLessonScreen(
                      contentIDs: contentIDs,
                      moduleId: moduleId,
                      roomId: roomId,
                      lessonId: lesson.id,
                    )));
      }
    } else if (category.contains('quiz')) {
      final List<String> contentIDs =
          List<String>.from(lessonData['contentBlockIds'] ?? []);
      if (contentIDs.isNotEmpty) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => QuizLessonScreen(
                      contentIDs: contentIDs,
                      lessonTitle: lessonData['title'] ?? 'Quiz',
                      moduleId: moduleId,
                      roomId: roomId,
                      lessonId: lesson.id,
                      userId: userId,
                    )));
      }
    } else if (category.contains('code')) {
      final List<String> contentIDs =
          List<String>.from(lessonData['contentBlockIds'] ?? []);
      if (contentIDs.isNotEmpty) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => CodeScreen(
                      contentID: contentIDs.first,
                      moduleId: moduleId,
                      roomId: roomId,
                      lessonId: lesson.id,
                    )));
      }
    } else if (category.contains('activity') ||
        category.contains('bulb') ||
        category.contains('game')) {
      final List<String> contentIDs =
          List<String>.from(lessonData['contentBlockIds'] ?? []);
      if (contentIDs.isNotEmpty) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => DragDropGameScreen(
                      contentIDs: contentIDs,
                      moduleId: moduleId,
                      roomId: roomId,
                      lessonId: lesson.id,
                    )));
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Error: No activity found.')));
      }
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Unknown category: $category')));
    }
  }

  bool _isLessonLocked(int index) {
    if (index == 0) return false;
    // Safety check
    if (index - 1 < 0 || index - 1 >= lessons.length) return true;
    
    final prevLessonId = lessons[index - 1].id;
    final bool isPrevComplete = lessonProgressMap[prevLessonId] == true;
    return !isPrevComplete;
  }

  void _showLockedMessage(BuildContext context, int index) {
    final lessonData = lessons[index - 1].data() as Map<String, dynamic>;
    final prevLessonTitle = lessonData['title'] ?? 'the previous lesson';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Complete "$prevLessonTitle" first!'),
        backgroundColor: Colors.red[700],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              Color.fromARGB(255, 255, 241, 198),
              Color.fromARGB(106, 251, 189, 4),
              Color.fromARGB(255, 255, 241, 198),
              Colors.white,
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        // 🌟 FIX: CrossAxisAlignment.stretch prevents RenderFlex errors
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHiveDisplay(
              context,
              moduleTitle,
              lessonTitle,
              lessons,
              selectedIndex,
            ),
            _buildLessonList(context, lessons),
          ],
        ),
      ),
    );
  }

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
      Offset(0, -ySeparation * 2),
      Offset(-xSeparation, -ySeparation),
      Offset(xSeparation, -ySeparation),
      const Offset(0, 0),
      Offset(-xSeparation, ySeparation),
      Offset(xSeparation, ySeparation),
      Offset(0, ySeparation * 2),
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
                  final lessonData =
                      lesson.data() as Map<String, dynamic>? ?? {};
                  final bool isSelected = index == selectedIndex;

                  final String assetPath =
                      _getImageAssetForCategory(lessonData['category']);

                  final bool isLocked = _isLessonLocked(index);

                  return Transform.translate(
                    offset: hivePositions[index],
                    child: GestureDetector(
                      onTap: () {
                        if (isLocked) {
                          _showLockedMessage(context, index);
                        } else {
                          onLessonTap(index);
                          _navigateToLesson(context, lesson);
                        }
                      },
                      child: HexagonWidget(
                        isSelected: isSelected,
                        isLocked: isLocked,
                        size: hiveSize,
                        assetPath: assetPath,
                        // 🌟 COLORS: Brown for unselected/locked, Gold for selected
                        selectedColor: const Color(0xFFFBBC04), 
                        unselectedColor: const Color(0xFFA27221), 
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

  Widget _buildLessonList(
      BuildContext context, List<DocumentSnapshot> lessons) {
    
    // 🌟 Safety calculation for progress
    double progress = 0.0;
    if (lessons.isNotEmpty) {
      int completedCount = 0;
      for (var lesson in lessons) {
        if (lessonProgressMap.containsKey(lesson.id) && 
            lessonProgressMap[lesson.id] == true) {
          completedCount++;
        }
      }
      progress = completedCount / lessons.length;
    }

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 🌟 PROGRESS BAR AREA 🌟
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 45.0, vertical: 0),
            child: Row(
              children: [
                Expanded(
                  // White Container wrapping the progress bar
                  child: Container(
                    height: 10, 
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(1.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8, 
                        backgroundColor: Colors.grey[400],
                        valueColor: const AlwaysStoppedAnimation<Color>(Color.fromARGB(255, 33, 150, 243)), // Blue
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  "${(progress * 100).toInt()}%",
                  style: const TextStyle(
                    color: Color.fromARGB(221, 129, 116, 0),
                    fontWeight: FontWeight.w400,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          // 🌟 LESSON LIST CONTAINER 🌟
          Expanded(
            child: Container(
              // 🌟 CHANGE: RESTORED PADDING TO EdgeInsets.all(20) (Similar to Last File) 🌟
              margin: const EdgeInsets.all(20), 
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(24)), // Made all corners rounded
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 16), // Top padding (Replaces the handle)
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

                        final assetPath = _getImageAssetForCategory(category);

                        final isSelected = index == selectedIndex;
                        final bool isLocked = _isLessonLocked(index);

                        // 🌟 CHECK IF LESSON IS COMPLETED 🌟
                        final bool isCompleted = 
                            lessonProgressMap.containsKey(lesson.id) && 
                            lessonProgressMap[lesson.id] == true;

                        return LessonListTile(
                          title: lessonTitle,
                          assetPath: assetPath,
                          isSelected: isSelected,
                          isLocked: isLocked,
                          isCompleted: isCompleted, // Pass the completed status
                          onTap: () {
                            if (isLocked) {
                              _showLockedMessage(context, index);
                            } else {
                              onLessonTap(index);
                              _navigateToLesson(context, lesson);
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- REUSABLE WIDGETS ---

class LessonListTile extends StatelessWidget {
  final String title;
  final String assetPath;
  final bool isSelected;
  final bool isLocked;
  final bool isCompleted; // Added parameter
  final VoidCallback onTap;

  const LessonListTile({
    Key? key,
    required this.title,
    required this.assetPath,
    required this.isSelected,
    this.isLocked = false,
    this.isCompleted = false, // Default false
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 🌟 VISUAL LOGIC: 
    // 1. Locked -> Grey
    // 2. Selected OR Completed -> Blue
    // 3. Default -> Light Grey
    final bool isHighlighted = isSelected || isCompleted;

    final Color cardColor = isLocked
        ? const Color(0xFFE0E0E0)
        : isHighlighted
            ? Colors.blue
            : const Color(0xFFF0F0F0);

    final Color textColor = isLocked
        ? Colors.grey[600]!
        : isHighlighted
            ? Colors.white
            : Colors.black;

    return Card(
      color: cardColor,
      elevation: isSelected ? 2 : 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        leading: HexagonWidget(
          assetPath: assetPath,
          isSelected: isSelected,
          isLocked: isLocked,
          isCompleted: isCompleted, // Pass completed status
          size: 50,
          selectedColor: Colors.white,
          unselectedColor: const Color(0xFFFBBC04),
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

class HexagonWidget extends StatelessWidget {
  final String? assetPath;
  final Widget? child;
  final bool isSelected;
  final bool isLocked;
  final bool isCompleted; // Added parameter
  final double size;
  final Color? selectedColor;
  final Color? unselectedColor;

  const HexagonWidget({
    Key? key,
    this.assetPath,
    this.child,
    required this.isSelected,
    this.isLocked = false,
    this.isCompleted = false, // Default false
    this.size = 60.0,
    this.selectedColor,
    this.unselectedColor,
  })  : assert(assetPath == null || child == null,
            'Cannot provide both an image path and a child'),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color safeSelected = selectedColor ?? const Color(0xFFFBBC04);
    final Color safeUnselected = unselectedColor ?? const Color(0xFFA27221);

    final Color bgColor = isSelected ? safeSelected : safeUnselected;

    final Path path = HexClipper().getClip(Size(size, size));

    return CustomPaint(
      painter: HexPainter(
        path: path,
        color: bgColor,
        shadowColor: Colors.white.withOpacity(0.8),
        shadowBlur: 10.0,
      ),
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        padding: EdgeInsets.zero,
        // 🌟 CHILD CONTENT LOGIC:
        // 1. Locked: Show Nothing
        // 2. Unlocked & (Selected OR Completed): Show Image normal opacity (1.0)
        // 3. Unlocked & Not Selected/Completed: Show Image reduced opacity (0.5)
        child: child ??
            (!isLocked && assetPath != null
                ? Opacity(
                    opacity: (isSelected || isCompleted) ? 1.0 : 0.5,
                    child: Image.asset(
                      assetPath!,
                      fit: BoxFit.contain,
                    ),
                  )
                : const SizedBox.shrink()),
      ),
    );
  }
}

class HexPainter extends CustomPainter {
  final Path path;
  final Color color;
  final Color shadowColor;
  final double shadowBlur;

  HexPainter({
    required this.path,
    required this.color,
    required this.shadowColor,
    this.shadowBlur = 8.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint shadowPaint = Paint()
      ..color = shadowColor
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadowBlur);

    canvas.drawPath(path, shadowPaint);

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