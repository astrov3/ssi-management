import 'package:flutter/material.dart';

import 'package:ssi_app/features/auth/authenticate/view/authenticate_screen.dart';
import 'package:ssi_app/features/home/view/home_screen.dart';
import 'package:ssi_app/features/splash/view/splash_screen.dart';

class AppRouter {
  const AppRouter._();

  static const splash = '/';
  static const authenticate = '/authenticate';
  static const home = '/home';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _buildRoute(const SplashScreen(), settings);
      case authenticate:
        return _buildRoute(const AuthenticateScreen(), settings);
      case home:
        return _buildRoute(const HomeScreen(), settings, fullscreenDialog: true);
      default:
        return MaterialPageRoute<void>(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );
    }
  }

  static MaterialPageRoute<T> _buildRoute<T>(
    Widget child,
    RouteSettings settings, {
    bool fullscreenDialog = false,
  }) {
    return MaterialPageRoute<T>(
      builder: (_) => child,
      settings: settings,
      fullscreenDialog: fullscreenDialog,
    );
  }
}

