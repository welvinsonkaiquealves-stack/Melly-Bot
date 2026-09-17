import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ui/l10n/app_language_mode.dart';

void main() {
  test('resolves explicit and system Brazilian Portuguese locales', () {
    final explicit = resolveAppLocale(
      mode: AppLanguageMode.ptBr,
      systemLocale: const Locale('en', 'US'),
    );
    final system = resolveAppLocale(
      mode: AppLanguageMode.system,
      systemLocale: const Locale('pt', 'BR'),
    );

    expect(explicit.locale, const Locale('pt', 'BR'));
    expect(system.locale, const Locale('pt', 'BR'));
    expect(explicit.brandName, 'Melly');
  });
}
