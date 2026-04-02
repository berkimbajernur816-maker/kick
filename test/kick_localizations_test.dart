import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kick/l10n/kick_localizations.dart';

void main() {
  testWidgets('resolves supported locales from the system locale list', (tester) async {
    addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
    tester.binding.platformDispatcher.localesTestValue = const <Locale>[
      Locale('ru', 'RU'),
      Locale('en', 'US'),
    ];

    final l10n = lookupKickLocalizations();

    expect(l10n.localeName, 'ru');
  });

  testWidgets('falls back to English when the system locale is unsupported', (tester) async {
    addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
    tester.binding.platformDispatcher.localesTestValue = const <Locale>[Locale('de', 'DE')];

    final l10n = lookupKickLocalizations();

    expect(l10n.localeName, 'en');
  });
}
