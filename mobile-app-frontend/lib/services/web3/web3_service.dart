import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bip39/bip39.dart' as bip39;
import 'package:eth_sig_util/eth_sig_util.dart';
import 'package:eth_sig_util/model/typed_data.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' show Client;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/web3dart.dart';

import 'package:ssi_app/config/environment.dart';
import 'package:ssi_app/services/wallet/wallet_connect_service.dart';
import 'package:ssi_app/services/wallet/wallet_name_service.dart';

class Web3Service {
  Web3Service({
    Client? httpClient,
    WalletConnectService? walletConnectService,
  })  : _httpClient = httpClient ?? Client(),
        _walletConnectService = walletConnectService ?? WalletConnectService() {
    _client = Web3Client(Environment.rpcUrl, _httpClient);
    _contract = DeployedContract(
      ContractAbi.fromJson(_contractAbi, 'IdentityManager'),
      EthereumAddress.fromHex(Environment.contractAddress),
    );
  }

  final Client _httpClient;
  late final Web3Client _client;
  late final DeployedContract _contract;
  Credentials? _credentials;
  final WalletConnectService _walletConnectService;
  static const _secureStorage = FlutterSecureStorage();
  
  /// Check if using WalletConnect (no private key available)
  /// Returns true only if there's an ACTIVE WalletConnect session (not just stored address)
  /// This ensures transactions can be sent via WalletConnect
  Future<bool> _isUsingWalletConnect() async {
    // Check if we have private key credentials
    if (_credentials != null) return false;
    
    // Try to load private key
    final privateKeyHex = await _secureStorage.read(key: 'privateKey');
    if (privateKeyHex != null) return false;
    
    // Check if WalletConnect has an ACTIVE session (required for transactions)
    // Note: isConnected() returns true even with just stored address, but we need active session for transactions
    return await _walletConnectService.hasActiveSession();
  }
  
  /// Get current address from either private key or WalletConnect
  Future<String?> getCurrentAddress() async {
    // Try private key first
    final pkAddress = await loadWallet();
    if (pkAddress != null) return pkAddress;
    
    // Try WalletConnect
    return await _walletConnectService.getStoredAddress();
  }

  static const String _contractAbi = '''
  [
    {
      "inputs": [],
      "name": "admin",
      "outputs": [{"internalType": "address","name": "","type": "address"}],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [{"internalType": "string","name": "orgID","type": "string"},{"internalType": "address","name": "issuer","type": "address"}],
      "name": "authorizeIssuer",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [{"internalType": "string","name": "","type": "string"},{"internalType": "address","name": "","type": "address"}],
      "name": "authorizedIssuers",
      "outputs": [{"internalType": "bool","name": "","type": "bool"}],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [{"internalType": "uint256","name": "requestId","type": "uint256"}],
      "name": "cancelVerificationRequest",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [{"internalType": "string","name": "","type": "string"},{"internalType": "uint256","name": "","type": "uint256"}],
      "name": "credentials",
      "outputs": [
        {"internalType": "bytes32","name": "hashCredential","type": "bytes32"},
        {"internalType": "string","name": "uri","type": "string"},
        {"internalType": "address","name": "issuer","type": "address"},
        {"internalType": "bool","name": "valid","type": "bool"},
        {"internalType": "uint256","name": "expirationDate","type": "uint256"},
        {"internalType": "uint256","name": "issuedAt","type": "uint256"},
        {"internalType": "bool","name": "verified","type": "bool"},
        {"internalType": "address","name": "verifier","type": "address"},
        {"internalType": "uint256","name": "verifiedAt","type": "uint256"}
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [{"internalType": "string","name": "orgID","type": "string"}],
      "name": "deactivateDID",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [{"internalType": "string","name": "","type": "string"}],
      "name": "dids",
      "outputs": [
        {"internalType": "address","name": "owner","type": "address"},
        {"internalType": "bytes32","name": "hashData","type": "bytes32"},
        {"internalType": "string","name": "uri","type": "string"},
        {"internalType": "bool","name": "active","type": "bool"}
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [{"internalType": "string","name": "orgID","type": "string"},{"internalType": "uint256","name": "index","type": "uint256"}],
      "name": "getVC",
      "outputs": [
        {"internalType": "bytes32","name": "hashCredential","type": "bytes32"},
        {"internalType": "string","name": "uri","type": "string"},
        {"internalType": "address","name": "issuer","type": "address"},
        {"internalType": "bool","name": "valid","type": "bool"},
        {"internalType": "uint256","name": "expirationDate","type": "uint256"},
        {"internalType": "uint256","name": "issuedAt","type": "uint256"},
        {"internalType": "bool","name": "verified","type": "bool"},
        {"internalType": "address","name": "verifier","type": "address"},
        {"internalType": "uint256","name": "verifiedAt","type": "uint256"}
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [{"internalType": "string","name": "orgID","type": "string"}],
      "name": "getVCLength",
      "outputs": [{"internalType": "uint256","name": "","type": "uint256"}],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [{"internalType": "string","name": "orgID","type": "string"},{"internalType": "uint256","name": "vcIndex","type": "uint256"}],
      "name": "getVCRequestId",
      "outputs": [{"internalType": "uint256","name": "","type": "uint256"}],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [{"internalType": "uint256","name": "requestId","type": "uint256"}],
      "name": "getVerificationRequest",
      "outputs": [
        {"internalType": "string","name": "orgID","type": "string"},
        {"internalType": "uint256","name": "vcIndex","type": "uint256"},
        {"internalType": "address","name": "requester","type": "address"},
        {"internalType": "address","name": "targetVerifier","type": "address"},
        {"internalType": "string","name": "metadataUri","type": "string"},
        {"internalType": "uint256","name": "requestedAt","type": "uint256"},
        {"internalType": "bool","name": "processed","type": "bool"}
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [{"internalType": "string","name": "orgID","type": "string"},{"internalType": "uint256","name": "vcIndex","type": "uint256"}],
      "name": "hasPendingVerificationRequest",
      "outputs": [{"internalType": "bool","name": "","type": "bool"}],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [{"internalType": "string","name": "orgID","type": "string"},{"internalType": "bytes32","name": "hashCredential","type": "bytes32"},{"internalType": "string","name": "uri","type": "string"}],
      "name": "issueVC",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [{"internalType": "string","name": "orgID","type": "string"},{"internalType": "bytes32","name": "hashCredential","type": "bytes32"},{"internalType": "string","name": "uri","type": "string"},{"internalType": "uint256","name": "expirationDate","type": "uint256"}],
      "name": "issueVCWithExpiration",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "nextRequestId",
      "outputs": [{"internalType": "uint256","name": "","type": "uint256"}],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [{"internalType": "string","name": "orgID","type": "string"},{"internalType": "bytes32","name": "hashData","type": "bytes32"},{"internalType": "string","name": "uri","type": "string"}],
      "name": "registerDID",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [{"internalType": "string","name": "orgID","type": "string"},{"internalType": "uint256","name": "vcIndex","type": "uint256"},{"internalType": "address","name": "targetVerifier","type": "address"},{"internalType": "string","name": "metadataUri","type": "string"}],
      "name": "requestVerification",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [{"internalType": "string","name": "orgID","type": "string"},{"internalType": "uint256","name": "index","type": "uint256"}],
      "name": "revokeVC",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [{"internalType": "address","name": "newAdmin","type": "address"}],
      "name": "setAdmin",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [{"internalType": "address","name": "verifier","type": "address"},{"internalType": "bool","name": "allowed","type": "bool"}],
      "name": "setTrustedVerifier",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [{"internalType": "address","name": "","type": "address"}],
      "name": "trustedVerifiers",
      "outputs": [{"internalType": "bool","name": "","type": "bool"}],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [{"internalType": "string","name": "orgID","type": "string"},{"internalType": "bytes32","name": "newHash","type": "bytes32"},{"internalType": "string","name": "newUri","type": "string"}],
      "name": "updateDID",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [{"internalType": "string","name": "","type": "string"},{"internalType": "uint256","name": "","type": "uint256"}],
      "name": "vcRequestId",
      "outputs": [{"internalType": "uint256","name": "","type": "uint256"}],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [{"internalType": "uint256","name": "","type": "uint256"}],
      "name": "verificationRequests",
      "outputs": [
        {"internalType": "string","name": "orgID","type": "string"},
        {"internalType": "uint256","name": "vcIndex","type": "uint256"},
        {"internalType": "address","name": "requester","type": "address"},
        {"internalType": "address","name": "targetVerifier","type": "address"},
        {"internalType": "string","name": "metadataUri","type": "string"},
        {"internalType": "uint256","name": "requestedAt","type": "uint256"},
        {"internalType": "bool","name": "processed","type": "bool"}
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [{"internalType": "string","name": "orgID","type": "string"},{"internalType": "uint256","name": "index","type": "uint256"}],
      "name": "verifyCredential",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [{"internalType": "string","name": "orgID","type": "string"},{"internalType": "uint256","name": "index","type": "uint256"},{"internalType": "bytes32","name": "providedHash","type": "bytes32"}],
      "name": "verifyVC",
      "outputs": [{"internalType": "bool","name": "","type": "bool"}],
      "stateMutability": "view",
      "type": "function"
    }
  ]
  ''';

