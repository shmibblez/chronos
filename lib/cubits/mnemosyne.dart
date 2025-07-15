import 'dart:async';
import 'dart:developer';

import 'package:audioplayers/audioplayers.dart';
import 'package:chronos/chronos_constants.dart';
import 'package:chronos/cubits/hephaestus.dart';
import 'package:chronos/cubits/hermes.dart';
import 'package:chronos/main.dart';
import 'package:chronos/preset_drawer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';
import 'package:vibration/vibration.dart';
import 'package:path/path.dart' as p;

class Mnemosyne {
  static final Mnemosyne _mnemosyne = Mnemosyne._();

  factory Mnemosyne() {
    return _mnemosyne;
  }

  Mnemosyne._();

  Database? _db;
  StoreRef<String, dynamic>? _prefStore;
  StoreRef<String, dynamic>? _presetStore;
  List<AudioPlayer>? audioPlayers;
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

    DatabaseFactory dbFactory = databaseFactoryIo;
    final appDocDir = await getApplicationDocumentsDirectory();
    _db = await dbFactory.openDatabase(
      p.join(appDocDir.path, "chronos.db"),
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

    // begin loading
    var l = await lastPreset();

    // setup audio players
    _updateAudioPlayers(l.beatsPerBar);
    // todo: when support for more or custom sounds is added, load file to audio cache:
    //  audioPlayer?.audioCache = AudioCache();
    //  audioPlayer?.audioCache.load(fileName)
    // // todo: if load fails then use default asset, it probably means file doesn't exist

    // load last toolbox, depends on [audioPlayers]
    var t = await lastToolbox();

    var d = InitialData(
      toolbox: t,
      preset: l, // can't be null since default is included
      audioPlayers: audioPlayers!,
    );

    return d;
  }

  /// loads last toolbox
  Future<Toolbox> lastToolbox() async {
    var prefs = await _prefStore!.record("prefs").get(_db!);
    // get sound file path
    // todo: fix sembast file structure, also add selected sound path, could be asset or other.
    //  this will get messy when exporting presets, make sure to have multiple default sounds,
    //  if sound not default or available use default (means need to check if file exists)
    //  this could be handled in audio player, in error listener if file not found, use default sound
    // final ByteData bytes = await rootBundle.load(prefs["sound"]); // #7
    // load asset into soundpool
    final Source soundSource = AssetSource("sounds/wood_sound.wav");
    for (AudioPlayer ap in audioPlayers!) {
      await ap.audioCache.load("sounds/wood_sound.wav");
    }
    // check if can vibrate
    final bool canVibrate = await Vibration.hasVibrator();

    var t = Toolbox(
      color1: Color(ChronosConstants.defPrefs["color1"] as int),
      color2: Color(ChronosConstants.defPrefs["color2"] as int),
      // color1: Color(prefs["color1"] as int),
      // color2: Color(prefs["color2"] as int),
      blinkEnabled: prefs["blinkEnabled"],
      vibrateEnabled: prefs["vibrateEnabled"],
      clickEnabled: prefs["clickEnabled"],
      vibrateAvailable: canVibrate && !kIsWeb,
      soundSource: soundSource,
    );

    return t;
  }

  /// loads last preset used
  /// Preset will be null if default not included and none exist yet
  Future<Preset> lastPreset() async {
    final finder = Finder(
      sortOrders: [SortOrder("millis", false)],
      // whether to include default preset or not
      filter: null,
      limit: 1,
    );
    final lastPresetSnap =
        (await _presetStore!.findFirst(_db!, finder: finder));
    final lastPreset = (lastPresetSnap == null
        ? await newPreset()
        : Preset.fromJSON(lastPresetSnap.key, lastPresetSnap.value));

    // if last preset exists, should be first in list,
    // if not there, insert
    if (_presets!.isEmpty || _presets!.first.key != lastPreset.key) {
      log("last preset added to _presets, key: ${lastPreset.key} -- [Mnemosyne.lastPreset]");
      _presets!.insert(0, lastPreset);
    }
    return lastPreset;
  }

