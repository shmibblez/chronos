import 'dart:async';

import 'package:chronos/cubits/mnemosyne.dart';
import 'package:chronos/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class Preset {
  Preset({
    required this.key,
    required String name,
    required int bpm,
    required int beatsPerBar,
    required int barNote,
    required this.millis,
    required String notes,
  })  : name = validateName(name),
        bpm = validateBPM(bpm),
        beatsPerBar = validateBeatsPerBar(beatsPerBar),
        barNote = validateBarNote(barNote),
        notes = validateNotes(notes);

  Preset.from(
    Preset old, {
    String? key,
    String? name,
    int? bpm,
    int? beatsPerBar,
    int? barNote,
    int? millis,
    String? notes,
  })  : key = key ?? old.key,
        name = name ?? old.name,
        bpm = bpm ?? old.bpm,
        beatsPerBar = beatsPerBar ?? old.beatsPerBar,
        barNote = barNote ?? old.barNote,
        millis = millis ?? old.millis,
        notes = notes ?? old.notes;

  @override
  bool operator ==(Object other) {
    return other is Preset &&
            other.key == key &&
            other.name == name &&
            other.bpm == bpm &&
            other.beatsPerBar == beatsPerBar &&
            other.barNote == barNote
        // && other.millis == millis // !!! NOTE !!! millis not tested since not shown in ui
        ;
  }

  @override
  int get hashCode => key.hashCode;

  final String key;
  final String name;
  final int bpm;
  final int beatsPerBar;
  final int barNote;
  final int millis;
  final String notes;

  static String validateName(String name) {
    if (name.length > ChronosConstants.maxNameLength) {
      return name.substring(0, ChronosConstants.maxNameLength);
    } else if (name.length < ChronosConstants.minNameLength) {
      return "";
    }
    return name;
  }

  static int validateBPM(int bpm) {
    if (bpm > ChronosConstants.maxBPM) {
      return ChronosConstants.maxBPM;
    } else if (bpm < ChronosConstants.minBPM) {
      return ChronosConstants.minBPM;
    }
    return bpm;
  }

  static int validateBeatsPerBar(int beats) {
    if (beats > ChronosConstants.maxBeatsPerBar) {
      return ChronosConstants.maxBeatsPerBar;
    } else if (beats < ChronosConstants.minBeatsPerBar) {
      return ChronosConstants.minBeatsPerBar;
    }
    return beats;
  }

  static int validateBarNote(int barNote) {
    if (barNote <= 0) return 1;
    return barNote;
  }

  static String validateNotes(String notes) {
    if (notes.length > ChronosConstants.maxNotesLength) {
      return notes.substring(0, ChronosConstants.maxNotesLength);
    } else if (notes.length < ChronosConstants.minNotesLength) {
      return "";
    }
    return notes;
  }

  /// beat period in millis
  Duration get beatPeriod => Duration(milliseconds: (60000 / bpm).truncate());
  bool get isDefault => name == "default";

  /// decodes preset from JSON in db
  static Preset fromJSON(String key, dynamic json) {
    var sigSegments = (json["sig"] as String)
        .split(RegExp(r'[|/]'))
        .map((e) => int.parse(e))
        .toList();
    return Preset(
      key: key,
      name: json["name"],
      bpm: sigSegments[0],
      beatsPerBar: sigSegments[1],
      barNote: sigSegments[2],
      millis: json["millis"],
      notes: json["notes"],
    );
  }

  /// converts preset to JSON for db storage
  static Map toJSON(Preset p) {
    return {
      "name": p.name,
      "sig": "${p.bpm}|${p.beatsPerBar}/${p.barNote}",
      "millis": p.millis,
      "notes": p.notes,
    };
  }

  static final Map newPresetJSON = {
    "name": "",
    "sig": "100|4/4",
    "millis": DateTime.now().millisecondsSinceEpoch,
    "notes": "",
  };
}

/// [Hermes] transports presets between Mnemosyne and widgets
class Hermes extends Cubit<Preset> {
  Hermes(Preset initialState) : super(initialState);

  /// !! does not emit change (millis not shown in UI) !!
  ///
  /// tells Mnemosyne to update millis
  Future<void> selectPreset(Preset p, int millis) async {
    var f = Mnemosyne().updatePreset(
      state,
      millis: millis,
    );
    emit(Preset.from(p, millis: millis));
    await f;
  }

  /// tells Mnemosyne to delete preset from db
  Future<void> deletePreset(Preset preset) async {
    await Mnemosyne().deletePreset(preset);
  }

  // update name, notify Mnemosyne
  Future<void> updateName(String name) async {
    String validated = Preset.validateName(name);
    if (validated == state.name) return;
    var f = Mnemosyne().updatePreset(state, name: name);
    emit(Preset.from(state, name: validated));
    await f;
  }

  /// update bpm by amount, notify Mnemosyne
  Future<void> updateBPMby(int bpm) async {
    if (bpm == 0) return;
    await updateBPM(state.bpm + bpm);
  }

