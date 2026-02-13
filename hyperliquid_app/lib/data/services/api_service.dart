import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants.dart';
import 'http_client_stub.dart'
    if (dart.library.js_interop) 'http_client_web.dart';

class ApiService {
  final http.Client _client = createHttpClient();

  Future<dynamic> fetchInfo(
    String type, [
    Map<String, dynamic> params = const {},
  ]) async {
    final body = {'type': type, ...params};
    final response = await _client
        .post(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('API error: ${response.statusCode}');
    }
    return jsonDecode(response.body);
  }

  void dispose() {
    _client.close();
  }
}
