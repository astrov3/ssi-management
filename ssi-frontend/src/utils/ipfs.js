import axios from 'axios';

// Pinata API Configuration
const PINATA_API_URL = 'https://api.pinata.cloud';
const PINATA_GATEWAY_URL = 'https://gateway.pinata.cloud/ipfs';

/**
 * Get Pinata credentials from environment
 * @returns {Object} Pinata credentials
 */
const getPinataCredentials = () => {
  const PINATA_PROJECT_ID = import.meta.env.VITE_PINATA_PROJECT_ID;
  const PINATA_PROJECT_SECRET = import.meta.env.VITE_PINATA_PROJECT_SECRET;

  if (!PINATA_PROJECT_ID || !PINATA_PROJECT_SECRET) {
    throw new Error('Pinata credentials not configured. Please check your .env file.');
  }

  return {
    pinata_api_key: PINATA_PROJECT_ID,
    pinata_secret_api_key: PINATA_PROJECT_SECRET,
  };
};

/**
 * Upload JSON data to Pinata IPFS
 * @param {Object} data - Data to upload (will be JSON stringified)
 * @param {string} name - Name for the pin (optional)
 * @returns {Promise<{hash: string, uri: string}>} - IPFS hash and URI
 */
const pinJSONToPinata = async (data, name = 'ssi-data') => {
  try {
    const credentials = getPinataCredentials();
    
    // Prepare request
    const pinataContent = typeof data === 'string' ? JSON.parse(data) : data;
    
    const requestBody = {
      pinataContent: pinataContent,
      pinataMetadata: {
        name: name,
      },
    };

    // Upload to Pinata
    const response = await axios.post(
      `${PINATA_API_URL}/pinning/pinJSONToIPFS`,
      requestBody,
      {
        headers: {
          'Content-Type': 'application/json',
          ...credentials,
        },
      }
    );

    if (!response.data || !response.data.IpfsHash) {
      throw new Error('Invalid response from Pinata API');
    }

    const ipfsHash = response.data.IpfsHash;
    const uri = `ipfs://${ipfsHash}`;

    return {
      hash: ipfsHash,
      uri: uri,
    };
  } catch (error) {
    console.error('Pinata API Error:', {
      message: error.message,
      response: error.response?.data,
      status: error.response?.status,
      statusText: error.response?.statusText,
    });

    if (error.response?.status === 401) {
      throw new Error('Pinata authentication failed. Please check your API keys.');
    } else if (error.response?.status === 403) {
      throw new Error('Pinata API access denied. Please check your API key permissions.');
    } else if (error.response?.status === 429) {
      throw new Error('Pinata API rate limit exceeded. Please try again later.');
    } else if (error.response?.data?.error) {
      throw new Error(`Pinata API error: ${error.response.data.error}`);
    } else {
      throw new Error(`Failed to upload to IPFS: ${error.message}`);
    }
  }
};

/**
 * Upload data to IPFS via Pinata
 * @param {string|Object} data - Data to upload
 * @param {string} metadataName - Name for metadata (optional)
 * @returns {Promise<{hash: string, uri: string}>} - IPFS hash and URI
 */
export const uploadToIPFS = async (data, metadataName = 'ssi-data') => {
  try {
    // Convert data to object if it's a string
    let dataObject;
    if (typeof data === 'string') {
      try {
        dataObject = JSON.parse(data);
      } catch {
        // If not JSON, wrap it in an object
        dataObject = { data: data };
      }
    } else {
      dataObject = data;
    }

    return await pinJSONToPinata(dataObject, metadataName);
  } catch (error) {
    console.error('Error uploading to IPFS:', error);
    throw error;
  }
};

/**
 * Create W3C DID Document
 * @param {Object} params - DID Document parameters
 * @param {string} params.id - DID identifier (e.g., "did:ethr:0x...")
 * @param {string} params.controller - Controller address
 * @param {string} params.serviceEndpoint - Service endpoint (optional)
 * @returns {Object} W3C DID Document
 */
