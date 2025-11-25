import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:ssi_app/app/theme/app_colors.dart';
import 'package:ssi_app/app/theme/app_gradients.dart';
import 'package:ssi_app/core/widgets/glass_container.dart';
import 'package:ssi_app/features/did/view/did_management_screen.dart';
import 'package:ssi_app/l10n/app_localizations.dart';
import 'package:ssi_app/services/role/role_service.dart';
import 'package:ssi_app/services/web3/web3_service.dart';
import 'package:ssi_app/services/wallet/wallet_connect_service.dart';
import 'package:ssi_app/services/wallet/wallet_name_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _web3Service = Web3Service();
  final _walletConnectService = WalletConnectService();
  final _roleService = RoleService();
  final _walletNameService = WalletNameService();
  String _address = 'Loading...';
  int _vcCount = 0;
  bool _isLoading = true;
  Map<String, dynamic>? _didData;
  bool _isOwner = false;
  bool _isAdmin = false;
  bool _isVerifier = false;
  String _walletName = 'SSI Account';

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  @override
  void dispose() {
    _roleService.dispose();
    super.dispose();
  }

  Future<void> _loadWalletData() async {
    try {
      // Try to load from Web3Service first (private key wallet)
      String? address = await _web3Service.loadWallet();
      
      // If not found, try WalletConnect service
      if (address == null) {
        debugPrint('[Dashboard] No private key wallet, checking WalletConnect...');
        address = await _walletConnectService.getStoredAddress();
        debugPrint('[Dashboard] WalletConnect address: $address');
      }
      
      if (address == null || address.isEmpty) {
        debugPrint('[Dashboard] No wallet address found');
        if (!mounted) return;
        setState(() {
          _address = 'No wallet connected';
          _isLoading = false;
        });
        return;
      }

      final vcs = await _safeFetchVCs(address);

      // Check DID status
      Map<String, dynamic>? didData;
      bool isOwner = false;
      try {
        didData = await _web3Service.getDID(address);
        if (didData != null) {
          isOwner = didData['owner'].toString().toLowerCase() == address.toLowerCase() && didData['active'] == true;
        }
      } catch (_) {
        // DID doesn't exist yet
      }

      // Get wallet name
      final walletName = await _walletNameService.getWalletName(address);

      // Check admin and verifier status
      bool isAdmin = false;
      bool isVerifier = false;
      try {
        final admin = await _web3Service.getAdmin();
        isAdmin = admin != null && admin.toLowerCase() == address.toLowerCase();
        
        isVerifier = await _web3Service.isTrustedVerifier(address);
      } catch (e) {
        debugPrint('[Dashboard] Error checking admin/verifier status: $e');
      }

      // Note: All users are owners and issuers by default
      // They can only authorize others to issue VCs for their DID
      // No need to check user role preference - users are always both

      if (!mounted) return;
      setState(() {
        _address = address!;
        _vcCount = vcs.length;
        _didData = didData;
        _isOwner = isOwner;
        _isAdmin = isAdmin;
        _isVerifier = isVerifier;
        _walletName = walletName ?? 'SSI Account';
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[Dashboard] Error loading wallet data: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _safeFetchVCs(String orgID) async {
    try {
      return await _web3Service.getVCs(orgID);
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  String _shortenAddress(String address) {
    if (address.length < 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 6)}';
  }

  void _copyToClipboard(String value, String message) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const _LoadingState()
            : RefreshIndicator(
                onRefresh: _loadWalletData,
                color: AppColors.secondary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DashboardHeader(
                        walletName: _walletName,
                        onNotificationsTap: () {},
                      ),
                      const SizedBox(height: 24),
                      _WalletCard(
                        address: _address,
                        walletName: _walletName,
                        formattedAddress: _shortenAddress(_address),
                        onCopy: () => _copyToClipboard(_address, AppLocalizations.of(context)!.addressCopied),
                      ),
                      const SizedBox(height: 32),
                      _StatisticsRow(vcCount: _vcCount),
                      if (_didData != null) ...[
                        const SizedBox(height: 24),
                        _DIDStatusCard(
                          didData: _didData!,
                          isOwner: _isOwner,
                          onManageTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const DIDManagementScreen()),
                            ).then((_) => _loadWalletData());
                          },
                        ),
                      ],
                      const SizedBox(height: 32),
                      _QuickActions(
                        orgId: _address,
                        isOwnerOnChain: _isOwner,
                        isAdmin: _isAdmin,
                        isVerifier: _isVerifier,
                        onRegister: _showRegisterDIDDialog,
                        onIssue: _showIssueVCDialog,
                        onManageDID: _didData != null && _isOwner
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const DIDManagementScreen()),
                                ).then((_) => _loadWalletData());
                              }
                            : null,
                        onAdminPanel: _isAdmin ? _showAdminPanel : null,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  void _showRegisterDIDDialog() {
    final orgIDController = TextEditingController(text: _address);
    final uriController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) => _RegisterDidDialog(
        orgIDController: orgIDController,
        uriController: uriController,
        onSubmit: (orgID, uri) async {
          Navigator.pop(context);
          await _registerDID(orgID, uri);
        },
      ),
    );
  }

  void _showAdminPanel() {
    final verifierAddressController = TextEditingController();
    bool isAdding = true;

    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Admin Panel - Manage Trusted Verifiers', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: verifierAddressController,
                  decoration: const InputDecoration(
                    labelText: 'Verifier Address *',
                    hintText: '0x...',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text('Add/Enable', style: TextStyle(color: Colors.white)),
                        value: true,
                        groupValue: isAdding,
                        onChanged: (value) => setState(() => isAdding = value!),
                        activeColor: AppColors.primary,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text('Remove/Disable', style: TextStyle(color: Colors.white)),
                        value: false,
                        groupValue: isAdding,
                        onChanged: (value) => setState(() => isAdding = value!),
                        activeColor: AppColors.danger,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (verifierAddressController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter verifier address'), backgroundColor: AppColors.danger),
                  );
                  return;
                }
                Navigator.pop(context);
                await _setTrustedVerifier(verifierAddressController.text.trim(), isAdding);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: Text(isAdding ? 'Add Verifier' : 'Remove Verifier'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setTrustedVerifier(String verifierAddress, bool allowed) async {
    final navigator = Navigator.of(context);
    try {
      _showBlockingSpinner();
      final txHash = await _web3Service.setTrustedVerifier(verifierAddress, allowed);
      navigator.pop();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Trusted verifier ${allowed ? 'added' : 'removed'}: ${txHash.substring(0, 10)}...'),
          backgroundColor: AppColors.success,
        ),
      );
      _loadWalletData();
    } catch (e) {
      navigator.pop();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _registerDID(String orgID, String uri) async {
    final navigator = Navigator.of(context);
    try {
      _showBlockingSpinner();
      final hashData = '0x${orgID.replaceAll('0x', '').padRight(64, '0').substring(0, 64)}';
      final txHash = await _web3Service.registerDID(orgID, hashData, uri);
      navigator.pop();
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.didRegistered('${txHash.substring(0, 10)}...')),
          backgroundColor: AppColors.success,
        ),
      );
      _loadWalletData();
    } catch (e) {
      navigator.pop();
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorOccurred(e.toString())), backgroundColor: AppColors.danger),
      );
    }
  }

  void _showIssueVCDialog() {
    final orgIDController = TextEditingController(text: _address);
    final uriController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) => _IssueVcDialog(
        orgIDController: orgIDController,
        uriController: uriController,
        onSubmit: (orgID, uri) async {
          Navigator.pop(context);
          await _issueVC(orgID, uri);
        },
      ),
    );
  }

  Future<void> _issueVC(String orgID, String uri) async {
    final navigator = Navigator.of(context);
    try {
      _showBlockingSpinner();
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final hashData = '0x${(orgID + timestamp).replaceAll('0x', '').padRight(64, '0').substring(0, 64)}';
      final txHash = await _web3Service.issueVC(orgID, hashData, uri);
      navigator.pop();
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.vcIssued('${txHash.substring(0, 10)}...')),
          backgroundColor: AppColors.success,
        ),
      );
      _loadWalletData();
    } catch (e) {
      navigator.pop();
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorOccurred(e.toString())), backgroundColor: AppColors.danger),
      );
    }
  }

  void _showBlockingSpinner() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.secondary),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.secondary),
          SizedBox(height: 16),
          Text('Đang tải dữ liệu...', style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.walletName,
    required this.onNotificationsTap,
  });

  final String walletName;
  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              walletName.isEmpty ? 'SSI Account' : walletName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        IconButton(
          onPressed: onNotificationsTap,
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
        ),
      ],
    );
  }
}

