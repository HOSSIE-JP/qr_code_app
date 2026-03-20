import 'dart:convert';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../providers/providers.dart';
import '../../router/app_router.dart';

/// QR コードスキャンページ。カメラでリアルタイムに QR コードを読み取る。
///
/// 読み取った QR コードはすべて標準テキスト QR として扱い、
/// DB に同じデータが登録されている場合は編集画面へ遷移する。
@RoutePage()
class ScannerPage extends ConsumerStatefulWidget {
  const ScannerPage({super.key});

  @override
  ConsumerState<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends ConsumerState<ScannerPage> {
  final MobileScannerController _controller = MobileScannerController();

  /// ナビゲーション処理中フラグ。true の間は新しい検出を無視する。
  bool _navigating = false;

  /// 最後に検出した値。同一 QR の連続検出を抑止する。
  String? _lastScannedValue;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QRコードスキャン'),
        actions: [
          // 画像ファイルから QR コードを読み取るボタン
          IconButton(
            icon: const Icon(Icons.image),
            onPressed: _pickImage,
            tooltip: '画像から読み取り',
          ),
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
            tooltip: 'フラッシュ',
          ),
          IconButton(
            icon: const Icon(Icons.camera_front),
            onPressed: () => _controller.switchCamera(),
            tooltip: 'カメラ切替',
          ),
        ],
      ),
      body: MobileScanner(controller: _controller, onDetect: _onDetect),
    );
  }

  /// カメラが QR コードを検出したときのコールバック。
  ///
  /// rawDecodedBytes が取得できる場合はバイト列をそのまま保存し、
  /// QR コードの再表示時に元と同じ内容を再現できるようにする。
  void _onDetect(BarcodeCapture capture) {
    if (_navigating) return;

    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue == null || rawValue == _lastScannedValue) continue;

      _navigating = true;
      _lastScannedValue = rawValue;
      // rawDecodedBytes があればそのまま使い、なければ rawValue を UTF-8 エンコード
      final Uint8List data;
      final rawDecoded = barcode.rawDecodedBytes;
      if (rawDecoded is DecodedBarcodeBytes) {
        data = rawDecoded.bytes;
      } else if (rawDecoded is DecodedVisionBarcodeBytes) {
        data = rawDecoded.bytes ?? rawDecoded.rawBytes;
      } else {
        data = Uint8List.fromList(utf8.encode(rawValue));
      }
      _navigateWithData(data, isTextMode: true);
      return;
    }
  }

  /// スキャンデータで DB を検索し、既存なら編集画面、新規なら登録画面に遷移する。
  ///
  /// 遷移先から戻ったら再スキャン可能にするため [_navigating] をリセットする。
  Future<void> _navigateWithData(
    Uint8List data, {
    required bool isTextMode,
  }) async {
    try {
      final repo = ref.read(qrRepositoryProvider);
      final existing = await repo.findByOriginalData(data);
      if (!mounted) return;

      if (existing != null) {
        // 既に DB に存在 → 編集画面へ
        await context.router.push(EditRoute(entryId: existing.id));
      } else {
        // 新規データ → 登録画面へ
        await context.router.push(
          ScanProgressRoute(scannedData: data, isTextMode: isTextMode),
        );
      }
    } finally {
      // 戻ってきたら再スキャン可能にする
      if (mounted) {
        _navigating = false;
        _lastScannedValue = null;
      }
    }
  }

  /// 画像ファイルからQRコードを読み取る。
  Future<void> _pickImage() async {
    // Web ではファイルパスを取得できないため analyzeImage が使えない
    if (kIsWeb) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Web 環境では画像読み取りに対応していません')));
      return;
    }

    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final result = await _controller.analyzeImage(image.path);
    if (!mounted) return;

    if (result == null || result.barcodes.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('画像からQRコードを検出できませんでした')));
      return;
    }

    // 検出された QR コードをカメラ検出と同じロジックで処理する
    _onDetect(result);
  }
}
