import { ethers } from 'ethers';

/**
 * Create W3C Verifiable Credential structure
 * @param {Object} params - VC parameters
 * @param {string} params.type - VC type (e.g., "EducationalCredential")
 * @param {string} params.issuer - Issuer DID or address
 * @param {string} params.credentialSubject - Subject DID or address
 * @param {Object} params.claims - Credential claims/data
 * @param {string} params.expirationDate - Expiration date (ISO string)
 * @param {string} params.id - VC ID (optional)
 * @returns {Object} W3C VC structure
 */
export const createVerifiableCredential = ({
  type,
  issuer,
  credentialSubject,
  claims,
  expirationDate,
  id
}) => {
  const vcId = id || `vc:${Date.now()}:${Math.random().toString(36).substring(7)}`;
  
  const vc = {
    "@context": [
      "https://www.w3.org/2018/credentials/v1",
      "https://www.w3.org/2018/credentials/examples/v1"
    ],
    "id": vcId,
    "type": ["VerifiableCredential", type || "Credential"],
    "issuer": issuer,
    "issuanceDate": new Date().toISOString(),
    "credentialSubject": {
      "id": credentialSubject,
      ...claims
    }
  };

  if (expirationDate) {
    // Ensure expirationDate is in ISO format
    try {
      const date = new Date(expirationDate);
      if (!isNaN(date.getTime())) {
        vc.expirationDate = date.toISOString();
      }
    } catch {
      console.warn('Invalid expiration date format:', expirationDate);
    }
  }

  return vc;
};

/**
 * Get EIP-712 domain for VC signing
 * @param {Object} signer - Ethers signer
 * @returns {Promise<Object>} EIP-712 domain
 */
const getChainIdFromSigner = async (signer) => {
  if (!signer) {
    throw new Error('No signer available');
  }

  // 1. Native getChainId if available (some wallet adapters expose it)
  if (typeof signer.getChainId === 'function') {
    try {
      return await signer.getChainId();
    } catch (error) {
      console.warn('signer.getChainId() failed, falling back to provider network lookup', error);
    }
  }

  const provider = signer.provider;

  if (!provider) {
    throw new Error('Signer is missing provider');
  }

  // 2. Ethers v6 provider.getNetwork()
  if (typeof provider.getNetwork === 'function') {
    const network = await provider.getNetwork();
    if (network?.chainId) {
      return typeof network.chainId === 'bigint'
        ? Number(network.chainId)
        : network.chainId;
    }
  }

  // 3. Low-level RPC call
  if (typeof provider.send === 'function') {
    const chainIdHex = await provider.send('eth_chainId', []);
    if (chainIdHex) {
      return Number.parseInt(chainIdHex, 16);
    }
  }

  throw new Error('Unable to determine chainId from signer');
};

export const getVCDomain = async (signer) => {
  const chainId = await getChainIdFromSigner(signer);
  const contractAddress = import.meta.env.VITE_CONTRACT_ADDRESS;

  if (!contractAddress) {
    throw new Error('Contract address not configured in environment (VITE_CONTRACT_ADDRESS)');
  }

  return {
    name: "SSI Identity Manager",
    version: "1",
    chainId: chainId,
    verifyingContract: contractAddress
  };
};

/**
 * Get EIP-712 types for VC signing
 * @param {Object} vc - Verifiable Credential
 * @returns {Object} EIP-712 types
 */
export const getVCTypes = (vc) => {
  // Get all keys from credentialSubject (excluding 'id')
  const subjectKeys = Object.keys(vc.credentialSubject).filter(key => key !== 'id');
  
  // Build CredentialSubject type dynamically
  const credentialSubjectType = [
    { name: "id", type: "string" },
    ...subjectKeys.map(key => ({
      name: key,
      type: typeof vc.credentialSubject[key] === 'string' ? "string" : 
            typeof vc.credentialSubject[key] === 'number' ? "uint256" :
            "string" // Default to string for complex types
    }))
  ];

  return {
    VerifiableCredential: [
      { name: "@context", type: "string[]" },
      { name: "id", type: "string" },
      { name: "type", type: "string[]" },
      { name: "issuer", type: "string" },
      { name: "issuanceDate", type: "string" },
      { name: "expirationDate", type: "string" },
      { name: "credentialSubject", type: "CredentialSubject" }
    ],
    CredentialSubject: credentialSubjectType
  };
};

/**
 * Sign Verifiable Credential with EIP-712
 * @param {Object} vc - Verifiable Credential (without proof)
 * @param {Object} signer - Ethers signer
 * @returns {Promise<string>} Signature
 */