export const createDIDDocument = ({
  id,
  controller,
  serviceEndpoint
}) => {
  const didDocument = {
    "@context": [
      "https://www.w3.org/ns/did/v1",
      "https://w3id.org/security/suites/eip712sig-2021/v1"
    ],
    "id": id,
    "controller": controller,
    "verificationMethod": [
      {
        "id": `${id}#keys-1`,
        "type": "EcdsaSecp256k1RecoveryMethod2020",
        "controller": controller,
        "blockchainAccountId": `eip155:1:${controller}`
      }
    ],
    "created": new Date().toISOString(),
    "updated": new Date().toISOString()
  };

  if (serviceEndpoint) {
    didDocument.service = [
      {
        "id": `${id}#service-1`,
        "type": "LinkedDomains",
        "serviceEndpoint": serviceEndpoint
      }
    ];
  }

  return didDocument;
};

/**
 * Upload DID Document to IPFS
 * @param {Object} didDocument - W3C DID Document
 * @returns {Promise<{hash: string, uri: string}>} - IPFS hash and URI
 */
export const uploadDIDDocumentToIPFS = async (didDocument) => {
  return await uploadToIPFS(didDocument, 'did-document');
};

/**
 * Upload DID data to IPFS (legacy support)
 * @param {Object} didData - DID data object
 * @returns {Promise<{hash: string, uri: string}>} - IPFS hash and URI
 */
export const uploadDIDToIPFS = async (didData) => {
  // If didData is already a DID Document, upload it directly
  if (didData["@context"] && didData.id) {
    return await uploadToIPFS(didData, 'did-document');
  }

  // Otherwise, create a DID Document from legacy data
  const didDocument = createDIDDocument({
    id: didData.id || `did:ethr:${didData.orgID || didData.owner}`,
    controller: didData.owner || didData.controller,
    serviceEndpoint: didData.serviceEndpoint
  });

  return await uploadToIPFS(didDocument, 'did-document');
};

/**
 * Upload Verifiable Credential to IPFS
 * @param {Object} vc - W3C Verifiable Credential
 * @returns {Promise<{hash: string, uri: string}>} - IPFS hash and URI
 */
export const uploadVCToIPFS = async (vc) => {
  // Validate that vc is a W3C VC structure
  if (!vc["@context"] || !vc.type || !vc.issuer || !vc.credentialSubject) {
    throw new Error('Invalid VC structure. Expected W3C Verifiable Credential format.');
  }

  // Upload VC to IPFS
  return await uploadToIPFS(vc, 'verifiable-credential');
};

/**
 * Upload a binary file to IPFS via Pinata
 * @param {File} file - Browser File instance
 * @param {string} metadataName - Optional name for the pin
 * @returns {Promise<{hash: string, uri: string, fileName: string}>}
 */
export const uploadFileToIPFS = async (file, metadataName = 'ssi-file') => {
  if (!file) {
    throw new Error('No file provided for IPFS upload');
  }

  try {
    const credentials = getPinataCredentials();
    const formData = new FormData();
    formData.append('file', file, file.name);

    const metadata = {
      name: `${metadataName}-${Date.now()}`,
    };

    formData.append('pinataMetadata', JSON.stringify(metadata));
    formData.append('pinataOptions', JSON.stringify({ cidVersion: 1 }));

    const response = await axios.post(
      `${PINATA_API_URL}/pinning/pinFileToIPFS`,
      formData,
      {
        maxContentLength: Infinity,
        headers: {
          ...credentials,
        },
      }
    );

    if (!response.data?.IpfsHash) {
      throw new Error('Invalid Pinata response when uploading file');
    }

    const ipfsHash = response.data.IpfsHash;
    return {
      hash: ipfsHash,
      uri: `ipfs://${ipfsHash}`,
      fileName: file.name,
    };
  } catch (error) {
    console.error('Failed to upload file to IPFS:', error);
    if (error.response?.status === 413) {
      throw new Error('File is too large to upload to IPFS via Pinata.');
    }
    throw new Error(error.message || 'File upload to IPFS failed.');
  }
};

