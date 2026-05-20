import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class DockerContainer {
  const DockerContainer({
    required this.id,
    required this.name,
    required this.image,
    required this.state,
    required this.status,
  });

  final String id;
  final String name;
  final String image;
  final String state;
  final String status;

  bool get isRunning => state == 'running';

  String get shortId => id.length > 12 ? id.substring(0, 12) : id;

  factory DockerContainer.fromJson(Map<String, Object?> json) {
    return DockerContainer(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }
}

class ContainersApiException implements Exception {
  const ContainersApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ContainersApi {
  ContainersApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<DockerContainer>> listContainers({
    required String baseUrl,
    required String accessToken,
  }) async {
    final uri = Uri.parse('${_normalizeBaseUrl(baseUrl)}/containers');

    http.Response response;
    try {
      response = await _client
          .get(uri, headers: {'authorization': 'Bearer $accessToken'})
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw const ContainersApiException(
        'Tempo esgotado ao buscar containers.',
      );
    } on FormatException {
      throw const ContainersApiException('URL do backend invalida.');
    } on Exception {
      throw const ContainersApiException(
        'Nao foi possivel conectar ao backend.',
      );
    }

    final body = _decodeBody(response.body);

    if (response.statusCode == 200) {
      final containers = body['containers'];
      if (containers is List) {
        return containers
            .whereType<Map<String, Object?>>()
            .map(DockerContainer.fromJson)
            .toList();
      }

      throw const ContainersApiException('Resposta de containers invalida.');
    }

    if (response.statusCode == 401) {
      throw const ContainersApiException(
        'Sessao invalida. Faca login novamente.',
      );
    }

    final message = body['message'];
    throw ContainersApiException(
      message is String && message.isNotEmpty
          ? message
          : 'Falha ao buscar containers.',
    );
  }

  Future<void> runContainerAction({
    required String baseUrl,
    required String accessToken,
    required String containerId,
    required String action,
  }) async {
    final uri = Uri.parse(
      '${_normalizeBaseUrl(baseUrl)}/containers/${Uri.encodeComponent(containerId)}/$action',
    );

    http.Response response;
    try {
      response = await _client
          .post(uri, headers: {'authorization': 'Bearer $accessToken'})
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw const ContainersApiException('Tempo esgotado ao executar acao.');
    } on FormatException {
      throw const ContainersApiException('URL do backend invalida.');
    } on Exception {
      throw const ContainersApiException(
        'Nao foi possivel conectar ao backend.',
      );
    }

    if (response.statusCode == 200) {
      return;
    }

    final body = _decodeBody(response.body);

    if (response.statusCode == 401) {
      throw const ContainersApiException(
        'Sessao invalida. Faca login novamente.',
      );
    }

    final message = body['message'];
    throw ContainersApiException(
      message is String && message.isNotEmpty
          ? message
          : 'Falha ao executar acao.',
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
