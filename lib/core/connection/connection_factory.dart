import 'package:party_game/core/connection/connection_service.dart';
import 'package:party_game/core/connection/pass_play_connection.dart';
import 'package:party_game/core/connection/webrtc_connection.dart';
import 'package:party_game/data/models/connection_type.dart';

ConnectionService createConnectionService(ConnectionType type) {
  switch (type) {
    case ConnectionType.passAndPlay:
      return PassPlayConnectionService();
    case ConnectionType.webRTC:
      return WebRTCConnectionService();
  }
}
