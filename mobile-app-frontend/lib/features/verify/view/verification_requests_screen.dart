import 'package:flutter/material.dart';
import 'package:ssi_app/app/theme/app_colors.dart';
import 'package:ssi_app/core/utils/navigation_utils.dart';
import 'package:ssi_app/services/ipfs/pinata_service.dart';
import 'package:ssi_app/services/web3/web3_service.dart';
import 'package:ssi_app/services/wallet/wallet_connect_service.dart';
import 'package:ssi_app/features/verify/widgets/verification_request_card.dart';
import 'package:ssi_app/features/verify/widgets/verification_request_detail_dialog.dart';
import 'package:ssi_app/l10n/app_localizations.dart';

class VerificationRequestsScreen extends StatefulWidget {
  const VerificationRequestsScreen({super.key});

  @override
  State<VerificationRequestsScreen> createState() => _VerificationRequestsScreenState();
}

class _VerificationRequestsScreenState extends State<VerificationRequestsScreen> {
  final _web3Service = Web3Service();
  final _pinataService = PinataService();
  final _walletConnectService = WalletConnectService();
  
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;
  String? _currentAddress;
  bool _isTrustedVerifier = false;

  /// Format hash/txHash safely, handling short strings
  String _formatHash(String hash, {int prefixLength = 10}) {
    if (hash.isEmpty) return '';
    if (hash.length <= prefixLength) {
      return hash; // Return as-is if too short
    }
    return '${hash.substring(0, prefixLength)}...';
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Lấy địa chỉ hiện tại
      String? address = await _web3Service.loadWallet();
      address ??= await _walletConnectService.getStoredAddress();
      _currentAddress = address;
      
      // Kiểm tra xem có phải trusted verifier không
      if (address != null) {
        _isTrustedVerifier = await _web3Service.isTrustedVerifier(address);
      }
      
      // Lấy danh sách verification requests (chỉ pending)
      final requests = await _web3Service.getAllVerificationRequests(onlyPending: true);
      
      if (mounted) {
        setState(() {
          _requests = requests;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading verification requests: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _canVerifyRequest(Map<String, dynamic> request) {
    if (!_isTrustedVerifier) return false;
    
    final targetVerifier = request['targetVerifier'] as String?;
    if (targetVerifier == null || targetVerifier.isEmpty) return true;
    
    if (targetVerifier.toLowerCase() == '0x0000000000000000000000000000000000000000') {
      return true;
    }
    
    return _currentAddress?.toLowerCase() == targetVerifier.toLowerCase();
  }

  bool _canCancelRequest(Map<String, dynamic> request) {
    final requester = request['requester'] as String?;
    return _currentAddress?.toLowerCase() == requester?.toLowerCase();
  }

  Future<void> _showRequestDetail(int index) async {
    final request = _requests[index];
    
    // Load credential từ metadataUri
    Map<String, dynamic>? credentialData;
    try {
      final metadataUri = request['metadataUri'] as String?;
      if (metadataUri != null && metadataUri.isNotEmpty) {
        credentialData = await _pinataService.getJSON(metadataUri);
      }
    } catch (e) {
      debugPrint('Error loading credential from metadataUri: $e');
    }
    
    if (!mounted) return;
    
    showDialog<void>(
      context: context,
      builder: (context) => VerificationRequestDetailDialog(
        request: request,
        credentialData: credentialData,
        isTrustedVerifier: _isTrustedVerifier,
        currentAddress: _currentAddress,
        onVerify: () async {
          Navigator.pop(context);
          await _verifyCredential(request);
        },
        onCancel: () async {
          Navigator.pop(context);
          await _cancelRequest(request);
        },
        onRefresh: _loadData,
      ),
    );
  }

  Future<void> _verifyCredential(Map<String, dynamic> request) async {
    try {
      _showBlockingSpinner(AppLocalizations.of(context)!.processing);
      
      final orgID = request['orgID'] as String;
      final vcIndex = request['vcIndex'] as int? ?? 0;
      
      final txHash = await _web3Service.verifyCredential(orgID, vcIndex);
      
      NavigationUtils.safePopDialog(mounted ? context : null);
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.credentialVerifiedSuccessfully(_formatHash(txHash)),
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
        ),
      );
      
      await _loadData();
    } catch (e) {
      // Safely dismiss dialog even if context is invalid
      NavigationUtils.safePopDialog(mounted ? context : null);
      
      // Clear pending flags if transaction was rejected
      if (e.toString().toLowerCase().contains('rejected') ||
          e.toString().toLowerCase().contains('denied')) {
        _walletConnectService.clearPendingFlags();
      }
      
      if (!mounted) return;
      
      // Provide user-friendly error message
      final l10n = AppLocalizations.of(context)!;
      String errorMessage = l10n.verificationErrorMessage(e.toString());
      if (e.toString().toLowerCase().contains('rejected') ||
          e.toString().toLowerCase().contains('denied')) {
        errorMessage = l10n.verificationCancelledInWallet;
      } else if (e.toString().toLowerCase().contains('timeout')) {
        errorMessage = l10n.verificationTimedOut;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppColors.danger,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _cancelRequest(Map<String, dynamic> request) async {
    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            AppLocalizations.of(context)!.cancel,
            style: const TextStyle(color: Colors.white),
          ),
          content: Text(
            AppLocalizations.of(context)!.confirmCancelVerificationRequest,
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
              ),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
          ],
        ),
      );

      if (result != true) return;

      _showBlockingSpinner(AppLocalizations.of(context)!.processing);
      
      final requestId = request['requestId'] as int? ?? 0;
      final txHash = await _web3Service.cancelVerificationRequest(requestId);
      
      NavigationUtils.safePopDialog(mounted ? context : null);
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.requestCancelledSuccessfully(_formatHash(txHash)),
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
        ),
      );
      
