// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'SSI Blockchain';

  @override
  String get welcomeBack => 'Chào mừng trở lại';

  @override
  String get loginToIdentityWallet => 'Đăng nhập vào ví danh tính của bạn';

  @override
  String get privateKeyOrMnemonic => 'Private Key hoặc Mnemonic (12 từ)';

  @override
  String get or => 'hoặc';

  @override
  String get connectWithMetaMask => 'Connect with MetaMask';

  @override
  String get connectWithTrustWallet => 'Connect with Trust Wallet';

  @override
  String get login => 'Đăng nhập';

  @override
  String get loggingIn => 'Đang đăng nhập...';

  @override
  String get pleaseEnterPrivateKeyOrMnemonic =>
      'Vui lòng nhập Private Key hoặc Mnemonic';

  @override
  String get loginError =>
      'Lỗi đăng nhập: Private Key hoặc Mnemonic không hợp lệ';

  @override
  String get metamaskConnectionFailed => 'Kết nối MetaMask thất bại';

  @override
  String get cannotGetWalletInfoFromMetamask =>
      'Không thể lấy thông tin ví từ MetaMask. Vui lòng đảm bảo MetaMask đã được cài đặt và đăng nhập.';

  @override
  String get metamaskConnectionInterrupted =>
      'Kết nối MetaMask bị gián đoạn. Vui lòng thử lại.';

  @override
  String get trustWalletConnectionFailed => 'Kết nối Trust Wallet thất bại';

  @override
  String get cannotGetWalletInfoFromTrustWallet =>
      'Không thể lấy thông tin ví từ Trust Wallet. Vui lòng đảm bảo Trust Wallet đã được cài đặt và đăng nhập.';

  @override
  String get trustWalletConnectionTimeout =>
      'Kết nối Trust Wallet quá thời gian chờ. Vui lòng đảm bảo Trust Wallet đã được mở và chấp nhận kết nối.';

  @override
  String get hello => 'Xin chào,';

  @override
  String get user => 'Người dùng';

  @override
  String get identityWallet => 'Ví Danh Tính';

  @override
  String get sepoliaTestnet => 'Sepolia Testnet';

  @override
  String get statistics => 'Thống kê';

  @override
  String get credentials => 'Chứng chỉ';

  @override
  String get verified => 'Đã xác minh';

  @override
  String get balance => 'Số dư';

  @override
  String get registerDid => 'Đăng ký DID';

  @override
  String get quickActions => 'Hành động nhanh';

  @override
  String get manageDid => 'Quản lý DID';

  @override
  String get viewAndManageYourDid => 'Xem và quản lý DID của bạn';

  @override
  String get issueCredential => 'Phát hành chứng chỉ';

  @override
  String get createAndIssueNewVC => 'Tạo và phát hành VC mới';

  @override
  String get registerDidOnBlockchain => 'Đăng ký danh tính trên blockchain';

  @override
  String get loadingData => 'Đang tải dữ liệu...';

  @override
  String didRegistered(String txHash) {
    return 'DID đã được đăng ký! TX: $txHash';
  }

  @override
  String vcIssued(String txHash) {
    return 'VC đã được phát hành! TX: $txHash';
  }

  @override
  String get error => 'Lỗi';

  @override
  String errorOccurred(String error) {
    return 'Lỗi: $error';
  }

  @override
  String get close => 'Đóng';

  @override
  String get organizationId => 'Organization ID';

  @override
  String get didUri => 'DID URI (IPFS/URL)';

  @override
  String get vcUri => 'VC URI (IPFS/URL)';

  @override
  String get cancel => 'Hủy';

  @override
  String get register => 'Đăng ký';

  @override
  String get issue => 'Phát hành';

  @override
  String get processing => 'Đang xử lý...';

  @override
  String get addressCopied => 'Đã sao chép địa chỉ';

  @override
  String get didStatus => 'DID Status';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get owner => 'Owner';

  @override
  String get profile => 'Hồ Sơ';

  @override
  String get walletInfo => 'Thông tin ví';

  @override
  String get changeWalletName => 'Đổi tên ví';

  @override
  String get backupKeys => 'Sao lưu khóa';

  @override
  String get security => 'Bảo mật';

  @override
  String get transactionHistory => 'Lịch sử giao dịch';

  @override
  String get settings => 'Cài đặt';

  @override
  String get help => 'Trợ giúp';

  @override
  String get soon => 'Soon';

  @override
  String get logout => 'Đăng xuất';

  @override
  String get confirmLogout => 'Xác nhận đăng xuất';

  @override
  String get confirmLogoutMessage =>
      'Bạn có chắc chắn muốn đăng xuất?\n\nĐảm bảo bạn đã sao lưu Private Key hoặc Mnemonic.';

  @override
  String get walletAddress => 'Địa chỉ ví';

  @override
  String get doNotShareThisInfo => 'Không chia sẻ thông tin này với bất kỳ ai!';

  @override
  String get changeWalletNameTitle => 'Đổi tên ví';

  @override
  String get walletName => 'Tên ví';

  @override
  String get enterWalletName => 'Nhập tên cho ví của bạn';

  @override
  String get address => 'Địa chỉ';

  @override
  String get save => 'Lưu';

  @override
  String get walletNameSaved => 'Đã lưu tên ví';

  @override
  String get backupKeysTitle => 'Sao lưu khóa';

  @override
  String get importantSaveInfo =>
      'QUAN TRỌNG: Lưu thông tin này ở nơi an toàn!';

  @override
  String get recoveryPhrase => 'Cụm từ khôi phục (12 từ):';

  @override
  String get mnemonicCopied => 'Đã sao chép mnemonic';

  @override
  String get mnemonicNotAvailable =>
      'Mnemonic không khả dụng.\nBạn có thể đã import ví bằng Private Key.';

  @override
  String get noWalletConnected => 'No wallet connected';

  @override
  String get loading => 'Loading...';

  @override
  String get verification => 'Xác Minh';

  @override
  String get myQrCode => 'Mã QR của tôi';

  @override
  String get shareQrCodeMessage =>
      'Chia sẻ mã QR này để người khác có thể xác minh danh tính của bạn';

  @override
  String get verifyVC => 'Xác minh VC';

  @override
  String get manualInput => 'Nhập thủ công';

  @override
  String get scanQr => 'Quét QR';

  @override
  String get qrScanningFeatureComingSoon =>
      'Chức năng quét QR sẽ được tích hợp trong phiên bản tiếp theo';

  @override
  String get youCanUseManualInput =>
      'Hiện tại bạn có thể sử dụng chức năng \"Nhập thủ công\"';

  @override
  String get verifyVCTitle => 'Xác minh VC';

  @override
  String get vcIndex => 'VC Index';

  @override
  String get credentialHash => 'Credential Hash';

  @override
  String get hashCopied => 'Đã sao chép hash';

  @override
  String get universityDegree => 'Bằng Đại Học';

  @override
  String get professionalCertificate => 'Chứng Chỉ Nghề Nghiệp';

  @override
  String get idCard => 'CMND/CCCD';

  @override
  String get driversLicense => 'Giấy Phép Lái Xe';

  @override
  String get healthInsurance => 'Bảo Hiểm Y Tế';

  @override
  String get membershipCard => 'Thẻ Thành Viên';

  @override
  String get certificate => 'Chứng Nhận';

  @override
  String get badge => 'Huy Hiệu';

  @override
  String get language => 'Ngôn ngữ';

  @override
  String get selectLanguage => 'Chọn ngôn ngữ';

  @override
  String get network => 'Mạng';

  @override
  String get verify => 'Xác minh';

  @override
  String verificationError(String error) {
    return 'Lỗi xác minh: $error';
  }

  @override
  String get valid => 'Hợp lệ';

  @override
  String get invalid => 'Không hợp lệ';

  @override
  String get credentialVerified =>
      'Chứng chỉ này đã được xác minh và còn hiệu lực';

  @override
  String get credentialInvalid =>
      'Chứng chỉ này không hợp lệ hoặc đã bị thu hồi';

  @override
  String get invalidIndex => 'Index không hợp lệ';

  @override
  String get loadingCredentials => 'Đang tải chứng chỉ...';

  @override
  String get noCredentials => 'Chưa có chứng chỉ';

  @override
  String get pressAddToAddCredential => 'Nhấn nút + để thêm chứng chỉ mới';

  @override
  String get pleaseConnectWallet => 'Vui lòng kết nối ví trước';

  @override
  String get creatingVCAndUploading => 'Đang tạo VC và upload lên IPFS...';

  @override
  String get revokingVC => 'Đang thu hồi VC...';

  @override
  String vcRevoked(String txHash) {
    return 'VC đã bị thu hồi! TX: $txHash';
  }

  @override
  String get issuer => 'Issuer';

  @override
  String get index => 'Index';

  @override
  String get copyHash => 'Copy Hash';

  @override
  String get revoke => 'Revoke';

  @override
  String get revoked => 'Revoked';

  @override
  String get issueNewVC => 'Phát hành VC mới';

  @override
  String get credentialType => 'Loại chứng chỉ';

  @override
  String get credentialName => 'Tên chứng chỉ';

  @override
  String get description => 'Mô tả';

  @override
  String get exampleEducationalCredential =>
      'Ví dụ: EducationalCredential, ProfessionalCredential';

  @override
  String get exampleUniversityDegree => 'Ví dụ: Bằng Đại Học';

  @override
  String get credentialDescription => 'Mô tả chi tiết về chứng chỉ';

  @override
  String get unknown => 'Unknown';

  @override
  String get overview => 'Tổng quan';

  @override
  String get createNewWallet => 'Create New Wallet';

  @override
  String get createDecentralizedIdentity => 'Create decentralized\nidentity';

  @override
  String get fullName => 'Tên đầy đủ';

  @override
  String get email => 'Email';

  @override
  String get password => 'Mật khẩu';

  @override
  String get createWallet => 'Create Wallet';

  @override
  String get pleaseFillAllFields => 'Please fill in all fields';

  @override
  String walletCreationError(String error) {
    return 'Wallet creation error: $error';
  }

  @override
  String get walletCreated => 'Ví đã được tạo';

  @override
  String get yourWalletAddress => 'Địa chỉ ví của bạn:';

  @override
  String get saveRecoveryPhrase => 'Lưu cụm từ khôi phục bên dưới!';

  @override
  String get recoveryPhraseCopied => 'Đã sao chép cụm từ khôi phục';

  @override
  String get continueButton => 'Tiếp tục';

  @override
  String get unlockWallet => 'Unlock Wallet';

  @override
  String get authenticateToAccessWallet => 'Authenticate to access your wallet';

  @override
  String get useBiometric => 'Use Biometric';

  @override
  String get unlock => 'Unlock';

  @override
  String get authenticating => 'Authenticating...';

  @override
  String get pleaseEnterPassword => 'Please enter your password';

  @override
  String get incorrectPassword => 'Incorrect password. Please try again.';

  @override
  String get biometricAuthenticationFailed =>
      'Biometric authentication failed. Please try again or use password.';

  @override
  String get authenticationError => 'Authentication error. Please try again.';

  @override
  String get setupPassword => 'Set up Password';

  @override
  String get setupPasswordDescription =>
      'Set a password to secure your wallet. You\'ll need this password to unlock your wallet in future sessions.';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match. Please try again.';

  @override
  String get enableBiometric => 'Enable Biometric Authentication';

  @override
  String get biometricDescription =>
      'Use fingerprint or face recognition to quickly unlock your wallet';

  @override
  String get setup => 'Setup';

  @override
  String get skip => 'Skip';

  @override
  String get biometricNotAvailable =>
      'Biometric authentication is not available on this device';

  @override
  String get forgotPassword => 'Forgot Password';

  @override
  String get changeAccount => 'Change Account';

  @override
  String get support => 'Support';

  @override
  String get about => 'About';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get authenticate => 'Authenticate';

  @override
  String get tapFingerprintToAuthenticate =>
      'Tap your fingerprint to authenticate';

  @override
  String get tapFaceIdToAuthenticate =>
      'Look at the screen to authenticate with Face ID';

  @override
  String get retry => 'Retry';

  @override
  String get changeAccountDescription =>
      'Enter your private key or mnemonic and set a new password to change account';

  @override
  String get resetPasswordDescription =>
      'Enter your private key or mnemonic to reset your password';

  @override
  String get newPassword => 'New Password';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get passwordResetSuccess => 'Password reset successfully';

  @override
  String get enterPrivateKeyOrMnemonic =>
      'Enter private key or mnemonic phrase';

  @override
  String get success => 'Success';

  @override
  String get useBiometricLogin => 'Use Biometric';

  @override
  String get enterFullName => 'Enter your full name';

  @override
  String get enterEmail => 'Enter your email';

  @override
  String get invalidQRCode => 'Mã QR không hợp lệ';

  @override
  String get invalidQRCodeMessage =>
      'Mã QR đã quét không chứa dữ liệu SSI hợp lệ. Vui lòng quét mã QR DID, VC hoặc yêu cầu xác minh hợp lệ.';

  @override
  String get positionQRCodeInFrame => 'Đặt mã QR trong khung để quét';

  @override
  String get tryAgain => 'Thử lại';

  @override
  String get details => 'Chi tiết';

  @override
  String get verifiableCredential => 'Chứng chỉ có thể xác minh';
}
