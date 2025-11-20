import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert'; // To encode the user answers JSON
import 'package:beehive/features/students/modules/progress_service.dart';

class QuizLessonScreen extends StatefulWidget {
  final List<String> contentIDs;
  final String lessonTitle;
  final String moduleId;
  final String lessonId;
  final String userId; // NEW: required to save submission

  const QuizLessonScreen({
    Key? key,
    required this.contentIDs,
    required this.lessonTitle,
    required this.moduleId,
    required this.lessonId,
    required this.userId, // NEW
  }) : super(key: key);

  @override
  _QuizLessonScreenState createState() => _QuizLessonScreenState();
}

class _QuizLessonScreenState extends State<QuizLessonScreen> {
  late final Future<List<Map<String, dynamic>>> _fetchQuestions;
  final Map<String, String> _userAnswers = {};
  bool _isSubmitted = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchQuestions = _loadQuestionsFromSupabase();
  }

  Future<List<Map<String, dynamic>>> _loadQuestionsFromSupabase() async {
    final supabase = Supabase.instance.client;
    if (widget.contentIDs.isEmpty) return [];

    try {
      final List<Map<String, dynamic>> fetchedQuestions = await supabase
          .from('QuizQuestion')
          .select()
          .inFilter('lessonContentId', widget.contentIDs);

      // Re-sort based on the provided contentIDs order
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
      throw Exception('Failed to load quiz: $e');
    }
  }

  Future<void> _submitQuiz() async {
    if (_isSubmitted) return;

    setState(() {
      _isSubmitted = true;
      _isSaving = true;
    });

    try {
      final questions = await _fetchQuestions;
      final int totalQuestions = questions.length;
      int correctCount = 0;

      // Calculate score: compare each question's correctAnswer with user's answer
      for (final q in questions) {
        final String qId = q['lessonContentId'] ?? '';
        final String correct = (q['correctAnswer'] ?? '').toString();
        final String? userSelected = _userAnswers[qId];

        if (userSelected != null && userSelected == correct) {
          correctCount += 1;
        }
      }

      final int scoreTotal = correctCount;

      // Prepare submission row
      final Map<String, dynamic> submissionRow = {
        // Use the correct column names matching your Supabase table
        'userId': widget.userId, // If your DB expects integer, cast/adapt here
        'moduleId': widget.moduleId,
        // the table field is 'lessonContentId' in your screenshot;
        // since this represents the quiz/lesson we put the lessonId here
        'lessonContentId': widget.lessonId,
        'scoreTotal': scoreTotal,
        'totalQuestions': totalQuestions,
        // Save the map of user's answers as JSONB
        'userAnswers': jsonEncode(_userAnswers),
        'submittedAt': DateTime.now().toUtc().toIso8601String(),
      };

      final supabase = Supabase.instance.client;

      // Insert the submission.
      // If you prefer to replace a previous submission by same user for same lesson,
      // consider using upsert() with an appropriate unique constraint.
      // Here we do a simple insert; change to upsert if needed.
      final insertResult = await supabase.from('QuizSubmission').insert(submissionRow);

      // Optional: If your table uses integer userId but you pass string,
      // Supabase may fail. Adjust types in DB or cast accordingly in code.

      // Mark lesson completed in Firestore progress
      try {
        await ProgressService().markLessonAsCompleted(
          moduleId: widget.moduleId,
          lessonId: widget.lessonId,
        );
      } catch (e) {
        // Non-fatal if marking progress fails
        print('Failed to mark quiz complete: $e');
      }

      // Show the result to the user
      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Quiz Submitted'),
            content: Text('You scored $scoreTotal / $totalQuestions'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('Error submitting quiz: $e');

      // If DB save failed, allow user to re-submit (set _isSubmitted back to false)
      if (mounted) {
        setState(() {
          _isSubmitted = false;
        });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.lessonTitle)),
      body: FutureBuilder<List<Map<String, dynamic>>>(
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

              // Submit Button
              if (!_isSubmitted)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _submitQuiz,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: _isSaving ? const SizedBox(height:20, width:20, child: CircularProgressIndicator(color: Colors.white, strokeWidth:2)) : const Text("Submit Quiz"),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> questionData, int number) {
    final String id = questionData['lessonContentId'];
    final String text = questionData['questionText'] ?? 'No Question Text';

    final Map<String, dynamic> choices = (questionData['choices'] is String)
        ? jsonDecode(questionData['choices'])
        : (questionData['choices'] ?? {});

    final String correctAnswer = questionData['correctAnswer'] ?? '';
    final String? selectedAnswer = _userAnswers[id];

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question Text
            Text(
              "$number. $text",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Choices
            ...choices.entries.map((entry) {
              final String key = entry.key; // "A", "B", etc.
              final String val = entry.value.toString(); // "Answer text"

              Color? tileColor;
              if (_isSubmitted) {
                if (key == correctAnswer) {
                  tileColor = Colors.green.withOpacity(0.2); // Correct!
                } else if (key == selectedAnswer && key != correctAnswer) {
                  tileColor = Colors.red.withOpacity(0.2); // Wrong!
                }
              }

              return Container(
                color: tileColor,
                child: RadioListTile<String>(
                  title: Text("$key. $val"),
                  value: key,
                  groupValue: selectedAnswer,
                  onChanged: _isSubmitted
                      ? null // Disable changing answers after submit
                      : (value) {
                          setState(() {
                            _userAnswers[id] = value!;
                          });
                        },
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
