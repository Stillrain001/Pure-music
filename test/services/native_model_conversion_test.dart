import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:pure_music/native/rust/api/library_db.dart' as rust_library_db;
import 'package:pure_music/native/rust/api/tag_reader.dart' as rust_tag_reader;
import 'package:pure_music/services/native/library_index_service.dart';
import 'package:pure_music/services/native/media_metadata_service.dart';
import 'package:pure_music/services/native/playback_stats_service.dart';

void main() {
  test('library index model converts BigInt counters and phase', () {
    final state = LibraryIndexState.fromNative(
      rust_tag_reader.IndexActionState(
        progress: 0.5,
        message: 'scanning',
        phase: rust_tag_reader.IndexPhase.saving,
        unreadableTotal: BigInt.from(3),
      ),
    );

    expect(state.progress, 0.5);
    expect(state.phase, LibraryIndexPhase.saving);
    expect(state.unreadableTotal, 3);
  });

  test('media metadata model converts file size and items', () {
    final metadata = AudioExtraMetadata.fromNative(
      rust_tag_reader.AudioExtraMetadata(
        extension_: 'flac',
        fileSize: BigInt.from(1234),
        channels: 2,
        bitDepth: 24,
        items: const [
          rust_tag_reader.AudioExtraItem(key: 'genre', value: 'Rock'),
        ],
        replaygainTrackGain: '-3 dB',
        replaygainTrackPeak: null,
        replaygainAlbumGain: null,
        replaygainAlbumPeak: null,
      ),
    );

    expect(metadata.extension, 'flac');
    expect(metadata.fileSize, 1234);
    expect(metadata.channels, 2);
    expect(metadata.items.single.value, 'Rock');
    expect(metadata.replaygainTrackGain, '-3 dB');
  });

  test('playback stats model converts counters and lists', () {
    final stats = PlayHistoryStats.fromNative(
      rust_library_db.PlayHistoryStats(
        total: 7,
        firstAt: 100,
        lastAt: 200,
        earliestAt: 90,
        daily: const [rust_library_db.DayCount(day: '2026-10-24', count: 2)],
        hourly: Int64List.fromList([0, 1, 2]),
        weekdayHourly: Int64List.fromList([3, 4]),
      ),
    );

    expect(stats.total, 7);
    expect(stats.earliestAt, 90);
    expect(stats.daily.single.count, 2);
    expect(stats.hourly, [0, 1, 2]);
    expect(stats.weekdayHourly, [3, 4]);
  });
}
