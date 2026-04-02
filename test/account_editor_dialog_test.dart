import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kick/data/models/account_profile.dart';
import 'package:kick/features/accounts/account_editor_dialog.dart';
import 'package:kick/l10n/kick_localizations.dart';

void main() {
  final ruL10n = lookupKickLocalizations(const Locale('ru'));
  final enL10n = lookupKickLocalizations(const Locale('en'));

  testWidgets('expands advanced account settings without throwing', (tester) async {
    await tester.pumpWidget(const _TestApp());

    await tester.tap(find.text('Открыть диалог'));
    await tester.pumpAndSettle();

    expect(find.text(ruL10n.accountDialogAdvancedTitle), findsOneWidget);

    final advancedSettings = find.byType(ExpansionTile);
    await tester.ensureVisible(advancedSettings);
    await tester.tap(advancedSettings);
    await tester.pumpAndSettle();

    expect(find.text(ruL10n.blockedModelsLabel), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('allows submitting the dialog without project id', (tester) async {
    await tester.pumpWidget(const _TestApp());

    await tester.tap(find.text('Открыть диалог'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, ruL10n.continueButton));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text(ruL10n.projectIdRequiredError), findsNothing);
  });

  testWidgets('shows only browser authorization fields for kiro and stretches provider selector', (
    tester,
  ) async {
    await tester.pumpWidget(const _TestApp());

    await tester.tap(find.text('Открыть диалог'));
    await tester.pumpAndSettle();

    await tester.tap(find.text(ruL10n.accountProviderKiro));
    await tester.pumpAndSettle();

    expect(find.text('Способ подключения'), findsNothing);
    expect(find.text('Локальная сессия'), findsNothing);
    expect(find.text('Локальный источник Kiro'), findsNothing);
    expect(find.text(ruL10n.kiroBuilderIdStartUrlLabel), findsOneWidget);
    expect(find.text(ruL10n.kiroRegionLabel), findsOneWidget);
    expect(find.text(ruL10n.kiroBuilderIdStartUrlHelperText), findsOneWidget);
    expect(find.text(ruL10n.kiroRegionHelperText), findsOneWidget);

    final providerSelector = find.byWidgetPredicate(
      (widget) => widget is SegmentedButton<AccountProvider>,
    );
    final field = find.byType(TextField).first;
    expect(tester.getSize(providerSelector).width, closeTo(tester.getSize(field).width, 0.1));
  });

  testWidgets('builds the account editor dialog with the English locale enabled', (tester) async {
    await tester.pumpWidget(const _TestApp(locale: Locale('en')));

    await tester.tap(find.text('Открыть диалог'));
    await tester.pumpAndSettle();

    expect(find.text(enL10n.accountDialogTitle), findsOneWidget);
    expect(find.text(enL10n.accountDialogBasicsTitle), findsOneWidget);
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({this.locale});

  final Locale? locale;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: FilledButton(
              onPressed: () {
                showAccountEditorDialog(context);
              },
              child: const Text('Открыть диалог'),
            ),
          ),
        ),
      ),
    );
  }
}
