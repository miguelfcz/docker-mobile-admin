import 'dart:convert';
import 'dart:io';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:shelf/shelf.dart';

class AuthException implements Exception {
  AuthException(this.message);

  final String message;
}

class AuthService {
  AuthService({String? username, String? password, String? jwtSecret})
    : _username = username ?? Platform.environment['AUTH_USERNAME'] ?? 'admin',
      _password = password ?? Platform.environment['AUTH_PASSWORD'] ?? 'admin',
      _jwtSecret =
          jwtSecret ??
          Platform.environment['JWT_SECRET'] ??
          'dev-secret-change-me';

  final String _username;
  final String _password;
  final String _jwtSecret;
  static const _issuer = 'docker-mobile-admin';

  Future<String> login(Request request) async {
    final body = await request.readAsString();
    final decoded = jsonDecode(body);

    if (decoded is! Map<String, Object?>) {
      throw AuthException('Corpo da requisicao invalido.');
    }

    final username = decoded['username'];
    final password = decoded['password'];

    if (username != _username || password != _password) {
      throw AuthException('Usuario ou senha invalidos.');
    }

    final jwt = JWT({'sub': username, 'role': 'admin'}, issuer: _issuer);

    return jwt.sign(SecretKey(_jwtSecret), expiresIn: const Duration(hours: 8));
  }

  void validateAuthHeader(String? authorizationHeader) {
    if (authorizationHeader == null || authorizationHeader.isEmpty) {
      throw AuthException('Token nao informado.');
    }

    const bearerPrefix = 'Bearer ';
    if (!authorizationHeader.startsWith(bearerPrefix)) {
      throw AuthException('Formato do token invalido.');
    }

    final token = authorizationHeader.substring(bearerPrefix.length).trim();
    if (token.isEmpty) {
      throw AuthException('Token nao informado.');
    }

    try {
      JWT.verify(token, SecretKey(_jwtSecret), issuer: _issuer);
    } on JWTExpiredException {
      throw AuthException('Token expirado.');
    } on JWTException {
      throw AuthException('Token invalido.');
    }
  }
}
