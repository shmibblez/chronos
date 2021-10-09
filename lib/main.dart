import 'package:chronos/cubits.dart';
import 'package:chronos/zeus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  runApp(const Root());
}

/// Some potential improvements
/// - load last used settings, fall back to defaults in [ChronosConstants]

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
                        beats: 4,
                        measure: 4,
                        color1: Colors.black87,
                        color2: Colors.white70,
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
        endDrawer: RightDrawer(),
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
      ),
    );
  }
}

/// The [RightDrawer] contains metronome settings like
/// - play/pause
/// - tempo
/// - bars
/// - meter
/// - enabled indicators
/// - color
/// FIXME: left off adding settings
class RightDrawer extends StatelessWidget {
  const RightDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          const Text("Metronome Options"), // title text
          // play/pause
          Row(
            children: [
              const Text("play/pause"),
              IconButton(
                  onPressed: () {
                    // show dialog explainig tap to play/pause
                  },
                  icon: const Icon(Icons.help)),
            ],
          ),
          // tempo
          Row(
            children: [
              const Text("tempo"),
              BlocBuilder<SettingsCubit, ChronosSettings>(
                  builder: (_, settings) {
                final TextEditingController _tempoController =
                    TextEditingController(text: "${settings.bpm} bpm}");
                return TextField(
                  controller: _tempoController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onSubmitted: (str) {
                    int newBPM = int.parse(str);
                    // TODO: if bpm outside min & max bounds, show message and set to min or max
                    BlocProvider.of<SettingsCubit>(context).updateBPM(newBPM);
                  },
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}
