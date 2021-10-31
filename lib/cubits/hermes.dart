import 'package:chronos/cubits/mnemosyne.dart';
import 'package:chronos/main.dart';
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

  Preset.from(Preset old,
      {String? key,
      String? name,
      int? bpm,
      int? beatsPerBar,
      int? barNote,
      int? millis,
      String? notes})
      : key = key ?? old.key,
        name = name ?? old.name,
        bpm = bpm ?? old.bpm,
        beatsPerBar = beatsPerBar ?? old.beatsPerBar,
        barNote = barNote ?? old.barNote,
        millis = millis ?? old.millis,
        notes = notes ?? old.notes;

  @override
  bool operator ==(Object other) {
    return other is Preset && other.key == key;
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
    var segments = (json["sig"] as String)
        .split(RegExp(r'[|/]'))
        .map((e) => int.parse(e))
        .toList();
    return Preset(
      key: key,
      name: json["name"],
      bpm: segments[0],
      beatsPerBar: segments[1],
      barNote: segments[2],
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

  void updateName(String name) {
    String validated = Preset.validateName(name);
    if (validated == state.name) return;
    emit(Preset.from(state, name: validated));
  }

  /// update bpm
  void updateBPMby(int bpm) {
    updateBPM(state.bpm + bpm);
  }

  void updateBPM(int bpm) {
    int validated = Preset.validateBPM(bpm);
    if (validated == state.bpm) return;
    emit(Preset.from(state, bpm: validated));
  }

  /// update beats per barNote
  void updateBeatsPerBar(int beats) {
    int validated = Preset.validateBeatsPerBar(beats);
    if (validated == state.beatsPerBar) return;
    emit(Preset.from(state, beatsPerBar: validated));
  }

  /// update barNote
  void updateBarNote(int barNote) {
    int validated = Preset.validateBarNote(barNote);
    if (barNote == state.barNote) return;
    emit(Preset.from(state, barNote: validated));
  }

  void updateNotes(String notes) {
    String validated = Preset.validateNotes(notes);
    if (validated == state.notes) return;
    emit(Preset.from(state, notes: validated));
  }

  Future<Preset> loadDefault() async {
    Preset p = await Mnemosyne().defaultPreset();
    emit(p);
    return p;
  }

  Future<Preset> loadLastPreset() async {
    Preset? p = await Mnemosyne().lastPreset(includeDefault: false);

    p ??= await Mnemosyne().newPreset();

    emit(p);
    return p;
  }
}
