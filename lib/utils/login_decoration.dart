import 'package:flutter/material.dart';

InputDecoration loginDecoration({
  required String hintText,
  required IconData icon,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: const TextStyle(color: Color(0xFF6C7890)),
    prefixIcon: Icon(icon, color: const Color(0xFF123F78)),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: const Color(0xFFFFFBEE),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE7D28A)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE7D28A)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFD8AD20), width: 1.8),
    ),
  );
}
