import 'dart:developer';

import 'package:chronos/convenience_widgets.dart';
import 'package:chronos/cubits/hephaestus.dart';
import 'package:chronos/cubits/hermes.dart';
import 'package:chronos/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sliding_sheet/sliding_sheet.dart';
import 'dart:math' show min;

printPresetKeys(List<Preset> presets) {
  log("-- keys:");
  for (Preset p in presets) {
    log("   " +
        p.key +
        ", millis: " +
        p.millis.toString() +
        (p.isDefault ? " (default)" : ""));
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
  const PresetDrawer({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PresetDrawerState();
}

class _PresetDrawerState extends State<PresetDrawer> {
  // controllers
  late final SheetController _sc;
  late final SliderHeaderController _hc;
  late final TextEditingController _nameController;
  late final TextEditingController _bpmController;
  late final TextEditingController _beatsPerBarController;
  late final TextEditingController _barNoteController;
  late final TextEditingController _notesController;
  late final SaveNotesButtonController _saveNotesButtonController;
// focus nodes
  late final FocusNode _nameFocusNode;
  late final FocusNode _bpmFocusNode;
  late final FocusNode _beatsPerBarFocusNode;
  late final FocusNode _barNoteFocusNode;
  late final FocusNode _notesFocusNode;
  // used to know if need to update textfield values in case of preset or toolbox change
  late String _oldPresetKey;

  @override
  void initState() {
    super.initState();
    // controllers
    _sc = SheetController();
    _hc = SliderHeaderController();
    _nameController = TextEditingController();
    _bpmController = TextEditingController();
    _beatsPerBarController = TextEditingController();
    _barNoteController = TextEditingController();
    _notesController = TextEditingController();
    _saveNotesButtonController = SaveNotesButtonController();
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
      // or if presets enabled state changed
      buildWhen: (ps, cs) =>
          ps.color1 != cs.color1 ||
          ps.color2 != cs.color2 ||
          ps.presetsEnabled != cs.presetsEnabled,
      builder: (_, settings) {
        // set initial preset
        _setPreset(settings.presetsEnabled);
        // Mobile:
        // Width = Screen width − 56 dp
        // Maximum width: 320dp
        // Maximum width applies only when using a left nav. When using a right nav,
        // the panel can cover the full width of the screen.
        // Desktop/Tablet:
        // Maximum width for a left nav is 400dp.
        // The right nav can vary depending on content.
        final screenW = MediaQuery.of(context).size.width;
        final w = min((screenW * (2 / 3)).truncate().toDouble(), 304.0);
        // rebuild when relevant app settings change
        return SizedBox(
          height: double.infinity,
          width: w,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SlidingSheet(
              controller: _sc,
              minHeight: MediaQuery.of(context).size.height,
              duration: const Duration(milliseconds: 300),
              snapSpec: SnapSpec(
                initialSnap: settings.presetsEnabled ? SnapSpec.headerSnap : 0,
                snappings: [SnapSpec.headerSnap, 1],
                positioning: SnapPositioning.relativeToAvailableSpace,
              ),
              body: buildPreset(settings),
              headerBuilder: (_, state) => SliderHeader(
                state: _HeaderState.peeking,
                action: _onClickPanelHeader,
                newPreset: _onClickNewPreset,
                controller: _hc,
              ),
              listener: (state) {
                if (state.isExpanded) {
                  _hc.notifyExpanded();
                } else {
                  _hc.notifyPeeking();
                }
              },
              customBuilder: (_, controller, __) => PresetList(
                controller: controller,
                action: _peek,
                delete: (preset) => _onPresetDeleted(enabledAfter: true),
              ),
            ),
          ),
        );
      },
    );
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
    _saveNotesButtonController.disable();
    _saveNotesButtonController.hide();
    if (_notesFocusNode.hasFocus) _notesFocusNode.unfocus();
  }

  void _setPreset(bool enabled) {
    if (enabled) {
      _peek();
      BlocProvider.of<Hermes>(context).loadLastPreset();
    } else if (!enabled) {
      BlocProvider.of<Hermes>(context).loadDefault();
      _hide();
    }
  }

  /// collapse and only show header
  /// called when preset selected from preset list
  Future<void> _peek() async {
    await _sc.snapToExtent(SnapSpec.headerSnap);
  }

  /// completely expand sheet
  /// called when presets enabled, or when user wants to change current preset
  Future<void> _expand() async {
    await _sc.expand();
  }

  /// completely hide sheet
  /// called when user cancels preset selection, or presets disabled
  Future<void> _hide() async {
    await _sc.hide();
  }

  void _onClickPanelHeader() {
    if (_sc.state!.isCollapsed) {
      _expand();
    } else {
      _peek();
    }
  }

  void _onClickNewPreset() {
    BlocProvider.of<Hermes>(context).loadNewPreset();
    _peek();
  }

  Future<void> _onPresetDeleted({required bool enabledAfter}) async {
    // active preset can be deleted (first list item)
    Hermes h = BlocProvider.of<Hermes>(context);
    // if enabled after
    if (enabledAfter) {
      // load last preset to replace current one
      h.loadLastPreset();
    } else {
      // else load default preset and disable presets
      h.loadDefault();
    }
    BlocProvider.of<Hephaestus>(context).updatePresetsEnabled(enabledAfter);
  }

  Widget buildPreset(Toolbox settings) {
    // drawer background color is lighter than metronome disabled color
    final Color backgroundColor = settings.color1l;
    final Color textColor =
        settings.visibleTextColor(backgroundColor, settings.color2);
    final Color dividerColor = settings.color2d;
    final TextStyle textStyle = TextStyle(color: textColor, fontSize: 14);
    // update old preset key
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      _oldPresetKey = BlocProvider.of<Hermes>(context).state.key;
    });
    return Drawer(
      backgroundColor: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
        child: DefaultTextStyle(
          style: textStyle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              /// presets enabled toggle
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(
                  "Presets Enabled:",
                  style: textStyle.copyWith(fontWeight: FontWeight.bold),
                ),
                BlocBuilder<Hephaestus, Toolbox>(builder: (_, t) {
                  return Switch(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    value: t.presetsEnabled,
                    onChanged: (enabled) async {
                      _setPreset(enabled);
                      BlocProvider.of<Hephaestus>(context)
                          .updatePresetsEnabled(enabled);
                    },
                  );
                }),
              ]),

              /// separator
              Divider(color: dividerColor),

              /// title text
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                BlocBuilder<Hermes, Preset>(
                  buildWhen: (prev, curr) =>
                      prev.name != curr.name ||
                      prev.isDefault != curr.isDefault,
                  builder: (context, preset) {
                    if (preset.isDefault) {
                      _nameController.text = "";
                    } else if (_oldPresetKey != preset.key ||
                        _nameController.text.isEmpty) {
                      _nameController.text = preset.name;
                    }
                    return Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              focusNode: _nameFocusNode,
                              enabled: preset.isDefault ? false : true,
                              maxLength: ChronosConstants.maxNameLength,
                              readOnly: preset.isDefault,
                              style: textStyle,
                              textAlign: TextAlign.start,
                              controller: _nameController,
                              inputFormatters: [
                                FilteringTextInputFormatter.singleLineFormatter,
                              ],
                              // onSubmitted:: _saveName,
                              decoration: InputDecoration(
                                hintStyle: textStyle,
                                hintText: preset.isDefault
                                    ? "Default Preset"
                                    : "new preset",
                              ),
                            ),
                          ),
                          // default preset cannot be deleted
                          if (!preset.isDefault)
                            IconButton(
                              onPressed: () async {
                                await BlocProvider.of<Hermes>(context)
                                    .deletePreset(preset);
                                _onPresetDeleted(enabledAfter: true);
                              },
                              icon: Icon(
                                Icons.delete_forever,
                                color: settings.color2,
                              ),
                            )
                        ],
                      ),
                    );
                  },
                ),
              ]),

              /// edit bpm
              Row(children: [
                BlocBuilder<Hermes, Preset>(
                  buildWhen: (prev, curr) => prev.bpm != curr.bpm,
                  builder: (_, preset) {
                    if (_oldPresetKey != preset.key ||
                        _bpmController.text.isEmpty) {
                      _bpmController.text = preset.bpm.toString();
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
                        BlocBuilder<Hermes, Preset>(
                          buildWhen: (prev, curr) =>
                              prev.beatsPerBar != curr.beatsPerBar,
                          builder: (_, preset) {
                            if (_oldPresetKey != preset.key ||
                                _beatsPerBarController.text.isEmpty) {
                              _beatsPerBarController.text =
                                  preset.beatsPerBar.toString();
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
                        BlocBuilder<Hermes, Preset>(
                          buildWhen: (prev, curr) =>
                              prev.barNote != curr.barNote,
                          builder: (_, preset) {
                            if (_oldPresetKey != preset.key ||
                                _barNoteController.text.isEmpty) {
                              _barNoteController.text =
                                  preset.barNote.toString();
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
              Expanded(
                child: BlocBuilder<Hermes, Preset>(
                  buildWhen: (prev, curr) => prev.notes != curr.notes,
                  builder: (_, preset) {
                    if (_oldPresetKey != preset.key ||
                        _notesController.text.isEmpty) {
                      _notesController.text = preset.notes;
                    }
                    return TextField(
                      focusNode: _notesFocusNode,
                      maxLines: null,
                      style: textStyle,
                      textAlign: TextAlign.start,
                      controller: _notesController,
                      keyboardType: TextInputType.multiline,
                      onChanged: (str) {
                        // enable save notes button if changes detected
                        if (preset.notes != str) {
                          _saveNotesButtonController.enable();
                        } else {
                          _saveNotesButtonController.disable();
                          _saveNotesButtonController.hide();
                        }
                      },
                      decoration: InputDecoration(
                        hintStyle: textStyle,
                        hintText: "edit notes",
                      ),
                    );
                  },
                ),
              ),
              SaveNotesButton(
                controller: _saveNotesButtonController,
                onPressed: _saveNotes,
                initiallyEnabled: false,
                initiallyHidden: true,
              ),
              // if bottom peeking, add spacing to show all notes
              if (settings.presetsEnabled)
                const SizedBox(
                  height: kBottomNavigationBarHeight,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// for notifying widget when to change icon and its action (expand or hide)
class SliderHeaderController {
  SliderHeaderController();
  void Function()? _notifyExpanded;
  void Function()? _notifyPeeking;

  void notifyExpanded() {
    _notifyExpanded?.call();
  }

  void notifyPeeking() {
    _notifyPeeking?.call();
  }
}

/// in charge of creating interface for preset list, and allowing its manipulation
/// allows:
/// - deletion of preset
/// - selection of preset
/// also:
/// - notifies Mnemosyne of changes
class SliderHeader extends StatefulWidget {
  const SliderHeader({
    Key? key,
    required this.state,
    required this.action,
    required this.newPreset,
    required this.controller,
  }) : super(key: key);

  final _HeaderState state;
  final void Function() action;
  final void Function() newPreset;
  final SliderHeaderController controller;

  @override
  State<StatefulWidget> createState() {
    return _SliderHeaderState();
  }
}

enum _HeaderState { peeking, expanded }

class _SliderHeaderState extends State<SliderHeader> {
  late _HeaderState state;

  @override
  void initState() {
    super.initState();
    state = widget.state;
    widget.controller._notifyExpanded = () {
      setState(() {
        state = _HeaderState.expanded;
      });
    };
    widget.controller._notifyPeeking = () {
      setState(() {
        state = _HeaderState.peeking;
      });
    };
  }

  @override
  void didUpdateWidget(SliderHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.controller._notifyExpanded = () {
      setState(() {
        state = _HeaderState.expanded;
      });
    };
    widget.controller._notifyPeeking = () {
      setState(() {
        state = _HeaderState.peeking;
      });
    };
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // padding: const EdgeInsets.only(right: 16),
      width: double.infinity,
      height: kBottomNavigationBarHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: Icon(
                state == _HeaderState.peeking
                    ? Icons.keyboard_arrow_up
                    : Icons.close,
              ),
              onPressed: widget.action,
            ),
          ),
          const Expanded(
            child: Text(
              "Select Preset",
              textAlign: TextAlign.start,
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.fromLTRB(2, 8, 8, 8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.add),
                SizedBox(width: 8),
                Text("new preset"),
              ],
            ),
            onPressed: widget.newPreset,
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}

class SaveNotesButtonController {
  SaveNotesButtonController();
  void Function()? _enable;
  void Function()? _disable;
  void Function()? _show;
  void Function()? _hide;

  void enable() {
    _enable?.call();
  }

  void disable() {
    _disable?.call();
  }

  void show() {
    _show?.call();
  }

  void hide() {
    _hide?.call();
  }
}

class SaveNotesButton extends StatefulWidget {
  const SaveNotesButton({
    Key? key,
    required this.controller,
    required this.onPressed,
    this.initiallyEnabled = true,
    this.initiallyHidden = true,
  }) : super(key: key);
  final SaveNotesButtonController controller;
  final void Function() onPressed;
  final bool initiallyEnabled;
  final bool initiallyHidden;

  @override
  State<StatefulWidget> createState() => _SaveNotesButtonState();
}

class _SaveNotesButtonState extends State<SaveNotesButton> {
  late bool _enabled;
  late bool _hidden;

  @override
  void initState() {
    super.initState();
    _enabled = widget.initiallyEnabled;
    _hidden = widget.initiallyHidden;
    widget.controller._enable = () {
      setState(() {
        _hidden = false;
        _enabled = true;
      });
    };
    widget.controller._disable = () {
      setState(() {
        _hidden = false;
        _enabled = false;
      });
    };
    widget.controller._hide = () {
      setState(() {
        _hidden = true;
      });
    };
  }

  @override
  void didUpdateWidget(covariant SaveNotesButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.controller._enable = () {
      setState(() {
        _hidden = false;
        _enabled = true;
      });
    };
    widget.controller._disable = () {
      setState(() {
        _hidden = false;
        _enabled = false;
      });
    };
    widget.controller._hide = () {
      setState(() {
        _hidden = true;
      });
    };
  }

  @override
  Widget build(BuildContext context) {
    return _hidden
        ? const SizedBox(width: 0, height: 0)
        : ElevatedButton(
            onPressed: _enabled ? widget.onPressed : null,
            child: const Text("save notes"),
          );
  }
}
