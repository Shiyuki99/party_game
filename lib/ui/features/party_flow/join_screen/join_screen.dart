import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:party_game/ui/core/theme/app_theme.dart';
import 'package:party_game/ui/core/widgets/app_button.dart';
import 'package:party_game/ui/core/widgets/app_scaffold.dart';

class JoinScreen extends ConsumerStatefulWidget {
  const JoinScreen({super.key});

  @override
  ConsumerState<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends ConsumerState<JoinScreen> {
  bool _isHost = false;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'LAN Party',
      body: Column(
        children: [
          const Spacer(flex: 1),
          _OptionCard(
            icon: Icons.qr_code,
            title: 'Host a Game',
            description: 'Create a party and show QR code',
            onTap: () {
              setState(() => _isHost = true);
            },
          ),
          const SizedBox(height: 16),
          _OptionCard(
            icon: Icons.qr_code_scanner,
            title: 'Join a Game',
            description: 'Scan host\'s QR code to join',
            onTap: () {
              setState(() => _isHost = false);
            },
          ),
          const SizedBox(height: 24),
          if (_isHost)
            _HostQRView()
          else
            _ScannerView(
              onScan: (code) {
                context.push('/lobby');
              },
            ),
          const Spacer(flex: 1),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, size: 36, color: AppColors.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context).textTheme.titleLarge),
                    Text(description,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HostQRView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(Icons.qr_code, size: 200, color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                'Show this QR to players',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Players scan to join the party',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        AppButton(
          label: 'Continue to Lobby',
          onPressed: () => context.push('/lobby'),
        ),
      ],
    );
  }
}

class _ScannerView extends StatelessWidget {
  final void Function(String code) onScan;

  const _ScannerView({required this.onScan});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: MobileScanner(
        onDetect: (capture) {
          final code = capture.barcodes.first.rawValue;
          if (code != null) onScan(code);
        },
      ),
    );
  }
}
