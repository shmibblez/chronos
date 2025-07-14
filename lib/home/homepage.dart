// todo: stuff to fix:
//  - when go to component that pauses metronome, when come back only resume if playing before
//  - fix preset drawer (too tranparent, also drawer too wide (width at least space of 20 from right), 
//    or make 4/5ths of width or something like that)
//  - app icon
//  - 

import 'package:chronos/cubits/chronos.dart';
import 'package:chronos/cubits/hermes.dart';
import 'package:chronos/home/metronome.dart';
import 'package:chronos/main.dart';
import 'package:chronos/preset_drawer.dart';
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
  // text field controllers
  late final TextEditingController _nameController;
  late final TextEditingController _bpmController;
  late final TextEditingController _notesController;
  // focus nodes
  late final FocusNode _nameFocusNode;
  late final FocusNode _bpmFocusNode;
  late final FocusNode _notesFocusNode;
  // used to know if need to update textfield values in case of preset or toolbox change
  late String _oldPresetKey;

  /// delete preset
  Future<void> _onPresetDeleted() async {
    // active preset can be deleted (first list item)
    Hermes h = BlocProvider.of<Hermes>(context);
    // load last preset to replace current one
    h.loadLastPreset();
  }

  void _saveName(String str) {
    BlocProvider.of<Hermes>(context).updateName(str);
    _nameController.text = Preset.validateName(str);
  }

  void _saveBPM(String str) {
    int bpm = int.parse(str);
    BlocProvider.of<Hermes>(context).updateBPM(bpm);
    _bpmController.text = Preset.validateBPM(bpm).toString();
  }

  void _saveNotes() {
    final validated = Preset.validateNotes(_notesController.text);
    _notesController.text = validated;
    BlocProvider.of<Hermes>(context).updateNotes(validated);
    if (_notesFocusNode.hasFocus) _notesFocusNode.unfocus();
  }

  @override
  void initState() {
    super.initState();
    // controllers
    // _ac = AnimationController(vsync: this)
    _nameController = TextEditingController();
    _bpmController = TextEditingController();
    _notesController = TextEditingController();
    // focus nodes
    _nameFocusNode = FocusNode();
    _bpmFocusNode = FocusNode();
    _notesFocusNode = FocusNode();
    // focus node listeners (save changes when focus removed)
    // no need to store since dont need to be removed (don't change and focus nodes disposed)
    // for all of these:
    // - if focus removed from textfield, save value
    _nameFocusNode.addListener(() {
      // save name if focus removed
      if (!_nameFocusNode.hasFocus) _saveName(_nameController.text);
    });
    _bpmFocusNode.addListener(() {
      // save bpm if focus removed
      if (!_bpmFocusNode.hasFocus) _saveBPM(_bpmController.text);
    });
    _notesFocusNode.addListener(() {
      // save notes if focus removed
      if (!_notesFocusNode.hasFocus) _saveNotes();
    });

    _oldPresetKey = "";
  }

  @override
  void dispose() {
    // controllers
    _nameController.dispose();
    _bpmController.dispose();
    _notesController.dispose();
    // _saveNotesButtonController.dispose();
    // focus nodes
    _nameFocusNode.dispose();
    _bpmFocusNode.dispose();
    _notesFocusNode.dispose();

    super.dispose();
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
            // change tempo by 1
            double delta = details.delta.dy;
            int bpmChange = -delta.sign.toInt();
            BlocProvider.of<Hermes>(context).updateBPMbyThrottled(bpmChange);
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
                // settings and help icons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  spacing: 12,
                  children: [
                    // menu item
                    GestureDetector(
                      onTap: () {
                        _scaffoldKey.currentState?.openDrawer();
                      },
                      child: Icon(Icons.menu_rounded, color: Colors.white),
                    ),

                    Spacer(),

                    // settings icon
                    GestureDetector(
                      onTap: () {
                        // todo: go to settings screen
                      },
                      child: Icon(Icons.settings, color: Colors.white),
                    ),
                    // help icon
                    GestureDetector(
                      onTap: () {
                        // todo: show help dialog
                      },
                      child: Icon(Icons.help_outline, color: Colors.white),
                    )
                  ],
                ),

                /// todo:
                ///  - reorganize layout
                ///    - add edge padding in parent,
                ///    - make whole page scrollable and add bottom inset for keyboard padding so scrolls up when item focused
                ///    - make text fields look better, make border surround text widget instead of underline
                ///    - figure out how to remove focus from textfields

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
                //                   }
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
                  buildWhen: (prev, curr) => prev?.notes != curr?.notes,
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
                        // notes
                        Container(
                          padding: EdgeInsets.all(12),
                          width: double.maxFinite,
                          alignment: AlignmentDirectional.centerStart,
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
                              showModalBottomSheet<void>(
                                context: context,
                                builder: (_) {
                                  // todo: make text editor template with title, onSave and onDismiss
                                  //  in this case make fill max height since notes can get pretty big
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.pop(context);
                                      BlocProvider.of<Chronos>(context).start();
                                    },
                                    child: Text("under construction >:("),
                                  );
                                },
                              ).whenComplete(() {
                                if (mounted) {
                                  BlocProvider.of<Chronos>(context).start();
                                }
                              });
                            },
                            // notes text & view icon
                            child: Text(
                              (preset != null && preset.notes.isNotEmpty)
                                  ? preset.notes
                                  : "Preset Title (Click to edit)",
                              style: (preset?.notes ?? "").isNotEmpty
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

                // /// edit bpm
                // Row(children: [
                //   BlocBuilder<Hermes, Preset?>(
                //     buildWhen: (prev, curr) => prev?.bpm != curr?.bpm,
                //     builder: (_, preset) {
                //       if (_oldPresetKey != preset?.key ||
                //           _bpmController.text.isEmpty) {
                //         _bpmController.text = preset?.bpm.toString() ?? "";
                //       }
                //       return Expanded(
                //         child: TextField(
                //           focusNode: _bpmFocusNode,
                //           style: textStyle,
                //           textAlign: TextAlign.center,
                //           controller: _bpmController,
                //           keyboardType: TextInputType.number,
                //           inputFormatters: [
                //             FilteringTextInputFormatter.digitsOnly
                //           ],
                //           // onSubmitted:: _saveBPM,
                //         ),
                //       );
                //     },
                //   ),
                //   Expanded(
                //     child: Text(
                //       "bpm",
                //       textAlign: TextAlign.start,
                //       style: textStyle,
                //     ),
                //   ),
                //   const HelpButton(
                //     msg:
                //         "bpm stands for beats per minute. You can also change it by sliding up or down on the metronome screen.",
                //   ),
                // ]),

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
                              Container(
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
                                child: GestureDetector(
                                  onTap: () {
                                    BlocProvider.of<Chronos>(context).stop();
                                    showModalBottomSheet<void>(
                                      context: context,
                                      builder: (_) {
                                        // todo: make text editor template with title, onSave and onDismiss
                                        return GestureDetector(
                                          onTap: () {
                                            Navigator.pop(context);
                                            BlocProvider.of<Chronos>(context)
                                                .start();
                                          },
                                          child: Text("under construction >:("),
                                        );
                                      },
                                    ).whenComplete(() {
                                      if (mounted) {
                                        BlocProvider.of<Chronos>(context)
                                            .start();
                                      }
                                    });
                                  },
                                  // beats per bar & bar note
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
                              Container(
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
                                child: GestureDetector(
                                  onTap: () {
                                    BlocProvider.of<Chronos>(context).stop();
                                    showModalBottomSheet<void>(
                                        context: context,
                                        builder: (_) {
                                          return TimeSignatureSelector(
                                            initialBeatsPerBar:
                                                preset?.beatsPerBar ?? 4,
                                            initialBarNote:
                                                preset?.barNote ?? 4,
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
                                      if (mounted) {
                                        BlocProvider.of<Chronos>(context)
                                            .start();
                                      }
                                    });
                                  },
                                  // beats per bar & bar note
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

                // /// edit notes, also works in default mode
                // Row(
                //   children: [
                //     Expanded(
                //       child: Text(
                //         "notes",
                //         textAlign: TextAlign.start,
                //         style: textStyle,
                //       ),
                //     ),
                //     const HelpButton(
                //       msg:
                //           "This is the notes section. Here you can write down stuff like bpm goal, song section, or anything else that's useful during your practice sessions.",
                //     ),
                //   ],
                // ),

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
                              showModalBottomSheet<void>(
                                context: context,
                                builder: (_) {
                                  // todo: make text editor template with title, onSave and onDismiss
                                  //  in this case make fill max height since notes can get pretty big
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.pop(context);
                                      BlocProvider.of<Chronos>(context).start();
                                    },
                                    child: Text("under construction >:("),
                                  );
                                },
                              ).whenComplete(() {
                                if (mounted) {
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
