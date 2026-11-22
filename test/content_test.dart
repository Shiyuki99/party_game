import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const gameIds = [
    'imposter',
    'truth_or_dare',
    'question_imposter',
    'charades',
  ];

  test('bundled content is valid, substantial and matches the manifest', () {
    final manifest = jsonDecode(File('content/manifest.json').readAsStringSync())
        as Map<String, dynamic>;

    for (final id in gameIds) {
      final file = File('content/$id.json');
      expect(file.existsSync(), isTrue, reason: '$id content missing');
      final bytes = file.readAsBytesSync();
      final data = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;

      final asset = File('assets/content/$id.json');
      expect(asset.existsSync(), isTrue, reason: '$id asset missing');
      expect(asset.readAsBytesSync(), bytes, reason: '$id asset out of sync');

      final expectedHash = sha256.convert(bytes).toString();
      expect(manifest[id]?['hash'], expectedHash, reason: '$id hash mismatch');

      switch (id) {
        case 'truth_or_dare':
          expect((data['truths'] as List).length, greaterThanOrEqualTo(60));
          expect((data['dares'] as List).length, greaterThanOrEqualTo(60));
        case 'imposter':
          final categories = data['categories'] as Map<String, dynamic>;
          expect(categories.length, greaterThanOrEqualTo(14));
          for (final entry in categories.entries) {
            expect((entry.value as List).length, greaterThanOrEqualTo(16),
                reason: '${entry.key} too small');
          }
        case 'question_imposter':
          expect((data['questions'] as List).length, greaterThanOrEqualTo(45));
        case 'charades':
          expect((data['words'] as List).length, greaterThanOrEqualTo(100));
      }
    }
  });

  test('all content lists contain unique non-empty strings', () {
    for (final id in gameIds) {
      final data =
          jsonDecode(File('content/$id.json').readAsStringSync())
              as Map<String, dynamic>;
      final lists = <List<String>>[];
      if (data['categories'] is Map) {
        for (final value in (data['categories'] as Map).values) {
          lists.add((value as List).cast<String>());
        }
      }
      for (final key in ['truths', 'dares', 'questions', 'words']) {
        if (data[key] is List) lists.add((data[key] as List).cast<String>());
      }
      for (final list in lists) {
        expect(list.every((s) => s.trim().isNotEmpty), isTrue, reason: id);
        expect(list.toSet(), hasLength(list.length), reason: '$id has duplicates');
      }
    }
  });
}
