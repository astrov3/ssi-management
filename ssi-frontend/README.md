# SSI Identity Manager Frontend

A comprehensive React frontend for managing Self-Sovereign Identity (SSI) and Verifiable Credentials (VC) on the Ethereum blockchain.

## Features

### 🏠 Dashboard

- Wallet connection status
- Quick actions for all main features
- Statistics overview
- Current organization status

### 👤 DID Management

- Register new Digital Identity Documents
- Check existing DIDs
- View DID status and details
- QR code generation for DIDs
- QR code scanning for DID data

### 🛡️ VC Operations

- Issue Verifiable Credentials
- Authorize issuers
- Verify VC authenticity
- Revoke VCs when needed
- Manage VC lifecycle
- QR code integration for VCs

### 📱 QR Code Scanner

- Scan QR codes containing DID/VC data
- Automatic data processing
- Verification capabilities
- Export scanned data

### ⚙️ Settings

- Network configuration
- IPFS/Pinata settings
- Wallet management
- Organization settings

## Technology Stack

- **React 19** - Modern React with latest features
- **Vite** - Fast build tool and dev server
- **Tailwind CSS** - Utility-first CSS framework
- **DaisyUI** - Tailwind CSS component library
- **Zustand** - Lightweight state management
- **React Router** - Client-side routing
- **Ethers.js** - Ethereum library
- **html5-qrcode** - QR code scanning
- **qrcode** - QR code generation
- **React Hot Toast** - Toast notifications
- **Lucide React** - Icon library

## Installation

1. Install dependencies:

```bash
npm install
```

1. Copy environment configuration:

```bash
cp env.example .env
```

1. Configure your environment variables in `.env`:

```env
# Smart Contract Configuration
VITE_CONTRACT_ADDRESS=your_contract_address_here
VITE_SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/your_infura_key

# Pinata IPFS Configuration
VITE_PINATA_PROJECT_ID=your_pinata_project_id
VITE_PINATA_PROJECT_SECRET=your_pinata_project_secret

# App Configuration
VITE_APP_NAME=SSI Identity Manager
VITE_APP_VERSION=1.0.0
VITE_NETWORK=sepolia
```

## Development

Start the development server:

```bash
npm run dev
```

Build for production:

```bash
npm run build
```

Preview production build:

```bash
npm run preview
```

## Usage

### 1. Connect Wallet

- Install MetaMask browser extension
- Click "Connect Wallet" on the dashboard
- Approve the connection request

### 2. Register DID

- Navigate to "DID Management"
- Enter your organization ID
- Provide DID data
- Click "Register DID"

### 3. Issue VCs

- Navigate to "VC Operations"
- Ensure your DID is active
- Authorize issuers if needed
- Issue new Verifiable Credentials

### 4. Scan QR Codes

- Navigate to "QR Scanner"
- Click "Scan QR Code"
- Point camera at QR code
- Review scanned data

### 5. Verify Credentials

- Use the verification form in VC Operations
- Or scan QR codes and verify automatically
- Check verification results

## QR Code Integration

The application supports comprehensive QR code functionality:

### QR Code Types

- **DID QR Codes**: Contain DID information for easy sharing
- **VC QR Codes**: Contain Verifiable Credential data
- **Verification Request QR Codes**: Request VC verification

### QR Code Features

- Generate QR codes for any data type
- Scan QR codes with camera
- Automatic data processing
- Export QR codes as images
- Copy data to clipboard

## Smart Contract Integration

The frontend integrates with the IdentityManager smart contract:

### Contract Functions Used

- `registerDID()` - Register new DIDs
- `checkDID()` - Check DID status
- `authorizeIssuer()` - Authorize VC issuers
- `issueVC()` - Issue Verifiable Credentials
- `verifyVC()` - Verify credential authenticity
- `revokeVC()` - Revoke credentials
- `getVC()` - Retrieve VC data
- `getVCLength()` - Get VC count

## IPFS Integration

The application uses Pinata for IPFS storage:

### IPFS Features

- Upload DID data to IPFS
- Upload VC data to IPFS
- Retrieve data from IPFS
- Automatic URI generation

## Environment Configuration

### Required Environment Variables

- `VITE_CONTRACT_ADDRESS` - Deployed smart contract address
- `VITE_SEPOLIA_RPC_URL` - Ethereum RPC endpoint
- `VITE_PINATA_PROJECT_ID` - Pinata project ID
- `VITE_PINATA_PROJECT_SECRET` - Pinata project secret

### Optional Environment Variables

- `VITE_APP_NAME` - Application name
- `VITE_APP_VERSION` - Application version
- `VITE_NETWORK` - Target network (sepolia, mainnet, localhost)
- `VITE_QR_CODE_SIZE` - Default QR code size
- `VITE_QR_CODE_ERROR_CORRECTION_LEVEL` - QR code error correction

## Deployment

### Build and Deploy

1. Build the application:

```bash
npm run build
```

1. Deploy the `dist` folder to your hosting provider

### Environment Setup

- Ensure all environment variables are properly configured
- Update contract address if deploying to different network
- Configure CORS settings if needed

## Security Considerations

- Never commit `.env` files with real credentials
- Use HTTPS in production
- Validate all user inputs
- Implement proper error handling
- Use secure RPC endpoints

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License.

## Support

For support and questions:

- Create an issue in the repository
- Check the documentation
- Review the smart contract integration

## Roadmap

- [ ] Multi-wallet support
- [ ] Advanced VC schemas
- [ ] Batch operations
- [ ] Mobile app version
- [ ] Advanced analytics
- [ ] Integration with other SSI standards
