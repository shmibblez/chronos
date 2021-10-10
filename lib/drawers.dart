import 'package:chronos/convenience_widgets.dart';
import 'package:chronos/cubits.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The [RightDrawer] contains metronome settings like
/// - play/pause
/// - tempo
/// - beats
/// - bar note
/// - enabled indicators
/// - color
/// FIXME: left off adding settings
class RightDrawer extends StatefulWidget {
  const RightDrawer({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _RightDrawerState();
}

class _RightDrawerState extends State<RightDrawer> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          const Text("Metronome Options"), // title text
          /// play/pause
          Row(
            children: const [
              Expanded(child: Text("play/pause")),
              HelpButton(
                  msg: "you can play or pause by tapping metronome screen"),
            ],
          ),

          /// tempo
          Row(children: [
            const Expanded(child: Text("tempo")),
            BlocBuilder<SettingsCubit, ChronosSettings>(builder: (_, settings) {
              final TextEditingController _tempoController =
                  TextEditingController(text: "${settings.bpm} bpm}");
              return Expanded(
                  child: TextField(
                      controller: _tempoController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onSubmitted: (str) {
                        int newBPM = int.parse(str);
                        // #1
                        BlocProvider.of<SettingsCubit>(context)
                            .updateBPM(newBPM);
                      }));
            }),
          ]),

          /// beats per bar
          Row(children: [
            const Expanded(child: Text("beats per bar")),
            BlocBuilder<SettingsCubit, ChronosSettings>(builder: (_, settings) {
              final TextEditingController _tempoController =
                  TextEditingController(text: settings.beatsPerBar.toString());
              return Expanded(
                  child: TextField(
                      controller: _tempoController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onSubmitted: (str) {
                        int newBeatsPerBar = int.parse(str);
                        // #1
                        BlocProvider.of<SettingsCubit>(context)
                            .updateBeats(newBeatsPerBar);
                      }));
            }),
          ]),

          /// bar note
          Row(children: [
            const Expanded(child: Text("type of note per bar")),
            BlocBuilder<SettingsCubit, ChronosSettings>(builder: (_, settings) {
              final TextEditingController _tempoController =
                  TextEditingController(
                      text: "1/${settings.beatsPerBar}} note");
              return Expanded(
                  child: TextField(
                      controller: _tempoController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onSubmitted: (str) {
                        int newBarNote = int.parse(str);
                        // #1
                        BlocProvider.of<SettingsCubit>(context)
                            .updateBarNote(newBarNote);
                      }));
            }),
          ]),

          /// enabled indicators
          /// FIXME:
          /// was trying to figure out how to
          /// - show available indicators and whether enabled/disabled
          const Text("enabled indicators"),
        ],
      ),
    );
  }
}
