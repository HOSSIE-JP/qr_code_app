import 'dart:convert';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
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
    final url = _extractUrl(dataText);
    final qrConfig = ref.watch(qrGenerationSettingsProvider);

    return Scaffold(
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
                  title: Text('削除', style: TextStyle(color: colorScheme.error)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
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
                              constraints: const BoxConstraints(maxHeight: 280),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.memory(
                                  entry.thumbnail!,
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                ),
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
                            if (entry.description.isNotEmpty) ...[
                              const Divider(),
                              _infoRow(theme, '説明', entry.description),
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