  /// FIXME: throttle updates since too quick when slide-setting bpm
  /// Mnemosyne can store bpm value, and set future in 2 seconds to update
  ///   if future set, only set value
  ///   if future not set, set future and when complete, update bpm in db and close & set future to null
  ///
  /// update bpm, notify Mnemosyne
  Future<void> updateBPM(int bpm) async {
    int validated = Preset.validateBPM(bpm);
    if (validated == state.bpm) return;
    // var f = Mnemosyne().updatePreset(state,bpm:bpm);
    emit(Preset.from(state, bpm: validated));
    // await f;
  }

  /// update beats per barNote, notify Mnemosyne
  Future<void> updateBeatsPerBar(int beats) async {
    int validated = Preset.validateBeatsPerBar(beats);
    debugPrint("-beatsPerBar: $beats, validated: $validated");
    if (validated == state.beatsPerBar) return;
    var f = Mnemosyne().updatePreset(state, beatsPerBar: beats);
    emit(Preset.from(state, beatsPerBar: validated));
    await f;
  }

  /// update barNote, notify Mnemosyne
  Future<void> updateBarNote(int barNote) async {
    int validated = Preset.validateBarNote(barNote);
    debugPrint("-barNotes: $barNote, validated: $validated");
    if (barNote == state.barNote) return;
    var f = Mnemosyne().updatePreset(state, barNote: barNote);
    emit(Preset.from(state, barNote: validated));
    await f;
  }

  /// update user's notes, notify Mnemosyne
  Future<void> updateNotes(String notes) async {
    String validated = Preset.validateNotes(notes);
    if (validated == state.notes) return;
    var f = Mnemosyne().updatePreset(state, notes: notes);
    emit(Preset.from(state, notes: validated));
    await f;
  }

  /// load default preset and set as current
  Future<Preset> loadDefault() async {
    Preset p = await Mnemosyne().defaultPreset();
    emit(p);
    return p;
  }

  /// load last used preset and set as current
  /// if no last preset exists, create and load new one
  Future<Preset> loadLastPreset() async {
    Preset? p = await Mnemosyne().lastPreset(includeDefault: false);
    // if no preset exists create new one
    p ??= await Mnemosyne().newPreset();
    emit(p);
    return p;
  }

  /// creates new preset and loads it
  Future<Preset> loadNewPreset() async {
    Preset p = await Mnemosyne().newPreset();
    emit(p);
    return p;
  }
}

class PresetList extends StatefulWidget {
  const PresetList({
    Key? key,
    required this.action,
    required this.delete,
    this.controller,
  }) : super(key: key);
  final void Function(Preset) action;
  final void Function(Preset) delete;
  final ScrollController? controller;

  @override
  State<StatefulWidget> createState() => _PresetListState();
}

class _PresetListState extends State<PresetList> {
  late List<Preset> _presets;
  late bool _noMore;
  late bool _loading;
  late StreamSubscription<Preset> _presetStream;

  @override
  void initState() {
    super.initState();
    _presets = [];
    _noMore = false;
    _loading = false;
    _presetStream = BlocProvider.of<Hermes>(context).stream.listen((event) {
      // index of updated preset
      int i = _presets.indexWhere((element) => element.key == event.key);
      if (i < 0) {
        if (event.isDefault) return;
        setState(() {
          _presets.insert(0, event);
        });
        return;
      }
      setState(() {
        _presets.replaceRange(i, i + 1, [event]);
        debugPrint("replaced ${event.name}");
      });
    });
  }

  @override
  void dispose() {
    _presetStream.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        primary: false,
        controller: widget.controller,
        itemCount: _presets.length + 1,
        itemBuilder: (_, i) {
          if (i >= _presets.length) {
            if (_noMore) {
              if (_presets.isEmpty) {
                return Container(
                  child: const Text("no presets found",
                      textAlign: TextAlign.center),
                  padding: const EdgeInsets.all(16),
                );
              }
              return Container(
                child: const Text("end of list", textAlign: TextAlign.center),
                padding: const EdgeInsets.all(16),
              );
            }
            // load some presets if at end of list
            _loadPresets(context);
            return Container(
              child: const Text("loading...", textAlign: TextAlign.center),
              padding: const EdgeInsets.all(16),
            );
          }
          String title = _presets[i].name;
          return ListTile(
            title: Text(title.isEmpty ? "new preset" : title),
            subtitle: Text("key: ${_presets[i].key}, bpm ${_presets[i].bpm}"),
            onTap: () {
              _presetSelected(context, i);
            },
            trailing: IconButton(
              icon: const Icon(Icons.delete_forever),
              onPressed: () {
                _presetDeleted(context, i);
              },
            ),
          );
        },
      ),
    );
  }

  void _loadPresets(BuildContext context) async {
    if (_loading) return;
    _loading = true;
    var newPresets = await Mnemosyne().loadPresets(
      offset: _presets.length,
      exclude: BlocProvider.of<Hermes>(context).state,
    );
    setState(() {
      if (newPresets.isEmpty) {
        _noMore = true;
      } else {
        _presets.addAll(newPresets);
      }
      _loading = false;
    });
  }

  void _presetSelected(BuildContext context, int i) {
    setState(() {
      Preset p = _presets.removeAt(i);
      _presets.insert(0, p); // updates preset selected
      widget.action(p);
    });
  }

  void _presetDeleted(BuildContext contrxt, int i) {
    setState(() {
      Preset p = _presets.removeAt(i);
      // deletes preset
      widget.delete(p);
    });
  }
}
