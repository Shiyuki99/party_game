import 'package:flutter/material.dart';

class GameTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;

  const GameTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.onSubmitted,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(hintText: hintText),
      onSubmitted: onSubmitted != null ? (v) => onSubmitted!(v) : null,
      textInputAction: textInputAction,
    );
  }
}
