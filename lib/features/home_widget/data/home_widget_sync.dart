import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';

import '../../../core/logging/app_log_buffer.dart';
import '../domain/home_widget_snapshot.dart';

/// Pushes [HomeWidgetSnapshot]s to the native home-screen widgets and
/// reports widget taps as app routes.
class HomeWidgetSync {
  static const androidProvider = 'com.nextgen.expenseflowapp.SafeToSpendWidget';
  static const iOSKind = 'SafeToSpendWidget';

  /// Must match the App Group of the Runner and the widget extension.
  static const iOSAppGroup = 'group.com.nextgen.expenseflowapp';

  /// Deep-link host → in-app route.
  static const routes = {'add-expense': '/add-expense', 'open': '/dashboard'};

  HomeWidgetSnapshot? _last;

  bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> initialize() async {
    if (!_supported) return;
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await HomeWidget.setAppGroupId(iOSAppGroup);
      }
    } on PlatformException catch (e, st) {
      AppLogBuffer.instance.captureError('homeWidget.init', e, st);
    }
  }

  /// Saves and redraws, skipping identical snapshots.
  Future<void> push(HomeWidgetSnapshot snapshot) async {
    if (!_supported || snapshot == _last) return;
    try {
      await Future.wait([
        HomeWidget.saveWidgetData<String>('date', snapshot.date),
        HomeWidget.saveWidgetData<String>('safe', snapshot.safeToSpend ?? ''),
        HomeWidget.saveWidgetData<String>('spent', snapshot.spentToday),
        HomeWidget.saveWidgetData<bool>('over', snapshot.overBudget),
        HomeWidget.saveWidgetData<bool>('hidden', snapshot.hidden),
      ]);
      await HomeWidget.updateWidget(
        qualifiedAndroidName: androidProvider,
        iOSName: iOSKind,
      );
      _last = snapshot;
    } on PlatformException catch (e, st) {
      AppLogBuffer.instance.captureError('homeWidget.push', e, st);
    } on MissingPluginException {
      // Not available in tests / unsupported embeddings.
    }
  }

  /// Route for a widget tap URI like `expenseflow://add-expense`.
  static String? routeFor(Uri? uri) =>
      uri == null ? null : routes[uri.host];

  /// Route to open if the app was cold-started from the widget.
  Future<String?> initialRoute() async {
    if (!_supported) return null;
    try {
      return routeFor(await HomeWidget.initiallyLaunchedFromHomeWidget());
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  Stream<String> get taps => _supported
      ? HomeWidget.widgetClicked.map(routeFor).where((r) => r != null).cast()
      : const Stream.empty();
}
