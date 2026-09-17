import 'dart:ui';

enum AppLanguageMode {
  system('system'),
  zhHans('zhHans'),
  en('en'),
  ptBr('ptBr');

  const AppLanguageMode(this.storageValue);

  final String storageValue;

  static AppLanguageMode fromStorageValue(String? raw) {
    final normalized = raw?.trim();
    return AppLanguageMode.values.firstWhere(
      (mode) => mode.storageValue == normalized,
      orElse: () => AppLanguageMode.system,
    );
  }
}

class ResolvedAppLocale {
  const ResolvedAppLocale({
    required this.mode,
    required this.systemLocale,
    required this.locale,
  });

  final AppLanguageMode mode;
  final Locale systemLocale;
  final Locale locale;

  bool get isEnglish => locale.languageCode != 'zh';
  bool get isChinese => locale.languageCode == 'zh';
  bool get isPortugueseBrazil => locale.languageCode == 'pt';
  String get brandName => 'Melly';
}

ResolvedAppLocale resolveAppLocale({
  required AppLanguageMode mode,
  required Locale systemLocale,
}) {
  final normalizedSystemLocale = _normalizeSupportedLocale(systemLocale);
  final resolvedLocale = switch (mode) {
    AppLanguageMode.system => normalizedSystemLocale,
    AppLanguageMode.zhHans => const Locale('zh', 'CN'),
    AppLanguageMode.en => const Locale('en', 'US'),
    AppLanguageMode.ptBr => const Locale('pt', 'BR'),
  };

  return ResolvedAppLocale(
    mode: mode,
    systemLocale: normalizedSystemLocale,
    locale: resolvedLocale,
  );
}

Locale _normalizeSupportedLocale(Locale locale) {
  if (locale.languageCode.toLowerCase() == 'zh') {
    return const Locale('zh', 'CN');
  }
  if (locale.languageCode.toLowerCase() == 'pt') {
    return const Locale('pt', 'BR');
  }
  return const Locale('en', 'US');
}
