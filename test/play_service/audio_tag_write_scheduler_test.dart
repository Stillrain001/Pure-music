import 'package:flutter_test/flutter_test.dart';
import 'package:pure_music/play_service/audio_tag_write_scheduler.dart';

void main() {
  test('open file is queued until the player releases it', () async {
    final open = <String>{r'c:\song.mp3'};
    var writes = 0;
    final scheduler = AudioTagWriteScheduler(
      isPathOpen: (path) => open.contains(path.toLowerCase()),
    );

    final timing = await scheduler.submit(
      path: r'C:\song.mp3',
      write: () async => writes++,
    );
    scheduler.onAudioFilesChanged();
    await Future<void>.delayed(Duration.zero);

    expect(timing, AudioTagWriteTiming.afterPlayback);
    expect(writes, 0);

    open.clear();
    scheduler.onAudioFilesChanged();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(writes, 1);
  });

  test('idle file writes immediately', () async {
    var writes = 0;
    final scheduler = AudioTagWriteScheduler(isPathOpen: (_) => false);

    final timing = await scheduler.submit(
      path: r'D:\other.flac',
      write: () async => writes++,
    );

    expect(timing, AudioTagWriteTiming.now);
    expect(writes, 1);
  });

  test('flushAll writes queued files even if they still look open', () async {
    var writes = 0;
    final scheduler = AudioTagWriteScheduler(isPathOpen: (_) => true);
    await scheduler.submit(path: r'C:\song.mp3', write: () async => writes++);

    await scheduler.flushAll();

    expect(writes, 1);
  });
}
