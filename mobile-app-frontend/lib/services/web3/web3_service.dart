import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bip39/bip39.dart' as bip39;
import 'package:eth_sig_util/eth_sig_util.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' show Client;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/crypto.dart' as crypto;
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
    final normalizedClaims = claims.map((key, value) => MapEntry(key, value.toString()));
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
    final normalizedClaims = credentialSubjectMap..remove('id');

    final credentialSubjectTypes = [
      {'name': 'id', 'type': 'string'},
      for (final key in normalizedClaims.keys) {'name': key, 'type': 'string'},
    ];

    final messageCredentialSubject = <String, String>{
      'id': subjectId,
      for (final entry in normalizedClaims.entries) entry.key: entry.value.toString(),
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
    final isWC = await _isUsingWalletConnect();
    
    if (isWC) {
      // Use WalletConnect to send transaction
      final contractAddress = Environment.contractAddress;
      
      // Convert hashData to bytes32 - ensure it's exactly 32 bytes
      final hashBytes = _hexToBytes(hashData);
      if (hashBytes.length != 32) {
        throw ArgumentError('hashData must be exactly 32 bytes (bytes32), got ${hashBytes.length} bytes');
      }
      
      debugPrint('[Web3Service] Encoding function call for WalletConnect...');
      debugPrint('[Web3Service] orgID: $orgID');
      debugPrint('[Web3Service] hashData: $hashData (${hashBytes.length} bytes)');
      debugPrint('[Web3Service] uri: $uri');
      
      final encodedData = _encodeFunctionCall(function, [orgID, hashBytes, uri]);
      debugPrint('[Web3Service] Encoded data length: ${encodedData.length}');
      debugPrint('[Web3Service] Encoded data: $encodedData');
      
      return await _walletConnectService.sendTransaction(
        to: contractAddress,
        data: encodedData,
      );
    } else {
      // Use private key to send transaction
      final txHash = await _client.sendTransaction(
        await _requireCredentials(),
        Transaction.callContract(
          contract: _contract,
          function: function,
          parameters: [orgID, _hexToBytes(hashData), uri],
        ),
        chainId: Environment.chainId,
      );

      return txHash;
    }
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
    final contractAddress = Environment.contractAddress;
    final encodedData = _encodeFunctionCall(function, [orgID, _hexToBytes(hashCredential), uri, expiration]);
    final isWC = await _isUsingWalletConnect();

    // Simulate transaction to catch revert reason before sending
    final callerAddress = await _getCurrentAddress();
    if (callerAddress != null) {
      await _simulateTransaction(
        from: callerAddress,
        to: contractAddress,
        data: encodedData,
      );
    }
    
    if (isWC) {
      // Use WalletConnect to send transaction
      return await _walletConnectService.sendTransaction(
        to: contractAddress,
        data: encodedData,
      );
    } else {
      // Use private key to send transaction
      final credentials = await _requireCredentials();
      final txHash = await _client.sendTransaction(
        credentials,
        Transaction.callContract(
          contract: _contract,
          function: function,
          parameters: [orgID, _hexToBytes(hashCredential), uri, expiration],
        ),
        chainId: Environment.chainId,
      );

      return txHash;
    }
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

      final owner = result[0] as EthereumAddress;
      // Check if DID exists - if owner is zero address, DID doesn't exist
      if (owner == EthereumAddress.fromHex('0x0000000000000000000000000000000000000000')) {
        return null;
      }

      return {
        'owner': owner.hex,
        'hashData': _bytesToHex(result[1] as List<int>),
        'uri': result[2] as String,
        'active': result[3] as bool,
      };
    } catch (e) {
      debugPrint('[Web3Service] Error getting DID: $e');
      // Nếu client đã bị close, throw error rõ ràng hơn
      if (e.toString().contains('closed') || e.toString().contains('Client')) {
        throw StateError('Web3 client error. Vui lòng thử lại.');
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getVCs(String orgID) async {
    final lengthFunction = _contract.function('getVCLength');
    final lengthResult = await _client.call(
      contract: _contract,
      function: lengthFunction,
      params: [orgID],
    );

    final length = (lengthResult.first as BigInt).toInt();
    final vcs = <Map<String, dynamic>>[];
    final getVCFunction = _contract.function('getVC');

    for (var i = 0; i < length; i++) {
      final result = await _client.call(
        contract: _contract,
        function: getVCFunction,
        params: [orgID, BigInt.from(i)],
      );

      vcs.add({
        'index': i,
        'hashCredential': _bytesToHex(result[0] as List<int>),
        'uri': result[1] as String,
        'issuer': (result[2] as EthereumAddress).hex,
        'valid': result[3] as bool,
        'expirationDate': (result[4] as BigInt).toInt(),
        'issuedAt': (result[5] as BigInt).toInt(),
        'verified': result[6] as bool,
        'verifier': (result[7] as EthereumAddress).hex,
        'verifiedAt': (result[8] as BigInt).toInt(),
      });
    }

    return vcs;
  }

  Future<Map<String, dynamic>> getVC(String orgID, int index) async {
    final getVCFunction = _contract.function('getVC');
    final result = await _client.call(
      contract: _contract,
      function: getVCFunction,
      params: [orgID, BigInt.from(index)],
    );

    return {
      'index': index,
      'hashCredential': _bytesToHex(result[0] as List<int>),
      'uri': result[1] as String,
      'issuer': (result[2] as EthereumAddress).hex,
      'valid': result[3] as bool,
      'expirationDate': (result[4] as BigInt).toInt(),
      'issuedAt': (result[5] as BigInt).toInt(),
      'verified': result[6] as bool,
      'verifier': (result[7] as EthereumAddress).hex,
      'verifiedAt': (result[8] as BigInt).toInt(),
    };
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
    final isWC = await _isUsingWalletConnect();
    
    if (isWC) {
      final contractAddress = Environment.contractAddress;
      final encodedData = _encodeFunctionCall(function, [orgID, BigInt.from(index)]);
      
      return await _walletConnectService.sendTransaction(
        to: contractAddress,
        data: encodedData,
      );
    } else {
      final txHash = await _client.sendTransaction(
        await _requireCredentials(),
        Transaction.callContract(
          contract: _contract,
          function: function,
          parameters: [orgID, BigInt.from(index)],
        ),
        chainId: Environment.chainId,
      );

      return txHash;
    }
  }

  Future<String> updateDID(String orgID, String newHash, String newUri) async {
    final function = _contract.function('updateDID');
    final isWC = await _isUsingWalletConnect();
    
    if (isWC) {
      final contractAddress = Environment.contractAddress;
      final encodedData = _encodeFunctionCall(function, [orgID, _hexToBytes(newHash), newUri]);
      
      return await _walletConnectService.sendTransaction(
        to: contractAddress,
        data: encodedData,
      );
    } else {
      final txHash = await _client.sendTransaction(
        await _requireCredentials(),
        Transaction.callContract(
          contract: _contract,
          function: function,
          parameters: [orgID, _hexToBytes(newHash), newUri],
        ),
        chainId: Environment.chainId,
      );

      return txHash;
    }
  }

  Future<String> authorizeIssuer(String orgID, String issuerAddress) async {
    final function = _contract.function('authorizeIssuer');
    final isWC = await _isUsingWalletConnect();
    
    if (isWC) {
      final contractAddress = Environment.contractAddress;
      final encodedData = _encodeFunctionCall(function, [orgID, EthereumAddress.fromHex(issuerAddress)]);
      
      return await _walletConnectService.sendTransaction(
        to: contractAddress,
        data: encodedData,
      );
    } else {
      final txHash = await _client.sendTransaction(
        await _requireCredentials(),
        Transaction.callContract(
          contract: _contract,
          function: function,
          parameters: [orgID, EthereumAddress.fromHex(issuerAddress)],
        ),
        chainId: Environment.chainId,
      );

      return txHash;
    }
  }

  Future<String> deactivateDID(String orgID) async {
    final function = _contract.function('deactivateDID');
    final isWC = await _isUsingWalletConnect();
    
    if (isWC) {
      final contractAddress = Environment.contractAddress;
      final encodedData = _encodeFunctionCall(function, [orgID]);
      
      return await _walletConnectService.sendTransaction(
        to: contractAddress,
        data: encodedData,
      );
    } else {
      final txHash = await _client.sendTransaction(
        await _requireCredentials(),
        Transaction.callContract(
          contract: _contract,
          function: function,
          parameters: [orgID],
        ),
        chainId: Environment.chainId,
      );

      return txHash;
    }
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
      debugPrint('[Web3Service] Error checking authorized issuer: $e');
      // Nếu client đã bị close hoặc network error, return false để validation tiếp tục
      // Contract sẽ revert với message rõ ràng hơn nếu thực sự không có quyền
      return false;
    }
  }

  /// Thiết lập trusted verifier (chỉ admin)
  Future<String> setTrustedVerifier(String verifierAddress, bool allowed) async {
    final function = _contract.function('setTrustedVerifier');
    final isWC = await _isUsingWalletConnect();
    
    if (isWC) {
      final contractAddress = Environment.contractAddress;
      final encodedData = _encodeFunctionCall(function, [EthereumAddress.fromHex(verifierAddress), allowed]);
      
      return await _walletConnectService.sendTransaction(
        to: contractAddress,
        data: encodedData,
      );
    } else {
      final txHash = await _client.sendTransaction(
        await _requireCredentials(),
        Transaction.callContract(
          contract: _contract,
          function: function,
          parameters: [EthereumAddress.fromHex(verifierAddress), allowed],
        ),
        chainId: Environment.chainId,
      );

      return txHash;
    }
  }

  /// Xác thực VC bởi cơ quan cấp cao (trusted verifier)
  Future<String> verifyCredential(String orgID, int index) async {
    final function = _contract.function('verifyCredential');
    final isWC = await _isUsingWalletConnect();
    
    if (isWC) {
      final contractAddress = Environment.contractAddress;
      final encodedData = _encodeFunctionCall(function, [orgID, BigInt.from(index)]);
      
      return await _walletConnectService.sendTransaction(
        to: contractAddress,
        data: encodedData,
      );
    } else {
      final txHash = await _client.sendTransaction(
        await _requireCredentials(),
        Transaction.callContract(
          contract: _contract,
          function: function,
          parameters: [orgID, BigInt.from(index)],
        ),
        chainId: Environment.chainId,
      );

      return txHash;
    }
  }

  /// Kiểm tra xem một địa chỉ có phải là trusted verifier không
  Future<bool> isTrustedVerifier(String verifierAddress) async {
    final function = _contract.function('trustedVerifiers');
    final result = await _client.call(
      contract: _contract,
      function: function,
      params: [EthereumAddress.fromHex(verifierAddress)],
    );

    return result.first as bool;
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
    final isWC = await _isUsingWalletConnect();
    final targetVerifierAddress = targetVerifier != null && targetVerifier.isNotEmpty
        ? EthereumAddress.fromHex(targetVerifier)
        : EthereumAddress.fromHex('0x0000000000000000000000000000000000000000');
    
    final contractAddress = Environment.contractAddress;
    final encodedData = _encodeFunctionCall(function, [orgID, BigInt.from(index), targetVerifierAddress, metadataUri]);
    
    if (isWC) {
      // Estimate gas automatically with buffer and network cap
      // This ensures flexibility while staying within network limits
      try {
        final callerAddress = await _getCurrentAddress();
        if (callerAddress != null) {
          debugPrint('[Web3Service] Auto-estimating gas for requestVerification...');
          debugPrint('[Web3Service] orgID: $orgID, index: $index, metadataUri length: ${metadataUri.length}');
          
          // _estimateGas already includes 30% buffer and network cap (15M)
          final finalGas = await _estimateGas(
            from: callerAddress,
            to: contractAddress,
            data: encodedData,
          );
          
          debugPrint('[Web3Service] Final gas limit (with buffer and cap): $finalGas');
          
          return await _walletConnectService.sendTransaction(
            to: contractAddress,
            data: encodedData,
            gas: finalGas.toRadixString(10), // Pass as decimal string
          );
        }
      } catch (e) {
        debugPrint('[Web3Service] Gas estimation failed: $e');
        
        // Check if it's a gas limit error - don't retry with default
        if (e.toString().contains('gas limit too high') || 
            e.toString().contains('16777216')) {
          rethrow; // Re-throw gas limit errors
        }
        
        // For estimation failures, use a safe default
        // requestVerification typically uses 100k-300k gas, so 500k is safe
        debugPrint('[Web3Service] Using safe default gas limit: 500,000');
        const safeGasLimit = 500000;
        
        return await _walletConnectService.sendTransaction(
          to: contractAddress,
          data: encodedData,
          gas: safeGasLimit.toString(),
        );
      }
      
      // If no address available, use safe default
      debugPrint('[Web3Service] No address available, using safe default gas limit: 500,000');
      const safeGasLimit = 500000;
      return await _walletConnectService.sendTransaction(
        to: contractAddress,
        data: encodedData,
        gas: safeGasLimit.toString(),
      );
    } else {
      final txHash = await _client.sendTransaction(
        await _requireCredentials(),
        Transaction.callContract(
          contract: _contract,
          function: function,
          parameters: [orgID, BigInt.from(index), targetVerifierAddress, metadataUri],
        ),
        chainId: Environment.chainId,
      );

      return txHash;
    }
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

      return {
        'requestId': requestId,
        'orgID': result[0] as String,
        'vcIndex': (result[1] as BigInt).toInt(),
        'requester': (result[2] as EthereumAddress).hex,
        'targetVerifier': (result[3] as EthereumAddress).hex,
        'metadataUri': result[4] as String,
        'requestedAt': (result[5] as BigInt).toInt(),
        'processed': result[6] as bool,
      };
    } catch (e) {
      debugPrint('[Web3Service] Error getting verification request $requestId: $e');
      return null;
    }
  }

  /// Lấy tất cả verification requests (pending và processed)
  /// Chỉ lấy các requests chưa được xử lý nếu onlyPending = true
  Future<List<Map<String, dynamic>>> getAllVerificationRequests({bool onlyPending = true}) async {
    final requests = <Map<String, dynamic>>[];
    try {
      final nextRequestId = await getNextRequestId();
      
      // Lấy tất cả requests từ 1 đến nextRequestId
      for (int i = 1; i < nextRequestId; i++) {
        final request = await getVerificationRequest(i);
        if (request != null) {
          // Nếu onlyPending = true, chỉ lấy requests chưa được xử lý
          if (!onlyPending || !request['processed']) {
            requests.add(request);
          }
        }
      }
      
      // Sắp xếp theo requestedAt (mới nhất trước)
      requests.sort((a, b) => (b['requestedAt'] as int).compareTo(a['requestedAt'] as int));
      
      return requests;
    } catch (e) {
      debugPrint('[Web3Service] Error getting all verification requests: $e');
      return [];
    }
  }

  /// Hủy verification request (chỉ requester mới có thể hủy)
  Future<String> cancelVerificationRequest(int requestId) async {
    final function = _contract.function('cancelVerificationRequest');
    final isWC = await _isUsingWalletConnect();
    
    if (isWC) {
      final contractAddress = Environment.contractAddress;
      final encodedData = _encodeFunctionCall(function, [BigInt.from(requestId)]);
      
      return await _walletConnectService.sendTransaction(
        to: contractAddress,
        data: encodedData,
      );
    } else {
      final txHash = await _client.sendTransaction(
        await _requireCredentials(),
        Transaction.callContract(
          contract: _contract,
          function: function,
          parameters: [BigInt.from(requestId)],
        ),
        chainId: Environment.chainId,
      );

      return txHash;
    }
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
  
  /// Encode function call data for WalletConnect transactions
  /// Uses manual ABI encoding since we can't easily extract data from Transaction object
  String _encodeFunctionCall(ContractFunction function, List<dynamic> parameters) {
    // Use manual encoding for WalletConnect transactions
    return _encodeFunctionCallManual(function, parameters);
  }
  
  /// Manual ABI encoding for WalletConnect
  String _encodeFunctionCallManual(ContractFunction function, List<dynamic> parameters) {
    // Calculate function selector (first 4 bytes of keccak256(function signature))
    // Use the actual type name from the parameter's type property
    final paramTypes = <String>[];
    for (var i = 0; i < function.parameters.length; i++) {
      final param = function.parameters[i];
      try {
        final typeName = _getTypeName(param.type);
        paramTypes.add(typeName);
        debugPrint('Parameter $i: typeName=$typeName, type=${param.type}, runtimeType=${param.type.runtimeType}');
      } catch (e) {
        debugPrint('Error getting type name for parameter $i: $e');
        rethrow;
      }
    }
    
    final paramTypesStr = paramTypes.join(',');
    final functionSignature = '${function.name}($paramTypesStr)';
    debugPrint('Function signature: $functionSignature');
    final signatureHash = crypto.keccak256(utf8.encode(functionSignature));
    final functionSelector = signatureHash.sublist(0, 4);
    
    // Encode parameters
    final head = <int>[];
    final tail = <int>[];
    int dynamicOffset = function.parameters.length * 32; // Start offset for dynamic types
    
    for (var i = 0; i < function.parameters.length; i++) {
      final param = function.parameters[i];
      final value = parameters[i];
      final typeName = _getTypeName(param.type);
      
      if (typeName == 'string') {
        // Dynamic type: store offset in head, data in tail
        head.addAll(_uint256ToBytes(BigInt.from(dynamicOffset)));
        
        final strBytes = utf8.encode(value.toString());
        final lengthBytes = _uint256ToBytes(BigInt.from(strBytes.length));
        tail.addAll(lengthBytes);
        
        // Pad string data to multiple of 32 bytes
        final paddedLength = ((strBytes.length + 31) ~/ 32) * 32;
        final padded = Uint8List(paddedLength);
        padded.setRange(0, strBytes.length, strBytes);
        tail.addAll(padded);
        
        dynamicOffset += 32 + paddedLength; // Update offset for next dynamic type
      } else {
        // Static type: encode directly in head
        if (typeName == 'bytes32') {
          final bytes = value is List<int> 
              ? Uint8List.fromList(value)
              : _hexToBytes(value.toString());
          final padded = Uint8List(32);
          padded.setRange(0, bytes.length > 32 ? 32 : bytes.length, bytes);
          head.addAll(padded);
        } else if (typeName == 'address') {
          final address = value is EthereumAddress 
              ? value.hex
              : (value is String ? value : value.toString());
          final bytes = _hexToBytes(address);
          final padded = Uint8List(32);
          padded.setRange(12, 32, bytes); // Address: 20 bytes, left-padded to 32
          head.addAll(padded);
        } else if (typeName.startsWith('uint')) {
          final bigInt = value is BigInt 
              ? value
              : (value is int ? BigInt.from(value) : BigInt.parse(value.toString()));
          head.addAll(_uint256ToBytes(bigInt));
        } else {
          throw UnsupportedError('Unsupported parameter type: $typeName (${param.type.runtimeType})');
        }
      }
    }
    
    // Combine function selector + head + tail
    final encoded = Uint8List.fromList([...functionSelector, ...head, ...tail]);
    return _bytesToHex(encoded);
  }
  
  /// Get type name from Parameter type, handling different type representations
  String _getTypeName(dynamic type) {
    // Try to get the canonical type name
    final typeString = type.toString();
    final runtimeTypeName = type.runtimeType.toString();
    
    debugPrint('_getTypeName: typeString="$typeString", runtimeType="$runtimeTypeName"');
    
    // Check runtime type first (more reliable)
    // Handle "StringType" class name
    if (runtimeTypeName.contains('StringType') || 
        (runtimeTypeName.contains('String') && !runtimeTypeName.contains('Bytes') && !runtimeTypeName.contains('Fixed'))) {
      return 'string';
    }
    
    // Handle "AddressType" class name
    if (runtimeTypeName.contains('AddressType') || 
        (runtimeTypeName.contains('Address') && !runtimeTypeName.contains('Bytes'))) {
      return 'address';
    }
    
    // Handle "FixedBytes" - this represents bytes32, bytes16, etc.
    if (runtimeTypeName.contains('FixedBytes') || typeString.contains('FixedBytes')) {
      // Try to extract the size from the type
      // FixedBytes usually represents bytes32, bytes16, etc.
      // Check if we can get the size from the type object
      try {
        // Try to access size property if it exists
        if (type is Map) {
          final size = type['size'];
          if (size != null) {
            return 'bytes$size';
          }
        }
        // Check typeString for bytes pattern
        final bytesMatch = RegExp(r'bytes(\d+)').firstMatch(typeString);
        if (bytesMatch != null) {
          return 'bytes${bytesMatch.group(1)}';
        }
        // For our contract, we only use bytes32, so default to that
        // But we should try to be more accurate
        if (typeString.contains('32') || runtimeTypeName.contains('32')) {
          return 'bytes32';
        }
        // Default to bytes32 for FixedBytes (most common case)
        debugPrint('Warning: FixedBytes without size info, defaulting to bytes32');
        return 'bytes32';
      } catch (e) {
        debugPrint('Error extracting bytes size from FixedBytes: $e');
        return 'bytes32'; // Default fallback
      }
    }
    
    // Handle "Bytes32Type" class name (alternative representation)
    if (runtimeTypeName.contains('Bytes32Type') || 
        runtimeTypeName.contains('Bytes32')) {
      return 'bytes32';
    }
    
    // Handle "UintType" class name
    if (runtimeTypeName.contains('UintType') || 
        (runtimeTypeName.contains('Uint') && !runtimeTypeName.contains('Bytes'))) {
      // Extract uint size from runtime type name
      final match = RegExp(r'Uint(\d+)').firstMatch(runtimeTypeName);
      if (match != null) {
        return 'uint${match.group(1)}';
      }
      // Check typeString for size
      final typeMatch = RegExp(r'[Uu]int(\d+)').firstMatch(typeString);
      if (typeMatch != null) {
        return 'uint${typeMatch.group(1)}';
      }
      return 'uint256'; // Default
    }
    
    // Fallback to typeString analysis
    final lowerTypeString = typeString.toLowerCase();
    
    // Check for string (be careful with case sensitivity)
    if (typeString == 'string' || 
        typeString.contains('StringType') ||
        (lowerTypeString.contains('string') && !lowerTypeString.contains('bytes'))) {
      return 'string';
    }
    
    // Check for address
    if (typeString == 'address' || 
        typeString.contains('AddressType') ||
        lowerTypeString.contains('address')) {
      return 'address';
    }
    
    // Check for bytes (bytes32, bytes16, etc.)
    if (lowerTypeString.contains('bytes')) {
      final bytesMatch = RegExp(r'bytes(\d+)').firstMatch(lowerTypeString);
      if (bytesMatch != null) {
        return 'bytes${bytesMatch.group(1)}';
      }
      // If just "bytes" without number, check if it's bytes32 (most common)
      if (typeString.contains('32') || runtimeTypeName.contains('32')) {
        return 'bytes32';
      }
      return 'bytes32'; // Default to bytes32
    }
    
    // Check for uint
    if (lowerTypeString.contains('uint')) {
      final match = RegExp(r'[Uu]int(\d+)').firstMatch(typeString);
      if (match != null) {
        return 'uint${match.group(1)}';
      }
      return 'uint256';
    }
    
    // Last resort: log and return error
    debugPrint('Error: Could not determine type name for: typeString="$typeString", runtimeType="$runtimeTypeName"');
    debugPrint('Type object: $type');
    throw UnsupportedError('Unsupported parameter type: $typeString (runtime: $runtimeTypeName). Please check the contract ABI.');
  }
  
  Uint8List _uint256ToBytes(BigInt value) {
    final hex = value.toRadixString(16).padLeft(64, '0');
    return Uint8List.fromList(
      List.generate(32, (i) => int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16)),
    );
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
      // Parse signature
      final signatureBytes = _hexToBytes(signature);
      if (signatureBytes.length != 65) {
        return null;
      }

      final r = BigInt.parse(
        '0x${signatureBytes.sublist(0, 32).map((b) => b.toRadixString(16).padLeft(2, '0')).join()}',
      );
      final s = BigInt.parse(
        '0x${signatureBytes.sublist(32, 64).map((b) => b.toRadixString(16).padLeft(2, '0')).join()}',
      );
      final v = signatureBytes[64];

      // Create the message hash using the same method as signing
      // For EIP-712, we need: keccak256("\x19\x01" || domainSeparator || hashStruct(message))
      // Simplified: hash the JSON representation with EIP-712 prefix
      final domain = typedData['domain'] as Map<String, dynamic>;
      final domainName = domain['name'] as String? ?? 'SSI Identity Manager';
      final domainVersion = domain['version'] as String? ?? '1';
      final chainId = domain['chainId'] is BigInt 
          ? domain['chainId'] as BigInt 
          : BigInt.from(domain['chainId'] ?? Environment.chainId);
      final verifyingContract = domain['verifyingContract'] as String? ?? Environment.contractAddress;

      // Hash domain (simplified)
      final domainTypeString = 'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)';
      final domainTypeHash = crypto.keccak256(Uint8List.fromList(utf8.encode(domainTypeString)));
      
      // Encode domain values
      final nameHash = crypto.keccak256(Uint8List.fromList(utf8.encode(domainName)));
      final versionHash = crypto.keccak256(Uint8List.fromList(utf8.encode(domainVersion)));
      final chainIdBytes = _padUint256(chainId);
      final contractBytes = _padAddress(verifyingContract);
      
      // Combine domain encoding
      final domainEncoding = Uint8List.fromList([
        ...domainTypeHash,
        ...nameHash,
        ...versionHash,
        ...chainIdBytes,
        ...contractBytes,
      ]);
      final domainSeparator = crypto.keccak256(domainEncoding);

      // Hash the message struct
      // For simplicity, we'll hash the JSON representation of the message
      // In production, implement proper struct hashing
      final message = typedData['message'] as Map<String, dynamic>;
      final messageJson = jsonEncode(message);
      final messageHash = crypto.keccak256(Uint8List.fromList(utf8.encode(messageJson)));

      // Create final hash: keccak256("\x19\x01" || domainSeparator || messageHash)
      final prefix = Uint8List.fromList([0x19, 0x01]);
      final finalHash = crypto.keccak256(Uint8List.fromList([
        ...prefix,
        ...domainSeparator,
        ...messageHash,
      ]));

      // Recover address using web3dart's ECDSA recovery
      // Create MsgSignature - web3dart uses recovery ID (v - 27) or just v
      // EIP-712 signatures typically use v = 27 or 28, but we need recovery ID 0 or 1
      final recoveryId = v >= 27 ? v - 27 : v;
      final msgSignature = crypto.MsgSignature(r, s, recoveryId);
      
      // ecRecover returns Uint8List (20 bytes for address)
      final addressBytes = crypto.ecRecover(finalHash, msgSignature);
      return _bytesToHex(addressBytes);
    } catch (e) {
      // If verification fails, return null
      debugPrint('Error recovering signature: $e');
      return null;
    }
  }

  /// Pad a uint256 to 32 bytes
  Uint8List _padUint256(BigInt value) {
    final hex = value.toRadixString(16).padLeft(64, '0');
    return Uint8List.fromList(_hexToBytes('0x$hex'));
  }

  /// Pad an address to 32 bytes (left-padded with zeros)
  Uint8List _padAddress(String address) {
    final addressBytes = _hexToBytes(address.startsWith('0x') ? address : '0x$address');
    final padded = Uint8List(32);
    padded.setRange(32 - addressBytes.length, 32, addressBytes);
    return padded;
  }
}

