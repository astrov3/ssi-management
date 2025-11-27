import 'package:flutter/foundation.dart';

import 'package:ssi_app/services/role/role_service.dart';
import 'package:ssi_app/services/web3/web3_service.dart';

class RoleContextSnapshot {
  RoleContextSnapshot({
    required this.address,
    required this.orgId,
    required this.didData,
    required this.isOwner,
    required this.isIssuer,
    required this.canIssue,
    required this.canRevoke,
    required this.isTrustedVerifier,
    required this.isAdmin,
  });

  final String address;
  final String orgId;
  final Map<String, dynamic>? didData;
  final bool isOwner;
  final bool isIssuer;
  final bool canIssue;
  final bool canRevoke;
  final bool isTrustedVerifier;
  final bool isAdmin;
}

class RoleContextProvider {
  RoleContextProvider({
    RoleService? roleService,
    Web3Service? web3Service,
  })  : _roleService = roleService ?? RoleService(),
        _web3Service = web3Service ?? Web3Service();

  final RoleService _roleService;
  final Web3Service _web3Service;

  final Map<String, _RoleCacheEntry> _cache = {};
  Duration cacheTtl = const Duration(seconds: 30);

  Future<RoleContextSnapshot?> load({
    String? orgId,
    bool forceRefresh = false,
  }) async {
    final address = await _roleService.getCurrentAddress();
    if (address == null || address.isEmpty) {
      return null;
    }

    final resolvedOrgId =
        (orgId != null && orgId.trim().isNotEmpty) ? orgId : address;
    final cacheKey = '${address.toLowerCase()}::${resolvedOrgId.toLowerCase()}';

    if (!forceRefresh) {
      final entry = _cache[cacheKey];
      if (entry != null && !_isExpired(entry.timestamp)) {
        return entry.snapshot;
      }
    }

    Map<String, dynamic>? didData;
    bool isOwner = false;
    try {
      didData = await _web3Service.getDID(resolvedOrgId);
      if (didData != null) {
        final owner = didData['owner']?.toString();
        final isActive = didData['active'] == true;
        if (owner != null) {
          isOwner = owner.toLowerCase() == address.toLowerCase() && isActive;
        }
      }
    } catch (e) {
      debugPrint('[RoleContextProvider] Error loading DID: $e');
    }

    bool isIssuer = false;
    try {
      isIssuer = await _web3Service.isAuthorizedIssuer(resolvedOrgId, address);
    } catch (e) {
      debugPrint('[RoleContextProvider] Error checking issuer: $e');
    }

    bool isTrustedVerifier = false;
    try {
      isTrustedVerifier = await _web3Service.isTrustedVerifier(address);
    } catch (e) {
      debugPrint('[RoleContextProvider] Error checking verifier: $e');
    }

    bool isAdmin = false;
    try {
      final admin = await _web3Service.getAdmin();
      if (admin != null) {
        isAdmin = admin.toLowerCase() == address.toLowerCase();
      }
    } catch (e) {
      debugPrint('[RoleContextProvider] Error checking admin: $e');
    }

    final snapshot = RoleContextSnapshot(
      address: address,
      orgId: resolvedOrgId,
      didData: didData,
      isOwner: isOwner,
      isIssuer: isOwner || isIssuer,
      canIssue: isOwner || isIssuer,
      canRevoke: isOwner,
      isTrustedVerifier: isTrustedVerifier || isAdmin,
      isAdmin: isAdmin,
    );

    _cache[cacheKey] = _RoleCacheEntry(snapshot: snapshot);
    return snapshot;
  }

  void invalidate({
    required String address,
    required String orgId,
  }) {
    final cacheKey = '${address.toLowerCase()}::${orgId.toLowerCase()}';
    _cache.remove(cacheKey);
  }

  void clear() => _cache.clear();

  bool _isExpired(DateTime timestamp) {
    return DateTime.now().difference(timestamp) > cacheTtl;
  }
}

class _RoleCacheEntry {
  _RoleCacheEntry({required this.snapshot}) : timestamp = DateTime.now();

  final RoleContextSnapshot snapshot;
  final DateTime timestamp;
}

