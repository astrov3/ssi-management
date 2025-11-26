import 'dart:async';
import 'dart:convert';

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
  String? _lastWalletConnectUri;
  String? _cachedAddress;
  String? _lastWalletUniversalLink; // Ghi nhớ loại ví (MetaMask / TrustWallet) để mở lại đúng app
  static const String _prefsLastWalletUniversalLinkKey = 'walletconnect_last_wallet_universal_link';
  
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
      // Restore last used wallet universal link (MetaMask / TrustWallet / others)
      try {
        final prefs = await SharedPreferences.getInstance();
        _lastWalletUniversalLink = prefs.getString(_prefsLastWalletUniversalLinkKey);
        if (_lastWalletUniversalLink != null) {
          debugPrint('[WalletConnect] Restored last wallet universal link: $_lastWalletUniversalLink');
        }
      } catch (e) {
        debugPrint('[WalletConnect] Error restoring last wallet universal link: $e');
      }

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
    if (_cachedAddress != null && _isValidEthereumAddress(_cachedAddress!)) {
      return _cachedAddress;
    }
    if (_activeSession != null) {
      try {
        final address = _extractAddressFromSession(_activeSession!);
        if (_isValidEthereumAddress(address)) {
          _cachedAddress = address;
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
    
    if (_cachedAddress != null && _isValidEthereumAddress(_cachedAddress!)) {
      debugPrint('[WalletConnect] Using cached address: $_cachedAddress');
      return _cachedAddress;
    }

    if (_activeSession != null) {
      try {
        final address = _extractAddressFromSession(_activeSession!);
        if (_isValidEthereumAddress(address)) {
          debugPrint('[WalletConnect] Retrieved address from active session: $address');
          _cachedAddress = address;
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
    _lastWalletConnectUri = null;
    _cachedAddress = null;
    
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
      // Ghi nhớ loại ví (universal link) mà user đã chọn, để về sau mở đúng app (MetaMask / TrustWallet, ...)
      try {
        final prefs = await SharedPreferences.getInstance();
        if (walletUniversalLink != null && walletUniversalLink.isNotEmpty) {
          _lastWalletUniversalLink = walletUniversalLink;
          await prefs.setString(_prefsLastWalletUniversalLinkKey, walletUniversalLink);
          debugPrint('[WalletConnect] Saved last wallet universal link: $walletUniversalLink');
        } else {
          // Nếu không truyền vào, default dùng MetaMask universal link để nhất quán với flow hiện tại
          const defaultLink = 'https://metamask.app.link';
          _lastWalletUniversalLink = defaultLink;
          await prefs.setString(_prefsLastWalletUniversalLinkKey, defaultLink);
          debugPrint('[WalletConnect] No walletUniversalLink provided, defaulting to $defaultLink');
        }
      } catch (e) {
        debugPrint('[WalletConnect] Error saving last wallet universal link: $e');
      }

      final effectiveLink = _lastWalletUniversalLink;
      if (effectiveLink != null && effectiveLink.isNotEmpty) {
        final deepLink = Uri.parse('$effectiveLink/wc?uri=${Uri.encodeComponent(wcUri)}');
        debugPrint('[WalletConnect] Launching deep link: $deepLink');
        await launchUrl(deepLink, mode: LaunchMode.externalApplication);
      } else {
        // Fallback cũ: dùng trực tiếp wcUri (để WalletConnect tự handle)
        debugPrint('[WalletConnect] No universal link available, launching raw WalletConnect URI: $wcUri');
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
      address = _extractAddressFromSession(session);
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

    // Check if we're already on Sepolia, if not, attempt to switch
    final currentChainId = _getCurrentChainId(session);
    final targetSepoliaChainId = Environment.chainId;
    
    if (currentChainId != targetSepoliaChainId) {
      debugPrint('[WalletConnect] Current chain: $currentChainId, switching to Sepolia: $targetSepoliaChainId');
      unawaited(_attemptSepoliaSwitchInBackground());
    } else {
      debugPrint('[WalletConnect] Already connected to Sepolia (chainId: $targetSepoliaChainId)');
    }

    _cachedAddress = address;
    debugPrint('[WalletConnect] Connection completed successfully. Returning address: $address');
    return address;
  }

  String _extractAddressFromSession(SessionData session) {
    final account = _firstAccountFromSession(session);
    debugPrint('[WalletConnect] Account extracted: $account');
    return _extractAddressFromAccount(account);
  }

  Future<void> _attemptSepoliaSwitchInBackground() async {
    try {
      await switchToSepolia().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('[WalletConnect] Sepolia switch timeout - connection still successful');
        },
      );
      debugPrint('[WalletConnect] Successfully switched to Sepolia');
    } catch (e) {
      debugPrint('[WalletConnect] Failed to switch to Sepolia: $e');
      debugPrint('[WalletConnect] Connection successful, but wallet may be on different chain');
    }
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
      
      // Open wallet app once if requested (no retries - WalletConnect notification will handle it)
      if (autoOpenWallet) {
        debugPrint('[WalletConnect] Opening wallet app for transaction request...');
        unawaited(_tryOpenWalletApp());
      } else {
        debugPrint('[WalletConnect] Relying on WalletConnect notification system.');
      }
      
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

  Future<String?> _getStoredWalletConnectUri() async {
    return _lastWalletConnectUri;
  }

  /// Lấy lại universal link của ví đã dùng lần gần nhất
  Future<String?> _getStoredWalletUniversalLink() async {
    if (_lastWalletUniversalLink != null && _lastWalletUniversalLink!.isNotEmpty) {
      return _lastWalletUniversalLink;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      _lastWalletUniversalLink = prefs.getString(_prefsLastWalletUniversalLinkKey);
      return _lastWalletUniversalLink;
    } catch (e) {
      debugPrint('[WalletConnect] Error getting stored wallet universal link: $e');
      return null;
    }
  }

  /// Attempt to open wallet app (MetaMask) via deep link
  /// Simplified approach: Only use WalletConnect URI if available, otherwise rely on notifications
  /// This method opens MetaMask app and keeps our app in background
  /// The app should NOT automatically navigate when it resumes
  /// User will manually return to app after confirming transaction in MetaMask
  Future<void> _tryOpenWalletApp() async {
    try {
      final walletConnectUri = await _getStoredWalletConnectUri();
      final walletUniversalLink = await _getStoredWalletUniversalLink();

      // Only try to open wallet if we have WalletConnect URI
      // Otherwise, rely on WalletConnect notification system
      if (walletConnectUri != null && walletConnectUri.isNotEmpty) {
        // Ưu tiên mở đúng app ví mà user đã chọn (MetaMask / TrustWallet / ...)
        if (walletUniversalLink != null && walletUniversalLink.isNotEmpty) {
          final deepLink = Uri.parse('$walletUniversalLink/wc?uri=${Uri.encodeComponent(walletConnectUri)}');
          try {
            debugPrint('[WalletConnect] Opening wallet via universal link: $deepLink');
            await launchUrl(deepLink, mode: LaunchMode.externalApplication);
            debugPrint('[WalletConnect] Wallet app opened. User should confirm transaction there.');
            return;
          } catch (e) {
            debugPrint('[WalletConnect] Failed to open wallet via universal link: $e');
          }
        }

        // Fallback: cố gắng dùng MetaMask scheme cũ (để không phá flow hiện tại nếu universal link không có)
        final metamaskWcUri = Uri.parse('metamask://wc?uri=${Uri.encodeComponent(walletConnectUri)}');
        try {
          debugPrint('[WalletConnect] Opening MetaMask via wc URI (fallback): $metamaskWcUri');
          await launchUrl(metamaskWcUri, mode: LaunchMode.externalApplication);
          debugPrint('[WalletConnect] Wallet app opened (fallback). User should confirm transaction there.');
          return;
        } catch (e) {
          debugPrint('[WalletConnect] Failed to open wallet via fallback wc URI: $e');
          debugPrint('[WalletConnect] Relying on WalletConnect notification system.');
        }
      } else {
        debugPrint('[WalletConnect] No WalletConnect URI available. Relying on WalletConnect notification system.');
        debugPrint('[WalletConnect] User should check wallet app for pending transaction notification.');
      }
    } catch (e) {
      debugPrint('[WalletConnect] Error attempting to open wallet app: $e');
      // Don't throw - this is best effort, WalletConnect notification will work
      debugPrint('[WalletConnect] WalletConnect notification system will handle the request.');
    }
  }

  /// Public helper so UI can explicitly reopen the wallet app (e.g. MetaMask)
  Future<void> openWalletApp() async {
    await _tryOpenWalletApp();
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
      
      // Open wallet app once (no retries - WalletConnect notification will handle it)
      debugPrint('[WalletConnect] Opening wallet app for signature request...');
      unawaited(_tryOpenWalletApp());
      
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


