import 'dart:ffi' hide Size;
import 'dart:io';
import 'dart:ui';

import 'package:ffi/ffi.dart';

typedef WindowVirtualScreen = ({int x, int y, int width, int height});
// 窗口矩形，单位为物理像素（GetWindowRect 的屏幕坐标）
typedef WindowPhysicalRect = ({int x, int y, int width, int height});

const _smXVirtualScreen = 76;
const _smYVirtualScreen = 77;
const _smCxVirtualScreen = 78;
const _smCyVirtualScreen = 79;
const _minVisiblePhysicalPx = 48.0;
const _swpNoZOrder = 0x0004;
const _swpNoActivate = 0x0010;

typedef _GetSystemMetricsNative = Int32 Function(Int32 index);
typedef _GetSystemMetricsDart = int Function(int index);

_GetSystemMetricsDart? _getSystemMetrics;

void _ensureSystemMetrics() {
  if (_getSystemMetrics != null || !Platform.isWindows) return;
  try {
    final user32 = DynamicLibrary.open('user32.dll');
    _getSystemMetrics = user32
        .lookupFunction<_GetSystemMetricsNative, _GetSystemMetricsDart>(
          'GetSystemMetrics',
        );
  } catch (_) {
    _getSystemMetrics = null;
  }
}

final class _NativeRect extends Struct {
  @Int32()
  external int left;

  @Int32()
  external int top;

  @Int32()
  external int right;

  @Int32()
  external int bottom;
}

// Win32 的 BOOL 是 4 字节整数，必须用 Int32 接收而不是 Bool
typedef _GetWindowRectNative =
    Int32 Function(IntPtr hwnd, Pointer<_NativeRect> rect);
typedef _GetWindowRectDart = int Function(int hwnd, Pointer<_NativeRect> rect);

typedef _SetWindowPosNative =
    Int32 Function(
      IntPtr hwnd,
      IntPtr hwndInsertAfter,
      Int32 x,
      Int32 y,
      Int32 cx,
      Int32 cy,
      Uint32 flags,
    );
typedef _SetWindowPosDart =
    int Function(
      int hwnd,
      int hwndInsertAfter,
      int x,
      int y,
      int cx,
      int cy,
      int flags,
    );

_GetWindowRectDart? _getWindowRect;
_SetWindowPosDart? _setWindowPos;

void _ensureWindowFns() {
  if ((_getWindowRect != null && _setWindowPos != null) ||
      !Platform.isWindows) {
    return;
  }
  try {
    final user32 = DynamicLibrary.open('user32.dll');
    _getWindowRect ??= user32
        .lookupFunction<_GetWindowRectNative, _GetWindowRectDart>(
          'GetWindowRect',
        );
    _setWindowPos ??= user32
        .lookupFunction<_SetWindowPosNative, _SetWindowPosDart>('SetWindowPos');
  } catch (_) {
    _getWindowRect = null;
    _setWindowPos = null;
  }
}

WindowVirtualScreen? windowsVirtualScreen() {
  _ensureSystemMetrics();
  final fn = _getSystemMetrics;
  if (fn == null) return null;
  final width = fn(_smCxVirtualScreen);
  final height = fn(_smCyVirtualScreen);
  if (width <= 0 || height <= 0) return null;
  return (
    x: fn(_smXVirtualScreen),
    y: fn(_smYVirtualScreen),
    width: width,
    height: height,
  );
}

bool windowPlacementIsOnscreen({
  required Offset position,
  required Size size,
  required double devicePixelRatio,
  required WindowVirtualScreen screen,
}) {
  if (devicePixelRatio <= 0 || size.width <= 0 || size.height <= 0) {
    return false;
  }
  final left = position.dx * devicePixelRatio;
  final top = position.dy * devicePixelRatio;
  final right = left + size.width * devicePixelRatio;
  final bottom = top + size.height * devicePixelRatio;
  final overlapX = _overlap(
    left,
    right,
    screen.x.toDouble(),
    (screen.x + screen.width).toDouble(),
  );
  final overlapY = _overlap(
    top,
    bottom,
    screen.y.toDouble(),
    (screen.y + screen.height).toDouble(),
  );
  return overlapX >= _minVisiblePhysicalPx && overlapY >= _minVisiblePhysicalPx;
}

double _overlap(double a0, double a1, double b0, double b1) {
  final start = a0 > b0 ? a0 : b0;
  final end = a1 < b1 ? a1 : b1;
  final delta = end - start;
  return delta > 0 ? delta : 0;
}

// 读取窗口当前矩形（物理像素）。多屏混合缩放下逻辑坐标会随各屏 DPI 缩放，
// 只有物理像素是稳定锚点，保存和还原都以它为准
WindowPhysicalRect? windowsWindowPhysicalRect(int hwnd) {
  if (hwnd <= 0) return null;
  _ensureWindowFns();
  final fn = _getWindowRect;
  if (fn == null) return null;
  final rect = calloc<_NativeRect>();
  try {
    if (fn(hwnd, rect) == 0) return null;
    final ref = rect.ref;
    final width = ref.right - ref.left;
    final height = ref.bottom - ref.top;
    if (width <= 0 || height <= 0) return null;
    return (x: ref.left, y: ref.top, width: width, height: height);
  } catch (_) {
    return null;
  } finally {
    calloc.free(rect);
  }
}

// 按物理像素直接摆放窗口。跨屏移动会触发 WM_DPICHANGED，
// 引擎会按建议矩形重设窗口，因此调用方需要间隔一帧再摆一次兜底
bool setWindowsWindowPhysicalRect({
  required int hwnd,
  required WindowPhysicalRect rect,
}) {
  if (hwnd <= 0 || rect.width <= 0 || rect.height <= 0) return false;
  _ensureWindowFns();
  final fn = _setWindowPos;
  if (fn == null) return false;
  try {
    return fn(
          hwnd,
          0,
          rect.x,
          rect.y,
          rect.width,
          rect.height,
          _swpNoZOrder | _swpNoActivate,
        ) !=
        0;
  } catch (_) {
    return false;
  }
}

// 校验物理像素矩形是否在虚拟屏幕上有足够可见面积，
// 坐标直接与虚拟屏比较，不涉及任何 DPI 换算
bool windowPhysicalRectIsOnscreen({
  required WindowPhysicalRect rect,
  required WindowVirtualScreen screen,
}) {
  if (rect.width <= 0 || rect.height <= 0) return false;
  final overlapX = _overlap(
    rect.x.toDouble(),
    (rect.x + rect.width).toDouble(),
    screen.x.toDouble(),
    (screen.x + screen.width).toDouble(),
  );
  final overlapY = _overlap(
    rect.y.toDouble(),
    (rect.y + rect.height).toDouble(),
    screen.y.toDouble(),
    (screen.y + screen.height).toDouble(),
  );
  return overlapX >= _minVisiblePhysicalPx && overlapY >= _minVisiblePhysicalPx;
}
