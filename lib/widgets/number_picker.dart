import 'package:chronos/chronos_constants.dart';
import 'package:flutter/material.dart';

class NumberPicker extends StatefulWidget {
  const NumberPicker({
    super.key,
    this.label,
    required this.min,
    required this.max,
    required this.initiallySelected,
    required this.onSelectedItemChanged,
  });

  final String? label;
  final int min;
  final int max;
  final int initiallySelected;
  final void Function(int) onSelectedItemChanged;

  @override
  State<StatefulWidget> createState() {
    return _NumberPickerState();
  }
}

class _NumberPickerState extends State<NumberPicker> {
  late final ScrollController _controller;
  int _selectedIndex = -1;

  @override
  void initState() {
    _controller = FixedExtentScrollController(
      initialItem: widget.initiallySelected - widget.min,
    );
    _selectedIndex = widget.initiallySelected - widget.min;
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 8,
      children: [
        // label if set
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: ChronosConstants.primaryTextStyle,
          )
        ],
        // number selector
        SizedBox(
          width: 70,
          height: 250,
          child: ListWheelScrollView.useDelegate(
            itemExtent: 20,
            perspective: 0.002,
            diameterRatio: 1,
            onSelectedItemChanged: (value) {
              setState(() {
                _selectedIndex = value;
              });
              widget.onSelectedItemChanged(value + widget.min);
            },
            // ensures scroll always lands on item
            physics: FixedExtentScrollPhysics(),
            controller: _controller,
            childDelegate: ListWheelChildLoopingListDelegate(
              children: List.generate(
                widget.max - widget.min + 1,
                (i) => Text(
                  i + widget.min < 10
                      ? "0${i + widget.min}"
                      : "${i + widget.min}",
                  style: _selectedIndex == i
                      ? ChronosConstants.actionTextStyle
                      : ChronosConstants.primaryTextStyle,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
