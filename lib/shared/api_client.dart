import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final Map<String, String> fields;
  const ApiException(this.message, [this.fields = const {}]);
  @override
  String toString() => message;
}

class ApiClient {
  final http.Client client;
  final String baseUrl;
  ApiClient({
    http.Client? client,
    this.baseUrl = const String.fromEnvironment(
      'API_URL',
      defaultValue: 'http://127.0.0.1:3001',
    ),
  }) : client = client ?? http.Client();

  Future<dynamic> request(
    String method,
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    try {
      final request = http.Request(method, Uri.parse('$baseUrl$path'));
      request.headers['Content-Type'] = 'application/json';
      if (body != null) request.body = jsonEncode(body);
      final response = await client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 12));
      if (response.statusCode == 204) return null;
      dynamic data;
      try {
        data = jsonDecode(utf8.decode(response.bodyBytes));
      } on FormatException {
        throw const ApiException(
          'O servidor enviou uma resposta inesperada. Tente novamente.',
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final fields = data is Map && data['campos'] is Map
            ? Map<String, dynamic>.from(data['campos'])
                  .map((key, value) => MapEntry(key, value.toString()))
            : <String, String>{};
        throw ApiException(
          data is Map
              ? data['erro']?.toString() ?? 'Não foi possível salvar.'
              : 'Não foi possível salvar.',
          fields,
        );
      }
      return data;
    } on TimeoutException {
      throw const ApiException(
        'A conexão demorou mais que o esperado. Tente novamente.',
      );
    } on http.ClientException {
      throw const ApiException(
        'Não conseguimos conectar. Confira se a API está em execução e tente novamente.',
      );
    }
  }

  void close() => client.close();
}
