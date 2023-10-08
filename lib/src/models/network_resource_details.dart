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
///
/// Network resource with additional details.
///
/// {@endtemplate}
class NetworkResourceDetails extends NetworkResource {
  /// The response headers of the resource.
  final Map<String, String> headers;

  /// {@macro network_resource_details}
  NetworkResourceDetails(
    NetworkResource resource,
    this.headers,
  ) : super(resource.uri, id: resource.id);
}
