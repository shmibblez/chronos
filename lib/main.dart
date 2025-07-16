import 'dart:developer';

import 'package:audioplayers/audioplayers.dart';
import 'package:chronos/chronos_constants.dart';
import 'package:chronos/cubits/chronos.dart';
import 'package:chronos/cubits/hephaestus.dart';
import 'package:chronos/cubits/hermes.dart';
import 'package:chronos/cubits/mnemosyne.dart';
import 'package:chronos/home/homepage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  runApp(const Root());
}

class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black87,
      body: Center(
        child: CircularProgressIndicator(color: Colors.red),
      ),
    );
  }
}

class InitialData {
  InitialData({
    required this.toolbox,
    required this.preset,
    required this.audioPlayers,
  });
  final Toolbox toolbox;
  final Preset preset;
  final List<AudioPlayer> audioPlayers;
}

class Root extends StatelessWidget {
  Future<InitialData> _initialSetup() async {
    // #7
    return await Mnemosyne().awaken();
  }

  const Root({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        theme: ChronosConstants.theme,
        home: SafeArea(
          child: FutureBuilder<InitialData>(
            future: _initialSetup(),
            builder: (context, snap) {
              // if not ready yet, show loading screen
              log("Root.build, snap.connectionState: ${snap.connectionState}");

              if (snap.hasError) {
                log("Root.build, error: ${snap.error}\ntrace: ${snap.stackTrace}");
              }

              // if future complete, use snap data
              if (snap.hasData) {
                return MultiBlocProvider(
                  providers: [
                    BlocProvider(
                      lazy: false,
                      create: (_) {
                        log("Creating Hephaestus, snap.data.toolbox: ${snap.data?.toolbox}");
                        return Hephaestus(snap.data!.toolbox);
                      },
                    ),
                    BlocProvider(
                      lazy: false,
                      create: (_) => Hermes(snap.data!.preset),
                    ),
                    BlocProvider(
                      lazy: false,
                      create: (BuildContext context1) => Chronos(
                        context: context1,
                      ),
                    ),
                  ],
                  child: Homepage(key: super.key),
                );
              }

              // if loading or error show loading page
              return const LoadingPage();
            },
          ),
        ),
      );
}

// todo: reference below for implementing blink
