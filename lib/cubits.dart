import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// [Chronos] Cubit keeps track of time and notifies beat changes based on bpm and
/// beats per measure
class Chronos extends Cubit<int> {
  Chronos({required BuildContext context, int first = 0, this.playing = true})
      : super(validateFirst(
            first, BlocProvider.of<SettingsCubit>(context).state.beats)) {
    ChronosSettings obj = BlocProvider.of<SettingsCubit>(context).state;
    _limit = obj.beats;
    _timerPeriod = obj.beatPeriod;
    if (playing) _initTimer(_timerPeriod);
    // listen to SettingsCubit and update values accordingly
    _settingsSub = BlocProvider.of<SettingsCubit>(context).stream.listen(
      (event) async {
        _limit = event.beats;
        _timerPeriod = event.beatPeriod;
        await _newTimer(_timerPeriod);
      },
    );
  }

  /// close cubit streams and timers
  @override
  Future<void> close() async {
    super.close();
    _timer?.cancel();
    _settingsSub.cancel();
  }

  /// instance variables
  bool playing;
  late final StreamSubscription<ChronosSettings> _settingsSub;
  late int _limit;
  late Duration _timerPeriod;
  Timer? _timer;

  /// init timer from duration
  void _initTimer(Duration d) {
    debugPrint("_initTimer, duration: $d");
    Timer.periodic(d, (timer) {
      _timer = timer;
      debugPrint("first timer activated");
      beat();
    });
  }

  /// update timer from period [d]
  ///
  /// waits for last tick to occur, which means tempo changes are smooth
  Future<void> _newTimer(Duration d) async {
    // if playing, wait for next beat for smooth transition in case of bpm change
    if (playing) await stream.any((_) => true);
    // proceed to update
    debugPrint("how long");
    Timer.periodic(d, (timer) {
      debugPrint("new timer activated");

      _timer = timer;
      beat();
    });
  }

  /// toggle playing, returns whether playing
  void togglePlaying({bool resetCounter = false}) async {
    debugPrint("play toggled");
    if (playing) {
      stop();
    } else {
      start();
    }
  }

  /// start playing
  /// FIXME: error when press toggle multiple times, multiple timers created
  void start() async {
    if (playing) return;
    debugPrint("creating new timer");
    await _newTimer(_timerPeriod);
    playing = true;
  }

  /// stop playing
  void stop() {
    if (!playing) return;
    debugPrint("canceled timer");
    _timer?.cancel();
    playing = false;
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

  /// update color1
  void updateColor1(Color c1) {
    emit(ChronosSettings.from(state, color1: c1));
  }

  /// update color2
  void updateColor2(Color c2) {
    emit(ChronosSettings.from(state, color2: c2));
  }
}
