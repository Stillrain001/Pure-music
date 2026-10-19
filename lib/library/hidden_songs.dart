import 'package:pure_music/core/settings.dart';
import 'package:pure_music/library/audio_library.dart';
import 'package:pure_music/native/rust/api/library_db.dart' as library_db;
import 'package:pure_music/play_service/play_service.dart';

/// 隐藏/恢复一批曲目并同步曲库与播放队列。
/// 隐藏时按已拍板的行为立即从播放队列移除（含正在播放的，跳到顺序下一首）。
Future<void> setSongsHidden(
  Iterable<Audio> audios, {
  required bool hidden,
}) async {
  final paths = audios.map((audio) => audio.path).toList();
  if (paths.isEmpty) return;
  final supportPath = (await getAppDataDir()).path;
  await library_db.setAudiosHidden(
    indexPath: supportPath,
    paths: paths,
    hidden: hidden,
  );
  if (hidden) {
    PlayService.instance.playbackService.removeHiddenFromQueue(paths);
  }
  await AudioLibrary.initFromIndex();
}

/// 读取被隐藏的曲目。每次进管理页现查 SQLite，不维护第二份内存集合。
Future<List<Audio>> loadHiddenSongs() async {
  final supportPath = (await getAppDataDir()).path;
  final items = await library_db.readHiddenAudios(indexPath: supportPath);
  return AudioLibrary.audioFromIndexList(items);
}
