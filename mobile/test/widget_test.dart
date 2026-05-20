import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:docker_mobile_app/auth_api.dart';
import 'package:docker_mobile_app/containers_api.dart';
import 'package:docker_mobile_app/main.dart';

void main() {
  testWidgets('shows the login screen first', (tester) async {
    await tester.pumpWidget(_buildApp());

    expect(find.text('Docker Mobile Admin'), findsOneWidget);
    expect(find.text('Entrar no painel'), findsOneWidget);
    expect(find.text('URL do backend'), findsOneWidget);
    expect(find.text('Usuario'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
  });

  testWidgets('valid login opens the containers list', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        containers: [
          const DockerContainer(
            id: 'abc1234567890000',
            name: 'api',
            image: 'nginx',
            state: 'running',
            status: 'Up 2 minutes',
          ),
        ],
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Painel de containers'), findsOneWidget);
    expect(find.text('1 containers encontrados'), findsOneWidget);
    expect(find.text('api'), findsOneWidget);
    expect(find.text('nginx'), findsOneWidget);
    expect(find.text('running'), findsOneWidget);
    expect(find.text('Up 2 minutes'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Stop'), findsOneWidget);
    expect(find.text('Restart'), findsOneWidget);
    expect(find.text('Logs'), findsOneWidget);
  });

  testWidgets('container action calls the API and reloads the list', (
    tester,
  ) async {
    var actionCalled = '';
    var loadCount = 0;

    await tester.pumpWidget(
      _buildApp(
        listContainers: ({required baseUrl, required accessToken}) async {
          loadCount++;
          return const [
            DockerContainer(
              id: 'abc123',
              name: 'api',
              image: 'nginx',
              state: 'running',
              status: 'Up 2 minutes',
            ),
          ];
        },
        runContainerAction:
            ({
              required baseUrl,
              required accessToken,
              required containerId,
              required action,
            }) async {
              actionCalled = '$containerId:$action';
            },
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Stop'));
    await tester.pumpAndSettle();

    expect(actionCalled, 'abc123:stop');
    expect(loadCount, 2);
    expect(find.text('Container parado.'), findsOneWidget);
  });

  testWidgets('logs button opens container logs dialog', (tester) async {
    var logsContainerId = '';

    await tester.pumpWidget(
      _buildApp(
        containers: [
          const DockerContainer(
            id: 'abc123',
            name: 'api',
            image: 'nginx',
            state: 'running',
            status: 'Up 2 minutes',
          ),
        ],
        fetchContainerLogs:
            ({
              required baseUrl,
              required accessToken,
              required containerId,
            }) async {
              logsContainerId = containerId;
              return 'linha 1\nlinha 2';
            },
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Logs'));
    await tester.pumpAndSettle();

    expect(logsContainerId, 'abc123');
    expect(find.text('Logs - api'), findsOneWidget);
    expect(find.text('linha 1\nlinha 2'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Fechar'));
    await tester.pumpAndSettle();
  });

  testWidgets('empty containers list shows an empty state', (tester) async {
    await tester.pumpWidget(_buildApp(containers: []));

    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Nenhum container encontrado'), findsOneWidget);
    expect(find.text('Atualizar'), findsOneWidget);
  });

  testWidgets('containers load error shows a retry action', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        listContainers: ({required baseUrl, required accessToken}) async {
          throw const ContainersApiException('Docker indisponivel.');
        },
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Nao foi possivel carregar containers'), findsOneWidget);
    expect(find.text('Docker indisponivel.'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);
  });

  testWidgets('invalid login shows an error message', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        login:
            ({required baseUrl, required username, required password}) async {
              throw const AuthApiException('Usuario ou senha invalidos.');
            },
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Usuario ou senha invalidos.'), findsOneWidget);
    expect(find.text('Entrar no painel'), findsOneWidget);
  });
}

Widget _buildApp({
  LoginCallback? login,
  ListContainersCallback? listContainers,
  ContainerActionCallback? runContainerAction,
  FetchContainerLogsCallback? fetchContainerLogs,
  List<DockerContainer> containers = const [
    DockerContainer(
      id: 'token',
      name: 'frontend',
      image: 'ticko-frontend',
      state: 'running',
      status: 'Up 1 hour',
    ),
  ],
}) {
  return DockerMobileApp(
    login:
        login ??
        ({required baseUrl, required username, required password}) async {
          return const LoginResult(accessToken: 'token', tokenType: 'Bearer');
        },
    listContainers:
        listContainers ??
        ({required baseUrl, required accessToken}) async {
          return containers;
        },
    runContainerAction:
        runContainerAction ??
        ({
          required baseUrl,
          required accessToken,
          required containerId,
          required action,
        }) async {},
    fetchContainerLogs:
        fetchContainerLogs ??
        ({required baseUrl, required accessToken, required containerId}) async {
          return '';
        },
  );
}
