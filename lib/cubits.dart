import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// FIXME: left off here
/// - finished cubit setups
/// - was going to work on Home widget
///.

/// [Chronos] Cubit keeps track of time and notifies beat changes based on bpm and
/// beats per measure
class Chronos extends Cubit<int> {
  Chronos({required BuildContext context, int first = 0, this.playing = false})
      : super(validateFirst(first, context.read<ChronosSettings>().beats)) {
    ChronosSettings obj = context.read<ChronosSettings>();
    _limit = obj.beats;
    _timerPeriod = obj.beatPeriod;
    _timer = _initTimer(_timerPeriod);
    // listen to SettingsCubit and update values accordingly
    _settingsSub = BlocProvider.of<SettingsCubit>(context).stream.listen(
      (event) async {
        _timerPeriod = event.beatPeriod;
        _timer = await _newTimer(_timerPeriod);
        _limit = event.beats;
      },
    );
  }

  /// close cubit streams and timers
  @override
  Future<void> close() async {
    super.close();
    _timer.cancel();
    _settingsSub.cancel();
  }

  /// instance variables
  bool playing;
  late final StreamSubscription<ChronosSettings> _settingsSub;
  late int _limit;
  late Duration _timerPeriod;
  late Timer _timer;

  /// init timer from duration
  Timer _initTimer(Duration d) {
    return Timer(d, () {
      beat();
    });
  }

  /// update timer from period [d]
  ///
  /// waits for last tick to occur, which means tempo changes are smooth
  Future<Timer> _newTimer(Duration d) async {
    // wait for next beat
    await stream.any((_) => true);
    // proceed to update
    return Timer(d, () {
      beat();
    });
  }

  /// toggle playing, returns whether playing
  void togglePlaying({bool resetCounter = false}) async {
    if (playing) {
      _timer.cancel();
      playing = false;
    } else {
      _timer = await _newTimer(_timerPeriod);
      playing = true;
    }
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
  });

  /// copy constructor
  ChronosSettings.from(ChronosSettings old,
      {int? bpm, int? beats, int? measure})
      : bpm = bpm ?? old.bpm,
        beats = beats ?? old.beats,
        measure = measure ?? old.measure;

  /// instance variables
  final int bpm;
  final int beats;
  final int measure;

  /// beat period in millis
  Duration get beatPeriod => Duration(milliseconds: (60000 / bpm).truncate());
}

/// cubit for metronome settings
class SettingsCubit extends Cubit<ChronosSettings> {
  SettingsCubit(ChronosSettings initialState) : super(initialState);

  /// update bpm
  void updateBPM(int bpm) {
    emit(ChronosSettings.from(state, bpm: bpm));
  }

  /// update beats per measure
  void updateBeats(int beats) {
    emit(ChronosSettings.from(state, beats: beats));
  }

  /// update measure
  void updateMeasure(int measure) {
    emit(ChronosSettings.from(state, measure: measure));
  }
}
