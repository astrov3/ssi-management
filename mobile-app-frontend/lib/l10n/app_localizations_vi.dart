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
  String get copyHash => 'Sao chép';

  @override
  String get revoke => 'Thu hồi';

  @override
  String get revoked => 'Đã thu hồi';

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
  String get unknown => 'Không xác định';

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

  @override
  String get defaultWalletName => 'Tài khoản SSI';

  @override
  String get creatingDidAndUploadingToIpfs =>
      'Đang tạo DID document và upload lên IPFS...';

  @override
  String get uploadingLogoToIpfs => 'Đang upload logo lên IPFS...';

  @override
  String get uploadingDocumentToIpfs => 'Đang upload tài liệu lên IPFS...';

  @override
  String get creatingDidDocument => 'Đang tạo DID document...';

  @override
  String get cannotGetCurrentWalletAddress =>
      'Không thể lấy địa chỉ ví hiện tại';

  @override
  String get sendingTransactionToMetamask =>
      'Đang gửi transaction đến MetaMask...\n\nVui lòng mở MetaMask và xác nhận transaction.';

  @override
  String get registeringDidOnBlockchain =>
      'Đang đăng ký DID trên blockchain...';

  @override
  String trustedVerifierAdded(String txHash) {
    return 'Đã thêm trusted verifier: $txHash';
  }

  @override
  String trustedVerifierRemoved(String txHash) {
    return 'Đã xoá trusted verifier: $txHash';
  }

  @override
  String get connectYourWalletToContinue => 'Kết nối ví của bạn để tiếp tục';

  @override
  String get adminPanel => 'Quản trị - Quản lý Trusted Verifiers';

  @override
  String get verifierAddress => 'Địa chỉ Verifier *';

  @override
  String get addEnable => 'Thêm/Kích hoạt';

  @override
  String get removeDisable => 'Xóa/Vô hiệu hóa';

  @override
  String get pleaseEnterVerifierAddress => 'Vui lòng nhập địa chỉ verifier';

  @override
  String get addVerifier => 'Thêm Verifier';

  @override
  String get removeVerifier => 'Xóa Verifier';

  @override
  String get createYourDecentralizedIdentity =>
      'Tạo danh tính phi tập trung (DID) của bạn';

  @override
  String get fillForm => 'Điền form';

  @override
  String get uploadDocument => 'Tải lên tài liệu';

  @override
  String get walletAddressLabel => 'Địa chỉ ví';

  @override
  String get displayName => 'Tên hiển thị *';

  @override
  String get enterYourOrOrgName => 'Nhập tên của bạn hoặc tổ chức';

  @override
  String get describeYourselfOrOrg => 'Mô tả về bạn hoặc tổ chức (tùy chọn)';

  @override
  String get website => 'Website';

  @override
  String get contactAddressOptional => 'Địa chỉ liên hệ (tùy chọn)';

  @override
  String get phoneNumber => 'Số điện thoại';

  @override
  String get logoOptional => 'Logo (tùy chọn)';

  @override
  String get chooseLogo => 'Chọn logo';

  @override
  String get takePhoto => 'Chụp ảnh';

  @override
  String get chooseFromGallery => 'Chọn từ thư viện';

  @override
  String selectedLogo(String filename) {
    return 'Logo đã chọn: $filename';
  }

  @override
  String get chooseLogoJpgPng => 'Chọn logo (JPG, PNG)';

  @override
  String get uploadDocumentToRegisterDid => 'Tải lên tài liệu để đăng ký DID';

  @override
  String get uploadDocumentDescription =>
      'Bạn có thể upload file PDF, JSON, hoặc hình ảnh chứa thông tin credential. Nếu là file JSON, dữ liệu sẽ được tự động trích xuất.';

  @override
  String get documentRequired => 'Tài liệu *';

  @override
  String get documentSelected => 'Tài liệu đã chọn';

  @override
  String get chooseDocument => 'Chọn tài liệu (PDF, JSON, JPG, PNG)';

  @override
  String get noteJsonWillBeParsed =>
      'Lưu ý: File JSON sẽ được phân tích tự động để trích xuất metadata. File PDF và hình ảnh sẽ được lưu trên IPFS.';

  @override
  String get pleaseEnterName => 'Vui lòng nhập tên';

  @override
  String get pleaseChooseDocument => 'Vui lòng chọn tài liệu';

  @override
  String get adminPanelAction => 'Quản trị';

  @override
  String get manageVerifiers => 'Quản lý trusted verifiers';

  @override
  String get updateDid => 'Cập nhật DID';

  @override
  String get uploadDocumentToUpdateDid => 'Tải lên tài liệu để cập nhật DID';

  @override
  String get update => 'Cập nhật';

  @override
  String get updateYourDidInformation =>
      'Cập nhật thông tin danh tính phi tập trung (DID) của bạn';

  @override
  String errorPickingImage(String error) {
    return 'Lỗi chọn ảnh: $error';
  }

  @override
  String errorPickingFile(String error) {
    return 'Lỗi chọn file: $error';
  }

  @override
  String get cloudflare => 'Cloudflare';

  @override
  String get pinata => 'Pinata';

  @override
  String get defaultGateway => 'Mặc định';

  @override
  String get original => 'Gốc';

  @override
  String get cannotOpenLink => 'Không thể mở liên kết';

  @override
  String cannotOpenFile(String error) {
    return 'Không thể mở file: $error';
  }

  @override
  String get verifiedStatus => 'Đã xác minh';

  @override
  String get unverified => 'Chưa xác minh';

  @override
  String get viewDetails => 'Xem chi tiết';

  @override
  String get verificationQueue => 'Hàng đợi xác minh';

  @override
  String get refresh => 'Làm mới';

  @override
  String get noVerificationRequests => 'Không có yêu cầu xác minh';

  @override
  String get onlyTrustedVerifiersCanSee =>
      'Chỉ trusted verifiers mới có thể xem và xử lý yêu cầu xác minh.';

  @override
  String credentialVerifiedSuccessfully(String hash) {
    return 'Xác minh chứng chỉ thành công!\nHash: $hash';
  }

  @override
  String verificationErrorMessage(String error) {
    return 'Lỗi xác minh: $error';
  }

  @override
  String get verificationCancelledInWallet =>
      'Xác minh đã bị hủy trong ví. Vui lòng thử lại.';

  @override
  String get verificationTimedOut =>
      'Yêu cầu xác minh đã hết thời gian chờ. Vui lòng thử lại.';

  @override
  String get confirmCancelVerificationRequest =>
      'Bạn có chắc chắn muốn hủy yêu cầu xác minh này?';

  @override
  String requestCancelledSuccessfully(String hash) {
    return 'Đã hủy yêu cầu thành công!\nHash: $hash';
  }

  @override
  String errorCancellingRequest(String error) {
    return 'Lỗi hủy yêu cầu: $error';
  }

  @override
  String get cancellationRejectedInWallet =>
      'Hủy bỏ đã bị từ chối trong ví. Vui lòng thử lại.';

  @override
  String get cancellationTimedOut =>
      'Yêu cầu hủy đã hết thời gian chờ. Vui lòng thử lại.';

  @override
  String get ownerRegisterOrManageDid =>
      'Bạn là owner. Hãy đăng ký hoặc quản lý DID của bạn.';

  @override
  String get didInformation => 'Thông tin DID';

  @override
  String get uriLabel => 'URI';

  @override
  String get issuedAt => 'Thời gian phát hành';

  @override
  String get expiration => 'Thời gian hết hạn';

  @override
  String get copied => 'Đã sao chép';

  @override
  String get notTrustedVerifierTitle => 'Bạn không phải trusted verifier';

  @override
  String get notTrustedVerifierMessage =>
      'Chỉ trusted verifiers mới có thể xem và xử lý yêu cầu xác minh.';

  @override
  String get noVerificationRequestsTitle => 'Không có yêu cầu xác minh';

  @override
  String get noVerificationRequestsMessage =>
      'Các yêu cầu xác minh mới sẽ xuất hiện tại đây để xử lý nhanh.';

  @override
  String moreRequests(int count) {
    return '+$count yêu cầu khác';
  }

  @override
  String get manualVerifyDescription =>
      'Nhập orgID, VC index và hash để xác minh thủ công khi không thể quét QR.';

  @override
  String get walletAddressNotFound =>
      'Không tìm thấy địa chỉ ví. Vui lòng mở ví trước.';

  @override
  String get connectWalletToDisplayQr =>
      'Kết nối ví hoặc WalletConnect để hiển thị mã QR.';

  @override
  String get selectCredentialToShare => 'Chọn credential để chia sẻ';

  @override
  String vcNumber(int index) {
    return 'VC #$index';
  }

  @override
  String expiryShort(String date) {
    return 'HSD: $date';
  }

  @override
  String get statusRevoked => 'Đã thu hồi';

  @override
  String get statusVerified => 'Đã xác minh';

  @override
  String get statusNotVerified => 'Chưa xác minh';

  @override
  String get queueOrgId => 'OrgID';

  @override
  String get queueSent => 'Gửi';

  @override
  String get queueVerifier => 'Verifier';

  @override
  String get queueAny => 'Bất kỳ';

  @override
  String get notAvailable => 'N/A';

  @override
  String timeDaysAgo(int count) {
    return '$count ngày trước';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count giờ trước';
  }

  @override
  String timeMinutesAgo(int count) {
    return '$count phút trước';
  }

  @override
  String get timeJustNow => 'Vừa xong';

  @override
  String get authorizeIssuer => 'Ủy quyền Issuer';

  @override
  String get issuerAddress => 'Địa chỉ Issuer';

  @override
  String get authorize => 'Ủy quyền';

  @override
  String get createAndIssueVerifiableCredential =>
      'Tạo và phát hành Verifiable Credential';

  @override
  String get credentialTypeLabel => 'Loại Credential *';

  @override
  String get credentialTypeHint =>
      'Ví dụ: EducationalCredential, IdentityCredential';

  @override
  String get subjectNameLabel => 'Tên chủ thể *';

  @override
  String get subjectNameHint => 'Tên người nhận credential';

  @override
  String get subjectEmailLabel => 'Email chủ thể';

  @override
  String get expirationDateOptional => 'Ngày hết hạn (tùy chọn)';

  @override
  String get selectExpirationDate => 'Chọn ngày hết hạn';

  @override
  String get uploadDocumentToIssueVC => 'Upload tài liệu để phát hành VC';

  @override
  String get pleaseEnterSubjectName => 'Vui lòng nhập tên chủ thể';

  @override
  String get governmentId => 'Căn Cước Công Dân';

  @override
  String get passport => 'Hộ Chiếu';

  @override
  String get driverLicense => 'Bằng Lái Xe';

  @override
  String get trainingCertificate => 'Chứng Chỉ Đào Tạo';

  @override
  String get employmentCredential => 'Giấy Chứng Nhận Công Tác';

  @override
  String get workPermit => 'Giấy Phép Lao Động';

  @override
  String get vaccinationCertificate => 'Giấy Chứng Nhận Tiêm Chủng';

  @override
  String get credential => 'Chứng Nhận';

  @override
  String get noDid => 'Chưa có DID';

  @override
  String get registerDidToStartUsingServices =>
      'Đăng ký DID để bắt đầu sử dụng dịch vụ';

  @override
  String get didDeactivated => 'DID đã bị vô hiệu hóa';

  @override
  String get noDidInformationAvailable => 'Không có thông tin DID';

  @override
  String get noPermissionUpdateDid => 'Bạn không có quyền cập nhật DID này';

  @override
  String get noPermissionDeactivateDid =>
      'Bạn không có quyền vô hiệu hóa DID này';

  @override
  String get noPermissionAuthorizeIssuer =>
      'Bạn không có quyền ủy quyền issuer';

  @override
  String get issuerAddressNotValid => 'Địa chỉ issuer không hợp lệ';

  @override
  String get authorizingIssuer => 'Đang ủy quyền issuer...';

  @override
  String get issuerAuthorizedSuccessfully => 'Đã ủy quyền issuer thành công!';

  @override
  String errorAuthorizingIssuer(String error) {
    return 'Lỗi ủy quyền issuer: $error';
  }

  @override
  String get confirmDeactivateDid => 'Xác nhận vô hiệu hóa DID';

  @override
  String get deactivateDidWarning =>
      'Bạn có chắc chắn muốn vô hiệu hóa DID này? Sau khi vô hiệu hóa, bạn sẽ không thể phát hành VC mới.';

  @override
  String get deactivatingDid => 'Đang vô hiệu hóa DID...';

  @override
  String get deactivateDid => 'Vô hiệu hóa DID';

  @override
  String errorDeactivatingDid(String error) {
    return 'Lỗi vô hiệu hóa DID: $error';
  }

  @override
  String get pleaseSelectCredentialType => 'Vui lòng chọn loại chứng nhận';

  @override
  String get pleaseSelectCredentialTypeFirst =>
      'Vui lòng chọn loại chứng nhận trước';

  @override
  String get informationFilledFromQR => 'Đã điền thông tin từ QR code';

  @override
  String get cannotReadQRCode => 'Không thể đọc thông tin từ QR code';

  @override
  String errorScanningQR(String error) {
    return 'Lỗi quét QR code: $error';
  }

  @override
  String get selectImageSource => 'Chọn nguồn ảnh';

  @override
  String get imageSavedOCRLater =>
      'Đã lưu ảnh. OCR sẽ được hỗ trợ trong phiên bản tiếp theo.';

  @override
  String get informationFilledFromImage => 'Đã điền thông tin từ ảnh';

  @override
  String get cannotReadFromImage =>
      'Không thể đọc thông tin từ ảnh. Đã lưu ảnh.';

  @override
  String errorOCR(String error) {
    return 'Lỗi OCR: $error. Đã lưu ảnh.';
  }

  @override
  String get createNewCredential => 'Tạo Chứng Nhận Mới';

  @override
  String get selectCredentialType => 'Chọn loại chứng nhận';

  @override
  String get scanQR => 'Quét QR';

  @override
  String get ocrFromImage => 'OCR từ ảnh';

  @override
  String get createCredential => 'Tạo Chứng Nhận';

  @override
  String get pleaseFillRequiredFields =>
      'Vui lòng điền đầy đủ thông tin bắt buộc';

  @override
  String fieldRequired(String field) {
    return '$field là bắt buộc';
  }

  @override
  String get invalidValue => 'Giá trị không hợp lệ';

  @override
  String get requestVerificationTitle => 'Gửi yêu cầu xác thực';

  @override
  String get requestVerificationDescription =>
      'Toàn bộ nội dung credential sẽ được gửi tự động đến cơ quan xác thực.';

  @override
  String requestVerificationVcIndex(String index) {
    return 'VC Index: $index';
  }

  @override
  String get requestVerificationAddressLabel => 'Địa chỉ verifier *';

  @override
  String get requestVerificationAddressHint =>
      '0x... (để trống nếu cho phép bất kỳ verifier nào)';

  @override
  String get requestVerificationSubmit => 'Gửi yêu cầu';

  @override
  String get loadingCredentialInformation => 'Đang tải thông tin credential...';

  @override
  String unableToLoadCredentialInformation(String error) {
    return 'Không thể tải thông tin credential: $error';
  }

  @override
  String get credentialMissingInformation =>
      'Credential không có dữ liệu để gửi. Vui lòng kiểm tra lại.';

  @override
  String get uploadingFullCredential =>
      'Đang tải toàn bộ credential lên IPFS...';

  @override
  String get sendingVerificationRequest =>
      'Đang gửi yêu cầu xác thực lên blockchain...';

  @override
  String verificationRequestSuccess(String hash) {
    return 'Yêu cầu xác thực đã được gửi thành công!\\nHash: $hash';
  }

  @override
  String get verificationRequestCancelled =>
      'Yêu cầu xác thực đã bị hủy trong ví của bạn. Vui lòng thử lại.';

  @override
  String get verificationRequestGasLimitHigh =>
      'Gas limit quá cao. Hệ thống đã cố gắng điều chỉnh, nhưng ví của bạn có thể đang ước tính lại. Vui lòng thử lại hoặc giảm kích thước metadata nếu có thể.';

  @override
  String get verificationRequestTimeout =>
      'Yêu cầu xác thực đã hết thời gian. Vui lòng thử lại.';

  @override
  String get walletConnectSessionDisconnected =>
      'Phiên WalletConnect đã bị ngắt kết nối. Vui lòng kết nối lại ví.';

  @override
  String get verifyingCredential => 'Đang xác thực credential...';

  @override
  String get verifyCredentialDialogTitle => 'Xác thực credential';

  @override
  String get verifyCredentialDialogMessage =>
      'Bạn có chắc chắn muốn xác thực credential này?';

  @override
  String get verifyCredentialConfirm => 'Xác thực';

  @override
  String credentialVerifiedMessage(String hash) {
    return 'Credential đã được xác thực: $hash';
  }

  @override
  String get verifyCredentialCancelled =>
      'Xác thực credential đã bị hủy trong ví. Vui lòng thử lại.';

  @override
  String get requestVerificationButton => 'Gửi yêu cầu xác thực';

  @override
  String get verifyButton => 'Xác thực';

  @override
  String get credentialDetailsSectionTitle => 'Chi tiết';

  @override
  String get credentialFilesSectionTitle => 'Tệp đính kèm';

  @override
  String get credentialDetailTypeLabel => 'Loại';

  @override
  String get credentialDetailSubjectLabel => 'Chủ thể';

  @override
  String get credentialSignatureLabel => 'Chữ ký';

  @override
  String get credentialVerifiedByLabel => 'Được xác minh bởi';

  @override
  String get credentialVerifiedAtLabel => 'Thời gian xác minh';

  @override
  String get credentialGatewayLabel => 'Gateway';

  @override
  String get credentialGatewayDefault => 'Mặc định';

  @override
  String get credentialGatewayOriginal => 'Gốc';

  @override
  String get documentLabel => 'Tài liệu';

  @override
  String get openInBrowser => 'Mở trong trình duyệt';

  @override
  String get attachmentPreviewUnavailableTitle => 'Không thể xem trước tệp này';

  @override
  String get attachmentPreviewUnavailableSubtitle =>
      'Vui lòng thử gateway khác hoặc mở trong trình duyệt.';

  @override
  String get viewFileTooltip => 'Xem tệp';
}
