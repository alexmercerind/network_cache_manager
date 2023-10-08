import 'package:network_cache_manager/src/network_connection_handler.dart';

void main() {
  // TODO:
  final handler = NetworkConnectionHandler(8080);
  handler.create(
    'https://user-images.githubusercontent.com/28951144/229373695-22f88f13-d18f-4288-9bf1-c3e078d83722.mp4',
    id: 0,
  );
}
