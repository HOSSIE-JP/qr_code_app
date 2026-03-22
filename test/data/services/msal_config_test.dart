import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android の MSAL 設定は個人 Microsoft アカウント専用になっている', () async {
    final jsonText = await File('assets/msal_config.json').readAsString();
    final decoded = jsonDecode(jsonText) as Map<String, dynamic>;
    final authorities = decoded['authorities'] as List<dynamic>;
    final authority = authorities.single as Map<String, dynamic>;
    final audience = authority['audience'] as Map<String, dynamic>;

    expect(audience['type'], 'PersonalMicrosoftAccount');
    expect(
      authority['authority_url'],
      'https://login.microsoftonline.com/consumers',
    );
    expect(authority['default'], isTrue);
    expect(decoded['broker_redirect_uri_registered'], isFalse);
  });
}
