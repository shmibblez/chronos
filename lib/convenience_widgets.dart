import 'package:flutter/material.dart';

class HelpButton extends StatelessWidget {
  const HelpButton({required this.msg, Key? key}) : super(key: key);

  final String msg;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        // show dialog explainig tap to play/pause
        showDialog(
            context: context, builder: (_) => AlertDialog(content: Text(msg)));
      },
      icon: const Icon(Icons.help),
    );
  }
}
