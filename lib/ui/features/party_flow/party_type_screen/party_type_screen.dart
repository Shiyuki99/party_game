import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:party_game/data/models/connection_type.dart';
import 'package:party_game/data/models/party_type.dart';
import 'package:party_game/provider/app_providers.dart';
import 'package:party_game/ui/core/theme/app_theme.dart';
import 'package:party_game/ui/core/widgets/app_scaffold.dart';

class PartyTypeScreen extends ConsumerWidget {
  const PartyTypeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScaffold(
      showBack: false,
      title: 'Party Game',
      body: Column(
        children: [
          const Spacer(flex: 2),
          Icon(
            Icons.sports_esports,
            size: 80,
            color: AppColors.primary.withValues(alpha: 0.8),
          ),
          const SizedBox(height: 16),
          Text(
            'Choose Your Party',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'How do you want to play?',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const Spacer(flex: 1),
          _PartyTypeCard(
            icon: Icons.phone_iphone,
            title: PartyType.passAndPlay.displayName,
            description: PartyType.passAndPlay.description,
            subtitle: 'Pass the phone around',
            onTap: () {
              ref.read(connectionTypeProvider.notifier).set(ConnectionType.passAndPlay);
              ref.read(partyTypeProvider.notifier).set(PartyType.passAndPlay);
              context.push('/lobby');
            },
          ),
          const SizedBox(height: 16),
          _PartyTypeCard(
            icon: Icons.wifi_tethering,
            title: PartyType.lan.displayName,
            description: PartyType.lan.description,
            subtitle: 'WebRTC P2P over QR',
            onTap: () {
              ref.read(connectionTypeProvider.notifier).set(ConnectionType.webRTC);
              ref.read(partyTypeProvider.notifier).set(PartyType.lan);
              context.push('/join');
            },
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
  final VoidCallback onTap;

  const _PartyTypeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Icon(icon, size: 48, color: AppColors.primary),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primaryLight.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
