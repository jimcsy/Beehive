import 'package:beehive/features/students/modules/supabase_code_screen.dart';
import 'package:beehive/features/students/modules/supabase_game_screen.dart';
import 'package:beehive/features/students/modules/supabase_quiz_screen.dart';
import 'package:beehive/features/students/modules/supabase_reading_screen.dart';
import 'package:beehive/features/students/modules/supabase_video_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:beehive/utils/hexagonal.dart'; // Uses your HexClipper

// --- 1. DATA & STATE LOGIC ---

class ViewUnitsTab extends StatefulWidget {
  final String roomId;
  final String moduleId;
  final String userId;

  const ViewUnitsTab({
    super.key,
    required this.roomId,
    required this.moduleId,
    required this.userId,
  });

  @override
  State<ViewUnitsTab> createState() => _ViewUnitsTabState();
}

class _ViewUnitsTabState extends State<ViewUnitsTab> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final moduleRef =
        FirebaseFirestore.instance.collection('modules').doc(widget.moduleId);

    // 🌟 FIX: READ FROM THE COMPOSITE ID (RoomID_ModuleID)
    final uniqueProgressId = '${widget.roomId}_${widget.moduleId}';

    final progressRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('progress')
        .doc(uniqueProgressId);

    return FutureBuilder<DocumentSnapshot>(
      future: moduleRef.get(),
      builder: (context, moduleSnapshot) {
        if (moduleSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (moduleSnapshot.hasError) {
          return Center(child: Text('Error: ${moduleSnapshot.error}'));
        }
        if (!moduleSnapshot.hasData || !moduleSnapshot.data!.exists) {
          return const Center(child: Text('Module not found.'));
        }

        final moduleData =
            moduleSnapshot.data!.data() as Map<String, dynamic>? ?? {};
        final moduleTitle = moduleData['title'] ?? 'Untitled Module';
        final lessonsRef = moduleRef.collection('lessons');

        return StreamBuilder<DocumentSnapshot>(
          stream: progressRef.snapshots(),
          builder: (context, progressSnapshot) {
            if (progressSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (progressSnapshot.hasError) {
              return Center(
                  child: Text("Progress Error: ${progressSnapshot.error}"));
            }

            // If no progress doc exists yet, handle gracefully
            if (!progressSnapshot.hasData || !progressSnapshot.data!.exists) {
              return const Center(
                  child: Text(
                      'Initializing Module... (Please re-join room if this persists)'));
            }

            final progressData =
                progressSnapshot.data!.data() as Map<String, dynamic>? ?? {};
            final Map<String, dynamic> lessonProgressMap =
                (progressData['lessons'] as Map<String, dynamic>?) ?? {};

            return StreamBuilder<QuerySnapshot>(
              stream: lessonsRef.snapshots(),
              builder: (context, lessonSnapshot) {
                if (lessonSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (lessonSnapshot.hasError) {
                  return Center(
                      child: Text('Lesson Error: ${lessonSnapshot.error}'));
                }
                if (lessonSnapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text('No lessons found for this module.'));
                }

                final lessons = lessonSnapshot.data!.docs;
                // Sort by ID to ensure correct order
                lessons.sort((a, b) => a.id.compareTo(b.id));

                if (_selectedIndex >= lessons.length) {
                  _selectedIndex = 0;
                }

                final selectedLesson = lessons[_selectedIndex];
                final selectedLessonData =
                    selectedLesson.data() as Map<String, dynamic>? ?? {};

                final unitTitle =
                    "Unit ${selectedLessonData['orderIndex'] ?? _selectedIndex + 1}";
                final lessonTitle = selectedLessonData['title'] ?? 'Lesson';

                return ViewUnitsLayout(
                  moduleTitle: moduleTitle,
                  unitTitle: unitTitle,
                  lessonTitle: lessonTitle,
                  lessons: lessons,
                  selectedIndex: _selectedIndex,
                  lessonProgressMap: lessonProgressMap,
                  moduleId: widget.moduleId,
                  roomId: widget.roomId,
                  userId: widget.userId,
                  onLessonTap: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

// --- 2. LAYOUT WIDGET ---

class ViewUnitsLayout extends StatelessWidget {
  final String moduleTitle;
  final String unitTitle; // We will ignore this, as requested
  final String lessonTitle;
  final List<DocumentSnapshot> lessons;
  final int selectedIndex;
  final ValueChanged<int> onLessonTap; // Callback function
  final Map<String, dynamic> lessonProgressMap; // 👈 --- ADDED: Progress data
  final String moduleId; // pass-through for progress updates
  final String roomId;
  final String userId; // pass-through for progress context

  const ViewUnitsLayout({
    Key? key,
    required this.moduleTitle,
    required this.unitTitle,
    required this.lessonTitle,
    required this.lessons,
    required this.selectedIndex,
    required this.onLessonTap,
    required this.lessonProgressMap, // 👈 --- ADDED: Progress data
    required this.moduleId,
    required this.roomId,
    required this.userId,
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
      case 'code': // Example for a new category
        return Icons.code_outlined;
      case 'game': // Example for another new category
        return Icons.gamepad_outlined; // Controller icon
      case 'bulb': // Example for another new category
        return Icons.lightbulb_outline; // Bulb icon
      default:
        return null; // Return null if no specific icon, so the hive is empty
    }
  }

  // 👈 --- MODIFIED: This is your navigation function
  void _navigateToLesson(BuildContext context, DocumentSnapshot lesson) {
    final lessonData = lesson.data() as Map<String, dynamic>? ?? {};
    final String category = lessonData['category'] ?? 'unknown';
    // 1. 🌟 Get the title directly from the tapped lesson
    final String newLessonTitle = lessonData['title'] ?? 'Lesson';

    switch (category) {
      case 'reading':
        final List<String> contentIDs =
            List<String>.from(lessonData['contentBlockIds'] ?? []);


        if (contentIDs.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PagedReadingScreen(
                // 2. 🌟 Use the new title here
                lessonTitle: newLessonTitle,
                contentIDs: contentIDs,
                moduleId: moduleId,
                roomId: roomId,
                lessonId: lesson.id,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: No content IDs found.')),
          );
        }
        break;
      case 'video':
      // 1. Get the array of IDs from Firestore
      final List<String> contentIDs = 
          List<String>.from(lessonData['contentBlockIds'] ?? []);

      if (contentIDs.isNotEmpty) {
        // 2. Navigate to your NEW video screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoLessonScreen( // 👈 Your new screen
              contentIDs: contentIDs,
              moduleId: moduleId,
              roomId: roomId,
              lessonId: lesson.id,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: No videos found for this lesson.')),
        );
      }
      break;
      
      // 🌟 --- ADD THIS NEW CASE --- 🌟
    case 'quiz':
      // 1. Get the array of IDs from Firestore
      final List<String> contentIDs = 
          List<String>.from(lessonData['contentBlockIds'] ?? []);

      if (contentIDs.isNotEmpty) {
        // 2. Navigate to your NEW quiz screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuizLessonScreen(
              contentIDs: contentIDs, // 👈 Pass the list of IDs
              lessonTitle: lessonData['title'] ?? 'Quiz',
              moduleId: moduleId,
              roomId: roomId,
              lessonId: lesson.id,
              userId: userId, // NEW: pass userId down from ViewUnitsLayout
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: No questions found for this quiz.')),
        );
      }
      break;

      case 'code':
      final List<String> contentIDs = 
          List<String>.from(lessonData['contentBlockIds'] ?? []);

      if (contentIDs.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CodeScreen(
              // 🌟 FIX: Change 'contentIDs' to 'contentID' (singular)
              contentID: contentIDs.first,
              moduleId: moduleId,
              roomId: roomId,
              lessonId: lesson.id,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: No practice problem found.')),
        );
      }
      break;

      case 'bulb': // The category from your Firestore screenshot
      
      // 1. Get the array of IDs (it's just one ID for this game)
      final List<String> contentIDs = 
          List<String>.from(lessonData['contentBlockIds'] ?? []);

      if (contentIDs.isNotEmpty) {
        // 2. Navigate to your NEW game screen
        Navigator.push(
          context,
          MaterialPageRoute(
           builder: (context) => DragDropGameScreen(
              contentIDs: contentIDs, // Pass the whole list!
              moduleId: moduleId,
              roomId: roomId,
              lessonId: lesson.id,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: No activity found.')),
        );
      }
      break;
    // 🌟 --- END OF NEW CASE --- 🌟
    }
  }

  // 👈 --- NEW: HELPER TO CHECK LOCK STATUS ---
  /// Checks if a lesson at a given [index] is locked.
  bool _isLessonLocked(int index) {
    if (index == 0) {
      return false; // Lesson 1 (index 0) is never locked
    }
    // Get the ID of the PREVIOUS lesson
    final prevLessonId = lessons[index - 1].id; // e.g., M01-L01
    // Check if the progress map says it's 'true'
    final bool isPrevComplete = lessonProgressMap[prevLessonId] == true;

    return !isPrevComplete; // It's locked if the previous is NOT complete
  }

  // 👈 --- NEW: HELPER TO SHOW ERROR MESSAGE ---
  void _showLockedMessage(BuildContext context, int index) {
    final prevLessonTitle =
        lessons[index - 1].get('title') ?? 'the previous lesson';
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
      //backgroundColor: const Color(0xFFF0F0F0),
      body: Container(
        decoration: BoxDecoration(
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
        child: Column(
          children: [
            // --- TOP HIVE DISPLAY ---
            _buildHiveDisplay(
              context,
              moduleTitle, // Pass "Module 1"
              lessonTitle, // Pass "Lesson 1"
              lessons,
              selectedIndex,
            ),

            // --- BOTTOM LESSON LIST ---
            _buildLessonList(context, lessons),
          ],
        ),
      ),
    );
  }

  // Helper widget for the top hive display
  Widget _buildHiveDisplay(
    BuildContext context,
    String moduleTitle, // Was unitTitle
    String lessonTitle,
    List<DocumentSnapshot> lessons,
    int selectedIndex,
  ) {
    const double hiveSize = 100.0;
    final double verticalSpacingFactor = 0.64;
    final double ySeparation = hiveSize * 0.72 * verticalSpacingFactor;
    final double xSeparation = hiveSize * 0.80;

    // These offsets are relative to the center of the Stack
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
      height: stackHeight + 100, // Add 100px for text and padding
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Text(
            moduleTitle, // Was unitTitle.toUpperCase()
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            lessonTitle.toUpperCase(), // This is correct
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 15),
          // Sized Box for the Stack of Hives
          SizedBox(
            width: xSeparation * 2.5,
            height: stackHeight, // Was ySeparation * 4.2
            child: Stack(
              alignment: Alignment.center, // Was Alignment.topCenter
              children: List.generate(
                lessons.length > 7 ? 7 : lessons.length,
                (index) {
                  final lesson = lessons[index];
                  final lessonData =
                      lesson.data() as Map<String, dynamic>? ?? {};
                  final bool isSelected = index == selectedIndex;
                  final IconData? iconForThisHive =
                      _getIconForCategory(lessonData['category']);

                  // 👈 --- CHECK IF THIS HIVE IS LOCKED ---
                  final bool isLocked = _isLessonLocked(index);

                  return Transform.translate(
                    offset: hivePositions[index],
                    child: GestureDetector(
                      // --- 👈 THIS IS THE MODIFIED TAP LOGIC ⬇️ ---
                      onTap: () {
                        if (isLocked) {
                          // Show error message
                          _showLockedMessage(context, index);
                        } else {
                          // It's unlocked, so update selection AND navigate
                          onLessonTap(index);
                          _navigateToLesson(context, lesson);
                        }
                      },
                      // --- ⬆️ END OF MODIFICATION ⬆️ ---
                      child: HexagonWidget(
                        isSelected: isSelected,
                        isLocked: isLocked, // 👈 --- PASS LOCK STATE
                        size: hiveSize,
                        // 👈 --- SHOW LOCK ICON IF LOCKED
                        child: Icon(
                          isLocked ? Icons.lock_outline : iconForThisHive,
                          color: isLocked
                              ? Colors.grey[400]
                              : isSelected
                                  ? Colors.white
                                  : Colors.white70,
                          size: hiveSize * 0.5,
                        ),
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

                    // 👈 --- CHECK IF THIS TILE IS LOCKED ---
                    final bool isLocked = _isLessonLocked(index);

                    return LessonListTile(
                      title: lessonTitle,
                      icon: icon,
                      isSelected: isSelected,
                      isLocked: isLocked, // 👈 --- PASS LOCK STATE
                      onTap: () {
                        // --- 👈 THIS IS THE MODIFIED TAP LOGIC ⬇️ ---
                        if (isLocked) {
                          // Show error message
                          _showLockedMessage(context, index);
                        } else {
                          // It's unlocked, so update selection AND navigate
                          onLessonTap(index);
                          _navigateToLesson(context, lesson);
                        }
                        // --- ⬆️ END OF MODIFICATION ⬆️ ---
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

// --- 3. REUSABLE WIDGETS ---
class LessonListTile extends StatelessWidget {
  final String title;
  final IconData? icon;
  final bool isSelected;
  final bool isLocked; // 👈 --- ADDED
  final VoidCallback onTap;

  const LessonListTile({
    Key? key,
    required this.title,
    required this.icon,
    required this.isSelected,
    this.isLocked = false, // 👈 --- ADDED
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // --- 👈 MODIFIED: Update colors based on lock
    final Color cardColor = isLocked
        ? const Color(0xFFE0E0E0) // Locked card color
        : isSelected
            ? Colors.blue
            : const Color(0xFFF0F0F0);

    final Color textColor = isLocked
        ? Colors.grey[600]! // Locked text color
        : isSelected
            ? Colors.white
            : Colors.black;

    final Color iconColor = isLocked ? Colors.grey[600]! : Colors.white;
    // --- END MODIFICATION ---

    return Card(
      color: cardColor,
      elevation: isSelected ? 2 : 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        leading: HexagonWidget(
          // --- 👈 MODIFIED: Pass lock state to hive
          icon: isLocked ? Icons.lock_outline : icon,
          isSelected: isSelected,
          isLocked: isLocked, // Pass lock state
          // --- END MODIFICATION ---
          size: 50,
          selectedColor: Colors.white,
          unselectedColor: const Color(0xFFFBBC04),
          iconSelectedColor: Colors.blue,
          iconUnselectedColor: iconColor,
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

// --- REPLACE YOUR OLD HEXAGONWIDGET WITH THIS ---
class HexagonWidget extends StatelessWidget {
  final IconData? icon;
  final Widget? child; // Can be an Icon or Text
  final bool isSelected;
  final bool isLocked; // 👈 --- ADDED
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
    this.isLocked = false, // 👈 --- ADDED
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
    // --- 👈 MODIFIED: Update colors based on lock
    final Color bgColor = isLocked
        ? Colors.grey[700]! // Locked color
        : isSelected
            ? (selectedColor ?? const Color(0xFFFBBC04))
            : (unselectedColor ?? Colors.brown[700]!.withOpacity(0.6));

    final Color effectiveIconColor = isLocked
        ? Colors.grey[400]! // Locked icon color
        : isSelected
            ? (iconSelectedColor ?? Colors.white)
            : (iconUnselectedColor ?? Colors.white70);
    // --- END MODIFICATION ---

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
          // --- 👈 MODIFIED: Child logic shows lock icon
          child: child ?? // Use explicit child first
              (icon == null
                  ? const SizedBox.shrink()
                  : Icon(
                      icon, // This will be lock icon if locked
                      color: effectiveIconColor,
                      size: size * 0.5,
                    )),
          // --- END MODIFICATION ---
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