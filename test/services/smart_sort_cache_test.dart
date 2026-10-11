import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pure_music/library/audio_library.dart';
import 'package:pure_music/services/smart_sort_cache.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('smart_sort_cache_');
  });

  tearDown(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  test(
    'corrupt cache is treated as empty and replaced by valid data',
    () async {
      final databaseFile = File(_databasePath(directory));
      await databaseFile.writeAsString('not a database');
      final cache = SmartSortFeatureCache.forTesting(directory);
      final audio = _audio(modified: 42);

      expect(await cache.lookup(audio), isNull);
      cache.put(audio, '{"bpm":120}');
      await cache.flush();

      expect(_readFeatures(directory, r'c:/music/track.mp3'), '{"bpm":120}');
      expect(await cache.lookup(audio), '{"bpm":120}');
    },
  );

  test(
    'failed flush remains dirty and succeeds after storage recovers',
    () async {
      final blocked = Directory(_databasePath(directory));
      await blocked.create();
      final cache = SmartSortFeatureCache.forTesting(directory);
      final audio = _audio(modified: 7);
      cache.put(audio, '{"bpm":90}');

      await cache.flush();
      expect(await blocked.exists(), isTrue);

      await blocked.delete();
      await cache.flush();

      final restored = SmartSortFeatureCache.forTesting(directory);
      expect(await restored.lookup(audio), '{"bpm":90}');
    },
  );

  test('version and modification mismatches are cache misses', () async {
    final legacy = File(_legacyPath(directory));
    await legacy.writeAsString(
      jsonEncode({
        'c:/music/track.mp3': {
          'version': 1,
          'mtime': 42,
          'features': '{"bpm":120}',
        },
      }),
    );
    final oldVersion = SmartSortFeatureCache.forTesting(directory);
    expect(await oldVersion.lookup(_audio(modified: 42)), isNull);
    expect(await legacy.exists(), isFalse);

    await legacy.writeAsString(
      jsonEncode({
        'c:/music/track.mp3': {
          'version': 2,
          'mtime': 41,
          'features': '{"bpm":120}',
        },
      }),
    );
    final staleFile = SmartSortFeatureCache.forTesting(directory);
    expect(await staleFile.lookup(_audio(modified: 42)), isNull);
  });

  test(
    'legacy cache is imported and later flushes keep untouched rows',
    () async {
      final legacy = File(_legacyPath(directory));
      await legacy.writeAsString(
        jsonEncode({
          'c:/music/track.mp3': {
            'version': 2,
            'mtime': 42,
            'features': '{"bpm":120}',
          },
        }),
      );
      final cache = SmartSortFeatureCache.forTesting(directory);
      final existing = _audio(modified: 42);
      final added = _audio(modified: 9, path: r'C:\Music\other.mp3');

      expect(await cache.lookup(existing), '{"bpm":120}');
      cache.put(added, '{"bpm":80}');
      await cache.flush();

      expect(await legacy.exists(), isFalse);
      final restored = SmartSortFeatureCache.forTesting(directory);
      expect(await restored.lookup(existing), '{"bpm":120}');
      expect(await restored.lookup(added), '{"bpm":80}');
      expect(_readFeatures(directory, r'c:/music/track.mp3'), '{"bpm":120}');
      expect(_readFeatures(directory, r'c:/music/other.mp3'), '{"bpm":80}');
    },
  );
}

String _databasePath(Directory directory) =>
    '${directory.path}${Platform.pathSeparator}smart_sort_features.sqlite';

String _legacyPath(Directory directory) =>
    '${directory.path}${Platform.pathSeparator}smart_sort_features.json';

String? _readFeatures(Directory directory, String path) {
  final database = sqlite3.open(_databasePath(directory));
  try {
    final rows = database.select(
      'SELECT features FROM features WHERE path = ?',
      [path],
    );
    if (rows.isEmpty) return null;
    return rows.first['features'] as String;
  } finally {
    database.dispose();
  }
}

Audio _audio({required int modified, String path = r'C:\Music\track.mp3'}) =>
    Audio(
      'Track',
      'Artist',
      'Album',
      null,
      1,
      60,
      320,
      44100,
      path,
      modified,
      1,
      'test',
    );
