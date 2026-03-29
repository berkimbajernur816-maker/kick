import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kick/data/models/account_profile.dart';
import 'package:kick/data/models/app_settings.dart';
import 'package:kick/features/app_state/proxy_configuration_orchestrator.dart';

void main() {
  group('ProxyConfigurationOrchestrator', () {
    test('continues syncing after a failed configure', () async {
      var configureCallCount = 0;
      final reportedErrors = <Object>[];
      final orchestrator = ProxyConfigurationOrchestrator(
        readSettings: () => AppSettings.defaults(apiKey: 'initial-key'),
        readAccounts: () => const <AccountProfile>[],
        syncConfiguration: ({required settings, required accounts}) async {
          configureCallCount += 1;
          if (configureCallCount == 1) {
            throw StateError('configure failed once');
          }
        },
        refreshAccounts: () async {},
        refreshLogs: () async {},
        reportSyncError: (error, stackTrace) => reportedErrors.add(error),
      );
      addTearDown(orchestrator.dispose);

      orchestrator.onSettingsChanged();
      await _flushAsyncWork();

      orchestrator.onSettingsChanged();
      await _flushAsyncWork();

      expect(configureCallCount, 2);
      expect(reportedErrors.single, isA<StateError>());
    });

    test('coalesces repeated sync requests while configure is in flight', () async {
      final startedFirstConfigure = Completer<void>();
      final releaseFirstConfigure = Completer<void>();
      final configuredPorts = <int>[];
      var settings = AppSettings.defaults(apiKey: 'initial-key');
      final orchestrator = ProxyConfigurationOrchestrator(
        readSettings: () => settings,
        readAccounts: () => const <AccountProfile>[],
        syncConfiguration: ({required settings, required accounts}) async {
          configuredPorts.add(settings.port);
          if (configuredPorts.length == 1) {
            startedFirstConfigure.complete();
            await releaseFirstConfigure.future;
          }
        },
        refreshAccounts: () async {},
        refreshLogs: () async {},
      );
      addTearDown(orchestrator.dispose);

      orchestrator.onSettingsChanged();
      await startedFirstConfigure.future;

      settings = settings.copyWith(port: 4010);
      orchestrator.onSettingsChanged();
      settings = settings.copyWith(port: 4020);
      orchestrator.onSettingsChanged();

      releaseFirstConfigure.complete();
      await _flushAsyncWork();

      expect(configuredPorts, <int>[3000, 4020]);
    });

    test('suppresses account-triggered sync during runtime refresh', () async {
      var configureCallCount = 0;
      var refreshAccountsCallCount = 0;
      late ProxyConfigurationOrchestrator orchestrator;
      orchestrator = ProxyConfigurationOrchestrator(
        readSettings: () => AppSettings.defaults(apiKey: 'initial-key'),
        readAccounts: () => const <AccountProfile>[],
        syncConfiguration: ({required settings, required accounts}) async {
          configureCallCount += 1;
        },
        refreshAccounts: () async {
          refreshAccountsCallCount += 1;
          orchestrator.onAccountsChanged();
        },
        refreshLogs: () async {},
      );
      addTearDown(orchestrator.dispose);

      orchestrator.onProxyActivity('accounts');
      await _flushAsyncWork();

      expect(refreshAccountsCallCount, 1);
      expect(configureCallCount, 0);
    });
  });
}

Future<void> _flushAsyncWork() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}
