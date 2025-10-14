import { ethers } from 'ethers';
import { create } from 'zustand';

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
    const { contract } = get();
    if (!contract || !orgID) return false;

    try {
      set({ loading: true });
      
      // Create offchain data
      const offchainData = JSON.stringify({
        orgID,
        data,
        createdAt: Date.now()
      });

      // Upload to IPFS (simplified - you'll need to implement IPFS upload)
      const hashData = ethers.keccak256(ethers.toUtf8Bytes(offchainData));
      const uri = `ipfs://hash_${hashData.slice(2, 10)}`; // Simplified URI

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
    const { contract } = get();
    if (!contract || !orgID) return false;

    try {
      set({ loading: true });
      
      // Create VC data
      const credentialData = JSON.stringify({
        orgID,
        vcData,
        issuedAt: Date.now()
      });

      const hashVC = ethers.keccak256(ethers.toUtf8Bytes(credentialData));
      const uri = `ipfs://vc_${hashVC.slice(2, 10)}`; // Simplified URI

      const tx = await contract.issueVC(orgID, hashVC, uri);
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
    const { contract } = get();
    if (!contract || !orgID) return false;

    try {
      const isValid = await contract.verifyVC(orgID, index, providedHash);
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
    const { contract } = get();
    if (!contract || !orgID) return null;

    try {
      const vc = await contract.getVC(orgID, index);
      return {
        hashCredential: vc[0],
        uri: vc[1],
        issuer: vc[2],
        valid: vc[3]
      };
    } catch (error) {
      set({ 
        error: error.message,
        message: `Error getting VC: ${error.message}`
      });
      return null;
    }
  }
}));
