import 'package:flutter/material.dart';

abstract final class Spacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double bottomNav = 96;
}

abstract final class AppRadius {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;

  static final BorderRadius xsCircular = BorderRadius.circular(xs);
  static final BorderRadius smCircular = BorderRadius.circular(sm);
  static final BorderRadius mdCircular = BorderRadius.circular(md);
}

abstract final class AppType {
  static const double microlabel = 10;
  static const double caption = 12;
  static const double body = 14;
  static const double subtitle = 16;
  static const double sectionTitle = 18;
  static const double pageTitle = 20;
  static const double hero = 24;
  static const double display = 32;

  static const FontWeight weightRegular = FontWeight.w400;
  static const FontWeight weightMedium = FontWeight.w500;
  static const FontWeight weightSemibold = FontWeight.w600;
  static const FontWeight weightBold = FontWeight.w700;
}

abstract final class Alpha {
  static const double hover = 0.04;
  static const double focus = 0.04;
}

/// 页面标题行与工具行的按钮统一尺寸。
/// 文字按钮用 [pageAction]，方形图标按钮用 [iconSquare]；不要再各处手写尺寸。
abstract final class AppButton {
  /// 统一高度。
  static const double height = 40;

  /// 统一的横向内边距。
  static const double horizontalPadding = 16;

  /// 页面动作区的文字/图标+文字按钮（主按钮、次级按钮共用高度）。
  static const ButtonStyle pageAction = ButtonStyle(
    fixedSize: WidgetStatePropertyAll(Size.fromHeight(height)),
    padding: WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: horizontalPadding),
    ),
  );

  /// 40×40 方形图标按钮（多选栏小动作等），配 8 圆角。
  static final ButtonStyle iconSquare = ButtonStyle(
    fixedSize: const WidgetStatePropertyAll(Size.square(height)),
    padding: const WidgetStatePropertyAll(EdgeInsets.zero),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: AppRadius.smCircular),
    ),
  );
}
