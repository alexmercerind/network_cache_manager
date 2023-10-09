// This file is a part of network_cache_manager (https://github.com/alexmercerind/network_cache_manager).
//
// Copyright © 2023 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:network_cache_manager/src/models/network_resource.dart';

import '../common/resources.dart';

void main() {
  test(
    'network-resource',
    () {
      final a = NetworkResource(resources[0]);
      final b = NetworkResource(resources[0]);

      final c = NetworkResource(resources[1]);
      final d = NetworkResource(resources[2]);

      expect(a == b, isTrue);
      expect(c == d, isFalse);
    },
  );
  test(
    'network-resource-id-default',
    () {
      expect(
        NetworkResource(resources[0]).id,
        equals(resources[0].hashCode),
      );
    },
  );
  test(
    'network-resource-id-override',
    () {
      final a = NetworkResource(resources[0], id: 123);
      final b = NetworkResource(resources[0], id: 456);

      final c = NetworkResource(resources[1], id: 69);
      final d = NetworkResource(resources[2], id: 69);

      expect(a == b, isFalse);
      expect(c == d, isTrue);
    },
  );
}
