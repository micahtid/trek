import 'dart:convert';

import 'package:http/http.dart' as http;

const String kConvexDeploymentUrl = 'https://grand-tortoise-682.convex.cloud';

/// HTTP-based Convex service that calls the built-in Convex HTTP API.
///
/// Replaces the convex_flutter Rust FFI client with simple POST requests
/// to `/api/query` and `/api/mutation`. No native compilation required.
class ConvexHttpService {
  ConvexHttpService._();

  static final ConvexHttpService instance = ConvexHttpService._();

  String? _token;

  /// Sets the Bearer token sent with every request.
  void setToken(String? token) {
    _token = token;
  }

  /// Clears the stored auth token.
  void clearToken() {
    _token = null;
  }

  /// Calls a Convex query function via HTTP POST.
  ///
  /// [path] is the function path, e.g. `"entries:getEntriesToday"`.
  /// [args] is the map of arguments to pass.
  ///
  /// Returns the parsed `value` field from the Convex response.
  Future<dynamic> query({
    required String path,
    Map<String, dynamic> args = const {},
  }) async {
    return _call(endpoint: 'query', path: path, args: args);
  }

  /// Calls a Convex mutation function via HTTP POST.
  ///
  /// Returns the parsed `value` field from the Convex response.
  Future<dynamic> mutation({
    required String path,
    Map<String, dynamic> args = const {},
  }) async {
    return _call(endpoint: 'mutation', path: path, args: args);
  }

  Future<dynamic> _call({
    required String endpoint,
    required String path,
    required Map<String, dynamic> args,
  }) async {
    final url = Uri.parse('$kConvexDeploymentUrl/api/$endpoint');
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }

    final body = json.encode({
      'path': path,
      'args': args,
      'format': 'json',
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is Map && decoded['status'] == 'success') {
        return decoded['value'];
      }
      if (decoded is Map && decoded['status'] == 'error') {
        throw ConvexHttpException(
          decoded['errorMessage'] as String? ?? 'Unknown Convex error',
        );
      }
      // Unexpected shape — return raw decoded
      return decoded;
    }

    throw ConvexHttpException(
      'HTTP ${response.statusCode}: ${response.body}',
    );
  }
}

class ConvexHttpException implements Exception {
  final String message;
  const ConvexHttpException(this.message);

  @override
  String toString() => 'ConvexHttpException: $message';
}
