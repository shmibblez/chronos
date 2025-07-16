// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'dart:developer';

import 'package:chronos/chronos_constants.dart';
import 'package:chronos/cubits/mnemosyne.dart';
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
            other.barNote == barNote &&
            other.notes == notes
        // && other.millis == millis // !!! NOTE !!! millis not tested since not shown in ui
        ;
  }

  @override
  int get hashCode => "$key|$name|$bpm|$beatsPerBar|$barNote|$notes".hashCode;

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

  /// decodes preset from JSON in db
  static Preset fromJSON(
    String key,
    dynamic json, {
    String? name,
    int? bpm,
    int? beatsPerBar,
    int? barNote,
    int? millis,
    String? notes,
  }) {
    var sigSegments = (json["sig"] as String)
        .split(RegExp(r'[|/]'))
        .map((e) => int.parse(e))
        .toList();
    return Preset(
      key: key,
      name: name ?? json["name"],
      bpm: bpm ?? sigSegments[0],
      beatsPerBar: beatsPerBar ?? sigSegments[1],
      barNote: barNote ?? sigSegments[2],
      millis: millis ?? json["millis"],
      notes: notes ?? json["notes"],
    );
  }

  /// converts preset to JSON for db storage
  static Map toJSON(Preset p) {
    return {
      "name": p.name,
      "sig": p.sig(),
      "millis": p.millis,
      "notes": p.notes,
    };
  }

  /// formats time signature into value stored in map
  String sig() {
    return "$bpm|$beatsPerBar/$barNote";
  }

  static Map newPresetJSON() => {
        "name": "",
        "sig": "${ChronosConstants.defaultBPM}|4/4",
        "millis": DateTime.now().millisecondsSinceEpoch,
        "notes": "",
      };
}

/// [Hermes] transports presets between Mnemosyne and widgets
class Hermes extends Cubit<Preset?> {
  Hermes(Preset super.initialState);

  /// !! does not emit change (millis not shown in UI) !!
  ///
  /// tells Mnemosyne to update millis
  Future<void> selectPreset(Preset p, int millis) async {
    await Mnemosyne().updatePreset(
      p,
      millis: millis,
    );
    emit(Preset.from(p, millis: millis));
  }

  /// tells Mnemosyne to delete preset from db
  Future<void> deletePreset(Preset preset) async {
    await Mnemosyne().deletePreset(preset);
  }

  // update name, notify Mnemosyne
  Future<void> updateName(String name) async {
    final Preset? preset = state;
    if (preset == null) return;
    String validated = Preset.validateName(name);
    if (validated == preset.name) return;
    var f = Mnemosyne().updatePreset(preset, name: validated);
    emit(Preset.from(preset, name: validated));
    await f;
  }

  /// update bpm by amount, notify Mnemosyne
  Future<void> updateBPMby(int bpm) async {
    final Preset? preset = state;
    if (preset == null) return;
    if (bpm == 0) return;
    await updateBPM(preset.bpm + bpm);
  }

  /// update bpm, notify Mnemosyne
  Future<void> updateBPM(int bpm) async {
    final Preset? preset = state;
    if (preset == null) return;
    int validated = Preset.validateBPM(bpm);
    if (validated == preset.bpm) return;
    var f = Mnemosyne().updatePreset(preset, bpm: bpm);
    emit(Preset.from(preset, bpm: validated));
    await f;
  }

  /// update bpm by amount, notify Mnemosyne
  void updateBPMbyThrottled(int bpm) {
    final Preset? preset = state;
    if (preset == null) return;
    if (bpm == 0) return;
    updateBPMThrottled(bpm + preset.bpm);
  }

  /// update bpm periodically, notify Mnemosyne
  void updateBPMThrottled(int bpm) {
    final Preset? preset = state;
    if (preset == null) return;
    int validated = Preset.validateBPM(bpm);
    if (validated == preset.bpm) return;
    Mnemosyne().updateBPMThrottled(validated, preset);
    emit(Preset.from(preset, bpm: validated));
  }

  /// update beats per barNote, notify Mnemosyne
  Future<void> updateBeatsPerBar(int beats) async {
    final Preset? preset = state;
    if (preset == null) return;
    int validated = Preset.validateBeatsPerBar(beats);
    if (validated == preset.beatsPerBar) return;
    var f = Mnemosyne().updatePreset(preset, beatsPerBar: validated);
    emit(Preset.from(preset, beatsPerBar: validated));
    await f;
  }

  /// update barNote, notify Mnemosyne
  Future<void> updateBarNote(int barNote) async {
    final Preset? preset = state;
    if (preset == null) return;
    int validated = Preset.validateBarNote(barNote);
    if (barNote == preset.barNote) return;
    var f = Mnemosyne().updatePreset(preset, barNote: validated);
    emit(Preset.from(preset, barNote: validated));
    await f;
  }

  /// update user's notes, notify Mnemosyne
  Future<void> updateNotes(String notes) async {
    final Preset? preset = state;
    if (preset == null) return;
    String validated = Preset.validateNotes(notes);
    if (validated == preset.notes) return;
    var f = Mnemosyne().updatePreset(preset, notes: validated);
    emit(Preset.from(preset, notes: validated));
    await f;
  }

