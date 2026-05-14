import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

import 'package:docker_mobile_backend/auth_service.dart';
import 'package:docker_mobile_backend/docker_client.dart';

Response jsonResponse(Map<String, Object?> body, {int statusCode = 200}) {
  return Response(
    statusCode,
    body: jsonEncode(body),
    headers: {'content-type': 'application/json'},
  );
}

Router buildRouter() {
  final authService = AuthService();
  final dockerClient = DockerClient();
  final router = Router();

  router.get('/health', (Request request) {
    return jsonResponse({
      'status': 'ok',
      'service': 'docker-mobile-backend',
      'runtime': 'dart',
    });
  });

  router.post('/auth/login', (Request request) async {
    try {
      final token = await authService.login(request);

      return jsonResponse({'accessToken': token, 'tokenType': 'Bearer'});
    } on FormatException {
      return jsonResponse({
        'error': 'invalid_json',
        'message': 'JSON invalido.',
      }, statusCode: HttpStatus.badRequest);
    } on AuthException catch (error) {
      return jsonResponse({
        'error': 'invalid_credentials',
        'message': error.message,
      }, statusCode: HttpStatus.unauthorized);
    }
  });

  router.get('/containers', (Request request) async {
    try {
      authService.validateAuthHeader(request.headers['authorization']);
      final containers = await dockerClient.listContainers();

      return jsonResponse({'containers': containers});
    } on AuthException catch (error) {
      return jsonResponse({
        'error': 'unauthorized',
        'message': error.message,
      }, statusCode: HttpStatus.unauthorized);
    } on DockerApiException catch (error) {
      return jsonResponse({
        'error': 'docker_unavailable',
        'message': error.message,
      }, statusCode: HttpStatus.serviceUnavailable);
    }
  });

  return router;
}

Future<void> main() async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 3000;
  final router = buildRouter();
  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addHandler(router.call);
  final server = await serve(handler, InternetAddress.anyIPv4, port);

  stdout.writeln(
    'Docker Mobile backend running on http://localhost:${server.port}',
  );
}
