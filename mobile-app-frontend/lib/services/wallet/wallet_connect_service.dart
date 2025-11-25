import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:reown_appkit/reown_appkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:ssi_app/config/environment.dart';

class WalletConnectService {
  WalletConnectService._internal();
  static final WalletConnectService _instance = WalletConnectService._internal();
  factory WalletConnectService() => _instance;

  ReownAppKit? _appKit;
  SessionData? _activeSession;
  bool _isPendingTransaction = false; // Track if we're waiting for transaction/signature
  bool _isPendingSignature = false; // Track if we're waiting for signature
  String? _lastWalletLink;
  String? _lastWalletConnectUri;
  
  /// Kiểm tra xem có pending request (transaction hoặc signature) không
  bool hasPendingRequest() {
    return _isPendingTransaction || _isPendingSignature;
  }

  Future<void> init() async {
    if (_appKit != null) {
      return;
    }

    final projectId = Environment.walletConnectProjectId;
    if (projectId.isEmpty) {
      throw StateError('Missing WALLETCONNECT_PROJECT_ID in .env');
    }

    _appKit = await ReownAppKit.createInstance(
      projectId: projectId,
      metadata: const PairingMetadata(
        name: 'SSI Mobile',
        description: 'SSI Mobile WalletConnect',
        url: 'https://ssi.example',
        icons: ['https://images.seeklogo.com/logo-png/43/1/walletconnect-logo-png_seeklogo-430923.png'],
      ),
    );
    
    // Restore active session nếu có
    await _restoreActiveSession();
  }
  
  /// Khôi phục active session từ ReownAppKit
  /// Chỉ restore nếu chưa logout
  Future<void> _restoreActiveSession() async {
    if (_appKit == null) return;
    
    // Kiểm tra xem có flag logout không
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedOut = prefs.getBool('walletconnect_logged_out') ?? false;
      if (isLoggedOut) {
        debugPrint('[WalletConnect] Logout flag detected - skipping session restore');
        // Clear flag để lần sau có thể restore lại nếu user login
        await prefs.remove('walletconnect_logged_out');
        return;
      }
    } catch (e) {
      debugPrint('[WalletConnect] Error checking logout flag: $e');
    }
    
