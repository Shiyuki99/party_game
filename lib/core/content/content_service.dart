import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
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
          await _downloadGameContent(gameId);
          _contentBox.put(
              '$_contentKeyPrefix$gameId$_etagSuffix', remoteHash);
          hasUpdates = true;
        }
      }

      return hasUpdates;
    } catch (_) {
      return false;
    }
  }

  Future<void> _downloadGameContent(String gameId) async {
    final url = '$repoUrl/content/$gameId.json';
    final response = await _client.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _contentBox.put('$_contentKeyPrefix$gameId', data);
    }
  }

  Map<String, dynamic>? getContent(String gameId) {
    final cached =
        _contentBox.get('$_contentKeyPrefix$gameId') as Map<String, dynamic>?;
    if (cached != null) return cached;
    return _loadBundledContent(gameId);
  }

  Map<String, dynamic>? _loadBundledContent(String gameId) {
    try {
      final path = 'assets/games/$gameId.json';
      final raw = rootBundle.loadString(path);
      return jsonDecode(raw.toString()) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearCache() async {
    await _contentBox.clear();
  }
}
