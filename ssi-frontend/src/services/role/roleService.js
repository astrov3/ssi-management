export class RoleService {
  constructor({ web3Service } = {}) {
    this.web3Service = web3Service;
  }

  setWeb3Service(web3Service) {
    this.web3Service = web3Service;
  }

  async getCurrentAddress() {
    return this.web3Service?.getCurrentAddress() ?? null;
  }

  async isOwnerOf(orgId, address) {
    if (!this.web3Service || !orgId || !address) return false;
    try {
      const did = await this.web3Service.getDID(orgId);
      if (!did || !did.owner) return false;
      return (
        did.owner.toLowerCase() === address.toLowerCase() && Boolean(did.active)
      );
    } catch {
      return false;
    }
  }

  async isAuthorizedIssuerFor(orgId, address) {
    if (!this.web3Service || !orgId || !address) return false;
    try {
      return await this.web3Service.isAuthorizedIssuer(orgId, address);
    } catch {
      return false;
    }
  }

  async canIssueVC(orgId, address) {
    if (!address) return false;
    const isOwner = await this.isOwnerOf(orgId, address);
    if (isOwner) return true;
    return this.isAuthorizedIssuerFor(orgId, address);
  }

  async canRevokeVC(orgId, address) {
    return this.isOwnerOf(orgId, address);
  }
}

export default RoleService;

