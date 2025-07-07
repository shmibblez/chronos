# Chronos

Named after the god of time, this is the repo of a flutter metronome app! Chronos places heavy emphasis on access to components by gestures, and metronome presets can be persisted locally. Sometimes I'm learning a couple songs on guitar at the same time and need to switch between bpm and beats per measure quickly, and it's tough to memorize all bpms and change the metronome, which is why this app was created.

## Code Structure

This project uses the flutter BLoC pattern for data management, and given the async nature of a metronome, it makes sense. The base cubit emits time-based events to notify listeners when they should update ui components; this base class is called Chronos. Chronos' reputation precedes him, so he is now in charge of emitting time events based on the user's set bpm and beats per measure. He also times sound clicks and device vibration in case those options are enabled.

There are also 3 more cubits that do stuff: Hephaestus, Mnemosyne, and Hermes. Their jobs are as follows:

### Mnemosyne

Mnemosyne, goddess of memory, is in charge of local storage, and parsing stored data into user-friendly objects. She stores user preferences with the help of Hephaestus, and she also handles persistence of a .json file that stores all of a user's metronome presets. Each preset has a name, bpm, beats per measure, and an optional notes section.

### Hephaestus

Hephaestus is a master of craft, his true power in this scope is with the power of his toolbox, which stores app settings like theme colors, metronome sound used, active beat indicators (blink, vibrate, sound), and whether presets are enabled.

### Hermes

Hermes, messenger of the gods, is aware of the currently loaded presets provided by Mnemosyne, and so he fullfills his task of handing them over to ui widgets which display data to the user. He has also stolen Zeus' lighting bolt, which is then used to light up the corresponding beat measure, or to blink the screen in case the user has enabled that option.
