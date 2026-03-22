import 'dart:convert';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/web/pwa_install_helper.dart';
import '../../data/models/qr_entry_model.dart';
import '../../providers/providers.dart';

/// QR コード画像を表示するページ。
///
/// エントリの originalData をそのまま文字列として QR コードに埋め込む。
/// rawBytes 保存されたデータは UTF-8 → Latin-1 の順にデコードを試み、
/// 元の QR コードと同等の内容を再現する。
@RoutePage()
class QrViewerPage extends ConsumerWidget {
  const QrViewerPage({super.key, required this.entryId});

  final String entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entryAsync = ref.watch(qrEntryByIdProvider(entryId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('QRコード表示'),
        actions: [
          if (kIsWeb)
            IconButton(
              tooltip: 'ホーム画面に追加',
              icon: const Icon(Icons.add_to_home_screen),
              onPressed: () => _installAsPwa(context),
            ),
        ],
      ),
      body: entryAsync.when(
        data: (entry) {
          if (entry == null) {
            return const Center(child: Text('エントリが見つかりません'));
          }
          return _QrViewerContent(entry: entry);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('エラー: $e')),
      ),
    );
  }

  /// Web 向けに PWA インストールダイアログを表示する。
  Future<void> _installAsPwa(BuildContext context) async {
    final prompted = await promptPwaInstall();
    if (!context.mounted) {
      return;
    }

    if (prompted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ホーム画面への追加を開始しました')));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('このブラウザでは自動追加できません。ブラウザメニューからホーム画面に追加してください。'),
      ),
    );
  }
}

/// QR コードの表示本体。
///
/// originalData を文字列にデコードして QrImageView に渡す。
/// QR コードの表示サイズを大・中・小のプリセットまたはスライダーで変更できる。
class _QrViewerContent extends ConsumerStatefulWidget {
  const _QrViewerContent({required this.entry});

  final QrEntryModel entry;

  @override
  ConsumerState<_QrViewerContent> createState() => _QrViewerContentState();
}

class _QrViewerContentState extends ConsumerState<_QrViewerContent> {
  /// QR コードの表示サイズ（ピクセル）。スライダーとプリセットで変更可能。
  double _qrSize = 300;

  /// プリセットサイズ定義。
  static const double _sizeSmall = 120;
  @override
  void initState() {
    super.initState();
    // ユーザー設定の初期サイズを反映する。
    final savedSize = ref.read(qrViewerDefaultSizeProvider);
    _qrSize = savedSize.clamp(120, 500);
  }

  static const double _sizeMedium = 300;
  static const double _sizeLarge = 400;

  /// originalData を文字列にデコードして返す。
  ///
  /// まず UTF-8 を試み、失敗時は Latin-1 にフォールバックする。
  /// これによりスキャン時の rawBytes を忠実に再現できる。
  String _decodeData() {
    final bytes = widget.entry.originalData;
    try {
      return utf8.decode(bytes);
    } catch (_) {
      // UTF-8 デコード失敗時は Latin-1 (ISO 8859-1) にフォールバック
      return String.fromCharCodes(bytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dataText = _decodeData();
    final qrConfig = ref.watch(qrGenerationSettingsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            widget.entry.name,
            style: theme.textTheme.titleLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: QrImageView(
                data: dataText,
                version: QrVersions.auto,
                size: _qrSize,
                errorCorrectionLevel: _toQrErrorCorrectLevel(
                  qrConfig.errorLevel,
                ),
                gapless: qrConfig.gapless,
                backgroundColor: Colors.white,
                padding: EdgeInsets.all(qrConfig.padding),
              ),
            ),
          ),
        ),
        // サイズ調整コントロール
        _buildSizeControls(theme, colorScheme),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.qr_code, size: 16, color: colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        _formatSize(widget.entry.dataSize),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dataText.length > 200
                        ? '${dataText.substring(0, 200)}...'
                        : dataText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  /// QR コードの表示サイズを変更するプリセットボタンとスライダー。
  Widget _buildSizeControls(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _sizePresetButton(theme, colorScheme, '小', _sizeSmall),
              const SizedBox(width: 8),
              _sizePresetButton(theme, colorScheme, '中', _sizeMedium),
              const SizedBox(width: 8),
              _sizePresetButton(theme, colorScheme, '大', _sizeLarge),
            ],
          ),
          Slider(
            value: _qrSize,
            min: 120,
            max: 500,
            divisions: 38,
            label: '${_qrSize.round()}px',
            onChanged: (v) {
              setState(() => _qrSize = v);
            },
          ),
        ],
      ),
    );
  }

  Widget _sizePresetButton(
    ThemeData theme,
    ColorScheme colorScheme,
    String label,
    double size,
  ) {
    final isSelected = (_qrSize - size).abs() < 1;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _qrSize = size);
      },
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
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
}
