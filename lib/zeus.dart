import 'dart:async';
import 'dart:developer';

import 'package:chronos/cubits/chronos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Zeus holds Thunderbolts and activates them when necessary
class Zeus extends StatefulWidget {
  const Zeus({super.key});

  @override
  State<StatefulWidget> createState() => _ZeusState();
}

class _ZeusState extends State<Zeus> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late bool _playing;
  late final StreamSubscription _playingSub;

  @override
  void initState() {
    _playing = BlocProvider.of<Chronos>(context).playing;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 50),
    );
    if (_playing) {
      _controller.repeat();
    }
    _playingSub = BlocProvider.of<Chronos>(context)
        .playingStream
        .stream
        .listen((playing) {
      setState(() {
        _playing = playing;
      });
      if (playing) {
        _controller.repeat();
      } else {
        _controller.animateTo(0);
      }
    });
    super.initState();
    log("Zeus.initState, _playing: $_playing");
  }

  /// thunderbolt'
  @override
  Widget build(BuildContext context) {
    final chronos = BlocProvider.of<Chronos>(context);
    log("Zeus.build, _playing: $_playing, progress: ${chronos.progress}");
    return SizedBox(
      width: double.maxFinite,
      height: double.maxFinite,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          return Container(
            width: double.maxFinite,
            height: double.maxFinite,
            color: _playing
                ? Colors.white70
                    .withAlpha((255.0 * (1-chronos.progress)).clamp(0, 255).toInt())
                : Colors.transparent,
          );
        },
      ),
    );
  }

  /// dispose
  @override
  void dispose() {
    _controller.dispose();
    _playingSub.cancel();
    super.dispose();
  }
}
