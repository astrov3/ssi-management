import 'package:flutter/material.dart';
import 'package:ssi_app/app/app.dart';

/// Utility class for safe navigation operations
/// Handles cases where context might be invalid (e.g., when returning from external app)
class NavigationUtils {
  const NavigationUtils._();

  /// Safely dismiss a dialog, even if context is invalid
  /// Uses global navigator key as fallback
  static void safePopDialog(BuildContext? context) {
    try {
      // Try using provided context first
      if (context != null) {
        final navigator = Navigator.of(context, rootNavigator: false);
        if (navigator.canPop()) {
          navigator.pop();
          return;
        }
      }
    } catch (e) {
      debugPrint('[NavigationUtils] Context-based pop failed: $e');
    }

    // Fallback: use global navigator key
    try {
      final navigator = SSIApp.navigatorKey.currentState;
      if (navigator != null && navigator.canPop()) {
        navigator.pop();
        debugPrint('[NavigationUtils] Dialog dismissed using global navigator key');
      } else {
        debugPrint('[NavigationUtils] Cannot pop - no dialog to dismiss');
      }
    } catch (e) {
      debugPrint('[NavigationUtils] Global navigator pop failed: $e');
    }
  }

  /// Safely dismiss multiple dialogs (e.g., nested dialogs)
  static void safePopDialogs(BuildContext? context, {int count = 1}) {
    for (int i = 0; i < count; i++) {
      safePopDialog(context);
    }
  }

  /// Check if a dialog is currently showing
  static bool hasDialog(BuildContext? context) {
    try {
      if (context != null) {
        final navigator = Navigator.of(context, rootNavigator: false);
        return navigator.canPop();
      }
    } catch (e) {
      debugPrint('[NavigationUtils] Error checking dialog: $e');
    }

    // Fallback: check global navigator
    try {
      final navigator = SSIApp.navigatorKey.currentState;
      return navigator != null && navigator.canPop();
    } catch (e) {
      return false;
    }
  }
}

