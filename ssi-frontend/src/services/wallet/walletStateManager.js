import RoleContextProvider from '../role/roleContextProvider';
import RoleService from '../role/roleService';
import WalletNameService from './walletNameService';

class WalletStateCache {
  constructor(state) {
    this.state = state;
    this.timestamp = Date.now();
  }
}

export class WalletStateManager {
  constructor({
    web3Service,
    roleContextProvider,
    walletNameService,
    cacheTtlMs = 30_000,
  } = {}) {
    this.web3Service = web3Service;
    this.roleContextProvider =
      roleContextProvider ??
      new RoleContextProvider({
        roleService: new RoleService({ web3Service }),
        web3Service,
      });
    this.walletNameService = walletNameService ?? new WalletNameService();
    this.cacheTtlMs = cacheTtlMs;
    this.cache = new Map();
  }

  setWeb3Service(web3Service) {
    this.web3Service = web3Service;
    if (this.roleContextProvider) {
      this.roleContextProvider.setWeb3Service(web3Service);
    }
    this.clearCache();
  }

  _cacheKey(address, orgId) {
    return `${address?.toLowerCase() ?? ''}::${orgId?.toLowerCase() ?? ''}`;
  }

  _isCacheValid(entry) {
    if (!entry) return false;
    return Date.now() - entry.timestamp < this.cacheTtlMs;
  }

  clearCache() {
    this.cache.clear();
  }

  async load({ orgId, forceRefresh = false } = {}) {
    if (!this.web3Service) return null;
    const roleContext = await this.roleContextProvider.load({
      orgId,
      forceRefresh,
    });
    if (!roleContext) return null;

    const { address, orgId: resolvedOrgId } = roleContext;
    const key = this._cacheKey(address, resolvedOrgId);
    if (!forceRefresh && this._isCacheValid(this.cache.get(key))) {
      return this.cache.get(key).state;
    }

    const [vcs, verificationRequests, displayName] = await Promise.all([
      this.web3Service.getVCs(resolvedOrgId),
      this.web3Service.getAllVerificationRequests({
        onlyPending: true,
        orgIdFilter: resolvedOrgId,
        requesterAddress: address,
      }),
      this.walletNameService.getDisplayName(address),
    ]);

    const state = {
      address,
      orgId: resolvedOrgId,
      displayName,
      didData: roleContext.didData,
      vcs,
      verificationRequests,
      canIssueVc: roleContext.canIssue,
      canRevokeVc: roleContext.canRevoke,
      isTrustedVerifier: roleContext.isTrustedVerifier,
      isAdmin: roleContext.isAdmin,
      roleContext,
    };

    this.cache.set(key, new WalletStateCache(state));
    return state;
  }
}

export default WalletStateManager;

