import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert'; // To decode the 'choices' JSON

class DragDropGameScreen extends StatefulWidget {
  final String contentID;

  const DragDropGameScreen({
    Key? key,
    required this.contentID,
  }) : super(key: key);

  @override
  _DragDropGameScreenState createState() => _DragDropGameScreenState();
}

class _DragDropGameScreenState extends State<DragDropGameScreen> {
  bool _isLoading = true;
  
  // These will hold the data from Supabase
  String _questionText = "";
  Map<String, dynamic> _choices = {};
  String _correctAnswerKey = "";
  
  // This is the state for the game
  String _droppedValue = ""; // The text in the box
  bool? _isCorrect; // null = empty, true = correct, false = wrong

  @override
  void initState() {
    super.initState();
    _loadProblem();
  }

  Future<void> _loadProblem() async {
    final supabase = Supabase.instance.client;
    try {
      final response = await supabase
          .from('Activity') // 👈 Your Supabase table name
          .select()
          .eq('lessonContentId', widget.contentID)
          .single();

      setState(() {
        _questionText = response['questionText'];
        _choices = response['choices']; // This is your JSONB
        _correctAnswerKey = response['correctAnswer'];
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading activity: $e");
      setState(() {
        _isLoading = false;
        _questionText = "Error loading problem.";
      });
    }
  }

  // This runs when you drop an item
  void _onItemDropped(String droppedKey) {
    setState(() {
      // 1. "Paste" the text into the box
      _droppedValue = _choices[droppedKey];
      
      // 2. Check if the answer is correct
      if (droppedKey == _correctAnswerKey) {
        _isCorrect = true;
      } else {
        _isCorrect = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Drag & Drop Activity")),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  SizedBox(height: 40),
                  
                  // 1. The Question and the Drop Target
                  _buildDropTarget(),
                  
                  SizedBox(height: 60),
                  
                  // 2. The Draggable Options
                  _buildDraggableOptions(),
                  
                  SizedBox(height: 20),
                  
                  // 3. Feedback
                  if (_isCorrect == true)
                    Text(
                      "Correct!",
                      style: TextStyle(color: Colors.green, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  if (_isCorrect == false)
                    Text(
                      "Try again!",
                      style: TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ),
    );
  }

  // This is the blank box that accepts the answer
  Widget _buildDropTarget() {
    Color borderColor = Colors.grey;
    if (_isCorrect == true) borderColor = Colors.green;
    if (_isCorrect == false) borderColor = Colors.red;

    return DragTarget<String>(
      // 1. This function runs when you drop a correct item
      onAccept: (data) {
        _onItemDropped(data);
      },
      
      // 2. This builds the UI of the box
      builder: (context, candidateData, rejectedData) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // "Variable name for storing 'Alice'"
            Text(
              _questionText,
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(width: 10),
            
            // The Box
            Container(
              width: 120,
              height: 50,
              decoration: BoxDecoration(
                border: Border.all(color: borderColor, width: 2),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
              ),
              child: Center(
                child: Text(
                  _droppedValue, // 👈 Shows the "pasted" text
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // This builds the draggable option cards
  Widget _buildDraggableOptions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: _choices.entries.map((entry) {
        final String key = entry.key; // "a", "b", "c"
        final String value = entry.value; // "name", "username", "person"

        return Draggable<String>(
          // 1. The data to send when dropped
          data: key, 
          
          // 2. How it looks when dragging
          feedback: Material(
            elevation: 4.0,
            child: _buildOptionCard(value, isDragging: true),
          ),
          
          // 3. How it looks in the row
          child: _buildOptionCard(value),
        );
      }).toList(),
    );
  }

  // A helper to style the draggable cards
  Widget _buildOptionCard(String text, {bool isDragging = false}) {
    return Container(
      width: 100,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDragging ? Colors.blue.withOpacity(0.5) : Colors.blue,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          if (!isDragging)
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: Offset(0, 2),
            )
        ],
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}