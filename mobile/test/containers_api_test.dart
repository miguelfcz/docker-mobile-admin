import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:docker_mobile_app/containers_api.dart';

void main() {
  test('listContainers returns containers on success', () async {
    final api = ContainersApi(
      client: MockClient((request) async {
        expect(request.url.toString(), 'http://localhost:3000/containers');
        expect(request.headers['authorization'], 'Bearer token');

        return http.Response(
          '{"containers":[{"id":"abc1234567890000","name":"api","image":"nginx","state":"running","status":"Up 2 minutes"}]}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final containers = await api.listContainers(
      baseUrl: 'http://localhost:3000',
      accessToken: 'token',
    );

    expect(containers, hasLength(1));
    expect(containers.first.name, 'api');
    expect(containers.first.image, 'nginx');
    expect(containers.first.shortId, 'abc123456789');
    expect(containers.first.isRunning, isTrue);
  });

  test('listContainers throws a friendly error on invalid token', () async {
    final api = ContainersApi(
      client: MockClient((request) async {
        return http.Response(
          '{"error":"unauthorized","message":"Token invalido."}',
          401,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    expect(
      () => api.listContainers(
        baseUrl: 'http://localhost:3000',
        accessToken: 'bad-token',
      ),
      throwsA(
        isA<ContainersApiException>().having(
          (error) => error.message,
          'message',
          'Sessao invalida. Faca login novamente.',
        ),
      ),
    );
  });

  test('runContainerAction posts the selected action', () async {
    final api = ContainersApi(
      client: MockClient((request) async {
        expect(
          request.url.toString(),
          'http://localhost:3000/containers/abc123/stop',
        );
        expect(request.method, 'POST');
        expect(request.headers['authorization'], 'Bearer token');

        return http.Response(
          '{"success":true,"message":"Container parado."}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    await api.runContainerAction(
      baseUrl: 'http://localhost:3000',
      accessToken: 'token',
      containerId: 'abc123',
      action: 'stop',
    );
  });
}