class _WalletCard extends StatelessWidget {
  const _WalletCard({
    required this.address,
    required this.walletName,
    required this.formattedAddress,
    required this.onCopy,
  });

  final String address;
  final String walletName;
  final String formattedAddress;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.all(Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x806366F1),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.identityWallet,
                style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: onCopy,
                    icon: const Icon(Icons.copy, color: Colors.white, size: 18),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.more_horiz, color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (walletName.isNotEmpty) ...[
            Text(
              walletName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              formattedAddress,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
                letterSpacing: 1.0,
                fontFamily: 'Courier',
              ),
            ),
          ] else
            Text(
              formattedAddress,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.verified, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(AppLocalizations.of(context)!.sepoliaTestnet, style: const TextStyle(color: Colors.white, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatisticsRow extends StatelessWidget {
  const _StatisticsRow({required this.vcCount});

  final int vcCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.statistics,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: AppLocalizations.of(context)!.credentials,
                value: vcCount.toString(),
                icon: Icons.card_membership,
                color: const Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: AppLocalizations.of(context)!.verified,
                value: vcCount.toString(),
                icon: Icons.verified,
                color: const Color(0xFF10B981),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      backgroundColor: Colors.white.withValues(alpha: 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            title,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      backgroundColor: Colors.white.withValues(alpha: 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.secondary, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.orgId,
    this.isOwnerOnChain = false,
    this.isAdmin = false,
    this.isVerifier = false,
    this.onRegister,
    required this.onIssue,
    this.onManageDID,
    this.onAdminPanel,
  });

  final String orgId;
  final bool isOwnerOnChain;
  final bool isAdmin;
  final bool isVerifier;
  final VoidCallback? onRegister;
  final VoidCallback onIssue;
  final VoidCallback? onManageDID;
  final VoidCallback? onAdminPanel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.quickActions,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        if (onManageDID != null)
          _QuickActionTile(
            title: AppLocalizations.of(context)!.manageDid,
            subtitle: AppLocalizations.of(context)!.viewAndManageYourDid,
            icon: Icons.badge,
            iconColor: AppColors.secondary,
            onTap: onManageDID!,
          ),
        _QuickActionTile(
          title: AppLocalizations.of(context)!.issueCredential,
          subtitle: AppLocalizations.of(context)!.createAndIssueNewVC,
          icon: Icons.add_card,
          iconColor: const Color(0xFF3B82F6),
          onTap: onIssue,
        ),
        // All users can register DID (they are owners by default)
        if (onRegister != null)
          _QuickActionTile(
            title: AppLocalizations.of(context)!.registerDid,
            subtitle: isOwnerOnChain 
                ? 'You are an owner. Register or manage your DID.'
                : AppLocalizations.of(context)!.registerDidOnBlockchain,
            icon: Icons.person_add,
            iconColor: AppColors.secondary,
            onTap: onRegister!,
          ),
        if (onAdminPanel != null)
          _QuickActionTile(
            title: 'Admin Panel',
            subtitle: 'Manage trusted verifiers',
            icon: Icons.admin_panel_settings,
            iconColor: Colors.orange,
            onTap: onAdminPanel!,
          ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: GlassContainer(
          borderRadius: 16,
          padding: const EdgeInsets.all(16),
          backgroundColor: Colors.white.withValues(alpha: 0.05),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.white.withValues(alpha: 0.3), size: 14),
            ],
          ),
        ),
      ),
    );
  }
}

