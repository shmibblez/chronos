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
          await _prefStore!.record("prefs").put(
                database,
                ChronosConstants.defPrefs,
              );

          // default preset
          await _presetStore!.record("default").put(
                database,
                ChronosConstants.defPreset,
              );
        }
      },
    );

    soundpool = Soundpool.fromOptions(options: SoundpoolOptions.kDefault);
    // begin loading
    var t = lastToolbox();
    var l = lastPreset();

    var d = InitialData(
      toolbox: await t,
      preset: (await l)!, // can't be null since default is included
      soundpool: soundpool!,
    );
    return d;
  }

  /// loads last toolbox
  Future<Toolbox> lastToolbox() async {
    var prefs = await _prefStore!.record("prefs").get(db!);
    // get sound file path
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
      presetsEnabled: prefs["presetsEnabled"],
    );

    return t;
  }

  /// loads last preset used
  /// Preset will be null if default not included and none exist yet
  Future<Preset?> lastPreset({includeDefault = true}) async {
    var finder = Finder(
      sortOrders: [SortOrder("millis", false)],
      // whether to include default preset or not
      filter: includeDefault ? null : Filter.notEquals("name", "default"),
      limit: 1,
    );
    var lastPreset = (await _presetStore!.findFirst(db!, finder: finder));

    return lastPreset == null
        ? null
        : Preset.fromJSON(lastPreset.key, lastPreset.value);
  }

  Future<Preset> defaultPreset() async {
    var defaultPreset = await _presetStore!.record("default").getSnapshot(db!);
    return Preset.fromJSON(defaultPreset!.key, defaultPreset.value!);
  }

  /// creates new preset with random key
  Future<Preset> newPreset() async {
    var json = Preset.newPresetJSON;
    String key = await _presetStore!.add(db!, json);
    return Preset.fromJSON(key, json);
  }

  /// load some presets
  /// if `exclude` set, excludes preset from search results
  Future<List<Preset>> loadPresets({
    int offset = 0,
    int limit = 20,
    Preset? exclude,
    excludeDefault = true,
  }) async {
    var finder = Finder(
      sortOrders: [SortOrder("millis", false)],
      offset: offset,
      limit: limit,
      filter: Filter.and([
        // if (exclude != null) Filter.notEquals(Field.key, exclude.key),
        if (excludeDefault) Filter.notEquals(Field.key, "default"),
      ]),
    );
    var presets = (await _presetStore!.find(db!, finder: finder)).map<Preset>(
      (e) => Preset.fromJSON(e.key, e.value),
    );

    return presets.toList();
  }

  /// send update to db with values given
  Future<void> updatePreset(
    Preset old, {
    String? key,
    String? name,
    int? bpm,
    int? beatsPerBar,
    int? barNote,
    int? millis,
    String? notes,
  }) async {
    Map updated = Preset.toJSON(Preset(
      key: key ?? old.key,
      name: name ?? old.name,
      bpm: bpm ?? old.bpm,
      beatsPerBar: beatsPerBar ?? old.beatsPerBar,
      barNote: barNote ?? old.barNote,
      millis: millis ?? old.millis,
      notes: notes ?? old.notes,
    ));
    // update val
    var val = await _presetStore!.record(old.key).update(db!, updated);
    debugPrint("updated db entry: \n$val");
  }

  /// delete preset from db
  Future<void> deletePreset(Preset p) async {
    await _presetStore!.record(p.key).delete(db!);
  }
}