      await _loadData();
    } catch (e) {
      // Safely dismiss dialog even if context is invalid
      NavigationUtils.safePopDialog(mounted ? context : null);
      
      // Clear pending flags if transaction was rejected
      if (e.toString().toLowerCase().contains('rejected') ||
          e.toString().toLowerCase().contains('denied')) {
        _walletConnectService.clearPendingFlags();
      }
      
      if (!mounted) return;
      
      // Provide user-friendly error message
      final l10n = AppLocalizations.of(context)!;
      String errorMessage = l10n.errorCancellingRequest(e.toString());
      if (e.toString().toLowerCase().contains('rejected') ||
          e.toString().toLowerCase().contains('denied')) {
        errorMessage = l10n.cancellationRejectedInWallet;
      } else if (e.toString().toLowerCase().contains('timeout')) {
        errorMessage = l10n.cancellationTimedOut;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppColors.danger,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showBlockingSpinner([String? message]) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.secondary),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          AppLocalizations.of(context)!.verificationQueue,
          style: TextStyle(color: Colors.grey[900]),
        ),
        iconTheme: IconThemeData(color: Colors.grey[900]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: AppLocalizations.of(context)!.refresh,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.secondary),
              )
            : _requests.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)!.noVerificationRequests,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 16,
                          ),
                        ),
                        if (!_isTrustedVerifier) ...[
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(context)!.onlyTrustedVerifiersCanSee,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    color: AppColors.secondary,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _requests.length,
                      itemBuilder: (context, index) {
                        final request = _requests[index];
                        final canVerify = _canVerifyRequest(request);
                        final canCancel = _canCancelRequest(request);
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: VerificationRequestCard(
                            request: request,
                            isTrustedVerifier: _isTrustedVerifier,
                            currentAddress: _currentAddress,
                            onTap: () => _showRequestDetail(index),
                            onVerify: canVerify ? () => _verifyCredential(request) : null,
                            onCancel: canCancel ? () => _cancelRequest(request) : null,
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}

