import 'package:chronos/cubits/hermes.dart';
import 'package:chronos/zeus.dart';
import 'package:flutter/material.dart';

/// Some potential improvements, priority 1, 2, or 3
/// - #2 (1) show beat strength editor (from 1-3) when long-press screen. Also store this in preset as array of numbers (0 for off, 3 for max strength)
/// - #4 (2) save last settings (last preset, tempo, enabled indicators, beat strength selections), careful with tempo since set very quickly
/// - #5 (2) add tap to tempo option (not necessary), or better yet show note volume/pitch editor
/// - #6 (3) consider using ToggleButtons instead of row
/// - #7 (2) load futures simultaneously with Future.wait instead of waiting one after another
/// - #! (1) when blink is off, [Zeus] has some adapted thunderbolts which means only borders of blocks blink, not whole block
/// - #! (3) add sound file picker option in right drawer
/// - #NaN (3) better way to cache loaded sounds, Mnemosyne could store them instead of PresetList
/// - #9 (3) when item unfocused, whole preset should be saved, not just notes
/// - #10 (3) show confirmation screen when deleting preset
/// - #12 (1) add way to export/import preset
/// - #NaN (1) fix local preset list when adding new presets, also keep in sync better with db
/// ChromosComstamts, some app constants
///
class ChronosConstants {
  static const TextStyle titleTextStyle = TextStyle(
    color: Colors.white,
    fontSize: 18,
  );
  static const TextStyle secondaryTitleTextStyle = TextStyle(
    color: Colors.white54,
    fontSize: 18,
  );
  static const TextStyle normalTextStyle = TextStyle(
    color: Colors.white,
    fontSize: 16,
  );
  static const TextStyle secondaryNormalTextStyle = TextStyle(
    color: Colors.white54,
    fontSize: 16,
  );
  static const TextStyle actionTextStyle = TextStyle(
    color: Colors.red,
    fontSize: 16,
  );
  static TextStyle secondaryActionTextStyle = TextStyle(
    color: Colors.red.withAlpha(122),
    fontSize: 16,
  );
  static const TextStyle smallTextStyle = TextStyle(
    color: Colors.white54,
    fontSize: 12,
  );
  static const TextStyle secondarySmallTextStyle = TextStyle(
    color: Colors.white,
    fontSize: 12,
  );
  static const int maxNameLength = 100;
  static const int minNameLength = 0;
  static const int maxNotesLength = 750;
  static const int minNotesLength = 0;
  static const int maxBPM = 500;
  static const int minBPM = 20;
  static const int maxBeatsPerBar = 20;
  static const int minBeatsPerBar = 2;
  static const int deltaBPM = maxBPM - minBPM;
  static const int defaultBPM = 75; // resting heart bpm is about 70-80
  static const defaultColor1 = Color.fromARGB(255, 25, 25, 25);
  static const defaultColor2 = Colors.white;
  static final defPrefs = {
    "color1": defaultColor1.toARGB32(),
    "color2": defaultColor2.toARGB32(),
    "blinkEnabled": false,
    "vibrateEnabled": false,
    "clickEnabled": true,
    "sound": "assets/sounds/wood_sound.wav",
  };
  static final defPreset = Preset.toJSON(
    Preset(
      key: "default",
      name: "default",
      bpm: 100,
      beatsPerBar: 4,
      barNote: 4,
      millis: DateTime.now().millisecondsSinceEpoch,
      notes: "",
    ),
  );
  static final theme = ThemeData(
    scaffoldBackgroundColor: Colors.black45,
    colorScheme: const ColorScheme.dark(
      primary: Colors.black,
      secondary: Colors.red,
      // inversePrimary: Colors.white,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(
          width: 3,
          color: Colors.red,
        ),
      ),
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
        style: TextButton.styleFrom(
      backgroundColor: Colors.red,
      textStyle: const TextStyle(color: Colors.white),
    )),
    // Define the default font family.
    fontFamily: 'Arial',
    // Define the default `TextTheme`. Use this to specify the default
    // text styling for headlines, titles, bodies of text, and more.
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 72.0, fontWeight: FontWeight.bold),
      titleLarge: TextStyle(fontSize: 36.0, fontStyle: FontStyle.italic),
      bodyMedium: TextStyle(fontSize: 14.0, fontFamily: 'Hind'),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor:
          WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
        if (states.contains(WidgetState.disabled)) {
          return null;
        }
        if (states.contains(WidgetState.selected)) {
          return Colors.red;
        }
        return null;
      }),
    ),
    radioTheme: RadioThemeData(
      fillColor:
          WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
        if (states.contains(WidgetState.disabled)) {
          return null;
        }
        if (states.contains(WidgetState.selected)) {
          return Colors.red;
        }
        return null;
      }),
    ),
    switchTheme: SwitchThemeData(
      thumbColor:
          WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
        if (states.contains(WidgetState.disabled)) {
          return null;
        }
        if (states.contains(WidgetState.selected)) {
          return Colors.red;
        }
        return null;
      }),
      trackColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.disabled)) {
            return null;
          }
          if (states.contains(WidgetState.selected)) {
            return Colors.red;
          }
          return null;
        },
      ),
    ),
    // buttonTheme: const ButtonThemeData(
    //   buttonColor: Colors.red,
    //   highlightColor: Colors.red,
    //   textTheme: ButtonTextTheme.accent,
    //   splashColor: Colors.transparent,
    //   focusColor: Colors.redAccent,
    //   hoverColor: Colors.redAccent,
    //   disabledColor: Colors.grey,
    // ),
  );
}