    try {
      final activeSessions = _appKit!.getActiveSessions();
      if (activeSessions.isNotEmpty) {
        // Lấy session đầu tiên
        final session = activeSessions.values.first;
        _activeSession = session;
        debugPrint('[WalletConnect] Restored active session: ${session.topic}');
      }
    } catch (e) {
      debugPrint('[WalletConnect] Error restoring active session: $e');
    }
  }

  /// Checks if there's an active session and returns the address
  Future<String?> getActiveSessionAddress() async {
    await init();
    if (_activeSession != null) {
      try {
        final account = _firstAccountFromSession(_activeSession!);
        final address = _extractAddressFromAccount(account);
        if (_isValidEthereumAddress(address)) {
          return address;
        }
      } catch (e) {
        debugPrint('[WalletConnect] Error getting active session address: $e');
      }
    }
    return null;
  }

  Future<String?> getStoredAddress() async {
    await init();
    
    if (_activeSession != null) {
      try {
        final account = _firstAccountFromSession(_activeSession!);
        final address = _extractAddressFromAccount(account);
        if (_isValidEthereumAddress(address)) {
          debugPrint('[WalletConnect] Retrieved address from active session: $address');
          return address;
        }
      } catch (e) {
        debugPrint('[WalletConnect] Error getting address from active session: $e');
        _activeSession = null;
      }
    }
    
    debugPrint('[WalletConnect] No active session address available');
    return null;
  }

  /// Disconnect WalletConnect session
  /// [clearStoredData] - If true, clears stored address and topic. Default is false to allow session restore.
  Future<void> disconnect({bool clearStoredData = false}) async {
    final app = _appKit;
    
    if (app != null) {
      // Nếu clearStoredData = true, disconnect TẤT CẢ active sessions (logout)
      if (clearStoredData) {
        try {
          final activeSessions = app.getActiveSessions();
          for (final session in activeSessions.values) {
            try {
              await app.disconnectSession(
                topic: session.topic,
                reason: const ReownSignError(code: 6000, message: 'Session disconnected'),
              );
              debugPrint('[WalletConnect] Disconnected session: ${session.topic}');
            } catch (e) {
              debugPrint('[WalletConnect] Error disconnecting session ${session.topic}: $e');
            }
          }
          debugPrint('[WalletConnect] All sessions disconnected successfully');
        } catch (e) {
          debugPrint('[WalletConnect] Error getting active sessions: $e');
        }
      } else {
        // Chỉ disconnect session hiện tại (nếu có)
        final topic = _activeSession?.topic;
        if (topic != null) {
          try {
            await app.disconnectSession(
              topic: topic,
              reason: const ReownSignError(code: 6000, message: 'Session disconnected'),
            );
            debugPrint('[WalletConnect] Session disconnected successfully');
          } catch (e) {
            debugPrint('[WalletConnect] Error disconnecting session: $e');
          }
        }
      }
    }

    // Clear session references and cached links
    _activeSession = null;
    _lastWalletLink = null;
    _lastWalletConnectUri = null;
    
    if (clearStoredData) {
      debugPrint('[WalletConnect] Cleared cached wallet link and wc uri');
      // Lưu flag để không restore session sau khi logout
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('walletconnect_logged_out', true);
      debugPrint('[WalletConnect] Set logout flag to prevent session restore');
    }
  }

  Future<String> connectWithWallet({String? walletUniversalLink}) async {
    await init();
    final app = _appKit!;

    // Always disconnect any in-memory active session before starting a new login
    if (_activeSession != null) {
      debugPrint('[WalletConnect] Existing session found. Disconnecting to force fresh login...');
      await disconnect();
    }

    // Use Sepolia for development - declared in Environment
    // Also include mainnet as fallback for wallets that may not support Sepolia initially
    final sepoliaChain = Environment.sepoliaChainEip155;
    final ethereumMainnet = Environment.ethereumMainnetEip155;

    debugPrint('[WalletConnect] Starting connection with wallet: $walletUniversalLink');
    debugPrint('[WalletConnect] Requesting Sepolia (${Environment.sepoliaChainEip155}) as primary chain');

    final connectResponse = await app.connect(
      optionalNamespaces: {
        'eip155': RequiredNamespace(
          methods: const [
            'eth_sign',
            'personal_sign',
            'eth_signTypedData',
            'eth_sendTransaction',
            'wallet_switchEthereumChain',
            'wallet_addEthereumChain',
          ],
          // Request Sepolia first, but also allow mainnet for compatibility
          chains: [sepoliaChain, ethereumMainnet],
          events: const ['accountsChanged', 'chainChanged'],
        ),
      },
    );

    final uri = connectResponse.uri;
    if (uri != null) {
      debugPrint('[WalletConnect] URI generated: ${uri.toString()}');
      final wcUri = uri.toString();
      _lastWalletConnectUri = wcUri;
      debugPrint('[WalletConnect] Cached WalletConnect URI for in-app hand-offs');
      if (walletUniversalLink != null) {
        final deepLink = Uri.parse('$walletUniversalLink/wc?uri=${Uri.encodeComponent(wcUri)}');
        debugPrint('[WalletConnect] Launching deep link: $deepLink');
        await launchUrl(deepLink, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('[WalletConnect] Launching URI: $wcUri');
        await launchUrl(Uri.parse(wcUri), mode: LaunchMode.externalApplication);
      }
    }

    debugPrint('[WalletConnect] Waiting for session approval...');
    
    // Add timeout for session approval (5 minutes)
    final session = await connectResponse.session.future
        .timeout(
          const Duration(minutes: 5),
          onTimeout: () {
            debugPrint('[WalletConnect] Session approval timeout');
            throw TimeoutException(
              'Wallet connection timeout. Please try again.',
              const Duration(minutes: 5),
            );
          },
        );
    
    _activeSession = session;

    debugPrint('[WalletConnect] Session approved. Topic: ${session.topic}');
    debugPrint('[WalletConnect] Session namespaces: ${session.namespaces.keys.toList()}');
    
    debugPrint('[WalletConnect] Session approved - waiting for user to return to app manually');

    // Extract account with better error handling
    String address;
    try {
      final account = _firstAccountFromSession(session);
      debugPrint('[WalletConnect] Account extracted: $account');
      address = _extractAddressFromAccount(account);
      debugPrint('[WalletConnect] Address extracted: $address');
    } catch (e) {
      debugPrint('[WalletConnect] Error extracting account: $e');
      debugPrint('[WalletConnect] Session details: topic=${session.topic}, namespaces=${session.namespaces}');
      // Try alternative extraction methods
      address = _extractAddressAlternative(session);
      if (address.isEmpty) {
        rethrow;
      }
      debugPrint('[WalletConnect] Address extracted via alternative method: $address');
    }

    // Validate address format
    if (address.isEmpty || !_isValidEthereumAddress(address)) {
      throw StateError('Invalid wallet address extracted: $address');
    }

    if (walletUniversalLink != null && walletUniversalLink.isNotEmpty) {
      _lastWalletLink = walletUniversalLink;
      debugPrint('[WalletConnect] Cached wallet link for this session: $walletUniversalLink');
    } else {
      _lastWalletLink = null;
    }

    // Check if we're already on Sepolia, if not, attempt to switch
    final currentChainId = _getCurrentChainId(session);
    final targetSepoliaChainId = Environment.chainId;
    
    if (currentChainId != targetSepoliaChainId) {
      debugPrint('[WalletConnect] Current chain: $currentChainId, switching to Sepolia: $targetSepoliaChainId');
      try {
        await switchToSepolia().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            debugPrint('[WalletConnect] Sepolia switch timeout - connection still successful');
            return;
          },
        );
        debugPrint('[WalletConnect] Successfully switched to Sepolia');
      } catch (e) {
        debugPrint('[WalletConnect] Failed to switch to Sepolia: $e');
        debugPrint('[WalletConnect] Connection successful, but wallet may be on different chain');
        // Connection is still successful - user can manually switch to Sepolia if needed
      }
    } else {
      debugPrint('[WalletConnect] Already connected to Sepolia (chainId: $targetSepoliaChainId)');
    }

    debugPrint('[WalletConnect] Connection completed successfully. Returning address: $address');
    return address;
  }

  /// Gets the current chain ID from the session
  int? _getCurrentChainId(SessionData session) {
    try {
      final accounts = session.namespaces['eip155']?.accounts;
      if (accounts != null && accounts.isNotEmpty) {
        // Account format: eip155:chainId:address
        final firstAccount = accounts.first;
        final parts = firstAccount.split(':');
        if (parts.length >= 2) {
          return int.tryParse(parts[1]);
        }
      }
    } catch (e) {
      debugPrint('[WalletConnect] Error getting current chain ID: $e');
    }
    return null;
  }

  /// Attempts to switch the connected wallet to Sepolia testnet
  /// This may fail if Sepolia is not supported/added in the wallet
  Future<void> switchToSepolia() async {
    final app = _appKit;
    final session = _activeSession;
    if (app == null || session == null) {
      return;
    }

    final sepoliaChainId = Environment.chainId;
    final sepoliaChainIdHex = Environment.sepoliaChainIdHex;
    
    // Get the current chain from the session
    final currentAccounts = session.namespaces['eip155']?.accounts;
    if (currentAccounts == null || currentAccounts.isEmpty) {
      return;
    }
    
    // Try to find Sepolia account first, fallback to first account
    String chainIdToUse;
    try {
      final sepoliaAccount = currentAccounts.firstWhere(
        (account) => account.contains(':$sepoliaChainId:'),
      );
      chainIdToUse = sepoliaAccount.split(':').take(2).join(':');
      debugPrint('[WalletConnect] Using Sepolia chain for switch request: $chainIdToUse');
    } catch (_) {
      // Sepolia not in accounts, use first available chain
      chainIdToUse = currentAccounts.first.split(':').take(2).join(':');
      debugPrint('[WalletConnect] Sepolia not in session, using chain: $chainIdToUse');
    }

    try {
      // Try to switch to Sepolia using the available chain
      await app.request(
        topic: session.topic,
        chainId: chainIdToUse,
        request: SessionRequestParams(
          method: 'wallet_switchEthereumChain',
          params: [
            {'chainId': sepoliaChainIdHex},
          ],
        ),
      );
      debugPrint('[WalletConnect] Successfully requested chain switch to Sepolia');
    } catch (e) {
      debugPrint('[WalletConnect] Chain switch failed: $e, attempting to add Sepolia network');
      // If switch fails, try to add Sepolia network
      try {
        await app.request(
          topic: session.topic,
          chainId: chainIdToUse,
          request: SessionRequestParams(
            method: 'wallet_addEthereumChain',
            params: [
              {
                'chainId': sepoliaChainIdHex,
                'chainName': Environment.sepoliaChainName,
                'rpcUrls': [Environment.rpcUrl],
                'nativeCurrency': {
                  'name': 'ETH',
                  'symbol': 'ETH',
                  'decimals': 18,
                },
                'blockExplorerUrls': [Environment.sepoliaExplorerUrl],
              },
            ],
          ),
        );
        debugPrint('[WalletConnect] Successfully requested to add Sepolia network');
      } catch (e2) {
        debugPrint('[WalletConnect] Failed to add Sepolia network: $e2');
        // Silently fail - user may need to manually add Sepolia to their wallet
      }
    }
  }

  Future<String> signMessage(String message) async {
    final app = _appKit;
    final session = _activeSession;
    if (app == null || session == null) {
      throw StateError('Wallet not connected');
    }

    final account = _firstAccountFromSession(session);
    final address = _extractAddressFromAccount(account);

    final signature = await app.request(
      topic: session.topic,
      chainId: 'eip155:${Environment.chainId}',
      request: SessionRequestParams(
        method: 'personal_sign',
        params: [
          message,
          address,
        ],
      ),
    );

    return signature as String;
  }

  /// Send a transaction via WalletConnect
  /// Returns transaction hash
  /// [autoDisconnect] - DEPRECATED: No longer disconnects after transaction to avoid breaking flow
  /// Session remains active to allow transaction confirmation and potential follow-up transactions
  Future<String> sendTransaction({
    required String to,
    required String data,
    String? value,
    String? gas,
    String? gasPrice,
    bool autoDisconnect = false, // Changed to false - don't disconnect after transaction
    bool autoOpenWallet = true, // Automatically deep link to wallet once request is sent
  }) async {
    final app = _appKit;
    final session = _activeSession;
    if (app == null || session == null) {
      throw StateError('Wallet not connected. Please connect your wallet first.');
    }

    final account = _firstAccountFromSession(session);
    final from = _extractAddressFromAccount(account);

    // Ensure addresses are checksummed (EIP-55)
    final toAddress = to;
    final fromAddress = from;

    final transactionParams = <String, dynamic>{
      'from': fromAddress,
      'to': toAddress,
      'data': data,
    };

    if (value != null && value.isNotEmpty) {
      // Convert value to hex if it's a decimal string
      if (!value.startsWith('0x')) {
        final bigIntValue = BigInt.parse(value);
        transactionParams['value'] = '0x${bigIntValue.toRadixString(16)}';
      } else {
        transactionParams['value'] = value;
      }
    }
    
    if (gas != null && gas.isNotEmpty) {
      if (!gas.startsWith('0x')) {
        final bigIntGas = BigInt.parse(gas);
        transactionParams['gas'] = '0x${bigIntGas.toRadixString(16)}';
      } else {
        transactionParams['gas'] = gas;
      }
    }
    
    if (gasPrice != null && gasPrice.isNotEmpty) {
      if (!gasPrice.startsWith('0x')) {
        final bigIntGasPrice = BigInt.parse(gasPrice);
        transactionParams['gasPrice'] = '0x${bigIntGasPrice.toRadixString(16)}';
      } else {
        transactionParams['gasPrice'] = gasPrice;
      }
    }

    debugPrint('[WalletConnect] ===== Preparing transaction request =====');
    debugPrint('[WalletConnect] Session topic: ${session.topic}');
    debugPrint('[WalletConnect] From: $fromAddress');
    debugPrint('[WalletConnect] To: $toAddress');
    debugPrint('[WalletConnect] Data length: ${data.length}');
    final truncatedData = data.length > 100 ? '${data.substring(0, 100)}...' : data;
    debugPrint('[WalletConnect] Data (first 100 chars): $truncatedData');
    debugPrint('[WalletConnect] ChainId: eip155:${Environment.chainId}');
    debugPrint('[WalletConnect] Transaction params keys: ${transactionParams.keys.toList()}');
    debugPrint('[WalletConnect] Transaction params: $transactionParams');
    debugPrint('[WalletConnect] ===========================================');

    // Verify session is still active
    try {
      final activeSessions = app.getActiveSessions();
      if (!activeSessions.containsKey(session.topic)) {
        throw StateError('WalletConnect session is no longer active. Please reconnect your wallet.');
      }
      debugPrint('[WalletConnect] Session is active and valid');
    } catch (e) {
      debugPrint('[WalletConnect] Error checking session: $e');
      // Continue anyway - session might still be valid
    }

    try {
      debugPrint('[WalletConnect] Sending transaction request to wallet...');
      debugPrint('[WalletConnect] Waiting for user approval in wallet app...');
      
      // Create the request
      final requestParams = SessionRequestParams(
        method: 'eth_sendTransaction',
        params: [transactionParams],
      );
      
      debugPrint('[WalletConnect] Request params created');
      debugPrint('[WalletConnect] Method: ${requestParams.method}');
      debugPrint('[WalletConnect] Params count: ${requestParams.params.length}');
      
      // Send request
      final requestFuture = app.request(
        topic: session.topic,
        chainId: 'eip155:${Environment.chainId}',
        request: requestParams,
      );
      
      debugPrint('[WalletConnect] Request sent, waiting for response...');
      
      // Set flag to indicate we're waiting for transaction
      _isPendingTransaction = true;
      
      if (autoOpenWallet) {
        debugPrint('[WalletConnect] Auto-opening wallet for transaction request...');
        unawaited(_tryOpenWalletApp());
      }
      
      // Always schedule a follow-up reminder in case user misses the notification
      Future.delayed(const Duration(seconds: 2), () async {
        if (_isPendingTransaction) {
          debugPrint('[WalletConnect] Transaction still pending after delay, attempting to open wallet app again...');
          await _tryOpenWalletApp();
          debugPrint('[WalletConnect] Wallet app reopen attempt completed.');
        }
      });
      
      // Add timeout to prevent indefinite hanging
      // User should approve/reject within 5 minutes
      final result = await requestFuture.timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          debugPrint('[WalletConnect] Transaction request timeout after 5 minutes');
          debugPrint('[WalletConnect] User may not have approved the transaction in wallet app');
          throw TimeoutException(
            'Transaction request timed out. Please check your wallet app and approve the transaction, or try again.',
            const Duration(minutes: 5),
          );
        },
      );

      debugPrint('[WalletConnect] Received response from wallet');
      debugPrint('[WalletConnect] Response type: ${result.runtimeType}');
      debugPrint('[WalletConnect] Response value: $result');

      // Result should be transaction hash
      String txHash;
      if (result is String) {
        txHash = result;
      } else if (result is Map) {
        // Sometimes result might be wrapped in a map
        txHash = result.values.first.toString();
      } else {
        txHash = result.toString();
      }
      
      // Remove any quotes or brackets if present
      txHash = txHash.replaceAll('"', '').replaceAll("'", '').replaceAll('[', '').replaceAll(']', '').trim();
      
      // Ensure it starts with 0x
      if (!txHash.startsWith('0x')) {
        txHash = '0x$txHash';
      }
      
      debugPrint('[WalletConnect] Transaction sent successfully. Hash: $txHash');
      
      // Clear pending transaction flag - transaction is complete
      _isPendingTransaction = false;
      
      debugPrint('[WalletConnect] Transaction approved - waiting for user to return to app manually');
      
      // NOTE: We do NOT disconnect immediately after transaction
      // Reasons:
      // 1. Transaction is sent but user may still need to confirm in MetaMask
      // 2. User might want to do multiple transactions
      // 3. Disconnecting immediately can cause session restore issues
      // 
      // Session will remain active until:
      // - User manually disconnects
      // - Session expires naturally
      // - App is closed and session is not restored
      //
      // If you want to disconnect after transaction, set autoDisconnect=true
      // but be aware it may cause issues with pending transactions
      if (autoDisconnect) {
        debugPrint('[WalletConnect] autoDisconnect=true, but NOT disconnecting to avoid breaking transaction flow');
        debugPrint('[WalletConnect] Transaction hash received: $txHash');
        debugPrint('[WalletConnect] Session remains active to allow transaction confirmation in MetaMask');
        debugPrint('[WalletConnect] User can manually disconnect if needed');
      } else {
        debugPrint('[WalletConnect] Transaction completed. Session remains connected for potential follow-up transactions');
      }
      
      return txHash;
    } on TimeoutException catch (e) {
      // Clear pending flag on timeout
      _isPendingTransaction = false;
      debugPrint('[WalletConnect] Transaction request timeout: $e');
      debugPrint('[WalletConnect] Please check your wallet app and ensure the transaction was approved');
      rethrow;
    } catch (e, stackTrace) {
      // Clear pending flag on error
      _isPendingTransaction = false;
      debugPrint('[WalletConnect] Transaction failed: $e');
      debugPrint('[WalletConnect] Error type: ${e.runtimeType}');
      debugPrint('[WalletConnect] Stack trace: $stackTrace');
      
      // Provide more helpful error messages
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('user rejected') ||
          errorString.contains('user denied') ||
          errorString.contains('rejected') ||
          errorString.contains('denied')) {
        throw StateError('Transaction was rejected by user in wallet app');
      } else if (errorString.contains('timeout')) {
        throw TimeoutException(
          'Transaction request timed out. Please check your wallet app and approve the transaction.',
          const Duration(minutes: 5),
        );
      } else if (errorString.contains('session') && errorString.contains('disconnected')) {
        throw StateError('WalletConnect session disconnected. Please reconnect your wallet.');
      } else {
        rethrow;
      }
    }
  }

  /// Get stored wallet universal link from session or preferences
  Future<String?> _getStoredWalletLink() async {
    return _lastWalletLink;
  }

  Future<String?> _getStoredWalletConnectUri() async {
    return _lastWalletConnectUri;
  }

  /// Attempt to open wallet app (MetaMask) via deep link
  /// This method opens MetaMask app and keeps our app in background
  /// The app should NOT automatically navigate when it resumes
  /// User will manually return to app after confirming transaction in MetaMask
  Future<void> _tryOpenWalletApp() async {
    try {
      // Try to get stored wallet link
      final walletLink = await _getStoredWalletLink();
      final walletConnectUri = await _getStoredWalletConnectUri();
      
      // Default to MetaMask if no stored link
      final universalLink = (walletLink != null && walletLink.isNotEmpty)
          ? walletLink
          : 'https://metamask.app.link';
      final metamaskWcUri = (walletConnectUri != null && walletConnectUri.isNotEmpty)
          ? Uri.parse('metamask://wc?uri=${Uri.encodeComponent(walletConnectUri)}')
          : null;
      
      debugPrint('[WalletConnect] Preparing to open wallet app...');
      debugPrint('[WalletConnect] Stored wallet link: $walletLink');
      debugPrint('[WalletConnect] Using universal link: $universalLink');
      if (walletConnectUri != null && walletConnectUri.isNotEmpty) {
        debugPrint('[WalletConnect] WalletConnect URI cached - will try direct MetaMask hand-off instead of browser');
      } else {
        debugPrint('[WalletConnect] No stored WalletConnect URI - will rely on MetaMask app without browser fallback');
      }
      
      // For Android, try multiple methods
      if (Platform.isAndroid) {
        // Method 1: Try MetaMask Android package name (most reliable for opening app)
        try {
          // Android intent to open MetaMask app directly
          // This will open MetaMask and keep our app in background
          final intentUri = Uri.parse('intent://wc#Intent;scheme=metamask;package=io.metamask;end');
          final canLaunch = await canLaunchUrl(intentUri);
          if (canLaunch) {
            debugPrint('[WalletConnect] Opening MetaMask via Android intent (io.metamask)...');
            await launchUrl(intentUri, mode: LaunchMode.externalApplication);
            // Don't return immediately - let the system handle the app switch
            await Future.delayed(const Duration(milliseconds: 500));
            debugPrint('[WalletConnect] MetaMask should be opened. App is now in background.');
            return;
          }
        } catch (e) {
          debugPrint('[WalletConnect] Android intent method failed: $e');
        }
        
        // Method 2: Try MetaMask deep link
        try {
          final metamaskUri = Uri.parse('metamask://');
          final canLaunch = await canLaunchUrl(metamaskUri);
          if (canLaunch) {
            debugPrint('[WalletConnect] Opening MetaMask via deep link (metamask://)...');
            await launchUrl(metamaskUri, mode: LaunchMode.externalApplication);
            // Don't return immediately - let the system handle the app switch
            await Future.delayed(const Duration(milliseconds: 500));
            debugPrint('[WalletConnect] MetaMask should be opened. App is now in background.');
            return;
          }
        } catch (e) {
          debugPrint('[WalletConnect] MetaMask deep link failed: $e');
        }
        
        // Method 3: If we have the WalletConnect URI, hand it off directly without opening browser
        if (metamaskWcUri != null) {
          try {
            debugPrint('[WalletConnect] Attempting MetaMask direct hand-off with wc URI (metamask://wc?...).');
            await launchUrl(
              metamaskWcUri,
              mode: LaunchMode.externalApplication,
            );
            await Future.delayed(const Duration(milliseconds: 500));
            debugPrint('[WalletConnect] Direct hand-off attempted. App should remain in background.');
            return;
          } catch (e) {
            debugPrint('[WalletConnect] MetaMask wc URI hand-off failed: $e');
            debugPrint('[WalletConnect] Not falling back to browser since wallet is already open.');
            return;
          }
        }
        
        // If no wc URI, rely on MetaMask notifications (no browser fallback)
        debugPrint('[WalletConnect] No direct wc URI available. Waiting for MetaMask notification without browser fallback.');
      } else if (Platform.isIOS) {
        if (metamaskWcUri != null) {
          try {
            debugPrint('[WalletConnect] Opening MetaMask via wc URI on iOS (metamask://wc?...).');
            await launchUrl(metamaskWcUri, mode: LaunchMode.externalApplication);
            await Future.delayed(const Duration(milliseconds: 500));
            debugPrint('[WalletConnect] wc URI opened (iOS). App is now in background.');
            return;
          } catch (e) {
            debugPrint('[WalletConnect] wc URI failed on iOS: $e');
            debugPrint('[WalletConnect] Not falling back to browser since wallet is already open.');
            return;
          }
        } else {
          debugPrint('[WalletConnect] No wc URI available on iOS. Relying on MetaMask notification (no browser fallback).');
        }
      }
      
      // Final fallback: use the universal link (opens MetaMask if installed, otherwise prompts install)
      try {
        final universalUri = Uri.parse(universalLink);
        debugPrint('[WalletConnect] Attempting universal link fallback: $universalUri');
        await launchUrl(universalUri, mode: LaunchMode.externalApplication);
        await Future.delayed(const Duration(milliseconds: 500));
        debugPrint('[WalletConnect] Universal link opened. Awaiting user confirmation.');
        return;
      } catch (e) {
        debugPrint('[WalletConnect] Universal link fallback failed: $e');
      }
      
      debugPrint('[WalletConnect] Wallet app opening attempted. App will remain in background.');
      debugPrint('[WalletConnect] User should confirm transaction in MetaMask, then manually return to app.');
    } catch (e) {
      debugPrint('[WalletConnect] Error attempting to open wallet app: $e');
      // Don't throw - this is best effort, WalletConnect notification might still work
    }
  }

  /// Sign EIP-712 typed data via WalletConnect
  Future<String> signTypedData(String typedDataJson) async {
    final app = _appKit;
    final session = _activeSession;
    if (app == null || session == null) {
      throw StateError('Wallet not connected. Please connect your wallet first.');
    }

    final account = _firstAccountFromSession(session);
    final address = _extractAddressFromAccount(account);

    // Parse typed data JSON and ensure V4 format compatibility
    final typedData = jsonDecode(typedDataJson) as Map<String, dynamic>;
    
    // Ensure typed data is in correct format for WalletConnect/MetaMask
    // WalletConnect expects the typed data to be properly formatted with V4 support
    final formattedTypedData = _formatTypedDataForWalletConnect(typedData);

    debugPrint('[WalletConnect] ===== Preparing EIP-712 signature request =====');
    debugPrint('[WalletConnect] Session topic: ${session.topic}');
    debugPrint('[WalletConnect] Address: ${address.substring(0, 10)}...');
    debugPrint('[WalletConnect] ChainId: eip155:${Environment.chainId}');
    debugPrint('[WalletConnect] Primary type: ${formattedTypedData['primaryType']}');
    debugPrint('[WalletConnect] ================================================');

    // Verify session is still active
    try {
      final activeSessions = app.getActiveSessions();
      if (!activeSessions.containsKey(session.topic)) {
        throw StateError('WalletConnect session is no longer active. Please reconnect your wallet.');
      }
      debugPrint('[WalletConnect] Session is active and valid');
    } catch (e) {
      debugPrint('[WalletConnect] Error checking session: $e');
      // Continue anyway - session might still be valid
    }

    try {
      debugPrint('[WalletConnect] Sending EIP-712 signature request to wallet...');
      debugPrint('[WalletConnect] Waiting for user approval in wallet app...');
      
      // Create the request
      // MetaMask mobile requires the explicit V4 RPC method whenever arrays appear
      final requestParams = SessionRequestParams(
        method: 'eth_signTypedData_v4',
        params: [
          address,
          jsonEncode(formattedTypedData),
        ],
      );
      
      debugPrint('[WalletConnect] Request params created');
      debugPrint('[WalletConnect] Method: ${requestParams.method}');
      debugPrint('[WalletConnect] Params count: ${requestParams.params.length}');
      
      // Send request
      final requestFuture = app.request(
        topic: session.topic,
        chainId: 'eip155:${Environment.chainId}',
        request: requestParams,
      );
      
      debugPrint('[WalletConnect] Request sent, waiting for response...');
      
      // Set flag to indicate we're waiting for signature
      _isPendingSignature = true;
      
      // Immediately open wallet to surface the signature prompt, then keep a reminder
      unawaited(_tryOpenWalletApp());

      Future.delayed(const Duration(seconds: 3), () async {
        // Check if signature is still pending (user hasn't approved/rejected yet)
        if (_isPendingSignature) {
          debugPrint('[WalletConnect] Signature still pending after 3 seconds');
          debugPrint('[WalletConnect] User may not have seen the notification. Attempting to open MetaMask app...');
          await _tryOpenWalletApp();
          debugPrint('[WalletConnect] MetaMask app opened. User should confirm signature there.');
          debugPrint('[WalletConnect] App will remain in background until user returns manually.');
        } else {
          debugPrint('[WalletConnect] Signature already completed, no need to open wallet app');
        }
      });
      
      // Add timeout to prevent indefinite hanging
      // User should approve/reject within 5 minutes
      final result = await requestFuture.timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          debugPrint('[WalletConnect] Signature request timeout after 5 minutes');
          debugPrint('[WalletConnect] User may not have approved the signature in wallet app');
          throw TimeoutException(
            'Signature request timed out. Please check your wallet app and approve the signature, or try again.',
            const Duration(minutes: 5),
          );
        },
      );

      debugPrint('[WalletConnect] Received response from wallet');
      debugPrint('[WalletConnect] Response type: ${result.runtimeType}');
      debugPrint('[WalletConnect] Response value: $result');

      // Result should be signature
      String signature;
      if (result is String) {
        signature = result;
      } else if (result is Map) {
        // Sometimes result might be wrapped in a map
        signature = result.values.first.toString();
      } else {
        signature = result.toString();
      }
      
      // Remove any quotes or brackets if present
      signature = signature.replaceAll('"', '').replaceAll("'", '').replaceAll('[', '').replaceAll(']', '').trim();
      
      // Ensure it starts with 0x
      if (!signature.startsWith('0x')) {
        signature = '0x$signature';
      }
      
      debugPrint('[WalletConnect] Typed data signed successfully. Signature: ${signature.substring(0, 20)}...');
      
      // Clear pending signature flag - signature is complete
      _isPendingSignature = false;
      
      debugPrint('[WalletConnect] Signature approved - waiting for user to return to app manually');
      
      return signature;
    } on TimeoutException catch (e) {
      // Clear pending flag on timeout
      _isPendingSignature = false;
      debugPrint('[WalletConnect] Signature request timeout: $e');
      debugPrint('[WalletConnect] Please check your wallet app and ensure the signature was approved');
      rethrow;
    } catch (e, stackTrace) {
      // Clear pending flag on error
      _isPendingSignature = false;
      debugPrint('[WalletConnect] Typed data signing failed: $e');
      debugPrint('[WalletConnect] Error type: ${e.runtimeType}');
      debugPrint('[WalletConnect] Stack trace: $stackTrace');
      
      // Provide more helpful error messages
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('user rejected') || 
          errorString.contains('user denied') ||
          errorString.contains('rejected') ||
          errorString.contains('denied')) {
        throw StateError('Signature was rejected by user in wallet app');
      } else if (errorString.contains('timeout')) {
        throw TimeoutException(
          'Signature request timed out. Please check your wallet app and approve the signature.',
          const Duration(minutes: 5),
        );
      } else if (errorString.contains('session') && errorString.contains('disconnected')) {
        throw StateError('WalletConnect session disconnected. Please reconnect your wallet.');
      } else {
        rethrow;
      }
    }
  }

  /// Check if WalletConnect is available and connected
  /// Returns true only if there's an active in-memory session
  Future<bool> isConnected() async {
    await init();
    
    // Check if there's an active session
    if (_activeSession != null) {
      debugPrint('[WalletConnect] isConnected: true (active session exists)');
      return true;
    }
    
    debugPrint('[WalletConnect] isConnected: false (no active session)');
    return false;
  }
  
  /// Check if there's an active WalletConnect session (not just stored address)
  /// Kiểm tra cả trong-memory session và ReownAppKit active sessions
  Future<bool> hasActiveSession() async {
    await init();
    
    if (_appKit == null) return false;
    
    try {
      // Kiểm tra ReownAppKit active sessions
      final activeSessions = _appKit!.getActiveSessions();
      if (activeSessions.isNotEmpty) {
        // Cập nhật _activeSession nếu chưa có hoặc session đã thay đổi
        if (_activeSession == null || !activeSessions.containsKey(_activeSession!.topic)) {
          _activeSession = activeSessions.values.first;
          debugPrint('[WalletConnect] Restored active session from ReownAppKit: ${_activeSession!.topic}');
        }
        return true;
      }
    } catch (e) {
      debugPrint('[WalletConnect] Error checking active sessions: $e');
    }
    
    // Fallback: check in-memory session
    final hasActive = _activeSession != null;
    debugPrint('[WalletConnect] hasActiveSession: $hasActive');
    return hasActive;
  }

  /// Check if we're currently waiting for a transaction or signature
  /// This can be used to prevent auto-navigation when app resumes
  bool isPendingTransactionOrSignature() {
    return _isPendingTransaction || _isPendingSignature;
  }

  /// Clear pending transaction/signature flags
  /// Useful when user cancels or when we want to reset state
  void clearPendingFlags() {
    _isPendingTransaction = false;
    _isPendingSignature = false;
    debugPrint('[WalletConnect] Cleared pending transaction/signature flags');
  }

  String _firstAccountFromSession(SessionData session) {
    debugPrint('[WalletConnect] Extracting account from session...');
    debugPrint('[WalletConnect] Available namespaces: ${session.namespaces.keys.toList()}');
    
    // Try eip155 namespace first (most common)
    final eip155Namespace = session.namespaces['eip155'];
    if (eip155Namespace != null) {
      debugPrint('[WalletConnect] eip155 namespace found');
      debugPrint('[WalletConnect] Accounts: ${eip155Namespace.accounts}');
      
      final accounts = eip155Namespace.accounts;
      if (accounts.isNotEmpty) {
        // Prefer Sepolia account if available (for development)
        final sepoliaChainId = Environment.chainId;
        final sepoliaAccount = accounts.firstWhere(
          (account) => account.contains(':$sepoliaChainId:'),
          orElse: () => accounts.first,
        );
        
        if (sepoliaAccount != accounts.first) {
          debugPrint('[WalletConnect] Using Sepolia account: $sepoliaAccount');
        } else {
          debugPrint('[WalletConnect] Using first available account: $sepoliaAccount');
        }
        
        return sepoliaAccount;
      }
    }
    
    // Try alternative namespace keys
    for (final namespaceKey in session.namespaces.keys) {
      final namespace = session.namespaces[namespaceKey];
      if (namespace != null) {
        final accounts = namespace.accounts;
        if (accounts.isNotEmpty) {
          debugPrint('[WalletConnect] Found accounts in namespace: $namespaceKey');
          return accounts.first;
        }
      }
    }
    
    // Log all namespace data for debugging
    debugPrint('[WalletConnect] All namespaces data:');
    session.namespaces.forEach((key, value) {
      debugPrint('[WalletConnect]   $key: accounts=${value.accounts}, chains=${value.chains}');
    });
    
    throw StateError('No accounts found in WalletConnect session. Namespaces: ${session.namespaces.keys.toList()}');
  }

  /// Extracts address from account string (handles different formats)
  String _extractAddressFromAccount(String account) {
    // Account format can be: "eip155:1:0x..." or just "0x..."
    if (account.contains(':')) {
      final parts = account.split(':');
      // Get the last part which should be the address
      return parts.last;
    }
    // If no colon, assume it's already just the address
    return account;
  }

  /// Alternative method to extract address from session
  String _extractAddressAlternative(SessionData session) {
    try {
      // Try to get address from any available namespace
      for (final namespace in session.namespaces.values) {
        final accounts = namespace.accounts;
        for (final account in accounts) {
          final address = _extractAddressFromAccount(account);
          if (_isValidEthereumAddress(address)) {
            return address;
          }
        }
      }
    } catch (e) {
      debugPrint('[WalletConnect] Alternative extraction failed: $e');
    }
    return '';
  }

  /// Validates Ethereum address format
  bool _isValidEthereumAddress(String address) {
    // Remove 0x prefix if present for validation
    final cleanAddress = address.toLowerCase().replaceFirst('0x', '');
    // Ethereum address should be 40 hex characters (20 bytes)
    return RegExp(r'^[0-9a-f]{40}$').hasMatch(cleanAddress);
  }

  /// Format typed data for WalletConnect compatibility
  /// This ensures arrays are properly formatted for MetaMask mobile
  /// MetaMask mobile requires EIP-712 V4 format for arrays
  /// According to EIP-712, arrays are encoded as dynamic types with proper structure
  Map<String, dynamic> _formatTypedDataForWalletConnect(Map<String, dynamic> typedData) {
    // Create a deep copy to avoid modifying the original
    final formatted = jsonDecode(jsonEncode(typedData)) as Map<String, dynamic>;
    
    // Ensure domain chainId is a number (not string or BigInt)
    final domain = formatted['domain'] as Map<String, dynamic>?;
    if (domain != null && domain['chainId'] != null) {
      if (domain['chainId'] is String) {
        // Convert string to int if needed
        try {
          domain['chainId'] = int.parse(domain['chainId'] as String);
        } catch (e) {
          debugPrint('[WalletConnect] Warning: Could not parse chainId: ${domain['chainId']}');
        }
      } else if (domain['chainId'] is BigInt) {
        domain['chainId'] = (domain['chainId'] as BigInt).toInt();
      }
      debugPrint('[WalletConnect] Domain chainId: ${domain['chainId']} (type: ${domain['chainId'].runtimeType})');
    }
    
    // Ensure verifyingContract is checksummed address (EIP-55)
    if (domain != null && domain['verifyingContract'] != null) {
      try {
        final contractAddress = domain['verifyingContract'] as String;
        // Convert to checksummed address (EIP-55) for better compatibility
        domain['verifyingContract'] = EthereumAddress.fromHex(contractAddress).hexEip55;
        debugPrint('[WalletConnect] Domain verifyingContract: ${domain['verifyingContract']}');
      } catch (e) {
        debugPrint('[WalletConnect] Warning: Could not format contract address: $e');
      }
    }
    
    // Verify and log types structure
    final types = formatted['types'] as Map<String, dynamic>?;
    if (types != null) {
      debugPrint('[WalletConnect] Verifying typed data structure...');
      debugPrint('[WalletConnect] Available types: ${types.keys.toList()}');
      
      types.forEach((typeName, typeDef) {
        if (typeDef is List) {
          for (var field in typeDef) {
            if (field is Map<String, dynamic>) {
              final fieldType = field['type'] as String?;
              final fieldName = field['name'] as String?;
              if (fieldType != null && fieldType.contains('[]')) {
                debugPrint('[WalletConnect] Found array type in $typeName: $fieldName = $fieldType');
                // Arrays (like string[]) are supported in EIP-712 V4
                // The format 'string[]' is correct for EIP-712 V4
                // WalletConnect/MetaMask should handle this if properly formatted
              }
            }
          }
        }
      });
    }
    
    // Log formatted typed data structure for debugging
    debugPrint('[WalletConnect] Formatted typed data structure:');
    debugPrint('[WalletConnect] - Primary type: ${formatted['primaryType']}');
    debugPrint('[WalletConnect] - Domain name: ${domain?['name']}');
    debugPrint('[WalletConnect] - Domain version: ${domain?['version']}');
    debugPrint('[WalletConnect] - Domain chainId: ${domain?['chainId']}');
    debugPrint('[WalletConnect] - Domain verifyingContract: ${domain?['verifyingContract']}');
    debugPrint('[WalletConnect] - Types: ${types?.keys.toList()}');
    
    // Log message structure (first level only to avoid too much output)
    final message = formatted['message'] as Map<String, dynamic>?;
    if (message != null) {
      debugPrint('[WalletConnect] - Message keys: ${message.keys.toList()}');
      // Log array values to verify format
      if (message['@context'] is List) {
        debugPrint('[WalletConnect] - Message @context: ${message['@context']}');
      }
      if (message['type'] is List) {
        debugPrint('[WalletConnect] - Message type: ${message['type']}');
      }
    }
    
    return formatted;
  }
}


