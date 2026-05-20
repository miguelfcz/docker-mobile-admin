import 'dart:async';

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

typedef ContainerActionCallback =
    Future<void> Function({
      required String baseUrl,
      required String accessToken,
      required String containerId,
      required String action,
    });

typedef FetchContainerLogsCallback =
    Future<String> Function({
      required String baseUrl,
      required String accessToken,
      required String containerId,
    });

void main() {
  runApp(const DockerMobileApp());
}

class DockerMobileApp extends StatelessWidget {
  const DockerMobileApp({
    super.key,
    this.login,
    this.listContainers,
    this.runContainerAction,
    this.fetchContainerLogs,
  });

  final LoginCallback? login;
  final ListContainersCallback? listContainers;
  final ContainerActionCallback? runContainerAction;
  final FetchContainerLogsCallback? fetchContainerLogs;

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
        runContainerAction:
            runContainerAction ?? ContainersApi().runContainerAction,
        fetchContainerLogs:
            fetchContainerLogs ?? ContainersApi().fetchContainerLogs,
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.login,
    required this.listContainers,
    required this.runContainerAction,
    required this.fetchContainerLogs,
  });

  final LoginCallback login;
  final ListContainersCallback listContainers;
  final ContainerActionCallback runContainerAction;
  final FetchContainerLogsCallback fetchContainerLogs;

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
            runContainerAction: widget.runContainerAction,
            fetchContainerLogs: widget.fetchContainerLogs,
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
    required this.runContainerAction,
    required this.fetchContainerLogs,
  });

  final String accessToken;
  final String backendUrl;
  final ListContainersCallback listContainers;
  final ContainerActionCallback runContainerAction;
  final FetchContainerLogsCallback fetchContainerLogs;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var _isLoading = true;
  String? _errorMessage;
  String? _actionInProgressKey;
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
        _actionInProgressKey = null;
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
      _actionInProgressKey = null;
    });
  }

  Future<void> _runContainerAction(
    DockerContainer container,
    String action,
  ) async {
    final actionKey = '${container.id}:$action';

    setState(() {
      _actionInProgressKey = actionKey;
      _errorMessage = null;
    });

    try {
      await widget.runContainerAction(
        baseUrl: widget.backendUrl,
        accessToken: widget.accessToken,
        containerId: container.id,
        action: action,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_successMessageFor(action))));

      await _loadContainers();
    } on ContainersApiException catch (error) {
      _showActionError(error.message);
    } on Exception {
      _showActionError('Nao foi possivel executar a acao.');
    }
  }

  void _showActionError(String message) {
    if (!mounted) {
      return;
    }

    setState(() {
      _actionInProgressKey = null;
      _errorMessage = message;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showContainerLogs(DockerContainer container) {
    return showDialog<void>(
      context: context,
      builder: (_) => _ContainerLogsDialog(
        container: container,
        backendUrl: widget.backendUrl,
        accessToken: widget.accessToken,
        fetchContainerLogs: widget.fetchContainerLogs,
      ),
    );
  }

  String _successMessageFor(String action) {
    return switch (action) {
      'start' => 'Container iniciado.',
      'stop' => 'Container parado.',
      'restart' => 'Container reiniciado.',
      _ => 'Acao executada.',
    };
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
                        runContainerAction: ContainersApi().runContainerAction,
                        fetchContainerLogs: ContainersApi().fetchContainerLogs,
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
        final container = _containers[index];

        return _ContainerListItem(
          container: container,
          actionInProgressKey: _actionInProgressKey,
          onAction: _runContainerAction,
          onLogs: _showContainerLogs,
        );
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
  const _ContainerListItem({
    required this.container,
    required this.actionInProgressKey,
    required this.onAction,
    required this.onLogs,
  });

  final DockerContainer container;
  final String? actionInProgressKey;
  final Future<void> Function(DockerContainer container, String action)
  onAction;
  final Future<void> Function(DockerContainer container) onLogs;

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
          const SizedBox(height: 14),
          _ContainerActions(
            container: container,
            actionInProgressKey: actionInProgressKey,
            onAction: onAction,
            onLogs: onLogs,
          ),
        ],
      ),
    );
  }
}

