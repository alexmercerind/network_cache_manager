// This file is a part of network_cache_manager (https://github.com/alexmercerind/network_cache_manager).
//
// Copyright © 2023 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the LICENSE file.

/// {@template network_resource}
///
/// NetworkResource
/// ---------------
///
/// A network resource referenced by a URI.
/// Optionally, an ID may be provided to identify two or more resources with different URIs as the same resource.
///
/// {@endtemplate}
class NetworkResource {
  /// The URI of the resource.
  final String uri;

  /// The ID of the resource.
  final int id;

  /// {@macro network_resource}
  NetworkResource(
    this.uri, {
    int? id,
  }) : id = id ?? uri.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is NetworkResource && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
