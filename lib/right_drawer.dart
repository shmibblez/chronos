import 'package:chronos/convenience_widgets.dart';
import 'package:chronos/cubits/hephaestus.dart';
import 'package:chronos/cubits/hermes.dart';
import 'package:chronos/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The [RightDrawer] is [Hephaestus]'s domain, and is where the user can edit app
/// layout settings and indicators through metronome options like:
/// - play/pause
/// - enabled indicators
/// - color
///
/// these options are independent from [Preset]s, which is why they're in separate drawers
class RightDrawer extends StatefulWidget {
  const RightDrawer({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _RightDrawerState();
}

class _RightDrawerState extends State<RightDrawer> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<Hephaestus, Toolbox>(
        // rebuild whole tree only if any colors change
        buildWhen: (prev, curr) =>
            prev.color1 != curr.color1 || prev.color2 != curr.color2,
        builder: (context, settings) {
          final Color backgroundColor = settings.color1l;
          final Color textColor =
              settings.visibleTextColor(backgroundColor, settings.color2);
          final Color dividerColor = settings.color2d;
          final TextStyle textStyle = TextStyle(color: textColor);
          return Drawer(
            // drawer background color is lighter than metronome disabled color
            backgroundColor: backgroundColor,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: DefaultTextStyle(
                style: textStyle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    /// title text
                    const Text(
                      "Metronome Options",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    Divider(color: dividerColor),

                    /// play/pause
                    Row(children: const [
                      Expanded(
                        child: Text("play/pause", textAlign: TextAlign.start),
                      ),
                      HelpButton(
                        msg:
                            "You can play or pause metronome playback by tapping on the metronome screen.",
                      ),
                    ]),

                    Divider(color: dividerColor),

                    /// enabled indicators
                    Row(
                      children: const [
                        Expanded(child: Text("indicators")),
                        Expanded(child: BeatIndicators()),
                        HelpButton(
                          msg:
                              "Here you can toggle the 3 beat indicators that we came up with: blinking (visual), vibration (haptic) and clicking (auditory). These can also be changed at the bottom of the metronome screen",
                        ),
                      ],
                    ),

                    Divider(color: dividerColor),
                  ],
                ),
              ),
            ),
          );
        });
  }
}
