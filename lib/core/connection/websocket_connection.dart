import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:party_game/core/connection/connection_service.dart';
import 'package:party_game/data/models/player.dart';
import 'package:party_game/data/models/connection_type.dart';

class WebSocketConnectionService extends ConnectionService {
  WebSocket? _ws;
  HttpServer? _server;

  final _onMessageController = StreamController<NetworkMessage>.broadcast();
  final _onPlayerJoinController = StreamController<Player>.broadcast();
  final _onPlayerLeaveController = StreamController<String>.broadcast();

  String? _hostAddress;
  int? _hostPort;

  @override
  ConnectionType get type => ConnectionType.webRTC;

  @override
  Stream<NetworkMessage> get onMessage => _onMessageController.stream;

  @override
  Stream<Player> get onPlayerJoin => _onPlayerJoinController.stream;

  @override
  Stream<String> get onPlayerLeave => _onPlayerLeaveController.stream;

  String? get hostAddress => _hostAddress;
  int? get hostPort => _hostPort;

  /// Host starts a WebSocket server
  @override
  Future<void> initialize({required bool isHost}) async {
    if (isHost) {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
      _hostPort = _server!.port;

      final interfaces = await NetworkInterface.list();
      final addr = interfaces.isNotEmpty ? interfaces.first.addresses.firstOrNull?.address : '127.0.0.1';
      _hostAddress = addr;

      _server!.listen((HttpRequest req) {
        if (req.uri.path == '/game') {
          WebSocketTransformer.upgrade(req).then((ws) {
            _ws = ws;
            _setupWs();
          });
        } else {
          req.response.statusCode = 404;
          req.response.close();
        }
      });
    }
  }

  /// Client connects to host via address:port from QR
  Future<void> connect(String address, int port) async {
    _ws = await WebSocket.connect('ws://$address:$port/game');
    _setupWs();
  }

  void _setupWs() {
    _ws!.listen(
      (data) {
        final json = jsonDecode(data as String) as Map<String, dynamic>;
        _onMessageController.add(NetworkMessage.fromJson(json));
      },
      onDone: () {},
      onError: (e) {},
    );
  }

  @override
  Future<void> send(String playerId, NetworkMessage message) async {
    final json = jsonEncode(message.toJson());
    _ws?.add(json);
  }

  @override
  Future<void> broadcast(NetworkMessage message, {String? excludeId}) async {
    final json = jsonEncode(message.toJson());
    _ws?.add(json);
  }

  @override
  Future<void> disconnect() async {
    await _ws?.close();
    await _server?.close(force: true);
    await _onMessageController.close();
    await _onPlayerJoinController.close();
    await _onPlayerLeaveController.close();
  }
}
