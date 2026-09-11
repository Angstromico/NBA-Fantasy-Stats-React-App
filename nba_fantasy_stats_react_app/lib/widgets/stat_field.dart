import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Digits-only numeric input for a single stat category (Step 7 of
/// FLUTTER_PLAN.md).
class StatField extends StatelessWidget {
  const StatField({super.key, required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
