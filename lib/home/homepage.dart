// todo: stuff to fix:
//  - when go to component that pauses metronome, when come back only resume if playing before
//  - fix preset drawer (too tranparent, make 4/5ths of width or something like that)
//  - add play / pause button at the top, don't start playing automatically on startup
//  - move chronos timer, audio & vibrate to its own thread
//  - add trash icon to delete at the top, when delete requested show dialog to confirm
//  - make
//  - create add button at the top for preset list

import 'package:chronos/chronos_constants.dart';
import 'package:chronos/cubits/chronos.dart';
import 'package:chronos/cubits/hermes.dart';
import 'package:chronos/home/metronome.dart';
import 'package:chronos/home/top_icons.dart';
import 'package:chronos/preset_drawer.dart';
import 'package:chronos/widgets/text_editor.dart';
import 'package:chronos/widgets/time_signature_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<StatefulWidget> createState() {
    return HomepageState();
  }
}

class HomepageState extends State {
  // val
  final TextStyle textStyle = TextStyle(color: Colors.white, fontSize: 14);
  // scaffold
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late double _bpmChange;
  // delta to bpm equivalent (how much scroll distance is considered for 1 bpm)
  static const double _bpmThreshold = 10.0;

  // todo: remove comment when add delete preset option
  // /// delete preset
  // Future<void> _onPresetDeleted() async {
  //   // active preset can be deleted (first list item)
  //   Hermes h = BlocProvider.of<Hermes>(context);
  //   // load last preset to replace current one
  //   h.loadLastPreset();
  // }

  void _saveName(String str) {
    final validated = Preset.validateName(str);
    BlocProvider.of<Hermes>(context).updateName(validated);
  }

  void _saveBPM(String str) {
    int bpm = int.parse(str);
    final validated = Preset.validateBPM(bpm);
    BlocProvider.of<Hermes>(context).updateBPM(validated);
  }

  void _saveNotes(String notes) {
    final validated = Preset.validateNotes(notes);
    BlocProvider.of<Hermes>(context).updateNotes(validated);
  }

  void _updateBpm(double change) {
    _bpmChange += change;
    final wholeBpms = _bpmChange / _bpmThreshold;
    if (wholeBpms.abs() > 1) {
      // reset threshold
      _bpmChange = 0;
      BlocProvider.of<Hermes>(context).updateBPMbyThrottled(wholeBpms.toInt());
    }
  }

