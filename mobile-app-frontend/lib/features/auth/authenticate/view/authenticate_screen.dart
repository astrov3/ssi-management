import 'package:flutter/material.dart';

import 'package:ssi_app/app/theme/app_colors.dart';
import 'package:ssi_app/features/auth/shared/dialogs/auth_dialogs.dart';
import 'package:ssi_app/features/home/view/home_screen.dart';
import 'package:ssi_app/l10n/app_localizations.dart';
import 'package:ssi_app/services/auth/auth_service.dart';
import 'package:ssi_app/services/wallet/wallet_connect_service.dart';

class AuthenticateScreen extends StatefulWidget {
  const AuthenticateScreen({super.key});

  @override
  State<AuthenticateScreen> createState() => _AuthenticateScreenState();
}

class _AuthenticateScreenState extends State<AuthenticateScreen> with WidgetsBindingObserver {
  final _walletConnectService = WalletConnectService();
  bool _isLoading = false;
  bool _isConnectingWallet = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Defer wallet checks until after first frame to avoid blocking initial UI.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkExistingWallet();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _checkExistingWallet() async {
    try {
      final address = await _walletConnectService.getStoredAddress();
      if (mounted) {
        // If we have a stored WalletConnect address, check if we need authentication
        // If no password/biometric is set up, auto-login to home
        if (address != null && address.isNotEmpty) {
          final authService = AuthService();
          final hasStoredCredentials = await authService.hasStoredCredentials();
          
          // If no password/biometric authentication is required, auto-login
          if (!hasStoredCredentials) {
            debugPrint('[AuthenticateScreen] WalletConnect address found and no auth required, auto-logging in...');
            // Small delay to ensure UI is ready
            await Future.delayed(const Duration(milliseconds: 500));
            if (mounted) {
              _goToHome();
            }
          } else {
            debugPrint('[AuthenticateScreen] WalletConnect address found but authentication required');
            // User needs to authenticate with password/biometric
            // AuthenticateScreen will handle this
          }
        }
      }
    } catch (e) {
      debugPrint('[AuthenticateScreen] Error checking existing wallet: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && _isConnectingWallet) {
      _checkWalletConnectionAfterResume();
    }
  }

  Future<void> _checkWalletConnectionAfterResume() async {
    // Wait a bit longer to ensure any pending transactions/signatures are processed
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;
    
    // CRITICAL: Check if we're waiting for a transaction or signature
    // If yes, DON'T auto-navigate - user is still in MetaMask confirming transaction
    final isPending = _walletConnectService.isPendingTransactionOrSignature();
    if (isPending) {
      debugPrint('[AuthenticateScreen] App resumed but transaction/signature is pending, NOT auto-navigating');
      debugPrint('[AuthenticateScreen] User is still in MetaMask confirming transaction. Will wait for completion.');
      return;
    }
    
    try {
      final address = await _walletConnectService.getStoredAddress();
      if (address != null && address.isNotEmpty && mounted) {
        // Double-check we're still not pending (in case status changed)
        final stillPending = _walletConnectService.isPendingTransactionOrSignature();
        if (stillPending) {
          debugPrint('[AuthenticateScreen] Transaction/signature became pending, skipping auto-navigation');
          return;
        }
        
        setState(() {
          _isLoading = false;
          _isConnectingWallet = false;
        });
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          _goToHome();
        }
      }
    } catch (e) {
      debugPrint('[AuthenticateScreen] Error checking wallet connection after resume: $e');
      // Ignore - don't navigate on error
    }
  }


  Future<void> _connectWithMetaMask() async {
    setState(() {
      _isLoading = true;
      _isConnectingWallet = true;
    });
    
    try {
      final address = await _walletConnectService.connectWithWallet(
        walletUniversalLink: 'https://metamask.app.link',
      );
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _isConnectingWallet = false;
      });
      
