import 'package:flutter/material.dart';

class TextInputWidget extends StatelessWidget {
  final TextEditingController controller;
  
  const TextInputWidget({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        controller: controller,
        maxLines: 8,
        decoration: InputDecoration(
          hintText: 'Enter the text you want to convert to handwriting...',
          hintStyle: TextStyle(color: Colors.grey[500]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
        style: const TextStyle(
          fontSize: 16,
          height: 1.5,
        ),
      ),
    );
  }
}