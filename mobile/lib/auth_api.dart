import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class LoginResult {
  const LoginResult({required this.accessToken, required this.tokenType});

  final String accessToken;
  final String tokenType;
}

class AuthApiException implements Exception {
  const AuthApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthApi {
  AuthApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<LoginResult> login({
    required String baseUrl,
    required String username,
    required String password,
  }) async {
    final uri = Uri.parse('${_normalizeBaseUrl(baseUrl)}/auth/login');

    http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: {'content-type': 'application/json'},
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw const AuthApiException('Tempo esgotado ao conectar no backend.');
    } on FormatException {
      throw const AuthApiException('URL do backend invalida.');
    } on Exception {
      throw const AuthApiException('Nao foi possivel conectar ao backend.');
    }

    final body = _decodeBody(response.body);

    if (response.statusCode == 200) {
      final accessToken = body['accessToken'];
      final tokenType = body['tokenType'];

      if (accessToken is String && accessToken.isNotEmpty) {
        return LoginResult(
          accessToken: accessToken,
          tokenType: tokenType is String ? tokenType : 'Bearer',
        );
      }

      throw const AuthApiException('Resposta de login invalida.');
    }

    if (response.statusCode == 401) {
      throw const AuthApiException('Usuario ou senha invalidos.');
    }

    final message = body['message'];
    throw AuthApiException(
      message is String && message.isNotEmpty
          ? message
          : 'Falha ao fazer login.',
    );
  }

  Map<String, Object?> _decodeBody(String body) {
    if (body.isEmpty) {
      return {};
    }

    final decoded = jsonDecode(body);
    if (decoded is Map<String, Object?>) {
      return decoded;
    }

    return {};
  }

  String _normalizeBaseUrl(String baseUrl) {
    final trimmed = baseUrl.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }

    return trimmed;
  }
}
