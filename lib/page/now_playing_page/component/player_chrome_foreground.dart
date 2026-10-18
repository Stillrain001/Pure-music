import 'package:flutter/material.dart';
import 'package:pure_music/core/color_extraction.dart';
import 'package:pure_music/core/theme.dart';
import 'package:pure_music/page/now_playing_page/component/mesh_gradient_background.dart';
import 'package:pure_music/play_service/play_service.dart';

/// 播放页下半区控件（时间、进度、图标）的前景色。
/// 用主题色时按当前歌曲真实取色保证可读；不用主题色时沿用黑白。
Color playerChromeForeground(BuildContext context, {required bool enabled}) {
  final scheme = Theme.of(context).colorScheme;
  final base = playerThemeForeground(scheme, enabled: enabled);
  if (!enabled) return base;
  final audio = PlayService.existingPlaybackService?.nowPlaying;
  if (audio == null) return base;
  final palette = ColorExtractionService().getCachedPaletteForPath(
    audio.path,
    modified: audio.modified,
  );
  if (palette == null || palette.isEmpty) return base;
  final key = (
    audio.path,
    audio.modified,
    scheme.brightness,
    base,
    Object.hashAll(palette),
  );
  final memoized = _playerChromeForegroundMemo[key];
  if (memoized != null) return memoized;
  final result = resolvePlayerSafeForeground(
    foreground: base,
    palette: palette,
    brightness: scheme.brightness,
  );
  if (_playerChromeForegroundMemo.length >= 8) {
    _playerChromeForegroundMemo.clear();
  }
  _playerChromeForegroundMemo[key] = result;
  return result;
}

final Map<Object, Color> _playerChromeForegroundMemo = {};
