import 'package:network_cache_manager/src/network_connection_handler.dart';

void main() {
  // TODO:
  final handler = NetworkConnectionHandler(8080);
  print(
    handler.create(
      'https://github.com/media-kit/media-kit/assets/28951144/efb4057c-6fd3-4644-a0b1-42d5fb420ce9',
    ),
  );
}
