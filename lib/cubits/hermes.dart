import 'package:chronos/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class Preset {
  Preset({required int bpm, required int beatsPerBar, required this.barNote})
      : bpm = _validateBPM(bpm),
        beatsPerBar = _validateBeatsPerBar(beatsPerBar);

  Preset.from(Preset old, {int? bpm, int? beatsPerBar, int? barNote})
      : bpm = bpm ?? old.bpm,
        beatsPerBar = beatsPerBar ?? old.beatsPerBar,
        barNote = barNote ?? old.barNote;

  final int bpm;
  final int beatsPerBar;
  final int barNote;

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
}

/// these contain the information tranported by [Hermes] storing info like:
/// - active preset
/// - active settings
/// - active indicators
/// - active sound id
class MailBag {
  MailBag({
    required this.preset,
    required this.color1,
    required this.color2,
    required this.blinkEnabled,
    required this.vibrateEnabled,
    required this.clickEnabled,
    required this.vibrateAvailable,
    required this.soundId,
  });

  /// copy constructor
  MailBag.from(
    MailBag old, {
    Preset? preset,
    Color? color1,
    Color? color2,
    bool? blinkEnabled,
    bool? vibrateEnabled,
    bool? clickEnabled,
    int? soundId,
  })  : preset = preset ?? old.preset,
        color1 = color1 ?? old.color1,
        color2 = color2 ?? old.color2,
        blinkEnabled = blinkEnabled ?? old.blinkEnabled,
        vibrateEnabled = vibrateEnabled ?? old.vibrateEnabled,
        clickEnabled = clickEnabled ?? old.clickEnabled,
        vibrateAvailable = old.vibrateAvailable,
        soundId = soundId ?? old.soundId;

  /// instance variables
  final Preset preset;
  // main color, [Thunderbolt] color when idle
  final Color color1;
  // secondary/contrast color, [Thunderbolt] color when enabled
  final Color color2;
  // color1 but darker
  Color get color1d => Color.lerp(Colors.black, color1, 0.9)!;
  // color2 but darker
  Color get color2d => Color.lerp(Colors.black, color2, 0.6)!;
  // color1 but lighter
  Color get color1l => Color.lerp(color1, Colors.white, 0.1)!;
  // color2 but lighter
  Color get color2l => Color.lerp(color2, Colors.white, 0.1)!;
  final bool blinkEnabled;
  final bool vibrateEnabled;
  final bool clickEnabled;
  final bool vibrateAvailable;
  final int soundId;

  /// beat period in millis
  Duration get beatPeriod =>
      Duration(milliseconds: (60000 / preset.bpm).truncate());

  /// taking [bk] as background color, return color for text such that it's visible on it
  ///
  /// tries to return [xt], but if [bk] and [xt] are too similar, returns bk's opposite color
  Color visibleTextColor(Color bk, Color xt) {
    double avgDiff = ((bk.red - xt.red).abs() +
            (bk.green - xt.green).abs() +
            (bk.blue - xt.blue).abs()) /
        3;

    // if [xt] is different enough from [bk], return [xt]
    if (avgDiff > 10) return xt;
    // if not different enough, return opposite color
    return Color.fromARGB(255, 255 - bk.red, 255 - bk.green, 255 - bk.blue);
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
