import 'package:chronos/cubits/hephaestus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
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

class RangeTextInputFormatter extends TextInputFormatter {
  RangeTextInputFormatter({required this.rangeFunction});

  /// takes a number as a parameter
  /// - if within range -> return same input number
  /// - if below range -> return min
  /// - if above range -> return max
  final int Function(int) rangeFunction;
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: rangeFunction(int.parse(newValue.text)).toString(),
    );
  }
}
