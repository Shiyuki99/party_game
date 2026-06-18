import 'package:party_game/core/content/content_service.dart';

class ContentRepository {
  final ContentService _contentService;

  ContentRepository({required ContentService contentService})
      : _contentService = contentService;

  Future<bool> checkForUpdates() => _contentService.checkForUpdates();

  String get repoUrl => _contentService.repoUrl;
  set repoUrl(String url) => _contentService.repoUrl = url;

  Map<String, dynamic>? getContent(String gameId) =>
      _contentService.getContent(gameId);

  Future<void> clearCache() => _contentService.clearCache();
}
