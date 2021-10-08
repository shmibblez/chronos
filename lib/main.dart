import 'package:chronos/cubits.dart';
import 'package:chronos/zeus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  runApp(const Root());
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
      // change tempo based on
      onVerticalDragUpdate: (DragUpdateDetails details) {
        // here change tempo, show new tempo in bottom sheet
        // debugPrint();
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
        endDrawer: Drawer(
          child: ListView(
              // metronome settings (play/pause, tempo, # bars, display options: |blink|sound|vibrate|)
              ),
        ),
        onDrawerChanged: (open) {
          if (!open) {
            BlocProvider.of<Chronos>(context).play();
            debugPrint("drawer closed");
          }
        },
        onEndDrawerChanged: (open) {
          if (!open) {
            BlocProvider.of<Chronos>(context).play();
            debugPrint("end drawer closed");
          }
        },
        body: const Zeus(),
      ),
    );
  }
}
