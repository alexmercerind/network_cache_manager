// This file is a part of network_cache_manager (https://github.com/alexmercerind/network_cache_manager).
//
// Copyright © 2023 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:network_cache_manager/src/models/network_resource_details.dart';

/// {@template cache_entry}
///
/// CacheEntry
/// ----------
/// File-system cache entry for a [NetworkResource].
///
/// {@endtemplate}
class CacheEntry {
  /// The details of the resource.
  final NetworkResourceDetails details;

  /// The cached chunks of the resource.
  final SplayTreeMap<int, int> chunks;

  /// The time at which cache was created.
  final DateTime createdAt;

  /// The time at which cache was updated.
  final DateTime updatedAt;

  /// {@macro network_cache_entry}
  const CacheEntry(
    this.details,
    this.chunks,
    this.createdAt,
    this.updatedAt,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CacheEntry && details == other.details;

  @override
  int get hashCode => details.hashCode;

  @override
  String toString() => 'CacheEntry('
      'details: $details, '
      'chunks: $chunks, '
      'createdAt: $createdAt, '
      'updatedAt: $updatedAt'
      ')';

  factory CacheEntry.fromJson(dynamic json) => CacheEntry(
        NetworkResourceDetails.fromJson(json['details']),
        SplayTreeMap.from(
          json['chunks'].map(
            (k, v) => MapEntry(
              int.parse(k),
              int.parse(v),
            ),
          ),
        ),
        DateTime.parse(json['createdAt']),
        DateTime.parse(json['updatedAt']),
      );

  Map<String, dynamic> toJson() => {
        'details': details.toJson(),
        'chunks': chunks.map(
          (k, v) => MapEntry(
            k.toString(),
            v.toString(),
          ),
        ),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  CacheEntry copyWith({
    NetworkResourceDetails? details,
    SplayTreeMap<int, int>? chunks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CacheEntry(
      details ?? this.details,
      chunks ?? this.chunks,
      createdAt ?? this.createdAt,
      updatedAt ?? this.updatedAt,
    );
  }
}
