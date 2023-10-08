// This file is a part of network_cache_manager (https://github.com/alexmercerind/network_cache_manager).
//
// Copyright © 2023 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the LICENSE file.

/// {@template logger}
///
/// Logger
/// ------
/// A minimal implementation for level based logging.
///
/// {@endtemplate}
class Logger {
  /// [Logger] instance.
  static final Logger instance = Logger._();

  static const int kErrorLevel = 0;
  static const int kInfoLevel = 1;
  static const int kDebugLevel = 2;
  static const int kVerboseLevel = 3;

  // TODO:

  /// Current logging level.
  int level = 4;

  /// {@macro logger}
  Logger._();

  /// Error logging.
  void e(Object? object) {
    if (level >= kErrorLevel) {
      print(object);
    }
  }

  /// Info logging.
  void i(Object? object) {
    if (level >= kInfoLevel) {
      print(object);
    }
  }

  /// Debug logging.
  void d(Object? object) {
    if (level >= kDebugLevel) {
      print(object);
    }
  }

  /// Verbose logging.
  void v(Object? object) {
    if (level >= kVerboseLevel) {
      print(object);
    }
  }
}
