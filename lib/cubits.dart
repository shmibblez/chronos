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
            first, BlocProvider.of<SettingsCubit>(context).state.beats)) {
    ChronosSettings obj = BlocProvider.of<SettingsCubit>(context).state;
    _limit = obj.beats;
    _timerPeriod = obj.beatPeriod;
    if (initiallyPlaying) _initTimer(_timerPeriod);
    // listen to SettingsCubit and update values accordingly
    _settingsSub = BlocProvider.of<SettingsCubit>(context).stream.listen(
      (event) async {
        // update changed settings
        if (event.beats != _limit) {
          _limit = event.beats;
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
    required this.beats,
    required this.measure,
    required this.color1,
    required this.color2,
  });

  /// copy constructor
  ChronosSettings.from(ChronosSettings old,
      {int? bpm, int? beats, int? measure, Color? color1, Color? color2})
      : bpm = bpm ?? old.bpm,
        beats = beats ?? old.beats,
        measure = measure ?? old.measure,
        color1 = color1 ?? old.color1,
        color2 = color2 ?? old.color2;

  /// instance variables
  final int bpm;
  final int beats;
  final int measure;
  final Color color1;
  final Color color2;

  /// beat period in millis
  Duration get beatPeriod => Duration(milliseconds: (60000 / bpm).truncate());
}

/// cubit for metronome settings
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
    debugPrint("SettingsCubit.updateBPMby: updated BPM to $newBPM");
    emit(ChronosSettings.from(state, bpm: newBPM));
  }

  /// update beats per measure
  void updateBeats(int beats) {
    emit(ChronosSettings.from(state, beats: beats));
  }

  /// update measure
  void updateMeasure(int measure) {
    emit(ChronosSettings.from(state, measure: measure));
  }

  /// update color1
  void updateColor1(Color c1) {
    emit(ChronosSettings.from(state, color1: c1));
  }

  /// update color2
  void updateColor2(Color c2) {
    emit(ChronosSettings.from(state, color2: c2));
  }
}
