import 'package:pure_music/native/rust/api/installed_font.dart'
    as rust_installed_font;
import 'package:pure_music/native/rust/api/system_theme.dart'
    as rust_system_theme;
import 'package:pure_music/native/rust/api/utils.dart' as rust_utils;

class InstalledFontRecord {
  const InstalledFontRecord({required this.path, required this.fullName});

  factory InstalledFontRecord.fromNative(
    rust_installed_font.InstalledFont value,
  ) => InstalledFontRecord(path: value.path, fullName: value.fullName);

  final String path;
  final String fullName;
}

class SystemThemeColors {
  const SystemThemeColors({required this.fore, required this.accent});

  final (int, int, int, int) fore;
  final (int, int, int, int) accent;
}

class PlatformService {
  PlatformService._();

  static final PlatformService instance = PlatformService._();

  Future<bool> launchInBrowser(String uri) =>
      rust_utils.launchInBrowser(uri: uri);

  Future<bool> showInExplorer(String path) =>
      rust_utils.showInExplorer(path: path);

  SystemThemeColors getSystemTheme() {
    final value = rust_system_theme.SystemTheme.getSystemTheme();
    return SystemThemeColors(fore: value.fore, accent: value.accent);
  }

  Future<List<InstalledFontRecord>> getInstalledFonts() async {
    final values = await rust_installed_font.getInstalledFonts();
    if (values == null) return const <InstalledFontRecord>[];
    return List<InstalledFontRecord>.unmodifiable(
      values.map(InstalledFontRecord.fromNative),
    );
  }
}
