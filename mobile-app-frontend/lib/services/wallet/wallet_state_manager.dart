import 'package:flutter/foundation.dart';

import 'package:ssi_app/services/role/role_context_provider.dart';
import 'package:ssi_app/services/web3/web3_service.dart';
import 'package:ssi_app/services/wallet/wallet_connect_service.dart';
import 'package:ssi_app/services/wallet/wallet_name_service.dart';

/// Aggregated, ready-to-use wallet state for the UI.
class WalletState {
  const WalletState({
    required this.address,
    required this.orgId,
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

  /// The orgID (DID identifier) currently being inspected.
  final String orgId;

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
  final RoleContextProvider _roleContextProvider = RoleContextProvider();

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
  Future<WalletState?> loadWalletState({bool forceRefresh = false, String? orgId}) async {
    final now = DateTime.now();
    final roleContext = await _roleContextProvider.load(orgId: orgId, forceRefresh: forceRefresh);
    if (roleContext == null) {
      _cache = null;
      _lastUpdated = null;
      return null;
    }

    final address = roleContext.address;
    final resolvedOrgId = roleContext.orgId;

    final isCacheValid = !forceRefresh &&
        _cache != null &&
        _cache!.address.toLowerCase() == address.toLowerCase() &&
        _cache!.orgId.toLowerCase() == resolvedOrgId.toLowerCase() &&
        _lastUpdated != null &&
        now.difference(_lastUpdated!) < cacheTtl;

    if (isCacheValid) {
      debugPrint('[WalletStateManager] Using cached wallet state for $address');
      return _cache;
    }

    debugPrint('[WalletStateManager] Refreshing wallet state for $address (forceRefresh=$forceRefresh)');

    final futures = await Future.wait<dynamic>([
      _web3Service.getVCs(resolvedOrgId),
      _web3Service.getAllVerificationRequests(
        onlyPending: true,
        orgIdFilter: resolvedOrgId,
        requesterAddress: address,
      ),
      _walletNameService.getDisplayName(address),
      _walletConnectService.hasActiveSession(),
    ]);

    final vcs = (futures[0] as List).cast<Map<String, dynamic>>();
    final verificationRequests = (futures[1] as List).cast<Map<String, dynamic>>();
    final displayName = futures[2] as String? ?? address;
    final isUsingWalletConnect = futures[3] as bool? ?? false;

    final state = WalletState(
      address: address,
      orgId: resolvedOrgId,
      displayName: displayName,
      didData: roleContext.didData,
      vcs: vcs,
      verificationRequests: verificationRequests,
      canIssueVc: roleContext.canIssue,
      canRevokeVc: roleContext.canRevoke,
      isTrustedVerifier: roleContext.isTrustedVerifier,
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


