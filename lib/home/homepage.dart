// todo: homepage will have:
//  - metronome in center
//  - settings icon top right
//  - preset name at the top with indicator options below (above metronome)
//  - bpm, beats per bar editors below metronome
//  - notes at the bottom (2 lines max) with edit and view icons at the end
//    - when edit pressed, opaque dialog for editing pops up, playback paused
//    - when view is pressed, semi-transparent dialog only showing note pops up (scrollable), playback continues

import 'package:flutter/material.dart';

class Homepage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return HomepageState();
  }
}

class HomepageState extends State {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // settings and help icons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            spacing: 8,
            children: [
              // settings icon
              GestureDetector(
                onTap: () {
                  // todo: go to settings screen
                },
                child: Icon(Icons.settings),
              ),
              // help icon
              GestureDetector(
                onTap: () {
                  // todo: show help dialog
                },
                child: Icon(Icons.help_outline),
              )
            ],
          ),
          // todo: title editor
          //  - move focus node logic here for all items (for saving preset)
          //  - make text editor components have darker background
          //  - when not focused, text grayish
          //  - when focused, text white
          // todo: change how presets are handled
          //  - no default preset
          //  - if last preset deleted, or no preset exists, create preset with title "Default"
          //  - preset shared by mnemosyne can be null, if null show loading page and add new default preset
        ],
      ),
    );
  }
}
