import 'dart:async';
import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:party_game/core/connection/connection_service.dart';
import 'package:party_game/data/models/player.dart';
import 'package:party_game/data/models/connection_type.dart';

class WebRTCConnectionService extends ConnectionService {
  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _dataChannel;
  bool _isHost = false;

  final _onMessageController = StreamController<NetworkMessage>.broadcast();
  final _onPlayerJoinController = StreamController<Player>.broadcast();
  final _onPlayerLeaveController = StreamController<String>.broadcast();

  String? _pendingOffer;

  @override
  ConnectionType get type => ConnectionType.webRTC;

  @override
  Stream<NetworkMessage> get onMessage => _onMessageController.stream;

  @override
  Stream<Player> get onPlayerJoin => _onPlayerJoinController.stream;

  @override
  Stream<String> get onPlayerLeave => _onPlayerLeaveController.stream;

  Future<String?> generateOffer() async {
    if (!_isHost) return null;
    return _pendingOffer;
  }

  Future<String?> acceptOffer(String offerSdp) async {
    if (_isHost) return null;
    final desc = RTCSessionDescription(offerSdp, 'offer');
    await _peerConnection!.setRemoteDescription(desc);
    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);
    return answer.sdp;
  }

  Future<void> receiveAnswer(String answerSdp) async {
    if (!_isHost) return;
    final desc = RTCSessionDescription(answerSdp, 'answer');
    await _peerConnection!.setRemoteDescription(desc);
  }

  @override
  Future<void> initialize({required bool isHost}) async {
    _isHost = isHost;

    final config = <String, dynamic>{
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
      ],
    };

    _peerConnection = await createPeerConnection(config);

    _peerConnection!.onIceCandidate = (candidate) {};

    _peerConnection!.onDataChannel = (channel) {
      _dataChannel = channel;
      _setupDataChannel();
    };

    if (isHost) {
      _dataChannel = await _peerConnection!
          .createDataChannel('game', RTCDataChannelInit());
      _setupDataChannel();

      final offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);
      _pendingOffer = offer.sdp;
    }
  }

  void _setupDataChannel() {
    _dataChannel!.onMessage = (message) {
      final json = jsonDecode(message.text) as Map<String, dynamic>;
      _onMessageController.add(NetworkMessage.fromJson(json));
    };
  }

  @override
  Future<void> send(String playerId, NetworkMessage message) async {
    final json = jsonEncode(message.toJson());
    _dataChannel?.send(RTCDataChannelMessage(json));
  }

  @override
  Future<void> broadcast(NetworkMessage message, {String? excludeId}) async {
    final json = jsonEncode(message.toJson());
    _dataChannel?.send(RTCDataChannelMessage(json));
  }

  @override
  Future<void> disconnect() async {
    _dataChannel?.close();
    await _peerConnection?.close();
    await _onMessageController.close();
    await _onPlayerJoinController.close();
    await _onPlayerLeaveController.close();
  }
}
