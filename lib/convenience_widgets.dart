import 'package:chronos/cubits/hephaestus.dart';
import 'package:chronos/cubits/hermes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
      icon: Icon(
        Icons.help,
        color: BlocProvider.of<Hephaestus>(context).state.color2,
      ),
    );
  }
}
