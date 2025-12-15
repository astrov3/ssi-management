# SSI Web Frontend - React-Based Identity Management Platform

[![React](https://img.shields.io/badge/React-19.1.1-blue.svg)](https://react.dev)
[![Vite](https://img.shields.io/badge/Vite-7.1.7-purple.svg)](https://vitejs.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Web3](https://img.shields.io/badge/Web3-Enabled-green)](https://web3.foundation)

> **A modern, responsive React web application for managing Self-Sovereign Identity (SSI) on Ethereum blockchain, featuring real-time blockchain interactions, IPFS integration, QR code functionality, and comprehensive credential management.**

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Technology Stack](#technology-stack)
- [Architecture](#architecture)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage Guide](#usage-guide)
- [Development](#development)
- [Deployment](#deployment)
- [API Reference](#api-reference)
- [Troubleshooting](#troubleshooting)

---

## Overview

The SSI Web Frontend is a **production-ready React application** built with modern web technologies to provide a seamless interface for managing decentralized identities and verifiable credentials on the Ethereum blockchain. The application enables organizations to register DIDs, issue credentials, verify authenticity, and manage their blockchain identity through an intuitive web interface.

### Key Capabilities

- **Blockchain Integration** - Direct interaction with Ethereum smart contracts
- **Credential Management** - Complete lifecycle management for verifiable credentials
- **QR Code Support** - Generate and scan QR codes for credentials
- **IPFS Integration** - Decentralized storage for identity documents
- **Wallet Connectivity** - MetaMask and WalletConnect support
- **Real-time Dashboard** - Live statistics and status updates
- **Modern UI/UX** - Responsive design with Tailwind CSS

---

## Features

### **Dashboard**
- **Wallet Connection Status** - Real-time connection monitoring
- **Quick Actions** - Fast access to common operations
- **Statistics Overview** - Total DIDs, VCs, active credentials
- **Organization Status** - Current DID status and information
- **Recent Activity** - Latest transactions and operations
- **Network Information** - Current blockchain network

### **DID Management**
- **Register DID** - Create new decentralized identity
- **View DID Details** - Complete DID information display
- **Check DID Status** - Active/inactive status verification
- **Update DID** - Modify existing DID information
- **QR Code Generation** - Generate QR codes for DID sharing
- **Issuer Authorization** - Authorize addresses to issue credentials

### **VC Operations**
- **Issue Credentials** - Create new verifiable credentials
- **Verify Credentials** - On-chain credential verification
- **Revoke Credentials** - Revoke credentials when necessary
- **View Credential List** - Browse all issued credentials
- **Credential Details** - Complete credential information
- **Batch Operations** - Manage multiple credentials

### **QR Code Features**
- **QR Code Generation** - Generate QR codes for DIDs and VCs
- **QR Code Scanning** - Scan QR codes using device camera
- **Data Extraction** - Automatic processing of QR code data
- **Export Options** - Download QR codes as images
- **Verification Integration** - Direct verification from QR codes

### **Settings**
- **Network Configuration** - Switch between testnet and mainnet
- **IPFS Settings** - Configure Pinata IPFS credentials
- **Wallet Management** - Manage connected wallets
- **App Preferences** - Customize application behavior
- **Contract Configuration** - Update smart contract address

---

## Technology Stack

### **Core Framework**
- **React** ^19.1.1 - Modern React with latest features
- **Vite** ^7.1.7 - Fast build tool and dev server
- **React Router** ^6.28.0 - Client-side routing

### **Styling & UI**
- **Tailwind CSS** ^3.4.18 - Utility-first CSS framework
- **Lucide React** ^0.468.0 - Modern icon library
- **React Hot Toast** ^2.6.0 - Toast notifications

### **Blockchain & Web3**
- **Ethers.js** ^6.15.0 - Ethereum JavaScript library
- **Web3 Integration** - Direct smart contract interaction

### **State Management**
- **Zustand** ^5.0.2 - Lightweight state management

### **QR Code**
- **qrcode** ^1.5.4 - QR code generation
- **html5-qrcode** ^2.3.8 - QR code scanning

### **Utilities**
- **Axios** ^1.13.2 - HTTP client
- **date-fns** ^4.1.0 - Date manipulation
- **clsx** ^2.1.1 - Conditional class names

### **Development Tools**
- **ESLint** ^9.36.0 - Code linting
- **PostCSS** ^8.5.6 - CSS processing
- **Autoprefixer** ^10.4.21 - CSS vendor prefixes

---

## Architecture

### **Project Structure**

```
src/
├── components/              # Reusable React components
│   ├── Layout.jsx          # Main layout component
│   └── QRScanner.jsx        # QR code scanner component
│
├── pages/                   # Page components
│   ├── Dashboard.jsx       # Dashboard page
│   ├── DIDManagement.jsx   # DID management page
│   ├── VCOperations.jsx    # VC operations page
│   └── Settings.jsx         # Settings page
│
├── services/                # Business logic services
│   ├── web3/                # Web3 service
│   ├── wallet/              # Wallet services
│   └── role/                # Role management
│
├── store/                   # State management
│   └── useStore.js          # Zustand store
│
├── utils/                   # Utility functions
│   ├── ipfs.js              # IPFS utilities
│   ├── vc.js                # VC utilities
│   └── orgId.js             # Organization ID utilities
│
├── contracts/               # Smart contract ABIs
│   └── IdentityManager.json # Contract ABI
│
├── data/                    # Static data
│
├── assets/                  # Static assets
│
├── App.jsx                  # Main app component
└── main.jsx                 # Application entry point
```

### **Architecture Pattern**

The application follows a **component-based architecture** with:

- **Pages**: Top-level route components
- **Components**: Reusable UI components
- **Services**: Business logic and external integrations
- **Store**: Global state management (Zustand)
- **Utils**: Helper functions and utilities

### **State Management Flow**

```
User Action → Component → Store Action → Service → Blockchain/IPFS
                ↓
            Store Update
                ↓
            Component Re-render
```

### **Data Flow**

1. **User Interaction** → Component event handler
2. **Store Action** → Zustand action dispatcher
3. **Service Call** → Web3/IPFS service
4. **Blockchain/IPFS** → External API call
5. **Response** → Store update
6. **UI Update** → Component re-render

---

## Installation

### Prerequisites

- **Node.js** >= 16.0.0
- **npm** >= 7.0.0
- **MetaMask** browser extension
- **Modern browser** (Chrome, Firefox, Edge, Safari)

### Setup Steps

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd ssi-project/ssi-frontend
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Configure environment**
   ```bash
   cp env.example .env
   ```

4. **Update `.env` file** with your configuration:
   ```env
   # Smart Contract Configuration
   VITE_CONTRACT_ADDRESS=0x742d35Cc6634C0532925a3b8D1DE9c61F8E7c982
   VITE_SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_INFURA_KEY
   VITE_MAINNET_RPC_URL=https://mainnet.infura.io/v3/YOUR_INFURA_KEY
   
   # IPFS Configuration (Pinata)
   VITE_PINATA_PROJECT_ID=your_pinata_project_id
   VITE_PINATA_PROJECT_SECRET=your_pinata_project_secret
   VITE_PINATA_GATEWAY=https://gateway.pinata.cloud/ipfs/
   
   # App Configuration
   VITE_APP_NAME=SSI Identity Manager
   VITE_APP_VERSION=1.0.0
   VITE_NETWORK=sepolia
   ```

5. **Start development server**
   ```bash
   npm run dev
   ```

6. **Open browser**
   Navigate to `http://localhost:5173`

---

## Configuration

### Environment Variables

All environment variables must be prefixed with `VITE_` to be accessible in the browser.

#### **Required Variables**

```env
VITE_CONTRACT_ADDRESS=0x...          # Deployed smart contract address
VITE_SEPOLIA_RPC_URL=https://...    # Ethereum RPC endpoint
VITE_PINATA_PROJECT_ID=...          # Pinata project ID
VITE_PINATA_PROJECT_SECRET=...      # Pinata project secret
```

#### **Optional Variables**

```env
VITE_APP_NAME=SSI Identity Manager   # Application name
VITE_APP_VERSION=1.0.0               # Application version
VITE_NETWORK=sepolia                  # Default network
VITE_QR_CODE_SIZE=256                 # QR code size
```

### Smart Contract ABI

Ensure `IdentityManager.json` is in `src/contracts/` directory. This file contains the contract ABI for blockchain interactions.

---

## Usage Guide

### 1. **Connect Wallet**

1. Click **"Connect Wallet"** button on dashboard
2. Select **MetaMask** from wallet options
3. Approve connection request in MetaMask
4. Select account and network
5. Confirm connection

### 2. **Register DID**

1. Navigate to **"DID Management"** page
2. Click **"Register DID"** button
3. Enter organization ID (e.g., `university_tech_2024`)
4. Fill in DID information:
   - Organization name
   - Type
   - Website
   - Additional metadata
5. Click **"Register"**
6. Confirm transaction in MetaMask
7. Wait for blockchain confirmation

### 3. **Issue Verifiable Credential**

1. Navigate to **"VC Operations"** page
2. Ensure your DID is registered and active
3. Click **"Issue VC"** button
4. Fill in credential details:
   - Credential type
   - Subject information
   - Issuance date
   - Expiration date (optional)
5. Upload credential data/document
6. Click **"Issue Credential"**
7. Confirm transaction in MetaMask

### 4. **Verify Credential**

1. Go to **"VC Operations"** page
2. Enter organization ID and credential index
3. Click **"Verify VC"** button
4. View verification result:
   - Valid/Invalid status
   - Credential hash
   - Issuer address
   - Issuance timestamp
   - Expiration status

### 5. **Scan QR Code**

1. Click **"Scan QR Code"** button
2. Allow camera permissions
3. Point camera at QR code
4. App automatically processes QR data
5. View extracted information
6. Perform actions (verify, save, etc.)

### 6. **Authorize Issuer**

1. Go to **"DID Management"** page
2. Click **"Authorize Issuer"** button
3. Enter issuer wallet address
4. Click **"Authorize"**
5. Confirm transaction in MetaMask

---

## Development

### Development Server

```bash
# Start dev server with hot reload
npm run dev

# Start with specific port
npm run dev -- --port 3000
```

### Building for Production

```bash
# Build production bundle
npm run build

# Preview production build
npm run preview
```

### Code Quality

```bash
# Lint code
npm run lint

# Format code (if configured)
npm run format
```

### Project Scripts

```json
{
  "dev": "vite",                    // Start dev server
  "build": "vite build",            // Build for production
  "preview": "vite preview",        // Preview production build
  "lint": "eslint ."                // Lint code
}
```

---

## Deployment

### Build Process

1. **Build the application**
   ```bash
   npm run build
   ```

2. **Output directory**: `dist/` folder contains all production files

### Deployment Options

#### **Vercel**

1. Install Vercel CLI: `npm i -g vercel`
2. Run: `vercel`
3. Follow prompts

#### **Netlify**

1. Install Netlify CLI: `npm i -g netlify-cli`
2. Run: `netlify deploy --prod`
3. Follow prompts

#### **GitHub Pages**

1. Install gh-pages: `npm install --save-dev gh-pages`
2. Add to package.json:
   ```json
   "scripts": {
     "deploy": "npm run build && gh-pages -d dist"
   }
   ```
3. Run: `npm run deploy`

#### **Traditional Hosting**

1. Build: `npm run build`
2. Upload `dist/` folder to web server
3. Configure server to serve `index.html` for all routes

### Environment Variables in Production

- Set environment variables in hosting platform
- Ensure all `VITE_` prefixed variables are set
- Never commit `.env` files to repository

---

## API Reference

### **Store Actions (Zustand)**

#### **Wallet Actions**

```javascript
// Connect wallet
connectWallet()

// Disconnect wallet
disconnectWallet()

// Get wallet state
loadWalletState({ orgId })
```

#### **DID Actions**

```javascript
// Register DID
registerDID(orgID, didData)

// Get DID information
getDID(orgID)

// Update DID
updateDID(orgID, didData)
```

#### **VC Actions**

```javascript
// Issue credential
issueVC(orgID, credentialData)

// Verify credential
verifyVC(orgID, index)

// Revoke credential
revokeVC(orgID, index)

// Get VC list
getVCList(orgID)
```

### **Service Functions**

#### **Web3Service**

```javascript
class Web3Service {
  async connectWallet()
  async getContract()
  async registerDID(orgID, hashData, uri)
  async issueVC(orgID, hashCredential, uri)
  async verifyVC(orgID, index)
  async revokeVC(orgID, index)
}
```

#### **IPFS Utilities**

```javascript
// Upload DID document
uploadDIDDocumentToIPFS(didData)

// Upload VC document
uploadVCToIPFS(vcData)

// Retrieve from IPFS
retrieveJSONFromIPFS(ipfsHash)
```

### **Smart Contract Functions**

The application interacts with the `IdentityManager` smart contract:

- `registerDID(orgID, hashData, uri)` - Register new DID
- `authorizeIssuer(orgID, issuer)` - Authorize credential issuer
- `issueVC(orgID, hashCredential, uri)` - Issue verifiable credential
- `verifyVC(orgID, index)` - Verify credential
- `revokeVC(orgID, index)` - Revoke credential
- `getDID(orgID)` - Get DID information
- `getVCLength(orgID)` - Get credential count

---

## Troubleshooting

### Common Issues

#### **Wallet Connection Failed**

**Problem**: MetaMask not connecting

**Solutions**:
- Ensure MetaMask extension is installed
- Check if MetaMask is unlocked
- Verify network matches (Sepolia vs Mainnet)
- Clear browser cache and try again
- Check browser console for errors

#### **Transaction Failed**

**Problem**: Blockchain transactions failing

**Solutions**:
- Verify wallet has sufficient ETH for gas
- Check contract address is correct
- Ensure network matches contract deployment
- Verify transaction parameters
- Check gas limit is sufficient

#### **IPFS Upload Failed**

**Problem**: Cannot upload to IPFS

**Solutions**:
- Verify Pinata credentials in `.env`
- Check internet connection
- Ensure file size is within limits
- Verify Pinata project is active
- Check browser console for errors

#### **QR Code Not Scanning**

**Problem**: QR scanner not working

**Solutions**:
- Grant camera permissions
- Use HTTPS (required for camera access)
- Ensure good lighting
- Check QR code is not damaged
- Try different browser

### Debug Mode

Enable debug logging in browser console:

```javascript
// In browser console
localStorage.setItem('debug', 'true')
```

### Network Issues

If experiencing network issues:

1. Check RPC endpoint is accessible
2. Verify Infura/Alchemy API key is valid
3. Check network status on Etherscan
4. Try switching to different RPC endpoint

---

## Security Best Practices

1. **Environment Variables**
   - Never commit `.env` files
   - Use `.env.example` as template
   - Set variables in hosting platform

2. **Wallet Security**
   - Always verify transaction details
   - Never share private keys
   - Use hardware wallets for production

3. **Input Validation**
   - Validate all user inputs
   - Sanitize data before blockchain transactions
   - Check contract addresses format

4. **HTTPS**
   - Always use HTTPS in production
   - Required for camera access (QR scanning)
   - Secure data transmission

5. **Error Handling**
   - Implement comprehensive error handling
   - Don't expose sensitive information in errors
   - Log errors for debugging

---

## Performance Optimization

### **Code Splitting**
- Lazy load routes
- Dynamic imports for heavy components
- Split vendor bundles

### **Asset Optimization**
- Compress images
- Use modern image formats (WebP)
- Optimize bundle size

### **Caching**
- Cache blockchain data
- Use service workers for offline support
- Implement local storage caching

### **Network Optimization**
- Batch blockchain calls when possible
- Use efficient RPC endpoints
- Implement request debouncing

---

## Testing

### Manual Testing Checklist

- [ ] Wallet connection
- [ ] DID registration
- [ ] VC issuance
- [ ] VC verification
- [ ] VC revocation
- [ ] QR code generation
- [ ] QR code scanning
- [ ] Issuer authorization
- [ ] Network switching
- [ ] Error handling

### Browser Compatibility

- Chrome (latest)
- Firefox (latest)
- Edge (latest)
- Safari (latest)
- IE11 (not supported)

---

## Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

### Code Style

- Follow ESLint rules
- Use functional components with hooks
- Keep components small and focused
- Add comments for complex logic

---

## License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details.

---

## Skills Demonstrated

- **React Development**: Modern React with hooks, context, and state management
- **Web3 Integration**: Ethereum blockchain interaction with Ethers.js
- **State Management**: Zustand for global state
- **UI/UX Design**: Responsive design with Tailwind CSS
- **Build Tools**: Vite for fast development and optimized builds
- **IPFS Integration**: Decentralized storage implementation
- **QR Code**: Generation and scanning functionality
- **Testing**: Manual testing and quality assurance

---

## Related Documentation

- [Smart Contract Documentation](../ssi-smart-contract/README.md)
- [Mobile App Documentation](../mobile-app-frontend/README.md)
- [Main Project README](../README.md)

---

**Built with ❤️ using React and Vite**

*Last updated: November 2025*
