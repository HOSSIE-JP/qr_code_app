import 'package:flutter/material.dart';

import '../data/models/qr_entry_model.dart';

/// QR エントリをグリッドなどに表示するカードウィジェット。
///
/// サムネイル、名前、説明、タグ、データサイズをコンパクトに表示する。
/// 説明やタグが多くてもオーバーフローしないよう、表示領域を制限する。
/// QR 未登録エントリはサムネイルをグレーアウトして区別する。
class QrEntryCard extends StatelessWidget {
  const QrEntryCard({
    super.key,
    required this.entry,
    this.onTap,
    this.onLongPress,
    this.onFavoriteToggle,
    this.isSelected = false,
  });

  final QrEntryModel entry;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onFavoriteToggle;

  /// マルチ選択モードで選択中かどうか。
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      color: isSelected ? colorScheme.primaryContainer : null,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // サムネイル + お気に入りアイコン + 選択チェック
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // QR 未登録のエントリはグレーアウト
                  _buildThumbnail(colorScheme),
                  // お気に入りボタン
                  if ((entry.isFavorite || onFavoriteToggle != null) &&
                      !isSelected)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: onFavoriteToggle,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black38,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            entry.isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: entry.isFavorite ? Colors.red : Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  // 選択モードのチェックマーク
                  if (isSelected)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check,
                          color: colorScheme.onPrimary,
                          size: 16,
                        ),
                      ),
                    ),
                  // QR 未登録バッジ
                  if (!entry.hasQrData)
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'QR未登録',
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // 情報テキスト領域。Expanded で高さを制限しオーバーフローを防ぐ。
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.name,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (entry.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Flexible(
                        child: Text(
                          entry.description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      entry.hasQrData ? _formatSize(entry.dataSize) : 'QR未登録',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// サムネイル表示。QR 未登録エントリは ColorFiltered でグレーアウト。
  Widget _buildThumbnail(ColorScheme colorScheme) {
    Widget thumbnail;
    if (entry.thumbnail != null) {
      thumbnail = Image.memory(entry.thumbnail!, fit: BoxFit.cover);
    } else {
      thumbnail = Container(
        color: colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.qr_code_2,
          size: 48,
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }
    // QR 未登録の場合はグレースケール化して視覚的に区別
    if (!entry.hasQrData) {
      return ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]),
        child: Opacity(opacity: 0.5, child: thumbnail),
      );
    }
    return thumbnail;
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
