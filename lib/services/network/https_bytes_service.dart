import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

class HttpsBytesService {
  HttpsBytesService._();

  static final HttpsBytesService instance = HttpsBytesService._();

  static const int defaultMaxBytes = 10 * 1024 * 1024;

  Future<Uint8List?> get({
    required String url,
    Duration timeout = const Duration(seconds: 10),
    int maxBytes = defaultMaxBytes,
    bool Function()? isCancelled,
  }) async {
    HttpClient? client;
    try {
      if (isCancelled?.call() ?? false) return null;
      final uri = Uri.tryParse(url);
      if (uri == null || uri.scheme != 'https') return null;
      client = HttpClient()..connectionTimeout = timeout;
      final request = await client.getUrl(uri).timeout(timeout);
      final response = await request.close().timeout(timeout);
      if (response.statusCode != HttpStatus.ok) return null;
      final builder = BytesBuilder(copy: false);
      await for (final chunk in response.timeout(timeout)) {
        if (isCancelled?.call() ?? false) return null;
        builder.add(chunk);
        if (builder.length > maxBytes) return null;
      }
      return builder.takeBytes();
    } catch (_) {
      return null;
    } finally {
      client?.close(force: true);
    }
  }
}
