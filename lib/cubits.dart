import 'dart:async';
import 'package:chronos/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// [Chronos] Cubit keeps track of time and notifies beat changes based on bpm and
/// beats per measure
///
/// Timer can be reset in 2 cases:
/// 1. bpm change
/// 2. play/pause
/// For case 1, normal reset is done in sync with current
/// For case 2, wait until tick, then reset timer with new tempo
class Chronos extends Cubit<int> {
  Chronos(
      {required BuildContext context, int first = 0, initiallyPlaying = true})
      : super(validateFirst(
            first, BlocProvider.of<SettingsCubit>(context).state.beatsPerBar)) {
    ChronosSettings obj = BlocProvider.of<SettingsCubit>(context).state;
    _limit = obj.beatsPerBar;
    _timerPeriod = obj.beatPeriod;
    if (initiallyPlaying) _initTimer(_timerPeriod);
    // listen to SettingsCubit and update values accordingly
    _settingsSub = BlocProvider.of<SettingsCubit>(context).stream.listen(
      (event) async {
        // update changed settings
        if (event.beatsPerBar != _limit) {
          _limit = event.beatsPerBar;
        }
        if (_timerPeriod != event.beatPeriod) {
          _timerPeriod = event.beatPeriod;
          await _periodChanged(_timerPeriod);
        }
      },
    );
  }

  /// lifecycle end
  @override
  Future<void> close() async {
    super.close();
    // _timer?.clo();
    _settingsSub.cancel();
  }

  /// instance variables
  late final StreamSubscription<ChronosSettings> _settingsSub;
  late int _limit;
  late Duration _timerPeriod;
  StreamSubscription<void>? _timerSub;

  /// other instance variables
  bool get playing {
    return _timerSub != null && !_timerSub!.isPaused;
  }

  // bool get pendingNewTimer {
  //   return _newTimerResult != null;
  // }

  /// init timer from duration
  void _initTimer(Duration d) {
    _timerSub = Stream<void>.periodic(d).listen((_) {
      beat();
    });
  }

  /// update timer from period [d]
  ///
  /// waits for last tick to occur -> tempo changes are smooth
  Future<void> _periodChanged(Duration d) async {
    if (!playing) return;
    // update sub callback, allows for smooth tempo changes
    _timerSub!.onData((i) {
      beat();
      // remove current sub
      _timerSub?.pause();
      _timerSub?.cancel();
      _timerSub = null;
      // reset timer according to new duration
      _initTimer(d);
    });
  }

  /// toggle playing, returns whether playing
  void togglePlaying({bool resetCounter = false}) async {
    if (playing) {
      stop();
    } else {
      start();
    }
  }

  /// start playing
  void start() {
    if (playing) return;
    beat();
    _initTimer(_timerPeriod);
  }

  /// stop playing
  void stop() {
    if (!playing) return;
    _timerSub?.pause();
    _timerSub?.cancel();
    _timerSub = null;
  }

  /// increment and emit beat #
  int beat() {
    late int beat;
    if (state + 1 > _limit - 1) {
      beat = 0;
    } else {
      beat = state + 1;
    }
    emit(beat);
    return beat;
  }

  /// make sure starting beat [first] isn't greater than [limit]
  static int validateFirst(int first, int limit) {
    // limit - 1 since first is 0 indexed
    if (first >= limit - 1) return 0;
    return first;
  }

  // /// get next beat num
  // int nextBeatNum() {
  //   if (state + 1 > _limit - 1) return 0;
  //   return state + 1;
  // }
}

/// stores metronome settings
class ChronosSettings {
  const ChronosSettings({
    required this.bpm,
    required this.beatsPerBar,
    required this.barNote,
    required this.color1,
    required this.color2,
    required this.blinkEnabled,
    required this.vibrateEnabled,
    required this.clickEnabled,
    required this.vibrateAvailable,
  });

  /// copy constructor
  ChronosSettings.from(
    ChronosSettings old, {
    int? bpm,
    int? beats,
    int? barNote,
    Color? color1,
    Color? color2,
    bool? blinkEnabled,
    bool? vibrateEnabled,
    bool? clickEnabled,
  })  : bpm = bpm ?? old.bpm,
        beatsPerBar = beats ?? old.beatsPerBar,
        barNote = barNote ?? old.barNote,
        color1 = color1 ?? old.color1,
        color2 = color2 ?? old.color2,
        blinkEnabled = blinkEnabled ?? old.blinkEnabled,
        vibrateEnabled = vibrateEnabled ?? old.vibrateEnabled,
        clickEnabled = clickEnabled ?? old.clickEnabled,
        vibrateAvailable = old.vibrateAvailable;

  /// instance variables
  final int bpm;
  final int beatsPerBar;
  final int barNote;
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

  /// beat period in millis
  Duration get beatPeriod => Duration(milliseconds: (60000 / bpm).truncate());

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
/// for left drawer
/// - add presets
class SettingsCubit extends Cubit<ChronosSettings> {
  SettingsCubit(ChronosSettings initialState) : super(initialState);

  /// update bpm
  void updateBPMby(int bpm) {
    int newBPM = state.bpm + bpm;
    if (newBPM > ChronosConstants.maxBPM) {
      newBPM = ChronosConstants.maxBPM;
    } else if (newBPM < ChronosConstants.minBPM) {
      newBPM = ChronosConstants.minBPM;
    }
    emit(ChronosSettings.from(state, bpm: newBPM));
  }

  void updateBPM(int bpm) {
    if (bpm > ChronosConstants.maxBPM) {
      bpm = ChronosConstants.maxBPM;
    } else if (bpm < ChronosConstants.minBPM) {
      bpm = ChronosConstants.minBPM;
    }
    emit(ChronosSettings.from(state, bpm: bpm));
  }

  /// update beats per barNote
  void updateBeats(int beats) {
    if (beats == state.beatsPerBar) return;
    emit(ChronosSettings.from(state, beats: beats));
  }

  /// update barNote
  void updateBarNote(int barNote) {
    if (barNote == state.barNote) return;
    emit(ChronosSettings.from(state, barNote: barNote));
  }

  /// update color1
  void updateColor1(Color c1) {
    if (c1 == state.color1) return;
    emit(ChronosSettings.from(state, color1: c1));
  }

  /// update color2
  void updateColor2(Color c2) {
    if (c2 == state.color2) return;
    emit(ChronosSettings.from(state, color2: c2));
  }

  /// update blinkEnabled
  void toggleBlinkEnabled() {
    emit(ChronosSettings.from(state, blinkEnabled: !state.blinkEnabled));
  }

  /// update vibrateEnabled
  void toggleVibrateEnabled() {
    emit(ChronosSettings.from(state, vibrateEnabled: !state.vibrateEnabled));
  }

  /// update clivkEnabled
  void toggleClickEnabled() {
    emit(ChronosSettings.from(state, clickEnabled: !state.clickEnabled));
  }
}
