import 'package:chronos/cubits.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The [LeftDrawer] contains metronome presets
/// presets store the following
/// - preset name
/// - notes (so user can store progress and write down tempos)
/// - tempo
/// - sound file (defaults to default)
/// - date last used
///
/// selected preset is shown, all values are shown in [TextField]s so can be easily edited
///
/// list of recently used presets is shown below selected preset, enough to not overflow
///
/// button to see all presets is shown, when presed goes to new page where all presets are
/// shown, ordered by last used

class LeftDrawer extends StatefulWidget {
  const LeftDrawer({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _LeftDrawerState();
}

class _LeftDrawerState extends State<LeftDrawer> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, ChronosSettings>(
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
                      "Presets",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    Divider(color: dividerColor),
                  ],
                ),
              ),
            ),
          );
        });
  }
}
