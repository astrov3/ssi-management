import { ethers } from 'ethers';
import IdentityManager from '../../contracts/IdentityManager.json';
import { normalizeOrgId } from '../../utils/orgId';

const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';

const safeNumber = (value) => {
  if (value === undefined || value === null) {
    return 0;
  }
  try {
    return Number(value);
  } catch {
    return 0;
  }
};

export class Web3Service {
  constructor({
    provider,
    signer,
    contractAddress = import.meta.env.VITE_CONTRACT_ADDRESS,
    abi = IdentityManager?.abi,
  } = {}) {
    if (!contractAddress) {
      throw new Error('Contract address (VITE_CONTRACT_ADDRESS) is missing');
    }
    if (!abi) {
      throw new Error('IdentityManager ABI not found');
    }

    this.contractAddress = contractAddress;
    this.abi = abi;
    this.provider = provider ?? signer?.provider ?? null;
    this.signer = signer ?? null;

    const signerOrProvider = this.signer ?? this.provider;
    if (!signerOrProvider) {
      throw new Error('Provider or signer is required to initialize Web3Service');
    }

    this.readContract = new ethers.Contract(
      this.contractAddress,
      this.abi,
      this.provider ?? signerOrProvider,
    );
    this.writeContract = this.signer
      ? this.readContract.connect(this.signer)
      : null;
  }

  updateSigner(signer) {
    if (!signer) return;
    this.signer = signer;
    this.provider = signer.provider ?? this.provider;
    this.writeContract = this.readContract.connect(signer);
  }

  getContract(forWrite = false) {
    if (forWrite) {
      if (!this.writeContract) {
        throw new Error('No signer available for write operations');
      }
      return this.writeContract;
    }
    return this.readContract;
  }

  async getCurrentAddress() {
    if (!this.signer) return null;
    try {
      return await this.signer.getAddress();
    } catch {
      return null;
    }
  }

  async getDID(orgId) {
    const normalizedOrgId = normalizeOrgId(orgId);
    if (!normalizedOrgId) return null;
    try {
      const contract = this.getContract();
      const result = await contract.dids(normalizedOrgId);
      const owner = result?.owner ?? result?.[0];
      if (!owner || owner === ZERO_ADDRESS) {
        return null;
      }
      return {
        owner,
        hashData: result?.hashData ?? result?.[1] ?? '',
        uri: result?.uri ?? result?.[2] ?? '',
        active: Boolean(result?.active ?? result?.[3]),
      };
    } catch (error) {
      console.warn('[Web3Service] getDID error', error);
      return null;
    }
  }

  async getVC(orgId, index) {
    const normalizedOrgId = normalizeOrgId(orgId);
    if (!normalizedOrgId) return null;
    try {
      const contract = this.getContract();
      const vc = await contract.getVC(normalizedOrgId, index);
      const expiration = safeNumber(vc?.expirationDate ?? vc?.[4]);
      const issuedAt = safeNumber(vc?.issuedAt ?? vc?.[5]);
      const verifiedAt = safeNumber(vc?.verifiedAt ?? vc?.[8]);
      return {
        index,
        hashCredential: vc?.hashCredential ?? vc?.[0],
        uri: vc?.uri ?? vc?.[1],
        issuer: vc?.issuer ?? vc?.[2],
        valid: Boolean(vc?.valid ?? vc?.[3]),
        expirationDate: expiration,
        issuedAt,
        verified: Boolean(vc?.verified ?? vc?.[6]),
        verifier: vc?.verifier ?? vc?.[7] ?? ZERO_ADDRESS,
        verifiedAt,
        isExpired:
          expiration > 0 ? expiration * 1000 < Date.now() : false,
      };
    } catch (error) {
      console.warn('[Web3Service] getVC error', error);
      return null;
    }
  }

  async getVCLength(orgId) {
    const normalizedOrgId = normalizeOrgId(orgId);
    if (!normalizedOrgId) return 0;
    try {
      const contract = this.getContract();
      const value = await contract.getVCLength(normalizedOrgId);
      return safeNumber(value);
    } catch (error) {
      console.warn('[Web3Service] getVCLength error', error);
      return 0;
    }
  }

  async getVCs(orgId) {
    const normalizedOrgId = normalizeOrgId(orgId);
    if (!normalizedOrgId) return [];
    const length = await this.getVCLength(normalizedOrgId);
    if (!length) return [];
    const results = [];
    for (let index = 0; index < length; index += 1) {
      const vc = await this.getVC(normalizedOrgId, index);
      if (vc) {
        results.push(vc);
      }
    }
    return results;
  }

  async getNextRequestId() {
    try {
      const contract = this.getContract();
      if (!contract?.nextRequestId) {
        console.warn(
          '[Web3Service] getNextRequestId skipped: method missing on contract',
        );
        return 0;
      }
      const value = await contract.nextRequestId();
      return safeNumber(value);
    } catch (error) {
      console.warn('[Web3Service] getNextRequestId error', error);
      return 0;
    }
  }

  async getVerificationRequest(requestId) {
    try {
      const contract = this.getContract();
      const req = await contract.getVerificationRequest(requestId);
      if (!req) return null;
      return {
        requestId,
        orgID: req?.orgID ?? req?.[0] ?? '',
        vcIndex: safeNumber(req?.vcIndex ?? req?.[1]),
        requester: req?.requester ?? req?.[2] ?? ZERO_ADDRESS,
        targetVerifier: req?.targetVerifier ?? req?.[3] ?? ZERO_ADDRESS,
        metadataUri: req?.metadataUri ?? req?.[4] ?? '',
        requestedAt: safeNumber(req?.requestedAt ?? req?.[5]),
        processed: Boolean(req?.processed ?? req?.[6]),
      };
    } catch (error) {
      console.warn('[Web3Service] getVerificationRequest error', error);
      return null;
    }
  }

