//  - make blink based on progress also, reference metronome widget
import 'package:chronos/cubits/hephaestus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// #6 for beat indicators below
/// [TopIcons] allows toggling enabled beat indicators
class TopIcons extends StatelessWidget {
  const TopIcons({
    super.key,
    required this.openDrawer,
  });

  final void Function() openDrawer;

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
        return // settings and help icons
            Row(
          mainAxisAlignment: MainAxisAlignment.end,
          spacing: 12,
          children: [
            // menu item
            GestureDetector(
              onTap: openDrawer,
              child: Icon(Icons.menu_rounded, color: Colors.white),
            ),

            Spacer(),

            /// blink indicator
            GestureDetector(
              onTap: () {
                BlocProvider.of<Hephaestus>(context).toggleBlinkEnabled();
              },
              child: Icon(
                settings.blinkEnabled
                    ? Icons.lightbulb
                    : Icons.lightbulb_outline,
                color: settings.blinkEnabled ? Colors.white : Colors.white54,
              ),
            ),

            /// vibrate indicator, only show if device can vibrate
            GestureDetector(
              onTap: () {
                BlocProvider.of<Hephaestus>(context).toggleVibrateEnabled();
              },
              child: Icon(
                settings.vibrateEnabled
                    ? Icons.vibration_rounded
                    : Icons.phone_iphone_sharp,
                color: settings.vibrateEnabled ? Colors.white : Colors.white54,
              ),
            ),

            /// click indicator
            GestureDetector(
              onTap: () {
                BlocProvider.of<Hephaestus>(context).toggleClickEnabled();
              },
              child: Icon(
                settings.clickEnabled
                    ? Icons.volume_up_rounded
                    : Icons.volume_off_rounded,
                color: settings.clickEnabled ? Colors.white : Colors.white54,
              ),
            ),

            Spacer(),

            // settings icon
            GestureDetector(
              onTap: () {
                // todo: go to settings screen
              },
              child: Icon(Icons.settings, color: Colors.white),
            ),
            // help icon
            GestureDetector(
              onTap: () {
                // todo: show help dialog
              },
              child: Icon(Icons.help_outline, color: Colors.white),
            )
          ],
        );
      },
    );
  }
}
