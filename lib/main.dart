import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:party_game/core/content/content_service.dart';
import 'package:party_game/provider/app_providers.dart';
import 'package:party_game/ui/core/routes/app_router.dart';
import 'package:party_game/ui/core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('game_content');
  await Hive.openBox('app_settings');
  await Hive.openBox('scoreboard');

  // Content is bundled as an asset and cached in Hive. Load it before the UI
  // starts so every game immediately has data, online or offline.
  final contentService = ContentService(
    client: http.Client(),
    contentBox: Hive.box('game_content'),
    settingsBox: Hive.box('app_settings'),
  );
  await contentService.init();

  runApp(ProviderScope(
    overrides: [
      contentServiceProvider.overrideWithValue(contentService),
    ],
    child: const PartyGameApp(),
  ));
}

class PartyGameApp extends ConsumerWidget {
  const PartyGameApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Party Game',
      theme: AppTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