/**
 * Retrieve data from IPFS via Pinata Gateway
 * @param {string} hash - IPFS hash or URI
 * @returns {Promise<string>} - Retrieved data as string
 */
export const retrieveFromIPFS = async (hash) => {
  try {
    // Remove 'ipfs://' prefix if present and get clean hash
    const cleanHash = hash.replace('ipfs://', '').split('/')[0];
    
    if (!cleanHash) {
      throw new Error('Invalid IPFS hash');
    }

    // Retrieve from Pinata Gateway
    const gatewayUrl = `${PINATA_GATEWAY_URL}/${cleanHash}`;
    
    const response = await axios.get(gatewayUrl, {
      timeout: 10000, // 10 second timeout
      headers: {
        'Accept': 'application/json',
      },
    });

    // If response is already a string, return it
    if (typeof response.data === 'string') {
      return response.data;
    }

    // Otherwise, stringify it
    return JSON.stringify(response.data);
  } catch (error) {
    console.error('Error retrieving from IPFS:', {
      hash: hash,
      message: error.message,
      response: error.response?.data,
      status: error.response?.status,
    });

    if (error.response?.status === 404) {
      throw new Error(`IPFS content not found: ${hash}. The content may not be pinned or may have been removed.`);
    } else if (error.code === 'ECONNABORTED') {
      throw new Error(`IPFS request timeout. Please try again later.`);
    } else {
      throw new Error(`Failed to retrieve from IPFS: ${error.message}`);
    }
  }
};

/**
 * Retrieve and parse JSON from IPFS
 * @param {string} hash - IPFS hash or URI
 * @returns {Promise<Object>} - Parsed JSON object
 */
export const retrieveJSONFromIPFS = async (hash) => {
  try {
    // Remove 'ipfs://' prefix if present and get clean hash
    const cleanHash = hash.replace('ipfs://', '').split('/')[0];
    
    if (!cleanHash) {
      throw new Error('Invalid IPFS hash');
    }

    // Retrieve from Pinata Gateway
    const gatewayUrl = `${PINATA_GATEWAY_URL}/${cleanHash}`;
    
    const response = await axios.get(gatewayUrl, {
      timeout: 10000, // 10 second timeout
      headers: {
        'Accept': 'application/json',
      },
    });

    // Return parsed JSON (axios automatically parses JSON responses)
    return response.data;
  } catch (error) {
    console.error('Error retrieving JSON from IPFS:', {
      hash: hash,
      message: error.message,
      response: error.response?.data,
      status: error.response?.status,
    });

    if (error.response?.status === 404) {
      throw new Error(`IPFS content not found: ${hash}. The content may not be pinned or may have been removed.`);
    } else if (error.response?.status === 400) {
      throw new Error(`Invalid IPFS content: ${hash}. The content may not be valid JSON.`);
    } else if (error.code === 'ECONNABORTED') {
      throw new Error(`IPFS request timeout. Please try again later.`);
    } else {
      throw new Error(`Failed to retrieve JSON from IPFS: ${error.message}`);
    }
  }
};

/**
 * Validate IPFS URI
 * @param {string} uri - IPFS URI
 * @returns {boolean} - Whether the URI is valid
 */
export const isValidIPFSUri = (uri) => {
  return typeof uri === 'string' && (uri.startsWith('ipfs://') || uri.startsWith('Qm') || uri.startsWith('baf'));
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
  
  // Remove ipfs:// prefix if present
  const hash = uri.replace('ipfs://', '').split('/')[0];
  return hash;
};

/**
 * Get Pinata Gateway URL for an IPFS hash
 * @param {string} hash - IPFS hash or URI
 * @returns {string} - Gateway URL
 */
export const getPinataGatewayURL = (hash) => {
  const cleanHash = extractIPFSHash(hash);
  return `${PINATA_GATEWAY_URL}/${cleanHash}`;
};
