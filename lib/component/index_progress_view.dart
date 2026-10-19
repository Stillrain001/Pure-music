import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:pure_music/core/design_tokens.dart';
import 'package:pure_music/native/rust/api/tag_reader/index_state.dart';

/// 曲库扫描进度视图：阶段文案 + 进度条 + 完成后的不可读文件计数。
/// 供启动扫描页、首次建库视图和手动刷新对话框共用；重试由调用者提供回调。
class IndexProgressView extends StatelessWidget {
  const IndexProgressView({
    super.key,
    this.state,
    this.errorMessage,
    this.onRetry,
  });

  /// 最新一次进度状态；流尚未吐出首条或出错后为 null。
  final IndexActionState? state;

  /// 失败信息；非空时展示失败态。
  final String? errorMessage;

  /// 失败态的重试回调；为 null 则不显示重试按钮。
  final VoidCallback? onRetry;

  String get _phaseLabel {
    final value = state;
    if (value == null) return '正在准备…';
    switch (value.phase) {
      case IndexPhase.preparing:
        return '正在准备…';
      case IndexPhase.scanning:
        return value.message.isEmpty ? '正在扫描…' : value.message;
      case IndexPhase.saving:
        return '正在保存索引…';
      case IndexPhase.complete:
        return value.message.isEmpty ? '扫描完成' : value.message;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final errorMessage = this.errorMessage;
    if (errorMessage != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Symbols.error, color: scheme.error, size: 20.0),
              const SizedBox(width: 8.0),
              Flexible(
                child: Text(
                  errorMessage,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: scheme.error),
                ),
              ),
            ],
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12.0),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Symbols.refresh, size: 16),
              label: const Text('重试'),
            ),
          ],
        ],
      );
    }
    final value = state;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        LinearProgressIndicator(
          value: value?.progress,
          borderRadius: AppRadius.xsCircular,
          minHeight: 8,
        ),
        const SizedBox(height: 16.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                _phaseLabel,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: scheme.onSurface, fontSize: 14),
              ),
            ),
            if (value != null && value.phase != IndexPhase.complete) ...[
              const SizedBox(width: 8.0),
              Text(
                '${(value.progress.clamp(0.0, 1.0) * 100).round()}%',
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 12,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ],
        ),
        if (value != null &&
            value.phase == IndexPhase.complete &&
            value.unreadableTotal > BigInt.zero) ...[
          const SizedBox(height: 8.0),
          Text(
            '${value.unreadableTotal} 个文件无法读取，已跳过；可稍后重新扫描',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
          ),
        ],
      ],
    );
  }
}
