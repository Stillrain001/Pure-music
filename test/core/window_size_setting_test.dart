import 'package:flutter_test/flutter_test.dart';
import 'package:pure_music/core/setting_action_state.dart';

void main() {
  test('minimized window dimensions restore the default size', () {
    expect(normalizedWindowSizeSetting('158.0,26.0'), defaultWindowSizeSetting);
  });

  test('valid window dimensions are preserved', () {
    expect(normalizedWindowSizeSetting('1280.0,756.0'), (
      width: 1280.0,
      height: 756.0,
    ));
  });

  test('encoded window size roundtrips through the decoder', () {
    expect(normalizedWindowSizeSetting(encodedWindowSizeSetting(1440, 900)), (
      width: 1440.0,
      height: 900.0,
    ));
  });

  test('a comma-only payload restores the default size', () {
    expect(normalizedWindowSizeSetting(','), defaultWindowSizeSetting);
  });

  test('window position keeps negatives for a left-side monitor', () {
    expect(normalizedWindowPositionSetting('-1920.0,80.0'), (
      x: -1920.0,
      y: 80.0,
    ));
  });

  test('invalid window position is ignored', () {
    expect(normalizedWindowPositionSetting(','), isNull);
    expect(normalizedWindowPositionSetting(null), isNull);
  });

  test('encoded physical placement roundtrips through the decoder', () {
    expect(
      normalizedWindowPlacementPxSetting(
        encodedWindowPlacementPxSetting(1920, 0, 2200, 2650),
      ),
      (x: 1920, y: 0, width: 2200, height: 2650),
    );
  });

  test('physical placement keeps negatives for a left-side monitor', () {
    expect(normalizedWindowPlacementPxSetting('-1152,-40,1200,900'), (
      x: -1152,
      y: -40,
      width: 1200,
      height: 900,
    ));
  });

  test('invalid physical placement is ignored', () {
    expect(normalizedWindowPlacementPxSetting('1,2,3'), isNull);
    expect(normalizedWindowPlacementPxSetting('1,2,-3,4'), isNull);
    expect(normalizedWindowPlacementPxSetting('1,2,3,abc'), isNull);
    expect(normalizedWindowPlacementPxSetting('1.5,2,3,4'), isNull);
    expect(normalizedWindowPlacementPxSetting(null), isNull);
  });
}
