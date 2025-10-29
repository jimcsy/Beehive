import 'package:flutter/material.dart';

void showMessage(BuildContext context, String text) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.info_outline, color: Colors.black54),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    ),
  );

  // Auto-close after 2 seconds
  Future.delayed(const Duration(seconds: 2), () {
    if (Navigator.canPop(context)) Navigator.pop(context);
  });
}
