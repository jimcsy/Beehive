import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:beehive/utils/hexagonal.dart'; // Uses your HexClipper

// --- 1. DATA & STATE LOGIC ---

class ViewUnitsTab extends StatefulWidget {
  final String roomId;
  final String moduleId;

  const ViewUnitsTab({
    super.key,
    required this.roomId,
    required this.moduleId,
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

        // Fetch lessons. Assumes you have an 'orderIndex' (Number) field.
        // This is CRUCIAL for correct positioning.
        final lessonsRef = moduleRef.collection('lessons'); 

        return StreamBuilder<QuerySnapshot>(
          stream: lessonsRef.snapshots(),
          builder: (context, lessonSnapshot) {
            if (lessonSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (lessonSnapshot.hasError) {
              return Center(child: Text('Error: ${lessonSnapshot.error}'));
            }
            if (lessonSnapshot.data!.docs.isEmpty) {
              return const Center(
                  child: Text('No lessons found for this module.'));
            }

            final lessons = lessonSnapshot.data!.docs;

            // Ensure selectedIndex is within bounds after data load
            if (_selectedIndex >= lessons.length) {
              _selectedIndex = 0;
            }
            
            final selectedLesson = lessons[_selectedIndex];
            final selectedLessonData =
                selectedLesson.data() as Map<String, dynamic>? ?? {};
            
            // The "Unit 1" title
            final unitTitle = "Unit ${selectedLessonData['orderIndex'] ?? _selectedIndex + 1}";
            // The "Introduction to Python" title
            final lessonTitle = selectedLessonData['title'] ?? 'Lesson';

            // Pass all the extracted data to the layout widget
            return ViewUnitsLayout(
              moduleTitle: moduleTitle,
              unitTitle: unitTitle,
              lessonTitle: lessonTitle,
              lessons: lessons,
              selectedIndex: _selectedIndex,
              onLessonTap: (index) {
                // This callback updates the state
                setState(() {
                  _selectedIndex = index;
                });
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

  // Central navigation function
  // Central navigation function
  void _navigateToLesson(BuildContext context, DocumentSnapshot lesson) {
    final lessonData = lesson.data() as Map<String, dynamic>? ?? {};
    final lessonTitle = lessonData['title'] ?? 'Lesson';

    showDialog(
      context: context,
      // 1. Give the builder's context a name (like 'dialogContext')
      builder: (dialogContext) => AlertDialog(
        title: Text(lessonTitle),
        content: Text(
            "Showing lesson content for: ${lessonData['description'] ?? '...'}"),
        actions: [
          TextButton(
            // 2. Use the new 'dialogContext' to pop the dialog
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
      //backgroundColor: const Color(0xFFF0F0F0),
      body: Container(
        decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Color.fromARGB(255, 255, 241, 198), Color.fromARGB(106, 251, 189, 4), Color.fromARGB(255, 255, 241, 198), Colors.white, Colors.white,],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
        child: Column(
          children: [
            // --- TOP HIVE DISPLAY ---
            _buildHiveDisplay(
              context,
              // --- PARAMETERS CHANGED ---
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
    // --- SIGNATURE CHANGED ---
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
    
    // --- FIX FOR OVERLAP: Calculate the true height needed ---
    // Total vertical offset range + one hive's height
    final double stackHeight = (ySeparation * 4) + hiveSize;

    return Container(
      // Height of the whole area (Text + Stack)
      height: stackHeight + 100, // Add 100px for text and padding
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Text(
            // --- VARIABLE CHANGED ---
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
            // --- FIX FOR OVERLAP: Use calculated height ---
            height: stackHeight, // Was ySeparation * 4.2
            child: Stack(
              // --- FIX FOR OVERLAP: Use Alignment.center ---
              alignment: Alignment.center, // Was Alignment.topCenter
              children: List.generate(
                lessons.length > 7 ? 7 : lessons.length,
                (index) {
                  final lesson = lessons[index];
                  final lessonData = lesson.data() as Map<String, dynamic>? ?? {};
                  final bool isSelected = index == selectedIndex;
                  final IconData? iconForThisHive = _getIconForCategory(lessonData['category']);
                  
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

// --- 3. REUSABLE WIDGETS ---
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