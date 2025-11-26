import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:ssi_app/app/theme/app_colors.dart';
import 'package:ssi_app/core/widgets/glass_container.dart';
import 'package:ssi_app/l10n/app_localizations.dart';
import 'package:ssi_app/services/ipfs/pinata_service.dart';
import 'package:ssi_app/services/web3/web3_service.dart';

class QRDisplayScreen extends StatefulWidget {
  const QRDisplayScreen({
    super.key,
    required this.qrData,
  });

  final Map<String, dynamic> qrData;

  @override
  State<QRDisplayScreen> createState() => _QRDisplayScreenState();
}

class _QRDisplayScreenState extends State<QRDisplayScreen> {
  final _web3Service = Web3Service();
  final _pinataService = PinataService();
  bool _isLoading = true;
  Map<String, dynamic>? _fullData;
  bool? _signatureValid;
  bool? _onChainValid;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFullData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadFullData() async {
    try {
      final type = widget.qrData['type'] as String?;
      
      if (type == 'VC') {
        await _loadVCData();
      } else if (type == 'DID') {
        await _loadDIDData();
      } else if (type == 'VERIFICATION_REQUEST') {
        await _verifyRequest();
      } else {
        setState(() {
          _error = 'Unknown QR code type';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadVCData() async {
    try {
      final orgID = widget.qrData['orgID'] as String?;
      final uri = widget.qrData['uri'] as String?;
      final hashCredential = widget.qrData['hashCredential'] as String?;

      if (uri == null || uri.isEmpty) {
        setState(() {
          _error = 'VC URI not found';
          _isLoading = false;
        });
        return;
      }

      // Fetch VC document from IPFS
      final vcDoc = await _pinataService.getJSON(uri);
      
      // Verify signature if proof exists
      bool? sigValid;
      if (vcDoc['proof'] != null) {
        try {
          final issuer = vcDoc['issuer'] as String? ?? widget.qrData['issuer'] as String?;
          if (issuer != null) {
            sigValid = await _web3Service.verifyVCSignature(vcDoc, expectedIssuer: issuer);
          }
        } catch (_) {
          sigValid = null;
        }
      }

      // Verify on-chain if we have orgID and hash
      bool? onChainValid;
      if (orgID != null && hashCredential != null) {
        try {
          // Try to get VC index from QR data or find it
          final index = widget.qrData['index'] as int?;
          if (index != null) {
            onChainValid = await _web3Service.verifyVC(orgID, index, hashCredential);
          }
        } catch (_) {
          onChainValid = null;
        }
      }

      if (!mounted) return;
      setState(() {
        _fullData = vcDoc;
        _signatureValid = sigValid;
        _onChainValid = onChainValid;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load VC: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDIDData() async {
    try {
      final uri = widget.qrData['uri'] as String?;

      if (uri == null || uri.isEmpty) {
        setState(() {
          _error = 'DID URI not found';
          _isLoading = false;
        });
        return;
      }

      // Fetch DID document from IPFS
      final didDoc = await _pinataService.getJSON(uri);

      if (!mounted) return;
      setState(() {
        _fullData = didDoc;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load DID: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyRequest() async {
    try {
      final orgID = widget.qrData['orgID'] as String?;
      final vcIndex = widget.qrData['vcIndex'] as int?;

      if (orgID == null || vcIndex == null) {
        setState(() {
          _error = 'Invalid verification request';
          _isLoading = false;
        });
        return;
      }

      // Get VC data from blockchain
      final vc = await _web3Service.getVC(orgID, vcIndex);
      final hash = vc['hashCredential'] as String?;
      final uri = vc['uri'] as String?;

      if (hash == null) {
        setState(() {
          _error = 'VC not found';
          _isLoading = false;
        });
        return;
      }

      // Verify on-chain
      final isValid = await _web3Service.verifyVC(orgID, vcIndex, hash);

      // Fetch VC document if URI exists
      Map<String, dynamic>? vcDoc;
      bool? sigValid;
      if (uri != null && uri.isNotEmpty) {
        try {
          vcDoc = await _pinataService.getJSON(uri);
          if (vcDoc['proof'] != null) {
            final issuer = vcDoc['issuer'] as String?;
            if (issuer != null) {
              sigValid = await _web3Service.verifyVCSignature(vcDoc, expectedIssuer: issuer);
            }
          }
        } catch (_) {
          // Ignore IPFS fetch errors
        }
      }

      if (!mounted) return;
      setState(() {
        _fullData = {...vc, if (vcDoc != null) 'document': vcDoc};
        _onChainValid = isValid;
        _signatureValid = sigValid;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to verify: $e';
        _isLoading = false;
      });
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      final date = timestamp is int
          ? DateTime.fromMillisecondsSinceEpoch(timestamp)
          : DateTime.parse(timestamp.toString());
      return DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
    } catch (_) {
      return timestamp.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final type = widget.qrData['type'] as String?;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.grey[900]),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          type == 'VC' 
              ? (l10n.verifiableCredential.isNotEmpty ? l10n.verifiableCredential : 'Verifiable Credential')
              : type == 'DID' 
                  ? 'DID Document' 
                  : l10n.verification,
          style: TextStyle(color: Colors.grey[900]),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.secondary),
              )
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: AppColors.danger),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: TextStyle(color: Colors.grey[700]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                          ),
                          child: Text(l10n.close),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (type == 'VC') _buildVCDisplay(l10n),
                        if (type == 'DID') _buildDIDDisplay(l10n),
                        if (type == 'VERIFICATION_REQUEST') _buildVerificationDisplay(l10n),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildVCDisplay(AppLocalizations l10n) {
    final vcDoc = _fullData;
    if (vcDoc == null) {
      return const SizedBox.shrink();
    }

    final credentialSubject = vcDoc['credentialSubject'] as Map<String, dynamic>? ?? {};
    final type = (vcDoc['type'] as List?)?.join(', ') ?? 'VerifiableCredential';
    final issuer = vcDoc['issuer'] as String? ?? '';
    final issuanceDate = vcDoc['issuanceDate'] as String?;
    final expirationDate = vcDoc['expirationDate'] as String?;
    final id = vcDoc['id'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Status badges
        Row(
          children: [
            if (_onChainValid != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _onChainValid! ? AppColors.success : AppColors.danger,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _onChainValid! ? l10n.valid : l10n.revoked,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (_signatureValid != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _signatureValid! ? AppColors.success : AppColors.danger,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _signatureValid! ? 'Valid Sig' : 'Invalid Sig',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 24),
        // Credential details
        GlassContainer(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DetailRow(label: 'Type', value: type),
              if (id != null) _DetailRow(label: 'ID', value: id),
              _DetailRow(label: l10n.issuer, value: issuer),
              if (issuanceDate != null)
                _DetailRow(label: 'Issued At', value: _formatTimestamp(issuanceDate)),
              if (expirationDate != null)
                _DetailRow(label: 'Expiration', value: _formatTimestamp(expirationDate)),
              const SizedBox(height: 16),
              Text(
                'Credential Subject',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              ...credentialSubject.entries.map(
                (entry) => _DetailRow(
                  label: entry.key,
                  value: entry.value.toString(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDIDDisplay(AppLocalizations l10n) {
    final didDoc = _fullData;
    if (didDoc == null) {
      return const SizedBox.shrink();
    }

    final id = didDoc['id'] as String? ?? '';
    final controller = didDoc['controller'] as String?;
    final alsoKnownAs = didDoc['alsoKnownAs'] as List?;
    final service = didDoc['service'] as List?;
    final verificationMethod = didDoc['verificationMethod'] as List?;

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DetailRow(label: 'DID', value: id),
          if (controller != null) _DetailRow(label: 'Controller', value: controller),
          if (alsoKnownAs != null && alsoKnownAs.isNotEmpty)
            _DetailRow(label: 'Also Known As', value: alsoKnownAs.join(', ')),
          if (service != null && service.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Services',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
              ...service.map((s) {
                final serviceMap = s as Map<String, dynamic>;
                return _DetailRow(
                  label: serviceMap['type']?.toString() ?? 'Service',
                  value: serviceMap['serviceEndpoint']?.toString() ?? '',
                );
              }),
          ],
          if (verificationMethod != null && verificationMethod.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Verification Methods',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            ...verificationMethod.map((vm) {
              final vmMap = vm as Map<String, dynamic>;
              return _DetailRow(
                label: vmMap['type']?.toString() ?? 'Method',
                value: vmMap['id']?.toString() ?? '',
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildVerificationDisplay(AppLocalizations l10n) {
    final data = _fullData;
    if (data == null) {
      return const SizedBox.shrink();
    }

    final document = data['document'] as Map<String, dynamic>?;
    final valid = data['valid'] as bool?;
    final issuer = data['issuer'] as String?;
    final hash = data['hashCredential'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Verification result
        GlassContainer(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                _onChainValid == true ? Icons.check_circle : Icons.cancel,
                size: 64,
                color: _onChainValid == true ? AppColors.success : AppColors.danger,
              ),
              const SizedBox(height: 16),
              Text(
                _onChainValid == true ? l10n.valid : l10n.invalid,
                style: TextStyle(
                  color: _onChainValid == true ? AppColors.success : AppColors.danger,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_onChainValid == true)
                Text(
                  l10n.credentialVerified,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // VC details
        if (document != null) ...[
          GlassContainer(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (issuer != null) _DetailRow(label: l10n.issuer, value: issuer),
                if (hash != null) _DetailRow(label: 'Hash', value: hash),
                if (valid != null)
                  _DetailRow(label: 'Status', value: valid ? l10n.valid : l10n.revoked),
                const SizedBox(height: 16),
                Text(
                  'Credential Details',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                ...(document['credentialSubject'] as Map<String, dynamic>? ?? {}).entries.map(
                  (entry) => _DetailRow(
                    label: entry.key,
                    value: entry.value.toString(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

