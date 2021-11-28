import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// [Hephaestus]'s toolbox. This is where he stores app settings
class Toolbox {
  Toolbox({
    required this.color1,
    required this.color2,
    required this.blinkEnabled,
    required this.vibrateEnabled,
    required this.clickEnabled,
    required this.vibrateAvailable,
    required this.soundId,
    required this.presetsEnabled,
  });

  /// copy constructor
  Toolbox.from(
    Toolbox old, {
    Color? color1,
    Color? color2,
    bool? blinkEnabled,
    bool? vibrateEnabled,
    bool? clickEnabled,
    int? soundId,
    bool? presetsEnabled,
  })  : color1 = color1 ?? old.color1,
        color2 = color2 ?? old.color2,
        blinkEnabled = blinkEnabled ?? old.blinkEnabled,
        vibrateEnabled = vibrateEnabled ?? old.vibrateEnabled,
        clickEnabled = clickEnabled ?? old.clickEnabled,
        vibrateAvailable = old.vibrateAvailable,
        soundId = soundId ?? old.soundId,
        presetsEnabled = presetsEnabled ?? old.presetsEnabled;

  /// instance variables
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
  final bool presetsEnabled;

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

/// [Hephaestus] is in charge of crafting this app, and stores and updates settings like:
/// - app colors
/// - enabled indicators
/// - selected sound
class Hephaestus extends Cubit<Toolbox> {
  Hephaestus(Toolbox initialState) : super(initialState);

  /// update color1
  void updateColor1(Color c1) {
    if (c1 == state.color1) return;
    emit(Toolbox.from(state, color1: c1));
  }

  /// update color2
  void updateColor2(Color c2) {
    if (c2 == state.color2) return;
    emit(Toolbox.from(state, color2: c2));
  }

  /// update blinkEnabled
  void toggleBlinkEnabled() {
    emit(Toolbox.from(state, blinkEnabled: !state.blinkEnabled));
  }

  /// update vibrateEnabled
  void toggleVibrateEnabled() {
    // only allow true if vibration is available
    if (!state.vibrateAvailable) return;
    emit(Toolbox.from(state, vibrateEnabled: !state.vibrateEnabled));
  }

  /// update clivkEnabled
  void toggleClickEnabled() {
    emit(Toolbox.from(state, clickEnabled: !state.clickEnabled));
  }

  void updatePresetsEnabled(bool enabled) {
    if (enabled == state.presetsEnabled) return;
    emit(Toolbox.from(state, presetsEnabled: enabled));
  }
}
