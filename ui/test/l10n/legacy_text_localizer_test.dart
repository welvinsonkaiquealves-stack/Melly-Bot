import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/l10n/legacy_text_localizer.dart';

void main() {
  tearDown(LegacyTextLocalizer.clearResolvedLocale);

  test('uses active locale override for legacy translations', () {
    LegacyTextLocalizer.setResolvedLocale(const Locale('zh'));
    expect(LegacyTextLocalizer.localize('设置'), '设置');

    LegacyTextLocalizer.setResolvedLocale(const Locale('en'));
    expect(LegacyTextLocalizer.localize('设置'), 'Settings');

    LegacyTextLocalizer.setResolvedLocale(const Locale('pt', 'BR'));
    expect(LegacyTextLocalizer.localize('设置'), 'Settings');
    expect(
      LegacyTextLocalizer.localize('Melly忙不过来了，等会儿再试试吧'),
      'Melly is busy right now. Please try again in a moment.',
    );
  });
}
