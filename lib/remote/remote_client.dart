import 'dart:typed_data';

import 'package:pure_music/remote/remote_source.dart';

typedef RemoteSyncProgress = void Function(double progress, String message);

abstract class RemoteClient {
  Future<List<RemoteTrack>> fetchTracks(
    RemoteSource source,
    String password, {
    RemoteSyncProgress? onProgress,
  });

  /// 增量同步提示：上次同步的结果。实现的客户端可以据此跳过未变化的文件，
  /// 避免每次同步都把整个库重新解析一遍。
  void seedExistingTracks(List<RemoteTrack> tracks) {}

  String playbackUrl(RemoteSource source, String password, String trackId);

  Future<Uint8List?> cover(
    RemoteSource source,
    String password,
    String? coverId,
    int size,
  ) async {
    return null;
  }
}
