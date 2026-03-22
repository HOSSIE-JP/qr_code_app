import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/qr_entry_model.dart';
import '../../providers/providers.dart';
import '../../router/app_router.dart';
import '../../widgets/tag_chips.dart';

/// QR エントリの詳細表示ページ。
///
/// メタ情報の詳細をアコーディオンで開閉でき、
/// サムネイル拡大表示、URL 起動、QR プレビュー表示に対応する。
/// また、左右スワイプで前後エントリへ循環移動できる。
@RoutePage()
class DetailPage extends ConsumerStatefulWidget {
  const DetailPage({
    super.key,
    required this.entryId,
    this.scopedEntryIds,
    this.initialIndex,
  });

  final String entryId;

  /// スワイプ対象を明示したいときの ID 一覧（検索結果など）。
  /// スワイプ対象IDを改行区切りでエンコードした文字列。
  final String? scopedEntryIds;

  /// [entryIds] を使う場合の初期インデックス。
  final int? initialIndex;

  @override
  ConsumerState<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends ConsumerState<DetailPage> {
  late String _currentEntryId;

  @override
  void initState() {
    super.initState();
    _currentEntryId = widget.entryId;
    final parsedIds = _parsedScopedIds;
    if (parsedIds.isNotEmpty && widget.initialIndex != null) {
      final index = widget.initialIndex!;
      if (index >= 0 && index < parsedIds.length) {
        _currentEntryId = parsedIds[index];
      }
    }
  }

  List<String> get _parsedScopedIds {
    final raw = widget.scopedEntryIds;
    if (raw == null || raw.isEmpty) return const <String>[];
    return raw.split('\n').where((id) => id.isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    final idsFromCurrentDb = ref
        .watch(qrEntriesProvider)
        .maybeWhen(
          data: (entries) => entries.map((entry) => entry.id).toList(),
          orElse: () => <String>[],
        );

    final parsedIds = _parsedScopedIds;
    final scopedIds = parsedIds.isNotEmpty ? parsedIds : idsFromCurrentDb;

    final entryAsync = ref.watch(qrEntryByIdProvider(_currentEntryId));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return entryAsync.when(
      data: (entry) {
        if (entry == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('詳細')),
            body: const Center(child: Text('エントリが見つかりません')),
          );
        }
        return _buildContent(
          context,
          ref,
          entry,
          scopedIds,
          theme,
          colorScheme,
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('詳細')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('詳細')),
        body: Center(child: Text('エラー: $error')),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    QrEntryModel entry,
    List<String> scopedIds,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final dataText = _decodeData(entry.originalData);
    final effectiveDescription = entry.description.isNotEmpty
        ? entry.description
        : (entry.isTextMode ? dataText : '');
    final url = _extractUrl(dataText);
    final qrConfig = ref.watch(qrGenerationSettingsProvider);

    return FocusScope(
      canRequestFocus: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(entry.name),
          actions: [
            IconButton(
              icon: Icon(
                entry.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: entry.isFavorite ? Colors.red : null,
              ),
              tooltip: entry.isFavorite ? 'お気に入り解除' : 'お気に入り',
              onPressed: () async {
                await ref.read(qrRepositoryProvider).toggleFavorite(entry.id);
                ref.invalidate(qrEntryByIdProvider(_currentEntryId));
              },
            ),
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value != 'delete') return;
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('削除確認'),
                    content: Text('「${entry.name}」を削除しますか？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('キャンセル'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.error,
                        ),
                        child: const Text('削除'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await ref.read(qrRepositoryProvider).deleteEntry(entry.id);
                  if (!context.mounted) return;
                  context.router.popUntilRoot();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: colorScheme.error),
                    title: Text(
                      '削除',
                      style: TextStyle(color: colorScheme.error),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'QR画像を共有',
              onPressed: entry.hasQrData
                  ? () => _shareQrImage(
                      context: context,
                      entry: entry,
                      dataText: dataText,
                      qrConfig: qrConfig,
                    )
                  : null,
            ),
          ],
        ),
        body: SizedBox.expand(
          child: Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                onHorizontalDragEnd: (details) {
                  final velocity = details.primaryVelocity ?? 0;
                  if (velocity.abs() < 300 || scopedIds.length <= 1) return;
                  if (velocity < 0) {
                    _moveToRelativeEntry(1, scopedIds);
                  } else {
                    _moveToRelativeEntry(-1, scopedIds);
                  }
                },
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (entry.thumbnail != null)
                        Center(
                          child: GestureDetector(
                            onTap: () => _showThumbnailPreview(context, entry),
                            key: const Key('detail-thumbnail'),
                            child: Hero(
                              tag: 'thumb_${entry.id}',
                              child: Container(
                                constraints: const BoxConstraints(
                                  maxHeight: 280,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: _buildDetailThumbnail(entry),
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (entry.hasQrData) ...[
                        const SizedBox(height: 12),
                        Center(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: QrImageView(
                                data: dataText,
                                size: 140,
                                version: QrVersions.auto,
                                errorCorrectionLevel: _toQrErrorCorrectLevel(
                                  qrConfig.errorLevel,
                                ),
                                gapless: qrConfig.gapless,
                                padding: EdgeInsets.all(qrConfig.padding),
                                backgroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _infoRow(theme, '名称', entry.name),
                              if (effectiveDescription.isNotEmpty) ...[
                                const Divider(),
                                _infoRow(theme, '説明', effectiveDescription),
                              ],
                              const SizedBox(height: 8),
                              ExpansionTile(
                                tilePadding: EdgeInsets.zero,
                                childrenPadding: EdgeInsets.zero,
                                title: Text(
                                  '詳細情報',
                                  style: theme.textTheme.titleSmall,
                                ),
                                children: [
                                  _infoRow(
                                    theme,
                                    'データサイズ',
                                    entry.hasQrData
                                        ? _formatSize(entry.dataSize)
                                        : 'QR 未登録',
                                  ),
                                  if (entry.hasQrData)
                                    _infoRow(
                                      theme,
                                      'データ形式',
                                      entry.isTextMode ? 'テキスト' : 'バイナリ',
                                    ),
                                  _infoRow(
                                    theme,
                                    'QRコード枚数',
                                    '${entry.chunkCount}枚',
                                  ),
                                  _infoRow(
                                    theme,
                                    '作成日時',
                                    _formatDate(entry.createdAt),
                                  ),
                                  _infoRow(
                                    theme,
                                    '更新日時',
                                    _formatDate(entry.updatedAt),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (entry.tags.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text('タグ', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        TagChips(tags: entry.tags),
                      ],
                      if (entry.hasQrData && !entry.isTextMode) ...[
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () =>
                              _copyBinaryData(context, entry.originalData),
                          icon: const Icon(Icons.content_copy),
                          label: const Text('バイナリデータをコピー'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (scopedIds.length > 1)
                _buildFloatingPageSwitchButtons(scopedIds, colorScheme),
            ],
          ),
        ),
        bottomNavigationBar: _buildStickyActions(context, entry, url),
      ),
    );
  }

  /// 画面左右に前後移動ボタンを重ねて表示する。
  Widget _buildFloatingPageSwitchButtons(
    List<String> scopedIds,
    ColorScheme colorScheme,
  ) {
    return Positioned.fill(
      child: Align(
        alignment: Alignment.center,
        child: SizedBox(
          width: double.infinity,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _buildFloatingNavButton(
                  tooltip: '前のQRへ',
                  icon: Icons.chevron_left,
                  colorScheme: colorScheme,
                  onPressed: () => _moveToRelativeEntry(-1, scopedIds),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildFloatingNavButton(
                  tooltip: '次のQRへ',
                  icon: Icons.chevron_right,
                  colorScheme: colorScheme,
                  onPressed: () => _moveToRelativeEntry(1, scopedIds),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 詳細画面下部に常時表示するアクションバーを構築する。
  Widget _buildStickyActions(
    BuildContext context,
    QrEntryModel entry,
    Uri? url,
  ) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: const [
            BoxShadow(
              blurRadius: 10,
              offset: Offset(0, -2),
              color: Colors.black12,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: SizedBox(
                height: 96,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: url != null ? () => _openUrl(context, url) : null,
                  child: _buildStickyButtonLabel(Icons.open_in_new, 'URLを開く'),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 96,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: entry.hasQrData
                      ? () => context.router.push(
                          QrViewerRoute(entryId: _currentEntryId),
                        )
                      : null,
                  child: _buildStickyButtonLabel(Icons.qr_code_2, 'QRコードを表示'),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 96,
                child: FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () =>
                      context.router.push(EditRoute(entryId: _currentEntryId)),
                  child: _buildStickyButtonLabel(Icons.edit, '情報を編集'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 下部固定アクションのアイコン+ラベル2段表示を構築する。
  Widget _buildStickyButtonLabel(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon),
        Container(
          margin: const EdgeInsets.only(top: 8),
          child: Text(label, textAlign: TextAlign.center),
        ),
      ],
    );
  }

  /// 詳細切替用の丸型フローティングボタンを構築する。
  Widget _buildFloatingNavButton({
    required String tooltip,
    required IconData icon,
    required ColorScheme colorScheme,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 44,
      height: 44,
      child: IconButton.filledTonal(
        style: IconButton.styleFrom(
          backgroundColor: colorScheme.surface.withValues(alpha: 0.9),
        ),
        onPressed: onPressed,
        tooltip: tooltip,
        icon: Icon(icon),
      ),
    );
  }

  /// 設定値から qr パッケージのエラー訂正レベル定数へ変換する。
  int _toQrErrorCorrectLevel(QrGenerationErrorLevel level) {
    switch (level) {
      case QrGenerationErrorLevel.low:
        return QrErrorCorrectLevel.L;
      case QrGenerationErrorLevel.medium:
        return QrErrorCorrectLevel.M;
      case QrGenerationErrorLevel.quartile:
        return QrErrorCorrectLevel.Q;
      case QrGenerationErrorLevel.high:
        return QrErrorCorrectLevel.H;
    }
  }

  /// スワイプ方向に応じて前後エントリへ循環移動する。
  void _moveToRelativeEntry(int delta, List<String> ids) {
    if (ids.isEmpty) return;
    final currentIndex = ids.indexOf(_currentEntryId);
    final base = currentIndex >= 0 ? currentIndex : 0;
    final nextIndex = (base + delta) % ids.length;
    final normalized = nextIndex < 0 ? nextIndex + ids.length : nextIndex;
    setState(() => _currentEntryId = ids[normalized]);
  }

  /// サムネイル拡大プレビューをヒーローアニメーションで表示する。
  void _showThumbnailPreview(BuildContext context, QrEntryModel entry) {
    Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black87,
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (context, animation, secondaryAnimation) =>
            _ThumbnailPreviewPage(entry: entry),
        transitionsBuilder: (context, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  /// バイト列を文字列にデコードする。UTF-8 失敗時は Latin-1 を使う。
  String _decodeData(List<int> bytes) {
    try {
      return utf8.decode(bytes);
    } catch (_) {
      return String.fromCharCodes(bytes);
    }
  }

  /// URL 形式文字列なら Uri を返し、そうでなければ null。
  Uri? _extractUrl(String data) {
    final uri = Uri.tryParse(data.trim());
    if (uri == null) return null;
    if (!(uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https'))) {
      return null;
    }
    if (uri.host.isEmpty) return null;
    return uri;
  }

  /// 外部ブラウザで URL を開く。
  Future<void> _openUrl(BuildContext context, Uri uri) async {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ブラウザ起動に失敗しました')));
    }
  }

  /// バイナリデータを Base64 文字列にしてクリップボードへコピーする。
  Future<void> _copyBinaryData(BuildContext context, List<int> bytes) async {
    final base64 = base64Encode(bytes);
    await Clipboard.setData(ClipboardData(text: base64));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('バイナリデータをコピーしました')));
  }

  /// QRコード画像を生成し、PNGとして共有する。
  Future<void> _shareQrImage({
    required BuildContext context,
    required QrEntryModel entry,
    required String dataText,
    required QrGenerationConfig qrConfig,
  }) async {
    try {
      final painter = QrPainter(
        data: dataText,
        version: QrVersions.auto,
        errorCorrectionLevel: _toQrErrorCorrectLevel(qrConfig.errorLevel),
        gapless: qrConfig.gapless,
      );
      final pngBytes = await _buildShareImageBytes(
        entry: entry,
        painter: painter,
      );

      await SharePlus.instance.share(
        ShareParams(
          text: '${entry.name} のQRコード',
          files: [
            XFile.fromData(
              Uint8List.fromList(pngBytes),
              mimeType: 'image/png',
              name: 'qr_${entry.id}.png',
            ),
          ],
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('QR画像の共有に失敗しました: $error')));
    }
  }

  /// 共有用の PNG 画像を合成する。
  ///
  /// 画像には名称、任意のサムネイル、余白付き QR コードを含める。
  Future<Uint8List> _buildShareImageBytes({
    required QrEntryModel entry,
    required QrPainter painter,
  }) async {
    final qrByteData = await painter.toImageData(
      1024,
      format: ui.ImageByteFormat.png,
    );
    final qrBytes = qrByteData?.buffer.asUint8List();
    if (qrBytes == null || qrBytes.isEmpty) {
      throw StateError('QR画像の生成に失敗しました');
    }

    final qrImage = await _decodeUiImage(qrBytes);
    final thumbnailImage = entry.thumbnail != null
        ? await _decodeUiImage(entry.thumbnail!)
        : null;

    const canvasWidth = 1280;
    final hasThumbnail = thumbnailImage != null;
    final canvasHeight = hasThumbnail ? 1720 : 1460;
    const horizontalPadding = 72.0;
    const quietZone = 72.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final backgroundPaint = Paint()..color = Colors.white;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, canvasWidth.toDouble(), canvasHeight.toDouble()),
      backgroundPaint,
    );

    final titlePainter = TextPainter(
      text: TextSpan(
        text: entry.name,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 56,
          fontWeight: FontWeight.w700,
        ),
      ),
      maxLines: 2,
      ellipsis: '…',
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: canvasWidth - horizontalPadding * 2);

    final titleOffset = Offset((canvasWidth - titlePainter.width) / 2, 56);
    titlePainter.paint(canvas, titleOffset);

    var cursorY = titleOffset.dy + titlePainter.height + 36;

    if (thumbnailImage != null) {
      const thumbMaxWidth = 360.0;
      final ratio = thumbnailImage.width / thumbnailImage.height;
      final thumbHeight = ratio >= 1 ? thumbMaxWidth / ratio : thumbMaxWidth;
      final thumbWidth = ratio >= 1 ? thumbMaxWidth : thumbMaxWidth * ratio;
      final thumbRect = Rect.fromLTWH(
        (canvasWidth - thumbWidth) / 2,
        cursorY,
        thumbWidth,
        thumbHeight,
      );

      final clipRRect = RRect.fromRectAndRadius(
        thumbRect,
        const Radius.circular(24),
      );
      canvas.save();
      canvas.clipRRect(clipRRect);
      canvas.drawImageRect(
        thumbnailImage,
        Rect.fromLTWH(
          0,
          0,
          thumbnailImage.width.toDouble(),
          thumbnailImage.height.toDouble(),
        ),
        thumbRect,
        Paint(),
      );
      canvas.restore();

      cursorY = thumbRect.bottom + 44;
    }

    const qrOuterSize = canvasWidth - horizontalPadding * 2;
    const qrInnerSize = qrOuterSize - quietZone * 2;
    final qrOuterRect = Rect.fromLTWH(
      horizontalPadding,
      cursorY,
      qrOuterSize,
      qrOuterSize,
    );
    final qrInnerRect = Rect.fromLTWH(
      qrOuterRect.left + quietZone,
      qrOuterRect.top + quietZone,
      qrInnerSize,
      qrInnerSize,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(qrOuterRect, const Radius.circular(28)),
      Paint()..color = Colors.white,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(qrOuterRect, const Radius.circular(28)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0x33000000),
    );

    canvas.drawImageRect(
      qrImage,
      Rect.fromLTWH(0, 0, qrImage.width.toDouble(), qrImage.height.toDouble()),
      qrInnerRect,
      Paint(),
    );

    final image = await recorder.endRecording().toImage(
      canvasWidth,
      canvasHeight,
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final png = bytes?.buffer.asUint8List();
    if (png == null || png.isEmpty) {
      throw StateError('共有画像の生成に失敗しました');
    }
    return png;
  }

  /// PNG/JPEG バイト列を [ui.Image] に変換する。
  Future<ui.Image> _decodeUiImage(Uint8List bytes) {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, completer.complete);
    return completer.future;
  }

  Widget _infoRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/'
        '${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  /// 詳細画面のサムネイル表示を構築する。
  ///
  /// QR未登録の場合はグレースケールで表示して状態を視覚的に区別する。
  Widget _buildDetailThumbnail(QrEntryModel entry) {
    final image = Image.memory(
      entry.thumbnail!,
      fit: BoxFit.contain,
      width: double.infinity,
    );
    if (entry.hasQrData) {
      return image;
    }
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
      child: Opacity(opacity: 0.6, child: image),
    );
  }
}

/// サムネイル拡大表示専用ページ。
///
/// 詳細画面のサムネイルと同じ Hero tag を使い、
/// ルート遷移時に自然な拡大アニメーションを行う。
class _ThumbnailPreviewPage extends StatelessWidget {
  const _ThumbnailPreviewPage({required this.entry});

  final QrEntryModel entry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('thumbnail-preview-page'),
      backgroundColor: Colors.black87,
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Center(
          child: Hero(
            tag: 'thumb_${entry.id}',
            child: Material(
              color: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.memory(entry.thumbnail!, fit: BoxFit.contain),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
