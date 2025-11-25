import 'package:ssi_app/services/web3/web3_service.dart';
import 'package:ssi_app/services/wallet/wallet_connect_service.dart';

class UserRole {
  final bool isOwner;
  final bool isIssuer;
  final List<String> ownedOrgIDs;
  final Map<String, List<String>> authorizedOrgIDs; // orgID -> list of authorized addresses

  UserRole({
    required this.isOwner,
    required this.isIssuer,
    required this.ownedOrgIDs,
    required this.authorizedOrgIDs,
  });
}

class RoleService {
  final Web3Service _web3Service;
  final WalletConnectService _walletConnectService;

  RoleService({
    Web3Service? web3Service,
    WalletConnectService? walletConnectService,
  })  : _web3Service = web3Service ?? Web3Service(),
        _walletConnectService = walletConnectService ?? WalletConnectService();

  /// Get the current user's address (from either private key or WalletConnect)
  Future<String?> getCurrentAddress() async {
    // Try private key wallet first
    final pkAddress = await _web3Service.loadWallet();
    if (pkAddress != null) return pkAddress;

    // Try WalletConnect
    final wcAddress = await _walletConnectService.getStoredAddress();
    return wcAddress;
  }

  /// Check if user is owner of a specific orgID
  Future<bool> isOwnerOf(String orgID, String? address) async {
    if (address == null) return false;
    try {
      final did = await _web3Service.getDID(orgID);
      if (did == null) return false;
      return did['owner'].toString().toLowerCase() == address.toLowerCase() && did['active'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Check if user is authorized issuer for a specific orgID
  Future<bool> isAuthorizedIssuerFor(String orgID, String? address) async {
    if (address == null) return false;
    try {
      return await _web3Service.isAuthorizedIssuer(orgID, address);
    } catch (_) {
      return false;
    }
  }

  /// Get all orgIDs where user is owner
  Future<List<String>> getOwnedOrgIDs(String? address) async {
    // Note: This is a simplified implementation
    // In a real scenario, you might need to track orgIDs off-chain or use events
    // For now, we'll check common orgID patterns or let the user specify
    return [];
  }

  /// Determine user role for a specific orgID
  Future<UserRole> getUserRoleForOrgID(String orgID, String? address) async {
    if (address == null) {
      return UserRole(
        isOwner: false,
        isIssuer: false,
        ownedOrgIDs: [],
        authorizedOrgIDs: {},
      );
    }

    final isOwner = await isOwnerOf(orgID, address);
    final isIssuer = await isAuthorizedIssuerFor(orgID, address);

    return UserRole(
      isOwner: isOwner,
      isIssuer: isIssuer || isOwner, // Owner can also issue VCs
      ownedOrgIDs: isOwner ? [orgID] : [],
      authorizedOrgIDs: isIssuer ? {orgID: [address]} : {},
    );
  }

  /// Check if user can issue VC for a specific orgID
  Future<bool> canIssueVC(String orgID, String? address) async {
    if (address == null) return false;
    final isOwner = await isOwnerOf(orgID, address);
    if (isOwner) return true;
    return await isAuthorizedIssuerFor(orgID, address);
  }

  /// Check if user can revoke VC for a specific orgID
  Future<bool> canRevokeVC(String orgID, String? address) async {
    if (address == null) return false;
    return await isOwnerOf(orgID, address);
  }

  void dispose() {
  }
}