  /// load last used preset and set as current
  /// if no last preset exists, create and load new one
  Future<Preset> loadLastPreset() async {
    Preset p = await Mnemosyne().lastPreset();
    log("last preset: $p");
    // if no preset exists create new one
    // p ??= await Mnemosyne().newPreset();
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
    super.key,
    required this.onAddPreset,
    required this.onDelete,
    required this.onSelectPreset,
  });

  final void Function() onAddPreset;
  final void Function(Preset) onDelete;
  final void Function() onSelectPreset;

  @override
  State<StatefulWidget> createState() => _PresetListState();
}

class _PresetListState extends State<PresetList> {
  late bool _noMore;
  late bool _loading;
  late StreamSubscription<Preset?> _presetStream;

  List<Preset> get _presets => Mnemosyne().presets;

  @override
  void initState() {
    super.initState();
    _noMore = false;
    _loading = false;
    _presetStream = BlocProvider.of<Hermes>(context).stream.listen((event) {
      setState(() {
        // updates Mnemosyne list
      });
    });
    log("PresetList.initState, presets size: ${_presets.length} _presets: $_presets");
    // _presetStream = BlocProvider.of<Hermes>(context).stream.listen((event) {
    //   // index of updated preset
    //   int i = _presets.indexWhere((element) => element.key == event.key);
    //   if (i < 0) {
    //     if (event.isDefault) return;
    //     setState(() {
    //       _presets.insert(0, event);
    //     });
    //   } else {
    //     setState(() {
    //       _presets.replaceRange(i, i + 1, [event]);
    //     });
    //   }
    // });
  }

  @override
  void dispose() {
    _presetStream.cancel();
    super.dispose();
  }

  Widget _AddPresetButton() {
    return OutlinedButton(
      onPressed: widget.onAddPreset,
      child: Text(
        "add new preset",
        style: ChronosConstants.normalTextStyle,
      ),
    );
  }

  Widget _Preset(Preset preset) {
    return ListTile(
      contentPadding: EdgeInsets.all(0),
      title: Text(
        preset.name.isEmpty ? "(unnamed preset)" : preset.name,
        style: ChronosConstants.normalTextStyle,
        maxLines: 1,
      ),
      subtitle: Text(
        "bpm: ${preset.bpm}, time sig: ${preset.beatsPerBar} / ${preset.barNote}",
        style: ChronosConstants.secondarySmallTextStyle,
        maxLines: 1,
      ),
      onTap: () {
        _presetSelected(context, preset);
      },
      trailing: IconButton(
        icon: const Icon(
          Icons.delete_rounded,
          color: Colors.white,
        ),
        onPressed: () {
          // #10
          _presetDeleted(context, preset);
        },
      ),
    );
  }

  Widget _LoadingItem() {
    return SizedBox(
      width: double.maxFinite,
      child: const Text(
        "loading...",
        style: ChronosConstants.secondarySmallTextStyle,
        textAlign: TextAlign.center,
      ),
    );
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
    // final screenW = MediaQuery.of(context).size.width;
    // final w = min((screenW * (2 / 3)).truncate().toDouble(), 304.0);
    // rebuild when relevant app settings change
    final w = MediaQuery.of(context).size.width * 4 / 5;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.black.withAlpha((255.0 * 0.75).toInt()),
      height: double.infinity,
      width: w,
      alignment: AlignmentDirectional.topStart,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        primary: false,
        // controller: widget.controller,
        // first item is add preset item
        itemCount: 1 + _presets.length + 1,
        itemBuilder: (_, i) {
          if (i == 0) {
            /// first item is add new preset option
            return _AddPresetButton();
          } else if (i - 1 >= _presets.length) {
            /// loading item

            // if already attempted load and no more items, return
            if (_noMore) return null;
            // if at end of list then loading item
            _loadPresets(context);
            return _LoadingItem();
          }

          /// else show preset
          return _Preset(_presets[i - 1]);
        },
      ),
    );
  }

  void _loadPresets(BuildContext context) async {
    if (_loading) return;
    _loading = true;
    final prevLength = _presets.length;
    await Mnemosyne().loadPresets();
    final newLength = _presets.length;
    // also updates list shown
    setState(() {
      if (prevLength == newLength) _noMore = true;
      _loading = false;
    });
  }

  void _presetSelected(BuildContext context, Preset p) async {
    // Hermes tells Mnemosyne and she updates list
    // must complete before setting state
    log("preset selected, title: ${p.name}, key: ${p.key}");
    await BlocProvider.of<Hermes>(context).selectPreset(
      p,
      DateTime.now().millisecondsSinceEpoch,
    );
    // also updates list shown
    setState(() {
      // updates list
    });
    widget.onSelectPreset();
  }

  void _presetDeleted(BuildContext context, Preset p) async {
    // Preset p = _presets.removeAt(i);
    log("preset deleted, title: ${p.name}, key: ${p.key}");
    await BlocProvider.of<Hermes>(context).deletePreset(p);
    // also updates list shown
    setState(() {
      // does ui stuff
      widget.onDelete(p);
    });
  }
}
