import 'dart:developer';

import 'package:audioplayers/audioplayers.dart';
import 'package:chronos/cubits/chronos.dart';
import 'package:chronos/cubits/hephaestus.dart';
import 'package:chronos/cubits/hermes.dart';
import 'package:chronos/cubits/mnemosyne.dart';
import 'package:chronos/home/homepage.dart';
import 'package:chronos/preset_drawer.dart';
import 'package:chronos/zeus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  runApp(const Root());
}

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
/// FIXME: on initial load, preset loaded doesnt reflect actual
/// default preset and only updates when drawer opened for
/// first time
/// FIXME: figure out how to setup android testing
class ChronosConstants {
  static const TextStyle titleTextStyle = TextStyle(color: Colors.white, fontSize: 18);
  static const TextStyle secondaryTitleTextStyle = TextStyle(color: Colors.white54, fontSize: 18);
  static const TextStyle primaryTextStyle = TextStyle(color: Colors.white, fontSize: 16);
  static const TextStyle secondaryTextStyle = TextStyle(color: Colors.white54, fontSize: 16);
  static const TextStyle actionTextStyle = TextStyle(color: Colors.red, fontSize: 16);
  static const TextStyle smallTextStyle = TextStyle(color: Colors.white54, fontSize: 12);
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
    "color1": defaultColor1.value,
    "color2": defaultColor2.value,
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
}

class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black87,
      body: Center(
        child: CircularProgressIndicator(color: Colors.red),
      ),
    );
  }
}

class InitialData {
  InitialData({
    required this.toolbox,
    required this.preset,
    required this.audioPlayers,
  });
  final Toolbox toolbox;
  final Preset preset;
  final List<AudioPlayer> audioPlayers;
}

class Root extends StatelessWidget {
  Future<InitialData> _initialSetup() async {
    // #7
    return await Mnemosyne().awaken();
  }

