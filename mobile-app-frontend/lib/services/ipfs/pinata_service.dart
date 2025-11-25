import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:web3dart/crypto.dart' as crypto;

import 'package:ssi_app/config/environment.dart';

class PinataService {
  static const String _pinataApiUrl = 'https://api.pinata.cloud';
  static const String _pinataGatewayUrl = 'https://gateway.pinata.cloud/ipfs';

  /// Upload JSON data to IPFS via Pinata
  Future<String> uploadJSON(Map<String, dynamic> jsonData) async {
    try {
      final url = Uri.parse('$_pinataApiUrl/pinning/pinJSONToIPFS');
      final headers = {
        'Content-Type': 'application/json',
        'pinata_api_key': Environment.pinataProjectId,
        'pinata_secret_api_key': Environment.pinataProjectSecret,
      };

      final body = jsonEncode({
        'pinataContent': jsonData,
        'pinataMetadata': {
          'name': 'SSI-${DateTime.now().millisecondsSinceEpoch}',
        },
      });

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final ipfsHash = responseData['IpfsHash'] as String;
        return 'ipfs://$ipfsHash';
      } else {
        throw Exception('Failed to upload to Pinata: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error uploading to IPFS: $e');
    }
  }

  /// Upload file data to IPFS via Pinata
  Future<String> uploadFile(Uint8List fileData, String fileName) async {
    try {
      final url = Uri.parse('$_pinataApiUrl/pinning/pinFileToIPFS');
      final headers = {
        'pinata_api_key': Environment.pinataProjectId,
        'pinata_secret_api_key': Environment.pinataProjectSecret,
      };

      final request = http.MultipartRequest('POST', url);
      request.headers.addAll(headers);
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileData,
          filename: fileName,
        ),
      );

      final pinataMetadata = {
        'name': fileName,
      };
      request.fields['pinataMetadata'] = jsonEncode(pinataMetadata);

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final responseData = jsonDecode(responseBody) as Map<String, dynamic>;
        final ipfsHash = responseData['IpfsHash'] as String;
        return 'ipfs://$ipfsHash';
      } else {
        throw Exception('Failed to upload file to Pinata: ${response.statusCode} - $responseBody');
      }
    } catch (e) {
      throw Exception('Error uploading file to IPFS: $e');
    }
  }

  /// Retrieve JSON data from IPFS with multi-gateway fallback
  Future<Map<String, dynamic>> getJSON(String ipfsUrl) async {
    final candidateUrls = _buildGatewayUrlCandidates(ipfsUrl);
    Object? lastError;

    for (final url in candidateUrls) {
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          return jsonDecode(response.body) as Map<String, dynamic>;
        }
        lastError = Exception('Failed to fetch from IPFS gateway ($url): ${response.statusCode}');
      } catch (e) {
        lastError = e;
      }
    }

    throw Exception('Error fetching from IPFS: ${lastError ?? 'No gateways available'}');
  }

  /// Convert ipfs:// URIs or plain hashes into a HTTP gateway URL (Pinata)
  String resolveToHttp(String ipfsUrl) {
    if (ipfsUrl.isEmpty) {
      return ipfsUrl;
    }

    if (ipfsUrl.startsWith('ipfs://')) {
      final hash = ipfsUrl.replaceFirst('ipfs://', '');
      return '$_pinataGatewayUrl/$hash';
    }

    if (!ipfsUrl.startsWith('http')) {
      return '$_pinataGatewayUrl/$ipfsUrl';
    }

    return ipfsUrl;
  }

  List<String> _buildGatewayUrlCandidates(String ipfsUrl) {
    final urls = <String>[];

    void addUrl(String url) {
      if (url.isEmpty) return;
      if (!urls.contains(url)) {
        urls.add(url);
      }
    }

    addUrl(resolveToHttp(ipfsUrl));

    final hash = _extractIpfsHash(ipfsUrl);
    if (hash != null && hash.isNotEmpty) {
      addUrl('https://ipfs.io/ipfs/$hash');
      addUrl('https://dweb.link/ipfs/$hash');
      addUrl('https://cloudflare-ipfs.com/ipfs/$hash');
    }

    return urls;
  }

  String? _extractIpfsHash(String ipfsUrl) {
    if (ipfsUrl.isEmpty) {
      return null;
    }
    if (ipfsUrl.startsWith('ipfs://')) {
      return ipfsUrl.replaceFirst('ipfs://', '');
    }
    final ipfsIndex = ipfsUrl.indexOf('/ipfs/');
    if (ipfsIndex != -1) {
      final hash = ipfsUrl.substring(ipfsIndex + 6);
      return hash.split('?').first;
    }
    final segments = ipfsUrl.split('/');
    if (segments.isNotEmpty) {
      return segments.last.split('?').first;
    }
    return null;
  }

  /// Create a DID document JSON structure
  Map<String, dynamic> createDIDDocument({
    required String id,
    required String controller,
    String? serviceEndpoint,
    List<String>? alsoKnownAs,
    Map<String, dynamic>? metadata,
  }) {
    final document = <String, dynamic>{
      '@context': [
        'https://www.w3.org/ns/did/v1',
        'https://w3id.org/security/suites/eip712sig-2021/v1',
      ],
      'id': id,
      'controller': controller,
      'verificationMethod': [
        {
          'id': '$id#keys-1',
          'type': 'EcdsaSecp256k1RecoveryMethod2020',
          'controller': controller,
          'blockchainAccountId': 'eip155:${Environment.chainId}:$controller',
        },
      ],
      'created': DateTime.now().toUtc().toIso8601String(),
      'updated': DateTime.now().toUtc().toIso8601String(),
    };

    if (serviceEndpoint != null && serviceEndpoint.isNotEmpty) {
      document['service'] = [
        {
          'id': '$id#service-1',
          'type': 'LinkedDomains',
          'serviceEndpoint': serviceEndpoint,
        },
      ];
    }

    if (alsoKnownAs != null && alsoKnownAs.isNotEmpty) {
      document['alsoKnownAs'] = alsoKnownAs;
    }

    if (metadata != null && metadata.isNotEmpty) {
      document['metadata'] = metadata;
    }

    return document;
  }

  /// Create a Verifiable Credential JSON structure
  Map<String, dynamic> createVerifiableCredential({
    required String id,
    required List<String> type,
    required String issuer,
    required String credentialSubject,
    required Map<String, dynamic> credentialData,
    String? expirationDate,
  }) {
    return {
      '@context': [
        'https://www.w3.org/2018/credentials/v1',
        'https://www.w3.org/2018/credentials/examples/v1',
      ],
      'id': id,
      'type': type,
      'issuer': issuer,
      'issuanceDate': DateTime.now().toIso8601String(),
      'expirationDate': expirationDate,
      'credentialSubject': {
        'id': credentialSubject,
        ...credentialData,
      },
      'proof': {
        'type': 'EthereumEip712Signature2021',
        'created': DateTime.now().toIso8601String(),
      },
    };
  }

  /// Generate hash from JSON data (for blockchain storage)
  String generateHash(Map<String, dynamic> jsonData) {
    final jsonString = jsonEncode(jsonData);
    final bytes = Uint8List.fromList(utf8.encode(jsonString));
    final hash = crypto.keccak256(bytes);
    // Convert Uint8List to hex string
    return '0x${hash.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';
  }
}

