// This file is a part of network_cache_manager (https://github.com/alexmercerind/network_cache_manager).
//
// Copyright © 2023 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'dart:io';
import 'package:network_cache_manager/src/logger.dart';
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

  /// Associated [NetworkResource]s currently being handled by this instance.
  final Map<int, NetworkResource> resources = {};

  /// Associated [HttpClient]s currently being handled by this instance.
  final Map<int, HttpClient> clients = {};

  /// The [HttpServer] instance.
  final Future<HttpServer> server;

  /// Creates a new [NetworkResource] currently being handled by this instance.
  String create(String uri, {int? id}) {
    final resource = NetworkResource(uri, id: id);
    int key = resources.length;
    resources[key] = resource;
    return '127.0.0.1:$port/$key';
  }

  /// {@macro network_connection_handler}
  NetworkConnectionHandler(this.port)
      : server = HttpServer.bind('127.0.0.1', port) {
    server.then((server) => server.listen(_handler));
  }

  /// Creates a new [HttpClient] for the [NetworkResource] with the given [key].
  /// The existing (if any) [HttpClient] is closed.
  Future<HttpClientResponse> _connect(
    int key,
    Map<String, String> headers,
  ) async {
    try {
      clients[key]?.close(force: true);
    } catch (exception, stacktrace) {
      Logger.instance.e(exception);
      Logger.instance.e(stacktrace);
    }
    final client = HttpClient();
    final uri = resources[key]?.uri ?? '';
    final request = await client.getUrl(Uri.parse(uri));
    for (final entry in headers.entries) {
      request.headers.add(entry.key, entry.value);
    }
    final response = await request.close();

    Logger.instance.i('----------');
    Logger.instance.i('NetworkConnectionHandler._connect');
    Logger.instance.i('Status Code: ${response.statusCode}');
    Logger.instance.i('Headers: ${response.headers}');
    Logger.instance.i('----------');

    return response;
  }

  /// HTTP request handler.
  Future<void> _handler(HttpRequest request) async {
    if (request.method == 'GET') {
      final key = int.tryParse(request.uri.path.substring(1));
      final uri = resources[key]?.uri;
      final headers = request.headers;

      Logger.instance.i('----------');
      Logger.instance.i('NetworkConnectionHandler._handler');
      Logger.instance.i('Key: $key');
      Logger.instance.i('URI: $uri');
      Logger.instance.i('Headers: $headers');
      Logger.instance.i('----------');

      if (key != null && uri != null) {
        final headers = <String, String>{};

        // TODO: Selection of headers to be forwarded.
        final range = request.headers.value('range');
        if (range != null) {
          headers['range'] = range;
        }

        try {
          final response = await _connect(key, headers);
          response.headers.forEach((name, values) {
            for (final value in values) {
              request.response.headers.add(name, value);
            }
          });
          request.response.statusCode = response.statusCode;
          await response.pipe(request.response);
        } catch (exception, stacktrace) {
          // TODO: Probably evict the resource from cache & try again.
          Logger.instance.e(exception);
          Logger.instance.e(stacktrace);
        }
      }
    }
  }
}
