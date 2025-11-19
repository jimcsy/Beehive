import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:beehive/features/students/modules/progress_service.dart';

// -----------------------------------------------------------------------------
// 1. THE PARENT SCREEN (Handles Navigation & Data Fetching)
// -----------------------------------------------------------------------------
class DragDropGameScreen extends StatefulWidget {
  // 🌟 CHANGE: Accept a LIST of IDs
  final List<String> contentIDs;
  final String moduleId;
  final String lessonId;

  const DragDropGameScreen({Key? key, required this.contentIDs, required this.moduleId, required this.lessonId}) : super(key: key);

  @override
  _DragDropGameScreenState createState() => _DragDropGameScreenState();
}

class _DragDropGameScreenState extends State<DragDropGameScreen> {
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;
  
  late final Future<List<Map<String, dynamic>>> _fetchActivities;
  
  // Track if the CURRENT page is solved to enable the Next button
  bool _isCurrentPageSolved = false; 

  @override
  void initState() {
    super.initState();
    _fetchActivities = _loadActivitiesFromSupabase();
  }

  Future<List<Map<String, dynamic>>> _loadActivitiesFromSupabase() async {
    final supabase = Supabase.instance.client;
    if (widget.contentIDs.isEmpty) return [];

    try {
      // 1. Fetch all activities in the list
      final List<Map<String, dynamic>> fetchedData = await supabase
          .from('Activity')
          .select()
          .inFilter('lessonContentId', widget.contentIDs);

      // 2. Sort them to match Firestore order
      final Map<String, Map<String, dynamic>> dataMap = {
        for (var item in fetchedData) item['lessonContentId']: item
      };
      final List<Map<String, dynamic>> sortedData = [];
      for (String id in widget.contentIDs) {
        if (dataMap.containsKey(id)) {
          sortedData.add(dataMap[id]!);
        }
      }
      return sortedData;
    } catch (e) {
      print('Error fetching activities: $e');
      throw Exception('Failed to load content: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Activity", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchActivities,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Error loading activities.'));
          }

          final pages = snapshot.data!;

