import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
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
    required this._client,
    required this._contentBox,
    required this._settingsBox,
  });

  String get repoUrl =>
      _settingsBox.get(_settingsKey, defaultValue: defaultRepoUrl) as String;

  set repoUrl(String url) => _settingsBox.put(_settingsKey, url);

  static const String defaultRepoUrl =
      'https://raw.githubusercontent.com/Shiyuki99/party-game-content/main';

  static const _gameIds = [
    'imposter',
    'truth_or_dare',
    'question_imposter',
    'charades',
  ];

  /// Seeds the cache from the bundled assets. Network refresh is deliberately
  /// separate (see [checkForUpdates]) so the app starts instantly offline.
  Future<void> init() async {
    for (final id in _gameIds) {
      final key = '$_contentKeyPrefix$id';
      if (_contentBox.get(key) != null) continue;
      final data = await _loadBundledContent(id);
      if (data != null) await _contentBox.put(key, data);
    }
  }

  Future<Map<String, dynamic>?> _fetchFromGitHub(String gameId) async {
    try {
      final url = '$repoUrl/content/$gameId.json';
      final response = await _client.get(Uri.parse(url)).timeout(
            const Duration(seconds: 8),
          );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> _loadBundledContent(String gameId) async {
    try {
      final raw = await rootBundle.loadString('assets/content/$gameId.json');
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      // Dev fallback: running from the repository root without built assets.
      try {
        final file = File('content/$gameId.json');
        if (!file.existsSync()) return null;
        return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      } catch (_) {
        return null;
      }
    }
  }

  Future<bool> checkForUpdates() async {
    final manifestUrl = '$repoUrl/manifest.json';
    try {
      final response = await _client.get(Uri.parse(manifestUrl)).timeout(
            const Duration(seconds: 8),
          );
      if (response.statusCode != 200) return false;

      final manifest = jsonDecode(response.body) as Map<String, dynamic>;
      bool hasUpdates = false;

      for (final entry in manifest.entries) {
        final gameId = entry.key;
        final remoteHash = entry.value['hash'] as String?;
        if (remoteHash == null) continue;
        final localHash =
            _contentBox.get('$_contentKeyPrefix$gameId$_etagSuffix');

        if (localHash != remoteHash) {
          final data = await _fetchFromGitHub(gameId);
          if (data != null) {
            await _contentBox.put('$_contentKeyPrefix$gameId', data);
            await _contentBox.put(
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
    return null;
  }

  Future<void> clearCache() => _contentBox.clear();
}