  Future<String> importWallet(String privateKeyOrMnemonic) async {
    try {
      final privateKey = await _deriveCredentials(privateKeyOrMnemonic);
      final address = privateKey.address;

      // Store sensitive data in secure storage
      await _secureStorage.write(key: 'privateKey', value: _bytesToHex(privateKey.privateKey));
      
      // If it's a mnemonic, store it too
      if (privateKeyOrMnemonic.split(' ').length > 1) {
        await _secureStorage.write(key: 'mnemonic', value: privateKeyOrMnemonic);
      }
      
      // Store non-sensitive data in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('address', address.hex);

      _credentials = privateKey;
      return address.hex;
    } catch (e) {
      throw Exception('Invalid private key or mnemonic: $e');
    }
  }

  Future<String?> loadWallet() async {
    // Try to load from secure storage first
    final privateKeyHex = await _secureStorage.read(key: 'privateKey');
    if (privateKeyHex == null) {
      // Fallback to SharedPreferences for backward compatibility
      final prefs = await SharedPreferences.getInstance();
      final oldPrivateKeyHex = prefs.getString('privateKey');
      if (oldPrivateKeyHex == null) return null;
      
      // Migrate to secure storage
      await _secureStorage.write(key: 'privateKey', value: oldPrivateKeyHex);
      await prefs.remove('privateKey');
      
      final credentials = EthPrivateKey.fromHex(oldPrivateKeyHex);
      final address = credentials.address;
      _credentials = credentials;
      return address.hex;
    }

    final credentials = EthPrivateKey.fromHex(privateKeyHex);
    final address = credentials.address;
    _credentials = credentials;
    return address.hex;
  }

