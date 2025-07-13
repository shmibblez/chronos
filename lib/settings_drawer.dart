import 'package:chronos/convenience_widgets.dart';
import 'package:chronos/cubits/hephaestus.dart';
import 'package:chronos/cubits/hermes.dart';
import 'package:chronos/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The [SettingsDrawer] is [Hephaestus]'s domain, and is where the user can edit app
/// layout settings and indicators through metronome options like:
/// - play/pause
/// - enabled indicators
/// - color
///
/// these options are independent from [Preset]s, which is why they're in separate drawers
class SettingsDrawer extends StatefulWidget {
  const SettingsDrawer({super.key});

  @override
  State<StatefulWidget> createState() => _SettingsDrawerState();
}

class _SettingsDrawerState extends State<SettingsDrawer> {
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
                    const Row(children: [
                      Expanded(
                        child: Text("play/pause", textAlign: TextAlign.start),
                      ),
                      HelpButton(
                        msg:
                            "Play or pause metronome playback by tapping on the metronome screen.",
                      ),
                    ]),

                    Divider(color: dividerColor),

                    /// enabled indicators
                    const Row(
                      children: [
                        Expanded(child: Text("indicators")),
                        HelpButton(
                          msg:
                              "Here you can toggle the 3 beat indicators that we came up with:\nblinking (visual), vibration (haptic) and clicking (auditory). These can also be changed at the bottom of the metronome screen",
                        ),
                      ],
                    ),
                    const BeatIndicators(),

                    Divider(color: dividerColor),

                    /// export presets (coming soon)
                    /// #12
                    Row(
                      children: [
                        const Expanded(child: Text("export presets")),
                        Expanded(
                            child: ElevatedButton(
                          child: const Text("coming soon"),
                          onPressed: () {},
                        )),
                        const HelpButton(
                          msg:
                              "We're currently working on a way to export/import your presets to/from a json file",
                        ),
                      ],
                    ),

                    Divider(color: dividerColor),

                    /// import presets (coming soon)
                    /// #12
                    Row(
                      children: [
                        const Expanded(child: Text("import presets")),
                        Expanded(
                            child: ElevatedButton(
                          child: const Text("coming soon"),
                          onPressed: () {},
                        )),
                        const HelpButton(
                          msg:
                              "We're currently working on a way to export/import your presets to/from a json file",
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        });
  }
}
