import 'package:flutter_test/flutter_test.dart';
import 'package:qr_code_app/core/constants/app_constants.dart';

void main() {
  group('AppConstants', () {
    test('qrMaxTextBytes は 2953', () {
      expect(AppConstants.qrMaxTextBytes, 2953);
    });

    test('thumbnailMaxWidth は 512', () {
      expect(AppConstants.thumbnailMaxWidth, 512);
    });

    test('exportFileExtension は .qrdb', () {
      expect(AppConstants.exportFileExtension, '.qrdb');
    });

    test('exportJsonExtension は .qrjson', () {
      expect(AppConstants.exportJsonExtension, '.qrjson');
    });
  });
}
