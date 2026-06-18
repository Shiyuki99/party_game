import 'dart:async';
import 'package:party_game/data/models/player.dart';
import 'package:party_game/data/models/connection_type.dart';

class NetworkMessage {
  final String senderId;
  final String type;
  final Map<String, dynamic> data;

  NetworkMessage({
    required this.senderId,
    required this.type,
    required this.data,
  });

  Map<String, dynamic> toJson() => {
        'senderId': senderId,
        'type': type,
        'data': data,
      };

  factory NetworkMessage.fromJson(Map<String, dynamic> json) => NetworkMessage(
        senderId: json['senderId'] as String,
        type: json['type'] as String,
        data: json['data'] as Map<String, dynamic>,
      );
}

abstract class ConnectionService {
  ConnectionType get type;

  Stream<NetworkMessage> get onMessage;
  Stream<Player> get onPlayerJoin;
  Stream<String> get onPlayerLeave;

  Future<void> initialize({required bool isHost});
  Future<void> send(String playerId, NetworkMessage message);
  Future<void> broadcast(NetworkMessage message, {String? excludeId});
  Future<void> disconnect();
}
