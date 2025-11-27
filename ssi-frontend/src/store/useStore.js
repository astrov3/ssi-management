import { ethers } from 'ethers';
import { create } from 'zustand';
import Web3Service from '../services/web3/web3Service';
import WalletStateManager from '../services/wallet/walletStateManager';
import RoleContextProvider from '../services/role/roleContextProvider';
import RoleService from '../services/role/roleService';
import WalletNameService from '../services/wallet/walletNameService';
import { createDIDDocument, uploadDIDDocumentToIPFS, uploadVCToIPFS, retrieveJSONFromIPFS, uploadFileToIPFS } from '../utils/ipfs';
import { createAndSignVC, verifyVCSignature } from '../utils/vc';
import IdentityManager from '../contracts/IdentityManager.json';
import { normalizeOrgId } from '../utils/orgId';

export const useStore = create((set, get) => ({
  // Wallet state
  provider: null,
  signer: null,
  account: null,
  isConnected: false,
  contract: null,
  web3Service: null,
  walletStateManager: null,

  // App state
  loading: false,
  error: null,
  message: '',

  // DID state
  currentOrgID: '',
  didData: null,
  didActive: null,

  walletState: null,
  walletStateLoading: false,

  // VC state
  vcList: [],
  vcLength: 0,
  authorizedIssuers: [],

  // Actions
  setLoading: (loading) => set({ loading }),
  setError: (error) => set({ error }),
  setMessage: (message) => set({ message }),
  
  // Wallet actions
  connectWallet: async () => {
    try {
      set({ loading: true, error: null });
      
      if (!window.ethereum) {
        throw new Error('Please install MetaMask!');
      }

      const provider = new ethers.BrowserProvider(window.ethereum);
      await window.ethereum.request({ method: 'eth_requestAccounts' });
      const signer = await provider.getSigner();
      const account = await signer.getAddress();
      const normalizedAccountOrgId = normalizeOrgId(account);

      // Initialize contract
      const contractAddress = import.meta.env.VITE_CONTRACT_ADDRESS;
      
      if (!contractAddress) {
        throw new Error('Contract address not configured');
      }

      const contract = new ethers.Contract(contractAddress, IdentityManager.abi, signer);
      const web3Service = new Web3Service({ provider, signer, contractAddress });
      const walletNameService = new WalletNameService(
        typeof window !== 'undefined' ? window.localStorage : null,
      );
      const roleContextProvider = new RoleContextProvider({
        roleService: new RoleService({ web3Service }),
        web3Service,
      });
      const walletStateManager = new WalletStateManager({
        web3Service,
        roleContextProvider,
        walletNameService,
      });

      set({
        provider,
        signer,
        account,
        isConnected: true,
        contract,
        web3Service,
        walletStateManager,
        walletState: null,
        walletStateLoading: false,
        currentOrgID: normalizedAccountOrgId,
        loading: false,
        message: `Connected: ${account}`
      });

      await get().loadWalletState({
        orgId: normalizedAccountOrgId,
        forceRefresh: true,
      });
      return true;
    } catch (error) {
      set({ 
        loading: false, 
        error: error.message,
        message: `Error: ${error.message}`
      });
      return false;
    }
  },

  updateDID: async (orgID, updates) => {
    const { contract, account } = get();
    const normalizedOrgId = normalizeOrgId(orgID);
    if (!contract || !normalizedOrgId || !account) return false;

    try {
      set({ loading: true });

      // Fetch current DID document from IPFS if available
      let existingDoc = null;
      try {
        const did = await contract.dids(normalizedOrgId);
        if (did && did.uri) {
          existingDoc = await retrieveJSONFromIPFS(did.uri);
        }
      } catch {
        // ignore fetch failures; we'll build from scratch
      }

      // Build next DID Document (merge if existing)
      const didId = `did:ethr:${normalizedOrgId}`;
      let nextDoc;

      if (existingDoc) {
        nextDoc = {
          ...existingDoc,
          id: didId,
          controller: account,
          updated: new Date().toISOString(),
        };

        // Merge service endpoint
        if (updates?.serviceEndpoint !== undefined) {
          if (updates.serviceEndpoint) {
            nextDoc.service = [
              {
                id: `${didId}#service-1`,
                type: 'LinkedDomains',
                serviceEndpoint: updates.serviceEndpoint,
              },
            ];
          } else {
            delete nextDoc.service;
          }
        }

        // Merge alsoKnownAs
        if (updates?.alsoKnownAs !== undefined) {
          if (Array.isArray(updates.alsoKnownAs) && updates.alsoKnownAs.length > 0) {
            nextDoc.alsoKnownAs = updates.alsoKnownAs;
          } else {
            delete nextDoc.alsoKnownAs;
          }
        }

        // Merge metadata (shallow)
        if (updates) {
          const reserved = ['serviceEndpoint', 'alsoKnownAs', 'metadata', 'id', 'controller'];
          const incoming = Object.keys(updates).reduce((acc, key) => {
            if (!reserved.includes(key) && updates[key] !== undefined) {
              acc[key] = updates[key];
            }
            return acc;
          }, {});

          const meta = {
            ...(existingDoc.metadata || {}),
            ...(updates.metadata || {}),
            ...incoming,
            updatedAt: new Date().toISOString(),
          };

          if (Object.keys(meta).length > 0) {
            nextDoc.metadata = meta;
          }
        }
      } else {
        // No existing doc: create a fresh one
        nextDoc = createDIDDocument({
          id: didId,
          controller: account,
          serviceEndpoint: updates?.serviceEndpoint,
        });

        if (updates?.alsoKnownAs) {
          nextDoc.alsoKnownAs = updates.alsoKnownAs;
        }

        const metadata = { createdAt: new Date().toISOString() };
        const reserved = ['serviceEndpoint', 'alsoKnownAs', 'metadata', 'id', 'controller'];
        Object.keys(updates || {}).forEach((key) => {
          if (!reserved.includes(key) && updates[key] !== undefined) {
            metadata[key] = updates[key];
          }
        });
        if (updates?.metadata && typeof updates.metadata === 'object') {
          Object.assign(metadata, updates.metadata);
        }
        if (Object.keys(metadata).length > 0) {
          nextDoc.metadata = metadata;
        }
      }

      // Upload updated DID Document
      const { uri } = await uploadDIDDocumentToIPFS(nextDoc);

      // Hash and update on-chain
      const hashData = ethers.keccak256(ethers.toUtf8Bytes(JSON.stringify(nextDoc)));
      const tx = await contract.updateDID(normalizedOrgId, hashData, uri);
      await tx.wait();

      set({
        loading: false,
        didData: { ...(get().didData || {}), uri, hashData },
        message: 'DID updated successfully',
      });
      await get().loadWalletState({
        forceRefresh: true,
        orgId: normalizedOrgId,
      });
      return true;
    } catch (error) {
      set({
        loading: false,
        error: error.message,
        message: `Error updating DID: ${error.message}`,
      });
      return false;
    }
  },

  disconnectWallet: () => {
    const { walletStateManager } = get();
    walletStateManager?.clearCache?.();
    set({
      provider: null,
      signer: null,
      account: null,
      isConnected: false,
      contract: null,
      web3Service: null,
      walletStateManager: null,
      walletState: null,
      walletStateLoading: false,
      message: 'Disconnected'
    });
  },

  // DID actions
  setCurrentOrgID: (orgID) => {
    const normalizedOrgId = normalizeOrgId(orgID);
    set({ currentOrgID: normalizedOrgId });
    get().loadWalletState({
      orgId: normalizedOrgId || undefined,
      forceRefresh: true,
    });
  },

  loadWalletState: async ({ orgId, forceRefresh = false } = {}) => {
    const {
      walletStateManager,
      currentOrgID,
      isConnected,
      walletStateLoading,
    } = get();
    if (!walletStateManager || !isConnected || walletStateLoading) {
      return null;
    }

    set({ walletStateLoading: true });
    try {
      const targetOrgId =
        normalizeOrgId(orgId) || normalizeOrgId(currentOrgID) || undefined;
      const state = await walletStateManager.load({
        orgId: targetOrgId,
        forceRefresh,
      });
      const nextOrgId = normalizeOrgId(state?.orgId) || currentOrgID;
      set({
        walletState: state,
        walletStateLoading: false,
        currentOrgID: nextOrgId,
        didData: state?.didData ?? get().didData,
        didActive: state?.didData?.active ?? get().didActive,
      });
      return state;
    } catch (error) {
      set({
        walletStateLoading: false,
        error: error.message,
        message: `Error loading wallet state: ${error.message}`,
      });
      return null;
    }
  },
  
  checkDID: async (orgID) => {
    const { contract } = get();
    const normalizedOrgId = normalizeOrgId(orgID);
    if (!contract || !normalizedOrgId) return false;

    try {
      set({ loading: true });
      const did = await contract.dids(normalizedOrgId);
      set({
        didData: did,
        didActive: did.active,
        loading: false,
        message: `DID active: ${did.active}`
      });
      get().setCurrentOrgID(normalizedOrgId);
      return did;
    } catch (error) {
      set({ 
        loading: false, 
        error: error.message,
        message: `Error checking DID: ${error.message}`
      });
      return null;
    }
  },

  registerDID: async (orgID, options = {}) => {
    const { contract, account, signer } = get();
    const normalizedOrgId = normalizeOrgId(orgID);
    if (!contract || !normalizedOrgId || !account || !signer) return false;

    const {
      metadata: incomingMetadata = {},
      additionalMetadata = {},
      serviceEndpoint,
      logoFile,
      documentFile,
      jsonDocumentFile,
      mode = 'form',
    } = options ?? {};

    try {
      set({ loading: true });

      let mergedMetadata = {
        createdAt: new Date().toISOString(),
        ...incomingMetadata,
      };

      Object.entries(additionalMetadata || {}).forEach(([key, value]) => {
        if (key && value) {
          mergedMetadata[key.trim()] = typeof value === 'string' ? value.trim() : value;
        }
      });

      if (!mergedMetadata.name || !mergedMetadata.name.trim()) {
        mergedMetadata.name = `DID ${account.slice(0, 10)}...`;
      }

      if (logoFile instanceof File) {
        const upload = await uploadFileToIPFS(logoFile, `did-logo-${normalizedOrgId}`);
        mergedMetadata.logo = upload.uri;
        mergedMetadata.logoFileName = upload.fileName;
      }

      if (documentFile instanceof File) {
        const upload = await uploadFileToIPFS(documentFile, `did-attachment-${normalizedOrgId}`);
        mergedMetadata.document = upload.uri;
        mergedMetadata.documentFileName = upload.fileName;
      }

      let parsedDocument = null;
      if (jsonDocumentFile instanceof File) {
        const text = await jsonDocumentFile.text();
        try {
          parsedDocument = JSON.parse(text);
        } catch {
          throw new Error('Invalid DID JSON document. Please upload a valid JSON file.');
        }
      }

      const didId = `did:ethr:${normalizedOrgId}`;
      const nowIso = new Date().toISOString();
      let didDocument;

      if (parsedDocument && mode === 'upload') {
        didDocument = {
          ...parsedDocument,
          id: parsedDocument.id || didId,
          controller: account,
          updated: nowIso,
        };
        if (!didDocument.created) {
          didDocument.created = nowIso;
        }

        const parsedMetadata =
          parsedDocument.metadata && typeof parsedDocument.metadata === 'object'
            ? parsedDocument.metadata
            : {};

        didDocument.metadata = {
          ...parsedMetadata,
          ...mergedMetadata,
          updatedAt: nowIso,
        };

        if (!didDocument.service && (serviceEndpoint || mergedMetadata.website)) {
          didDocument.service = [
            {
              id: `${didId}#service-1`,
              type: 'LinkedDomains',
              serviceEndpoint: serviceEndpoint || mergedMetadata.website,
            },
          ];
        }
      } else {
        const endpoint = serviceEndpoint || mergedMetadata.website || 'https://ssi.example.com';
        didDocument = createDIDDocument({
          id: didId,
          controller: account,
          serviceEndpoint: endpoint,
        });
        didDocument.metadata = {
          ...mergedMetadata,
          updatedAt: nowIso,
        };
      }

      const { uri } = await uploadDIDDocumentToIPFS(didDocument);
      const hashData = ethers.keccak256(
        ethers.toUtf8Bytes(JSON.stringify(didDocument)),
      );

      const tx = await contract.registerDID(normalizedOrgId, hashData, uri);
      await tx.wait();

      set({
        loading: false,
        didActive: true,
        message: 'DID registered successfully',
      });
      get().setCurrentOrgID(normalizedOrgId);
      return true;
    } catch (error) {
      set({
        loading: false,
        error: error.message,
        message: `Error registering DID: ${error.message}`,
      });
      return false;
    }
  },

  authorizeIssuer: async (orgID, issuerAddress) => {
    const { contract } = get();
    const normalizedOrgId = normalizeOrgId(orgID);
    if (!contract || !normalizedOrgId || !issuerAddress) return false;

    try {
      set({ loading: true });
      const tx = await contract.authorizeIssuer(
        normalizedOrgId,
        issuerAddress,
      );
      await tx.wait();

      set({ 
        loading: false,
        message: `Issuer ${issuerAddress} authorized`
      });
      await get().loadWalletState({
        forceRefresh: true,
        orgId: normalizedOrgId,
      });
      return true;
    } catch (error) {
      set({ 
        loading: false, 
        error: error.message,
        message: `Error authorizing issuer: ${error.message}`
      });
      return false;
    }
  },

  issueVC: async (orgID, options = {}) => {
    const { contract, account, signer } = get();
    const normalizedOrgId = normalizeOrgId(orgID);
    if (!contract || !normalizedOrgId || !account || !signer) return false;

    const {
      claims: rawClaims = {},
      vcType = 'Credential',
      expirationDate = null,
    } = options ?? {};

    try {
      set({ loading: true });

      const processedClaims = {};
      for (const [key, value] of Object.entries(rawClaims)) {
        if (!key) continue;
        if (value === undefined || value === null || value === '') continue;

        if (value instanceof File) {
          const upload = await uploadFileToIPFS(
            value,
            `vc-${normalizedOrgId}-${key}`,
          );
          processedClaims[key] = upload.uri;
          processedClaims[`${key}FileName`] = upload.fileName;
        } else {
          processedClaims[key] =
            typeof value === 'string' ? value.trim() : value;
        }
      }

      if (Object.keys(processedClaims).length === 0) {
        throw new Error('Please provide at least one credential field.');
      }

      const signedVC = await createAndSignVC(
        {
          type: vcType,
          issuer: `did:ethr:${account}`,
          credentialSubject: `did:ethr:${normalizedOrgId}`,
          claims: processedClaims,
          expirationDate: expirationDate || null,
        },
        signer,
      );

      const { uri } = await uploadVCToIPFS(signedVC);
      const hashVC = ethers.keccak256(
        ethers.toUtf8Bytes(JSON.stringify(signedVC)),
      );

      let expirationTimestamp = 0;
      if (expirationDate) {
        const date = new Date(expirationDate);
        if (!Number.isNaN(date.getTime())) {
          expirationTimestamp = Math.floor(date.getTime() / 1000);
        }
      }

      const tx = await contract.issueVCWithExpiration(
        normalizedOrgId,
        hashVC,
        uri,
        expirationTimestamp,
      );
      await tx.wait();

      set({
        loading: false,
        message: '✅ VC issued successfully',
      });
      await get().loadWalletState({
        forceRefresh: true,
        orgId: normalizedOrgId,
      });
      return true;
    } catch (error) {
      set({
        loading: false,
        error: error.message,
        message: `Error issuing VC: ${error.message}`,
      });
      return false;
    }
  },

  getVCCount: async (orgID) => {
    const { contract } = get();
    const normalizedOrgId = normalizeOrgId(orgID);
    if (!contract || !normalizedOrgId) return 0;

    try {
      const count = await contract.getVCLength(normalizedOrgId);
      set({ 
        vcLength: Number(count),
        message: `VC count: ${count.toString()}`
      });
      return Number(count);
    } catch (error) {
      set({ 
        error: error.message,
        message: `Error getting VC count: ${error.message}`
      });
      return 0;
    }
  },

  verifyVC: async (orgID, index, providedHash) => {
    const { contract, signer } = get();
    const normalizedOrgId = normalizeOrgId(orgID);
    if (!contract || !normalizedOrgId) return false;

    try {
      // Verify on blockchain (checks validity, expiration, and hash)
      const isValid = await contract.verifyVC(
        normalizedOrgId,
        index,
        providedHash,
      );
      
      // If valid on blockchain, also verify signature from IPFS
      if (isValid) {
        try {
          const vc = await get().getVC(normalizedOrgId, index);
          if (vc && vc.document && vc.document.proof && signer) {
            const signatureValid = await verifyVCSignature(vc.document, signer, vc.issuer);
            if (!signatureValid) {
              set({ 
                message: '⚠️ VC is valid on blockchain but signature verification failed'
              });
              return false;
            }
          }
        } catch (error) {
          console.warn('Signature verification failed:', error);
        }
      }

      set({ 
        message: isValid ? 'VC is valid' : 'VC is invalid'
      });
      return isValid;
    } catch (error) {
      set({ 
        error: error.message,
        message: `Error verifying VC: ${error.message}`
      });
      return false;
    }
  },

  revokeVC: async (orgID, index) => {
    const { contract } = get();
    const normalizedOrgId = normalizeOrgId(orgID);
    if (!contract || !normalizedOrgId) return false;

    try {
      set({ loading: true });
      const tx = await contract.revokeVC(normalizedOrgId, index);
      await tx.wait();

      set({ 
        loading: false,
        message: 'VC revoked successfully'
      });
      await get().loadWalletState({
        forceRefresh: true,
        orgId: normalizedOrgId,
      });
      return true;
    } catch (error) {
      set({ 
        loading: false, 
        error: error.message,
        message: `Error revoking VC: ${error.message}`
      });
      return false;
    }
  },

  getVC: async (orgID, index) => {
    const { contract, signer } = get();
    const normalizedOrgId = normalizeOrgId(orgID);
    if (!contract || !normalizedOrgId) return null;

    try {
      const vc = await contract.getVC(normalizedOrgId, index);
      
      // Retrieve VC document from IPFS
      let vcDocument = null;
      try {
        vcDocument = await retrieveJSONFromIPFS(vc[1]); // vc[1] is uri
      } catch (error) {
        console.warn('Failed to retrieve VC from IPFS:', error);
      }

      const vcData = {
        hashCredential: vc[0],
        uri: vc[1],
        issuer: vc[2],
        valid: vc[3],
        expirationDate: vc[4] ? new Date(Number(vc[4]) * 1000).toISOString() : null,
        issuedAt: vc[5] ? new Date(Number(vc[5]) * 1000).toISOString() : null,
        verified: vc[6], // Đã được xác thực bởi cơ quan cấp cao
        verifier: vc[7], // Địa chỉ của cơ quan đã xác thực
        verifiedAt: vc[8] ? new Date(Number(vc[8]) * 1000).toISOString() : null,
        document: vcDocument, // Full VC document from IPFS
        isExpired: vc[4] > 0 ? Number(vc[4]) * 1000 < Date.now() : false
      };

      // Verify VC signature if document is available
      if (vcDocument && vcDocument.proof && signer) {
        try {
          const isValid = await verifyVCSignature(vcDocument, signer, vc[2]);
          vcData.signatureValid = isValid;
        } catch (error) {
          console.warn('Failed to verify VC signature:', error);
          vcData.signatureValid = false;
        }
      }

      return vcData;
    } catch (error) {
      set({ 
        error: error.message,
        message: `Error getting VC: ${error.message}`
      });
      return null;
    }
  },

  // Thiết lập trusted verifier (chỉ admin)
  setTrustedVerifier: async (verifierAddress, allowed) => {
    const { contract, account } = get();
    if (!contract || !account) return false;

    try {
      set({ loading: true });
      const tx = await contract.setTrustedVerifier(verifierAddress, allowed);
      await tx.wait();
      set({ 
        loading: false,
        message: `Trusted verifier ${allowed ? 'added' : 'removed'} successfully`
      });
      await get().loadWalletState({ forceRefresh: true });
      return true;
    } catch (error) {
      set({ 
        loading: false,
        error: error.message,
        message: `Error setting trusted verifier: ${error.message}`
      });
      return false;
    }
  },

  // Xác thực VC bởi cơ quan cấp cao (trusted verifier)
  verifyCredential: async (orgID, index) => {
    const { contract, account } = get();
    const normalizedOrgId = normalizeOrgId(orgID);
    if (!contract || !normalizedOrgId || !account) return false;

    try {
      set({ loading: true });
      const tx = await contract.verifyCredential(normalizedOrgId, index);
      await tx.wait();
      set({ 
        loading: false,
        message: 'VC verified successfully'
      });
      await get().loadWalletState({
        forceRefresh: true,
        orgId: normalizedOrgId,
      });
      return true;
    } catch (error) {
      set({ 
        loading: false,
        error: error.message,
        message: `Error verifying credential: ${error.message}`
      });
      return false;
    }
  },

  // Kiểm tra xem một địa chỉ có phải là trusted verifier không
  isTrustedVerifier: async (verifierAddress) => {
    const { contract } = get();
    if (!contract) return false;

    try {
      const isTrusted = await contract.trustedVerifiers(verifierAddress);
      return isTrusted;
    } catch (error) {
      set({ 
        error: error.message,
        message: `Error checking trusted verifier: ${error.message}`
      });
      return false;
    }
  },

  // Yêu cầu xác thực VC on-chain
  requestVerification: async (orgID, vcIndex, targetVerifier, metadataUri) => {
    const { contract, account } = get();
    const normalizedOrgId = normalizeOrgId(orgID);
    if (!contract || !normalizedOrgId || !account) return false;

    try {
      set({ loading: true });
      const tx = await contract.requestVerification(
        normalizedOrgId,
        vcIndex,
        targetVerifier || ethers.ZeroAddress,
        metadataUri
      );
      await tx.wait();
      set({ 
        loading: false,
        message: 'Verification request created successfully'
      });
      await get().loadWalletState({
        forceRefresh: true,
        orgId: normalizedOrgId,
      });
      return true;
    } catch (error) {
      set({ 
        loading: false,
        error: error.message,
        message: `Error requesting verification: ${error.message}`
      });
      return false;
    }
  },

  // Hủy yêu cầu xác thực
  cancelVerificationRequest: async (requestId) => {
    const { contract, account } = get();
    if (!contract || !account) return false;

    try {
      set({ loading: true });
      const tx = await contract.cancelVerificationRequest(requestId);
      await tx.wait();
      set({ 
        loading: false,
        message: 'Verification request cancelled successfully'
      });
      await get().loadWalletState({ forceRefresh: true });
      return true;
    } catch (error) {
      set({ 
        loading: false,
        error: error.message,
        message: `Error cancelling verification request: ${error.message}`
      });
      return false;
    }
  },

  // Lấy thông tin verification request
  getVerificationRequest: async (requestId) => {
    const { contract } = get();
    if (!contract) return null;

    try {
      const request = await contract.getVerificationRequest(requestId);
      return {
        orgID: request[0],
        vcIndex: Number(request[1]),
        requester: request[2],
        targetVerifier: request[3],
        metadataUri: request[4],
        requestedAt: request[5] ? new Date(Number(request[5]) * 1000).toISOString() : null,
        processed: request[6]
      };
    } catch (error) {
      set({ 
        error: error.message,
        message: `Error getting verification request: ${error.message}`
      });
      return null;
    }
  },

  // Lấy request ID của VC
  getVCRequestId: async (orgID, vcIndex) => {
    const { contract } = get();
    const normalizedOrgId = normalizeOrgId(orgID);
    if (!contract || !normalizedOrgId) return 0;

    try {
      const requestId = await contract.vcRequestId(
        normalizedOrgId,
        vcIndex,
      );
      return Number(requestId);
    } catch {
      return 0;
    }
  },

  // Kiểm tra xem VC có đang có verification request chưa được xử lý không
  hasPendingVerificationRequest: async (orgID, vcIndex) => {
    const { contract } = get();
    const normalizedOrgId = normalizeOrgId(orgID);
    if (!contract || !normalizedOrgId) return false;

    try {
      const hasPending = await contract.hasPendingVerificationRequest(
        normalizedOrgId,
        vcIndex,
      );
      return hasPending;
    } catch {
      return false;
    }
  },

  // Lấy admin address
  getAdmin: async () => {
    const { contract } = get();
    if (!contract) return null;

    try {
      const admin = await contract.admin();
      return admin;
    } catch {
      return null;
    }
  }
}));
