import 'package:flutter/material.dart';

const nowPlayingOpenCurve = Curves.easeOutCubic;
const nowPlayingCloseCurve = Curves.easeInCubic;

class NowPlayingBarBounds {
  static final barKey = GlobalKey();
  static Rect? captured;

  static Rect? globalRect() {
    final box = barKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  static void capture() {
    captured = globalRect();
  }
}

class NowPlayingOpenTransition extends StatefulWidget {
  const NowPlayingOpenTransition({
    super.key,
    required this.animation,
    required this.motionEnabled,
    required this.child,
  });

  final Animation<double> animation;
  final bool motionEnabled;
  final Widget child;

  @override
  State<NowPlayingOpenTransition> createState() =>
      _NowPlayingOpenTransitionState();
}

class _NowPlayingOpenTransitionState extends State<NowPlayingOpenTransition> {
  Rect? _barRect;
  late final CurvedAnimation _curved = CurvedAnimation(
    parent: widget.animation,
    curve: nowPlayingOpenCurve,
    reverseCurve: nowPlayingCloseCurve,
  );

  @override
  void dispose() {
    _curved.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.motionEnabled) return widget.child;
    return AnimatedBuilder(
      animation: _curved,
      builder: (context, child) {
        if (widget.animation.status == AnimationStatus.completed) {
          return child!;
        }
        _barRect ??=
            NowPlayingBarBounds.captured ?? NowPlayingBarBounds.globalRect();
        final bar = _barRect;
        final box = context.findRenderObject() as RenderBox?;
        if (bar == null || box == null || !box.hasSize || !box.attached) {
          return _NowPlayingFadeSlide(animation: widget.animation, child: child!);
        }
        final full = Offset.zero & box.size;
        final begin = Rect.fromPoints(
          box.globalToLocal(bar.topLeft),
          box.globalToLocal(bar.bottomRight),
        );
        final t = _curved.value;
        final rect = Rect.lerp(begin, full, t)!;
        final radius = 8.0 * (1 - t);
        final veil = const Interval(
          0.0,
          0.42,
          curve: Curves.easeOut,
        ).transform(t);
        final scheme = Theme.of(context).colorScheme;
        final shade = (1 - t).clamp(0.0, 1.0) * veil;
        return Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            Positioned.fromRect(
              rect: rect,
              child: Opacity(
                opacity: veil,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(radius),
                    boxShadow: [
                      for (final shadow in kElevationToShadow[4]!)
                        BoxShadow(
                          color: shadow.color.withValues(
                            alpha: shadow.color.a * shade,
                          ),
                          offset: shadow.offset,
                          blurRadius: shadow.blurRadius,
                          spreadRadius: shadow.spreadRadius,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            ClipPath(
              clipper: _NowPlayingOpenClipper(rect, radius),
              child: Opacity(opacity: veil, child: child),
            ),
          ],
        );
      },
      child: widget.child,
    );
  }
}

class _NowPlayingOpenClipper extends CustomClipper<Path> {
  const _NowPlayingOpenClipper(this.rect, this.radius);

  final Rect rect;
  final double radius;

  @override
  Path getClip(Size size) {
    return Path()..addRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
    );
  }

  @override
  bool shouldReclip(covariant _NowPlayingOpenClipper oldClipper) {
    return oldClipper.rect != rect || oldClipper.radius != radius;
  }
}

class _NowPlayingFadeSlide extends StatefulWidget {
  const _NowPlayingFadeSlide({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  State<_NowPlayingFadeSlide> createState() => _NowPlayingFadeSlideState();
}

class _NowPlayingFadeSlideState extends State<_NowPlayingFadeSlide> {
  late final CurvedAnimation _curved = CurvedAnimation(
    parent: widget.animation,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  @override
  void dispose() {
    _curved.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slide = Tween<Offset>(
      begin: const Offset(0.0, 0.06),
      end: Offset.zero,
    ).animate(_curved);
    return FadeTransition(
      opacity: _curved,
      child: SlideTransition(position: slide, child: widget.child),
    );
  }
}


