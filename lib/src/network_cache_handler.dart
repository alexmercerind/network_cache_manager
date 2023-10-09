// This file is a part of network_cache_manager (https://github.com/alexmercerind/network_cache_manager).
//
// Copyright © 2023 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:convert';
import 'dart:collection';
import 'package:meta/meta.dart';
import 'package:path/path.dart';
import 'package:synchronized/synchronized.dart';

import 'package:network_cache_manager/src/models/cache_entry.dart';
import 'package:network_cache_manager/src/models/network_resource_details.dart';

/// {@template network_cache_handler}
///
/// NetworkCacheHandler
/// -------------------
/// Implementation to handle [NetworkResource] file-system caching.
///
/// {@endtemplate}
class NetworkCacheManager {
  /// The default cache chunk size for each [NetworkResource].
  static const int kCacheChunkSize = 4 * 1024 * 1024;

  /// The cache directory.
  final Directory directory;

  /// For mutual-exclusion.
  final Lock lock = Lock();

  /// Currently cached [NetworkResource] entries.
  final HashMap<int, CacheEntry> entries = HashMap<int, CacheEntry>();

  /// {@macro network_cache_handler}
  NetworkCacheManager(this.directory);

  /// Initializes this instance.
  Future<void> ensureInitialized() {
    return lock.synchronized(() async {
      final contents = directory.listSync(recursive: false, followLinks: false);
      for (final entity in contents) {
        try {
          final id = int.tryParse(basename(entity.path));
          if (entity is Directory && id != null) {
            final file = File(join(entity.path, '.index'));
            final data = await file.readAsString();
            final entry = CacheEntry.fromJson(json.decode(data));
            entries[id] = entry;
          }
        } catch (_) {}
      }
    });
  }

  Future<void> update(
    NetworkResourceDetails resource,
    List<int> data,
    int start,
    int end,
  ) {
    return lock.synchronized(() async {
      try {
        final id = resource.id;
        final entry = entries[id];

        final indexStart = start ~/ kCacheChunkSize;
        final indexEnd = end ~/ kCacheChunkSize;
        final offsetStart = start % kCacheChunkSize;
        final offsetEnd = end % kCacheChunkSize;

        for (int i = indexStart; i <= indexEnd; i++) {
          if (i == indexStart && i == indexEnd) {
            // Single chunk; same chunk contains [start, end] range.
            await write(
              resource,
              i,
              data,
              offsetStart,
              offsetEnd,
            );
          } else if (i == indexStart) {
            // Multiple chunks; first chunk w/ start offset.
            await write(
              resource,
              i,
              data,
              offsetStart,
              kCacheChunkSize - 1,
            );
          } else if (i == indexEnd) {
            // Multiple chunks; last chunk w/ end offset.
            await write(
              resource,
              i,
              data,
              0,
              offsetEnd,
            );
          } else {
            // Multiple chunks; middle chunk.
            await write(
              resource,
              i,
              data,
              0,
              kCacheChunkSize - 1,
            );
          }
        }

        // TODO:

        entries[id] ??= CacheEntry(
          resource,
          SplayTreeMap<int, int>(),
          DateTime.now(),
          DateTime.now(),
        );
      } catch (_) {}
    });
  }

  Future<void> exists(NetworkCacheManager resource) {
    return lock.synchronized(() async {});
  }

  Future<void> create(NetworkCacheManager resource) {
    return lock.synchronized(() async {});
  }

  Future<void> evict(NetworkResourceDetails resource) {
    return lock.synchronized(() async {});
  }

  @visibleForTesting
  Future<List<int>> read(
    NetworkResourceDetails resource,
    int index,
  ) async {
    final path = join(directory.path, resource.id.toString(), index.toString());
    final file = File(path);
    if (await file.exists()) {
      return file.readAsBytes();
    } else {
      return List.generate(kCacheChunkSize, (_) => 0);
    }
  }

  @visibleForTesting
  Future<void> write(
    NetworkResourceDetails resource,
    int index,
    List<int> data,
    int start,
    int end,
  ) async {
    final current = await read(resource, index);
    current.setRange(start, end + 1, current);
    final path = join(directory.path, resource.id.toString(), index.toString());
    final file = File(path);
    if (!await file.exists()) {
      await file.create(recursive: true);
    }
    await file.writeAsBytes(current);
  }
}
