import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msal_auth/msal_auth.dart';
import 'package:qr_code_app/data/services/onedrive_auth_client_factory_msal.dart';

void main() {
  test('未ログインのMsalExceptionは対話認証フォールバック対象になる', () {
    const error = MsalException(
      message: 'There is no currently signed in account.',
      correlationId: null,
    );

    expect(isMsalInteractiveLoginRequired(error), isTrue);
    expect(canIgnoreMissingMsalAccount(error), isTrue);
  });

  test('MsalUiRequiredExceptionは対話認証フォールバック対象になる', () {
    const error = MsalUiRequiredException(
      oauthSubErrorCode: null,
      oauthError: null,
      oauthErrorDescription: null,
      message: 'UI is required for token acquisition.',
      correlationId: null,
    );

    expect(isMsalInteractiveLoginRequired(error), isTrue);
  });

  test('MsalUserCancelExceptionはキャンセルとして扱う', () {
    const error = MsalUserCancelException(
      message: 'User cancelled the flow.',
      correlationId: null,
    );

    expect(isMsalUserCancellation(error), isTrue);
  });

  test('Android ではログイン prompt を優先する', () {
    expect(resolveMsalPrompt(TargetPlatform.android), Prompt.login);
    expect(resolveMsalPrompt(TargetPlatform.macOS), Prompt.selectAccount);
  });
}
