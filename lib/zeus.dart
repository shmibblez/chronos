import 'dart:async';

import 'package:chronos/cubits.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Zeus holds Thunderbolts and activates them when necessary
class Zeus extends StatefulWidget {
  const Zeus({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ZeusState();
}

class _ZeusState extends State<Zeus> {
  late final List<Thunderbolt> _thunderbolts;
  late List<ThunderboltController> _thunderboltControllers;
  late final StreamSubscription<int> _chronosSub;
  late int _lastBeat;

  /// init thunderbolts based on # of beats
  @override
  void initState() {
    super.initState();
    _thunderbolts = [];
    _thunderboltControllers = [];
    int nBolts = context.read<SettingsCubit>().state.beats;
    for (int i = 0; i < nBolts; i++) {
      _thunderboltControllers.add(ThunderboltController());
      _thunderbolts.add(Thunderbolt(
        controller: _thunderboltControllers.last,
      ));
    }
    _lastBeat = -1;
    _chronosSub = BlocProvider.of<Chronos>(context).stream.listen((int event) {
      if (_lastBeat != -1) _thunderboltControllers[_lastBeat].vanish!();
      _thunderboltControllers[event].unleash!();
      _lastBeat = event;
    });
  }

  /// lay out thunderbolts evenly in Column
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, ChronosSettings>(
      builder: (context, chron) {
        return Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var t in _thunderbolts) Expanded(child: t),
            ]);
      },
    );
  }

  /// dispose
  @override
  void dispose() {
    _chronosSub.cancel();
    super.dispose();
  }
}

/// [Thunderbolt] controller, allows [Zeus] to call [_ThunderboltState] functions
class ThunderboltController {
  void Function()? unleash;
  void Function()? vanish;
}

/// Thunderbolt lights up when called upon
class Thunderbolt extends StatefulWidget {
  const Thunderbolt(
      {required this.controller, Key? key, this.initiallyUnleashed = false})
      : super(key: key);
  final bool initiallyUnleashed;
  final ThunderboltController controller;
  @override
  State<StatefulWidget> createState() => _ThunderboltState();
}

/// _ThunderboltState
class _ThunderboltState extends State<Thunderbolt> {
  late bool unleashed;

  @override
  void initState() {
    super.initState();
    unleashed = widget.initiallyUnleashed;
    widget.controller.unleash = unleash;
    widget.controller.vanish = vanish;
  }

  @override
  void didUpdateWidget(covariant Thunderbolt oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.controller.unleash = unleash;
    widget.controller.vanish = vanish;
  }

  @override
  void dispose() {
    widget.controller.unleash = null;
    widget.controller.vanish = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        color: unleashed
            ? BlocProvider.of<SettingsCubit>(context).state.color2
            : BlocProvider.of<SettingsCubit>(context).state.color1);
  }

  /// set background color to on
  void unleash() {
    setState(() {
      unleashed = true;
    });
  }

  /// set background color to off
  void vanish() {
    setState(() {
      unleashed = false;
    });
  }
}
