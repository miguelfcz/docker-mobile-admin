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
}
