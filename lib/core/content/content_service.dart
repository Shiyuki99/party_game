import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';

class ContentService {
  static const _contentKeyPrefix = 'game_';
  static const _etagSuffix = '_etag';
  static const _settingsKey = 'content_repo_url';

  final http.Client _client;
  final Box _contentBox;
  final Box _settingsBox;

  ContentService({
    required http.Client client,
    required Box contentBox,
    required Box settingsBox,
  })  : _client = client,
        _contentBox = contentBox,
        _settingsBox = settingsBox;

  String get repoUrl =>
      _settingsBox.get(_settingsKey, defaultValue: defaultRepoUrl) as String;

  set repoUrl(String url) => _settingsBox.put(_settingsKey, url);

  static const String defaultRepoUrl =
      'https://raw.githubusercontent.com/Shiyuki99/party_game_content/main';

  static const _gameIds = [
    'imposter',
    'truth_or_dare',
    'question_imposter',
    'charades',
  ];

  Future<void> init() async {
    for (final id in _gameIds) {
      final key = '$_contentKeyPrefix$id';
      if (_contentBox.get(key) != null) continue;
      final data = await _fetchFromGitHub(id) ?? _loadLocalDevContent(id);
      if (data != null) {
        _contentBox.put(key, data);
      }
    }
  }

  Future<Map<String, dynamic>?> _fetchFromGitHub(String gameId) async {
    try {
      final url = '$repoUrl/content/$gameId.json';
      final response = await _client.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Map<String, dynamic>? _loadLocalDevContent(String gameId) {
    try {
      final file = File('content/$gameId.json');
      if (!file.existsSync()) return null;
      final raw = file.readAsStringSync();
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<bool> checkForUpdates() async {
    final manifestUrl = '$repoUrl/manifest.json';
    try {
      final response = await _client.get(Uri.parse(manifestUrl));
      if (response.statusCode != 200) return false;

      final manifest = jsonDecode(response.body) as Map<String, dynamic>;
      bool hasUpdates = false;

      for (final entry in manifest.entries) {
        final gameId = entry.key;
        final remoteHash = entry.value['hash'] as String;
        final localHash =
            _contentBox.get('$_contentKeyPrefix$gameId$_etagSuffix');

        if (localHash != remoteHash) {
          final data = await _fetchFromGitHub(gameId);
          if (data != null) {
            _contentBox.put('$_contentKeyPrefix$gameId', data);
            _contentBox.put(
                '$_contentKeyPrefix$gameId$_etagSuffix', remoteHash);
            hasUpdates = true;
          }
        }
      }

      return hasUpdates;
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic>? getContent(String gameId) {
    final cached =
        _contentBox.get('$_contentKeyPrefix$gameId') as Map<String, dynamic>?;
    if (cached != null) return cached;
    final dev = _loadLocalDevContent(gameId);
    if (dev != null) {
      _contentBox.put('$_contentKeyPrefix$gameId', dev);
    }
    return dev;
  }

  Future<void> clearCache() async {
    await _contentBox.clear();
  }
}
