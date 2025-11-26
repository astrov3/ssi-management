import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'SSI Blockchain'**
  String get appTitle;

  /// Login screen welcome message
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// Login screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Login to your identity wallet'**
  String get loginToIdentityWallet;

  /// Placeholder for private key input
  ///
  /// In en, this message translates to:
  /// **'Private Key or Mnemonic (12 words)'**
  String get privateKeyOrMnemonic;

  /// Divider text between login options
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// MetaMask connection button
  ///
  /// In en, this message translates to:
  /// **'Connect with MetaMask'**
  String get connectWithMetaMask;

  /// Trust Wallet connection button
  ///
  /// In en, this message translates to:
  /// **'Connect with Trust Wallet'**
  String get connectWithTrustWallet;

  /// Login button text
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// Login button loading state
  ///
  /// In en, this message translates to:
  /// **'Logging in...'**
  String get loggingIn;

  /// Validation error for empty private key
  ///
  /// In en, this message translates to:
  /// **'Please enter Private Key or Mnemonic'**
  String get pleaseEnterPrivateKeyOrMnemonic;

  /// Login error message
  ///
  /// In en, this message translates to:
  /// **'Login error: Invalid Private Key or Mnemonic'**
  String get loginError;

  /// MetaMask connection error
  ///
  /// In en, this message translates to:
  /// **'MetaMask connection failed'**
  String get metamaskConnectionFailed;

  /// MetaMask error message for account issues
  ///
  /// In en, this message translates to:
  /// **'Cannot get wallet information from MetaMask. Please ensure MetaMask is installed and logged in.'**
  String get cannotGetWalletInfoFromMetamask;

  /// MetaMask session error
  ///
  /// In en, this message translates to:
  /// **'MetaMask connection interrupted. Please try again.'**
  String get metamaskConnectionInterrupted;

  /// Trust Wallet connection error
  ///
  /// In en, this message translates to:
  /// **'Trust Wallet connection failed'**
  String get trustWalletConnectionFailed;

  /// Trust Wallet error message
  ///
  /// In en, this message translates to:
  /// **'Cannot get wallet information from Trust Wallet. Please ensure Trust Wallet is installed and logged in.'**
  String get cannotGetWalletInfoFromTrustWallet;

  /// Trust Wallet timeout error
  ///
  /// In en, this message translates to:
  /// **'Trust Wallet connection timed out. Please ensure Trust Wallet is opened and accepts the connection.'**
  String get trustWalletConnectionTimeout;

  /// Dashboard greeting
  ///
  /// In en, this message translates to:
  /// **'Hello,'**
  String get hello;

  /// Default user name
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// Wallet card title
  ///
  /// In en, this message translates to:
  /// **'Identity Wallet'**
  String get identityWallet;

  /// Network name
  ///
  /// In en, this message translates to:
  /// **'Sepolia Testnet'**
  String get sepoliaTestnet;

  /// Statistics section title
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// Credentials stat card
  ///
  /// In en, this message translates to:
  /// **'Credentials'**
  String get credentials;

  /// Verified stat card
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// Balance stat card
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// Register DID action
  ///
  /// In en, this message translates to:
  /// **'Register DID'**
  String get registerDid;

  /// Quick actions section title
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// Manage DID action
  ///
  /// In en, this message translates to:
  /// **'Manage DID'**
  String get manageDid;

  /// Manage DID subtitle
  ///
  /// In en, this message translates to:
  /// **'View and manage your DID'**
  String get viewAndManageYourDid;

  /// Issue credential action
  ///
  /// In en, this message translates to:
  /// **'Issue Credential'**
  String get issueCredential;

  /// Issue credential subtitle
  ///
  /// In en, this message translates to:
  /// **'Create and issue new VC'**
  String get createAndIssueNewVC;

  /// Register DID subtitle
  ///
  /// In en, this message translates to:
  /// **'Register identity on blockchain'**
  String get registerDidOnBlockchain;

  /// Loading indicator text
  ///
  /// In en, this message translates to:
  /// **'Loading data...'**
  String get loadingData;

  /// DID registration success message
  ///
  /// In en, this message translates to:
  /// **'DID has been registered! TX: {txHash}'**
  String didRegistered(String txHash);

  /// VC issue success message
  ///
  /// In en, this message translates to:
  /// **'VC has been issued! TX: {txHash}'**
  String vcIssued(String txHash);

  /// Error dialog title
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Error message with error detail
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorOccurred(String error);

  /// Close button
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Organization ID label
  ///
  /// In en, this message translates to:
  /// **'Organization ID'**
  String get organizationId;

  /// DID URI input label
  ///
  /// In en, this message translates to:
  /// **'DID URI (IPFS/URL)'**
  String get didUri;

  /// VC URI input label
  ///
  /// In en, this message translates to:
  /// **'VC URI (IPFS/URL)'**
  String get vcUri;

  /// Cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Register button
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// Issue button
  ///
  /// In en, this message translates to:
  /// **'Issue'**
  String get issue;

  /// Processing indicator
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// Address copied message
  ///
  /// In en, this message translates to:
  /// **'Address copied'**
  String get addressCopied;

  /// DID status card title
  ///
  /// In en, this message translates to:
  /// **'DID Status'**
  String get didStatus;

  /// Active status
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// Inactive status
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// Owner badge
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get owner;

  /// Profile screen title
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Wallet info option
  ///
  /// In en, this message translates to:
  /// **'Wallet Info'**
  String get walletInfo;

  /// Change wallet name option
  ///
  /// In en, this message translates to:
  /// **'Change Wallet Name'**
  String get changeWalletName;

  /// Backup keys option
  ///
  /// In en, this message translates to:
  /// **'Backup Keys'**
  String get backupKeys;

  /// Security option
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// Transaction history option
  ///
  /// In en, this message translates to:
  /// **'Transaction History'**
  String get transactionHistory;

  /// Settings option
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Help option
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// Coming soon badge
  ///
  /// In en, this message translates to:
  /// **'Soon'**
  String get soon;

  /// Logout button
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Logout confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Confirm Logout'**
  String get confirmLogout;

  /// Logout confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?\n\nMake sure you have backed up your Private Key or Mnemonic.'**
  String get confirmLogoutMessage;

  /// Wallet address label
  ///
  /// In en, this message translates to:
  /// **'Wallet Address'**
  String get walletAddress;

  /// Security warning
  ///
  /// In en, this message translates to:
  /// **'Do not share this information with anyone!'**
  String get doNotShareThisInfo;

  /// Change wallet name dialog title
  ///
  /// In en, this message translates to:
  /// **'Change Wallet Name'**
  String get changeWalletNameTitle;

  /// Wallet name label
  ///
  /// In en, this message translates to:
  /// **'Wallet Name'**
  String get walletName;

  /// Wallet name placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter a name for your wallet'**
  String get enterWalletName;

  /// Address label
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// Save button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Wallet name saved message
  ///
  /// In en, this message translates to:
  /// **'Wallet name saved'**
  String get walletNameSaved;

  /// Backup keys dialog title
  ///
  /// In en, this message translates to:
  /// **'Backup Keys'**
  String get backupKeysTitle;

  /// Backup keys warning
  ///
  /// In en, this message translates to:
  /// **'IMPORTANT: Save this information in a safe place!'**
  String get importantSaveInfo;

  /// Recovery phrase label
  ///
  /// In en, this message translates to:
  /// **'Recovery Phrase (12 words):'**
  String get recoveryPhrase;

  /// Mnemonic copied message
  ///
  /// In en, this message translates to:
  /// **'Mnemonic copied'**
  String get mnemonicCopied;

  /// Mnemonic unavailable message
  ///
  /// In en, this message translates to:
  /// **'Mnemonic not available.\nYou may have imported wallet using Private Key.'**
  String get mnemonicNotAvailable;

  /// No wallet message
  ///
  /// In en, this message translates to:
  /// **'No wallet connected'**
  String get noWalletConnected;

  /// Loading state
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Verification screen title
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get verification;

  /// QR code title
  ///
  /// In en, this message translates to:
  /// **'My QR Code'**
  String get myQrCode;

  /// QR code sharing message
  ///
  /// In en, this message translates to:
  /// **'Share this QR code so others can verify your identity'**
  String get shareQrCodeMessage;

  /// Verify VC button
  ///
  /// In en, this message translates to:
  /// **'Verify VC'**
  String get verifyVC;

  /// Manual input button
  ///
  /// In en, this message translates to:
  /// **'Manual Input'**
  String get manualInput;

  /// Scan QR dialog title
  ///
  /// In en, this message translates to:
  /// **'Scan QR'**
  String get scanQr;

  /// QR scanning coming soon message
  ///
  /// In en, this message translates to:
  /// **'QR scanning feature will be integrated in the next version'**
  String get qrScanningFeatureComingSoon;

  /// Manual input suggestion
  ///
  /// In en, this message translates to:
  /// **'Currently you can use the \"Manual Input\" feature'**
  String get youCanUseManualInput;

  /// Verify VC dialog title
  ///
  /// In en, this message translates to:
  /// **'Verify VC'**
  String get verifyVCTitle;

  /// VC index label
  ///
  /// In en, this message translates to:
  /// **'VC Index'**
  String get vcIndex;

  /// Credential hash label
  ///
  /// In en, this message translates to:
  /// **'Credential Hash'**
  String get credentialHash;

  /// Hash copied message
  ///
  /// In en, this message translates to:
  /// **'Hash copied'**
  String get hashCopied;

  /// Title for university degree credential type
  ///
  /// In en, this message translates to:
  /// **'University Degree'**
  String get universityDegree;

  /// Title for professional certificate credential type
  ///
  /// In en, this message translates to:
  /// **'Professional Certificate'**
  String get professionalCertificate;

  /// Credential type
  ///
  /// In en, this message translates to:
  /// **'ID Card'**
  String get idCard;

  /// Credential type
  ///
  /// In en, this message translates to:
  /// **'Driver\'s License'**
  String get driversLicense;

  /// Title for health insurance credential type
  ///
  /// In en, this message translates to:
  /// **'Health Insurance'**
  String get healthInsurance;

  /// Title for membership card credential type
  ///
  /// In en, this message translates to:
  /// **'Membership Card'**
  String get membershipCard;

  /// Credential type
  ///
  /// In en, this message translates to:
  /// **'Certificate'**
  String get certificate;

  /// Credential type
  ///
  /// In en, this message translates to:
  /// **'Badge'**
  String get badge;

  /// Language option
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Language selection dialog title
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// Network label
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get network;

  /// Verify button
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// Verification error message
  ///
  /// In en, this message translates to:
  /// **'Verification error: {error}'**
  String verificationError(String error);

  /// Valid status
  ///
  /// In en, this message translates to:
  /// **'Valid'**
  String get valid;

  /// Invalid status
  ///
  /// In en, this message translates to:
  /// **'Invalid'**
  String get invalid;

  /// Credential verified message
  ///
  /// In en, this message translates to:
  /// **'This credential has been verified and is valid'**
  String get credentialVerified;

  /// Credential invalid message
  ///
  /// In en, this message translates to:
  /// **'This credential is invalid or has been revoked'**
  String get credentialInvalid;

  /// Invalid index error
  ///
  /// In en, this message translates to:
  /// **'Invalid index'**
  String get invalidIndex;

  /// Loading credentials message
  ///
  /// In en, this message translates to:
  /// **'Loading credentials...'**
  String get loadingCredentials;

  /// No credentials message
  ///
  /// In en, this message translates to:
  /// **'No credentials'**
  String get noCredentials;

  /// Press add to add credential message
  ///
  /// In en, this message translates to:
  /// **'Press the + button to add a new credential'**
  String get pressAddToAddCredential;

  /// Please connect wallet message
  ///
  /// In en, this message translates to:
  /// **'Please connect wallet first'**
  String get pleaseConnectWallet;

  /// Creating VC and uploading message
  ///
  /// In en, this message translates to:
  /// **'Creating VC and uploading to IPFS...'**
  String get creatingVCAndUploading;

  /// Revoking VC message
  ///
  /// In en, this message translates to:
  /// **'Revoking VC...'**
  String get revokingVC;

  /// VC revoked message
  ///
  /// In en, this message translates to:
  /// **'VC has been revoked! TX: {txHash}'**
  String vcRevoked(String txHash);

  /// Issuer label
  ///
  /// In en, this message translates to:
  /// **'Issuer'**
  String get issuer;

  /// Index label
  ///
  /// In en, this message translates to:
  /// **'Index'**
  String get index;

  /// Copy hash button
  ///
  /// In en, this message translates to:
  /// **'Copy Hash'**
  String get copyHash;

  /// Revoke button
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get revoke;

  /// Revoked status
  ///
  /// In en, this message translates to:
  /// **'Revoked'**
  String get revoked;

  /// Issue new VC dialog title
  ///
  /// In en, this message translates to:
  /// **'Issue New VC'**
  String get issueNewVC;

  /// Credential type label
  ///
  /// In en, this message translates to:
  /// **'Credential Type'**
  String get credentialType;

  /// Credential name label
  ///
  /// In en, this message translates to:
  /// **'Credential Name'**
  String get credentialName;

  /// Description label
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// Example for credential type
  ///
  /// In en, this message translates to:
  /// **'Example: EducationalCredential, ProfessionalCredential'**
  String get exampleEducationalCredential;

  /// Example for credential name
  ///
  /// In en, this message translates to:
  /// **'Example: University Degree'**
  String get exampleUniversityDegree;

  /// Credential description hint
  ///
  /// In en, this message translates to:
  /// **'Detailed description of the credential'**
  String get credentialDescription;

  /// Unknown value
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// Bottom navigation bar label for dashboard/overview
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// Create wallet screen title
  ///
  /// In en, this message translates to:
  /// **'Create New Wallet'**
  String get createNewWallet;

  /// Create wallet screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Create decentralized\nidentity'**
  String get createDecentralizedIdentity;

  /// Full name label
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// Email label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Password label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Create wallet button
  ///
  /// In en, this message translates to:
  /// **'Create Wallet'**
  String get createWallet;

  /// Validation error for empty fields
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields'**
  String get pleaseFillAllFields;

  /// Wallet creation error message
  ///
  /// In en, this message translates to:
  /// **'Wallet creation error: {error}'**
  String walletCreationError(String error);

  /// Wallet created success title
  ///
  /// In en, this message translates to:
  /// **'Wallet Created'**
  String get walletCreated;

  /// Wallet address label
  ///
  /// In en, this message translates to:
  /// **'Your wallet address:'**
  String get yourWalletAddress;

  /// Save recovery phrase warning
  ///
  /// In en, this message translates to:
  /// **'Save the recovery phrase below!'**
  String get saveRecoveryPhrase;

  /// Recovery phrase copied message
  ///
  /// In en, this message translates to:
  /// **'Recovery phrase copied'**
  String get recoveryPhraseCopied;

  /// Continue button
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// Unlock wallet screen title
  ///
  /// In en, this message translates to:
  /// **'Unlock Wallet'**
  String get unlockWallet;

  /// Authentication screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Authenticate to access your wallet'**
  String get authenticateToAccessWallet;

  /// Biometric authentication button
  ///
  /// In en, this message translates to:
  /// **'Use Biometric'**
  String get useBiometric;

  /// Unlock button
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// Authentication button loading state
  ///
  /// In en, this message translates to:
  /// **'Authenticating...'**
  String get authenticating;

  /// Validation error for empty password
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get pleaseEnterPassword;

  /// Incorrect password error message
  ///
  /// In en, this message translates to:
  /// **'Incorrect password. Please try again.'**
  String get incorrectPassword;

  /// Biometric authentication error message
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication failed. Please try again or use password.'**
  String get biometricAuthenticationFailed;

  /// General authentication error message
  ///
  /// In en, this message translates to:
  /// **'Authentication error. Please try again.'**
  String get authenticationError;

  /// Setup password dialog title
  ///
  /// In en, this message translates to:
  /// **'Set up Password'**
  String get setupPassword;

  /// Setup password dialog description
  ///
  /// In en, this message translates to:
  /// **'Set a password to secure your wallet. You\'ll need this password to unlock your wallet in future sessions.'**
  String get setupPasswordDescription;

  /// Confirm password label
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// Password mismatch error
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match. Please try again.'**
  String get passwordsDoNotMatch;

  /// Enable biometric checkbox label
  ///
  /// In en, this message translates to:
  /// **'Enable Biometric Authentication'**
  String get enableBiometric;

  /// Biometric authentication description
  ///
  /// In en, this message translates to:
  /// **'Use fingerprint or face recognition to quickly unlock your wallet'**
  String get biometricDescription;

  /// Setup button
  ///
  /// In en, this message translates to:
  /// **'Setup'**
  String get setup;

  /// Skip button
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// Biometric not available message
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication is not available on this device'**
  String get biometricNotAvailable;

  /// Forgot password link
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgotPassword;

  /// Change account link
  ///
  /// In en, this message translates to:
  /// **'Change Account'**
  String get changeAccount;

  /// Support option
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// About option
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// Privacy policy link
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// Authenticate title
  ///
  /// In en, this message translates to:
  /// **'Authenticate'**
  String get authenticate;

  /// Fingerprint authentication instruction
  ///
  /// In en, this message translates to:
  /// **'Tap your fingerprint to authenticate'**
  String get tapFingerprintToAuthenticate;

  /// Face ID authentication instruction
  ///
  /// In en, this message translates to:
  /// **'Look at the screen to authenticate with Face ID'**
  String get tapFaceIdToAuthenticate;

  /// Retry button
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Change account screen description
  ///
  /// In en, this message translates to:
  /// **'Enter your private key or mnemonic and set a new password to change account'**
  String get changeAccountDescription;

  /// Reset password screen description
  ///
  /// In en, this message translates to:
  /// **'Enter your private key or mnemonic to reset your password'**
  String get resetPasswordDescription;

  /// New password label
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// Reset password button
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// Password reset success message
  ///
  /// In en, this message translates to:
  /// **'Password reset successfully'**
  String get passwordResetSuccess;

  /// Private key or mnemonic hint
  ///
  /// In en, this message translates to:
  /// **'Enter private key or mnemonic phrase'**
  String get enterPrivateKeyOrMnemonic;

  /// Success title
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// Use biometric login text
  ///
  /// In en, this message translates to:
  /// **'Use Biometric'**
  String get useBiometricLogin;

  /// Full name input hint
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get enterFullName;

  /// Email input hint
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterEmail;

  /// Invalid QR code dialog title
  ///
  /// In en, this message translates to:
  /// **'Invalid QR Code'**
  String get invalidQRCode;

  /// Invalid QR code error message
  ///
  /// In en, this message translates to:
  /// **'The scanned QR code does not contain valid SSI data. Please scan a valid DID, VC, or verification request QR code.'**
  String get invalidQRCodeMessage;

  /// QR scanner instruction
  ///
  /// In en, this message translates to:
  /// **'Position the QR code within the frame to scan'**
  String get positionQRCodeInFrame;

  /// Try again button
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// Details label
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// Verifiable credential label
  ///
  /// In en, this message translates to:
  /// **'Verifiable Credential'**
  String get verifiableCredential;

  /// Default wallet account name when no custom name is set
  ///
  /// In en, this message translates to:
  /// **'SSI Account'**
  String get defaultWalletName;

  /// Message shown when creating DID document and uploading it to IPFS
  ///
  /// In en, this message translates to:
  /// **'Creating DID document and uploading to IPFS...'**
  String get creatingDidAndUploadingToIpfs;

  /// Message shown when uploading a logo file to IPFS
  ///
  /// In en, this message translates to:
  /// **'Uploading logo to IPFS...'**
  String get uploadingLogoToIpfs;

  /// Message shown when uploading a document file to IPFS
  ///
  /// In en, this message translates to:
  /// **'Uploading document to IPFS...'**
  String get uploadingDocumentToIpfs;

  /// Message shown when creating DID document
  ///
  /// In en, this message translates to:
  /// **'Creating DID document...'**
  String get creatingDidDocument;

  /// Error message when the current wallet address cannot be retrieved
  ///
  /// In en, this message translates to:
  /// **'Cannot get current wallet address'**
  String get cannotGetCurrentWalletAddress;

  /// Message shown when sending a transaction to MetaMask and waiting for user confirmation
  ///
  /// In en, this message translates to:
  /// **'Sending transaction to MetaMask...\n\nPlease open MetaMask wallet and confirm the transaction.'**
  String get sendingTransactionToMetamask;

  /// Message shown when registering DID on the blockchain
  ///
  /// In en, this message translates to:
  /// **'Registering DID on blockchain...'**
  String get registeringDidOnBlockchain;

  /// Message shown when a trusted verifier is added
  ///
  /// In en, this message translates to:
  /// **'Trusted verifier added: {txHash}'**
  String trustedVerifierAdded(String txHash);

  /// Message shown when a trusted verifier is removed
  ///
  /// In en, this message translates to:
  /// **'Trusted verifier removed: {txHash}'**
  String trustedVerifierRemoved(String txHash);

  /// Subtitle message on authentication screen
  ///
  /// In en, this message translates to:
  /// **'Connect your wallet to continue'**
  String get connectYourWalletToContinue;

  /// Admin panel dialog title
  ///
  /// In en, this message translates to:
  /// **'Admin Panel - Manage Trusted Verifiers'**
  String get adminPanel;

  /// Label for verifier address input
  ///
  /// In en, this message translates to:
  /// **'Verifier Address *'**
  String get verifierAddress;

  /// Radio option to add/enable verifier
  ///
  /// In en, this message translates to:
  /// **'Add/Enable'**
  String get addEnable;

  /// Radio option to remove/disable verifier
  ///
  /// In en, this message translates to:
  /// **'Remove/Disable'**
  String get removeDisable;

  /// Validation message for empty verifier address
  ///
  /// In en, this message translates to:
  /// **'Please enter verifier address'**
  String get pleaseEnterVerifierAddress;

  /// Button to add verifier
  ///
  /// In en, this message translates to:
  /// **'Add Verifier'**
  String get addVerifier;

  /// Button to remove verifier
  ///
  /// In en, this message translates to:
  /// **'Remove Verifier'**
  String get removeVerifier;

  /// Subtitle for register DID dialog
  ///
  /// In en, this message translates to:
  /// **'Create your decentralized identity (DID)'**
  String get createYourDecentralizedIdentity;

  /// Tab label for form input
  ///
  /// In en, this message translates to:
  /// **'Fill form'**
  String get fillForm;

  /// Tab label for document upload
  ///
  /// In en, this message translates to:
  /// **'Upload document'**
  String get uploadDocument;

  /// Label for wallet address field
  ///
  /// In en, this message translates to:
  /// **'Wallet Address'**
  String get walletAddressLabel;

  /// Label for display name field
  ///
  /// In en, this message translates to:
  /// **'Display name *'**
  String get displayName;

  /// Hint for display name field
  ///
  /// In en, this message translates to:
  /// **'Enter your or your organization name'**
  String get enterYourOrOrgName;

  /// Hint for description field
  ///
  /// In en, this message translates to:
  /// **'Describe yourself or your organization (optional)'**
  String get describeYourselfOrOrg;

  /// Label for website field
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// Hint for address field
  ///
  /// In en, this message translates to:
  /// **'Contact address (optional)'**
  String get contactAddressOptional;

  /// Label for phone number field
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// Label for logo upload section
  ///
  /// In en, this message translates to:
  /// **'Logo (optional)'**
  String get logoOptional;

  /// Dialog title for choosing logo
  ///
  /// In en, this message translates to:
  /// **'Choose logo'**
  String get chooseLogo;

  /// Option to take photo with camera
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get takePhoto;

  /// Option to choose from gallery
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseFromGallery;

  /// Message showing selected logo filename
  ///
  /// In en, this message translates to:
  /// **'Selected logo: {filename}'**
  String selectedLogo(String filename);

  /// Hint for logo upload
  ///
  /// In en, this message translates to:
  /// **'Choose logo (JPG, PNG)'**
  String get chooseLogoJpgPng;

  /// Title for document upload section
  ///
  /// In en, this message translates to:
  /// **'Upload document to register DID'**
  String get uploadDocumentToRegisterDid;

  /// Description for upload tab
  ///
  /// In en, this message translates to:
  /// **'You can upload a PDF, JSON file, or image containing credential information. If it is a JSON file, metadata will be extracted automatically.'**
  String get uploadDocumentDescription;

  /// Label for document upload
  ///
  /// In en, this message translates to:
  /// **'Document *'**
  String get documentRequired;

  /// Text when document is selected
  ///
  /// In en, this message translates to:
  /// **'Document selected'**
  String get documentSelected;

  /// Hint for document upload
  ///
  /// In en, this message translates to:
  /// **'Choose document (PDF, JSON, JPG, PNG)'**
  String get chooseDocument;

  /// Note about JSON parsing
  ///
  /// In en, this message translates to:
  /// **'Note: JSON files will be parsed automatically to extract metadata. PDF and image files will be stored on IPFS.'**
  String get noteJsonWillBeParsed;

  /// Validation error for empty name
  ///
  /// In en, this message translates to:
  /// **'Please enter a name'**
  String get pleaseEnterName;

  /// Error message when document is not selected
  ///
  /// In en, this message translates to:
  /// **'Please choose document'**
  String get pleaseChooseDocument;

  /// Admin panel quick action
  ///
  /// In en, this message translates to:
  /// **'Admin Panel'**
  String get adminPanelAction;

  /// Admin panel subtitle
  ///
  /// In en, this message translates to:
  /// **'Manage trusted verifiers'**
  String get manageVerifiers;

  /// Update DID dialog title
  ///
  /// In en, this message translates to:
  /// **'Update DID'**
  String get updateDid;

  /// Title for document upload section in update DID
  ///
  /// In en, this message translates to:
  /// **'Upload document to update DID'**
  String get uploadDocumentToUpdateDid;

  /// Update button
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// Subtitle for update DID dialog
  ///
  /// In en, this message translates to:
  /// **'Update your decentralized identity (DID) information'**
  String get updateYourDidInformation;

  /// Error message when picking image fails
  ///
  /// In en, this message translates to:
  /// **'Error picking image: {error}'**
  String errorPickingImage(String error);

  /// Error message when picking file fails
  ///
  /// In en, this message translates to:
  /// **'Error picking file: {error}'**
  String errorPickingFile(String error);

  /// Cloudflare gateway label
  ///
  /// In en, this message translates to:
  /// **'Cloudflare'**
  String get cloudflare;

  /// Pinata gateway label
  ///
  /// In en, this message translates to:
  /// **'Pinata'**
  String get pinata;

  /// Default gateway label
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultGateway;

  /// Original URL label
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get original;

  /// Error when link cannot be opened
  ///
  /// In en, this message translates to:
  /// **'Cannot open link'**
  String get cannotOpenLink;

  /// Error when file cannot be opened
  ///
  /// In en, this message translates to:
  /// **'Cannot open file: {error}'**
  String cannotOpenFile(String error);

  /// Verified status label
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verifiedStatus;

  /// Unverified status label
  ///
  /// In en, this message translates to:
  /// **'Unverified'**
  String get unverified;

  /// View details button label
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get viewDetails;

  /// Verification queue screen title
  ///
  /// In en, this message translates to:
  /// **'Verification Queue'**
  String get verificationQueue;

  /// Refresh button tooltip
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// Empty state message for verification requests
  ///
  /// In en, this message translates to:
  /// **'No verification requests'**
  String get noVerificationRequests;

  /// Information message about trusted verifiers
  ///
  /// In en, this message translates to:
  /// **'Only trusted verifiers can see and process verification requests.'**
  String get onlyTrustedVerifiersCanSee;

  /// Success message when credential is verified
  ///
  /// In en, this message translates to:
  /// **'Credential verified successfully!\nHash: {hash}'**
  String credentialVerifiedSuccessfully(String hash);

  /// Error message during verification
  ///
  /// In en, this message translates to:
  /// **'Verification error: {error}'**
  String verificationErrorMessage(String error);

  /// Error when verification is cancelled in wallet
  ///
  /// In en, this message translates to:
  /// **'Verification was cancelled in wallet. Please try again.'**
  String get verificationCancelledInWallet;

  /// Error when verification times out
  ///
  /// In en, this message translates to:
  /// **'Verification request timed out. Please try again.'**
  String get verificationTimedOut;

  /// Confirmation dialog for cancelling verification
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this verification request?'**
  String get confirmCancelVerificationRequest;

  /// Success message when request is cancelled
  ///
  /// In en, this message translates to:
  /// **'Request cancelled successfully!\nHash: {hash}'**
  String requestCancelledSuccessfully(String hash);

  /// Error message when cancelling request fails
  ///
  /// In en, this message translates to:
  /// **'Error cancelling request: {error}'**
  String errorCancellingRequest(String error);

  /// Error when cancellation is rejected in wallet
  ///
  /// In en, this message translates to:
  /// **'Cancellation was rejected in wallet. Please try again.'**
  String get cancellationRejectedInWallet;

  /// Error when cancellation times out
  ///
  /// In en, this message translates to:
  /// **'Cancellation request timed out. Please try again.'**
  String get cancellationTimedOut;

  /// Helper text when owner can register or manage DID
  ///
  /// In en, this message translates to:
  /// **'You are an owner. Register or manage your DID.'**
  String get ownerRegisterOrManageDid;

  /// Title for DID information card
  ///
  /// In en, this message translates to:
  /// **'DID Information'**
  String get didInformation;

  /// Label for URI field
  ///
  /// In en, this message translates to:
  /// **'URI'**
  String get uriLabel;

  /// Label for issued at field
  ///
  /// In en, this message translates to:
  /// **'Issued At'**
  String get issuedAt;

  /// Label for expiration field
  ///
  /// In en, this message translates to:
  /// **'Expiration'**
  String get expiration;

  /// Generic copied message
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// Title when user is not a trusted verifier
  ///
  /// In en, this message translates to:
  /// **'You are not a trusted verifier'**
  String get notTrustedVerifierTitle;

  /// Message when user is not a trusted verifier
  ///
  /// In en, this message translates to:
  /// **'Only trusted verifiers can see and process verification requests.'**
  String get notTrustedVerifierMessage;

  /// Title when there are no verification requests
  ///
  /// In en, this message translates to:
  /// **'No verification requests'**
  String get noVerificationRequestsTitle;

  /// Message when there are no verification requests
  ///
  /// In en, this message translates to:
  /// **'New verification requests will appear here for quick processing.'**
  String get noVerificationRequestsMessage;

  /// Label for additional requests count
  ///
  /// In en, this message translates to:
  /// **'+{count} more request(s)'**
  String moreRequests(int count);

  /// Description text for manual verify card
  ///
  /// In en, this message translates to:
  /// **'Enter orgID, VC index and hash to verify manually when QR scanning is not possible.'**
  String get manualVerifyDescription;

  /// Message when wallet address is not available
  ///
  /// In en, this message translates to:
  /// **'Wallet address not found. Please open your wallet first.'**
  String get walletAddressNotFound;

  /// Message prompting user to connect wallet to display QR
  ///
  /// In en, this message translates to:
  /// **'Connect wallet or WalletConnect to display QR code.'**
  String get connectWalletToDisplayQr;

  /// Subtitle in credential picker sheet
  ///
  /// In en, this message translates to:
  /// **'Select credential to share'**
  String get selectCredentialToShare;

  /// VC number label
  ///
  /// In en, this message translates to:
  /// **'VC #{index}'**
  String vcNumber(int index);

  /// Short expiration label
  ///
  /// In en, this message translates to:
  /// **'Exp: {date}'**
  String expiryShort(String date);

  /// Status text for revoked
  ///
  /// In en, this message translates to:
  /// **'Revoked'**
  String get statusRevoked;

  /// Status text for verified
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get statusVerified;

  /// Status text for not verified
  ///
  /// In en, this message translates to:
  /// **'Not verified'**
  String get statusNotVerified;

  /// Label for OrgID in queue tile
  ///
  /// In en, this message translates to:
  /// **'OrgID'**
  String get queueOrgId;

  /// Label for sent time in queue tile
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get queueSent;

  /// Label for verifier in queue tile
  ///
  /// In en, this message translates to:
  /// **'Verifier'**
  String get queueVerifier;

  /// Label when any verifier is allowed
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get queueAny;

  /// Generic not-available label
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get notAvailable;

  /// Relative time in days
  ///
  /// In en, this message translates to:
  /// **'{count} day(s) ago'**
  String timeDaysAgo(int count);

  /// Relative time in hours
  ///
  /// In en, this message translates to:
  /// **'{count} hour(s) ago'**
  String timeHoursAgo(int count);

  /// Relative time in minutes
  ///
  /// In en, this message translates to:
  /// **'{count} minute(s) ago'**
  String timeMinutesAgo(int count);

  /// Relative time for just now
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get timeJustNow;

  /// Title for authorize issuer dialog
  ///
  /// In en, this message translates to:
  /// **'Authorize Issuer'**
  String get authorizeIssuer;

  /// Label for issuer address field
  ///
  /// In en, this message translates to:
  /// **'Issuer Address'**
  String get issuerAddress;

  /// Button label for authorize action
  ///
  /// In en, this message translates to:
  /// **'Authorize'**
  String get authorize;

  /// Subtitle for issue VC dialog
  ///
  /// In en, this message translates to:
  /// **'Create and issue Verifiable Credential'**
  String get createAndIssueVerifiableCredential;

  /// Label for credential type field
  ///
  /// In en, this message translates to:
  /// **'Credential Type *'**
  String get credentialTypeLabel;

  /// Hint for credential type field
  ///
  /// In en, this message translates to:
  /// **'Example: EducationalCredential, IdentityCredential'**
  String get credentialTypeHint;

  /// Label for subject name field
  ///
  /// In en, this message translates to:
  /// **'Subject Name *'**
  String get subjectNameLabel;

  /// Hint for subject name field
  ///
  /// In en, this message translates to:
  /// **'Name of credential recipient'**
  String get subjectNameHint;

  /// Label for subject email field
  ///
  /// In en, this message translates to:
  /// **'Subject Email'**
  String get subjectEmailLabel;

  /// Label for expiration date field
  ///
  /// In en, this message translates to:
  /// **'Expiration Date (optional)'**
  String get expirationDateOptional;

  /// Hint for expiration date field
  ///
  /// In en, this message translates to:
  /// **'Select expiration date'**
  String get selectExpirationDate;

  /// Title for upload tab
  ///
  /// In en, this message translates to:
  /// **'Upload document to issue VC'**
  String get uploadDocumentToIssueVC;

  /// Error message when subject name is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter subject name'**
  String get pleaseEnterSubjectName;

  /// Title for identity credential type
  ///
  /// In en, this message translates to:
  /// **'Government ID'**
  String get governmentId;

  /// Title for passport credential type
  ///
  /// In en, this message translates to:
  /// **'Passport'**
  String get passport;

  /// Title for driver license credential type
  ///
  /// In en, this message translates to:
  /// **'Driver License'**
  String get driverLicense;

  /// Title for training certificate credential type
  ///
  /// In en, this message translates to:
  /// **'Training Certificate'**
  String get trainingCertificate;

  /// Title for employment credential type
  ///
  /// In en, this message translates to:
  /// **'Employment Credential'**
  String get employmentCredential;

  /// Title for work permit credential type
  ///
  /// In en, this message translates to:
  /// **'Work Permit'**
  String get workPermit;

  /// Title for vaccination certificate credential type
  ///
  /// In en, this message translates to:
  /// **'Vaccination Certificate'**
  String get vaccinationCertificate;

  /// Generic credential title
  ///
  /// In en, this message translates to:
  /// **'Credential'**
  String get credential;

  /// Title when no DID exists
  ///
  /// In en, this message translates to:
  /// **'No DID'**
  String get noDid;

  /// Description when user has no DID yet
  ///
  /// In en, this message translates to:
  /// **'Register a DID to start using services'**
  String get registerDidToStartUsingServices;

  /// Message when DID has been deactivated
  ///
  /// In en, this message translates to:
  /// **'DID has been deactivated'**
  String get didDeactivated;

  /// Error when there is no DID information to show
  ///
  /// In en, this message translates to:
  /// **'No DID information available'**
  String get noDidInformationAvailable;

  /// Error when user tries to update DID without permission
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to update this DID'**
  String get noPermissionUpdateDid;

  /// Error when user tries to deactivate DID without permission
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to deactivate this DID'**
  String get noPermissionDeactivateDid;

  /// Error when user tries to authorize issuer without permission
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to authorize an issuer'**
  String get noPermissionAuthorizeIssuer;

  /// Error when issuer address is invalid
  ///
  /// In en, this message translates to:
  /// **'Issuer address is not valid'**
  String get issuerAddressNotValid;

  /// Spinner message when authorizing issuer
  ///
  /// In en, this message translates to:
  /// **'Authorizing issuer...'**
  String get authorizingIssuer;

  /// Success message when issuer is authorized
  ///
  /// In en, this message translates to:
  /// **'Issuer has been authorized successfully!'**
  String get issuerAuthorizedSuccessfully;

  /// Error message when authorizing issuer fails
  ///
  /// In en, this message translates to:
  /// **'Error authorizing issuer: {error}'**
  String errorAuthorizingIssuer(String error);

  /// Title for confirm deactivate DID dialog
  ///
  /// In en, this message translates to:
  /// **'Confirm DID deactivation'**
  String get confirmDeactivateDid;

  /// Warning message before deactivating DID
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to deactivate this DID? After deactivation, you will not be able to issue new VCs.'**
  String get deactivateDidWarning;

  /// Spinner message when deactivating DID
  ///
  /// In en, this message translates to:
  /// **'Deactivating DID...'**
  String get deactivatingDid;

  /// Button label for deactivating DID
  ///
  /// In en, this message translates to:
  /// **'Deactivate DID'**
  String get deactivateDid;

  /// Error message when deactivating DID fails
  ///
  /// In en, this message translates to:
  /// **'Error deactivating DID: {error}'**
  String errorDeactivatingDid(String error);

  /// Error when credential type is not selected
  ///
  /// In en, this message translates to:
  /// **'Please select credential type'**
  String get pleaseSelectCredentialType;

  /// Error when trying to scan QR before selecting type
  ///
  /// In en, this message translates to:
  /// **'Please select credential type first'**
  String get pleaseSelectCredentialTypeFirst;

  /// Success message when QR code data is parsed
  ///
  /// In en, this message translates to:
  /// **'Information filled from QR code'**
  String get informationFilledFromQR;

  /// Error when QR code cannot be parsed
  ///
  /// In en, this message translates to:
  /// **'Cannot read information from QR code'**
  String get cannotReadQRCode;

  /// Error message when QR scanning fails
  ///
  /// In en, this message translates to:
  /// **'Error scanning QR code: {error}'**
  String errorScanningQR(String error);

  /// Dialog title for image source selection
  ///
  /// In en, this message translates to:
  /// **'Select Image Source'**
  String get selectImageSource;

  /// Message when image is saved but OCR not available
  ///
  /// In en, this message translates to:
  /// **'Image saved. OCR will be supported in the next version.'**
  String get imageSavedOCRLater;

  /// Success message when OCR data is parsed
  ///
  /// In en, this message translates to:
  /// **'Information filled from image'**
  String get informationFilledFromImage;

  /// Error when OCR fails but image is saved
  ///
  /// In en, this message translates to:
  /// **'Cannot read information from image. Image saved.'**
  String get cannotReadFromImage;

  /// Error message when OCR fails
  ///
  /// In en, this message translates to:
  /// **'OCR error: {error}. Image saved.'**
  String errorOCR(String error);

  /// Dialog title for creating credential
  ///
  /// In en, this message translates to:
  /// **'Create New Credential'**
  String get createNewCredential;

  /// Title for credential type selection
  ///
  /// In en, this message translates to:
  /// **'Select Credential Type'**
  String get selectCredentialType;

  /// Button label for QR scanning
  ///
  /// In en, this message translates to:
  /// **'Scan QR'**
  String get scanQR;

  /// Button label for OCR from image
  ///
  /// In en, this message translates to:
  /// **'OCR from Image'**
  String get ocrFromImage;

  /// Button label for creating credential
  ///
  /// In en, this message translates to:
  /// **'Create Credential'**
  String get createCredential;

  /// Validation error when required fields are missing
  ///
  /// In en, this message translates to:
  /// **'Please fill in all required fields'**
  String get pleaseFillRequiredFields;

  /// Validation error for required field
  ///
  /// In en, this message translates to:
  /// **'{field} is required'**
  String fieldRequired(String field);

  /// Generic validation error message
  ///
  /// In en, this message translates to:
  /// **'Invalid value'**
  String get invalidValue;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
