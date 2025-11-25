// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'SSI Blockchain';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get loginToIdentityWallet => 'Login to your identity wallet';

  @override
  String get privateKeyOrMnemonic => 'Private Key or Mnemonic (12 words)';

  @override
  String get or => 'or';

  @override
  String get connectWithMetaMask => 'Connect with MetaMask';

  @override
  String get connectWithTrustWallet => 'Connect with Trust Wallet';

  @override
  String get login => 'Login';

  @override
  String get loggingIn => 'Logging in...';

  @override
  String get pleaseEnterPrivateKeyOrMnemonic =>
      'Please enter Private Key or Mnemonic';

  @override
  String get loginError => 'Login error: Invalid Private Key or Mnemonic';

  @override
  String get metamaskConnectionFailed => 'MetaMask connection failed';

  @override
  String get cannotGetWalletInfoFromMetamask =>
      'Cannot get wallet information from MetaMask. Please ensure MetaMask is installed and logged in.';

  @override
  String get metamaskConnectionInterrupted =>
      'MetaMask connection interrupted. Please try again.';

  @override
  String get trustWalletConnectionFailed => 'Trust Wallet connection failed';

  @override
  String get cannotGetWalletInfoFromTrustWallet =>
      'Cannot get wallet information from Trust Wallet. Please ensure Trust Wallet is installed and logged in.';

  @override
  String get trustWalletConnectionTimeout =>
      'Trust Wallet connection timed out. Please ensure Trust Wallet is opened and accepts the connection.';

  @override
  String get hello => 'Hello,';

  @override
  String get user => 'User';

  @override
  String get identityWallet => 'Identity Wallet';

  @override
  String get sepoliaTestnet => 'Sepolia Testnet';

  @override
  String get statistics => 'Statistics';

  @override
  String get credentials => 'Credentials';

  @override
  String get verified => 'Verified';

  @override
  String get balance => 'Balance';

  @override
  String get registerDid => 'Register DID';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get manageDid => 'Manage DID';

  @override
  String get viewAndManageYourDid => 'View and manage your DID';

  @override
  String get issueCredential => 'Issue Credential';

  @override
  String get createAndIssueNewVC => 'Create and issue new VC';

  @override
  String get registerDidOnBlockchain => 'Register identity on blockchain';

  @override
  String get loadingData => 'Loading data...';

  @override
  String didRegistered(String txHash) {
    return 'DID has been registered! TX: $txHash';
  }

  @override
  String vcIssued(String txHash) {
    return 'VC has been issued! TX: $txHash';
  }

  @override
  String get error => 'Error';

  @override
  String errorOccurred(String error) {
    return 'Error: $error';
  }

  @override
  String get close => 'Close';

  @override
  String get organizationId => 'Organization ID';

  @override
  String get didUri => 'DID URI (IPFS/URL)';

  @override
  String get vcUri => 'VC URI (IPFS/URL)';

  @override
  String get cancel => 'Cancel';

  @override
  String get register => 'Register';

  @override
  String get issue => 'Issue';

  @override
  String get processing => 'Processing...';

  @override
  String get addressCopied => 'Address copied';

  @override
  String get didStatus => 'DID Status';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get owner => 'Owner';

  @override
  String get profile => 'Profile';

  @override
  String get walletInfo => 'Wallet Info';

  @override
  String get changeWalletName => 'Change Wallet Name';

  @override
  String get backupKeys => 'Backup Keys';

  @override
  String get security => 'Security';

  @override
  String get transactionHistory => 'Transaction History';

  @override
  String get settings => 'Settings';

  @override
  String get help => 'Help';

  @override
  String get soon => 'Soon';

  @override
  String get logout => 'Logout';

  @override
  String get confirmLogout => 'Confirm Logout';

  @override
  String get confirmLogoutMessage =>
      'Are you sure you want to logout?\n\nMake sure you have backed up your Private Key or Mnemonic.';

  @override
  String get walletAddress => 'Wallet Address';

  @override
  String get doNotShareThisInfo => 'Do not share this information with anyone!';

  @override
  String get changeWalletNameTitle => 'Change Wallet Name';

  @override
  String get walletName => 'Wallet Name';

  @override
  String get enterWalletName => 'Enter a name for your wallet';

  @override
  String get address => 'Address';

  @override
  String get save => 'Save';

  @override
  String get walletNameSaved => 'Wallet name saved';

  @override
  String get backupKeysTitle => 'Backup Keys';

  @override
  String get importantSaveInfo =>
      'IMPORTANT: Save this information in a safe place!';

  @override
  String get recoveryPhrase => 'Recovery Phrase (12 words):';

  @override
  String get mnemonicCopied => 'Mnemonic copied';

  @override
  String get mnemonicNotAvailable =>
      'Mnemonic not available.\nYou may have imported wallet using Private Key.';

  @override
  String get noWalletConnected => 'No wallet connected';

  @override
  String get loading => 'Loading...';

  @override
  String get verification => 'Verification';

  @override
  String get myQrCode => 'My QR Code';

  @override
  String get shareQrCodeMessage =>
      'Share this QR code so others can verify your identity';

  @override
  String get verifyVC => 'Verify VC';

  @override
  String get manualInput => 'Manual Input';

  @override
  String get scanQr => 'Scan QR';

  @override
  String get qrScanningFeatureComingSoon =>
      'QR scanning feature will be integrated in the next version';

  @override
  String get youCanUseManualInput =>
      'Currently you can use the \"Manual Input\" feature';

  @override
  String get verifyVCTitle => 'Verify VC';

  @override
  String get vcIndex => 'VC Index';

  @override
  String get credentialHash => 'Credential Hash';

  @override
  String get hashCopied => 'Hash copied';

  @override
  String get universityDegree => 'University Degree';

  @override
  String get professionalCertificate => 'Professional Certificate';

  @override
  String get idCard => 'ID Card';

  @override
  String get driversLicense => 'Driver\'s License';

  @override
  String get healthInsurance => 'Health Insurance';

  @override
  String get membershipCard => 'Membership Card';

  @override
  String get certificate => 'Certificate';

  @override
  String get badge => 'Badge';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get network => 'Network';

  @override
  String get verify => 'Verify';

  @override
  String verificationError(String error) {
    return 'Verification error: $error';
  }

  @override
  String get valid => 'Valid';

  @override
  String get invalid => 'Invalid';

  @override
  String get credentialVerified =>
      'This credential has been verified and is valid';

  @override
  String get credentialInvalid =>
      'This credential is invalid or has been revoked';

  @override
  String get invalidIndex => 'Invalid index';

  @override
  String get loadingCredentials => 'Loading credentials...';

  @override
  String get noCredentials => 'No credentials';

  @override
  String get pressAddToAddCredential =>
      'Press the + button to add a new credential';

  @override
  String get pleaseConnectWallet => 'Please connect wallet first';

  @override
  String get creatingVCAndUploading => 'Creating VC and uploading to IPFS...';

  @override
  String get revokingVC => 'Revoking VC...';

  @override
  String vcRevoked(String txHash) {
    return 'VC has been revoked! TX: $txHash';
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
  String get issueNewVC => 'Issue New VC';

  @override
  String get credentialType => 'Credential Type';

  @override
  String get credentialName => 'Credential Name';

  @override
  String get description => 'Description';

  @override
  String get exampleEducationalCredential =>
      'Example: EducationalCredential, ProfessionalCredential';

  @override
  String get exampleUniversityDegree => 'Example: University Degree';

  @override
  String get credentialDescription => 'Detailed description of the credential';

  @override
  String get unknown => 'Unknown';

  @override
  String get overview => 'Overview';

  @override
  String get createNewWallet => 'Create New Wallet';

  @override
  String get createDecentralizedIdentity => 'Create decentralized\nidentity';

  @override
  String get fullName => 'Full Name';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get createWallet => 'Create Wallet';

  @override
  String get pleaseFillAllFields => 'Please fill in all fields';

  @override
  String walletCreationError(String error) {
    return 'Wallet creation error: $error';
  }

  @override
  String get walletCreated => 'Wallet Created';

  @override
  String get yourWalletAddress => 'Your wallet address:';

  @override
  String get saveRecoveryPhrase => 'Save the recovery phrase below!';

  @override
  String get recoveryPhraseCopied => 'Recovery phrase copied';

  @override
  String get continueButton => 'Continue';

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
  String get invalidQRCode => 'Invalid QR Code';

  @override
  String get invalidQRCodeMessage =>
      'The scanned QR code does not contain valid SSI data. Please scan a valid DID, VC, or verification request QR code.';

  @override
  String get positionQRCodeInFrame =>
      'Position the QR code within the frame to scan';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get details => 'Details';

  @override
  String get verifiableCredential => 'Verifiable Credential';
}
