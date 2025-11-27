import RoleService from './roleService';

class RoleCacheEntry {
  constructor(snapshot) {
    this.snapshot = snapshot;
    this.timestamp = Date.now();
  }
}

export class RoleContextProvider {
  constructor({
    roleService,
    web3Service,
    cacheTtlMs = 30_000,
  } = {}) {
    this.roleService = roleService ?? new RoleService({ web3Service });
    this.web3Service = web3Service;
    this.cacheTtlMs = cacheTtlMs;
    this.cache = new Map();
  }

  setWeb3Service(web3Service) {
    this.web3Service = web3Service;
    if (this.roleService) {
      this.roleService.setWeb3Service(web3Service);
    }
    this.clear();
  }

  _cacheKey(address, orgId) {
    return `${address?.toLowerCase() ?? ''}::${orgId?.toLowerCase() ?? ''}`;
  }

  _isEntryValid(entry) {
    if (!entry) return false;
    return Date.now() - entry.timestamp < this.cacheTtlMs;
  }

  clear() {
    this.cache.clear();
  }

  async load({ orgId, forceRefresh = false } = {}) {
    if (!this.web3Service) return null;
    const address = await this.roleService.getCurrentAddress();
    if (!address) return null;
    const resolvedOrgId =
      orgId?.trim() && orgId.trim().length > 0 ? orgId.trim() : address;

    const key = this._cacheKey(address, resolvedOrgId);
    if (!forceRefresh && this._isEntryValid(this.cache.get(key))) {
      return this.cache.get(key).snapshot;
    }

    const didData = await this.web3Service.getDID(resolvedOrgId);
    const isOwner = await this.roleService.isOwnerOf(resolvedOrgId, address);
    const isIssuer = await this.roleService.isAuthorizedIssuerFor(
      resolvedOrgId,
      address,
    );
    const canIssue = isOwner || isIssuer;
    const canRevoke = isOwner;
    const isTrustedVerifier = await this.web3Service.isTrustedVerifier(address);
    const admin = await this.web3Service.getAdmin();
    const isAdmin =
      admin?.toLowerCase() === address.toLowerCase() || false;

    const snapshot = {
      address,
      orgId: resolvedOrgId,
      didData,
      isOwner,
      isIssuer: canIssue,
      canIssue,
      canRevoke,
      isTrustedVerifier: isTrustedVerifier || isAdmin,
      isAdmin,
    };

    this.cache.set(key, new RoleCacheEntry(snapshot));
    return snapshot;
  }
}

export default RoleContextProvider;

