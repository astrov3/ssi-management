import 'package:flutter/foundation.dart';

import 'package:ssi_app/services/web3/web3_service.dart';
import 'package:ssi_app/services/wallet/wallet_connect_service.dart';
import 'package:ssi_app/services/wallet/wallet_name_service.dart';

/// Aggregated, ready-to-use wallet state for the UI.
class WalletState {
  const WalletState({
    required this.address,
    required this.displayName,
    required this.didData,
    required this.vcs,
    required this.verificationRequests,
    required this.canIssueVc,
    required this.canRevokeVc,
    required this.isTrustedVerifier,
    required this.isUsingWalletConnect,
  });

  /// Current wallet address (either private key wallet or WalletConnect).
  final String address;

  /// Friendly name for the wallet (from [WalletNameService]) or shortened address.
  final String displayName;

  /// DID information for this address (may be null if not registered).
  final Map<String, dynamic>? didData;

  /// All credentials (VCs) for this address.
  final List<Map<String, dynamic>> vcs;

  /// All verification requests (optionally filtered to pending only by the loader).
  final List<Map<String, dynamic>> verificationRequests;

  /// Whether this address can issue VC for its orgID.
  final bool canIssueVc;

  /// Whether this address can revoke VC for its orgID.
  final bool canRevokeVc;

  /// Whether this address is a trusted verifier.
  final bool isTrustedVerifier;

  /// True if this wallet is currently using WalletConnect (no private key).
  final bool isUsingWalletConnect;
}

/// Central place to load & cache wallet-related state.
///
/// - Uses in-memory cache so navigating giữa các màn không phải gọi lại RPC quá nhiều.
/// - Vẫn đảm bảo dữ liệu mới bằng cách:
///   - Tự động refresh nếu cache quá cũ (TTL),
///   - Hoặc khi caller truyền [forceRefresh] = true (ví dụ sau khi issue/revoke VC).
class WalletStateManager {
  WalletStateManager._internal();
  static final WalletStateManager _instance = WalletStateManager._internal();
  factory WalletStateManager() => _instance;

  final Web3Service _web3Service = Web3Service();
  final WalletConnectService _walletConnectService = WalletConnectService();
  final WalletNameService _walletNameService = WalletNameService();

  WalletState? _cache;
  DateTime? _lastUpdated;

  /// Thời gian tối đa giữ cache trước khi tự refresh.
  /// Có thể điều chỉnh nếu cần (mặc định 30 giây).
  Duration cacheTtl = const Duration(seconds: 30);

  /// Load (và cache) toàn bộ thông tin ví hiện tại.
  ///
  /// - Trả về null nếu chưa có ví (chưa import hoặc chưa connect WalletConnect).
  /// - Nếu [forceRefresh] = false và cache còn mới → dùng cache.
  /// - Nếu [forceRefresh] = true hoặc cache hết hạn → gọi lại RPC để lấy dữ liệu mới nhất.
  Future<WalletState?> loadWalletState({bool forceRefresh = false}) async {
    final now = DateTime.now();

    // 1. Lấy địa chỉ hiện tại từ Web3Service (ưu tiên private key, fallback WalletConnect).
    final address = await _web3Service.getCurrentAddress();
    if (address == null || address.isEmpty) {
      _cache = null;
      _lastUpdated = null;
      return null;
    }

    // 2. Nếu cache cùng địa chỉ và chưa quá hạn, dùng lại.
    final isCacheValid = !forceRefresh &&
        _cache != null &&
        _cache!.address.toLowerCase() == address.toLowerCase() &&
        _lastUpdated != null &&
        now.difference(_lastUpdated!) < cacheTtl;

    if (isCacheValid) {
      debugPrint('[WalletStateManager] Using cached wallet state for $address');
      return _cache;
    }

    debugPrint('[WalletStateManager] Refreshing wallet state for $address (forceRefresh=$forceRefresh)');

    // 3. Tải dữ liệu song song tối đa có thể.
    // DID, VCs, verification requests, quyền, tên ví, tình trạng WalletConnect.
    final futures = await Future.wait<dynamic>([
      _web3Service.getDID(address), // 0
      _web3Service.getVCs(address), // 1
      _web3Service.getAllVerificationRequests(), // 2
      _web3Service.isAuthorizedIssuer(address, address), // 3: canIssue
      _web3Service.isAuthorizedIssuer(address, address), // 4: canRevoke (same logic, tách nếu khác rule)
      _web3Service.isTrustedVerifier(address), // 5
      _walletNameService.getDisplayName(address), // 6
      _walletConnectService.hasActiveSession(), // 7
    ]);

    final didData = futures[0] as Map<String, dynamic>?;
    final vcs = (futures[1] as List).cast<Map<String, dynamic>>();
    final verificationRequests = (futures[2] as List).cast<Map<String, dynamic>>();
    final canIssueVc = futures[3] as bool? ?? false;
    final canRevokeVc = futures[4] as bool? ?? false;
    final isTrustedVerifier = futures[5] as bool? ?? false;
    final displayName = futures[6] as String? ?? address;
    final isUsingWalletConnect = futures[7] as bool? ?? false;

    final state = WalletState(
      address: address,
      displayName: displayName,
      didData: didData,
      vcs: vcs,
      verificationRequests: verificationRequests,
      canIssueVc: canIssueVc,
      canRevokeVc: canRevokeVc,
      isTrustedVerifier: isTrustedVerifier,
      isUsingWalletConnect: isUsingWalletConnect,
    );

    _cache = state;
    _lastUpdated = now;

    return state;
  }

  /// Xoá cache (ví dụ sau khi logout hoặc clearWalletData).
  void clearCache() {
    _cache = null;
    _lastUpdated = null;
    debugPrint('[WalletStateManager] Wallet state cache cleared');
  }
}


