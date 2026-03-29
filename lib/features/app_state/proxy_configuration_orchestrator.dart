import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/account_profile.dart';
import '../../data/models/app_settings.dart';

typedef ProxyConfigurationSyncCallback =
    Future<void> Function({required AppSettings settings, required List<AccountProfile> accounts});
typedef ProxyConfigurationRefreshCallback = Future<void> Function();
typedef ProxyConfigurationErrorReporter = void Function(Object error, StackTrace stackTrace);

class ProxyConfigurationOrchestrator {
  ProxyConfigurationOrchestrator({
    required AppSettings? Function() readSettings,
    required List<AccountProfile>? Function() readAccounts,
    required ProxyConfigurationSyncCallback syncConfiguration,
    required ProxyConfigurationRefreshCallback refreshAccounts,
    required ProxyConfigurationRefreshCallback refreshLogs,
    ProxyConfigurationErrorReporter? reportSyncError,
  }) : _readSettings = readSettings,
       _readAccounts = readAccounts,
       _syncConfiguration = syncConfiguration,
       _refreshAccounts = refreshAccounts,
       _refreshLogs = refreshLogs,
       _reportSyncError = reportSyncError ?? _defaultReportSyncError;

  final AppSettings? Function() _readSettings;
  final List<AccountProfile>? Function() _readAccounts;
  final ProxyConfigurationSyncCallback _syncConfiguration;
  final ProxyConfigurationRefreshCallback _refreshAccounts;
  final ProxyConfigurationRefreshCallback _refreshLogs;
  final ProxyConfigurationErrorReporter _reportSyncError;

  Future<void>? _pendingSync;
  bool _syncRequested = false;
  bool _suppressAccountsSync = false;
  bool _disposed = false;

  void onSettingsChanged() {
    _scheduleSync();
  }

  void onAccountsChanged() {
    if (_suppressAccountsSync) {
      return;
    }
    _scheduleSync();
  }

  void onProxyActivity(String? activity) {
    if (_disposed) {
      return;
    }
    if (activity == 'accounts') {
      unawaited(_refreshAccountsFromRuntime());
    } else if (activity == 'logs') {
      unawaited(_refreshLogs());
    }
  }

  void dispose() {
    _disposed = true;
  }

  void _scheduleSync() {
    if (_disposed) {
      return;
    }

    _syncRequested = true;
    _pendingSync ??= Future<void>.microtask(() async {
      try {
        while (_syncRequested && !_disposed) {
          _syncRequested = false;
          final settings = _readSettings();
          final accounts = _readAccounts();
          try {
            if (settings != null && accounts != null) {
              await _syncConfiguration(settings: settings, accounts: accounts);
            }
          } catch (error, stackTrace) {
            _reportSyncError(error, stackTrace);
          }
        }
      } finally {
        _pendingSync = null;
        if (_syncRequested && !_disposed) {
          _scheduleSync();
        }
      }
    });
  }

  Future<void> _refreshAccountsFromRuntime() async {
    if (_disposed) {
      return;
    }

    _suppressAccountsSync = true;
    try {
      await _refreshAccounts();
    } finally {
      _suppressAccountsSync = false;
    }
  }

  static void _defaultReportSyncError(Object error, StackTrace stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'kick',
        context: ErrorDescription('while synchronizing proxy configuration'),
      ),
    );
  }
}
