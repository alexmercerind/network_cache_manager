// This file is a part of network_cache_manager (https://github.com/alexmercerind/network_cache_manager).
//
// Copyright © 2023 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'dart:io';
import 'package:network_cache_manager/src/models/network_resource.dart';

/// {@template network_connection_handler}
///
/// NetworkConnectionHandler
/// ------------------------
/// Implementation to handle [NetworkResource] HTTP connection & response streaming.
///
/// {@endtemplate}
class NetworkConnectionHandler {
  /// The local port to bind the [HttpServer].
  final int port;

  /// The network resources currently being streamed.
  final Map<int, NetworkResource> resources = {};

  /// The [HttpServer] instance.
  final Future<HttpServer> server;

  /// Creates a new [NetworkResource] currently being handled by this instance.
  NetworkResource create(String uri, {int? id}) {
    final resource = NetworkResource(uri, id: id);
    resources[resource.id] = resource;
    return resource;
  }

  /// {@macro network_connection_handler}
  NetworkConnectionHandler(this.port)
      : server = HttpServer.bind('127.0.0.1', port) {
    server.then((server) => server.listen(_handler));
  }

  /// HTTP request handler.
  Future<void> _handler(HttpRequest request) async {
    if (request.method == 'GET') {
      final id = int.tryParse(request.uri.path.substring(1));
      final uri = resources[id]?.uri;
      if (uri != null) {
        final client = HttpClient();
        final connection = await client.getUrl(Uri.parse(uri));

        final range = request.headers.value('range');
        if (range != null) {
          connection.headers.add('range', range);
        }

        final response = await connection.close();

        response.headers.forEach((name, values) {
          request.response.headers.add(name, values);
        });

        request.response.statusCode = response.statusCode;
        await response.pipe(request.response);
      }
    }
  }
}
