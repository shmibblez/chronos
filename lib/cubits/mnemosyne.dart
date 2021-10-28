import 'dart:async';

import 'package:chronos/cubits/hephaestus.dart';
import 'package:chronos/cubits/hermes.dart';
import 'package:chronos/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sembast/sembast.dart';
import 'package:soundpool/soundpool.dart';
import 'package:tekartik_app_flutter_sembast/sembast.dart';
import 'package:vibration/vibration.dart';

class Mnemosyne {
  static final Mnemosyne _mnemosyne = Mnemosyne._();

  factory Mnemosyne() {
    return _mnemosyne;
  }

  Mnemosyne._();

  Database? db;
  StoreRef<String, dynamic>? _prefStore;
  StoreRef<String, dynamic>? _presetStore;
  Soundpool? soundpool;

  /// prepare db
  ///
  /// must be called before anything else (await at app start)
  Future<InitialData> awaken() async {
    _prefStore = stringMapStoreFactory.store("prefs");
    _presetStore = stringMapStoreFactory.store("presets");

    DatabaseFactory dbFactory = getDatabaseFactory();
    db = await dbFactory.openDatabase(
      "chronos.db",
      version: 1,
      onVersionChanged: (database, oldVer, newVer) {
        if (oldVer <= 0) {
          // db created, set default values
          // default prefs
          _prefStore!.record("prefs").put(database, {
            "color1": Colors.black87.value,
            "color2": Colors.white70.value,
            "blinkEnabled": true,
            "vibrateEnabled": false,
            "clickEnabled": true,
            // sound file selected
            "sound": "sounds/wood_sound.wav",
          });
          // default presets
          _presetStore!.record("default").put(
                database,
                Preset.toJSON(
                  Preset(
                    name: "default",
                    bpm: 100,
                    beatsPerBar: 4,
                    barNote: 4,
                    millis: DateTime.now().millisecondsSinceEpoch,
                  ),
                ),
                // timestamp last used
              );
        }
      },
    );

    soundpool = Soundpool.fromOptions();
    return InitialData(
      toolbox: await _toolbox,
      preset: await _lastPreset,
      soundpool: soundpool!,
    );
  }

  Future<Toolbox> get _toolbox async {
    var prefs = await _prefStore!.record("prefs").get(db!);

    final ByteData bytes = await rootBundle.load(prefs["sound"]); // #7
    final int soundId = await soundpool!.load(bytes);
    return Toolbox(
      color1: prefs["color1"],
      color2: prefs["color2"],
      blinkEnabled: prefs["blinkEnabled"],
      vibrateEnabled: prefs["vibrateEnabled"],
      clickEnabled: prefs["clickEnabled"],
      vibrateAvailable: (await Vibration.hasVibrator() ?? false) && !kIsWeb,
      soundId: soundId,
    );
  }

  Future<Preset> get _lastPreset async {
    var finder = Finder(sortOrders: [SortOrder("millis")]);
    var lastPreset =
        (await _presetStore!.findFirst(db!, finder: finder))!.value;

    return Preset.fromJSON(lastPreset);
  }
}
