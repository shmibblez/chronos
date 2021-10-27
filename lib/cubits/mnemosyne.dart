import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Mnemosyne, the godess of memory, is the primary source of information, as
/// she's in direct contact with the preset database.
///
/// her state signals whether she's ready or not:
/// - if false, database is setting up
/// - if true, database is ready
class Mnemosyne extends Cubit<bool> {
  Mnemosyne(bool ready) : super(ready) {
    if (ready) return;
    // TODO: load database here
    if (kIsWeb) {
    } else {}
  }
}
