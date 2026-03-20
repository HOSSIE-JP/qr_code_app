import 'package:auto_route/auto_route.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/utils/image_utils.dart';

/// サムネイル用の画像トリミングページ。
///
/// [crop_your_image] パッケージを利用してトリミングし、
/// 最大幅 512px にリサイズした PNG を前画面に返す。
/// アスペクト比は 1:1（正方形）または自由を選択できる。
/// 画像処理は [compute] でバックグラウンド Isolate に逃がし、
/// UI スレッドのブロックを防ぐ。
@RoutePage()
class ThumbnailCropPage extends StatefulWidget {
  const ThumbnailCropPage({super.key, required this.imageBytes});

  final Uint8List imageBytes;

  @override
  State<ThumbnailCropPage> createState() => _ThumbnailCropPageState();
}

class _ThumbnailCropPageState extends State<ThumbnailCropPage> {
  final _cropController = CropController();
  bool _cropping = false;

  /// true=1:1 正方形, false=自由アスペクト比
  bool _isSquare = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('サムネイルをトリミング'),
        actions: [
          TextButton.icon(
            onPressed: _cropping ? null : _doCrop,
            icon: _cropping
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: const Text('完了'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            // 画面端までトリムエッジが来ないようマージンを設ける
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Crop(
                key: ValueKey(_isSquare),
                image: widget.imageBytes,
                controller: _cropController,
                aspectRatio: _isSquare ? 1 : null,
                withCircleUi: false,
                onCropped: _onCropped,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _isSquare ? '1:1 正方形（最大幅 512px）' : '自由アスペクト比（最大幅 512px）',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                SegmentedButton<bool>(
                  style: const ButtonStyle(
                    tapTargetSize: MaterialTapTargetSize.padded,
                    visualDensity: VisualDensity.comfortable,
                  ),
                  segments: const [
                    ButtonSegment(value: true, label: Text('1:1')),
                    ButtonSegment(value: false, label: Text('自由')),
                  ],
                  selected: {_isSquare},
                  onSelectionChanged: (selected) {
                    setState(() => _isSquare = selected.first);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _doCrop() {
    setState(() => _cropping = true);
    _cropController.crop();
  }

  /// クロップ結果を受け取り、リサイズ処理を Isolate で実行する。
  Future<void> _onCropped(CropResult result) async {
    switch (result) {
      case CropSuccess(:final croppedImage):
        try {
          // 重い画像処理をバックグラウンド Isolate で実行
          final resized = await compute(
            ImageUtils.resizeToThumbnail,
            croppedImage,
          );
          if (!mounted) return;
          context.router.maybePop(resized);
        } catch (e) {
          if (!mounted) return;
          setState(() => _cropping = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('リサイズに失敗しました: $e')));
        }
      case CropFailure(:final cause):
        setState(() => _cropping = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('トリミングに失敗しました: $cause')));
    }
  }
}