          return Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  // 🔒 Disable swipe so they MUST solve it to click Next
                  physics: NeverScrollableScrollPhysics(), 
                  itemCount: pages.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPageIndex = index;
                      _isCurrentPageSolved = false; // Reset for new page
                    });
                  },
                  itemBuilder: (context, index) {
                    // 🌟 Render the specific game for this page
                    return SingleDragDropGame(
                      data: pages[index],
                      onSolved: () {
                        // ✅ Enable button when child says it's solved
                        setState(() {
                          _isCurrentPageSolved = true;
                        });
                      },
                    );
                  },
                ),
              ),
              
              // 🌟 YOUR NAVIGATION CONTROLS 🌟
              _buildNavigationControls(pages.length),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNavigationControls(int totalPages) {
    final bool isLastPage = _currentPageIndex == (totalPages - 1);

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // --- PREV ---
          ElevatedButton.icon(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            label: Text('Prev', style: TextStyle(color: Colors.black)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white, 
              elevation: 0,
              side: BorderSide(color: Colors.grey[300]!)
            ),
            onPressed: _currentPageIndex == 0 ? null : () {
              _pageController.previousPage(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            },
          ),
          
          Text(
            'Activity ${_currentPageIndex + 1} of $totalPages',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[600]),
          ),
          
          // --- NEXT / DONE ---
          ElevatedButton.icon(
            icon: Icon(Icons.arrow_forward),
            label: Text(isLastPage ? 'Done' : 'Next'),
            style: ElevatedButton.styleFrom(
              // Gold if solved, Grey if not
              backgroundColor: _isCurrentPageSolved 
                  ? Color(0xFFE8A319) 
                  : Colors.grey[300],
              disabledBackgroundColor: Colors.grey[300],
              foregroundColor: Colors.white,
            ),
            // Disable button if not solved yet
            onPressed: !_isCurrentPageSolved 
              ? null 
              : () async {
                  if (isLastPage) {
                    // Save progress before leaving
                    try {
                      await ProgressService().markLessonAsCompleted(
                        moduleId: widget.moduleId,
                        lessonId: widget.lessonId,
                      );
                    } catch (e) {
                      print('Failed to mark lesson complete: $e');
                    }
                    Navigator.of(context).pop(); // Done
                  } else {
                    _pageController.nextPage(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                },
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 2. THE CHILD WIDGET (The Actual Game Logic)
// -----------------------------------------------------------------------------
class SingleDragDropGame extends StatefulWidget {
  final Map<String, dynamic> data;
  final VoidCallback onSolved; // Tell parent we finished

  const SingleDragDropGame({
    Key? key, 
    required this.data, 
    required this.onSolved
  }) : super(key: key);

  @override
  _SingleDragDropGameState createState() => _SingleDragDropGameState();
}

class _SingleDragDropGameState extends State<SingleDragDropGame> {
  late String _questionText;
  late String _sampleCode;
  late Map<String, dynamic> _choices;
  late String _correctAnswerKey;
  
  String? _droppedValue;
  bool? _isCorrect;

  @override
  void initState() {
    super.initState();
    // Load data from the passed Map
    _questionText = widget.data['questionText'] ?? "";
    _sampleCode = widget.data['sampleCode'] ?? "";
    _choices = widget.data['choices'] ?? {};
    _correctAnswerKey = widget.data['correctAnswer'] ?? "";
  }

  void _onItemDropped(String key, String value) {
    setState(() {
      _droppedValue = value;
      
      if (key == _correctAnswerKey) {
        _isCorrect = true;
        widget.onSolved(); // 🎉 Notify parent that we won!
      } else {
        _isCorrect = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Question
          Text(
            _questionText,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),

          // 2. Code Box (Drop Target)
          _buildCodeContainer(),

          SizedBox(height: 40),

          // 3. Feedback
          Center(
            child: Text(
              _isCorrect == true 
                  ? "Correct! Great job." 
                  : (_isCorrect == false ? "Try again!" : "Drag the correct option above"),
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold,
                color: _isCorrect == true ? Colors.green : (_isCorrect == false ? Colors.red : Colors.grey),
              ),
            ),
          ),

          SizedBox(height: 20),

          // 4. Choices
          _buildChoicesStack(),
        ],
      ),
    );
  }

  Widget _buildCodeContainer() {
    List<String> parts = _sampleCode.split('___');
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2b2b2b), 
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (parts.isNotEmpty)
            Text(parts[0], style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 16)),

          DragTarget<String>(
            onAccept: (key) => _onItemDropped(key, _choices[key]),
            builder: (context, candidate, rejected) {
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 4),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _isCorrect == true 
                      ? Colors.green.withOpacity(0.2) 
                      : (_isCorrect == false ? Colors.red.withOpacity(0.2) : Colors.grey[700]),
                  border: Border.all(
                    color: _isCorrect == true ? Colors.green : (_isCorrect == false ? Colors.red : Colors.grey)
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _droppedValue ?? " ? ", 
                  style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              );
            },
          ),

          if (parts.length > 1)
            Text(parts[1], style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildChoicesStack() {
    return Column(
      children: _choices.keys.map((key) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Draggable<String>(
            data: key, 
            feedback: Material(
              color: Colors.transparent,
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: _buildChoiceCard(_choices[key], isDragging: true),
              ),
            ),
            childWhenDragging: Opacity(opacity: 0.5, child: _buildChoiceCard(_choices[key])),
            child: _buildChoiceCard(_choices[key]),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChoiceCard(String text, {bool isDragging = false}) {
    return Container(
      width: double.infinity, 
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: isDragging ? Colors.blue.withOpacity(0.9) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          if (!isDragging) BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: Center(
        child: Text(
          text,
          style: GoogleFonts.jetBrainsMono(
            color: isDragging ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600, fontSize: 16
          ),
        ),
      ),
    );
  }
}