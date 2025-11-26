import 'package:flutter/material.dart';

import 'package:ssi_app/app/theme/app_gradients.dart';
import 'package:ssi_app/core/widgets/gradient_background.dart';
import 'package:ssi_app/features/auth/authenticate/view/authenticate_screen.dart';
import 'package:ssi_app/features/home/view/home_screen.dart';
import 'package:ssi_app/services/auth/auth_service.dart';
import 'package:ssi_app/services/wallet/wallet_connect_service.dart';
import 'package:ssi_app/services/web3/web3_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Wait for splash animation
    await Future.delayed(const Duration(seconds: 3));
    
    if (!mounted) return;

    // Check for any wallet (private key or WalletConnect)
    final web3Service = Web3Service();
    final walletConnectService = WalletConnectService();
    
    String? walletAddress;
    
    // Try private key wallet first
    try {
      walletAddress = await web3Service.loadWallet();
    } catch (e) {
      debugPrint('[SplashScreen] Error loading private key wallet: $e');
    }
    
    // If no private key wallet, try WalletConnect
    if (walletAddress == null || walletAddress.isEmpty) {
      try {
        walletAddress = await walletConnectService.getStoredAddress();
      } catch (e) {
        debugPrint('[SplashScreen] Error loading WalletConnect address: $e');
      }
    }

    if (!mounted) return;

    final authService = AuthService();
    final hasStoredCredentials = await authService.hasStoredCredentials();

    if (!mounted) return;

    // If we have a wallet address but no password/biometric auth, go directly to home
    if (walletAddress != null && walletAddress.isNotEmpty && !hasStoredCredentials) {
      debugPrint('[SplashScreen] Wallet found (${walletAddress.substring(0, 10)}...) and no auth required, going to home');
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, animation, __) => FadeTransition(
            opacity: animation,
            child: const HomeScreen(),
          ),
        ),
      );
    } else if (hasStoredCredentials) {
      // User has stored credentials (password/biometric), show authentication screen
      debugPrint('[SplashScreen] Password/biometric auth required, showing authenticate screen');
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, animation, __) => FadeTransition(
            opacity: animation,
            child: const AuthenticateScreen(),
          ),
        ),
      );
    } else {
      // No wallet and no credentials, show authenticate screen to connect wallet
      debugPrint('[SplashScreen] No wallet found, showing authenticate screen');
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, animation, __) => FadeTransition(
            opacity: animation,
            child: const AuthenticateScreen(),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        gradient: AppGradients.splash,
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  _SplashIcon(),
                  SizedBox(height: 32),
                  _SplashTitle(),
                  SizedBox(height: 12),
                  _SplashSubtitle(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashIcon extends StatelessWidget {
  const _SplashIcon();

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.18),
          // Keep a very light shadow to avoid heavy raster work on low-end GPUs.
          boxShadow: const [
            BoxShadow(
              color: Colors.white24,
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(
          Icons.fingerprint,
          size: 80,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _SplashTitle extends StatelessWidget {
  const _SplashTitle();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'SSI Blockchain',
      style: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _SplashSubtitle extends StatelessWidget {
  const _SplashSubtitle();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Self-Sovereign Identity',
      style: TextStyle(
        fontSize: 16,
        color: Colors.white.withValues(alpha: 0.8),
        letterSpacing: 2,
      ),
    );
  }
}

