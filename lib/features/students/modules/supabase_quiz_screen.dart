import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert'; 
import 'package:beehive/features/students/modules/progress_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  // 🌟 We use 'late' here, so we MUST assign it immediately in initState
  late final Future<List<Map<String, dynamic>>> _fetchQuestions;
  
  final Map<String, String> _userAnswers = {};
  bool _isSaving = false;
  
  // State for Logic
  bool _hasTakenQuiz = false;
  int _attemptsUsed = 0;
  int _previousScore = 0;
  final int _maxAttempts = 3;

  @override
  void initState() {
    super.initState();
    // 🌟 FIX: Initialize this IMMEDIATELY so the UI has something to load
    _fetchQuestions = _loadQuestionsFromSupabase();

    // Then check Firestore in the background (doesn't block UI)
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
            
            // If they used attempts, show the summary screen first
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

      // Sort based on ID order
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
      // Return empty list instead of crashing if error occurs
      return [];
    }
  }

  Future<void> _submitQuiz() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // We await the same future here to get the questions list for grading
      final questions = await _fetchQuestions;
      final int totalQuestions = questions.length;
      int correctCount = 0;

      // Calculate score
      for (final q in questions) {
        final String qId = q['lessonContentId'] ?? '';
        final String correct = (q['correctAnswer'] ?? '').toString();
        final String? userSelected = _userAnswers[qId];

        if (userSelected != null && userSelected == correct) {
          correctCount += 1;
        }
      }

      // 1. Save to Supabase (optional log)
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
      // Wrap in try-catch so Supabase failure doesn't stop Firestore progress
      try {
        await supabase.from('QuizSubmission').insert(submissionRow);
      } catch (e) {
        print("Supabase save error (non-fatal): $e");
      }

      // 2. Save to Firestore (Progress & Attempts)
      await ProgressService().saveQuizResult(
        roomId: widget.roomId,
        moduleId: widget.moduleId,
        lessonId: widget.lessonId,
        score: correctCount,
        totalQuestions: totalQuestions,
      );

      // 3. Update Local State
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
      appBar: AppBar(title: Text(widget.lessonTitle)),
      body: _hasTakenQuiz 
          ? _buildSummaryScreen()
          : FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchQuestions, // This is now guaranteed to be initialized
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
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: questions.length,
                        itemBuilder: (context, index) {
                          final question = questions[index];
                          return _buildQuestionCard(question, index + 1);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _submitQuiz,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: _isSaving 
                          ? const SizedBox(height:20, width:20, child: CircularProgressIndicator(color: Colors.white, strokeWidth:2)) 
                          : const Text("Submit Quiz"),
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
            const Text(
              "Quiz Completed!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      "Best Score",
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$_previousScore", // Can add /total if you want to calculate it
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    const Divider(height: 30),
                    Text(
                      "Attempts Used: $_attemptsUsed / $_maxAttempts",
                      style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            if (canRetake)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _retakeQuiz,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Retake Quiz"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA0701F),
                    foregroundColor: Colors.white,
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
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

  Widget _buildQuestionCard(Map<String, dynamic> questionData, int number) {
    final String id = questionData['lessonContentId'];
    final String text = questionData['questionText'] ?? 'No Question Text';

    // Safe Parsing for choices/options
    final rawOptions = questionData['choices'] ?? questionData['options'];
    final Map<String, dynamic> choices = (rawOptions is String)
        ? jsonDecode(rawOptions)
        : (rawOptions ?? {});

    final String? selectedAnswer = _userAnswers[id];

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$number. $text",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...choices.entries.map((entry) {
              final String key = entry.key;
              final String val = entry.value.toString();

              return RadioListTile<String>(
                title: Text("$key. $val"),
                value: key,
                groupValue: selectedAnswer,
                onChanged: (value) {
                  setState(() {
                    _userAnswers[id] = value!;
                  });
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}