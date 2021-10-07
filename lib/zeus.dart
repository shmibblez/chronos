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

  /// init thunderbolts based on # of beats
  @override
  void initState() {
    super.initState();
    _thunderbolts = [];
    int nBolts = context.read<SettingsCubit>().state.beats;
    for (int i = 0; i < nBolts; i++) {
      _thunderbolts.add(const Thunderbolt());
    }
  }

  /// lay out thunderbolts evenly in Column
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, ChronosSettings>(
        builder: (context, chron) {
      return Column(
        children: _thunderbolts,
      );
    });
  }
}

/// Thunderbolt lights up when called upon
class Thunderbolt extends StatefulWidget {
  const Thunderbolt({Key? key}) : super(key: key);
  @override
  State<StatefulWidget> createState() => _ThunderboltState();
}

/// _ThunderboltState
class _ThunderboltState extends State<Zeus> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }

  /// animate blink
  void unleash(int indx) {
    // blink here along with tempo
  }
}
