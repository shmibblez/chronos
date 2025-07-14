import 'package:chronos/main.dart';
import 'package:chronos/widgets/number_picker.dart';
import 'package:flutter/material.dart';

class TimeSignatureSelector extends StatefulWidget {
  final int initialBeatsPerBar;
  final int initialBarNote;
  final void Function() onDismiss;
  final void Function(int bpb, int bn)? onTimeSignatureChanged;
  final void Function(int bpb, int bn)? onTimeSignatureSaved;

  const TimeSignatureSelector({
    super.key,
    required this.initialBeatsPerBar,
    required this.initialBarNote,
    required this.onDismiss,
    this.onTimeSignatureChanged,
    this.onTimeSignatureSaved,
  });

  @override
  State<StatefulWidget> createState() => _TimeSignatureSelectorState();
}

class _TimeSignatureSelectorState extends State<TimeSignatureSelector> {
  late int _bpb;
  late int _bn;

  @override
  void initState() {
    _bpb = widget.initialBeatsPerBar;
    _bn = widget.initialBarNote;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.maxFinite,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // cancel / save buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // cancel button
              TextButton(
                onPressed: widget.onDismiss,
                style: ButtonStyle(
                  textStyle:
                      WidgetStatePropertyAll(ChronosConstants.actionTextStyle),
                ),
                child: Text(
                  "cancel",
                  style: ChronosConstants.actionTextStyle,
                ),
              ),
              // save button
              TextButton(
                onPressed: () {
                  widget.onTimeSignatureSaved?.call(_bpb, _bn);
                },
                style: ButtonStyle(
                  textStyle:
                      WidgetStatePropertyAll(ChronosConstants.actionTextStyle),
                ),
                child: Text(
                  "save",
                  style: ChronosConstants.actionTextStyle,
                ),
              ),
            ],
          ),

          Container(height: 8),

          // selectors
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // beats per bar selector
              NumberPicker(
                label: "beats per bar",
                min: ChronosConstants.minBeatsPerBar,
                max: ChronosConstants.maxBeatsPerBar,
                initiallySelected: widget.initialBeatsPerBar,
                onSelectedItemChanged: (bpb) {
                  _bpb = bpb;
                  widget.onTimeSignatureChanged?.call(_bpb, _bn);
                },
              ),
              // bar note selector
              NumberPicker(
                label: "bar note",
                min: ChronosConstants.minBeatsPerBar,
                max: ChronosConstants.maxBeatsPerBar,
                initiallySelected: widget.initialBarNote,
                onSelectedItemChanged: (bn) {
                  _bn = bn;
                  widget.onTimeSignatureChanged?.call(_bpb, _bn);
                },
              ),
            ],
          ),

          // bottom spacing
          Container(height: 16),
        ],
      ),
    );
  }
}
