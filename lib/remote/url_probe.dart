import 'dart:async';
import 'dart:io';

import 'package:pure_music/remote/remote_source.dart';

final _schemePattern = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.\-]*://');

/// 地址里是否已经带了协议（`http://`、`https://` …）。
bool hasUrlScheme(String input) => _schemePattern.hasMatch(input.trim());

/// 各服务的默认端口。只在用户没写端口时用来拼候选地址。
int? defaultPortForKind(RemoteSourceKind kind) => switch (kind) {
  RemoteSourceKind.jellyfin => 8096,
  RemoteSourceKind.navidrome => 4533,
  _ => null,
};

/// 去掉结尾多余的斜杠，但保留根路径的单个 `/`。
String stripTrailingSlash(String url) {
  var text = url.trim();
  while (text.length > 1 && text.endsWith('/')) {
    text = text.substring(0, text.length - 1);
  }
  return text;
}

bool _hasExplicitPort(String hostPart) {
  // host:port / [::1]:port；纯 IPv6 字面量不带方括号的情况在这里不用管。
  final bracket = RegExp(r'^\[[^\]]+\]:\d+$');
  if (bracket.hasMatch(hostPart)) return true;
  return RegExp(r'^[^:]+:\d+$').hasMatch(hostPart);
}

/// 把用户输入的地址补全成可用的 baseUrl。
///
/// - 已带协议：原样返回（只去尾部斜杠），不探测，避免自签证书等场景被改写。
/// - 没带协议：依次试 `https` → `http`（以及各服务的默认端口），
///   第一个能建立连接的胜出；都失败就退回 `http`，让后续请求给出明确报错。
///
/// 探测只要求「连得上」：401 / 404 / 405 都算通，说明主机和端口是活的。
Future<String> resolveRemoteBaseUrl(
  String input, {
  RemoteSourceKind? kind,
  Duration timeout = const Duration(milliseconds: 1500),
}) async {
  final text = input.trim();
  if (text.isEmpty) return text;
  if (hasUrlScheme(text)) return stripTrailingSlash(text);

  final slash = text.indexOf('/');
  final hostPart = slash < 0 ? text : text.substring(0, slash);
  final pathPart = slash < 0 ? '' : text.substring(slash);

  final candidates = <String>[];
  for (final scheme in const ['https', 'http']) {
    candidates.add('$scheme://$hostPart$pathPart');
  }
  final port = kind == null ? null : defaultPortForKind(kind);
  if (port != null && !_hasExplicitPort(hostPart)) {
    for (final scheme in const ['https', 'http']) {
      candidates.add('$scheme://$hostPart:$port$pathPart');
    }
  }

  for (final candidate in candidates) {
    if (await _reachable(candidate, timeout)) {
      return stripTrailingSlash(candidate);
    }
  }
  return stripTrailingSlash('http://$text');
}

/// 只发一个 GET 看有没有响应。不校验状态码 —— 有响应就说明主机活着。
Future<bool> _reachable(String url, Duration timeout) async {
  final client = HttpClient()..connectionTimeout = timeout;
  try {
    final request = await client.getUrl(Uri.parse(url)).timeout(timeout);
    request.headers.set(HttpHeaders.userAgentHeader, 'PureMusic/probe');
    final response = await request.close().timeout(timeout);
    await response.drain<void>().timeout(timeout);
    return true;
  } catch (_) {
    return false;
  } finally {
    client.close(force: true);
  }
}
