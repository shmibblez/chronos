// todo: homepage will have:
//  - metronome in center
//  - settings icon top right
//  - preset name at the top with indicator options below (above metronome)
//  - bpm, beats per bar editors below metronome
//  - notes at the bottom (2 lines max) with edit and view icons at the end
//    - when edit pressed, opaque dialog for editing pops up, playback paused
//    - when view is pressed, semi-transparent dialog only showing note pops up (scrollable), playback continues

import 'dart:developer';

import 'package:chronos/convenience_widgets.dart';
import 'package:chronos/cubits/chronos.dart';
import 'package:chronos/cubits/hermes.dart';
import 'package:chronos/home/metronome.dart';
import 'package:chronos/main.dart';
import 'package:chronos/preset_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  late final TextEditingController _beatsPerBarController;
  late final TextEditingController _barNoteController;
  late final TextEditingController _notesController;
  // focus nodes
  late final FocusNode _nameFocusNode;
  late final FocusNode _bpmFocusNode;
  late final FocusNode _beatsPerBarFocusNode;
  late final FocusNode _barNoteFocusNode;
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

  void _saveBeatsPerBar(String str) {
    int beats = int.parse(str);
    BlocProvider.of<Hermes>(context).updateBeatsPerBar(beats);
    _beatsPerBarController.text = Preset.validateBeatsPerBar(beats).toString();
  }

  void _saveBarNote(String str) {
    int barNote = int.parse(str);
    BlocProvider.of<Hermes>(context).updateBarNote(barNote);
    _barNoteController.text = Preset.validateBarNote(barNote).toString();
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
    _beatsPerBarController = TextEditingController();
    _barNoteController = TextEditingController();
    _notesController = TextEditingController();
    // focus nodes
    _nameFocusNode = FocusNode();
    _bpmFocusNode = FocusNode();
    _beatsPerBarFocusNode = FocusNode();
    _barNoteFocusNode = FocusNode();
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
    _beatsPerBarFocusNode.addListener(() {
      // save beats per bar if focus removed
      if (!_beatsPerBarFocusNode.hasFocus) {
        _saveBeatsPerBar(_beatsPerBarController.text);
        log("saved beats per bar");
      }
    });
    _barNoteFocusNode.addListener(() {
      // save bar note if focus removed
      if (!_barNoteFocusNode.hasFocus) _saveBarNote(_barNoteController.text);
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
    _beatsPerBarController.dispose();
    _barNoteController.dispose();
    _notesController.dispose();
    // _saveNotesButtonController.dispose();
    // focus nodes
    _nameFocusNode.dispose();
    _bpmFocusNode.dispose();
    _beatsPerBarFocusNode.dispose();
    _barNoteFocusNode.dispose();
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
          child: Column(
            children: [
              // settings and help icons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                spacing: 8,
                children: [
                  // settings icon
                  GestureDetector(
                    onTap: () {
                      // todo: go to settings screen
                    },
                    child: Icon(Icons.settings),
                  ),
                  // help icon
                  GestureDetector(
                    onTap: () {
                      // todo: show help dialog
                    },
                    child: Icon(Icons.help_outline),
                  )
                ],
              ),
              /// todo: 
              ///  - reorganize layout
              ///    - add edge padding in parent,
              ///    - make whole page scrollable and add bottom inset for keyboard padding so scrolls up when item focused
              ///    - make text fields look better, make border surround text widget instead of underline
              ///    - figure out how to remove focus from textfields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  BlocBuilder<Hermes, Preset?>(
                    buildWhen: (prev, curr) => prev?.name != curr?.name,
                    builder: (context, preset) {
                      if (_oldPresetKey != preset?.key ||
                          _nameController.text.isEmpty) {
                        _nameController.text = preset?.name ?? "";
                      }
                      return Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                focusNode: _nameFocusNode,
                                enabled: true,
                                maxLength: ChronosConstants.maxNameLength,
                                readOnly: false,
                                style: textStyle,
                                textAlign: TextAlign.start,
                                controller: _nameController,
                                inputFormatters: [
                                  FilteringTextInputFormatter
                                      .singleLineFormatter,
                                ],
                                // onSubmitted:: _saveName,
                                decoration: InputDecoration(
                                  hintStyle: textStyle,
                                  hintText: "Preset Name",
                                ),
                              ),
                            ),
                            // default preset cannot be deleted
                            IconButton(
                              onPressed: () async {
                                if (preset != null) {
                                  await BlocProvider.of<Hermes>(context)
                                      .deletePreset(preset);
                                  _onPresetDeleted();
                                }
                              },
                              icon: Icon(
                                Icons.delete_forever,
                                color: Colors.white,
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),

              /// beat indicator provided by the sun god
              Helios(),

              /// edit bpm
              Row(children: [
                BlocBuilder<Hermes, Preset?>(
                  buildWhen: (prev, curr) => prev?.bpm != curr?.bpm,
                  builder: (_, preset) {
                    if (_oldPresetKey != preset?.key ||
                        _bpmController.text.isEmpty) {
                      _bpmController.text = preset?.bpm.toString() ?? "";
                    }
                    return Expanded(
                      child: TextField(
                        focusNode: _bpmFocusNode,
                        style: textStyle,
                        textAlign: TextAlign.center,
                        controller: _bpmController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        // onSubmitted:: _saveBPM,
                      ),
                    );
                  },
                ),
                Expanded(
                  child: Text(
                    "bpm",
                    textAlign: TextAlign.start,
                    style: textStyle,
                  ),
                ),
                const HelpButton(
                  msg:
                      "bpm stands for beats per minute. You can also change it by sliding up or down on the metronome screen.",
                ),
              ]),

              /// edit time signature
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        BlocBuilder<Hermes, Preset?>(
                          buildWhen: (prev, curr) =>
                              prev?.beatsPerBar != curr?.beatsPerBar,
                          builder: (_, preset) {
                            if (_oldPresetKey != preset?.key ||
                                _beatsPerBarController.text.isEmpty) {
                              _beatsPerBarController.text =
                                  preset?.beatsPerBar.toString() ?? "";
                            }
                            return Expanded(
                              child: TextField(
                                focusNode: _beatsPerBarFocusNode,
                                style: textStyle,
                                textAlign: TextAlign.center,
                                controller: _beatsPerBarController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                //  onSubmitted: _saveBeatsPerBar,
                              ),
                            );
                          },
                        ),
                        const Text("/"),
                        BlocBuilder<Hermes, Preset?>(
                          buildWhen: (prev, curr) =>
                              prev?.barNote != curr?.barNote,
                          builder: (_, preset) {
                            if (_oldPresetKey != preset?.key ||
                                _barNoteController.text.isEmpty) {
                              _barNoteController.text =
                                  preset?.barNote.toString() ?? "";
                            }
                            return Expanded(
                              child: TextField(
                                focusNode: _barNoteFocusNode,
                                style: textStyle,
                                textAlign: TextAlign.center,
                                controller: _barNoteController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                // onSubmitted:: _saveBarNote,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "time signature",
                      textAlign: TextAlign.start,
                      style: textStyle,
                    ),
                  ),
                  const HelpButton(
                    msg:
                        "The time signature specifies both the number of notes per bar, and their type. For example, 3/4 time tells us there are 3 notes per bar, and they're all quarter notes.",
                  ),
                ],
              ),

              /// edit notes, also works in default mode
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "notes",
                      textAlign: TextAlign.start,
                      style: textStyle,
                    ),
                  ),
                  const HelpButton(
                    msg:
                        "This is the notes section. Here you can write down stuff like bpm goal, song section, or anything else that's useful during your practice sessions.",
                  ),
                ],
              ),

              /// notes section
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "notes",
                      textAlign: TextAlign.start,
                      style: textStyle,
                    ),
                  ),
                  const HelpButton(
                    msg:
                        "This is the notes section. Here you can write down stuff like bpm goal, song section, or anything else that's useful during your practice sessions.",
                  ),
                ],
              ),

              // notes section
              Row(
                children: [
                  // notes text
                  Expanded(
                    child: BlocBuilder<Hermes, Preset?>(
                      buildWhen: (prev, curr) => prev?.notes != curr?.notes,
                      builder: (_, preset) {
                        if (_oldPresetKey != preset?.key ||
                            _notesController.text.isEmpty) {
                          _notesController.text = preset?.notes ?? "";
                        }
                        return Text(
                          preset?.notes ?? "",
                          style: textStyle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.start,
                        );
                      },
                    ),
                  ),
                  // edit notes icon
                  GestureDetector(
                    onTap: () {
                      // todo: show note editor dialog (opaque, scrollable TextField)
                    },
                    child: Icon(Icons.edit_note_rounded, color: Colors.white54),
                  ),
                  // edit notes icon
                  GestureDetector(
                    onTap: () {
                      // todo: show note dialog (scrollable and partly transparent)
                    },
                    child:
                        Icon(Icons.visibility_rounded, color: Colors.white54),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
