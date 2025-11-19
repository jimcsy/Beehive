import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert'; // To decode the 'choices' JSON
import 'package:beehive/features/students/modules/progress_service.dart';

class QuizLessonScreen extends StatefulWidget {
  final List<String> contentIDs;
  final String lessonTitle;
  final String moduleId;
  final String lessonId;

  const QuizLessonScreen({
    Key? key,
    required this.contentIDs,
    required this.lessonTitle,
    required this.moduleId,
    required this.lessonId,
  }) : super(key: key);

  @override
  _QuizLessonScreenState createState() => _QuizLessonScreenState();
}

class _QuizLessonScreenState extends State<QuizLessonScreen> {
  late final Future<List<Map<String, dynamic>>> _fetchQuestions;
  
  // To track the user's selected answers
  // Map<QuestionID, SelectedAnswerKey>
  final Map<String, String> _userAnswers = {};
  
  // To track if the user has submitted the quiz
  bool _isSubmitted = false;

  @override
  void initState() {
    super.initState();
    _fetchQuestions = _loadQuestionsFromSupabase();
  }

  Future<List<Map<String, dynamic>>> _loadQuestionsFromSupabase() async {
    final supabase = Supabase.instance.client;
    if (widget.contentIDs.isEmpty) return [];

    try {
      // 1. Fetch from your 'QuizQuestion' table
      //    (Check your table name in Supabase, it looks like 'QuizQuestion' in the image)
      final List<Map<String, dynamic>> fetchedQuestions = await supabase
          .from('QuizQuestion') 
          .select()
          .inFilter('lessonContentId', widget.contentIDs);

      // 2. Re-sort based on Firestore order
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

  void _submitQuiz() async {
    setState(() {
      _isSubmitted = true;
    });
    // You can add logic here to calculate the score
    // and save it to Firestore if you want.
    try {
      await ProgressService().markLessonAsCompleted(
        moduleId: widget.moduleId,
        lessonId: widget.lessonId,
      );
    } catch (e) {
      print('Failed to mark quiz complete: $e');
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
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('This quiz has no questions.'));
          }

          final questions = snapshot.data!;

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(16.0),
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
                    onPressed: _submitQuiz,
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                    ),
                    child: Text("Submit Quiz"),
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
    
    // Parse choices (JSONB)
    // It looks like: {"A": "Answer A", "B": "Answer B"}
    final Map<String, dynamic> choices = questionData['choices'] ?? {};
    
    final String correctAnswer = questionData['correctAnswer'] ?? '';
    final String? selectedAnswer = _userAnswers[id];

    return Card(
      margin: EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question Text
            Text(
              "$number. $text",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            
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