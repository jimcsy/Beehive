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
      final List<Map<String, dynamic>> fetchedData = await supabase
          .from('Activity')
          .select()
          .inFilter('lessonContentId', widget.contentIDs);

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

  // 🌟 NEW: Handles the flow: Popup -> Goal Screen -> Next Page
  void _handleContinueFlow(int totalPages, Map<String, dynamic> currentData) {
    setState(() => _isCurrentPageSolved = true);

    // 1. Define what happens when they finish reading the Goal Screen
    VoidCallback onGoalFinished = () async {
      final bool isLastPage = _currentPageIndex == (totalPages - 1);

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
        // Pop the Goal Screen, then Pop the Game Screen
        Navigator.of(context).pop(); 
        Navigator.of(context).pop(); 
      } else {
        // Pop the Goal Screen
        Navigator.of(context).pop(); 
        // Move to next page
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    };

    // 2. Navigate to the Activity Goal Screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivityGoalScreen(
          data: currentData,
          onContinue: onGoalFinished,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Activity", style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
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
                  physics: const NeverScrollableScrollPhysics(), 
                  itemCount: pages.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPageIndex = index;
                      _isCurrentPageSolved = false; 
                    });
                  },
                  itemBuilder: (context, index) {
                    final activityData = pages[index];
                    final String type = activityData['type'] ?? '';

                    if (type == 'STATEMENT_COMPLETION') {
                       return CompleteStatementGame(
                        data: activityData,
                        onAttempt: (isCorrect) {
                          _showFeedbackModal(context, isCorrect, pages.length, activityData);
                        },
                      );
                    } else {
                      return SingleDragDropGame(
                        data: activityData,
                        onAttempt: (isCorrect) {
                          _showFeedbackModal(context, isCorrect, pages.length, activityData);
                        },
                      );
                    }
                  },
                ),
              ),
              
              _buildNavigationControls(pages.length),
            ],
          );
        },
      ),
    );
  }

  // 🌟 UPDATED: Passes data to _handleContinueFlow
  void _showFeedbackModal(BuildContext context, bool isCorrect, int totalPages, Map<String, dynamic> currentData) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isCorrect ? const Color(0xFFFFF3CD) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isCorrect ? Icons.check_circle : Icons.cancel,
                    color: isCorrect ? Colors.green : Colors.red,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isCorrect ? "Correct!" : "Incorrect!",
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isCorrect ? const Color(0xFF5D4037) : Colors.black87,
                    ),
                  ),
                  if (isCorrect) ...[
                    const Spacer(),
                  ]
                ],
              ),
              const SizedBox(height: 30),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA0701F),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context); // Close modal
                    if (isCorrect) {
                      // 🌟 Go to Activity Goal Screen instead of Next Page directly
                      _handleContinueFlow(totalPages, currentData);
                    }
                  },
                  child: Text(
                    isCorrect ? "Continue" : "Try again",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavigationControls(int totalPages) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${_currentPageIndex + 1} / $totalPages',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 🌟 NEW SCREEN: ACTIVITY GOAL (Summary)
// -----------------------------------------------------------------------------
class ActivityGoalScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onContinue;

  const ActivityGoalScreen({Key? key, required this.data, required this.onContinue}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Prepare the data to display
    final String question = data['questionText'] ?? "Activity Goal";
    final String rawCode = data['sampleCode'] ?? "";
    final Map<String, dynamic> choices = data['choices'] ?? {};
    final String correctKey = data['correctAnswer'] ?? "";
    final String correctValue = choices[correctKey] ?? "answer";

    // Replace the blank (___) with the correct answer for the final display
    final String filledCode = rawCode.isNotEmpty 
        ? rawCode.replaceAll('___', correctValue) 
        : correctValue; 
    
    // Split code lines for display
    final List<String> codeLines = filledCode.split('\n');
    // If it's just one line, maybe wrap it for better visuals if needed, 
    // but usually these snippets are short.

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black, size: 30),
            onPressed: onContinue, // Acts as a close/continue
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Text(
              "Activity Goal",
              style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 16),
            Text(
              // using question text as the description or a fallback
              question, 
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF4A4A4A), height: 1.5),
            ),
            const SizedBox(height: 32),

            // 🌟 The Code Card
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    color: const Color(0xFFA0701F), // Gold/Brown
                    child: Text(
                      "python",
                      style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                  // Body
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    color: const Color(0xFF2B2B2B), // Dark
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Line Numbers
                        Column(
                          children: List.generate(
                            codeLines.isEmpty ? 1 : codeLines.length, 
                            (i) => Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Text("${i + 1}", style: GoogleFonts.jetBrainsMono(color: const Color(0xFFA0701F), fontSize: 14)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Code Text
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: codeLines.map((line) {
                              // Simple syntax highlighting logic (Green strings)
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: RichText(
                                  text: _buildHighlightedCode(line),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Continue Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA0701F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: onContinue,
                child: Text(
                  "Continue",
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Simple helper to color strings (parts inside quotes) green
  TextSpan _buildHighlightedCode(String line) {
    List<TextSpan> spans = [];
    RegExp exp = RegExp(r'(".*?"|\{.*?\}|\b\w+\b|[^\w\s])');
    Iterable<Match> matches = exp.allMatches(line);

    int lastMatchEnd = 0;
    
    for (Match match in matches) {
      // Add spaces before match if needed (though regex captures most things)
      if (match.start > lastMatchEnd) {
         spans.add(TextSpan(text: line.substring(lastMatchEnd, match.start), style: GoogleFonts.jetBrainsMono(color: Colors.white)));
      }

      String word = match.group(0)!;
      Color color = Colors.white;
      
      if (word.startsWith('"') || word.startsWith("'")) {
        color = Colors.greenAccent;
      } else if (word == "print" || word == "input") {
        color = Colors.amber;
      } else if (word.startsWith("{")) {
        color = Colors.green; // f-string variables
      }

      spans.add(TextSpan(text: word, style: GoogleFonts.jetBrainsMono(color: color, fontSize: 16)));
      lastMatchEnd = match.end;
    }
    
    return TextSpan(children: spans);
  }
}


// -----------------------------------------------------------------------------
// 2. STATEMENT COMPLETION GAME (Unchanged)
// -----------------------------------------------------------------------------
class CompleteStatementGame extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(bool) onAttempt; 

  const CompleteStatementGame({Key? key, required this.data, required this.onAttempt}) : super(key: key);

  @override
  _CompleteStatementGameState createState() => _CompleteStatementGameState();
}

class _CompleteStatementGameState extends State<CompleteStatementGame> {
  late String _questionText;
  late Map<String, dynamic> _choices;
  late String _correctAnswerKey;
  String? _selectedAnswer;

  @override
  void initState() {
    super.initState();
    _questionText = widget.data['questionText'] ?? "Complete the statement.";
    _choices = widget.data['choices'] ?? {};
    _correctAnswerKey = widget.data['correctAnswer'] ?? "";
  }

  void _handleOptionTap(String key, String value) {
    setState(() {
      _selectedAnswer = value;
    });
    bool isCorrect = (key == _correctAnswerKey);
    widget.onAttempt(isCorrect);
    
    if (!isCorrect) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _selectedAnswer = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> parts = _questionText.split('___');
    String startText = parts.isNotEmpty ? parts[0] : _questionText;
    String endText = parts.length > 1 ? parts[1] : "";
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text("Variables and Data Types", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text("Activity Goal", style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            "Complete the sentence below correctly.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[700]),
          ),
          const SizedBox(height: 24),

          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: const Color(0xFFA0701F), 
                  child: Text("python", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  color: const Color(0xFF2B2B2B), 
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(startText, style: GoogleFonts.jetBrainsMono(fontSize: 14, color: Colors.white)),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: Text(
                          _selectedAnswer ?? " ? ",
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 14, 
                            fontWeight: FontWeight.bold, 
                            color: Colors.amber
                          ),
                        ),
                      ),
                      Text(endText, style: GoogleFonts.jetBrainsMono(fontSize: 14, color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 40),

          ..._choices.keys.map((key) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: InkWell(
                onTap: () => _handleOptionTap(key, _choices[key]),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E), 
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 4))],
                  ),
                  child: Center(
                    child: Text(
                      _choices[key],
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 3. DRAG AND DROP GAME (Unchanged)
// -----------------------------------------------------------------------------
class SingleDragDropGame extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(bool) onAttempt; 

  const SingleDragDropGame({Key? key, required this.data, required this.onAttempt}) : super(key: key);

  @override
  _SingleDragDropGameState createState() => _SingleDragDropGameState();
}

class _SingleDragDropGameState extends State<SingleDragDropGame> {
  late String _questionText;
  late String _sampleCode;
  late Map<String, dynamic> _choices;
  late String _correctAnswerKey;
  String? _droppedValue;

  @override
  void initState() {
    super.initState();
    _questionText = widget.data['questionText'] ?? "";
    _sampleCode = widget.data['sampleCode'] ?? ""; 
    _choices = widget.data['choices'] ?? {};
    _correctAnswerKey = widget.data['correctAnswer'] ?? "";
  }

  void _onItemDropped(String key, String value) {
    setState(() {
      _droppedValue = value;
    });
    
    bool isCorrect = (key == _correctAnswerKey);
    widget.onAttempt(isCorrect);

    if (!isCorrect) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _droppedValue = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text("Variables and Data Types", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w500)),
          const SizedBox(height: 5),
          Icon(Icons.more_horiz, color: Colors.grey[600]), 
          const SizedBox(height: 5),
          Text("Activity Goal", style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text(
            _questionText, 
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 15, color: Colors.grey[700], height: 1.4),
          ),
          const SizedBox(height: 24),
          _buildStyledCodeBlock(),
          const SizedBox(height: 40),
          _buildChoicesStack(),
        ],
      ),
    );
  }

  Widget _buildStyledCodeBlock() {
    List<String> parts = _sampleCode.isNotEmpty ? _sampleCode.split('___') : [];
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFFA0701F), 
            alignment: Alignment.centerLeft,
            child: Text("python", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: const Color(0xFF2B2B2B), 
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Text("1", style: GoogleFonts.jetBrainsMono(color: const Color(0xFFA0701F))),
                    Text("2", style: GoogleFonts.jetBrainsMono(color: const Color(0xFFA0701F))),
                    Text("3", style: GoogleFonts.jetBrainsMono(color: const Color(0xFFA0701F))),
                    Text("4", style: GoogleFonts.jetBrainsMono(color: const Color(0xFFA0701F))),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (parts.isNotEmpty)
                        Text(parts[0], style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 14)),

                      DragTarget<String>(
                        onAccept: (key) => _onItemDropped(key, _choices[key]),
                        builder: (context, candidate, rejected) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              border: Border(bottom: BorderSide(color: _droppedValue != null ? Colors.green : Colors.white, width: 1)),
                            ),
                            child: Text(
                              _droppedValue ?? "____", 
                              style: GoogleFonts.jetBrainsMono(
                                color: _droppedValue != null ? Colors.green : Colors.white54, 
                                fontSize: 14, 
                                fontWeight: FontWeight.bold
                              ),
                            ),
                          );
                        },
                      ),

                      if (parts.length > 1)
                        Text(parts[1], style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
              child: _buildDarkButton(_choices[key], isDragging: true),
            ),
            childWhenDragging: Opacity(opacity: 0.5, child: _buildDarkButton(_choices[key])),
            child: _buildDarkButton(_choices[key]),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDarkButton(String text, {bool isDragging = false}) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.8, 
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), 
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
           BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 4))
        ],
      ),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w500, 
            fontSize: 14
          ),
        ),
      ),
    );
  }
}