  Future<void> clearWalletData({bool clearWalletConnect = true}) async {
    try {
      await _secureStorage.delete(key: 'privateKey');
    } catch (e) {
      debugPrint('[Web3Service] Error clearing private key from secure storage: $e');
    }

    try {
      await _secureStorage.delete(key: 'mnemonic');
    } catch (e) {
      debugPrint('[Web3Service] Error clearing mnemonic from secure storage: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    final address = prefs.getString('address');

    await prefs.remove('address');
    await prefs.remove('mnemonic');
    await prefs.remove('privateKey');

    if (address != null && address.isNotEmpty) {
      try {
        final walletNameService = WalletNameService();
        await walletNameService.deleteWalletName(address);
      } catch (e) {
        debugPrint('[Web3Service] Error clearing wallet name: $e');
      }
    }

    _credentials = null;

    if (clearWalletConnect) {
      try {
        await _walletConnectService.disconnect(clearStoredData: true);
      } catch (e) {
        debugPrint('[Web3Service] Error disconnecting WalletConnect during clear: $e');
      }
    }
  }

  Future<Map<String, dynamic>> createAndSignVC({
    required String orgID,
    required Map<String, dynamic> claims,
    String vcType = 'Credential',
    String? expirationDateIso,
  }) async {
    // Get issuer address from either private key or WalletConnect
    final isWC = await _isUsingWalletConnect();
    String issuerAddress;
    String issuerDid;
    
    if (isWC) {
      final address = await _walletConnectService.getStoredAddress();
      if (address == null) {
        throw StateError('WalletConnect address not found');
      }
      issuerAddress = address;
      // Convert to EIP-55 format (checksummed)
      issuerDid = 'did:ethr:${EthereumAddress.fromHex(issuerAddress).hexEip55}';
    } else {
      final credentials = await _requireCredentials() as EthPrivateKey;
      issuerAddress = credentials.address.hex;
      issuerDid = 'did:ethr:${credentials.address.hexEip55}';
    }
    
    final subjectDid = 'did:ethr:$orgID';

    final now = DateTime.now().toUtc();
    final issuanceDate = now.toIso8601String();
    final contexts = [
      'https://www.w3.org/2018/credentials/v1',
      'https://www.w3.org/2018/credentials/examples/v1',
    ];
    final vcTypes = ['VerifiableCredential', vcType];
    final normalizedClaims = _normalizeClaims(claims);
    final credentialSubject = <String, String>{
      'id': subjectDid,
      ...normalizedClaims,
    };

    final credentialSubjectTypes = [
      {'name': 'id', 'type': 'string'},
      for (final key in normalizedClaims.keys) {'name': key, 'type': 'string'},
    ];

    // Extract address hex (remove 0x if present, take first 8 chars)
    final addressHex = issuerAddress.replaceFirst('0x', '').substring(0, 8);
    final vcId = 'vc:${now.millisecondsSinceEpoch}:$addressHex';
    final expirationValue = expirationDateIso ?? '';

    final typedData = {
      'types': {
        'EIP712Domain': [
          {'name': 'name', 'type': 'string'},
          {'name': 'version', 'type': 'string'},
          {'name': 'chainId', 'type': 'uint256'},
          {'name': 'verifyingContract', 'type': 'address'},
        ],
        'CredentialSubject': credentialSubjectTypes,
        'VerifiableCredential': [
          {'name': '@context', 'type': 'string[]'},
          {'name': 'id', 'type': 'string'},
          {'name': 'type', 'type': 'string[]'},
          {'name': 'issuer', 'type': 'string'},
          {'name': 'issuanceDate', 'type': 'string'},
          {'name': 'expirationDate', 'type': 'string'},
          {'name': 'credentialSubject', 'type': 'CredentialSubject'},
        ],
      },
      'primaryType': 'VerifiableCredential',
      'domain': {
        'name': 'SSI Identity Manager',
        'version': '1',
        'chainId': Environment.chainId,
        'verifyingContract': Environment.contractAddress,
      },
      'message': {
        '@context': contexts,
        'id': vcId,
        'type': vcTypes,
        'issuer': issuerDid,
        'issuanceDate': issuanceDate,
        'expirationDate': expirationValue,
        'credentialSubject': credentialSubject,
      },
    };

    // Sign using either private key or WalletConnect
    String signature;
    if (isWC) {
      // Use WalletConnect to sign EIP-712 typed data
      signature = await _walletConnectService.signTypedData(jsonEncode(typedData));
    } else {
      final credentials = await _requireCredentials() as EthPrivateKey;
      final privateKeyHex = _bytesToHex(credentials.privateKey).substring(2);
      signature = EthSigUtil.signTypedData(
        privateKey: privateKeyHex,
        jsonData: jsonEncode(typedData),
        version: TypedDataVersion.V4,
      );
    }

    final proof = {
      'type': 'EthereumEip712Signature2021',
      'created': DateTime.now().toUtc().toIso8601String(),
      'proofPurpose': 'assertionMethod',
      'verificationMethod': '$issuerDid#keys-1',
      'proofValue': signature,
    };

    final vc = <String, dynamic>{
      '@context': contexts,
      'id': vcId,
      'type': vcTypes,
      'issuer': issuerDid,
      'issuanceDate': issuanceDate,
      'credentialSubject': credentialSubject,
      'proof': proof,
    };

    if (expirationDateIso != null) {
      vc['expirationDate'] = expirationDateIso;
    }

    final isSignatureValid = await verifyVCSignature(
      vc,
      expectedIssuer: issuerAddress,
    );
    if (!isSignatureValid) {
      throw StateError(
        'Chữ ký VC không hợp lệ. Vui lòng thử lại quy trình ký trong MetaMask.',
      );
    }

    return vc;
  }

  Future<bool> verifyVCSignature(Map<String, dynamic> vc, {String? expectedIssuer}) async {
    final proof = vc['proof'] as Map<String, dynamic>?;
    if (proof == null || proof['proofValue'] == null) {
      return false;
    }

    final contexts = (vc['@context'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
    final types = (vc['type'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
    final credentialSubjectMap = Map<String, dynamic>.from(vc['credentialSubject'] as Map? ?? {});
    final subjectId = credentialSubjectMap['id']?.toString() ?? '';
    final filteredClaims = Map<String, dynamic>.from(credentialSubjectMap)..remove('id');
    final normalizedClaims = _normalizeClaims(filteredClaims);

    final credentialSubjectTypes = [
      {'name': 'id', 'type': 'string'},
      for (final key in normalizedClaims.keys) {'name': key, 'type': 'string'},
    ];

    final messageCredentialSubject = <String, String>{
      'id': subjectId,
      ...normalizedClaims,
    };

    final typedData = {
      'types': {
        'EIP712Domain': [
          {'name': 'name', 'type': 'string'},
          {'name': 'version', 'type': 'string'},
          {'name': 'chainId', 'type': 'uint256'},
          {'name': 'verifyingContract', 'type': 'address'},
        ],
        'CredentialSubject': credentialSubjectTypes,
        'VerifiableCredential': [
          {'name': '@context', 'type': 'string[]'},
          {'name': 'id', 'type': 'string'},
          {'name': 'type', 'type': 'string[]'},
          {'name': 'issuer', 'type': 'string'},
          {'name': 'issuanceDate', 'type': 'string'},
          {'name': 'expirationDate', 'type': 'string'},
          {'name': 'credentialSubject', 'type': 'CredentialSubject'},
        ],
      },
      'primaryType': 'VerifiableCredential',
      'domain': {
        'name': 'SSI Identity Manager',
        'version': '1',
        'chainId': Environment.chainId,
        'verifyingContract': Environment.contractAddress,
      },
      'message': {
        '@context': contexts,
        'id': vc['id']?.toString() ?? '',
        'type': types.isEmpty ? ['VerifiableCredential'] : types,
        'issuer': vc['issuer']?.toString() ?? '',
        'issuanceDate': vc['issuanceDate']?.toString() ?? '',
        'expirationDate': (vc['expirationDate'] ?? '').toString(),
        'credentialSubject': messageCredentialSubject,
      },
    };

    // Recover address from EIP-712 signature
    final signature = proof['proofValue'] as String;
    final recoveredAddress = _recoverTypedDataSignature(
      signature: signature,
      typedData: typedData,
    );

    final issuerDid = vc['issuer']?.toString() ?? '';
    final issuerAddress = expectedIssuer ??
        (issuerDid.startsWith('did:ethr:') ? issuerDid.substring('did:ethr:'.length) : issuerDid);

    return recoveredAddress?.toLowerCase() == issuerAddress.toLowerCase();
  }

  Future<String> registerDID(String orgID, String hashData, String uri) async {
    final function = _contract.function('registerDID');
    final hashBytes = _hexToBytes(hashData);
    if (hashBytes.length != 32) {
      throw ArgumentError('hashData must be exactly 32 bytes (bytes32), got ${hashBytes.length} bytes');
    }

    return _sendContractTransaction(
      function: function,
      parameters: [orgID, hashBytes, uri],
    );
  }

  Future<String> issueVC(String orgID, String hashCredential, String uri, {int? expirationTimestamp}) async {
    // Validate trước khi issue VC
    try {
      // Kiểm tra DID có tồn tại không
      final didData = await getDID(orgID);
      if (didData == null) {
        throw StateError('DID không tồn tại. Vui lòng đăng ký DID trước khi issue VC.');
      }
      
      if (didData['active'] != true) {
        throw StateError('DID đã bị deactivate. Vui lòng kích hoạt lại DID trước khi issue VC.');
      }
      
      // Kiểm tra quyền issue VC
      final currentAddress = await _getCurrentAddress();
      if (currentAddress == null) {
        throw StateError('Không thể lấy địa chỉ ví hiện tại.');
      }
      
      final isOwner = didData['owner'].toString().toLowerCase() == currentAddress.toLowerCase();
      final isAuthorized = await isAuthorizedIssuer(orgID, currentAddress);
      
      if (!isOwner && !isAuthorized) {
        throw StateError('Bạn không có quyền issue VC cho DID này. Chỉ owner hoặc authorized issuer mới có thể issue VC.');
      }
      
      debugPrint('[Web3Service] Validation passed: DID exists, active, and user has permission');
    } catch (e) {
      // Nếu là StateError từ validation, throw luôn
      if (e is StateError) {
        rethrow;
      }
      // Nếu là lỗi khác (network, etc.), log và tiếp tục (có thể contract sẽ revert với message rõ ràng hơn)
      debugPrint('[Web3Service] Validation warning: $e');
    }
    
    final function = _contract.function('issueVCWithExpiration');
    final expiration = BigInt.from(expirationTimestamp ?? 0);
    final parameters = [orgID, _hexToBytes(hashCredential), uri, expiration];
    final encodedData = _encodeFunctionCall(function, parameters);

    // Simulate transaction to catch revert reason before sending
    final callerAddress = await _getCurrentAddress();
    if (callerAddress != null) {
      await _simulateTransaction(
        from: callerAddress,
        to: Environment.contractAddress,
        data: encodedData,
      );
    }
    
    return _sendContractTransaction(
      function: function,
      parameters: parameters,
      preEncodedData: encodedData,
    );
  }
  
  /// Lấy địa chỉ ví hiện tại (từ private key hoặc WalletConnect)
  Future<String?> _getCurrentAddress() async {
    try {
      // Thử lấy từ private key wallet trước
      final address = await loadWallet();
      if (address != null && address.isNotEmpty) {
        return address;
      }
      
      // Nếu không có, thử WalletConnect
      final wcAddress = await _walletConnectService.getStoredAddress();
      return wcAddress;
    } catch (e) {
      debugPrint('[Web3Service] Error getting current address: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getDID(String orgID) async {
    try {
      final function = _contract.function('dids');
      final result = await _client.call(
        contract: _contract,
        function: function,
        params: [orgID],
      );

      if (result.isEmpty) {
        return null;
      }

      final owner = (result[0] as EthereumAddress?) ??
          EthereumAddress.fromHex('0x0000000000000000000000000000000000000000');
      // Check if DID exists - if owner is zero address, DID doesn't exist
      if (owner == EthereumAddress.fromHex('0x0000000000000000000000000000000000000000')) {
        return null;
      }

      return {
        'owner': owner.hex,
        'hashData': _bytesToHex((result[1] as List<int>?) ?? List<int>.filled(32, 0)),
        'uri': (result[2] as String?) ?? '',
        'active': result.length > 3 ? result[3] as bool? ?? false : false,
      };
    } catch (e) {
      if (_isNullIntCastError(e)) {
        debugPrint('[Web3Service] DID lookup returned no data for $orgID (treating as not registered)');
        return null;
      }
      debugPrint('[Web3Service] Error getting DID: $e');
      // Nếu client đã bị close, throw error rõ ràng hơn
      if (e.toString().contains('closed') || e.toString().contains('Client')) {
        throw StateError('Web3 client error. Vui lòng thử lại.');
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getVCs(String orgID) async {
    try {
      final lengthFunction = _contract.function('getVCLength');
      final lengthResult = await _client.call(
        contract: _contract,
        function: lengthFunction,
        params: [orgID],
      );

      final length = (lengthResult.first as BigInt?)?.toInt() ?? 0;
      final vcs = <Map<String, dynamic>>[];
      final getVCFunction = _contract.function('getVC');

      for (var i = 0; i < length; i++) {
        final result = await _client.call(
          contract: _contract,
          function: getVCFunction,
          params: [orgID, BigInt.from(i)],
        );

        if (result.isEmpty) {
          continue;
        }

        final expirationDate = (result[4] as BigInt?)?.toInt() ?? 0;
        final issuedAt = (result[5] as BigInt?)?.toInt() ?? 0;
        final verifiedAt = (result.length > 8 ? result[8] as BigInt? : BigInt.zero)?.toInt() ?? 0;

        vcs.add({
          'index': i,
          'hashCredential': _bytesToHex((result[0] as List<int>?) ?? List<int>.filled(32, 0)),
          'uri': (result[1] as String?) ?? '',
          'issuer': ((result[2] as EthereumAddress?) ??
                  EthereumAddress.fromHex('0x0000000000000000000000000000000000000000'))
              .hex,
          'valid': result[3] as bool? ?? false,
          'expirationDate': expirationDate,
          'issuedAt': issuedAt,
          'verified': result[6] as bool? ?? false,
          'verifier': ((result[7] as EthereumAddress?) ??
                  EthereumAddress.fromHex('0x0000000000000000000000000000000000000000'))
              .hex,
          'verifiedAt': verifiedAt,
        });
      }

      return vcs;
    } catch (e) {
      if (_isNullIntCastError(e)) {
        debugPrint('[Web3Service] getVCs returned empty result for $orgID (no credentials on-chain yet)');
        return <Map<String, dynamic>>[];
      }
      debugPrint('[Web3Service] Error getting VCs for $orgID: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getVC(String orgID, int index) async {
    try {
      final getVCFunction = _contract.function('getVC');
      final result = await _client.call(
        contract: _contract,
        function: getVCFunction,
        params: [orgID, BigInt.from(index)],
      );

      final expirationDate = (result.length > 4 ? result[4] as BigInt? : BigInt.zero)?.toInt() ?? 0;
      final issuedAt = (result.length > 5 ? result[5] as BigInt? : BigInt.zero)?.toInt() ?? 0;
      final verifiedAt = (result.length > 8 ? result[8] as BigInt? : BigInt.zero)?.toInt() ?? 0;

      return {
        'index': index,
        'hashCredential': _bytesToHex((result[0] as List<int>?) ?? List<int>.filled(32, 0)),
        'uri': (result[1] as String?) ?? '',
        'issuer': ((result[2] as EthereumAddress?) ??
                EthereumAddress.fromHex('0x0000000000000000000000000000000000000000'))
            .hex,
        'valid': result[3] as bool? ?? false,
        'expirationDate': expirationDate,
        'issuedAt': issuedAt,
        'verified': result[6] as bool? ?? false,
        'verifier': ((result[7] as EthereumAddress?) ??
                EthereumAddress.fromHex('0x0000000000000000000000000000000000000000'))
            .hex,
        'verifiedAt': verifiedAt,
      };
    } catch (e) {
      if (_isNullIntCastError(e)) {
        throw StateError('Credential not found for $orgID at index $index');
      }
      rethrow;
    }
  }

  Future<bool> verifyVC(String orgID, int index, String providedHash) async {
    final function = _contract.function('verifyVC');
    final result = await _client.call(
      contract: _contract,
      function: function,
      params: [orgID, BigInt.from(index), _hexToBytes(providedHash)],
    );

    return result.first as bool;
  }

  Future<String> revokeVC(String orgID, int index) async {
    final function = _contract.function('revokeVC');
    return _sendContractTransaction(
      function: function,
      parameters: [orgID, BigInt.from(index)],
    );
  }

  Future<String> updateDID(String orgID, String newHash, String newUri) async {
    final function = _contract.function('updateDID');
    return _sendContractTransaction(
      function: function,
      parameters: [orgID, _hexToBytes(newHash), newUri],
    );
  }

  Future<String> authorizeIssuer(String orgID, String issuerAddress) async {
    final function = _contract.function('authorizeIssuer');
    return _sendContractTransaction(
      function: function,
      parameters: [orgID, EthereumAddress.fromHex(issuerAddress)],
    );
  }

  Future<String> deactivateDID(String orgID) async {
    final function = _contract.function('deactivateDID');
    return _sendContractTransaction(
      function: function,
      parameters: [orgID],
    );
  }

  Future<bool> isAuthorizedIssuer(String orgID, String issuerAddress) async {
    try {
      final function = _contract.function('authorizedIssuers');
      final result = await _client.call(
        contract: _contract,
        function: function,
        params: [orgID, EthereumAddress.fromHex(issuerAddress)],
      );

      return result.first as bool;
    } catch (e) {
      if (_isNullIntCastError(e)) {
        debugPrint('[Web3Service] Authorization lookup returned empty result for $orgID / $issuerAddress (treating as unauthorized)');
        return false;
      }
      debugPrint('[Web3Service] Error checking authorized issuer: $e');
      // Nếu client đã bị close hoặc network error, return false để validation tiếp tục
      // Contract sẽ revert với message rõ ràng hơn nếu thực sự không có quyền
      return false;
    }
  }

  /// Thiết lập trusted verifier (chỉ admin)
  Future<String> setTrustedVerifier(String verifierAddress, bool allowed) async {
    final function = _contract.function('setTrustedVerifier');
    return _sendContractTransaction(
      function: function,
      parameters: [EthereumAddress.fromHex(verifierAddress), allowed],
    );
  }

  /// Xác thực VC bởi cơ quan cấp cao (trusted verifier)
  Future<String> verifyCredential(String orgID, int index) async {
    final function = _contract.function('verifyCredential');
    return _sendContractTransaction(
      function: function,
      parameters: [orgID, BigInt.from(index)],
    );
  }

  /// Kiểm tra xem một địa chỉ có phải là trusted verifier không
  Future<bool> isTrustedVerifier(String verifierAddress) async {
    final function = _contract.function('trustedVerifiers');
    try {
      final result = await _client.call(
        contract: _contract,
        function: function,
        params: [EthereumAddress.fromHex(verifierAddress)],
      );

      return result.first as bool;
    } catch (e) {
      if (_isNullIntCastError(e)) {
        debugPrint('[Web3Service] trustedVerifiers returned empty result for $verifierAddress (treating as untrusted)');
        return false;
      }
      rethrow;
    }
  }

  /// Estimate gas for a transaction
  /// Returns estimated gas with a safety buffer, capped at network limit
  Future<BigInt> _estimateGas({
    required String from,
    required String to,
    required String data,
  }) async {
    try {
      final requestBody = jsonEncode({
        'jsonrpc': '2.0',
        'method': 'eth_estimateGas',
        'params': [
          {
            'from': from,
            'to': to,
            'data': data,
          },
        ],
        'id': 1,
      });

      final response = await _httpClient.post(
        Uri.parse(Environment.rpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
        if (jsonResponse['error'] != null) {
          final error = jsonResponse['error'] as Map<String, dynamic>;
          final message = error['message']?.toString() ?? 'Gas estimation failed';
          throw StateError(message);
        }
        
        final result = jsonResponse['result'] as String?;
        if (result != null) {
          // Remove '0x' prefix and parse as hex
          final gasHex = result.startsWith('0x') ? result.substring(2) : result;
          final estimatedGas = BigInt.parse(gasHex, radix: 16);
          
          // Add 30% buffer for safety (network conditions, state changes, etc.)
          final gasWithBuffer = (estimatedGas * BigInt.from(130) ~/ BigInt.from(100));
          
          // Network gas limit cap (16,777,216) - leave some margin (use 15,000,000 as safe max)
          const networkGasCap = 15000000;
          final finalGas = gasWithBuffer > BigInt.from(networkGasCap) 
              ? BigInt.from(networkGasCap) 
              : gasWithBuffer;
          
          debugPrint('[Web3Service] Gas estimation: $estimatedGas -> with 30% buffer: $gasWithBuffer -> final (capped): $finalGas');
          
          return finalGas;
        }
      }
      
      throw StateError('Failed to estimate gas');
    } catch (e) {
      debugPrint('[Web3Service] Error estimating gas: $e');
      rethrow;
    }
  }

  /// Yêu cầu xác thực VC on-chain
  Future<String> requestVerification(String orgID, int index, String? targetVerifier, String metadataUri) async {
    final function = _contract.function('requestVerification');
    final targetVerifierAddress = targetVerifier != null && targetVerifier.isNotEmpty
        ? EthereumAddress.fromHex(targetVerifier)
        : EthereumAddress.fromHex('0x0000000000000000000000000000000000000000');
    final parameters = [orgID, BigInt.from(index), targetVerifierAddress, metadataUri];
    final encodedData = _encodeFunctionCall(function, parameters);

    String? walletConnectGas;
    if (await _isUsingWalletConnect()) {
      try {
        final callerAddress = await _getCurrentAddress();
        if (callerAddress != null) {
          debugPrint('[Web3Service] Auto-estimating gas for requestVerification...');
          debugPrint('[Web3Service] orgID: $orgID, index: $index, metadataUri length: ${metadataUri.length}');
          
          final finalGas = await _estimateGas(
            from: callerAddress,
            to: Environment.contractAddress,
            data: encodedData,
          );
          
          debugPrint('[Web3Service] Final gas limit (with buffer and cap): $finalGas');
          walletConnectGas = finalGas.toRadixString(10);
        }
      } catch (e) {
        debugPrint('[Web3Service] Gas estimation failed: $e');
        
        if (e.toString().contains('gas limit too high') || 
            e.toString().contains('16777216')) {
          rethrow;
        }
        
        debugPrint('[Web3Service] Using safe default gas limit: 500,000');
        walletConnectGas = '500000';
      }
      
      if (walletConnectGas == null) {
        debugPrint('[Web3Service] No address available, using safe default gas limit: 500,000');
        walletConnectGas = '500000';
      }
    }
    
    return _sendContractTransaction(
      function: function,
      parameters: parameters,
      walletConnectGas: walletConnectGas,
      preEncodedData: encodedData,
    );
  }

  /// Lấy admin address
  Future<String?> getAdmin() async {
    final function = _contract.function('admin');
    try {
      final result = await _client.call(
        contract: _contract,
        function: function,
        params: [],
      );
      return (result.first as EthereumAddress).hex;
    } catch (e) {
      return null;
    }
  }

  /// Lấy nextRequestId (số lượng requests hiện tại)
  Future<int> getNextRequestId() async {
    final function = _contract.function('nextRequestId');
    try {
      final result = await _client.call(
        contract: _contract,
        function: function,
        params: [],
      );
      return (result.first as BigInt).toInt();
    } catch (e) {
      if (_isNullIntCastError(e)) {
        debugPrint('[Web3Service] nextRequestId returned empty result (defaulting to 0)');
        return 0;
      }
      debugPrint('[Web3Service] Error getting nextRequestId: $e');
      return 0;
    }
  }

  /// Lấy thông tin verification request theo requestId
  Future<Map<String, dynamic>?> getVerificationRequest(int requestId) async {
    final function = _contract.function('getVerificationRequest');
    try {
      final result = await _client.call(
        contract: _contract,
        function: function,
        params: [BigInt.from(requestId)],
      );

      if (result.isEmpty) {
        return null;
      }

      final orgId = (result[0] as String?) ?? '';
      final vcIndex = (result[1] as BigInt?)?.toInt() ?? 0;
      final requester = (result[2] as EthereumAddress?)?.hex ??
          EthereumAddress.fromHex('0x0000000000000000000000000000000000000000').hex;
      final targetVerifier = (result[3] as EthereumAddress?)?.hex ??
          EthereumAddress.fromHex('0x0000000000000000000000000000000000000000').hex;
      final metadataUri = (result[4] as String?) ?? '';
      final requestedAt = (result[5] as BigInt?)?.toInt() ?? 0;
      final processed = result.length > 6 ? result[6] as bool? ?? false : false;

      return {
        'requestId': requestId,
        'orgID': orgId,
        'vcIndex': vcIndex,
        'requester': requester,
        'targetVerifier': targetVerifier,
        'metadataUri': metadataUri,
        'requestedAt': requestedAt,
        'processed': processed,
      };
    } catch (e) {
      if (_isNullIntCastError(e)) {
        debugPrint('[Web3Service] Verification request $requestId not found or empty, ignoring');
        return null;
      }
      debugPrint('[Web3Service] Error getting verification request $requestId: $e');
      return null;
    }
  }

  /// Lấy tất cả verification requests (pending và processed)
  /// Chỉ lấy các requests chưa được xử lý nếu onlyPending = true
  /// Có thể lọc theo orgID/requester để giảm dữ liệu cần xử lý trên client
  Future<List<Map<String, dynamic>>> getAllVerificationRequests({
    bool onlyPending = true,
    String? orgIdFilter,
    String? requesterAddress,
    int chunkSize = 25,
  }) async {
    final requests = <Map<String, dynamic>>[];
    try {
      final nextRequestId = await getNextRequestId();

      if (nextRequestId == 0) {
        return requests;
      }

      int currentId = 1;
      while (currentId <= nextRequestId) {
        final endId = currentId + chunkSize - 1;
        final actualEndId = endId > nextRequestId ? nextRequestId : endId;
        final futures = <Future<Map<String, dynamic>?>>[];
        for (int requestId = currentId; requestId <= actualEndId; requestId++) {
          futures.add(getVerificationRequest(requestId));
        }
        final chunkResults = await Future.wait(futures);
        for (final request in chunkResults) {
          if (request == null) continue;
          if (orgIdFilter != null &&
              request['orgID']?.toString().toLowerCase() != orgIdFilter.toLowerCase()) {
            continue;
          }
          if (requesterAddress != null &&
              request['requester']?.toString().toLowerCase() != requesterAddress.toLowerCase()) {
            continue;
          }
          if (!onlyPending || !request['processed']) {
            requests.add(request);
          }
        }
        currentId = actualEndId + 1;
      }
      
      // Sắp xếp theo requestedAt (mới nhất trước)
      requests.sort((a, b) {
        final requestedAtB = (b['requestedAt'] as int?) ?? 0;
        final requestedAtA = (a['requestedAt'] as int?) ?? 0;
        return requestedAtB.compareTo(requestedAtA);
      });
      
      return requests;
    } catch (e) {
      debugPrint('[Web3Service] Error getting all verification requests: $e');
      return [];
    }
  }

  /// Hủy verification request (chỉ requester mới có thể hủy)
  Future<String> cancelVerificationRequest(int requestId) async {
    final function = _contract.function('cancelVerificationRequest');
    return _sendContractTransaction(
      function: function,
      parameters: [BigInt.from(requestId)],
    );
  }

  Future<EtherAmount> getBalance() async {
    final credentials = await _requireCredentials();
    final address = credentials.address;
    return _client.getBalance(address);
  }

  Future<EtherAmount> getBalanceForAddress(String address) async {
    return _client.getBalance(EthereumAddress.fromHex(address));
  }

  /// Đợi transaction receipt và kiểm tra status
  /// Trả về true nếu transaction thành công, false nếu revert
  Future<bool> waitForTransactionReceipt(String txHash, {Duration timeout = const Duration(minutes: 2)}) async {
    final startTime = DateTime.now();
    
    while (DateTime.now().difference(startTime) < timeout) {
      try {
        // Sử dụng HTTP RPC call trực tiếp để lấy transaction receipt
        final requestBody = jsonEncode({
          'jsonrpc': '2.0',
          'method': 'eth_getTransactionReceipt',
          'params': [txHash],
          'id': 1,
        });
        
        final response = await _httpClient.post(
          Uri.parse(Environment.rpcUrl),
          headers: {'Content-Type': 'application/json'},
          body: requestBody,
        );
        
        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
          final result = jsonResponse['result'];
          
          if (result != null && result is Map) {
            // Transaction đã được mined
            // Status: "0x1" = success, "0x0" = revert
            final statusHex = result['status']?.toString() ?? '';
            if (statusHex.isNotEmpty) {
              final status = int.parse(statusHex.replaceFirst('0x', ''), radix: 16);
              debugPrint('[Web3Service] Transaction receipt received. Status: $status (0x${status.toRadixString(16)})');
              if (status == 0) {
                await _logRevertReason(txHash);
              }
              return status == 1;
            }
          }
        }
      } catch (e) {
        // Transaction chưa được mined, tiếp tục đợi
        debugPrint('[Web3Service] Transaction not yet mined, waiting... ($e)');
      }
      
      // Đợi 2 giây trước khi thử lại
      await Future.delayed(const Duration(seconds: 2));
    }
    
    throw TimeoutException('Transaction receipt timeout after ${timeout.inMinutes} minutes', timeout);
  }

  void dispose() {
    // Intentionally left blank.
    // Web3Service is reused across multiple screens and closing the underlying
    // HTTP client would break in-flight requests.
  }

  Future<EthPrivateKey> _deriveCredentials(String privateKeyOrMnemonic) async {
    if (privateKeyOrMnemonic.split(' ').length > 1) {
      final seed = bip39.mnemonicToSeed(privateKeyOrMnemonic);
      return EthPrivateKey.fromHex(_bytesToHex(seed.sublist(0, 32)));
    }
    return EthPrivateKey.fromHex(privateKeyOrMnemonic);
  }

  Future<Credentials> _requireCredentials() async {
    if (_credentials != null) return _credentials!;
    final address = await loadWallet();
    if (_credentials != null) return _credentials!;
    
    // Check if WalletConnect is available
    final isWC = await _isUsingWalletConnect();
    if (isWC) {
      final wcAddress = await _walletConnectService.getStoredAddress();
      throw StateError('Private key wallet not found. Using WalletConnect wallet: $wcAddress. Transactions will be sent via WalletConnect.');
    }
    
    throw StateError('Wallet credentials not found. Import or create a wallet first, or connect via WalletConnect. Last known address: $address');
  }

  Future<void> _logRevertReason(String txHash) async {
    try {
      final txRequest = jsonEncode({
        'jsonrpc': '2.0',
        'method': 'eth_getTransactionByHash',
        'params': [txHash],
        'id': 1,
      });

      final txResponse = await _httpClient.post(
        Uri.parse(Environment.rpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: txRequest,
      );

      if (txResponse.statusCode == 200) {
        final txJson = jsonDecode(txResponse.body) as Map<String, dynamic>;
        final txResult = txJson['result'] as Map<String, dynamic>?;

        if (txResult != null) {
          final from = txResult['from']?.toString();
          final to = txResult['to']?.toString();
          final input = txResult['input']?.toString();

          if (from != null && to != null && input != null) {
            try {
              await _simulateTransaction(from: from, to: to, data: input);
            } on StateError catch (e) {
              debugPrint('[Web3Service] Transaction revert reason: ${e.message}');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[Web3Service] Could not fetch revert reason: $e');
    }
  }

  Future<void> _simulateTransaction({
    required String from,
    required String to,
    required String data,
  }) async {
    try {
      final requestBody = jsonEncode({
        'jsonrpc': '2.0',
        'method': 'eth_call',
        'params': [
          {
            'from': from,
            'to': to,
            'data': data,
          },
          'latest',
        ],
        'id': 1,
      });

      final response = await _httpClient.post(
        Uri.parse(Environment.rpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
        if (jsonResponse['error'] != null) {
          final error = jsonResponse['error'] as Map<String, dynamic>;
          final reason = _extractRevertReason(error);
          throw StateError(reason ?? 'Transaction simulation failed');
        }
      } else {
        debugPrint('[Web3Service] Simulation HTTP error: ${response.statusCode}');
      }
    } on StateError {
      rethrow;
    } catch (e) {
      debugPrint('[Web3Service] Simulation error: $e');
    }
  }

  String? _extractRevertReason(Map<String, dynamic> error) {
    final message = error['message']?.toString();
    if (message != null && message.isNotEmpty) {
      return message;
    }

    final data = error['data'];
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }

    if (data is String && data.startsWith('0x08c379a0')) {
      try {
        final reasonHex = data.substring(10 + 64);
        final bytes = _hexToBytes('0x$reasonHex');
        final reason = String.fromCharCodes(bytes.where((byte) => byte != 0));
        if (reason.isNotEmpty) {
          return reason;
        }
      } catch (_) {}
    }

    return null;
  }
  
  /// Encode function call data for WalletConnect transactions.
  /// Relies on web3dart's ABI encoder to avoid maintaining custom logic.
  String _encodeFunctionCall(ContractFunction function, List<dynamic> parameters) {
    final encoded = function.encodeCall(parameters);
    return _bytesToHex(encoded);
  }

  Future<String> _sendContractTransaction({
    required ContractFunction function,
    required List<dynamic> parameters,
    EtherAmount? value,
    String? walletConnectGas,
    String? walletConnectValue,
    String? preEncodedData,
  }) async {
    final isWC = await _isUsingWalletConnect();
    if (isWC) {
      final encodedData = preEncodedData ?? _encodeFunctionCall(function, parameters);
      return await _walletConnectService.sendTransaction(
        to: Environment.contractAddress,
        data: encodedData,
        gas: walletConnectGas,
        value: walletConnectValue,
      );
    }

    final txHash = await _client.sendTransaction(
      await _requireCredentials(),
      Transaction.callContract(
        contract: _contract,
        function: function,
        parameters: parameters,
        value: value,
      ),
      chainId: Environment.chainId,
    );

    return txHash;
  }

  Uint8List _hexToBytes(String hex) {
    var sanitized = hex;
    if (sanitized.startsWith('0x')) {
      sanitized = sanitized.substring(2);
    }
    return Uint8List.fromList(
      List<int>.generate(
        sanitized.length ~/ 2,
        (i) => int.parse(sanitized.substring(i * 2, i * 2 + 2), radix: 16),
      ),
    );
  }

  String _bytesToHex(List<int> bytes) {
    return '0x${bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';
  }

  /// Recover address from EIP-712 typed data signature
  /// This is a simplified implementation - for production, use a full EIP-712 library
  String? _recoverTypedDataSignature({
    required String signature,
    required Map<String, dynamic> typedData,
  }) {
    try {
      final normalizedSignature =
          signature.startsWith('0x') ? signature : '0x$signature';
      final typedMessage = TypedMessage.fromJson(typedData);
      final publicKey = TypedDataUtil.recoverPublicKey(
        typedMessage,
        normalizedSignature,
        TypedDataVersion.V4,
      );
      if (publicKey == null) {
        debugPrint('Error recovering signature: public key is null');
        return null;
      }
      final addressBytes = SignatureUtil.publicKeyToAddress(publicKey);
      return _bytesToHex(addressBytes);
    } catch (e) {
      debugPrint('Error recovering signature: $e');
      return null;
    }
  }

  Map<String, String> _normalizeClaims(Map<String, dynamic> claims) {
    final sorted = SplayTreeMap<String, String>();
    for (final entry in claims.entries) {
      sorted[entry.key] = entry.value?.toString() ?? '';
    }
    return sorted;
  }

  bool _isNullIntCastError(Object error) {
    return error is TypeError &&
        error.toString().contains("type 'Null' is not a subtype of type 'int'");
  }
}

