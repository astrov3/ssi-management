import QRCode from 'qrcode';

/**
 * Generate QR code from data
 * @param {string} data - Data to encode in QR code
 * @param {Object} options - QR code options
 * @returns {Promise<string>} - Data URL of the QR code
 */
export const generateQRCode = async (data, options = {}) => {
  const defaultOptions = {
    width: import.meta.env.VITE_QR_CODE_SIZE || 200,
    margin: 2,
    color: {
      dark: '#000000',
      light: '#FFFFFF'
    },
    errorCorrectionLevel: import.meta.env.VITE_QR_CODE_ERROR_CORRECTION_LEVEL || 'M'
  };

  try {
    const qrCodeDataURL = await QRCode.toDataURL(data, {
      ...defaultOptions,
      ...options
    });
    return qrCodeDataURL;
  } catch (error) {
    console.error('Error generating QR code:', error);
    throw new Error('Failed to generate QR code');
  }
};

/**
 * Generate QR code for DID
 * @param {Object} didData - DID data object
 * @returns {Promise<string>} - Data URL of the QR code
 */
export const generateDIDQRCode = async (didData) => {
  const qrData = {
    type: 'DID',
    orgID: didData.orgID,
    owner: didData.owner,
    hashData: didData.hashData,
    uri: didData.uri,
    active: didData.active,
    timestamp: Date.now()
  };

  return generateQRCode(JSON.stringify(qrData));
};

/**
 * Generate QR code for VC
 * @param {Object} vcData - VC data object
 * @returns {Promise<string>} - Data URL of the QR code
 */
export const generateVCQRCode = async (vcData) => {
  const qrData = {
    type: 'VC',
    orgID: vcData.orgID,
    hashCredential: vcData.hashCredential,
    issuer: vcData.issuer,
    uri: vcData.uri,
    valid: vcData.valid,
    timestamp: Date.now()
  };

  return generateQRCode(JSON.stringify(qrData));
};

/**
 * Generate QR code for verification request
 * @param {string} orgID - Organization ID
 * @param {number} vcIndex - VC index
 * @returns {Promise<string>} - Data URL of the QR code
 */
export const generateVerificationQRCode = async (orgID, vcIndex) => {
  const qrData = {
    type: 'VERIFICATION_REQUEST',
    orgID,
    vcIndex,
    timestamp: Date.now()
  };

  return generateQRCode(JSON.stringify(qrData));
};

/**
 * Parse QR code data
 * @param {string} qrData - QR code data string
 * @returns {Object} - Parsed QR code data
 */
export const parseQRCodeData = (qrData) => {
  try {
    const parsed = JSON.parse(qrData);
    
    // Validate QR code type
    if (!parsed.type || !['DID', 'VC', 'VERIFICATION_REQUEST'].includes(parsed.type)) {
      throw new Error('Invalid QR code type');
    }

    return parsed;
  } catch (error) {
    console.error('Error parsing QR code data:', error);
    throw new Error('Invalid QR code data format');
  }
};

/**
 * Validate QR code data structure
 * @param {Object} data - Parsed QR code data
 * @returns {boolean} - Whether the data is valid
 */
export const validateQRCodeData = (data) => {
  if (!data || typeof data !== 'object') {
    return false;
  }

  const requiredFields = {
    'DID': ['type', 'orgID', 'owner', 'hashData', 'uri', 'active'],
    'VC': ['type', 'orgID', 'hashCredential', 'issuer', 'uri', 'valid'],
    'VERIFICATION_REQUEST': ['type', 'orgID', 'vcIndex']
  };

  const fields = requiredFields[data.type];
  if (!fields) {
    return false;
  }

  return fields.every(field => data.hasOwnProperty(field));
};
