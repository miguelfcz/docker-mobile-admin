import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:docker_mobile_app/auth_api.dart';

void main() {
  test('login returns the access token on success', () async {
    final api = AuthApi(
      client: MockClient((request) async {
        expect(request.url.toString(), 'http://localhost:3000/auth/login');

        return http.Response(
          '{"accessToken":"abc123","tokenType":"Bearer"}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final result = await api.login(
      baseUrl: 'http://localhost:3000',
      username: 'admin',
      password: 'admin',
    );

    expect(result.accessToken, 'abc123');
    expect(result.tokenType, 'Bearer');
  });

  test('login throws a friendly error on invalid credentials', () async {
    final api = AuthApi(
      client: MockClient((request) async {
        return http.Response(
          '{"error":"invalid_credentials","message":"Credenciais invalidas."}',
          401,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    expect(
      () => api.login(
        baseUrl: 'http://localhost:3000',
        username: 'admin',
        password: 'errada',
      ),
      throwsA(
        isA<AuthApiException>().having(
          (error) => error.message,
          'message',
          'Usuario ou senha invalidos.',
        ),
      ),
    );
  });
}
