# SSI Mobile Application - Flutter Cross-Platform Identity Management

[![Flutter](https://img.shields.io/badge/Flutter-3.7.0-blue.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.7.0-blue.svg)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android-lightgrey)](https://flutter.dev)

> **A production-ready Flutter mobile application for managing Self-Sovereign Identity (SSI) on Ethereum blockchain, featuring wallet integration, QR code scanning, biometric authentication, and comprehensive credential management.**

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Technology Stack](#technology-stack)
- [Architecture](#architecture)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [Development](#development)
- [Testing](#testing)
- [Deployment](#deployment)
- [API Reference](#api-reference)
- [Troubleshooting](#troubleshooting)

---

## Overview

The SSI Mobile Application is a **cross-platform Flutter application** (iOS & Android) that provides a complete mobile interface for managing decentralized identities and verifiable credentials on the Ethereum blockchain. The app enables users to register DIDs, issue/verify credentials, scan QR codes, and manage their blockchain identity directly from their mobile devices.

### Key Capabilities

- **Blockchain Identity Management** - Register and manage DIDs on Ethereum
- **Credential Operations** - Issue, verify, and revoke verifiable credentials
- **QR Code Integration** - Generate and scan QR codes for credentials
- **Secure Authentication** - Biometric authentication and secure key storage
- **Document Processing** - OCR for document text recognition
- **Multi-language Support** - English and Vietnamese localization
- **Wallet Integration** - MetaMask, WalletConnect, and Coinbase Wallet support

---

## Features

### **Dashboard**
- Real-time wallet connection status
- Quick access to all features
- Statistics overview (DID count, VC count, verification status)
- Organization status display
- Quick action buttons for common tasks

### **DID Management**
- **Register DID**: Create new decentralized identity for organizations
- **View DID Details**: Display complete DID information
- **Update DID**: Modify existing DID data
- **DID Status**: Check active/inactive status
- **QR Code Generation**: Generate QR codes for DID sharing
- **Authorization Management**: Authorize issuers for credential creation

### **Credential Management**
- **Issue Credentials**: Create new verifiable credentials
- **View Credentials**: Browse all issued credentials
- **Credential Details**: View complete credential information
- **Verify Credentials**: Verify credential authenticity on-chain
- **Revoke Credentials**: Revoke credentials when necessary
- **Credential Templates**: Pre-defined templates for common credential types
- **File Attachments**: Attach documents/images to credentials

### **Verification System**
- **On-chain Verification**: Verify credentials directly on blockchain
- **QR Code Verification**: Scan QR codes to verify credentials
- **Verification Requests**: Request credential verification from verifiers
- **Verification History**: Track all verification attempts
- **Status Tracking**: Real-time verification status updates

### **QR Code Features**
- **QR Code Generation**: Generate QR codes for DIDs and VCs
- **QR Code Scanning**: Scan QR codes with camera
- **Data Extraction**: Automatically extract and process QR code data
- **Export Options**: Save QR codes as images
- **Batch Operations**: Generate multiple QR codes

### **Security Features**
- **Biometric Authentication**: Face ID / Touch ID / Fingerprint support
- **Secure Storage**: Encrypted key storage using Flutter Secure Storage
- **Wallet Security**: Secure wallet connection and transaction signing
- **Session Management**: Automatic session timeout
- **Privacy Controls**: User-controlled data sharing

### **Document Processing**
- **OCR Integration**: Google ML Kit text recognition
- **Image Picker**: Select images from gallery or camera
- **File Picker**: Support for various file types
- **PDF Viewer**: View PDF documents within app
- **Image Viewer**: Full-screen image viewing

### **Settings & Configuration**
- **Language Selection**: Switch between English and Vietnamese
- **Network Configuration**: Switch between testnet and mainnet
- **IPFS Settings**: Configure Pinata IPFS credentials
- **Wallet Management**: Manage connected wallets
- **App Preferences**: Customize app behavior

---

## Technology Stack

### **Core Framework**
- **Flutter** ^3.7.0 - Cross-platform mobile framework
- **Dart** ^3.7.0 - Programming language

### **Blockchain Integration**
- **web3dart** ^2.7.3 - Ethereum blockchain interaction
- **reown_appkit** ^1.0.1 - WalletConnect integration
- **eth_sig_util** ^0.0.9 - Ethereum signature utilities
- **bip39** ^1.0.6 - BIP39 mnemonic phrase support
- **ed25519_hd_key** ^2.3.0 - HD key derivation

### **UI/UX Libraries**
- **qr_flutter** ^4.1.0 - QR code generation
- **mobile_scanner** ^5.2.3 - QR code scanning
- **flutter_localizations** - Internationalization support
- **intl** ^0.20.2 - Date and number formatting

### **Security & Storage**
- **flutter_secure_storage** ^9.2.2 - Encrypted key storage
- **local_auth** ^2.3.0 - Biometric authentication
- **shared_preferences** ^2.5.3 - App preferences storage

### **Media & Files**
- **image_picker** ^1.1.2 - Image selection
- **file_picker** ^8.1.4 - File selection
- **google_mlkit_text_recognition** ^0.15.0 - OCR capabilities
- **webview_flutter** ^4.9.0 - Web content display

### **Networking & Services**
- **http** ^1.5.0 - HTTP requests
- **flutter_dotenv** ^6.0.0 - Environment configuration
- **url_launcher** ^6.3.1 - URL launching

### **Utilities**
- **crypto** ^3.0.5 - Cryptographic functions
- **hex** ^0.2.0 - Hex encoding/decoding
- **dotenv** ^4.2.0 - Environment variables

---

## Architecture

### **Project Structure**

```
lib/
├── app/                          # App configuration
│   ├── app.dart                  # Main app widget
│   ├── router/                   # Navigation routing
│   └── theme/                    # App theming
│
├── config/                       # Configuration
│   └── environment.dart          # Environment variables
│
├── core/                         # Core utilities
│   ├── utils/                    # Utility functions
│   └── widgets/                  # Reusable widgets
│
├── features/                     # Feature modules
│   ├── auth/                     # Authentication
│   ├── credentials/              # Credential management
│   ├── dashboard/                # Dashboard
│   ├── did/                      # DID management
│   ├── home/                     # Home screen
│   ├── profile/                  # User profile
│   ├── qr/                       # QR code features
│   ├── splash/                   # Splash screen
│   └── verify/                   # Verification
│
├── services/                     # Business logic services
│   ├── auth/                     # Authentication service
│   ├── credentials/              # Credential service
│   ├── ipfs/                     # IPFS integration
│   ├── localization/             # Language service
│   ├── ocr/                      # OCR service
│   ├── parser/                   # Document parser
│   ├── role/                     # Role management
│   ├── wallet/                   # Wallet services
│   └── web3/                     # Web3 service
│
└── l10n/                         # Localization files
    ├── app_en.arb                # English translations
    └── app_vi.arb                # Vietnamese translations
```

### **Architecture Pattern**

The app follows a **feature-based architecture** with clear separation of concerns:

- **Features**: Self-contained modules with views, models, and widgets
- **Services**: Reusable business logic and external integrations
- **Core**: Shared utilities and base widgets
- **App**: Application-level configuration

### **State Management**

- **Provider Pattern**: For dependency injection
- **Service Layer**: Business logic in service classes
- **Local State**: StatefulWidget for component-level state

### **Data Flow**

```
User Action → View → Service → Web3/IPFS → Blockchain
                ↓
            State Update
                ↓
            UI Refresh
```

---

## Installation

### Prerequisites

- **Flutter SDK** >= 3.7.0
- **Dart SDK** >= 3.7.0
- **Android Studio** / **Xcode** (for mobile development)
- **MetaMask Mobile** or compatible wallet app

### Setup Steps

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd ssi-project/mobile-app-frontend
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure environment**
   ```bash
   cp env.example .env
   ```

4. **Update `.env` file** with your configuration:
   ```env
   # Smart Contract Configuration
   CONTRACT_ADDRESS=0x...
   SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_KEY
   
   # IPFS Configuration (Pinata)
   PINATA_PROJECT_ID=your_pinata_project_id
   PINATA_PROJECT_SECRET=your_pinata_project_secret
   
   # App Configuration
   APP_NAME=SSI Mobile App
   NETWORK=sepolia
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

### Platform-Specific Setup

#### **Android**

1. **Minimum SDK**: Android 5.0 (API level 21)
2. **Target SDK**: Android 13 (API level 33)
3. **Permissions** (already configured in `AndroidManifest.xml`):
   - Camera (for QR scanning)
   - Internet
   - Biometric authentication

#### **iOS**

1. **Minimum iOS**: iOS 12.0
2. **Permissions** (configure in `Info.plist`):
   - Camera usage description
   - Face ID usage description
   - Photo library access

---

## Configuration

### Environment Variables

Create a `.env` file in the root directory:

```env
# Smart Contract
CONTRACT_ADDRESS=0x742d35Cc6634C0532925a3b8D1DE9c61F8E7c982
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_INFURA_KEY
MAINNET_RPC_URL=https://mainnet.infura.io/v3/YOUR_INFURA_KEY

# IPFS (Pinata)
PINATA_PROJECT_ID=your_project_id
PINATA_PROJECT_SECRET=your_project_secret
PINATA_GATEWAY=https://gateway.pinata.cloud/ipfs/

# App Settings
APP_NAME=SSI Identity Manager
APP_VERSION=1.0.0
NETWORK=sepolia
DEFAULT_LANGUAGE=en
```

### Smart Contract ABI

Ensure `IdentityManager.json` is in the `assets/` folder. This file contains the contract ABI for blockchain interactions.

---

## Usage

### 1. **First Launch**

1. Open the app
2. Grant necessary permissions (camera, biometrics)
3. Connect your wallet (MetaMask, WalletConnect, or Coinbase Wallet)
4. Approve wallet connection request

### 2. **Register DID**

1. Navigate to **Dashboard**
2. Tap **"Register DID"** button
3. Enter organization ID
4. Fill in DID information
5. Confirm transaction in wallet
6. Wait for blockchain confirmation

### 3. **Issue Credential**

1. Go to **Credentials** tab
2. Tap **"+"** button
3. Select credential template or create custom
4. Fill in credential details
5. Attach documents if needed
6. Tap **"Issue Credential"**
7. Confirm transaction

### 4. **Verify Credential**

1. Go to **Verification** tab
2. Tap **"Scan QR Code"** or enter credential details manually
3. Review verification information
4. Tap **"Verify"**
5. View verification result

### 5. **Scan QR Code**

1. Tap QR scanner icon
2. Point camera at QR code
3. App automatically processes QR data
4. View extracted information
5. Perform actions (verify, save, etc.)

---

## Development

### Running in Development Mode

```bash
# Run on connected device
flutter run

# Run on specific device
flutter run -d <device-id>

# Run with hot reload
flutter run --hot

# Run in debug mode
flutter run --debug
```

### Code Generation

```bash
# Generate localization files
flutter gen-l10n

# Analyze code
flutter analyze

# Format code
dart format lib/
```

### Building for Production

#### **Android APK**
```bash
flutter build apk --release
```

#### **Android App Bundle**
```bash
flutter build appbundle --release
```

#### **iOS**
```bash
flutter build ios --release
```

---

## Testing

### Unit Tests

```bash
flutter test
```

### Widget Tests

```bash
flutter test test/widget_test.dart
```

### Integration Tests

```bash
flutter test integration_test/
```

### Test Coverage

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

---

## Deployment

### Android Play Store

1. **Build App Bundle**
   ```bash
   flutter build appbundle --release
   ```

2. **Sign the bundle** (if not auto-signed)
3. **Upload to Google Play Console**
4. **Complete store listing**
5. **Submit for review**

### iOS App Store

1. **Build iOS app**
   ```bash
   flutter build ios --release
   ```

2. **Open in Xcode**
   ```bash
   open ios/Runner.xcworkspace
   ```

3. **Archive and upload** via Xcode
4. **Submit for App Store review**

### App Signing

#### **Android**
- Configure signing in `android/app/build.gradle`
- Use keystore for release builds

#### **iOS**
- Configure signing in Xcode
- Set up certificates and provisioning profiles

---

## API Reference

### **Web3Service**

Main service for blockchain interactions.

```dart
class Web3Service {
  Future<DIDInfo?> getDID(String orgID);
  Future<void> registerDID(String orgID, String hashData, String uri);
  Future<void> authorizeIssuer(String orgID, String issuerAddress);
  Future<int> issueVC(String orgID, String hashCredential, String uri);
  Future<VCInfo?> verifyVC(String orgID, int index);
  Future<void> revokeVC(String orgID, int index);
}
```

### **PinataService**

IPFS storage service.

```dart
class PinataService {
  Future<String> uploadJSON(Map<String, dynamic> data);
  Future<String> uploadFile(File file);
  Future<Map<String, dynamic>> retrieveJSON(String hash);
}
```

### **WalletConnectService**

Wallet connection service.

```dart
class WalletConnectService {
  Future<void> init();
  Future<void> connect();
  Future<void> disconnect();
  Future<String?> signMessage(String message);
}
```

### **AuthService**

Authentication service.

```dart
class AuthService {
  Future<bool> authenticateWithBiometrics();
  Future<void> saveCredentials(String key, String value);
  Future<String?> getCredentials(String key);
}
```

---

## Troubleshooting

### Common Issues

#### **Wallet Connection Failed**
- Ensure MetaMask/WalletConnect app is installed
- Check network configuration matches wallet network
- Restart app and try again

#### **Transaction Failed**
- Check wallet has sufficient ETH for gas
- Verify contract address is correct
- Ensure network matches (Sepolia vs Mainnet)

#### **QR Code Not Scanning**
- Grant camera permissions
- Ensure good lighting
- Check QR code is not damaged

#### **IPFS Upload Failed**
- Verify Pinata credentials in `.env`
- Check internet connection
- Ensure file size is within limits

### Debug Mode

Enable debug logging:
```dart
// In main.dart
void main() {
  debugPrint = (String? message, {int? wrapWidth}) {
    print('[DEBUG] $message');
  };
  runApp(SSIApp());
}
```

---

## Security Best Practices

1. **Never commit `.env` files** - Use `.env.example` as template
2. **Secure key storage** - Use Flutter Secure Storage for sensitive data
3. **Validate inputs** - Always validate user inputs before blockchain transactions
4. **Error handling** - Implement comprehensive error handling
5. **Biometric auth** - Use biometric authentication for sensitive operations
6. **Network security** - Use HTTPS for all API calls
7. **Code obfuscation** - Enable code obfuscation for release builds

---

## Performance Optimization

- **Image optimization**: Compress images before upload
- **Lazy loading**: Load data on demand
- **Caching**: Cache frequently accessed data
- **Code splitting**: Minimize app bundle size
- **Memory management**: Dispose controllers and streams properly

---

## Internationalization

The app supports multiple languages:

- **English** (en) - Default
- **Vietnamese** (vi)

### Adding New Language

1. Create `app_XX.arb` file in `lib/l10n/`
2. Add translations
3. Run `flutter gen-l10n`
4. Update language service

---

## Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

---

## License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details.

---

## Skills Demonstrated

- **Flutter Development**: Cross-platform mobile app development
- **Dart Programming**: Object-oriented programming, async/await
- **Blockchain Integration**: Web3, Ethereum, smart contract interaction
- **State Management**: Provider pattern, service layer architecture
- **UI/UX Design**: Material Design, responsive layouts
- **Security**: Biometric auth, secure storage, encryption
- **Testing**: Unit tests, widget tests, integration tests
- **DevOps**: CI/CD, app signing, store deployment

---

**Built with ❤️ using Flutter**

*Last updated: November 2025*
