import 'package:chronos/convenience_widgets.dart';
import 'package:chronos/cubits/hephaestus.dart';
import 'package:chronos/cubits/hermes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The [LeftDrawer] is [Hermes]'s domain, and is where metronome presets live
/// presets store the following
/// - preset name
/// - notes (so user can store progress and write down tempos)
/// - tempo
/// - date last used
///
/// selected preset is shown, all values are shown in [TextField]s so can be easily edited
class LeftDrawer extends StatefulWidget {
  const LeftDrawer({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _LeftDrawerState();
}

class _LeftDrawerState extends State<LeftDrawer> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<Hephaestus, Toolbox>(
        // rebuild whole tree only if any colors change
        buildWhen: (prev, curr) =>
            prev.color1 != curr.color1 || prev.color2 != curr.color2,
        builder: (context, settings) {
          final Color backgroundColor = settings.color1l;
          final Color textColor =
              settings.visibleTextColor(backgroundColor, settings.color2);
          final Color dividerColor = settings.color2d;
          final TextStyle textStyle = TextStyle(color: textColor);
          return Drawer(
            // drawer background color is lighter than metronome disabled color
            backgroundColor: backgroundColor,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: DefaultTextStyle(
                style: textStyle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    /// title text
                    Row(
                      children: const [
                        Text(
                          "Default Preset",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        )
                      ],
                    ),
                    const SizedBox(height: 8),

                    Divider(color: dividerColor),

                    /// edit tempo
                    Row(children: [
                      BlocBuilder<Hermes, Preset>(
                        buildWhen: (prev, curr) => prev.bpm != curr.bpm,
                        builder: (_, settings) {
                          final TextEditingController _tempoController =
                              TextEditingController(
                                  text: settings.bpm.toString());
                          return Expanded(
                              child: TextField(
                                  style: textStyle,
                                  textAlign: TextAlign.center,
                                  controller: _tempoController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                  onSubmitted: (str) {
                                    int newBPM = int.parse(str);
                                    BlocProvider.of<Hermes>(context)
                                        .updateBPM(newBPM);
                                  }));
                        },
                      ),
                      const Expanded(
                        child: Text("bpm", textAlign: TextAlign.start),
                      ),
                      const HelpButton(
                        msg:
                            "bpm stands for beats per minute. You can also change it by sliding up or down on the metronome screen.",
                      ),
                    ]),

                    /// edit time signature
                    Row(children: [
                      Expanded(
                        child: Row(
                          children: [
                            BlocBuilder<Hermes, Preset>(
                              buildWhen: (prev, curr) =>
                                  prev.beatsPerBar != curr.beatsPerBar,
                              builder: (_, settings) {
                                final TextEditingController _tempoController =
                                    TextEditingController(
                                        text: settings.beatsPerBar.toString());
                                return Expanded(
                                    child: TextField(
                                        style: textStyle,
                                        textAlign: TextAlign.center,
                                        controller: _tempoController,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly
                                        ],
                                        onSubmitted: (str) {
                                          int newBeatsPerBar = int.parse(str);
                                          BlocProvider.of<Hermes>(context)
                                              .updateBeatsPerBar(
                                                  newBeatsPerBar);
                                        }));
                              },
                            ),
                            const Text("/"),
                            BlocBuilder<Hermes, Preset>(
                              buildWhen: (prev, curr) =>
                                  prev.barNote != curr.barNote,
                              builder: (_, settings) {
                                final TextEditingController _tempoController =
                                    TextEditingController(
                                  text: settings.beatsPerBar.toString(),
                                );
                                return Expanded(
                                    child: TextField(
                                        style: textStyle,
                                        textAlign: TextAlign.center,
                                        controller: _tempoController,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly
                                        ],
                                        onSubmitted: (str) {
                                          int newBarNote = int.parse(str);
                                          BlocProvider.of<Hermes>(context)
                                              .updateBarNote(newBarNote);
                                        }));
                              },
                            ),
                          ],
                        ),
                      ),
                      const Expanded(
                          child: Text(
                        "time signature",
                        textAlign: TextAlign.start,
                      )),
                      const HelpButton(
                        msg:
                            "The time signature specifies both the number of notes per bar, and their type. For example, 3/4 time tells us there are 3 notes per bar, and they're all quarter notes.",
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          );
        });
  }
}