  async getAllVerificationRequests({
    onlyPending = true,
    orgIdFilter,
    requesterAddress,
  } = {}) {
    const nextId = await this.getNextRequestId();
    if (!nextId) return [];
    const requests = [];
    for (let requestId = 1; requestId <= nextId; requestId += 1) {
      const data = await this.getVerificationRequest(requestId);
      if (!data) continue;
      if (
        orgIdFilter &&
        data.orgID?.toLowerCase() !== orgIdFilter.toLowerCase()
      ) {
        continue;
      }
      if (
        requesterAddress &&
        data.requester?.toLowerCase() !== requesterAddress.toLowerCase()
      ) {
        continue;
      }
      if (onlyPending && data.processed) {
        continue;
      }
      requests.push(data);
    }
    return requests.sort(
      (a, b) => (b.requestedAt || 0) - (a.requestedAt || 0),
    );
  }

  async isAuthorizedIssuer(orgId, address) {
    try {
      if (!address) return false;
      const contract = this.getContract();
      return Boolean(
        await contract.authorizedIssuers(orgId, address),
      );
    } catch (error) {
      console.warn('[Web3Service] isAuthorizedIssuer error', error);
      return false;
    }
  }

  async isTrustedVerifier(address) {
    try {
      if (!address) return false;
      const contract = this.getContract();
      return Boolean(await contract.trustedVerifiers(address));
    } catch (error) {
      console.warn('[Web3Service] isTrustedVerifier error', error);
      return false;
    }
  }

  async getAdmin() {
    try {
      const contract = this.getContract();
      return await contract.admin();
    } catch (error) {
      console.warn('[Web3Service] getAdmin error', error);
      return null;
    }
  }

  async registerDID(orgId, hashData, uri) {
    const normalizedOrgId = normalizeOrgId(orgId);
    if (!normalizedOrgId) throw new Error('Organization ID is required');
    const contract = this.getContract(true);
    const tx = await contract.registerDID(normalizedOrgId, hashData, uri);
    return tx.wait();
  }

  async updateDID(orgId, hashData, uri) {
    const normalizedOrgId = normalizeOrgId(orgId);
    if (!normalizedOrgId) throw new Error('Organization ID is required');
    const contract = this.getContract(true);
    const tx = await contract.updateDID(normalizedOrgId, hashData, uri);
    return tx.wait();
  }

  async authorizeIssuer(orgId, issuerAddress) {
    const normalizedOrgId = normalizeOrgId(orgId);
    if (!normalizedOrgId) throw new Error('Organization ID is required');
    const contract = this.getContract(true);
    const tx = await contract.authorizeIssuer(normalizedOrgId, issuerAddress);
    return tx.wait();
  }

  async issueVC(orgId, hashCredential, uri, expirationTimestamp = 0) {
    const normalizedOrgId = normalizeOrgId(orgId);
    if (!normalizedOrgId) throw new Error('Organization ID is required');
    const contract = this.getContract(true);
    const tx = await contract.issueVCWithExpiration(
      normalizedOrgId,
      hashCredential,
      uri,
      BigInt(expirationTimestamp ?? 0),
    );
    return tx.wait();
  }

  async verifyVC(orgId, index, providedHash) {
    const normalizedOrgId = normalizeOrgId(orgId);
    if (!normalizedOrgId) throw new Error('Organization ID is required');
    const contract = this.getContract();
    return contract.verifyVC(normalizedOrgId, index, providedHash);
  }

  async revokeVC(orgId, index) {
    const normalizedOrgId = normalizeOrgId(orgId);
    if (!normalizedOrgId) throw new Error('Organization ID is required');
    const contract = this.getContract(true);
    const tx = await contract.revokeVC(normalizedOrgId, index);
    return tx.wait();
  }

  async requestVerification(orgId, index, targetVerifier, metadataUri) {
    const normalizedOrgId = normalizeOrgId(orgId);
    if (!normalizedOrgId) throw new Error('Organization ID is required');
    const contract = this.getContract(true);
    const verifier =
      targetVerifier && targetVerifier.trim()
        ? targetVerifier
        : ZERO_ADDRESS;
    const tx = await contract.requestVerification(
      normalizedOrgId,
      index,
      verifier,
      metadataUri,
    );
    return tx.wait();
  }

  async cancelVerificationRequest(requestId) {
    const contract = this.getContract(true);
    const tx = await contract.cancelVerificationRequest(requestId);
    return tx.wait();
  }

  async verifyCredential(orgId, index) {
    const normalizedOrgId = normalizeOrgId(orgId);
    if (!normalizedOrgId) throw new Error('Organization ID is required');
    const contract = this.getContract(true);
    const tx = await contract.verifyCredential(normalizedOrgId, index);
    return tx.wait();
  }

  async setTrustedVerifier(verifierAddress, allowed) {
    const contract = this.getContract(true);
    const tx = await contract.setTrustedVerifier(verifierAddress, allowed);
    return tx.wait();
  }

  async hasPendingVerificationRequest(orgId, index) {
    const normalizedOrgId = normalizeOrgId(orgId);
    if (!normalizedOrgId) return false;
    try {
      const contract = this.getContract();
      return Boolean(
        await contract.hasPendingVerificationRequest(
          normalizedOrgId,
          index,
        ),
      );
    } catch (error) {
      console.warn('[Web3Service] hasPendingVerificationRequest error', error);
      return false;
    }
  }
}

export default Web3Service;