export const signVCWithEIP712 = async (vc, signer) => {
  try {
    const domain = await getVCDomain(signer);
    const types = getVCTypes(vc);

    // Prepare value for signing (exclude proof if present)
    const value = {
      "@context": vc["@context"],
      "id": vc.id,
      "type": vc.type,
      "issuer": vc.issuer,
      "issuanceDate": vc.issuanceDate,
      "expirationDate": vc.expirationDate || "",
      "credentialSubject": vc.credentialSubject
    };

    // Sign with EIP-712
    const signature = await signer.signTypedData(domain, types, value);
    return signature;
  } catch (error) {
    console.error('Error signing VC:', error);
    throw new Error(`Failed to sign VC: ${error.message}`);
  }
};

/**
 * Add proof to Verifiable Credential
 * @param {Object} vc - Verifiable Credential
 * @param {string} signature - EIP-712 signature
 * @param {string} verificationMethod - Verification method (e.g., "did:ethr:0x...#keys-1")
 * @returns {Object} VC with proof
 */
export const addProofToVC = (vc, signature, verificationMethod) => {
  return {
    ...vc,
    "proof": {
      "type": "EthereumEip712Signature2021",
      "created": new Date().toISOString(),
      "proofPurpose": "assertionMethod",
      "verificationMethod": verificationMethod,
      "proofValue": signature
    }
  };
};

/**
 * Create and sign Verifiable Credential
 * @param {Object} params - VC parameters
 * @param {Object} signer - Ethers signer
 * @returns {Promise<Object>} Signed VC
 */
export const createAndSignVC = async (params, signer) => {
  // Create VC structure
  const vc = createVerifiableCredential(params);
  
  // Sign VC
  const signature = await signVCWithEIP712(vc, signer);
  
  // Get issuer address for verification method
  const issuerAddress = await signer.getAddress();
  const verificationMethod = `did:ethr:${issuerAddress}#keys-1`;
  
  // Add proof
  const signedVC = addProofToVC(vc, signature, verificationMethod);
  
  return signedVC;
};

/**
 * Verify VC signature
 * @param {Object} vc - Verifiable Credential with proof
 * @param {Object} signer - Ethers signer (for domain)
 * @param {string} expectedIssuer - Expected issuer address
 * @returns {Promise<boolean>} True if signature is valid
 */
export const verifyVCSignature = async (vc, signer, expectedIssuer) => {
  try {
    if (!vc.proof || !vc.proof.proofValue) {
      return false;
    }

    const domain = await getVCDomain(signer);
    const types = getVCTypes(vc);

    // Prepare value for verification
    const value = {
      "@context": vc["@context"],
      "id": vc.id,
      "type": vc.type,
      "issuer": vc.issuer,
      "issuanceDate": vc.issuanceDate,
      "expirationDate": vc.expirationDate || "",
      "credentialSubject": vc.credentialSubject
    };

    // Verify signature
    const recoveredAddress = ethers.verifyTypedData(
      domain,
      types,
      value,
      vc.proof.proofValue
    );

    return recoveredAddress.toLowerCase() === expectedIssuer.toLowerCase();
  } catch (error) {
    console.error('Error verifying VC signature:', error);
    return false;
  }
};

/**
 * Check if VC is expired
 * @param {Object} vc - Verifiable Credential
 * @returns {boolean} True if VC is expired
 */
export const isVCExpired = (vc) => {
  if (!vc.expirationDate) {
    return false; // No expiration date means never expires
  }

  const expirationDate = new Date(vc.expirationDate);
  const now = new Date();
  
  return now > expirationDate;
};

/**
 * Validate VC structure
 * @param {Object} vc - Verifiable Credential
 * @returns {boolean} True if VC structure is valid
 */
export const validateVCStructure = (vc) => {
  // Check required fields
  if (!vc["@context"] || !Array.isArray(vc["@context"])) {
    return false;
  }

  if (!vc.type || !Array.isArray(vc.type)) {
    return false;
  }

  if (!vc.issuer) {
    return false;
  }

  if (!vc.issuanceDate) {
    return false;
  }

  if (!vc.credentialSubject || !vc.credentialSubject.id) {
    return false;
  }

  return true;
};

/**
 * Parse VC from JSON string
 * @param {string} jsonString - VC JSON string
 * @returns {Object} Parsed VC
 */
export const parseVC = (jsonString) => {
  try {
    const vc = JSON.parse(jsonString);
    if (!validateVCStructure(vc)) {
      throw new Error('Invalid VC structure');
    }
    return vc;
  } catch (error) {
    throw new Error(`Failed to parse VC: ${error.message}`);
  }
};

/**
 * Convert VC to JSON string
 * @param {Object} vc - Verifiable Credential
 * @returns {string} VC JSON string
 */
export const vcToJSON = (vc) => {
  return JSON.stringify(vc, null, 2);
};

