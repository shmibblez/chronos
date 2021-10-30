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
      onVersionChanged: (database, oldVer, newVer) async {
        if (oldVer <= 0) {
          // db created, set default values
          // default prefs
          await _prefStore!.record("prefs").put(database, {
            "color1": Colors.black87.value,
            "color2": Colors.white70.value,
            "blinkEnabled": true,
            "vibrateEnabled": false,
            "clickEnabled": true,
            // sound file selected
            "sound": "sounds/wood_sound.wav",
          });

          debugPrint("prefstore: $_prefStore");
          // default presets
          await _presetStore!.record("default").put(
                database,
                Preset.toJSON(
                  Preset(
                    key: "default",
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
    // begin loading
    var t = toolbox();
    var l = lastPreset();

    var d = InitialData(
      toolbox: await t,
      preset: (await l)!, // can't be null since default is included
      soundpool: soundpool!,
    );

    debugPrint("initial data ready, returning");

    return d;
  }

  Future<Toolbox> toolbox() async {
    var prefs = await _prefStore!.record("prefs").get(db!);
    // load sound asset
    final ByteData bytes = await rootBundle.load(prefs["sound"]); // #7
    // load asset into soundpool
    final int soundId = await soundpool!.load(bytes);
    // check if can vibrate
    final bool canVibrate = await Vibration.hasVibrator() ?? false;

    var t = Toolbox(
      color1: Color(prefs["color1"] as int),
      color2: Color(prefs["color2"] as int),
      blinkEnabled: prefs["blinkEnabled"],
      vibrateEnabled: prefs["vibrateEnabled"],
      clickEnabled: prefs["clickEnabled"],
      vibrateAvailable: canVibrate && !kIsWeb,
      soundId: soundId,
    );

    debugPrint("toolbox: $t");

    return t;
  }

  /// Preset will be null if default not included and none exist yet
  Future<Preset?> lastPreset({includeDefault = true}) async {
    var finder = Finder(
        sortOrders: [SortOrder("millis")],
        filter: includeDefault ? null : Filter.notEquals("name", "default"));
    var lastPreset = (await _presetStore!.findFirst(db!, finder: finder))!;

    return Preset.fromJSON(lastPreset.key, lastPreset.value);
  }

  Future<Preset> defaultPreset() async {
    var defaultPreset =
        (await _presetStore!.record("default").getSnapshot(db!))!;
    return Preset.fromJSON(defaultPreset.key, defaultPreset.value);
  }

  Future<Preset> newPreset() async {
    var json = Preset.newPresetJSON;
    String key = await _presetStore!.add(db!, json);
    return Preset.fromJSON(key, json);
  }
}
