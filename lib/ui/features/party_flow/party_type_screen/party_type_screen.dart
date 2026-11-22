import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:party_game/data/models/connection_type.dart';
import 'package:party_game/data/models/party_type.dart';
import 'package:party_game/data/repositories/player_repository.dart';
import 'package:party_game/provider/app_providers.dart';
import 'package:party_game/ui/core/theme/app_theme.dart';
import 'package:party_game/ui/core/widgets/app_scaffold.dart';

class PartyTypeScreen extends ConsumerWidget {
  const PartyTypeScreen({super.key});

  void _startPassAndPlay(WidgetRef ref) {
    ref.read(playerRepositoryProvider.notifier).clear();
    ref.read(scoreboardServiceProvider).reset();
    ref.read(connectionTypeProvider.notifier).set(ConnectionType.passAndPlay);
    ref.read(partyTypeProvider.notifier).set(PartyType.passAndPlay);
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Party Game'),
        content: const Text(
          'Four pass-and-play party games on one device.\n\n'
          'Add your players in the lobby, pick a game, then pass the device '
          'whenever the app asks you to. Scores carry over between games so '
          'you can crown an overall winner.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScaffold(
      showBack: false,
      title: 'Party Game',
      actions: [
        IconButton(
          tooltip: 'About',
          icon: const Icon(Icons.info_outline),
          onPressed: () => _showAbout(context),
        ),
      ],
      body: Column(
        children: [
          const Spacer(flex: 2),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.sports_esports,
                size: 72, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          Text('Party Game',
              style: Theme.of(context).textTheme.displayLarge,
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('Four games. One device. Endless bragging rights.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center),
          const Spacer(flex: 1),
          _PartyTypeCard(
            icon: Icons.phone_iphone,
            title: PartyType.passAndPlay.displayName,
            description: PartyType.passAndPlay.description,
            subtitle: 'Pass the device between turns',
            onTap: () {
              _startPassAndPlay(ref);
              context.push('/lobby');
            },
          ),
          const SizedBox(height: 16),
          _PartyTypeCard(
            icon: Icons.wifi_tethering,
            title: PartyType.lan.displayName,
            description: 'Play together, each on your own device',
            subtitle: 'Coming soon',
            enabled: false,
            onTap: () {},
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _PartyTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;

  const _PartyTypeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Opacity(
          opacity: enabled ? 1 : 0.55,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Icon(icon, size: 44, color: AppColors.primary),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 4),
                      Text(description,
                          style: Theme.of(context).textTheme.bodyMedium),
                      Text(subtitle,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.primaryLight)),
                    ],
                  ),
                ),
                if (!enabled)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('SOON',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary)),
                  )
                else
                  const Icon(Icons.arrow_forward_ios,
                      color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
