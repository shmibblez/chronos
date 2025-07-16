import 'dart:developer';

import 'package:chronos/cubits/hephaestus.dart';
import 'package:chronos/cubits/hermes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

dynamic printPresetKeys(List<Preset> presets) {
  log("-- keys:");
  for (Preset p in presets) {
    log("   ${p.key}, millis: ${p.millis.toString()}");
  }
  log("-------");
}

/// The [PresetDrawer] is [Hermes]'s domain, and is where metronome presets live
/// presets store the following
/// - preset name
/// - notes (so user can store progress and write down tempos)
/// - tempo
/// - date last used
///
/// selected preset is shown, all values are shown in [TextField]s so can be easily edited
class PresetDrawer extends StatefulWidget {
  const PresetDrawer({
    super.key,
    required this.onDismiss,
  });

  final void Function() onDismiss;

  @override
  State<StatefulWidget> createState() => _PresetDrawerState();
}

class _PresetDrawerState extends State<PresetDrawer> {
  @override
  Widget build(BuildContext context) {
    // used to have GestureDetector here, for detecting focus changes
    // onTap: () {
    //   // #9
    //   _saveNotes();
    //   // remove focus from widget, allows submitting
    //   FocusScopeNode? currentFocus = FocusScope.of(context);
    //   currentFocus.unfocus();
    // },
    return BlocBuilder<Hephaestus, Toolbox>(
      // rebuild whole tree only if any colors change
      // or if presets enabled state changedCanvas
      buildWhen: (ps, cs) => ps.color1 != cs.color1 || ps.color2 != cs.color2,
      builder: (_, settings) {
        return PresetList(
          onAddPreset: _onAddNewPreset,
          onDelete: (preset) => _onPresetDeleted(),
          onSelectPreset: () {
            widget.onDismiss();
          },
        );
      },
    );
  }

  void _onAddNewPreset() {
    BlocProvider.of<Hermes>(context).loadNewPreset();
    widget.onDismiss();
  }

  Future<void> _onPresetDeleted() async {
    // active preset can be deleted (first list item)
    Hermes h = BlocProvider.of<Hermes>(context);
    // load last preset to replace current one
    h.loadLastPreset();
    widget.onDismiss();
  }
}
