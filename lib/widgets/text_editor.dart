import 'package:chronos/chronos_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TextEditor extends StatefulWidget {
  const TextEditor({
    super.key,
    required this.title,
    required this.onDismiss,
    required this.onSave,
    this.initialText = "",
    this.textValidator,
    this.numbersOnly = false,
  });

  final String title;
  final void Function() onDismiss;
  final void Function(String text) onSave;
  final String initialText;
  final bool numbersOnly;

  /// @returns null if ok, if not then error string
  final String? Function(String text)? textValidator;

  @override
  State<StatefulWidget> createState() => _TextEditorState();
}

class _TextEditorState extends State<TextEditor> {
  late String _text;
  late String? _errorText;
  late TextEditingController _controller;

  @override
  void initState() {
    _text = widget.initialText;
    if (widget.textValidator != null) {
      _errorText = widget.textValidator!.call(_text);
    } else {
      _errorText = null;
    }
    _controller = TextEditingController.fromValue(
      TextEditingValue(
        text: _text,
        selection:
            TextSelection.fromPosition(TextPosition(offset: _text.length)),
      ),
    );
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // cancel / save buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // cancel button
                TextButton(
                  onPressed: widget.onDismiss,
                  style: ButtonStyle(
                    textStyle: WidgetStatePropertyAll(
                        ChronosConstants.actionTextStyle),
                  ),
                  child: Text(
                    "cancel",
                    style: ChronosConstants.actionTextStyle,
                  ),
                ),
                // save button
                TextButton(
                  onPressed: () {
                    if (_errorText == null) {
                      widget.onSave(_text);
                    }
                  },
                  style: ButtonStyle(
                    textStyle: WidgetStatePropertyAll(
                        ChronosConstants.actionTextStyle),
                  ),
                  child: Text(
                    "save",
                    style: ChronosConstants.actionTextStyle,
                  ),
                ),
              ],
            ),

            // title
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(widget.title, style: ChronosConstants.titleTextStyle),
            ),

            // text editor
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _controller,
                maxLines: null,
                autofocus: true,
                keyboardType: widget.numbersOnly ? TextInputType.number : null,
                inputFormatters: widget.numbersOnly
                    ? <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly
                      ]
                    : null,
                decoration: InputDecoration(
                  errorText: _errorText,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    // update text
                    _text = value;
                    // check for errors
                    if (widget.textValidator != null) {
                      _errorText = widget.textValidator!.call(_text);
                    }
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
