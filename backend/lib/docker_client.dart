import 'dart:convert';
import 'dart:io';

class DockerApiException implements Exception {
  DockerApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DockerClient {
  DockerClient({HttpClient? httpClient, String? baseUrl})
    : _httpClient = httpClient ?? HttpClient(),
      _baseUrl = baseUrl ?? 'http://127.0.0.1:2375';

  final HttpClient _httpClient;
  final String _baseUrl;

  Future<List<Map<String, Object?>>> listContainers() async {
    final uri = Uri.parse('$_baseUrl/containers/json?all=true');

    try {
      final request = await _httpClient.getUrl(uri);
      final response = await request.close();
      final body = await utf8.decodeStream(response);

      if (response.statusCode != HttpStatus.ok) {
        throw DockerApiException(
          'Docker retornou status ${response.statusCode}: $body',
        );
      }

      final decoded = jsonDecode(body);
      if (decoded is! List) {
        throw DockerApiException('Resposta inesperada da Docker Engine API.');
      }

      return decoded.map<Map<String, Object?>>((container) {
        if (container is! Map<String, Object?>) {
          throw DockerApiException('Container retornado em formato invalido.');
        }

        final names = container['Names'];
        final name = names is List && names.isNotEmpty
            ? names.first.toString().replaceFirst('/', '')
            : '';

        return {
          'id': container['Id'],
          'name': name,
          'image': container['Image'],
          'state': container['State'],
          'status': container['Status'],
        };
      }).toList();
    } on SocketException catch (error) {
      throw DockerApiException(
        'Nao foi possivel conectar ao Docker em $_baseUrl. '
        'Verifique se o Docker Desktop esta aberto e se a porta 2375 esta habilitada. '
        'Detalhe: ${error.message}',
      );
    } on FormatException catch (error) {
      throw DockerApiException(
        'Docker retornou uma resposta que nao parece JSON valido. '
        'Detalhe: ${error.message}',
      );
    }
  }

  Future<void> startContainer(String id) {
    return _postContainerAction(id, 'start');
  }

  Future<void> stopContainer(String id) {
    return _postContainerAction(id, 'stop');
  }

  Future<void> restartContainer(String id) {
    return _postContainerAction(id, 'restart');
  }

  Future<String> fetchContainerLogs(String id, {int tail = 100}) async {
    if (id.trim().isEmpty) {
      throw DockerApiException('ID do container nao informado.');
    }

    final uri =
        Uri.parse(
          '$_baseUrl/containers/${Uri.encodeComponent(id)}/logs',
        ).replace(
          queryParameters: {
            'stdout': 'true',
            'stderr': 'true',
            'tail': tail.toString(),
          },
        );

    try {
      final request = await _httpClient.getUrl(uri);
      final response = await request.close();
      final bytes = await response.fold<List<int>>(
        <int>[],
        (buffer, chunk) => buffer..addAll(chunk),
      );

      if (response.statusCode == HttpStatus.ok) {
        return _decodeDockerLogs(bytes);
      }

      final body = utf8.decode(bytes, allowMalformed: true);
      if (response.statusCode == HttpStatus.notFound) {
        throw DockerApiException('Container nao encontrado.');
      }

      throw DockerApiException(
        'Docker retornou status ${response.statusCode}: $body',
      );
    } on SocketException catch (error) {
      throw DockerApiException(
        'Nao foi possivel conectar ao Docker em $_baseUrl. '
        'Verifique se o Docker Desktop esta aberto e se a porta 2375 esta habilitada. '
        'Detalhe: ${error.message}',
      );
    }
  }

  Future<void> _postContainerAction(String id, String action) async {
    if (id.trim().isEmpty) {
      throw DockerApiException('ID do container nao informado.');
    }

    final uri = Uri.parse(
      '$_baseUrl/containers/${Uri.encodeComponent(id)}/$action',
    );

    try {
      final request = await _httpClient.postUrl(uri);
      final response = await request.close();
      final body = await utf8.decodeStream(response);

      if (response.statusCode == HttpStatus.noContent ||
          response.statusCode == HttpStatus.notModified) {
        return;
      }

      if (response.statusCode == HttpStatus.notFound) {
        throw DockerApiException('Container nao encontrado.');
      }

      throw DockerApiException(
        'Docker retornou status ${response.statusCode}: $body',
      );
    } on SocketException catch (error) {
      throw DockerApiException(
        'Nao foi possivel conectar ao Docker em $_baseUrl. '
        'Verifique se o Docker Desktop esta aberto e se a porta 2375 esta habilitada. '
        'Detalhe: ${error.message}',
      );
    }
  }

  String _decodeDockerLogs(List<int> bytes) {
    if (bytes.length < 8) {
      return utf8.decode(bytes, allowMalformed: true).trimRight();
    }

    final payload = <int>[];
    var offset = 0;

    while (offset + 8 <= bytes.length) {
      final streamType = bytes[offset];
      final isDockerFrame =
          (streamType == 1 || streamType == 2) &&
          bytes[offset + 1] == 0 &&
          bytes[offset + 2] == 0 &&
          bytes[offset + 3] == 0;

      if (!isDockerFrame) {
        return utf8.decode(bytes, allowMalformed: true).trimRight();
      }

      final frameLength =
          (bytes[offset + 4] << 24) |
          (bytes[offset + 5] << 16) |
          (bytes[offset + 6] << 8) |
          bytes[offset + 7];
      final frameStart = offset + 8;
      final frameEnd = frameStart + frameLength;

      if (frameEnd > bytes.length) {
        return utf8.decode(bytes, allowMalformed: true).trimRight();
      }

      payload.addAll(bytes.sublist(frameStart, frameEnd));
      offset = frameEnd;
    }

    if (offset != bytes.length) {
      return utf8.decode(bytes, allowMalformed: true).trimRight();
    }

    return utf8.decode(payload, allowMalformed: true).trimRight();
  }
}
