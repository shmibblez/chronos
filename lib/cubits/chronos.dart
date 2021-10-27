import 'dart:async';
import 'package:chronos/cubits/hephaestus.dart';
import 'package:chronos/cubits/hermes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soundpool/soundpool.dart';
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
      required this.soundpool,
      int first = 0,
      initiallyPlaying = true})
      : super(validateFirstBeat(
            first, BlocProvider.of<Hermes>(context).state.beatsPerBar)) {
    Preset preset = BlocProvider.of<Hermes>(context).state;
    _limit = preset.beatsPerBar;
    _timerPeriod = preset.beatPeriod;
    Toolbox toolbox = BlocProvider.of<Hephaestus>(context).state;
    _clickEnabled = toolbox.clickEnabled;
    _vibrateEnabled = toolbox.vibrateEnabled;
    _soundId = toolbox.soundId;
    if (initiallyPlaying) _initTimer(_timerPeriod);
    // listen to Hermes for preset changes
    _hermesSub = BlocProvider.of<Hermes>(context).stream.listen(
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
    // listen to Hephaestus for options changes
    _hephasestusSub = BlocProvider.of<Hephaestus>(context).stream.listen(
      (event) {
        if (event.clickEnabled != _clickEnabled) {
          _clickEnabled = event.clickEnabled;
        }
        if (event.vibrateEnabled != _vibrateEnabled) {
          _vibrateEnabled = event.vibrateEnabled;
        }
        if (event.soundId != _soundId) {
          _soundId = event.soundId;
        }
      },
    );
  }

  /// lifecycle end
  @override
  Future<void> close() async {
    super.close();
    // _timer?.clo();
    _hermesSub.cancel();
  }

  /// instance variables
  late final StreamSubscription<Preset> _hermesSub;
  late final StreamSubscription<Toolbox> _hephasestusSub;
  late int _limit;
  late Duration _timerPeriod;
  StreamSubscription<void>? _timerSub;
  late int _soundId;
  late bool _clickEnabled;
  late bool _vibrateEnabled;
  final Soundpool soundpool;

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
    if (_clickEnabled) soundpool.play(_soundId);
    if (_vibrateEnabled) Vibration.vibrate();
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
