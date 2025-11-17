// lib/widgets/output_modal.dart
import 'package:flutter/material.dart';

void showOutputModal(BuildContext context, String output, bool isLoading) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent, // For rounded corners
    isScrollControlled: true, // Allows modal to be taller
    builder: (BuildContext ctx) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.4, // 40% of screen
        decoration: const BoxDecoration(
          color: Color(0xFF2b2b2b), // Dark background
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.0),
            topRight: Radius.circular(16.0),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Title
              const Text(
                "Output:",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(color: Colors.grey),
              const SizedBox(height: 8),

              // 2. Content (Loading or Result)
              Expanded(
                child: isLoading
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: Color(0xFFc79100)),
                            SizedBox(height: 16),
                            Text(
                              "Running code...",
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        child: Text(
                          output,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      );
    },
  );
}