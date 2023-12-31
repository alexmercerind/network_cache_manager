// This file is a part of network_cache_manager (https://github.com/alexmercerind/network_cache_manager).
//
// Copyright © 2023 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;
import 'package:collection/collection.dart';
import 'package:network_cache_manager/src/network_cache_handler.dart';
import 'package:network_cache_manager/src/models/network_resource.dart';
import 'package:network_cache_manager/src/models/network_resource_details.dart';

import 'common/resources.dart';

void main() {
  final directory = Directory(
    path.join(
      Directory.systemTemp.path,
      'NetworkCacheHandler',
    ),
  );

  print(directory);

  Future<void> reset() async {
    try {
      final contents = directory.listSync();
      for (final e in contents) {
        if (e is File) {
          await e.delete();
        } else if (e is Directory) {
          await e.delete(recursive: true);
        }
      }
      await directory.delete();
    } catch (_) {}
  }

  test(
    'network-cache-handler-ensure-initialized',
    () async {
      final first = NetworkCacheHandler(directory);
      await first.ensureInitialized();

      await first.update(
        NetworkResourceDetails(
          NetworkResource('', id: 0),
          56 * 1024 * 1024,
          true,
        ),
        List.generate(1024, (_) => 1),
        0,
        1024 - 1,
      );
      await first.update(
        NetworkResourceDetails(
          NetworkResource('', id: 0),
          56 * 1024 * 1024,
          true,
        ),
        List.generate(1024, (_) => 1),
        2048,
        2048 + 1024 - 1,
      );
      await first.update(
        NetworkResourceDetails(
          NetworkResource('', id: 1),
          56 * 1024 * 1024,
          true,
        ),
        List.generate(1024, (_) => 1),
        0,
        1024 - 1,
      );

      final second = NetworkCacheHandler(directory);
      await second.ensureInitialized();

      expect(
        first.entries,
        equals(
          second.entries,
        ),
      );
    },
  );
  test(
    'network-cache-handler-update-chunks',
    () async {
      await reset();

      final instance = NetworkCacheHandler(directory);
      await instance.ensureInitialized();

      final resource = NetworkResourceDetails(
        NetworkResource(resources[0]),
        56 * 1024 * 1024,
        true,
      );

      // Fresh update.
      await instance.update(
        resource,
        List.generate(1024, (_) => 1),
        0,
        1024 - 1,
      );
      print(instance.entries[resource.id]?.chunks);

      expect(
        MapEquality().equals(
          instance.entries[resource.id]?.chunks,
          {
            0: 1024 - 1,
          },
        ),
        isTrue,
      );

      // Update w/ overlapping range.
      await instance.update(
        resource,
        List.generate(2048, (_) => 1),
        0,
        2048 - 1,
      );
      print(instance.entries[resource.id]?.chunks);

      expect(
        MapEquality().equals(
          instance.entries[resource.id]?.chunks,
          {
            0: 2048 - 1,
          },
        ),
        isTrue,
      );

      // Update w/ separate range.
      await instance.update(
        resource,
        List.generate(2048, (_) => 1),
        8192,
        8192 + 2048 - 1,
      );
      print(instance.entries[resource.id]?.chunks);

      expect(
        MapEquality().equals(
          instance.entries[resource.id]?.chunks,
          {
            0: 2048 - 1,
            8192: 8192 + 2048 - 1,
          },
        ),
        isTrue,
      );

      // Update w/ overlapping range, extending the end.
      await instance.update(
        resource,
        List.generate(2048, (_) => 1),
        1024,
        1024 + 2048 - 1,
      );
      print(instance.entries[resource.id]?.chunks);

      expect(
        MapEquality().equals(
          instance.entries[resource.id]?.chunks,
          {
            0: 1024 + 2048 - 1,
            8192: 8192 + 2048 - 1,
          },
        ),
        isTrue,
      );

      // Update w/ overlapping range, extending the start.
      await instance.update(
        resource,
        List.generate(2048, (_) => 1),
        7168,
        7168 + 2048 - 1,
      );
      print(instance.entries[resource.id]?.chunks);

      expect(
        MapEquality().equals(
          instance.entries[resource.id]?.chunks,
          {
            0: 1024 + 2048 - 1,
            7168: 8192 + 2048 - 1,
          },
        ),
        isTrue,
      );

      // Merge two ranges.

      await instance.update(
        resource,
        List.generate(6144, (_) => 1),
        2048,
        2048 + 6144 - 1,
      );
      print(instance.entries[resource.id]?.chunks);

      expect(
        MapEquality().equals(
          instance.entries[resource.id]?.chunks,
          {
            0: 8192 + 2048 - 1,
          },
        ),
        isTrue,
      );
    },
  );
  test(
    'network-cache-handler-update-data',
    () async {
      await reset();

      final instance = NetworkCacheHandler(directory);
      await instance.ensureInitialized();

      final resource = NetworkResourceDetails(
        NetworkResource(resources[0]),
        56 * 1024 * 1024,
        true,
      );

      // NOTE: The buffer is large enough to be split into 3 cache chunks.
      final offset = 256;
      final size = 2.5 * NetworkCacheHandler.kCacheChunkSize ~/ 1;
      final data = List.generate(size, (_) => 1);

      await instance.update(
        resource,
        data,
        offset,
        offset + size - 1,
      );

      final entry = Directory(path.join(directory.path, '${resource.id}'));
      final contents = entry.listSync().cast<File>();

      // Test for creation.
      expect(
        contents.length,
        equals(4),
      );
      expect(
        SetEquality().equals(
          contents.map((e) => e.path).toSet(),
          {
            for (int i = 0; i < 3; i++) path.join(entry.path, '$i'),
            path.join(entry.path, '.index'),
          },
        ),
        equals(true),
      );
      // Test for size.
      expect(
        ListEquality().equals(
          await Future.wait(
            contents.where((e) => int.tryParse(path.basename(e.path)) != null).map(
              (e) async {
                final data = await e.readAsBytes();
                return data.length;
              },
            ),
          ),
          [
            NetworkCacheHandler.kCacheChunkSize,
            NetworkCacheHandler.kCacheChunkSize,
            NetworkCacheHandler.kCacheChunkSize,
          ],
        ),
        equals(true),
      );
      // Test for contents.
      expect(
        ListEquality().equals(
          await File(path.join(entry.path, '0')).readAsBytes(),
          [
            for (int i = 0; i < offset; i++) 0,
            for (int i = 0; i < NetworkCacheHandler.kCacheChunkSize - offset; i++) 1,
          ],
        ),
        equals(true),
      );
      expect(
        ListEquality().equals(
          await File(path.join(entry.path, '1')).readAsBytes(),
          [
            for (int i = 0; i < NetworkCacheHandler.kCacheChunkSize; i++) 1,
          ],
        ),
        equals(true),
      );
      expect(
        ListEquality().equals(
          await File(path.join(entry.path, '2')).readAsBytes(),
          [
            for (int i = 0; i < size - 2 * NetworkCacheHandler.kCacheChunkSize + offset; i++) 1,
            for (int i = 0; i < NetworkCacheHandler.kCacheChunkSize - (size - 2 * NetworkCacheHandler.kCacheChunkSize + offset); i++) 0,
          ],
        ),
        equals(true),
      );
    },
  );
  test(
    'network-cache-handler-update-data',
    () async {
      await reset();

      final instance = NetworkCacheHandler(directory);
      await instance.ensureInitialized();

      final resource = NetworkResourceDetails(
        NetworkResource(resources[0]),
        56 * 1024 * 1024,
        true,
      );

      // NOTE: The buffer is positioned to be split into 2 cache chunks.
      final offset = NetworkCacheHandler.kCacheChunkSize ~/ 3;
      final size = NetworkCacheHandler.kCacheChunkSize;
      final data = List.generate(size, (_) => 1);

      await instance.update(
        resource,
        data,
        offset,
        offset + size - 1,
      );

      final entry = Directory(path.join(directory.path, '${resource.id}'));
      final contents = entry.listSync().cast<File>();

      // Test for creation.
      expect(
        contents.length,
        equals(3),
      );
      expect(
        SetEquality().equals(
          contents.map((e) => e.path).toSet(),
          {
            for (int i = 0; i < 2; i++) path.join(entry.path, '$i'),
            path.join(entry.path, '.index'),
          },
        ),
        equals(true),
      );
      // Test for size.
      expect(
        ListEquality().equals(
          await Future.wait(
            contents.where((e) => int.tryParse(path.basename(e.path)) != null).map(
              (e) async {
                final data = await e.readAsBytes();
                return data.length;
              },
            ),
          ),
          [
            NetworkCacheHandler.kCacheChunkSize,
            NetworkCacheHandler.kCacheChunkSize,
          ],
        ),
        equals(true),
      );
      // Test for contents.
      expect(
        ListEquality().equals(
          await File(path.join(entry.path, '0')).readAsBytes(),
          [
            for (int i = 0; i < offset; i++) 0,
            for (int i = 0; i < NetworkCacheHandler.kCacheChunkSize - offset; i++) 1,
          ],
        ),
        equals(true),
      );
      expect(
        ListEquality().equals(
          await File(path.join(entry.path, '1')).readAsBytes(),
          [
            for (int i = 0; i < size - NetworkCacheHandler.kCacheChunkSize + offset; i++) 1,
            for (int i = 0; i < NetworkCacheHandler.kCacheChunkSize - (size - NetworkCacheHandler.kCacheChunkSize + offset); i++) 0,
          ],
        ),
        equals(true),
      );
    },
  );
  test(
    'network-cache-handler-update-data',
    () async {
      await reset();

      final instance = NetworkCacheHandler(directory);
      await instance.ensureInitialized();

      final resource = NetworkResourceDetails(
        NetworkResource(resources[0]),
        56 * 1024 * 1024,
        true,
      );

      // NOTE: The buffer is positioned to skip first 5 cache chunks.
      final offset = 5.5 * NetworkCacheHandler.kCacheChunkSize ~/ 1;
      final size = 1.5 * NetworkCacheHandler.kCacheChunkSize ~/ 1;
      final data = List.generate(size, (_) => 1);

      await instance.update(
        resource,
        data,
        offset,
        offset + size - 1,
      );

      final entry = Directory(path.join(directory.path, '${resource.id}'));
      final contents = entry.listSync().cast<File>();

      // Test for creation.
      expect(
        contents.length,
        equals(3),
      );
      expect(
        SetEquality().equals(
          contents.map((e) => e.path).toSet(),
          {
            for (int i = 5; i < 5 + 2; i++) path.join(entry.path, '$i'),
            path.join(entry.path, '.index'),
          },
        ),
        equals(true),
      );
      // Test for size.
      expect(
        ListEquality().equals(
          await Future.wait(
            contents.where((e) => int.tryParse(path.basename(e.path)) != null).map(
              (e) async {
                final data = await e.readAsBytes();
                return data.length;
              },
            ),
          ),
          [
            NetworkCacheHandler.kCacheChunkSize,
            NetworkCacheHandler.kCacheChunkSize,
          ],
        ),
        equals(true),
      );
      // Test for contents.
      expect(
        ListEquality().equals(
          await File(path.join(entry.path, '5')).readAsBytes(),
          [
            for (int i = 0; i < offset % NetworkCacheHandler.kCacheChunkSize; i++) 0,
            for (int i = 0; i < NetworkCacheHandler.kCacheChunkSize - (offset % NetworkCacheHandler.kCacheChunkSize); i++) 1,
          ],
        ),
        equals(true),
      );
      expect(
        ListEquality().equals(
          await File(path.join(entry.path, '6')).readAsBytes(),
          [
            for (int i = 0; i < size - NetworkCacheHandler.kCacheChunkSize + offset % NetworkCacheHandler.kCacheChunkSize; i++) 1,
            for (int i = 0; i < NetworkCacheHandler.kCacheChunkSize - (size - NetworkCacheHandler.kCacheChunkSize + offset % NetworkCacheHandler.kCacheChunkSize); i++) 0,
          ],
        ),
        equals(true),
      );
    },
  );
  test(
    'network-cache-handler-read-data',
    () async {
      await reset();

      final instance = NetworkCacheHandler(directory);
      await instance.ensureInitialized();

      final resource = NetworkResourceDetails(
        NetworkResource(resources[0]),
        1024,
        true,
      );

      final data = List.generate(1024, (_) => 1);

      // Write to an inexistent chunk w/ index 0.
      await instance.write(
        resource,
        0,
        data,
        128,
        128 + 1024 - 1,
      );
      // Read chunk w/ index 0.
      final result = await instance.read(resource, 0);

      // Test for size & contents.
      expect(
        result.length,
        equals(NetworkCacheHandler.kCacheChunkSize),
      );
      expect(
        ListEquality().equals(
          result,
          [
            for (int i = 0; i < 128; i++) 0,
            for (int i = 0; i < 1024; i++) 1,
            for (int i = 0; i < NetworkCacheHandler.kCacheChunkSize - 128 - 1024; i++) 0,
          ],
        ),
        equals(true),
      );
    },
  );
  test(
    'network-cache-handler-read-data',
    () async {
      await reset();

      final instance = NetworkCacheHandler(directory);
      await instance.ensureInitialized();

      final resource = NetworkResourceDetails(
        NetworkResource(resources[0]),
        1024,
        true,
      );

      // Read from an inexistent chunk w/ index 0.
      final result = await instance.read(resource, 0);

      // Test for an empty buffer.
      expect(
        result.length,
        equals(NetworkCacheHandler.kCacheChunkSize),
      );
      expect(
        ListEquality().equals(
          result,
          [
            for (int i = 0; i < NetworkCacheHandler.kCacheChunkSize; i++) 0,
          ],
        ),
        equals(true),
      );
    },
  );
  test(
    'network-cache-handler-write-data',
    () async {
      await reset();

      final instance = NetworkCacheHandler(directory);
      await instance.ensureInitialized();

      final resource = NetworkResourceDetails(
        NetworkResource(resources[0]),
        1024,
        true,
      );

      final data = List.generate(1024, (_) => 1);

      // Write buffer to an inexistent chunk w/ index 0.
      await instance.write(
        resource,
        0,
        data,
        128,
        128 + 1024 - 1,
      );

      final entry = Directory(path.join(directory.path, '${resource.id}'));
      final contents = entry.listSync().cast<File>();

      // Test for creation.
      expect(
        contents.length,
        equals(1),
      );
      expect(
        contents.single.path,
        equals(path.join(entry.path, '0')),
      );
      // Test for contents.
      expect(
        ListEquality().equals(
          await contents.single.readAsBytes(),
          [
            for (int i = 0; i < 128; i++) 0,
            for (int i = 0; i < 1024; i++) 1,
            for (int i = 0; i < NetworkCacheHandler.kCacheChunkSize - 128 - 1024; i++) 0,
          ],
        ),
        equals(true),
      );
    },
  );
}