  @override
  void initState() {
    _bpmChange = 0;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      key: _scaffoldKey,
      drawer: const PresetDrawer(),
      // endDrawer: const SettingsDrawer(),
      onDrawerChanged: (open) {
        if (!open) {
          BlocProvider.of<Chronos>(context).start();
        } else {
          BlocProvider.of<Chronos>(context).stop();
        }
      },
      body: SizedBox(
        width: double.maxFinite,
        // height: MediaQuery.of(context).size.height,
        child: GestureDetector(
          // on tap toggle metronome click -> play/pause
          onTap: () {
            BlocProvider.of<Chronos>(context).togglePlaying();
          },
          // change tempo based on scroll amount
          // positive amount is down (tempo decrease)
          // negative amount is up (tempo increase)
          onVerticalDragUpdate: (DragUpdateDetails details) {
            _updateBpm(-details.delta.dy);
          },
          onHorizontalDragUpdate: (details) {
            if (details.delta.dx > 0) {
              // if swipe right, open drawer
              _scaffoldKey.currentState?.openDrawer();
            }
          },
          child: Padding(
            padding: EdgeInsetsGeometry.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                TopIcons(
                  openDrawer: () {
                    _scaffoldKey.currentState?.openDrawer();
                  },
                ),

                /// todo: use old code below for input formatting & saving new title
                // /// preset title
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //   children: [
                //     BlocBuilder<Hermes, Preset?>(
                //       buildWhen: (prev, curr) => prev?.name != curr?.name,
                //       builder: (context, preset) {
                //         if (_oldPresetKey != preset?.key ||
                //             _nameController.text.isEmpty) {
                //           _nameController.text = preset?.name ?? "";
                //         }
                //         return Expanded(
                //           child: Row(
                //             children: [
                //               Expanded(
                //                 child: TextField(
                //                   focusNode: _nameFocusNode,
                //                   enabled: true,
                //                   maxLength: ChronosConstants.maxNameLength,
                //                   readOnly: false,
                //                   style: textStyle,
                //                   textAlign: TextAlign.start,
                //                   controller: _nameController,
                //                   inputFormatters: [
                //                     FilteringTextInputFormatter
                //                         .singleLineFormatter,
                //                   ],
                //                   // onSubmitted:: _saveName,
                //                   decoration: InputDecoration(
                //                     hintStyle: textStyle,
                //                     hintText: "Preset Name",
                //                   ),
                //                 ),
                //               ),
                //               // default preset cannot be deleted
                //               IconButton(
                //                 onPressed: () async {
                //                   if (preset != null) {
                //                     await BlocProvider.of<Hermes>(context)
                //                         .deletePreset(preset);
                //                     _onPresetDeleted();
                //                   }_onPresetDeleted
                //                 },
                //                 icon: Icon(
                //                   Icons.delete_forever,
                //                   color: Colors.white,
                //                 ),
                //               )
                //             ],
                //           ),
                //         );
                //       },
                //     ),
                //   ],
                // ),

                // preset title
                BlocBuilder<Hermes, Preset?>(
                  buildWhen: (prev, curr) => prev?.name != curr?.name,
                  builder: (_, preset) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      spacing: 6,
                      children: [
                        // title
                        Text(
                          "preset title",
                          style: ChronosConstants.smallTextStyle,
                        ),
                        // title
                        GestureDetector(
                          onTap: () {
                            BlocProvider.of<Chronos>(context).stop();
                            showModalBottomSheet<dynamic>(
                              isScrollControlled: true,
                              context: context,
                              builder: (_) {
                                return TextEditor(
                                  title: "edit preset title",
                                  onDismiss: () {
                                    Navigator.pop(context);
                                    BlocProvider.of<Chronos>(context).start();
                                  },
                                  onSave: (text) {
                                    _saveName(text);
                                    Navigator.pop(context);
                                    BlocProvider.of<Chronos>(context).start();
                                  },
                                  initialText: preset?.name ?? "",
                                  textValidator: (text) {
                                    if (text.length >
                                        ChronosConstants.maxNameLength) {
                                      return "text too long";
                                    } else if (text.length <
                                        ChronosConstants.minNameLength) {
                                      return "text must have at least ${ChronosConstants.minNameLength} characters";
                                    }
                                    return null;
                                  },
                                );
                              },
                            ).whenComplete(
                              () {
                                if (context.mounted) {
                                  BlocProvider.of<Chronos>(context).start();
                                }
                              },
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.all(12),
                            width: double.maxFinite,
                            alignment: AlignmentDirectional.centerStart,
                            decoration: BoxDecoration(
                              border: BoxBorder.all(
                                color: Colors.white70,
                                style: BorderStyle.solid,
                              ),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(4)),
                            ),
                            child: Text(
                              (preset != null && preset.name.isNotEmpty)
                                  ? preset.name
                                  : "Preset Title (Click to edit)",
                              style: (preset?.name ?? "").isNotEmpty
                                  ? ChronosConstants.titleTextStyle
                                  : ChronosConstants.secondaryTitleTextStyle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.start,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                /// beat indicator provided by the sun god
                Helios(),

                // bpm & time signature
                BlocBuilder<Hermes, Preset?>(
                  buildWhen: (prev, curr) =>
                      prev?.bpm != curr?.bpm ||
                      prev?.beatsPerBar != curr?.beatsPerBar ||
                      prev?.barNote != curr?.barNote,
                  builder: (_, preset) {
                    final bpbText = preset?.beatsPerBar == null
                        ? "  "
                        : preset!.beatsPerBar < 10
                            ? " ${preset.beatsPerBar}"
                            : "${preset.beatsPerBar}";
                    final bnText = preset?.barNote == null
                        ? "  "
                        : preset!.barNote < 10
                            ? "${preset.barNote} "
                            : "${preset.barNote}";

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Spacer(),

                        // bpm
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            spacing: 6,
                            children: [
                              // title
                              Text(
                                "bpm",
                                style: ChronosConstants.smallTextStyle,
                              ),
                              // bpm
                              GestureDetector(
                                onTap: () {
                                  BlocProvider.of<Chronos>(context).stop();
                                  showModalBottomSheet<dynamic>(
                                    isScrollControlled: true,
                                    context: context,
                                    builder: (_) {
                                      return TextEditor(
                                        title: "edit bpm",
                                        onDismiss: () {
                                          Navigator.pop(context);
                                          BlocProvider.of<Chronos>(context)
                                              .start();
                                        },
                                        onSave: (text) {
                                          _saveBPM(text);
                                          Navigator.pop(context);
                                          BlocProvider.of<Chronos>(context)
                                              .start();
                                        },
                                        numbersOnly: true,
                                        initialText:
                                            "${preset?.bpm ?? ChronosConstants.defaultBPM}",
                                        textValidator: (text) {
                                          if (int.parse(text) >
                                              ChronosConstants.maxBPM) {
                                            return "max bpm is ${ChronosConstants.maxBPM}";
                                          } else if (int.parse(text) <
                                              ChronosConstants.minBPM) {
                                            return "min bpm is ${ChronosConstants.minBPM}";
                                          }
                                          return null;
                                        },
                                      );
                                    },
                                  ).whenComplete(() {
                                    if (context.mounted) {
                                      BlocProvider.of<Chronos>(context).start();
                                    }
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.all(12),
                                  width: double.maxFinite,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    border: BoxBorder.all(
                                      color: Colors.white70,
                                      style: BorderStyle.solid,
                                    ),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(4)),
                                  ),
                                  child: Text("${preset?.bpm ?? ""}",
                                      style: textStyle),
                                ),
                              ),
                            ],
                          ),
                        ),

                        Spacer(),

                        // time signature
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            spacing: 6,
                            children: [
                              // title
                              Text(
                                "time signature",
                                style: ChronosConstants.smallTextStyle,
                              ),
                              // time signature
                              GestureDetector(
                                onTap: () {
                                  BlocProvider.of<Chronos>(context).stop();
                                  showModalBottomSheet<dynamic>(
                                      isScrollControlled: true,
                                      context: context,
                                      builder: (_) {
                                        return TimeSignatureSelector(
                                          initialBeatsPerBar:
                                              preset?.beatsPerBar ?? 4,
                                          initialBarNote: preset?.barNote ?? 4,
                                          onDismiss: () {
                                            Navigator.pop(context);
                                            BlocProvider.of<Chronos>(context)
                                                .start();
                                          },
                                          onTimeSignatureSaved: (bpb, bn) {
                                            Navigator.pop(context);
                                            BlocProvider.of<Chronos>(context)
                                                .start();
                                            BlocProvider.of<Hermes>(context)
                                                .updateBeatsPerBar(bpb);
                                            BlocProvider.of<Hermes>(context)
                                                .updateBarNote(bn);
                                          },
                                        );
                                      }).whenComplete(() {
                                    if (context.mounted) {
                                      BlocProvider.of<Chronos>(context).start();
                                    }
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.all(12),
                                  width: double.maxFinite,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    border: BoxBorder.all(
                                      color: Colors.white70,
                                    ),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(4)),
                                  ),
                                  child: Text("$bpbText / $bnText",
                                      style: textStyle),
                                ),
                              ),
                            ],
                          ),
                        ),

                        Spacer(),
                      ],
                    );
                  },
                ),

                // notes section
                BlocBuilder<Hermes, Preset?>(
                  buildWhen: (prev, curr) => prev?.notes != curr?.notes,
                  builder: (_, preset) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      spacing: 6,
                      children: [
                        // title
                        Text(
                          "notes",
                          style: ChronosConstants.smallTextStyle,
                        ),
                        // notes
                        Container(
                          padding: EdgeInsets.all(12),
                          width: double.maxFinite,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: BoxBorder.all(
                              color: Colors.white70,
                              style: BorderStyle.solid,
                            ),
                            borderRadius: BorderRadius.all(Radius.circular(4)),
                          ),
                          child: GestureDetector(
                            onTap: () {
                              BlocProvider.of<Chronos>(context).stop();
                              showModalBottomSheet<dynamic>(
                                isScrollControlled: true,
                                context: context,
                                builder: (_) {
                                  //  in this case make fill max height since notes can get pretty big
                                  return TextEditor(
                                    title: "edit notes",
                                    onDismiss: () {
                                      Navigator.pop(context);
                                      BlocProvider.of<Chronos>(context).start();
                                    },
                                    onSave: (text) {
                                      _saveNotes(text);
                                      Navigator.pop(context);
                                      BlocProvider.of<Chronos>(context).start();
                                    },
                                    initialText: preset?.notes ?? "",
                                    textValidator: (text) {
                                      if (text.length >
                                          ChronosConstants.maxNotesLength) {
                                        return "max bpm is ${ChronosConstants.maxBPM}";
                                      } else if (text.length <
                                          ChronosConstants.minNotesLength) {
                                        return "min bpm is ${ChronosConstants.minBPM}";
                                      }
                                      return null;
                                    },
                                  );
                                },
                              ).whenComplete(() {
                                if (context.mounted) {
                                  BlocProvider.of<Chronos>(context).start();
                                }
                              });
                            },
                            // notes text & view icon
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              spacing: 12,
                              children: [
                                // notes text
                                Expanded(
                                  child: Text(
                                    (preset != null && preset.notes.isNotEmpty)
                                        ? preset.notes
                                        : "You can add notes here. I usually use them to save a song's bpm so i know how much arthritis awaits on my guitar.",
                                    style: (preset?.notes ?? "").isNotEmpty
                                        ? ChronosConstants.primaryTextStyle
                                        : ChronosConstants.secondaryTextStyle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.start,
                                  ),
                                ),
                                // view icon
                                GestureDetector(
                                  onTap: () {
                                    // todo: show notes viewer
                                  },
                                  child: Icon(Icons.visibility_rounded),
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
