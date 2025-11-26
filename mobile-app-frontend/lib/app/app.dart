import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:ssi_app/app/router/app_router.dart';
import 'package:ssi_app/app/theme/app_theme.dart';
import 'package:ssi_app/core/utils/navigation_utils.dart';
import 'package:ssi_app/l10n/app_localizations.dart';
import 'package:ssi_app/services/localization/language_service.dart';
import 'package:ssi_app/services/wallet/wallet_connect_service.dart';

class SSIApp extends StatefulWidget {
  const SSIApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static SSIAppState? of(BuildContext context) {
    return context.findAncestorStateOfType<SSIAppState>();
  }

  @override
  State<SSIApp> createState() => SSIAppState();
}

class SSIAppState extends State<SSIApp> with WidgetsBindingObserver {
  Locale _locale = LanguageService.defaultLocale;
  final WalletConnectService _walletConnectService = WalletConnectService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadLocale();
    _initWalletConnect();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _initWalletConnect() async {
    try {
      await _walletConnectService.init();
    } catch (e) {
      debugPrint('[SSIApp] Error initializing WalletConnect: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // App đã quay lại từ background (có thể từ MetaMask)
      // Kiểm tra WalletConnect session và tự động quay lại app nếu cần
      _handleAppResume();
    }
  }

  Future<void> _handleAppResume() async {
    try {
      // Đợi một chút để đảm bảo WalletConnect đã process response
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Kiểm tra xem có pending transaction/signature không
      final hasPending = _walletConnectService.hasPendingRequest();
      final isPendingTransaction = _walletConnectService.isPendingTransactionOrSignature();
      
      if (hasPending || isPendingTransaction) {
        debugPrint('[SSIApp] App resumed with pending WalletConnect request - waiting for completion');
        // WalletConnect sẽ tự động handle response khi app resume
        // Không cần làm gì thêm vì ReownAppKit sẽ tự động process pending requests
        
        // Đợi thêm một chút để xem transaction có được complete không
        await Future.delayed(const Duration(seconds: 2));
        
        // Nếu vẫn còn pending sau khi đợi, có thể user đã cancel
        // Clear flags và dismiss any dialogs
        final stillPending = _walletConnectService.isPendingTransactionOrSignature();
        if (stillPending) {
          debugPrint('[SSIApp] Transaction still pending after delay - user may have cancelled');
          // Clear pending flags to allow app to function normally
          _walletConnectService.clearPendingFlags();
          // Dismiss any blocking dialogs that might be showing
          // Only dismiss if there's actually a blocking dialog (like spinner)
          NavigationUtils.safePopDialog(null);
        }
      } else {
        // Không có pending request - có thể session đã được approve hoặc user đã quay lại
        debugPrint('[SSIApp] App resumed - no pending requests');
        
        // KHÔNG dismiss dialog tự động khi không có pending request
        // Vì user có thể đang ở trong một dialog quan trọng (như UpdateDIDDialog)
        // Chỉ dismiss nếu thực sự cần thiết (blocking dialogs từ WalletConnect)
        // NavigationUtils.safePopDialog(null); // REMOVED - don't auto-dismiss
      }
      
      // Kiểm tra xem có active session không (có thể đã được approve trong background)
      final hasActiveSession = await _walletConnectService.hasActiveSession();
      if (hasActiveSession) {
        debugPrint('[SSIApp] Active WalletConnect session detected after resume');
      }
    } catch (e) {
      debugPrint('[SSIApp] Error handling app resume: $e');
      // Fallback: clear flags but don't dismiss dialogs on error
      // User might be in an important dialog
      try {
        _walletConnectService.clearPendingFlags();
        // Only dismiss if there's a real error that requires cleanup
        // NavigationUtils.safePopDialog(null); // REMOVED - don't auto-dismiss
      } catch (fallbackError) {
        debugPrint('[SSIApp] Error in fallback cleanup: $fallbackError');
      }
    }
  }

  Future<void> _loadLocale() async {
    final savedLocale = await LanguageService.getSavedLocale();
    if (mounted) {
      setState(() {
        _locale = savedLocale;
      });
    }
  }

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
    LanguageService.setLocale(locale);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: SSIApp.navigatorKey,
      title: 'SSI Blockchain',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: LanguageService.supportedLocales,
      initialRoute: AppRouter.splash,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}

