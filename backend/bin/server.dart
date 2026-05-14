import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

Response jsonResponse(Map<String, Object> body, {int statusCode = 200}) {
  return Response(
    statusCode,
    body: jsonEncode(body),
    headers: {'content-type': 'application/json'},
  );
}

Router buildRouter() {
  final router = Router();

  router.get('/health', (Request request) {
    return jsonResponse({
      'status': 'ok',
      'service': 'docker-mobile-backend',
      'runtime': 'dart',
    });
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
