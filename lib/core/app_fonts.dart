import 'dart:io';
import 'dart:ui';

import 'package:flutter/services.dart';

const kHangulFallbackFontFamily = 'Pretendard Variable';

/// 未选字体时歌词必须点名 Roboto。
/// 传 null 时 Windows 会用 Segoe UI，它的字符表占着韩文空位，Pretendard 回退不会生效。
const kDefaultLyricFontFamily = 'Roboto';

final _loadedFontFamilies = <String>{};

List<String> appFontFamilyFallback([String? primary]) {
  if (primary == kHangulFallbackFontFamily) return const [];
  return const [kHangulFallbackFontFamily];
}

String lyricRenderFontFamily(String? selected) {
  if (selected == null || selected.isEmpty) return kDefaultLyricFontFamily;
  return selected;
}

/// 自选字体不再附加可变字重。wght 轴会让缺字的韩文跳过 Pretendard 回退。
List<FontVariation>? lyricWeightVariations(String? family, num weight) {
  final resolved = lyricRenderFontFamily(family);
  if (resolved != kDefaultLyricFontFamily &&
      resolved != kHangulFallbackFontFamily) {
    return null;
  }
  return [FontVariation('wght', weight.toDouble())];
}

String? resolvedLyricFontFamily({
  required bool followsUi,
  String? lyricFontFamily,
  String? uiFontFamily,
}) => followsUi ? uiFontFamily : lyricFontFamily;

bool isAppFontLoaded(String family) => _loadedFontFamilies.contains(family);

Future<void> loadAppFontFile({
  required String family,
  required String path,
}) async {
  if (!_loadedFontFamilies.add(family)) return;
  try {
    final fontLoader = FontLoader(family);
    fontLoader.addFont(
      File(path).readAsBytes().then((value) {
        return ByteData.sublistView(value);
      }),
    );
    await fontLoader.load();
  } catch (_) {
    _loadedFontFamilies.remove(family);
    rethrow;
  }
}