class _RegisterDidDialog extends StatelessWidget {
  const _RegisterDidDialog({
    required this.orgIDController,
    required this.uriController,
    required this.onSubmit,
  });

  final TextEditingController orgIDController;
  final TextEditingController uriController;
  final void Function(String orgId, String uri) onSubmit;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(AppLocalizations.of(context)!.registerDid, style: const TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DialogTextField(label: AppLocalizations.of(context)!.organizationId, controller: orgIDController),
          const SizedBox(height: 16),
          _DialogTextField(label: AppLocalizations.of(context)!.didUri, controller: uriController),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.cancel, style: const TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: () => onSubmit(orgIDController.text, uriController.text),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
          child: Text(AppLocalizations.of(context)!.register),
        ),
      ],
    );
  }
}

class _IssueVcDialog extends StatelessWidget {
  const _IssueVcDialog({
    required this.orgIDController,
    required this.uriController,
    required this.onSubmit,
  });

  final TextEditingController orgIDController;
  final TextEditingController uriController;
  final void Function(String orgId, String uri) onSubmit;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(AppLocalizations.of(context)!.issueCredential, style: const TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DialogTextField(label: AppLocalizations.of(context)!.organizationId, controller: orgIDController),
          const SizedBox(height: 16),
          _DialogTextField(label: AppLocalizations.of(context)!.vcUri, controller: uriController),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.cancel, style: const TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: () => onSubmit(orgIDController.text, uriController.text),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: Text(AppLocalizations.of(context)!.issue),
        ),
      ],
    );
  }
}

class _DIDStatusCard extends StatelessWidget {
  const _DIDStatusCard({
    required this.didData,
    required this.isOwner,
    required this.onManageTap,
  });

  final Map<String, dynamic> didData;
  final bool isOwner;
  final VoidCallback onManageTap;

  @override
  Widget build(BuildContext context) {
    final active = didData['active'] as bool;
    return InkWell(
      onTap: onManageTap,
      borderRadius: BorderRadius.circular(20),
      child: GlassContainer(
        borderRadius: 20,
        padding: const EdgeInsets.all(20),
        backgroundColor: Colors.white.withValues(alpha: 0.05),
        borderColor: (active ? AppColors.success : AppColors.danger).withValues(alpha: 0.3),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.badge, color: AppColors.secondary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.didStatus,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (active ? AppColors.success : AppColors.danger).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          active ? AppLocalizations.of(context)!.active : AppLocalizations.of(context)!.inactive,
                          style: TextStyle(
                            color: active ? AppColors.success : AppColors.danger,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (isOwner) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.owner,
                            style: const TextStyle(
                              color: AppColors.secondary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white.withValues(alpha: 0.3), size: 16),
          ],
        ),
      ),
    );
  }
}

class _DialogTextField extends StatelessWidget {
  const _DialogTextField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
        ),
      ),
    );
  }
}

