import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert'; 
import 'package:beehive/features/students/modules/progress_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart'; // Ensure this is in pubspec.yaml

class QuizLessonScreen extends StatefulWidget {
  final List<String> contentIDs;
  final String lessonTitle;
  final String moduleId;
  final String roomId;
  final String lessonId;
  final String userId;

  const QuizLessonScreen({
    Key? key,
    required this.contentIDs,
    required this.lessonTitle,
    required this.moduleId,
    required this.roomId,
    required this.lessonId,
    required this.userId,
  }) : super(key: key);

  @override
  _QuizLessonScreenState createState() => _QuizLessonScreenState();
}

class _QuizLessonScreenState extends State<QuizLessonScreen> {
  late final Future<List<Map<String, dynamic>>> _fetchQuestions;
  
  final Map<String, String> _userAnswers = {};
  bool _isSaving = false;
  
  bool _hasTakenQuiz = false;
  int _attemptsUsed = 0;
  int _previousScore = 0;
  final int _maxAttempts = 3;

  @override
  void initState() {
    super.initState();
    _fetchQuestions = _loadQuestionsFromSupabase();
    _checkPreviousProgress(); 
  }

  Future<void> _checkPreviousProgress() async {
    final uniqueProgressId = '${widget.roomId}_${widget.moduleId}';
    
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('progress')
          .doc(uniqueProgressId)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        final attemptsMap = data['quizAttempts'] as Map<String, dynamic>? ?? {};
        final scoresMap = data['quizScores'] as Map<String, dynamic>? ?? {};

        if (mounted) {
          setState(() {
            _attemptsUsed = attemptsMap[widget.lessonId] ?? 0;
            _previousScore = scoresMap[widget.lessonId] ?? 0;
            if (_attemptsUsed > 0) {
              _hasTakenQuiz = true;
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Error checking progress: $e");
    }
  }

  Future<List<Map<String, dynamic>>> _loadQuestionsFromSupabase() async {
    final supabase = Supabase.instance.client;
    if (widget.contentIDs.isEmpty) return [];

    try {
      final List<Map<String, dynamic>> fetchedQuestions = await supabase
          .from('QuizQuestion')
          .select()
          .inFilter('lessonContentId', widget.contentIDs);

      final Map<String, Map<String, dynamic>> questionMap = {
        for (var q in fetchedQuestions) q['lessonContentId']: q
      };
      final List<Map<String, dynamic>> sortedQuestions = [];
      for (String id in widget.contentIDs) {
        if (questionMap.containsKey(id)) {
          sortedQuestions.add(questionMap[id]!);
        }
      }
      return sortedQuestions;
    } catch (e) {
      print('Error fetching quiz: $e');
      return [];
    }
  }

  // 🌟 NEW: Shows the confirmation dialog before submitting
  void _showSubmitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Center(
          child: Text(
            "Are you sure?",
            style: GoogleFonts.inter(
              fontSize: 18, 
              fontWeight: FontWeight.bold,
              color: Colors.black
            ),
          ),
        ),
        contentPadding: const EdgeInsets.only(top: 20, bottom: 24, left: 24, right: 24),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          // NO Button (Gold/Yellow)
          SizedBox(
            width: 100,
            height: 45,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE0C068), // Light Gold
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text("No", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          const SizedBox(width: 16),
          // YES Button (Dark Brown/Gold)
          SizedBox(
            width: 100,
            height: 45,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA0701F), // Dark Gold
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pop(context); // Close dialog
                _submitQuiz(); // Proceed to submit
              },
              child: const Text("Yes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitQuiz() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final questions = await _fetchQuestions;
      final int totalQuestions = questions.length;
      int correctCount = 0;

      for (final q in questions) {
        final String qId = q['lessonContentId'] ?? '';
        final String correct = (q['correctAnswer'] ?? '').toString();
        final String? userSelected = _userAnswers[qId];

        if (userSelected != null && userSelected == correct) {
          correctCount += 1;
        }
      }

      final Map<String, dynamic> submissionRow = {
        'userId': widget.userId,
        'moduleId': widget.moduleId,
        'lessonContentId': widget.lessonId,
        'scoreTotal': correctCount,
        'totalQuestions': totalQuestions,
        'userAnswers': jsonEncode(_userAnswers),
        'submittedAt': DateTime.now().toUtc().toIso8601String(),
      };

      final supabase = Supabase.instance.client;
      try {
        await supabase.from('QuizSubmission').insert(submissionRow);
      } catch (e) {
        print("Supabase save error (non-fatal): $e");
      }

      await ProgressService().saveQuizResult(
        roomId: widget.roomId,
        moduleId: widget.moduleId,
        lessonId: widget.lessonId,
        score: correctCount,
        totalQuestions: totalQuestions,
      );

      if (mounted) {
        setState(() {
          _hasTakenQuiz = true;
          _attemptsUsed++;
          if (correctCount > _previousScore) _previousScore = correctCount;
        });
      }

    } catch (e) {
      print('Error submitting quiz: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save submission: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _retakeQuiz() {
    if (_attemptsUsed >= _maxAttempts) return;
    setState(() {
      _userAnswers.clear(); 
      _hasTakenQuiz = false; 
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Clean background like Image 2
      appBar: AppBar(
        title: Text(widget.lessonTitle, style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.black),
      ),
      body: _hasTakenQuiz 
          ? _buildSummaryScreen()
          : FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchQuestions,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('This quiz has no questions.'));
                }

                final questions = snapshot.data!;

                return Column(
                  children: [
                    // 🌟 Progress Bar (Visual flair like Image 2)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
                      child: LinearProgressIndicator(
                        value: _userAnswers.length / questions.length, // Dynamic progress
                        backgroundColor: Colors.grey[300],
                        color: const Color(0xFFA0701F), // Gold
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),

                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
                        itemCount: questions.length,
                        itemBuilder: (context, index) {
                          final question = questions[index];
                          return _buildStyledQuestionCard(question, index + 1);
                        },
                      ),
                    ),
                    
                    // 🌟 Submit Button
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          // 🌟 Calls the confirmation dialog now
                          onPressed: _isSaving ? null : _showSubmitConfirmation, 
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFA0701F), // Gold/Brown
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isSaving 
                            ? const SizedBox(height:24, width:24, child: CircularProgressIndicator(color: Colors.white, strokeWidth:2)) 
                            : Text(
                                "Submit Quiz", 
                                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)
                              ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildSummaryScreen() {
    final bool canRetake = _attemptsUsed < _maxAttempts;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assignment_turned_in, size: 80, color: Color(0xFFA0701F)),
            const SizedBox(height: 24),
            Text(
              "Quiz Completed!",
              style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              color: Colors.grey[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey[200]!),
              ),
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  children: [
                    Text(
                      "Best Score",
                      style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "$_previousScore",
                      style: GoogleFonts.inter(fontSize: 40, fontWeight: FontWeight.w800, color: const Color(0xFFA0701F)),
                    ),
                    const Divider(height: 40),
                    Text(
                      "Attempts Used: $_attemptsUsed / $_maxAttempts",
                      style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[800]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            if (canRetake)
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _retakeQuiz,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Retake Quiz"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA0701F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: const Text(
                  "Maximum attempts reached.",
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 🌟 STYLED QUESTION CARD (Matches Image 2)
  Widget _buildStyledQuestionCard(Map<String, dynamic> questionData, int number) {
    final String id = questionData['lessonContentId'];
    final String text = questionData['questionText'] ?? 'No Question Text';

    final rawOptions = questionData['choices'] ?? questionData['options'];
    final Map<String, dynamic> choices = (rawOptions is String)
        ? jsonDecode(rawOptions)
        : (rawOptions ?? {});

    final String? selectedAnswer = _userAnswers[id];

    return Container(
      margin: const EdgeInsets.only(bottom: 32.0), // Space between questions
      padding: const EdgeInsets.all(20), // Padding inside grey box
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9), // Very light grey background like Image 2
        borderRadius: BorderRadius.circular(12), 
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question Number
          Text(
            "Q$number.",
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black),
          ),
          const SizedBox(height: 12),
          
          // Question Text
          Text(
            text,
            style: GoogleFonts.inter(fontSize: 15, height: 1.5, color: Colors.black87),
          ),
          const SizedBox(height: 24),

          // Options List
          ...choices.entries.map((entry) {
            final String key = entry.key; // "a", "b"
            final String val = entry.value.toString(); // "web development..."
            final bool isSelected = selectedAnswer == key;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _userAnswers[id] = key;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    // Grey background for options, Darker grey if selected
                    color: isSelected ? const Color.fromARGB(255, 149, 149, 149) : const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(
                        "$key.)",
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          val,
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                        ),
                      ),
                    ],
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