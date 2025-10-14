import { create } from 'ipfs-http-client';

// Initialize IPFS client with Pinata
const getIPFSClient = () => {
  const PINATA_PROJECT_ID = import.meta.env.VITE_PINATA_PROJECT_ID;
  const PINATA_PROJECT_SECRET = import.meta.env.VITE_PINATA_PROJECT_SECRET;

  if (!PINATA_PROJECT_ID || !PINATA_PROJECT_SECRET) {
    throw new Error('Pinata credentials not configured');
  }

  const auth = 'Basic ' + btoa(PINATA_PROJECT_ID + ':' + PINATA_PROJECT_SECRET).toString('base64');

  return create({
    host: 'api.pinata.cloud',
    port: 443,
    protocol: 'https',
    headers: {
      authorization: auth,
    },
  });
};

/**
 * Upload data to IPFS
 * @param {string|Object} data - Data to upload
 * @returns {Promise<{hash: string, uri: string}>} - IPFS hash and URI
 */
export const uploadToIPFS = async (data) => {
  try {
    const ipfs = getIPFSClient();
    
    // Convert object to string if needed
    const dataString = typeof data === 'string' ? data : JSON.stringify(data);
    
    const added = await ipfs.add(dataString);
    const uri = 'ipfs://' + added.path;
    
    return {
      hash: added.path,
      uri: uri
    };
  } catch (error) {
    console.error('Error uploading to IPFS:', error);
    throw new Error('Failed to upload to IPFS');
  }
};

/**
 * Upload DID data to IPFS
 * @param {Object} didData - DID data object
 * @returns {Promise<{hash: string, uri: string}>} - IPFS hash and URI
 */
export const uploadDIDToIPFS = async (didData) => {
  const data = {
    type: 'DID',
    orgID: didData.orgID,
    owner: didData.owner,
    data: didData.data,
    createdAt: Date.now(),
    metadata: {
      version: '1.0',
      schema: 'DID'
    }
  };

  return uploadToIPFS(data);
};

/**
 * Upload VC data to IPFS
 * @param {Object} vcData - VC data object
 * @returns {Promise<{hash: string, uri: string}>} - IPFS hash and URI
 */
export const uploadVCToIPFS = async (vcData) => {
  const data = {
    type: 'VC',
    orgID: vcData.orgID,
    issuer: vcData.issuer,
    credential: vcData.credential,
    issuedAt: Date.now(),
    metadata: {
      version: '1.0',
      schema: 'VC'
    }
  };

  return uploadToIPFS(data);
};

/**
 * Retrieve data from IPFS
 * @param {string} hash - IPFS hash
 * @returns {Promise<string>} - Retrieved data
 */
export const retrieveFromIPFS = async (hash) => {
  try {
    const ipfs = getIPFSClient();
    
    // Remove 'ipfs://' prefix if present
    const cleanHash = hash.replace('ipfs://', '');
    
    const chunks = [];
    for await (const chunk of ipfs.cat(cleanHash)) {
      chunks.push(chunk);
    }
    
    const data = new TextDecoder().decode(Buffer.concat(chunks));
    return data;
  } catch (error) {
    console.error('Error retrieving from IPFS:', error);
    throw new Error('Failed to retrieve from IPFS');
  }
};

/**
 * Validate IPFS URI
 * @param {string} uri - IPFS URI
 * @returns {boolean} - Whether the URI is valid
 */
export const isValidIPFSUri = (uri) => {
  return typeof uri === 'string' && uri.startsWith('ipfs://');
};

/**
 * Extract hash from IPFS URI
 * @param {string} uri - IPFS URI
 * @returns {string} - IPFS hash
 */
export const extractIPFSHash = (uri) => {
  if (!isValidIPFSUri(uri)) {
    throw new Error('Invalid IPFS URI');
  }
  
  return uri.replace('ipfs://', '');
};
