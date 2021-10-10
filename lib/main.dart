import 'package:chronos/cubits.dart';
import 'package:chronos/zeus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'drawers.dart';

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
  static const int maxBPM = 400;
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
    return GestureDetector(
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
      child: Scaffold(
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
        body: const Zeus(),

        /// FIXME: bottomSheet overlaps scaffold body, need to place in column or something else. Also
        bottomSheet: FractionallySizedBox(
          heightFactor: 1 / 10,
          child: BlocBuilder<SettingsCubit, ChronosSettings>(
              builder: (_, settings) {
            Color darker = settings.color2d;
            Color lighter = settings.color2l;
            return Container(
              color: settings.color1d,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  /// blink indicator
                  IconButton(
                    onPressed: () {
                      BlocProvider.of<SettingsCubit>(context)
                          .toggleBlinkEnabled();
                    },
                    icon: settings.blinkEnabled
                        ? Icon(Icons.lightbulb, color: lighter)
                        : Icon(Icons.lightbulb_outline, color: darker),
                  ),

                  /// vibrate indicator
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
                      BlocProvider.of<SettingsCubit>(context)
                          .toggleClickEnabled();
                    },
                    icon: settings.clickEnabled
                        ? Icon(Icons.hearing, color: lighter)
                        : Icon(Icons.hearing_disabled, color: darker),
                  ),
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
                  //   ),
                  // ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
