import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:pure_music/core/settings.dart';
import 'package:pure_music/lyric/lyric.dart';

/// 每首歌的手动歌词偏移。正数与歌词标签 [offset:] 一致：歌词提前。
class LyricManualOffset extends ChangeNotifier {
  LyricManualOffset._();

  static final LyricManualOffset instance = LyricManualOffset._();

  final Map<String, int> _saved = {};
  Future<void>? _loading;
  String? _path;
  var _manualMs = 0;
  var _bindGeneration = 0;
  var _editGeneration = 0;

  int get manualMs => _manualMs;

  String? get path => _path;

  Future<void> ensureLoaded() {
    return _loading ??= _read();
  }

  Future<void> bind(String? path) async {
    final generation = ++_bindGeneration;
    if (_path != path) {
      _path = path;
      _manualMs = 0;
      notifyListeners();
    }
    final editAtStart = _editGeneration;
    await ensureLoaded();
    if (generation != _bindGeneration || _editGeneration != editAtStart) {
      return;
    }
    final next = path == null ? 0 : (_saved[path] ?? 0);
    if (_path != path || _manualMs == next) return;
    _manualMs = next;
    notifyListeners();
  }

  void add(int deltaMs) {
    if (_path == null || deltaMs == 0) return;
    setManual(_manualMs + deltaMs);
  }

  void reset() {
    setManual(0);
  }

  /// 切歌发生在写入过程中时，清掉那首歌已经写进文件的手动偏移。
  void forget(String path) {
    if (!_saved.containsKey(path) && _path != path) return;
    _saved.remove(path);
    unawaited(_persist());
    if (_path != path) return;
    _manualMs = 0;
    _editGeneration++;
    notifyListeners();
  }

  void setManual(int value, {bool notify = true}) {
    final path = _path;
    if (path == null) return;
    _editGeneration++;
    if (_manualMs == value && _saved[path] == value) {
      if (notify) notifyListeners();
      return;
    }
    _manualMs = value;
    if (value == 0) {
      _saved.remove(path);
    } else {
      _saved[path] = value;
    }
    unawaited(_persist());
    if (notify) notifyListeners();
  }

  Future<void> _read() async {
    final editAtStart = _editGeneration;
    try {
      final file = File(await _filePath());
      if (!await file.exists()) return;
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) return;
      final loaded = <String, int>{};
      for (final entry in decoded.entries) {
        final key = entry.key;
        if (key is! String) continue;
        final value = entry.value;
        if (value is int) {
          loaded[key] = value;
        } else if (value is num) {
          loaded[key] = value.round();
        }
      }
      if (editAtStart != _editGeneration) {
        for (final entry in loaded.entries) {
          _saved.putIfAbsent(entry.key, () => entry.value);
        }
      } else {
        _saved.addAll(loaded);
      }
    } catch (_) {
      // 读不到就当没有手动偏移，不影响播放。
    }
  }

  Future<void> _persist() async {
    await ensureLoaded();
    final filePath = await _filePath();
    await writeTextFileAtomically(filePath, jsonEncode(_saved));
  }

  Future<String> _filePath() async {
    final root = await getAppDataDir();
    return p.join(root.path, 'lyric_offset.json');
  }
}

final RegExp _lyricOffsetTag = RegExp(
  r'\[\s*offset\s*:\s*([+-]?\d+)\s*\]',
  caseSensitive: false,
);

/// 在原文上增加偏移。正数与 [offset:] 一致，表示歌词提前。
String lyricTextWithAddedOffset(String raw, int deltaMs) {
  if (deltaMs == 0) return raw;
  final match = _lyricOffsetTag.firstMatch(raw);
  if (match == null) return '[offset:$deltaMs]\n$raw';
  final existing = int.tryParse(match.group(1) ?? '') ?? 0;
  return raw.replaceFirst(match.group(0)!, '[offset:${existing + deltaMs}]');
}

/// 同一行写入后应提前 delta。按行号比，避免误把旁边一行当成已经对齐。
bool lyricOffsetShiftMatches(Lyric before, Lyric after, int deltaMs) {
  if (deltaMs == 0) return true;
  final count = before.lines.length < after.lines.length
      ? before.lines.length
      : after.lines.length;
  if (count == 0) return false;
  if ((before.lines.length - after.lines.length).abs() > 2) return false;
  var checked = 0;
  var hits = 0;
  for (var i = 0; i < count; i++) {
    final oldMs = before.lines[i].start.inMilliseconds;
    if (oldMs < deltaMs.abs() + 200) continue;
    checked++;
    final actual = after.lines[i].start.inMilliseconds;
    if ((oldMs - actual - deltaMs).abs() <= 5) hits++;
  }
  return checked > 0 && hits == checked;
}

/// 歌词时间轴上的毫秒。播放进度本身不变。
int lyricTimelineMs(double playbackSeconds) =>
    (playbackSeconds * 1000).round() + LyricManualOffset.instance.manualMs;

double lyricTimelineMsDouble(double playbackSeconds) =>
    playbackSeconds * 1000.0 + LyricManualOffset.instance.manualMs;
