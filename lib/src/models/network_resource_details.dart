// This file is a part of network_cache_manager (https://github.com/alexmercerind/network_cache_manager).
//
// Copyright © 2023 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'package:network_cache_manager/src/models/network_resource.dart';

/// {@template network_resource_details}
///
/// NetworkResourceDetails
/// ----------------------
/// Network resource with additional details fetched from the HTTP response.
///
/// {@endtemplate}
class NetworkResourceDetails extends NetworkResource {
  /// Size of the resource.
  /// The value of "Content-Length" header from the HTTP response.
  /// https://developer.mozilla.org/en-US/docs/Web/HTTP/Range_requests
  final int size;

  /// Whether the resource is resumable.
  /// The value of "Accept-Ranges" header from the HTTP response.
  /// https://developer.mozilla.org/en-US/docs/Web/HTTP/Range_requests
  final bool resumable;

  /// {@macro network_resource_details}
  NetworkResourceDetails(
    NetworkResource resource,
    this.size,
    this.resumable,
  ) : super(resource.uri, id: resource.id);

  @override
  String toString() => 'NetworkResourceDetails('
      'uri: $uri, '
      'id: $id, '
      'size: $size, '
      'resumable: $resumable'
      ')';

  factory NetworkResourceDetails.fromJson(dynamic json) =>
      NetworkResourceDetails(
        NetworkResource.fromJson(json),
        json['size'],
        json['resumable'],
      );

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'size': size,
        'resumable': resumable,
      };
}
