import { ethers } from 'ethers';
import { create } from 'zustand';
import { createDIDDocument, uploadDIDDocumentToIPFS, uploadVCToIPFS, retrieveJSONFromIPFS } from '../utils/ipfs';
import { createAndSignVC, verifyVCSignature } from '../utils/vc';

export const useStore = create((set, get) => ({
  // Wallet state
  provider: null,
  signer: null,
  account: null,
  isConnected: false,
  contract: null,

  // App state
  loading: false,
  error: null,
  message: '',

  // DID state
  currentOrgID: '',
  didData: null,
  didActive: null,

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

      // Initialize contract
      const IdentityManagerAbi = (await import('../IdentityManager.json')).abi;
      const contractAddress = import.meta.env.VITE_CONTRACT_ADDRESS;
      
      if (!contractAddress) {
        throw new Error('Contract address not configured');
      }

      const contract = new ethers.Contract(contractAddress, IdentityManagerAbi, signer);

      set({
        provider,
        signer,
        account,
        isConnected: true,
        contract,
        loading: false,
        message: `Connected: ${account}`
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
    if (!contract || !orgID || !account) return false;

    try {
      set({ loading: true });

      // Fetch current DID document from IPFS if available
      let existingDoc = null;
      try {
        const did = await contract.dids(orgID);
        if (did && did.uri) {
          existingDoc = await retrieveJSONFromIPFS(did.uri);
        }
      } catch {
        // ignore fetch failures; we'll build from scratch
      }

      // Build next DID Document (merge if existing)
      const didId = `did:ethr:${orgID}`;
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
      const tx = await contract.updateDID(orgID, hashData, uri);
      await tx.wait();

      set({
        loading: false,
        didData: { ...(get().didData || {}), uri, hashData },
        message: '✅ DID updated successfully',
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
    set({
      provider: null,
      signer: null,
      account: null,
      isConnected: false,
      contract: null,
      message: 'Disconnected'
    });
  },

  // DID actions
  setCurrentOrgID: (orgID) => set({ currentOrgID: orgID }),
  
  checkDID: async (orgID) => {
    const { contract } = get();
    if (!contract || !orgID) return false;

    try {
      set({ loading: true });
      const did = await contract.dids(orgID);
      set({ 
        didData: did,
        didActive: did.active,
        loading: false,
        message: `DID active: ${did.active}`
      });
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

  registerDID: async (orgID, data) => {
    const { contract, account, signer } = get();
    if (!contract || !orgID || !account || !signer) return false;

    try {
      set({ loading: true });
      
      // Parse data - can be string (JSON) or object
      let didData = {};
      if (typeof data === 'string') {
        try {
          didData = JSON.parse(data);
        } catch {
          // If not JSON, treat as plain text and store in metadata
          didData = { data: data };
        }
      } else if (typeof data === 'object' && data !== null) {
        didData = data;
      }

      // Create W3C DID Document
      const didId = `did:ethr:${orgID}`;
      const didDocument = createDIDDocument({
        id: didId,
        controller: account,
        serviceEndpoint: didData.serviceEndpoint
      });

      // Add custom data to DID Document if provided
      if (didData.alsoKnownAs) {
        didDocument.alsoKnownAs = didData.alsoKnownAs;
      }
      
      // Store all custom data in metadata
      // If data is plain text (stored in didData.data), preserve it
      // If data has other properties, store them in metadata
      const metadata = {
        createdAt: new Date().toISOString(),
      };
      
      // If data is plain text
      if (didData.data && typeof didData.data === 'string') {
        metadata.originalData = didData.data;
      }
      
      // Add other custom fields (except reserved fields)
      const reservedFields = ['serviceEndpoint', 'alsoKnownAs', 'data', 'metadata', 'id', 'controller'];
      Object.keys(didData).forEach(key => {
        if (!reservedFields.includes(key) && didData[key] !== undefined) {
          metadata[key] = didData[key];
        }
      });
      
      // Merge with existing metadata if provided
      if (didData.metadata && typeof didData.metadata === 'object') {
        Object.assign(metadata, didData.metadata);
      }
      
      // Only add metadata if it has content
      if (Object.keys(metadata).length > 1 || metadata.originalData) {
        didDocument.metadata = metadata;
      }

      // Upload DID Document to IPFS
      const { uri } = await uploadDIDDocumentToIPFS(didDocument);
      
      // Calculate hash of DID Document
      const hashData = ethers.keccak256(ethers.toUtf8Bytes(JSON.stringify(didDocument)));

      // Register DID on blockchain
      const tx = await contract.registerDID(orgID, hashData, uri);
      await tx.wait();

      set({ 
        loading: false,
        didActive: true,
        message: '✅ DID registered successfully'
      });
      return true;
    } catch (error) {
      set({ 
        loading: false, 
        error: error.message,
        message: `Error registering DID: ${error.message}`
      });
      return false;
    }
  },

  authorizeIssuer: async (orgID, issuerAddress) => {
    const { contract } = get();
    if (!contract || !orgID || !issuerAddress) return false;

    try {
      set({ loading: true });
      const tx = await contract.authorizeIssuer(orgID, issuerAddress);
      await tx.wait();

      set({ 
        loading: false,
        message: `✅ Issuer ${issuerAddress} authorized`
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

  issueVC: async (orgID, vcData) => {
    const { contract, account, signer } = get();
    if (!contract || !orgID || !account || !signer) return false;

    try {
      set({ loading: true });
      
      // Parse vcData - can be string (JSON) or object
      let claims = {};
      let vcType = 'Credential';
      let expirationDate = null;

      if (typeof vcData === 'string') {
        try {
          const parsed = JSON.parse(vcData);
          // If parsed is an object with claims, use claims; otherwise use the whole object
          if (parsed.claims && typeof parsed.claims === 'object') {
            claims = parsed.claims;
          } else if (typeof parsed === 'object' && !Array.isArray(parsed)) {
            // Remove reserved fields and use rest as claims
            const { type, expirationDate: expDate, claims: parsedClaims, ...rest } = parsed;
            claims = parsedClaims || rest;
            vcType = type || vcType;
            expirationDate = expDate || null;
          } else {
            claims = { data: vcData };
          }
        } catch {
          // If not JSON, treat as plain text
          claims = { data: vcData };
        }
      } else if (typeof vcData === 'object' && vcData !== null) {
        // If vcData has claims property, use it; otherwise use vcData itself as claims
        if (vcData.claims && typeof vcData.claims === 'string') {
          // If claims is a string, try to parse it
          try {
            claims = JSON.parse(vcData.claims);
          } catch {
            claims = { data: vcData.claims };
          }
        } else if (vcData.claims && typeof vcData.claims === 'object') {
          claims = vcData.claims;
        } else {
          // Use vcData as claims, but exclude reserved fields
          const { type, expirationDate: expDate, claims: _, ...rest } = vcData;
          claims = rest;
          vcType = type || vcType;
          expirationDate = expDate || null;
        }
        // Override with explicit type and expirationDate if provided
        vcType = vcData.type || vcType;
        expirationDate = vcData.expirationDate || expirationDate;
      }

      // Create and sign W3C Verifiable Credential
      const signedVC = await createAndSignVC({
        type: vcType,
        issuer: `did:ethr:${account}`,
        credentialSubject: `did:ethr:${orgID}`,
        claims: claims,
        expirationDate: expirationDate
      }, signer);

      // Upload VC to IPFS
      const { uri } = await uploadVCToIPFS(signedVC);
      
      // Calculate hash of VC document
      const hashVC = ethers.keccak256(ethers.toUtf8Bytes(JSON.stringify(signedVC)));
      
      // Calculate expiration timestamp (0 means no expiration)
      // Handle expirationDate - can be ISO string, datetime-local string, or Date object
      let expirationTimestamp = 0;
      if (expirationDate) {
        try {
          // If it's a datetime-local format (YYYY-MM-DDTHH:mm), convert to ISO
          const date = new Date(expirationDate);
          if (!isNaN(date.getTime())) {
            expirationTimestamp = Math.floor(date.getTime() / 1000);
          }
        } catch {
          console.warn('Invalid expiration date format:', expirationDate);
        }
      }

      // Issue VC on blockchain with expiration date
      const tx = await contract.issueVCWithExpiration(orgID, hashVC, uri, expirationTimestamp);
      await tx.wait();

      set({ 
        loading: false,
        message: '✅ VC issued successfully'
      });
      return true;
    } catch (error) {
      set({ 
        loading: false, 
        error: error.message,
        message: `Error issuing VC: ${error.message}`
      });
      return false;
    }
  },

  getVCCount: async (orgID) => {
    const { contract } = get();
    if (!contract || !orgID) return 0;

    try {
      const count = await contract.getVCLength(orgID);
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
    if (!contract || !orgID) return false;

    try {
      // Verify on blockchain (checks validity, expiration, and hash)
      const isValid = await contract.verifyVC(orgID, index, providedHash);
      
      // If valid on blockchain, also verify signature from IPFS
      if (isValid) {
        try {
          const vc = await get().getVC(orgID, index);
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
        message: isValid ? '✅ VC is valid' : '❌ VC is invalid'
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
    if (!contract || !orgID) return false;

    try {
      set({ loading: true });
      const tx = await contract.revokeVC(orgID, index);
      await tx.wait();

      set({ 
        loading: false,
        message: '✅ VC revoked successfully'
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
    if (!contract || !orgID) return null;

    try {
      const vc = await contract.getVC(orgID, index);
      
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
    if (!contract || !orgID || !account) return false;

    try {
      set({ loading: true });
      const tx = await contract.verifyCredential(orgID, index);
      await tx.wait();
      set({ 
        loading: false,
        message: 'VC verified successfully'
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
    if (!contract || !orgID || !account) return false;

    try {
      set({ loading: true });
      const tx = await contract.requestVerification(
        orgID,
        vcIndex,
        targetVerifier || ethers.ZeroAddress,
        metadataUri
      );
      await tx.wait();
      set({ 
        loading: false,
        message: 'Verification request created successfully'
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
    if (!contract) return 0;

    try {
      const requestId = await contract.vcRequestId(orgID, vcIndex);
      return Number(requestId);
    } catch {
      return 0;
    }
  },

  // Kiểm tra xem VC có đang có verification request chưa được xử lý không
  hasPendingVerificationRequest: async (orgID, vcIndex) => {
    const { contract } = get();
    if (!contract) return false;

    try {
      const hasPending = await contract.hasPendingVerificationRequest(orgID, vcIndex);
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
