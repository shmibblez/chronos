import 'package:chronos/cubits.dart';
import 'package:chronos/zeus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'right_drawer.dart';

void main() {
  runApp(const Root());
}

/// Some potential improvements, priority 1, 2, or 3
/// - load last used settings, fall back to defaults in [ChronosConstants]
/// - #1 (3) if bpm outside min & max bounds, show message and set to min or max
/// - #2 (1) show beat strength editor (from 1-3) when long-press screen. Also store this in preset as array of numbers (0 for off, 3 for max strength)
/// - #3 (1) check if vibration enabled, allow toggling if true
/// - #4 (2) save last settings and load new ones (last preset, tempo, enabled indicators, beat strength selections)
/// - #5 (2) add tap to tempo option

/// ChromosComstamts, some app constants
class ChronosConstants {
  static const int maxBPM = 500;
  static const int minBPM = 20;
  static const int deltaBPM = maxBPM - minBPM;
  static const int defaultBPM = 75; // resting heart bpm is about 70-80
  static const defaultColor1 = Colors.black87;
  static const defaultColor2 = Colors.white70;
}

class Root extends StatelessWidget {
  const Root({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider(
                lazy: false,
                create: (_) => SettingsCubit(
                      const ChronosSettings(
                        bpm: 100,
                        beatsPerBar: 4,
                        barNote: 4,
                        color1: Colors.black87,
                        color2: Colors.white70,
                        blinkEnabled: true,
                        vibrateEnabled: false, // #3
                        clickEnabled: true,
                        vibrateAvailable: false, // #3
                      ),
                    )),
            BlocProvider(
                create: (BuildContext context1) => Chronos(context: context1),
                lazy: false),
          ],
          child: Home(key: super.key),
        ),
      );
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        child: ListView(
            // settings and T&C
            ),
      ),
      endDrawer: const RightDrawer(),
      onDrawerChanged: (open) {
        if (!open) {
          BlocProvider.of<Chronos>(context).start();
          debugPrint("drawer closed");
        }
      },
      onEndDrawerChanged: (open) {
        if (!open) {
          BlocProvider.of<Chronos>(context).start();
          debugPrint("end drawer closed");
        }
      },
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          /// blink indicator with [GestureDetector] as parent for playback options:
          /// - play/pause -> tap
          /// - change bpm -> slide up or down
          /// - show options drawers -> slide left or right
          Expanded(
            child: GestureDetector(
              // change tempo based on scroll amount
              // positive amount is down (tempo decrease)
              // negative amount is up (tempo increase)
              onVerticalDragUpdate: (DragUpdateDetails details) {
                // change tempo by 1
                double delta = details.delta.dy;
                int bpmChange = -delta.sign.toInt();
                BlocProvider.of<SettingsCubit>(context).updateBPMby(bpmChange);
                // debugPrint(
                //   "VDU: delta: ${details.delta}, bpm change $bpmChange",
                // );
              },
              // open drawer depending on swipe direction
              onHorizontalDragEnd: (DragEndDetails details) {
                BlocProvider.of<Chronos>(context).stop();
                if ((details.primaryVelocity ?? 0) > 0) {
                  _scaffoldKey.currentState!.openDrawer();
                } else if ((details.primaryVelocity ?? 0) < 0) {
                  _scaffoldKey.currentState!.openEndDrawer();
                }
              },
              // on tap toggle metronome click -> play/pause
              onTap: () {
                BlocProvider.of<Chronos>(context).togglePlaying();
              },
              onLongPress: () {
                // show dialog that allows toggling tempo display options
              },

              /// blink indicator
              child: const Zeus(),
            ),
          ),

          /// bottom indicator options
          BlocBuilder<SettingsCubit, ChronosSettings>(
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    /// bpm modifier and display
                    BlocBuilder<SettingsCubit, ChronosSettings>(
                        buildWhen: (prev, curr) => prev.bpm != curr.bpm,
                        builder: (context, settings) {
                          final TextEditingController _tempoController =
                              TextEditingController(
                                  text: settings.bpm.toString());
                          return Expanded(
                              child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 50,
                                child: TextField(
                                    style: textStyle,
                                    textAlign: TextAlign.center,
                                    controller: _tempoController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly
                                    ],
                                    onSubmitted: (str) {
                                      int newBPM = int.parse(str);
                                      // #1
                                      BlocProvider.of<SettingsCubit>(context)
                                          .updateBPM(newBPM);
                                    }),
                              ),
                              Text("bpm", style: textStyle),
                            ],
                          ));
                        }),

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
    );
  }
}

/// [BeatIndicators] allows toggling enabled beat indicators
class BeatIndicators extends StatelessWidget {
  const BeatIndicators({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, ChronosSettings>(
        buildWhen: (prev, curr) =>
            prev.blinkEnabled != curr.blinkEnabled ||
            prev.vibrateEnabled != curr.vibrateEnabled ||
            prev.clickEnabled != curr.clickEnabled ||
            prev.color1 != curr.color1 ||
            prev.color2 != curr.color2,
        builder: (context, settings) {
          Color darker = settings.color2d;
          Color lighter = settings.color2l;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              /// blink indicator
              IconButton(
                onPressed: () {
                  BlocProvider.of<SettingsCubit>(context).toggleBlinkEnabled();
                },
                icon: settings.blinkEnabled
                    ? Icon(Icons.lightbulb, color: lighter)
                    : Icon(Icons.lightbulb_outline, color: darker),
              ),

              /// vibrate indicator, only show if device can vibrate
              if (settings.vibrateAvailable)
                IconButton(
                  onPressed: () {
                    BlocProvider.of<SettingsCubit>(context)
                        .toggleVibrateEnabled();
                  },
                  icon: settings.vibrateEnabled
                      ? Icon(Icons.vibration, color: lighter)
                      : Icon(Icons.vibration, color: darker),
                ),

              /// click indicator
              IconButton(
                onPressed: () {
                  BlocProvider.of<SettingsCubit>(context).toggleClickEnabled();
                },
                icon: settings.clickEnabled
                    ? Icon(Icons.volume_up_rounded, color: lighter)
                    : Icon(Icons.volume_off_rounded, color: darker),
              ),
            ],
          );
        });
  }
}
