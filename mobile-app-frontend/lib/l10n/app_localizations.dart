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

  /// Credential type
  ///
  /// In en, this message translates to:
  /// **'University Degree'**
  String get universityDegree;

  /// Credential type
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

  /// Credential type
  ///
  /// In en, this message translates to:
  /// **'Health Insurance'**
  String get healthInsurance;

  /// Credential type
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
