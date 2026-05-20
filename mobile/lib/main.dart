import 'package:flutter/material.dart';

import 'auth_api.dart';

typedef LoginCallback =
    Future<LoginResult> Function({
      required String baseUrl,
      required String username,
      required String password,
    });

void main() {
  runApp(const DockerMobileApp());
}

class DockerMobileApp extends StatelessWidget {
  const DockerMobileApp({super.key, this.login});

  final LoginCallback? login;

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
      home: LoginPage(login: login ?? AuthApi().login),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.login});

  final LoginCallback login;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _baseUrlController = TextEditingController(
    text: 'http://localhost:3000',
  );
  final _usernameController = TextEditingController(text: 'admin');
  final _passwordController = TextEditingController(text: 'admin');

  var _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _baseUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await widget.login(
        baseUrl: _baseUrlController.text,
        username: _usernameController.text,
        password: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => HomePage(
            accessToken: result.accessToken,
            backendUrl: _baseUrlController.text.trim(),
          ),
        ),
      );
    } on AuthApiException catch (error) {
      _showError(error.message);
    } on Exception {
      _showError('Nao foi possivel fazer login.');
    }
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
      _errorMessage = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Docker Mobile Admin'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.dns_outlined, color: colors.primary, size: 44),
                    const SizedBox(height: 16),
                    Text(
                      'Entrar no painel',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Use as credenciais de desenvolvimento para conectar no backend Dart.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _baseUrlController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'URL do backend',
                        prefixIcon: Icon(Icons.link),
                      ),
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.next,
                      validator: _requiredField,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Usuario',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: _requiredField,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Senha',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      obscureText: true,
                      onFieldSubmitted: (_) => _isLoading ? null : _submit(),
                      validator: _requiredField,
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: colors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _isLoading ? null : _submit,
                      icon: _isLoading
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.login),
                      label: Text(_isLoading ? 'Entrando...' : 'Entrar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _requiredField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obrigatorio.';
    }

    return null;
  }
}

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.accessToken,
    required this.backendUrl,
  });

  final String accessToken;
  final String backendUrl;

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
                      'Login conectado. A listagem de containers entra no proximo passo.',
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
                value: 'Conectado',
                color: colors.primary,
              ),
              const SizedBox(height: 12),
              _StatusRow(
                icon: Icons.lock_outline,
                label: 'Autenticacao JWT',
                value: 'Token recebido',
                color: colors.secondary,
              ),
              const SizedBox(height: 12),
              _StatusRow(
                icon: Icons.phone_android,
                label: 'Flutter app',
                value: 'Login validado',
                color: colors.tertiary,
              ),
              const SizedBox(height: 20),
              Text(
                'Backend: $backendUrl',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => LoginPage(login: AuthApi().login),
                    ),
                  );
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sair'),
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
            child: Text(label, style: Theme.of(context).textTheme.titleMedium),
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
