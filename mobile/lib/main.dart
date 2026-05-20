import 'package:flutter/material.dart';

import 'auth_api.dart';
import 'containers_api.dart';

typedef LoginCallback =
    Future<LoginResult> Function({
      required String baseUrl,
      required String username,
      required String password,
    });

typedef ListContainersCallback =
    Future<List<DockerContainer>> Function({
      required String baseUrl,
      required String accessToken,
    });

void main() {
  runApp(const DockerMobileApp());
}

class DockerMobileApp extends StatelessWidget {
  const DockerMobileApp({super.key, this.login, this.listContainers});

  final LoginCallback? login;
  final ListContainersCallback? listContainers;

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
      home: LoginPage(
        login: login ?? AuthApi().login,
        listContainers: listContainers ?? ContainersApi().listContainers,
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.login,
    required this.listContainers,
  });

  final LoginCallback login;
  final ListContainersCallback listContainers;

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
            listContainers: widget.listContainers,
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

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.accessToken,
    required this.backendUrl,
    required this.listContainers,
  });

  final String accessToken;
  final String backendUrl;
  final ListContainersCallback listContainers;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var _isLoading = true;
  String? _errorMessage;
  List<DockerContainer> _containers = [];

  @override
  void initState() {
    super.initState();
    _loadContainers();
  }

  Future<void> _loadContainers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final containers = await widget.listContainers(
        baseUrl: widget.backendUrl,
        accessToken: widget.accessToken,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _containers = containers;
        _isLoading = false;
      });
    } on ContainersApiException catch (error) {
      _showLoadError(error.message);
    } on Exception {
      _showLoadError('Nao foi possivel buscar containers.');
    }
  }

  void _showLoadError(String message) {
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
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadContainers,
            tooltip: 'Atualizar containers',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PanelHeader(
                backendUrl: widget.backendUrl,
                totalContainers: _containers.length,
              ),
              const SizedBox(height: 16),
              Expanded(child: _buildContent(colors)),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => LoginPage(
                        login: AuthApi().login,
                        listContainers: ContainersApi().listContainers,
                      ),
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

  Widget _buildContent(ColorScheme colors) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _LoadMessage(
        icon: Icons.cloud_off_outlined,
        title: 'Nao foi possivel carregar containers',
        message: _errorMessage!,
        actionLabel: 'Tentar novamente',
        onPressed: _loadContainers,
      );
    }

    if (_containers.isEmpty) {
      return _LoadMessage(
        icon: Icons.inbox_outlined,
        title: 'Nenhum container encontrado',
        message:
            'Quando houver containers no Docker Desktop, eles aparecem aqui.',
        actionLabel: 'Atualizar',
        onPressed: _loadContainers,
      );
    }

    return ListView.separated(
      itemCount: _containers.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return _ContainerListItem(container: _containers[index]);
      },
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({required this.backendUrl, required this.totalContainers});

  final String backendUrl;
  final int totalContainers;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.dns_outlined, color: colors.onPrimaryContainer, size: 36),
          const SizedBox(height: 16),
          Text(
            'Painel de containers',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: colors.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$totalContainers containers encontrados',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colors.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Backend: $backendUrl',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.onPrimaryContainer),
          ),
        ],
      ),
    );
  }
}

class _ContainerListItem extends StatelessWidget {
  const _ContainerListItem({required this.container});

  final DockerContainer container;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final statusColor = container.isRunning ? colors.primary : colors.error;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inventory_2_outlined, color: statusColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  container.name.isEmpty ? container.shortId : container.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _StatusBadge(
                label: container.state.isEmpty ? 'unknown' : container.state,
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ContainerDetail(icon: Icons.image_outlined, text: container.image),
          const SizedBox(height: 8),
          _ContainerDetail(
            icon: Icons.info_outline,
            text: container.status.isEmpty
                ? 'Sem status informado'
                : container.status,
          ),
          const SizedBox(height: 8),
          _ContainerDetail(icon: Icons.tag, text: container.shortId),
        ],
      ),
    );
  }
}

class _ContainerDetail extends StatelessWidget {
  const _ContainerDetail({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.secondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text.isEmpty ? '-' : text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LoadMessage extends StatelessWidget {
  const _LoadMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: colors.secondary),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.refresh),
            label: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}
