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
  late bool showPresets;

  @override
  void initState() {
    super.initState();
    showPresets = false;
  }

  @override
  Widget build(BuildContext context) {
    // rebuild when relevant app settings change
    return BlocBuilder<Hephaestus, Toolbox>(
        // rebuild whole tree only if any colors change
        buildWhen: (ps, cs) => ps.color1 != cs.color1 || ps.color2 != cs.color2,
        builder: (context, settings) {
          // rebuild when relevant preset data is changed
          return BlocBuilder<Hermes, Preset>(
            // rebuild when default changes
            buildWhen: (pp, cp) => pp.isDefault != cp.isDefault,
            builder: (context, preset) {
              // drawer background color is lighter than metronome disabled color
              final Color backgroundColor = settings.color1l;
              final Color textColor =
                  settings.visibleTextColor(backgroundColor, settings.color2);
              final Color dividerColor = settings.color2d;
              final TextStyle textStyle = TextStyle(color: textColor);
              return Drawer(
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
                          children: [
                            const Text(
                              "Default Preset",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Switch(
                                value: false,
                                onChanged: (v) {
                                  showPresets = v;

                                  /// FIXME: left off here:
                                  /// - add stream where actively awaited preset is loaded to hermes (below functions). If switch changed while loading, cancel active stream and load new one
                                  ///   - syncs loaded preset with user selection (preset enabled or disabled) and prevents futures completed and switch changed
                                  /// - also if possible cache values so loads instantly (need to update cache accordingly though, notify Mnemosyne every time preset is updated)
                                  /// - add pending updates list to Mnemosyne, or to Hermes who then notifies Mnemosyne who updates instantly
                                  ///   - on first update, set timer to commit updates, and from then until timer goes off, more futures can be added or removed
                                  ///   - this prevents updating too quickly, at least in the case of bpm updates
                                  ///   - if Hermes stores list, could be map of id: {changed fields}, which is then passed on to Mnemosyne who updates db and caches
                                  if (showPresets == true) {
                                    BlocProvider.of<Hermes>(context)
                                        .loadLastPreset();
                                  } else if (!showPresets) {
                                    BlocProvider.of<Hermes>(context)
                                        .loadDefault();
                                  }
                                  // call Hermes.showDefault or Hermes.showLastPreset
                                })
                          ],
                        ),
                        const SizedBox(height: 8),

                        Divider(color: dividerColor),

                        /// edit tempo
                        Row(children: [
                          BlocBuilder<Hermes, Preset>(
                            buildWhen: (prev, curr) => prev.bpm != curr.bpm,
                            builder: (_, settings) {
                              final TextEditingController _bpmController =
                                  TextEditingController(
                                      text: settings.bpm.toString());
                              return Expanded(
                                  child: TextField(
                                      style: textStyle,
                                      textAlign: TextAlign.center,
                                      controller: _bpmController,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly
                                      ],
                                      onSubmitted: (str) {
                                        int newBPM = int.parse(str);
                                        BlocProvider.of<Hermes>(context)
                                            .updateBPM(newBPM);
                                        _bpmController.text =
                                            Preset.validateBPM(newBPM)
                                                .toString();
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
                                    final TextEditingController
                                        _beatsPerBarController =
                                        TextEditingController(
                                            text: settings.beatsPerBar
                                                .toString());
                                    return Expanded(
                                        child: TextField(
                                            style: textStyle,
                                            textAlign: TextAlign.center,
                                            controller: _beatsPerBarController,
                                            keyboardType: TextInputType.number,
                                            inputFormatters: [
                                              FilteringTextInputFormatter
                                                  .digitsOnly,
                                            ],
                                            onSubmitted: (str) {
                                              int newBeatsPerBar =
                                                  int.parse(str);
                                              BlocProvider.of<Hermes>(context)
                                                  .updateBeatsPerBar(
                                                      newBeatsPerBar);
                                              _beatsPerBarController.text =
                                                  Preset.validateBeatsPerBar(
                                                          newBeatsPerBar)
                                                      .toString();
                                            }));
                                  },
                                ),
                                const Text("/"),
                                BlocBuilder<Hermes, Preset>(
                                  buildWhen: (prev, curr) =>
                                      prev.barNote != curr.barNote,
                                  builder: (_, settings) {
                                    final TextEditingController
                                        _barNoteController =
                                        TextEditingController(
                                      text: settings.beatsPerBar.toString(),
                                    );
                                    return Expanded(
                                        child: TextField(
                                            style: textStyle,
                                            textAlign: TextAlign.center,
                                            controller: _barNoteController,
                                            keyboardType: TextInputType.number,
                                            inputFormatters: [
                                              FilteringTextInputFormatter
                                                  .digitsOnly,
                                            ],
                                            onSubmitted: (str) {
                                              int newBarNote = int.parse(str);
                                              BlocProvider.of<Hermes>(context)
                                                  .updateBarNote(newBarNote);
                                              _barNoteController.text =
                                                  Preset.validateBarNote(
                                                          newBarNote)
                                                      .toString();
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
                            ),
                          ),
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
            },
          );
        });
  }
}