  const Root({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        theme: ThemeData(
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
            displayLarge:
                TextStyle(fontSize: 72.0, fontWeight: FontWeight.bold),
            titleLarge: TextStyle(fontSize: 36.0, fontStyle: FontStyle.italic),
            bodyMedium: TextStyle(fontSize: 14.0, fontFamily: 'Hind'),
          ),
          checkboxTheme: CheckboxThemeData(
            fillColor: WidgetStateProperty.resolveWith<Color?>(
                (Set<WidgetState> states) {
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
            fillColor: WidgetStateProperty.resolveWith<Color?>(
                (Set<WidgetState> states) {
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
            thumbColor: WidgetStateProperty.resolveWith<Color?>(
                (Set<WidgetState> states) {
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
        ),
        home: SafeArea(
          child: FutureBuilder<InitialData>(
            future: _initialSetup(),
            builder: (context, snap) {
              // if not ready yet, show loading screen
              log("Root.build, snap.connectionState: ${snap.connectionState}");

              if (snap.hasError) {
                log("Root.build, error: ${snap.error}");
              }

              // if future complete, use snap data
              if (snap.hasData) {
                return MultiBlocProvider(
                  providers: [
                    BlocProvider(
                      lazy: false,
                      create: (_) {
                        log("Creating Hephaestus, snap.data.toolbox: ${snap.data?.toolbox}");
                        return Hephaestus(snap.data!.toolbox);
                      },
                    ),
                    BlocProvider(
                      lazy: false,
                      create: (_) => Hermes(snap.data!.preset),
                    ),
                    BlocProvider(
                      lazy: false,
                      create: (BuildContext context1) => Chronos(
                        context: context1,
                      ),
                    ),
                  ],
                  child: Homepage(key: super.key),
                );
              }

              // if loading or error show loading page
              return const LoadingPage();
            },
          ),
        ),
      );
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<StatefulWidget> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final TextEditingController _bpmController;
  // used to know if need to update textfield values in case of preset or toolbox change
  Preset? _oldPreset;

  @override
  void initState() {
    super.initState();
    _bpmController = TextEditingController();
  }

  @override
  void dispose() {
    _bpmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _oldPreset = BlocProvider.of<Hermes>(context).state;
    });
    return Scaffold(
      key: _scaffoldKey,
      // todo: use default drawer size, also use same background as SettingsDrawer looks nice
      drawer: const PresetDrawer(),
      // endDrawer: const SettingsDrawer(),
      onDrawerChanged: (open) {
        if (!open) {
          BlocProvider.of<Chronos>(context).start();
        } else {
          BlocProvider.of<Chronos>(context).stop();
        }
      },
      // onEndDrawerChanged: (open) {
      //   if (!open) {
      //     BlocProvider.of<Chronos>(context).start();
      //   } else {
      //     BlocProvider.of<Chronos>(context).stop();
      //   }
      // },
      body: ColoredBox(
        // for setting color behind bottom bar
        color: Colors.black,
        child: Column(
          children: [
            /// blink indicator with [GestureDetector] as parent for playback options:
            /// - play/pause -> tap
            /// - change bpm -> slide up or down
            /// - show options drawers -> slide left or right
            Expanded(
              child: Stack(
                children: [
                  /// blink indicator
                  const Zeus(),

                  /// for gesture options
                  Center(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width - 70,
                      child: GestureDetector(
                        // change tempo based on scroll amount
                        // positive amount is down (tempo decrease)
                        // negative amount is up (tempo increase)
                        onVerticalDragUpdate: (DragUpdateDetails details) {
                          // change tempo by 1
                          double delta = details.delta.dy;
                          int bpmChange = -delta.sign.toInt();
                          BlocProvider.of<Hermes>(context)
                              .updateBPMbyThrottled(bpmChange);
                        },
                        onHorizontalDragEnd: (details) {
                          if (details.primaryVelocity != null) {
                            if (details.primaryVelocity! < 0) {
                              // if swipe left, open end drawer
                              _scaffoldKey.currentState?.openEndDrawer();
                            } else if (details.primaryVelocity! > 0) {
                              // if swipe right, open drawer
                              _scaffoldKey.currentState?.openDrawer();
                            }
                          }
                        },
                        // on tap toggle metronome click -> play/pause
                        onTap: () {
                          BlocProvider.of<Chronos>(context).togglePlaying();
                        },
                        onLongPress: () {
                          // todo: show edit preset dialog, if default show add preset dialog
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// bottom indicator options
            BlocBuilder<Hephaestus, Toolbox>(
              // rebuild only if background color has changed
              buildWhen: (prev, curr) => prev.color1l != curr.color1l,
              builder: (_, settings) {
                final Color backgroundColor = settings.color1l;
                final Color textColor =
                    settings.visibleTextColor(backgroundColor, settings.color2);
                final TextStyle textStyle = TextStyle(color: textColor);
                return Container(
                  height: kBottomNavigationBarHeight,
                  color: backgroundColor,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      /// bpm modifier and display
                      // rebuild when bpm changes
                      BlocBuilder<Hermes, Preset?>(
                        buildWhen: (prev, curr) => prev?.bpm != curr?.bpm,
                        builder: (context, preset) {
                          if (_oldPreset?.key != preset?.key ||
                              _oldPreset?.bpm != preset?.bpm ||
                              _bpmController.text.isEmpty) {
                            _bpmController.text = preset?.bpm.toString() ?? "";
                          }
                          return Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 50,
                                  child: TextField(
                                      style: textStyle,
                                      textAlign: TextAlign.center,
                                      controller: _bpmController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly
                                      ],
                                      onSubmitted: (str) {
                                        int newBPM = int.parse(str);
                                        BlocProvider.of<Hermes>(context)
                                            .updateBPM(newBPM);
                                      }),
                                ),
                                Text("bpm", style: textStyle),
                              ],
                            ),
                          );
                        },
                      ),

                      /// beat indicator selector
                      const BeatIndicators(),

                      /// #5 placeholder
                      Expanded(child: Container()),
                      // #5
                      // Expanded(
                      //   child: IconButton(
                      //     onPressed: () {
                      //       BlocProvider.of<SettingsCubit>(context)
                      //           .toggleClickEnabled();
                      //     },
                      //     icon: settings.clickEnabled
                      //         ? Icon(Icons.touch_app, color: lighter)
                      //         : Icon(Icons.touch_app, color: darker),
                      //     // color when enabled & not pressed
                      //     color: settings.color1,
                      //     // color when pressed
                      //     highlightColor: settings.color1l,
                      //   ),
                      // ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// [BeatIndicators] allows toggling enabled beat indicators
class BeatIndicators extends StatelessWidget {
  const BeatIndicators({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<Hephaestus, Toolbox>(
      buildWhen: (prev, curr) =>
          prev.blinkEnabled != curr.blinkEnabled ||
          prev.vibrateEnabled != curr.vibrateEnabled ||
          prev.clickEnabled != curr.clickEnabled ||
          prev.color1 != curr.color1 ||
          prev.color2 != curr.color2,
      builder: (context, settings) {
        Color darker = settings.color2d;
        Color lighter = settings.color2l;

        /// #6
        return Wrap(
          direction: Axis.horizontal,
          alignment: WrapAlignment.center,
          children: [
            // blink indicator is always enabled
            // /// blink indicator
            // IconButton(
            //   onPressed: () {
            //     BlocProvider.of<Hephaestus>(context).toggleBlinkEnabled();
            //   },
            //   icon: settings.blinkEnabled
            //       ? Icon(Icons.lightbulb, color: lighter)
            //       : Icon(Icons.lightbulb_outline, color: darker),
            // ),

            /// vibrate indicator, only show if device can vibrate
            if (settings.vibrateAvailable)
              IconButton(
                onPressed: () {
                  BlocProvider.of<Hephaestus>(context).toggleVibrateEnabled();
                },
                icon: settings.vibrateEnabled
                    ? Icon(Icons.vibration, color: lighter)
                    : Icon(Icons.phone_android_sharp, color: darker),
              ),

            /// click indicator
            IconButton(
              onPressed: () {
                BlocProvider.of<Hephaestus>(context).toggleClickEnabled();
              },
              icon: settings.clickEnabled
                  ? Icon(Icons.volume_up_rounded, color: lighter)
                  : Icon(Icons.volume_off_rounded, color: darker),
            ),
          ],
        );
      },
    );
  }
}
