import 'package:chronos/convenience_widgets.dart';
import 'package:chronos/cubits/hephaestus.dart';
import 'package:chronos/cubits/hermes.dart';
import 'package:chronos/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sliding_sheet/sliding_sheet.dart';
import 'dart:math' show min;

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
  late SheetController _sc;
  late SliderHeaderController _hc;

  @override
  void initState() {
    super.initState();
    _sc = SheetController();
    _hc = SliderHeaderController();
  }

  @override
  Widget build(BuildContext context) {
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
      child: Stack(children: [
        BlocBuilder<Hephaestus, Toolbox>(
          // rebuild whole tree only if any colors change
          buildWhen: (ps, cs) =>
              ps.color1 != cs.color1 || ps.color2 != cs.color2,
          builder: (_, settings) {
            // drawer background color is lighter than metronome disabled color
            final Color backgroundColor = settings.color1l;
            final Color textColor =
                settings.visibleTextColor(backgroundColor, settings.color2);
            final Color dividerColor = settings.color2d;
            final TextStyle textStyle = TextStyle(color: textColor);
            return SizedBox(
              width: w,
              child: Drawer(
                backgroundColor: backgroundColor,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: DefaultTextStyle(
                    style: textStyle,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ///
                        ///
                        /// FIXME: left off here:
                        /// - add stream where actively awaited preset is loaded to hermes (below functions). If switch changed while loading, cancel active stream and load new one
                        ///   - syncs loaded preset with user selection (preset enabled or disabled) and prevents futures completed and switch changed
                        /// - also if possible cache values so loads instantly (need to update cache accordingly though, notify Mnemosyne every time preset is updated)
                        /// - add pending updates list to Mnemosyne, or to Hermes who then notifies Mnemosyne who updates instantly
                        ///   - on first update, set timer to commit updates, and from then until timer goes off, more futures can be added or removed
                        ///   - this prevents updating too quickly, at least in the case of bpm updates
                        ///   - if Hermes stores list, could be map of id: {changed fields}, which is then passed on to Mnemosyne who updates db and caches
                        ///
                        ///

                        /// presets enabled toggle
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Presets Enabled:",
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              BlocBuilder<Hephaestus, Toolbox>(builder: (_, t) {
                                return Switch(
                                    value: t.presetsEnabled,
                                    onChanged: (enabled) async {
                                      if (enabled) {
                                        _expand();
                                        BlocProvider.of<Hermes>(context)
                                            .loadLastPreset();
                                      } else if (!enabled) {
                                        BlocProvider.of<Hermes>(context)
                                            .loadDefault();
                                        _hide();
                                      }
                                      BlocProvider.of<Hephaestus>(context)
                                          .updatePresetsEnabled(enabled);
                                    });
                              }),
                            ]),
                        // bottom spacing
                        const SizedBox(height: 8),

                        /// separator
                        Divider(color: dividerColor),

                        /// title text
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              BlocBuilder<Hermes, Preset>(
                                buildWhen: (prev, curr) =>
                                    prev.name != curr.name ||
                                    prev.isDefault != curr.isDefault,
                                builder: (context, preset) {
                                  final TextEditingController _nameController =
                                      TextEditingController(
                                          text: preset.isDefault
                                              ? "Default Preset"
                                              : preset.name);
                                  return Expanded(
                                    child: TextField(
                                      maxLength: ChronosConstants.maxNameLength,
                                      readOnly: preset.isDefault,
                                      style: textStyle,
                                      textAlign: TextAlign.start,
                                      controller: _nameController,
                                      inputFormatters: [
                                        FilteringTextInputFormatter
                                            .singleLineFormatter,
                                      ],
                                      onSubmitted: (str) {
                                        BlocProvider.of<Hermes>(context)
                                            .updateName(str);
                                        _nameController.text =
                                            Preset.validateName(str);
                                      },
                                      decoration: InputDecoration(
                                          hintStyle: textStyle,
                                          hintText: preset.name.isEmpty
                                              ? "change preset name"
                                              : null),
                                    ),
                                  );
                                },
                              ),
                            ]),

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
                                              controller:
                                                  _beatsPerBarController,
                                              keyboardType:
                                                  TextInputType.number,
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
                                              keyboardType:
                                                  TextInputType.number,
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

                        /// edit notess, also works in default mode
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
                                  "This is the notes section, you can write down stuff like bpm goal, song section, or anything else that's useful for your practice session.",
                            ),
                          ],
                        ),
                        Expanded(
                          child: BlocBuilder<Hermes, Preset>(
                            buildWhen: (prev, curr) => prev.notes != curr.notes,
                            builder: (_, preset) {
                              final TextEditingController _notesController =
                                  TextEditingController(text: preset.notes);
                              return TextField(
                                maxLines: null,
                                style: textStyle,
                                textAlign: TextAlign.start,
                                controller: _notesController,
                                keyboardType: TextInputType.multiline,
                                onSubmitted: (str) {
                                  BlocProvider.of<Hermes>(context)
                                      .updateNotes(str);
                                  _notesController.text =
                                      Preset.validateNotes(str).toString();
                                },
                                decoration: InputDecoration(
                                    hintStyle: textStyle,
                                    hintText: preset.notes.isEmpty
                                        ? "edit notes"
                                        : null),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        SizedBox(
          width: w,
          child: SlidingSheet(
            controller: _sc,
            minHeight: MediaQuery.of(context).size.height,
            duration: const Duration(milliseconds: 300),
            snapSpec: const SnapSpec(
              initialSnap: 0,
              snappings: [SnapSpec.headerSnap, 1],
              positioning: SnapPositioning.relativeToAvailableSpace,
            ),
            listener: (state) {
              if (state.isExpanded) {
                _hc.notifyExpanded();
              } else {
                _hc.notifyPeeking();
              }
            },
            headerBuilder: (_, state) => SliderHeader(
              state: _HeaderState.peeking,
              action: _onClickPanelHeader,
              controller: _hc,
            ),
            customBuilder: (_, scrollController, state) => ListView.builder(
              itemCount: 40,
              controller: scrollController,
              scrollDirection: Axis.vertical,
              itemBuilder: (_, i) {
                return ListTile(
                  title: Text("$i"),
                  onTap: _hide,
                );
              },
            ),
          ),
        ),
      ]),
    );
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
      _hide();
      BlocProvider.of<Hephaestus>(context).updatePresetsEnabled(false);
    }
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

class SliderHeader extends StatefulWidget {
  const SliderHeader({
    Key? key,
    required this.state,
    required this.action,
    required this.controller,
  }) : super(key: key);

  final _HeaderState state;
  final void Function() action;
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
    return Container(
      color: _HeaderState.peeking == state ? Colors.red : Colors.blue,
      padding: const EdgeInsets.only(right: 16),
      width: double.infinity,
      height: kBottomNavigationBarHeight,
      child: Row(
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
          Text(
            state == _HeaderState.peeking ? "Show Presets" : "Choose Preset",
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