class _ContainerActions extends StatelessWidget {
  const _ContainerActions({
    required this.container,
    required this.actionInProgressKey,
    required this.onAction,
    required this.onLogs,
  });

  final DockerContainer container;
  final String? actionInProgressKey;
  final Future<void> Function(DockerContainer container, String action)
  onAction;
  final Future<void> Function(DockerContainer container) onLogs;

  @override
  Widget build(BuildContext context) {
    final hasActionRunning = actionInProgressKey != null;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.play_arrow,
                label: 'Start',
                isLoading: actionInProgressKey == '${container.id}:start',
                onPressed: hasActionRunning || container.isRunning
                    ? null
                    : () => onAction(container, 'start'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionButton(
                icon: Icons.stop,
                label: 'Stop',
                isLoading: actionInProgressKey == '${container.id}:stop',
                onPressed: hasActionRunning || !container.isRunning
                    ? null
                    : () => onAction(container, 'stop'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionButton(
                icon: Icons.restart_alt,
                label: 'Restart',
                isLoading: actionInProgressKey == '${container.id}:restart',
                onPressed: hasActionRunning
                    ? null
                    : () => onAction(container, 'restart'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => onLogs(container),
            icon: const Icon(Icons.terminal),
            label: const Text('Logs'),
          ),
        ),
      ],
    );
  }
}

class _ContainerLogsDialog extends StatefulWidget {
  const _ContainerLogsDialog({
    required this.container,
    required this.backendUrl,
    required this.accessToken,
    required this.fetchContainerLogs,
  });

  final DockerContainer container;
  final String backendUrl;
  final String accessToken;
  final FetchContainerLogsCallback fetchContainerLogs;

  @override
  State<_ContainerLogsDialog> createState() => _ContainerLogsDialogState();
}

class _ContainerLogsDialogState extends State<_ContainerLogsDialog> {
  Timer? _refreshTimer;
  var _isLoading = true;
  var _isRefreshing = false;
  var _logs = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLogs(showLoading: true);
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _loadLogs(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadLogs({bool showLoading = false}) async {
    if (_isRefreshing) {
      return;
    }

    setState(() {
      _isRefreshing = true;
      if (showLoading) {
        _isLoading = true;
      }
    });

    try {
      final logs = await widget.fetchContainerLogs(
        baseUrl: widget.backendUrl,
        accessToken: widget.accessToken,
        containerId: widget.container.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _logs = logs;
        _errorMessage = null;
        _isLoading = false;
        _isRefreshing = false;
      });
    } on ContainersApiException catch (error) {
      _showError(error.message);
    } on Exception {
      _showError('Nao foi possivel buscar logs.');
    }
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }

    setState(() {
      _errorMessage = message;
      _isLoading = false;
      _isRefreshing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final title = widget.container.name.isEmpty
        ? widget.container.shortId
        : widget.container.name;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.terminal),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Logs - $title', overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
      content: SizedBox(width: 640, height: 360, child: _buildContent(colors)),
      actions: [
        TextButton.icon(
          onPressed: _isRefreshing ? null : () => _loadLogs(showLoading: true),
          icon: _isRefreshing
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh),
          label: const Text('Atualizar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      ],
    );
  }

  Widget _buildContent(ColorScheme colors) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _LoadMessage(
        icon: Icons.error_outline,
        title: 'Nao foi possivel carregar logs',
        message: _errorMessage!,
        actionLabel: 'Tentar novamente',
        onPressed: () => _loadLogs(showLoading: true),
      );
    }

    final text = _logs.trim().isEmpty
        ? 'Nenhum log recente encontrado.'
        : _logs;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        child: SelectableText(
          text,
          style: TextStyle(
            color: colors.onInverseSurface,
            fontFamily: 'monospace',
            fontSize: 13,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: isLoading
          ? const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon),
      label: Text(label),
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
