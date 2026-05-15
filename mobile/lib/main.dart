import 'package:flutter/material.dart';

void main() {
  runApp(const DockerMobileApp());
}

class DockerMobileApp extends StatelessWidget {
  const DockerMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Docker Mobile Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Docker Mobile Admin'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.dns_outlined,
                      color: colors.onPrimaryContainer,
                      size: 36,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Painel de containers',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: colors.onPrimaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Base mobile criada. O proximo passo sera conectar o login ao backend Dart.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _StatusRow(
                icon: Icons.check_circle_outline,
                label: 'Backend Dart',
                value: 'Validado',
                color: colors.primary,
              ),
              const SizedBox(height: 12),
              _StatusRow(
                icon: Icons.lock_outline,
                label: 'Autenticacao JWT',
                value: 'Validada',
                color: colors.secondary,
              ),
              const SizedBox(height: 12),
              _StatusRow(
                icon: Icons.phone_android,
                label: 'Flutter app',
                value: 'Base criada',
                color: colors.tertiary,
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: null,
                icon: const Icon(Icons.login),
                label: const Text('Login entra no proximo passo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
