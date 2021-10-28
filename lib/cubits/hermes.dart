import 'package:chronos/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class Preset {
  Preset({
    required this.name,
    required int bpm,
    required int beatsPerBar,
    required this.barNote,
    required this.millis,
  })  : bpm = _validateBPM(bpm),
        beatsPerBar = _validateBeatsPerBar(beatsPerBar);

  Preset.from(Preset old,
      {String? name, int? bpm, int? beatsPerBar, int? barNote, int? millis})
      : name = name ?? old.name,
        bpm = bpm ?? old.bpm,
        beatsPerBar = beatsPerBar ?? old.beatsPerBar,
        barNote = barNote ?? old.barNote,
        millis = millis ?? old.millis;

  final String name;
  final int bpm;
  final int beatsPerBar;
  final int barNote;
  final int millis;

  static int _validateBPM(int bpm) {
    if (bpm > ChronosConstants.maxBPM) {
      return ChronosConstants.maxBPM;
    } else if (bpm < ChronosConstants.minBPM) {
      return ChronosConstants.minBPM;
    }
    return bpm;
  }

  static int _validateBeatsPerBar(int beats) {
    if (beats > ChronosConstants.maxBeatsPerBar) {
      return ChronosConstants.maxBeatsPerBar;
    } else if (beats < ChronosConstants.minBeatsPerBar) {
      return ChronosConstants.minBeatsPerBar;
    }
    return beats;
  }

  static int _validateBarNote(int barNote) {
    if (barNote <= 0) return 1;
    return barNote;
  }

  /// beat period in millis
  Duration get beatPeriod => Duration(milliseconds: (60000 / bpm).truncate());

  /// decodes preset from JSON in db
  static Preset fromJSON(dynamic json) {
    var segments = (json["sig"] as String)
        .split(RegExp(r'[|/]'))
        .map((e) => int.parse(e))
        .toList();
    return Preset(
      name: json["name"],
      bpm: segments[0],
      beatsPerBar: segments[1],
      barNote: segments[2],
      millis: json["millis"],
    );
  }

  /// converts preset to JSON for db storage
  static Map toJSON(Preset p) {
    return {
      "name": p.name,
      "sig": "${p.bpm}|${p.beatsPerBar}/${p.barNote}",
      "millis": p.millis,
    };
  }
}

/// cubit for metronome settings
/// FIXME: left off here
/// finished ui for right drawer, now need to react accordingly to options
/// - if vibrate or sound enabled, listen to Chronos and dispatch sound and vibrate events
/// - when blink is off, [Zeus] has some adapted thunderbolts which means only borders of blocks blink, not whole block
///
/// for right drawer
/// - add sound file picker option
class Hermes extends Cubit<Preset> {
  Hermes(Preset initialState) : super(initialState);

  /// update bpm
  void updateBPMby(int bpm) {
    updateBPM(state.bpm + bpm);
  }

  void updateBPM(int bpm) {
    int validated = Preset._validateBPM(bpm);
    if (validated == state.bpm) return;
    emit(Preset.from(state, bpm: validated));
  }

  /// update beats per barNote
  void updateBeatsPerBar(int beats) {
    int validated = Preset._validateBeatsPerBar(beats);
    if (validated == state.beatsPerBar) return;
    emit(Preset.from(state, beatsPerBar: validated));
  }

  /// update barNote
  void updateBarNote(int barNote) {
    int validated = Preset._validateBarNote(barNote);
    if (barNote == state.barNote) return;
    emit(Preset.from(state, barNote: validated));
  }
}
