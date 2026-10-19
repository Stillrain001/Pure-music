import 'dart:async';

enum AudioTagWriteTiming { now, afterPlayback }

typedef AudioTagWrite = Future<void> Function();

/// 播放器还开着目标文件时，把标签写入先排起来。
/// 写 MP3 会先把文件截空再整份写回，歌还开着就会卡、进度也会错。
class AudioTagWriteScheduler {
  AudioTagWriteScheduler({required bool Function(String path) isPathOpen})
    : _isPathOpen = isPathOpen;

  bool Function(String path) _isPathOpen;

  final Map<String, List<_QueuedAudioTagWrite>> _pending = {};
  Future<void> _tail = Future<void>.value();

  void bindPathCheck(bool Function(String path) isPathOpen) {
    _isPathOpen = isPathOpen;
  }

  void onAudioFilesChanged() {
    _schedule(onlyIdle: true);
  }

  Future<void> flushAll() {
    _schedule(onlyIdle: false);
    return _tail;
  }

  Future<AudioTagWriteTiming> submit({
    required String path,
    required AudioTagWrite write,
    void Function()? onWritten,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) async {
    if (!_isPathOpen(path)) {
      await write();
      onWritten?.call();
      return AudioTagWriteTiming.now;
    }
    final key = path.toLowerCase();
    _pending
        .putIfAbsent(key, () => [])
        .add(
          _QueuedAudioTagWrite(
            path: path,
            write: write,
            onWritten: onWritten,
            onError: onError,
          ),
        );
    return AudioTagWriteTiming.afterPlayback;
  }

  void _schedule({required bool onlyIdle}) {
    _tail = _tail.then((_) => _drain(onlyIdle: onlyIdle));
  }

  Future<void> _drain({required bool onlyIdle}) async {
    while (true) {
      final ready = <_QueuedAudioTagWrite>[];
      final done = <String>[];
      for (final entry in _pending.entries) {
        final jobs = entry.value;
        if (jobs.isEmpty) {
          done.add(entry.key);
          continue;
        }
        if (onlyIdle && _isPathOpen(jobs.first.path)) continue;
        ready.addAll(jobs);
        done.add(entry.key);
      }
      for (final key in done) {
        _pending.remove(key);
      }
      if (ready.isEmpty) return;
      for (final job in ready) {
        try {
          await job.write();
          job.onWritten?.call();
        } catch (error, stackTrace) {
          job.onError?.call(error, stackTrace);
        }
      }
    }
  }
}

class _QueuedAudioTagWrite {
  const _QueuedAudioTagWrite({
    required this.path,
    required this.write,
    required this.onWritten,
    required this.onError,
  });

  final String path;
  final AudioTagWrite write;
  final void Function()? onWritten;
  final void Function(Object error, StackTrace stackTrace)? onError;
}

final audioTagWriteScheduler = AudioTagWriteScheduler(isPathOpen: (_) => false);