      if (address.isNotEmpty) {
        if (mounted) {
          await _checkExistingWallet();
          await Future.delayed(const Duration(milliseconds: 100));
          if (mounted) {
            _goToHome();
          }
        }
      } else {
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;
        final checkAddress = await _walletConnectService.getStoredAddress();
        if (checkAddress != null && checkAddress.isNotEmpty && mounted) {
          await _checkExistingWallet();
          await Future.delayed(const Duration(milliseconds: 100));
          if (mounted) {
            _goToHome();
          }
        } else {
          if (mounted) {
            AuthDialogs.showError(
              context,
              AppLocalizations.of(context)!.cannotGetWalletInfoFromMetamask,
            );
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isConnectingWallet = false;
      });
      
      final checkAddress = await _walletConnectService.getStoredAddress();
      if (checkAddress != null && checkAddress.isNotEmpty && mounted) {
        await _checkExistingWallet();
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          _goToHome();
        }
      } else {
        if (mounted) {
          AuthDialogs.showError(
            context,
            AppLocalizations.of(context)!.metamaskConnectionFailed,
          );
        }
      }
    }
  }

  Future<void> _connectWithTrustWallet() async {
    setState(() {
      _isLoading = true;
      _isConnectingWallet = true;
    });
    
    try {
      final address = await _walletConnectService.connectWithWallet(
        walletUniversalLink: 'https://link.trustwallet.com',
      );
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _isConnectingWallet = false;
      });
      
      if (address.isNotEmpty) {
        if (mounted) {
          await _checkExistingWallet();
          await Future.delayed(const Duration(milliseconds: 100));
          if (mounted) {
            _goToHome();
          }
        }
      } else {
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;
        final checkAddress = await _walletConnectService.getStoredAddress();
        if (checkAddress != null && checkAddress.isNotEmpty && mounted) {
          await _checkExistingWallet();
          await Future.delayed(const Duration(milliseconds: 100));
          if (mounted) {
            _goToHome();
          }
        } else {
          if (mounted) {
            AuthDialogs.showError(
              context,
              AppLocalizations.of(context)!.trustWalletConnectionFailed,
            );
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isConnectingWallet = false;
      });
      
      final checkAddress = await _walletConnectService.getStoredAddress();
      if (checkAddress != null && checkAddress.isNotEmpty && mounted) {
        await _checkExistingWallet();
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          _goToHome();
        }
      } else {
        if (mounted) {
          AuthDialogs.showError(
            context,
            AppLocalizations.of(context)!.trustWalletConnectionFailed,
          );
        }
      }
    }
  }


  void _goToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
          child: Stack(
            children: [
              // Main scrollable content
              Column(
                children: [
                  // Main content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 32),
                          // Instruction text
                          _InstructionText(),
                          const SizedBox(height: 48),
                          // Wallet connection buttons (primary method)
                          _WalletButtons(
                            onMetaMask: _isLoading ? null : _connectWithMetaMask,
                            onTrustWallet: _isLoading ? null : _connectWithTrustWallet,
                          ),
                          // Add bottom padding to account for fixed support section
                          const SizedBox(height: 180),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // Support section fixed at bottom
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _SupportSection(),
              ),
            ],
          ),
      ),
    );
  }
}

class _InstructionText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Text(
          l10n.loginToIdentityWallet,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.grey[900],
            height: 1.3,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Connect your wallet to continue',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _WalletButtons extends StatelessWidget {
  const _WalletButtons({
    required this.onMetaMask,
    required this.onTrustWallet,
  });

  final VoidCallback? onMetaMask;
  final VoidCallback? onTrustWallet;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 56,
          child: ElevatedButton.icon(
            onPressed: onMetaMask,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              elevation: 4,
              shadowColor: Colors.black.withValues(alpha: 0.15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            icon: const Icon(Icons.account_balance_wallet_outlined, size: 24),
            label: Text(
              l10n.connectWithMetaMask,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 56,
          child: ElevatedButton.icon(
            onPressed: onTrustWallet,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              elevation: 4,
              shadowColor: Colors.black.withValues(alpha: 0.15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            icon: const Icon(Icons.verified_user_outlined, size: 24),
            label: Text(
              l10n.connectWithTrustWallet,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SupportSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _SupportItem(
                icon: Icons.help_outline,
                label: l10n.help,
                onTap: () {
                  // TODO: Show help
                },
              ),
              _SupportItem(
                icon: Icons.phone_outlined,
                label: AppLocalizations.of(context)!.support,
                onTap: () {
                  // TODO: Show support
                },
              ),
              _SupportItem(
                icon: Icons.info_outline,
                label: AppLocalizations.of(context)!.about,
                onTap: () {
                  // TODO: Show about
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              // TODO: Show privacy policy
            },
            child: Text(
              AppLocalizations.of(context)!.privacyPolicy,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 12,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportItem extends StatelessWidget {
  const _SupportItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.grey[900], size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


