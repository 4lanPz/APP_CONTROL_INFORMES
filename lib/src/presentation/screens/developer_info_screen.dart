import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/app_diagnostics_service.dart';
import 'internal/debug_tools_screen.dart';

class DeveloperInfoScreen extends StatefulWidget {
  const DeveloperInfoScreen({
    super.key,
    required this.diagnosticsService,
  });

  final AppDiagnosticsService diagnosticsService;

  @override
  State<DeveloperInfoScreen> createState() => _DeveloperInfoScreenState();
}

class _DeveloperInfoScreenState extends State<DeveloperInfoScreen> {
  static const _developers = <_DeveloperProfile>[
    _DeveloperProfile(
      name: '4lanPZ',
      githubLabel: 'github.com/4lanPZ',
      githubUrl: 'https://github.com/4lanPZ',
      emailLabel: 'alanstvn420@gmail.com',
      emailAddress: 'alanstvn420@gmail.com',
    ),
    _DeveloperProfile(
      name: 'Ingrith-R2',
      githubLabel: 'github.com/Ingrith-R2',
      githubUrl: 'https://github.com/Ingrith-R2',
      emailLabel: 'Configurar correo',
      emailAddress: '',
    ),
  ];

  static const _brandAssetPath = 'assets/branding/TecnoReport.png';
  static const _requiredSecretTaps = 10;

  int _secretTapCount = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Información'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Desarrolladores',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Contáctanos para actualización de proyectos, nuevos proyectos o sugerencias.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                for (final developer in _developers) ...[
                  _DeveloperCard(developer: developer),
                  if (developer != _developers.last) const SizedBox(height: 16),
                ],
                const SizedBox(height: 20),
                _buildSecretEntry(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecretEntry(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _handleSecretTap(context),
          child: Image.asset(
            _brandAssetPath,
            width: 92,
            height: 92,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppDiagnosticsService.appVersionLabel,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Future<void> _handleSecretTap(BuildContext context) async {
    _secretTapCount++;
    if (_secretTapCount < _requiredSecretTaps) {
      return;
    }

    _secretTapCount = 0;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DebugToolsScreen(
          diagnosticsService: widget.diagnosticsService,
        ),
      ),
    );
  }
}

class _DeveloperCard extends StatelessWidget {
  const _DeveloperCard({
    required this.developer,
  });

  final _DeveloperProfile developer;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Desarrollado por ${developer.name}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ContactLinkTile(
                    icon: Icons.code_rounded,
                    label: developer.githubLabel,
                    onTap: () => _openGithub(context, developer),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ContactLinkTile(
                    icon: Icons.mail_outline_rounded,
                    label: developer.emailLabel,
                    onTap: () => _openEmail(context, developer),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openGithub(
    BuildContext context,
    _DeveloperProfile developer,
  ) async {
    final uri = Uri.tryParse(developer.githubUrl);
    if (uri == null) {
      _showPendingMessage(context, 'GitHub');
      return;
    }

    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && context.mounted) {
      _showPendingMessage(context, 'GitHub');
    }
  }

  Future<void> _openEmail(
    BuildContext context,
    _DeveloperProfile developer,
  ) async {
    final address = developer.emailAddress.trim();
    if (address.isEmpty) {
      _showPendingMessage(context, 'correo');
      return;
    }

    final uri = Uri(
      scheme: 'mailto',
      path: address,
    );
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && context.mounted) {
      _showPendingMessage(context, 'correo');
    }
  }

  void _showPendingMessage(BuildContext context, String channel) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Aún falta configurar el enlace de $channel para ${developer.name}.',
        ),
      ),
    );
  }
}

class _ContactLinkTile extends StatelessWidget {
  const _ContactLinkTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          children: [
            IconButton(
              onPressed: onTap,
              icon: Icon(icon),
              tooltip: label,
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _DeveloperProfile {
  const _DeveloperProfile({
    required this.name,
    required this.githubLabel,
    required this.githubUrl,
    required this.emailLabel,
    required this.emailAddress,
  });

  final String name;
  final String githubLabel;
  final String githubUrl;
  final String emailLabel;
  final String emailAddress;
}
