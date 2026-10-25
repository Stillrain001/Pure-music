import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:pure_music/core/settings.dart';
import 'package:pure_music/native/rust/api/library_db.dart' as rust_library_db;

int _int64ToInt(Object value) {
  if (value is int) return value;
  if (value is BigInt) return value.toInt();
  return int.parse(value.toString());
}

List<int> _copyInt64List(Iterable<Object?> values) =>
    List<int>.unmodifiable(values.map((value) => _int64ToInt(value!)));

class PlayCountRecord {
  const PlayCountRecord({
    required this.path,
    required this.title,
    required this.artist,
    required this.album,
    required this.playCount,
  });

  factory PlayCountRecord.fromNative(rust_library_db.PlayCountEntry value) =>
      PlayCountRecord(
        path: value.path,
        title: value.title,
        artist: value.artist,
        album: value.album,
        playCount: _int64ToInt(value.playCount),
      );

  final String path;
  final String title;
  final String artist;
  final String album;
  final int playCount;
}

class PlayHistoryRecord {
  const PlayHistoryRecord({required this.path, required this.playedAt});

  factory PlayHistoryRecord.fromNative(
    rust_library_db.PlayHistoryEntry value,
  ) => PlayHistoryRecord(
    path: value.path,
    playedAt: _copyInt64List(value.playedAt),
  );

  final String path;
  final List<int> playedAt;
}

class PlayHistoryDayCount {
  const PlayHistoryDayCount({required this.day, required this.count});

  factory PlayHistoryDayCount.fromNative(rust_library_db.DayCount value) =>
      PlayHistoryDayCount(day: value.day, count: _int64ToInt(value.count));

  final String day;
  final int count;
}

class PlayHistoryStats {
  const PlayHistoryStats({
    required this.total,
    required this.firstAt,
    required this.lastAt,
    required this.earliestAt,
    required this.daily,
    required this.hourly,
    required this.weekdayHourly,
  });

  factory PlayHistoryStats.fromNative(rust_library_db.PlayHistoryStats value) =>
      PlayHistoryStats(
        total: _int64ToInt(value.total),
        firstAt: _int64ToInt(value.firstAt),
        lastAt: _int64ToInt(value.lastAt),
        earliestAt: _int64ToInt(value.earliestAt),
        daily: List<PlayHistoryDayCount>.unmodifiable(
          value.daily.map(PlayHistoryDayCount.fromNative),
        ),
        hourly: _copyInt64List(value.hourly),
        weekdayHourly: _copyInt64List(value.weekdayHourly),
      );

  final int total;
  final int firstAt;
  final int lastAt;
  final int earliestAt;
  final List<PlayHistoryDayCount> daily;
  final List<int> hourly;
  final List<int> weekdayHourly;
}

class PlaybackStatsService {
  PlaybackStatsService._();

  static final PlaybackStatsService instance = PlaybackStatsService._();

  Future<List<PlayCountRecord>> getTopPlayed({int limit = -1}) async {
    final indexPath = (await getAppDataDir()).path;
    final values = await rust_library_db.getTopPlayed(
      indexPath: indexPath,
      limit: limit,
    );
    return List<PlayCountRecord>.unmodifiable(
      values.map(PlayCountRecord.fromNative),
    );
  }

  Future<List<PlayHistoryRecord>> exportPlayHistory({String? indexPath}) async {
    final values = await rust_library_db.exportPlayHistory(
      indexPath: indexPath ?? await _indexPath(),
    );
    return List<PlayHistoryRecord>.unmodifiable(
      values.map(PlayHistoryRecord.fromNative),
    );
  }

  Future<List<PlayCountRecord>> exportPlayCounts({String? indexPath}) async {
    final values = await rust_library_db.exportPlayCounts(
      indexPath: indexPath ?? await _indexPath(),
    );
    return List<PlayCountRecord>.unmodifiable(
      values.map(PlayCountRecord.fromNative),
    );
  }

  Future<void> importPlayCounts({
    required List<PlayCountRecord> entries,
    required bool overwrite,
    String? indexPath,
  }) async {
    await rust_library_db.importPlayCounts(
      indexPath: indexPath ?? await _indexPath(),
      entries: entries
          .map(
            (entry) => rust_library_db.PlayCountEntry(
              path: entry.path,
              title: entry.title,
              artist: entry.artist,
              album: entry.album,
              playCount: entry.playCount,
            ),
          )
          .toList(growable: false),
      overwrite: overwrite,
    );
  }

  Future<void> importPlayHistory({
    required List<PlayHistoryRecord> entries,
    required bool overwrite,
    String? indexPath,
  }) async {
    await rust_library_db.importPlayHistory(
      indexPath: indexPath ?? await _indexPath(),
      entries: entries
          .map(
            (entry) => rust_library_db.PlayHistoryEntry(
              path: entry.path,
              playedAt: Int64List.fromList(entry.playedAt),
            ),
          )
          .toList(growable: false),
      overwrite: overwrite,
    );
  }

  Future<PlayHistoryStats> getPlayHistoryStats({int? since, int? until}) async {
    final indexPath = await _indexPath();
    final value = await rust_library_db.getPlayHistoryStats(
      indexPath: indexPath,
      since: since,
      until: until,
    );
    return PlayHistoryStats.fromNative(value);
  }

  Future<String> _indexPath() async => (await getAppDataDir()).path;
}
