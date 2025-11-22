import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:beehive/features/students/modules/progress_service.dart';

// -----------------------------------------------------------------------------
// 1. THE PARENT SCREEN (Handles Navigation & Data Fetching)
// -----------------------------------------------------------------------------
class DragDropGameScreen extends StatefulWidget {
  final List<String> contentIDs;
  final String moduleId;
  final String roomId;
  final String lessonId;

  const DragDropGameScreen({
    Key? key,
    required this.contentIDs,
    required this.moduleId,
    required this.roomId,
    required this.lessonId,
  }) : super(key: key);

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
        title: const Text("Activity", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchActivities,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Error loading activities.'));
          }

          final pages = snapshot.data!;

          return Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(), // Disable swipe
                  itemCount: pages.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPageIndex = index;
                      _isCurrentPageSolved = false; // Reset for new page
                    });
                  },
                  itemBuilder: (context, index) {
                    final activityData = pages[index];
                    
                    // 🔍 FIX: Check the 'type' column from your database
                    final String type = activityData['type'] ?? '';

                    if (type == 'STATEMENT_COMPLETION') {
                       // --- NEW UI FOR FILL IN THE BLANK ---
                       return CompleteStatementGame(
                        data: activityData,
                        onSolved: () {
                          setState(() => _isCurrentPageSolved = true);
                        },
                      );
                    } else {
                      // --- DEFAULT TO DRAG & DROP ---
                      return SingleDragDropGame(
                        data: activityData,
                        onSolved: () {
                          setState(() => _isCurrentPageSolved = true);
                        },
                      );
                    }
                  },
                ),
              ),
              
              // Navigation Controls (Prev/Next)
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
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // --- PREV ---
          ElevatedButton.icon(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            label: const Text('Prev', style: TextStyle(color: Colors.black)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white, 
              elevation: 0,
              side: BorderSide(color: Colors.grey[300]!)
            ),
            onPressed: _currentPageIndex == 0 ? null : () {
              _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
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
            icon: const Icon(Icons.arrow_forward),
            label: Text(isLastPage ? 'Done' : 'Next'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isCurrentPageSolved 
                  ? const Color(0xFFE8A319) 
                  : Colors.grey[300],
              disabledBackgroundColor: Colors.grey[300],
              foregroundColor: Colors.white,
            ),
            onPressed: !_isCurrentPageSolved 
              ? null 
              : () async {
                  if (isLastPage) {
                    try {
                      await ProgressService().markLessonAsCompleted(
                        roomId: widget.roomId,
                        moduleId: widget.moduleId,
                        lessonId: widget.lessonId,
                      );
                    } catch (e) {
                      print('Failed to mark lesson complete: $e');
                    }
                    Navigator.of(context).pop();
                  } else {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
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
// 2. NEW WIDGET: COMPLETE THE STATEMENT (Tap to Fill)
// -----------------------------------------------------------------------------
class CompleteStatementGame extends StatefulWidget {
  final Map<String, dynamic> data;
  final VoidCallback onSolved;

  const CompleteStatementGame({Key? key, required this.data, required this.onSolved}) : super(key: key);

  @override
  _CompleteStatementGameState createState() => _CompleteStatementGameState();
}

class _CompleteStatementGameState extends State<CompleteStatementGame> {
  late String _questionText;
  late Map<String, dynamic> _choices;
  late String _correctAnswerKey;
  
  String? _selectedAnswer;
  bool? _isCorrect;

  @override
  void initState() {
    super.initState();
    // 🔍 FIX: Use 'questionText' which contains the full sentence in your DB
    _questionText = widget.data['questionText'] ?? "Complete the statement.";
    _choices = widget.data['choices'] ?? {};
    _correctAnswerKey = widget.data['correctAnswer'] ?? "";
  }

  void _handleOptionTap(String key, String value) {
    if (_isCorrect == true) return; // Already solved

    setState(() {
      _selectedAnswer = value;
      if (key == _correctAnswerKey) {
        _isCorrect = true;
        widget.onSolved();
      } else {
        _isCorrect = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Split based on a delimiter if your DB has one (e.g. "Python can ___ connect").
    // If your DB text is just "Question: What can Python NOT do?", we might not find '___'.
    // So we handle both cases.
    
    List<String> parts = _questionText.split('___');
    String startText = parts.isNotEmpty ? parts[0] : _questionText;
    String endText = parts.length > 1 ? parts[1] : "";
    
    // If no "___" was found, maybe we just want to show the question above the box
    bool hasBlank = parts.length > 1;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Select the correct answer",
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey),
          ),
          const SizedBox(height: 20),

          // --- THE SENTENCE / QUESTION CONTAINER ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1), // Light yellow background
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8A319), width: 1.5),
            ),
            child: hasBlank 
            ? Wrap( // Case 1: Sentence with a blank
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    startText,
                    style: GoogleFonts.poppins(fontSize: 18, height: 1.5, color: Colors.black87),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _selectedAnswer == null 
                          ? Colors.white 
                          : (_isCorrect == true ? Colors.green : Colors.red),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: Text(
                      _selectedAnswer ?? "   ?   ",
                      style: GoogleFonts.poppins(
                        fontSize: 18, 
                        fontWeight: FontWeight.bold,
                        color: _selectedAnswer == null ? Colors.grey.shade300 : Colors.white
                      ),
                    ),
                  ),
                  Text(
                    endText,
                    style: GoogleFonts.poppins(fontSize: 18, height: 1.5, color: Colors.black87),
                  ),
                ],
              )
            : Column( // Case 2: Direct Question (No blank found)
                children: [
                   Text(
                    startText,
                    style: GoogleFonts.poppins(fontSize: 18, height: 1.5, color: Colors.black87, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _selectedAnswer == null 
                          ? Colors.white 
                          : (_isCorrect == true ? Colors.green : Colors.red),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                     child: Text(
                      _selectedAnswer ?? "Tap an answer below",
                      style: GoogleFonts.poppins(
                        fontSize: 16, 
                        fontWeight: FontWeight.bold,
                        color: _selectedAnswer == null ? Colors.grey.shade400 : Colors.white
                      ),
                    ),
                  )
                ],
              ),
          ),
          
          const SizedBox(height: 30),

          // --- FEEDBACK ---
          Center(
            child: Text(
              _isCorrect == true 
                  ? "Correct!" 
                  : (_isCorrect == false ? "Try again!" : "Tap the correct option below"),
              style: TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.bold,
                color: _isCorrect == true ? Colors.green : (_isCorrect == false ? Colors.red : Colors.grey),
              ),
            ),
          ),
          
          const SizedBox(height: 20),

          // --- OPTIONS GRID ---
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 1, // Full width list for longer text answers
            childAspectRatio: 4.5, // Adjusted for list look
            mainAxisSpacing: 12,
            children: _choices.keys.map((key) {
              return InkWell(
                onTap: () => _handleOptionTap(key, _choices[key]),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                    ],
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "${key.toUpperCase()}.  ${_choices[key]}",
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 3. EXISTING WIDGET: DRAG AND DROP (Kept exactly as is)
// -----------------------------------------------------------------------------
class SingleDragDropGame extends StatefulWidget {
  final Map<String, dynamic> data;
  final VoidCallback onSolved;

  const SingleDragDropGame({Key? key, required this.data, required this.onSolved}) : super(key: key);

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
    _questionText = widget.data['questionText'] ?? "";
    _sampleCode = widget.data['sampleCode'] ?? ""; // Fallback if null
    _choices = widget.data['choices'] ?? {};
    _correctAnswerKey = widget.data['correctAnswer'] ?? "";
  }

  void _onItemDropped(String key, String value) {
    setState(() {
      _droppedValue = value;
      if (key == _correctAnswerKey) {
        _isCorrect = true;
        widget.onSolved();
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
          Text(
            _questionText,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildCodeContainer(),
          const SizedBox(height: 40),
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
          const SizedBox(height: 20),
          _buildChoicesStack(),
        ],
      ),
    );
  }

  Widget _buildCodeContainer() {
    // If sampleCode is null or empty, default to just showing a drop box
    List<String> parts = _sampleCode.isNotEmpty ? _sampleCode.split('___') : [];
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2b2b2b), 
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
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: isDragging ? Colors.blue.withOpacity(0.9) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          if (!isDragging) BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
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