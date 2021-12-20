import 'dart:async';
import 'dart:developer';

import 'package:chronos/cubits/hephaestus.dart';
import 'package:chronos/cubits/hermes.dart';
import 'package:chronos/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soundpool/soundpool.dart';
import 'package:tekartik_app_flutter_sembast/sembast.dart';
import 'package:vibration/vibration.dart';

class Mnemosyne {
  static final Mnemosyne _mnemosyne = Mnemosyne._();

  factory Mnemosyne() {
    return _mnemosyne;
  }

  Mnemosyne._();

  Database? _db;
  StoreRef<String, dynamic>? _prefStore;
  StoreRef<String, dynamic>? _presetStore;
  Soundpool? soundpool;
  List<Preset>? _presets;
  Map<String, Preset>? _pendingBPMUpdates;
  Future<void>? _updateBPMs;

  List<Preset> get presets => _presets ?? [];

  /// prepare db
  ///
  /// must be called before anything else (await at app start)
  Future<InitialData> awaken() async {
    _prefStore = stringMapStoreFactory.store("prefs");
    _presetStore = stringMapStoreFactory.store("presets");
    _presets = [];
    _pendingBPMUpdates = {};

    DatabaseFactory dbFactory = getDatabaseFactory();
    _db = await dbFactory.openDatabase(
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

    soundpool = Soundpool.fromOptions();
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
    var prefs = await _prefStore!.record("prefs").get(_db!);
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
    var lastPreset = (await _presetStore!.findFirst(_db!, finder: finder));

    return lastPreset == null
        ? null
        : Preset.fromJSON(lastPreset.key, lastPreset.value);
  }

  Future<Preset> defaultPreset() async {
    var defaultPreset = await _presetStore!.record("default").getSnapshot(_db!);
    return Preset.fromJSON(defaultPreset!.key, defaultPreset.value!);
  }

  /// creates new preset with random key
  Future<Preset> newPreset() async {
    var json = Preset.newPresetJSON;
    String key = await _presetStore!.add(_db!, json);
    return Preset.fromJSON(key, json);
  }

  /// load some presets
  /// if `exclude` set, excludes preset from search results
  Future<void> loadPresets({
    int limit = 20,
  }) async {
    var finder = Finder(
      sortOrders: [SortOrder("millis", false)],
      offset: _presets!.length,
      limit: limit,
      filter: Filter.and([
        // exclude default
        Filter.notEquals(Field.key, "default"),
      ]),
    );
    var presets = (await _presetStore!.find(_db!, finder: finder)).map<Preset>(
      (e) => Preset.fromJSON(e.key, e.value),
    );
    _presets!.addAll(presets.toList());
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
    log("Mnemosyne.updatePreset() called");
    Preset updated = Preset(
      key: key ?? old.key,
      name: name ?? old.name,
      bpm: bpm ?? old.bpm,
      beatsPerBar: beatsPerBar ?? old.beatsPerBar,
      barNote: barNote ?? old.barNote,
      millis: millis ?? old.millis,
      notes: notes ?? old.notes,
    );
    if (!old.isDefault) {
      int i = _presets!.indexWhere((element) => element.key == old.key);
      if (i > 0 && i < _presets!.length) {
        // move updated preset to first
        _presets!.removeAt(i);
        _presets!.insert(0, updated);
      }
    }
    // update db
    Map map = Preset.toJSON(updated);
    await _presetStore!.record(old.key).update(_db!, map);
  }

  /// updates bpm after a while, not immediately
  /// [preset] has not been updated yet
  void updateBPMThrottled(int bpm, Preset preset) {
    log("Mnemosyne.updateBPMThrottled: queued");
    // add preset with updated bpm to pending updates
    _pendingBPMUpdates![preset.key] = Preset.from(preset, bpm: bpm);

    // reset future if needed
    _updateBPMs ??= Future.delayed(
      const Duration(milliseconds: 1500),
      () async {
        log("Mnemosyne.updateBPMThrottled: values saved");
        // store keys and vals
        final vals =
            _pendingBPMUpdates!.values.map((p) => {"sig": p.sig()}).toList();
        final keys = _pendingBPMUpdates!.keys.toList();
        // reset pending updates in case new entry added while updating
        // should take less than future duration
        _pendingBPMUpdates = {};
        _updateBPMs = null;
        // update records
        final records = _presetStore!.records(keys);
        await records.update(_db!, vals);
      },
    );
  }

  /// delete preset from db
  Future<void> deletePreset(Preset p) async {
    // update list
    // find indx of preset to remove
    int i = _presets!.indexWhere((element) => element.key == p.key);
    // remove from list
    if (i >= 0) _presets!.removeAt(i);
    // update db
    await _presetStore!.record(p.key).delete(_db!);
  }
}
