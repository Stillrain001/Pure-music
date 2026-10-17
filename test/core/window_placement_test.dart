import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pure_music/core/window_placement.dart';

void main() {
  const screen = (x: 0, y: 0, width: 1920, height: 1080);

  test('saved placement on the current virtual screen is kept', () {
    expect(
      windowPlacementIsOnscreen(
        position: const Offset(100, 80),
        size: const Size(1280, 756),
        devicePixelRatio: 1,
        screen: screen,
      ),
      isTrue,
    );
  });

  test('placement on a disconnected monitor is rejected', () {
    expect(
      windowPlacementIsOnscreen(
        position: const Offset(4000, 80),
        size: const Size(1280, 756),
        devicePixelRatio: 1,
        screen: screen,
      ),
      isFalse,
    );
  });

  test('physical rect fully on the screen is kept', () {
    expect(
      windowPhysicalRectIsOnscreen(
        rect: const (x: 2200, y: 100, width: 1200, height: 900),
        screen: (x: 1920, y: 0, width: 1440, height: 2560),
      ),
      isTrue,
    );
  });

  test('physical rect is validated without any DPI scaling', () {
    const virtual = (x: 0, y: 0, width: 3360, height: 2560);
    // 主屏 200%、副屏 125%：副屏关闭时记录的真实物理矩形
    const savedRect = (x: 1920, y: 0, width: 2200, height: 2650);
    expect(
      windowPhysicalRectIsOnscreen(rect: savedRect, screen: virtual),
      isTrue,
    );
    // 旧的逻辑坐标还原路径会把逻辑值按主屏 DPI 放大一倍，
    // 同一位置被放大后几乎完全出屏，这正是本次要修的 bug
    expect(
      windowPhysicalRectIsOnscreen(
        rect: const (x: 3840, y: 0, width: 3520, height: 4240),
        screen: virtual,
      ),
      isFalse,
    );
  });

  test('physical rect barely visible keeps the placement', () {
    expect(
      windowPhysicalRectIsOnscreen(
        rect: const (x: -1152, y: 0, width: 1200, height: 900),
        screen: (x: 0, y: 0, width: 1920, height: 1080),
      ),
      isTrue,
    );
  });

  test('physical rect below the visibility threshold is rejected', () {
    expect(
      windowPhysicalRectIsOnscreen(
        rect: const (x: -1153, y: 0, width: 1200, height: 900),
        screen: (x: 0, y: 0, width: 1920, height: 1080),
      ),
      isFalse,
    );
  });

  test('empty physical rect is rejected', () {
    expect(
      windowPhysicalRectIsOnscreen(
        rect: const (x: 100, y: 100, width: 0, height: 900),
        screen: screen,
      ),
      isFalse,
    );
  });
}
