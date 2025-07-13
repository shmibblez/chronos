import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:chronos/cubits/hephaestus.dart';
import 'package:chronos/cubits/hermes.dart';
import 'package:chronos/cubits/mnemosyne.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vibration/vibration.dart';

/// [Chronos] keeps track of time and notifies beat changes based on bpm and
/// beats per measure
///
/// Timer can be reset in 2 cases:
/// 1. bpm change
/// 2. play/pause
/// For case 1, normal reset is done in sync with current
/// For case 2, wait until tick, then reset timer with new tempo
class Chronos extends Cubit<int> {
  Chronos(
      {required BuildContext context,
      int first = 0,
      initiallyPlaying = true})
      : super(validateFirstBeat(
            first, BlocProvider.of<Hermes>(context).state?.beatsPerBar ?? 4)) {
    _periodDurationMs = 0;
    _lastPeriodResetMs = DateTime.now().millisecondsSinceEpoch;
    Preset? preset = BlocProvider.of<Hermes>(context).state;
    _limit = preset?.beatsPerBar ?? 4;
    _timerPeriod = preset?.beatPeriod ?? Duration.zero;
    Toolbox toolbox = BlocProvider.of<Hephaestus>(context).state;
    _clickEnabled = toolbox.clickEnabled;
    _vibrateEnabled = toolbox.vibrateEnabled;
    _soundSource = toolbox.soundSource;
    if (initiallyPlaying) _initTimer(_timerPeriod);
    // listen to Hermes for preset changes
    _hermesSub = BlocProvider.of<Hermes>(context).stream.listen(
      (event) async {
        // update changed settings
        if (event?.beatsPerBar != _limit) {
          _limit = event?.beatsPerBar ?? 4;

        }
        if (_timerPeriod != event?.beatPeriod) {
          _timerPeriod = event?.beatPeriod ?? Duration.zero;
          await _periodChanged(_timerPeriod);
        }
      },
    );
    // listen to Hephaestus for options changes
    _hephasestusSub = BlocProvider.of<Hephaestus>(context).stream.listen(
      (event) {
        if (event.clickEnabled != _clickEnabled) {
          _clickEnabled = event.clickEnabled;
        }
        if (event.vibrateEnabled != _vibrateEnabled) {
          _vibrateEnabled = event.vibrateEnabled;
        }
        if (event.soundSource != _soundSource) {
          _soundSource = event.soundSource;
        }
      },
    );
  }

  /// lifecycle end
  @override
  Future<void> close() async {
    await super.close();
    // _timer?.clo();
    await _hermesSub.cancel();
    await _hephasestusSub.cancel();
  }

  /// instance variables
  // progress of current beat, from 0 to 1
  late int _periodDurationMs;
  late int _lastPeriodResetMs;
  late final StreamSubscription<Preset?> _hermesSub;
  late final StreamSubscription<Toolbox> _hephasestusSub;
  late int _limit;
  late Duration _timerPeriod;
  StreamSubscription<void>? _timerSub;
  late Source _soundSource;
  late bool _clickEnabled;
  late bool _vibrateEnabled;

  double get progress {
    return ((DateTime.now().millisecondsSinceEpoch - _lastPeriodResetMs) /
        _periodDurationMs).clamp(0.0, 1.0);
  }

  int get beatsPerBar {
    return _limit;
  }

  /// other instance variables
  bool get playing {
    return _timerSub != null && !_timerSub!.isPaused;
  }

  // bool get pendingNewTimer {
  //   return _newTimerResult != null;
  // }

  /// init timer from duration
  void _initTimer(Duration d) {
    _periodDurationMs = d.inMilliseconds;
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
    _periodDurationMs = d.inMilliseconds;
    _timerSub!.onData((i) {
      beat();
      // // remove current sub
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
    _lastPeriodResetMs = DateTime.now().millisecondsSinceEpoch;
    late int beat;
    if (state + 1 > _limit - 1) {
      beat = 0;
    } else {
      beat = state + 1;
    }
    emit(beat);
    final audioPlayers = Mnemosyne().audioPlayers;
    if (_clickEnabled) {
      audioPlayers?.elementAtOrNull(beat)?.seek(Duration.zero);
      audioPlayers?.elementAtOrNull(beat)?.play(_soundSource);
    }
    if (_vibrateEnabled) {
      // accounts for soundpool delay
      Future.delayed(
        const Duration(milliseconds: 55),
        () {
          Vibration.vibrate(
            duration: 150,
            sharpness: 50,
          );
        },
      );
    }
    return beat;
  }

  /// make sure starting beat [first] isn't greater than [limit]
  static int validateFirstBeat(int first, int limit) {
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