  /// creates new preset with random key
  Future<Preset> newPreset() async {
    // generate new preset json
    var json = Preset.newPresetJSON();
    // add new preset to db
    String key = await _presetStore!.add(_db!, json);
    // add new preset to cached list and return
    Preset newPreset = Preset.fromJSON(key, json);
    _presets!.insert(0, newPreset);
    log("new preset added to _presets, key: ${newPreset.key} -- [Mnemosyne.newPreset]");
    log("cached presets:");
    printPresetKeys(presets);
    log("presets in db:");
    printPresetKeys(await getAllPresets());
    return newPreset;
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
      // exclude default
      filter: Filter.notEquals(Field.key, "default"),
    );
    var presets = (await _presetStore!.find(_db!, finder: finder)).map<Preset>(
      (e) => Preset.fromJSON(e.key, e.value),
    );
    _presets!.addAll(presets.toList());
  }

  Future<List<Preset>> getAllPresets() async {
    var finder = Finder(
      sortOrders: [SortOrder("millis", false)],
      filter: Filter.notEquals(Field.key, "default"),
    );
    var presets = (await _presetStore!.find(_db!, finder: finder)).map<Preset>(
      (e) => Preset.fromJSON(e.key, e.value),
    );
    return presets.toList();
  }

  Future<void> _updateAudioPlayers(int bpb) async {
    audioPlayers ??= List.empty(growable: true);
      // if smaller add players
    while (audioPlayers!.length < bpb) {
      audioPlayers!.add(AudioPlayer());
      await audioPlayers!.last.setReleaseMode(ReleaseMode.stop);
    }
    if (audioPlayers!.length > bpb - 1) {
      // for sublist, start inclusive, end exclusive
      final removed = audioPlayers!.sublist(bpb, audioPlayers!.length);
      audioPlayers = audioPlayers!.sublist(0,bpb);
      for (final ap in removed) {
        await ap.dispose();
      }
    }
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
    Preset updated = Preset(
      key: key ?? old.key,
      name: name ?? old.name,
      bpm: bpm ?? old.bpm,
      beatsPerBar: beatsPerBar ?? old.beatsPerBar,
      barNote: barNote ?? old.barNote,
      millis: millis ?? old.millis,
      notes: notes ?? old.notes,
    );
    _updateAudioPlayers(updated.beatsPerBar);
    // if preset not default, find index and then ...
    int i = _presets!.indexWhere((element) => element.key == old.key);
    if (i >= 0 && i < _presets!.length) {
      // ... move to first in list
      _presets!.removeAt(i);
      _presets!.insert(0, updated);
      log("updated & moved preset to first in _presets, key: ${updated.key} -- [Mnemosyne.updatePreset]");
    }
    // update db
    await _presetStore!.record(old.key).update(_db!, Preset.toJSON(updated));
    log("cached presets:");
    printPresetKeys(presets);
    log("presets in db:");
    printPresetKeys(await getAllPresets());
  }

  /// updates bpm at intervals (after a while), not immediately
  /// [preset] has not been updated yet
  void updateBPMThrottled(int bpm, Preset preset) {
    // add preset with updated bpm to pending updates
    _pendingBPMUpdates![preset.key] = Preset.from(preset, bpm: bpm);

    // reset future if needed
    _updateBPMs ??= Future.delayed(
      const Duration(milliseconds: 1500),
      () async {
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
    log("deleting preset at indx $i -- [deletePreset]");
    if (i >= 0) _presets!.removeAt(i);
    // update db
    await _presetStore!.record(p.key).delete(_db!);
    log("cached presets:");
    printPresetKeys(presets);
    log("presets in db:");
    printPresetKeys(await getAllPresets());
  }
}
