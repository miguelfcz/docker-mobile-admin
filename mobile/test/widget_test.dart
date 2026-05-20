import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:docker_mobile_app/auth_api.dart';
import 'package:docker_mobile_app/main.dart';

void main() {
  testWidgets('shows the login screen first', (tester) async {
    await tester.pumpWidget(
      DockerMobileApp(
        login:
            ({required baseUrl, required username, required password}) async {
              return const LoginResult(
                accessToken: 'token',
                tokenType: 'Bearer',
              );
            },
      ),
    );

    expect(find.text('Docker Mobile Admin'), findsOneWidget);
    expect(find.text('Entrar no painel'), findsOneWidget);
    expect(find.text('URL do backend'), findsOneWidget);
    expect(find.text('Usuario'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
  });

  testWidgets('valid login opens the containers panel', (tester) async {
    await tester.pumpWidget(
      DockerMobileApp(
        login:
            ({required baseUrl, required username, required password}) async {
              return const LoginResult(
                accessToken: 'token',
                tokenType: 'Bearer',
              );
            },
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Painel de containers'), findsOneWidget);
    expect(find.text('Login validado'), findsOneWidget);
    expect(find.text('Token recebido'), findsOneWidget);
  });

  testWidgets('invalid login shows an error message', (tester) async {
    await tester.pumpWidget(
      DockerMobileApp(
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
