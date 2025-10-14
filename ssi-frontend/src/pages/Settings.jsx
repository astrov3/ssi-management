import {
    AlertCircle,
    Book,
    CheckCircle,
    ChevronDown,
    ChevronRight,
    Eye,
    EyeOff,
    HelpCircle,
    Info,
    QrCode,
    RefreshCw,
    Save,
    Shield,
    Trash2,
    User
} from 'lucide-react';
import { useEffect, useState } from 'react';
import toast from 'react-hot-toast';
import { useStore } from '../store/useStore';

const Settings = () => {
    const {
        account,
        isConnected,
        connectWallet,
        disconnectWallet,
        currentOrgID,
        setCurrentOrgID,
        loading
    } = useStore();

    const [settings, setSettings] = useState({
        contractAddress: import.meta.env.VITE_CONTRACT_ADDRESS || '',
        rpcUrl: import.meta.env.VITE_SEPOLIA_RPC_URL || '',
        pinataProjectId: import.meta.env.VITE_PINATA_PROJECT_ID || '',
        pinataProjectSecret: import.meta.env.VITE_PINATA_PROJECT_SECRET || '',
        showSecrets: false,
        autoConnect: false,
        network: import.meta.env.VITE_NETWORK || 'sepolia'
    });

    const [orgIDInput, setOrgIDInput] = useState(currentOrgID || '');
    const [expandedSections, setExpandedSections] = useState({
        getting_started: false,
        did_management: false,
        vc_operations: false,
        qr_scanner: false,
        troubleshooting: false
    });

    useEffect(() => {
        if (!isConnected) {
            connectWallet();
        }
    }, [isConnected, connectWallet]);

    const handleSaveSettings = () => {
        // In a real app, you'd save these to localStorage or a backend
        localStorage.setItem('ssi-settings', JSON.stringify(settings));
        toast.success('Settings saved successfully');
    };

    const handleResetSettings = () => {
        if (window.confirm('Are you sure you want to reset all settings to defaults?')) {
            const defaultSettings = {
                contractAddress: import.meta.env.VITE_CONTRACT_ADDRESS || '',
                rpcUrl: import.meta.env.VITE_SEPOLIA_RPC_URL || '',
                pinataProjectId: import.meta.env.VITE_PINATA_PROJECT_ID || '',
                pinataProjectSecret: import.meta.env.VITE_PINATA_PROJECT_SECRET || '',
                showSecrets: false,
                autoConnect: false,
                network: import.meta.env.VITE_NETWORK || 'sepolia'
            };
            setSettings(defaultSettings);
            localStorage.removeItem('ssi-settings');
            toast.success('Settings reset to defaults');
        }
    };

    const handleChangeOrgID = () => {
        if (orgIDInput.trim()) {
            setCurrentOrgID(orgIDInput.trim());
            toast.success('Organization ID updated');
        } else {
            toast.error('Please enter a valid Organization ID');
        }
    };

    const handleClearOrgID = () => {
        if (window.confirm('Are you sure you want to clear the current Organization ID?')) {
            setCurrentOrgID('');
            setOrgIDInput('');
            toast.success('Organization ID cleared');
        }
    };

    const toggleSecretVisibility = () => {
        setSettings({ ...settings, showSecrets: !settings.showSecrets });
    };

    const toggleSection = (section) => {
        setExpandedSections(prev => ({
            ...prev,
            [section]: !prev[section]
        }));
    };

    const formatAddress = (address) => {
        if (!address) return 'Not set';
        return `${address.slice(0, 10)}...${address.slice(-6)}`;
    };

    return (
        <div className="space-y-4 lg:space-y-6">
            {/* Header */}
            <div>
                <h1 className="text-xl sm:text-2xl lg:text-3xl font-bold text-gray-900">Settings</h1>
                <p className="mt-1 text-sm text-gray-700">
                    Configure your SSI Manager preferences and connections
                </p>
            </div>

            {/* Wallet Settings */}
            <div className="card">
                <div className="flex items-center justify-between mb-4">
                    <h2 className="text-lg font-bold text-gray-900">Wallet Connection</h2>
                    <div className="flex items-center space-x-2">
                        {isConnected ? (
                            <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                                <CheckCircle className="w-3 h-3 mr-1" />
                                Connected
                            </span>
                        ) : (
                            <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800">
                                <AlertCircle className="w-3 h-3 mr-1" />
                                Disconnected
                            </span>
                        )}
                    </div>
                </div>

                <div className="space-y-4">
                    <div>
                        <label className="form-label">
                            Connected Address
                        </label>
                        <div className="mt-1 flex items-center space-x-3">
                            <input
                                type="text"
                                value={account || 'Not connected'}
                                readOnly
                                className="block w-full border-gray-300 rounded-md shadow-sm bg-gray-50 text-gray-900 px-4 py-3 text-sm"
                            />
                            {isConnected && (
                                <button
                                    onClick={disconnectWallet}
                                    className="inline-flex items-center px-3 py-2 border border-red-300 shadow-sm text-sm font-medium rounded-md text-red-700 bg-white hover:bg-red-50"
                                >
                                    Disconnect
                                </button>
                            )}
                        </div>
                    </div>

                    {!isConnected && (
                        <div>
                            <button
                                onClick={connectWallet}
                                disabled={loading}
                                className="btn-primary"
                            >
                                {loading ? 'Connecting...' : 'Connect Wallet'}
                            </button>
                        </div>
                    )}
                </div>
            </div>

            {/* Organization Settings */}
            <div className="card">
                <h2 className="text-lg font-bold text-gray-900 mb-4">Organization Settings</h2>

                <div className="space-y-4">
                    <div>
                        <label htmlFor="orgID" className="block text-sm font-semibold text-gray-700 mb-2">
                            Current Organization ID
                        </label>
                        <div className="mt-1 flex items-center space-x-3">
                            <input
                                type="text"
                                id="orgID"
                                value={orgIDInput}
                                onChange={(e) => setOrgIDInput(e.target.value)}
                                className="form-input"
                                placeholder="Enter organization ID"
                            />
                            <button
                                onClick={handleChangeOrgID}
                                disabled={!orgIDInput.trim()}
                                className="btn-secondary btn-sm"
                            >
                                Update
                            </button>
                            {currentOrgID && (
                                <button
                                    onClick={handleClearOrgID}
                                    className="inline-flex items-center px-3 py-2 border border-red-300 shadow-sm text-sm font-medium rounded-md text-red-700 bg-white hover:bg-red-50"
                                >
                                    <Trash2 className="h-4 w-4" />
                                </button>
                            )}
                        </div>
                    </div>

                    {currentOrgID && (
                        <div>
                            <label className="form-label">
                                Current Organization ID
                            </label>
                            <div className="mt-1 text-sm text-gray-900 font-mono bg-gray-50 p-3 rounded">
                                {currentOrgID}
                            </div>
                        </div>
                    )}
                </div>
            </div>

            {/* Network Settings */}
            <div className="card">
                <h2 className="text-lg font-bold text-gray-900 mb-4">Network Configuration</h2>

                <div className="space-y-4">
                    <div>
                        <label htmlFor="network" className="block text-sm font-semibold text-gray-700 mb-2">
                            Network
                        </label>
                        <select
                            id="network"
                            value={settings.network}
                            onChange={(e) => setSettings({ ...settings, network: e.target.value })}
                            className="form-input"
                        >
                            <option value="sepolia">Sepolia Testnet</option>
                            <option value="mainnet">Ethereum Mainnet</option>
                            <option value="localhost">Local Development</option>
                        </select>
                    </div>

                    <div>
                        <label htmlFor="rpcUrl" className="block text-sm font-semibold text-gray-700 mb-2">
                            RPC URL
                        </label>
                        <input
                            type="url"
                            id="rpcUrl"
                            value={settings.rpcUrl}
                            onChange={(e) => setSettings({ ...settings, rpcUrl: e.target.value })}
                            className="form-input"
                            placeholder="https://sepolia.infura.io/v3/your-key"
                        />
                    </div>

                    <div>
                        <label htmlFor="contractAddress" className="block text-sm font-semibold text-gray-700 mb-2">
                            Contract Address
                        </label>
                        <input
                            type="text"
                            id="contractAddress"
                            value={settings.contractAddress}
                            onChange={(e) => setSettings({ ...settings, contractAddress: e.target.value })}
                            className="form-input"
                            placeholder="0x..."
                        />
                        <p className="mt-1 text-sm text-gray-700">
                            Current: {formatAddress(settings.contractAddress)}
                        </p>
                    </div>
                </div>
            </div>

            {/* IPFS Settings */}
            <div className="card">
                <h2 className="text-lg font-bold text-gray-900 mb-4">IPFS Configuration</h2>

                <div className="space-y-4">
                    <div>
                        <label htmlFor="pinataProjectId" className="block text-sm font-semibold text-gray-700 mb-2">
                            Pinata Project ID
                        </label>
                        <input
                            type="text"
                            id="pinataProjectId"
                            value={settings.pinataProjectId}
                            onChange={(e) => setSettings({ ...settings, pinataProjectId: e.target.value })}
                            className="form-input"
                            placeholder="Your Pinata Project ID"
                        />
                    </div>

                    <div>
                        <label htmlFor="pinataProjectSecret" className="block text-sm font-semibold text-gray-700 mb-2">
                            Pinata Project Secret
                        </label>
                        <div className="mt-1 relative">
                            <input
                                type={settings.showSecrets ? "text" : "password"}
                                id="pinataProjectSecret"
                                value={settings.pinataProjectSecret}
                                onChange={(e) => setSettings({ ...settings, pinataProjectSecret: e.target.value })}
                                className="form-input pr-10"
                                placeholder="Your Pinata Project Secret"
                            />
                            <button
                                type="button"
                                onClick={toggleSecretVisibility}
                                className="absolute inset-y-0 right-0 pr-3 flex items-center"
                            >
                                {settings.showSecrets ? (
                                    <EyeOff className="h-4 w-4 text-gray-400" />
                                ) : (
                                    <Eye className="h-4 w-4 text-gray-400" />
                                )}
                            </button>
                        </div>
                    </div>
                </div>
            </div>

            {/* Application Settings */}
            <div className="card">
                <h2 className="text-lg font-bold text-gray-900 mb-4">Application Settings</h2>

                <div className="space-y-4">
                    <div className="flex items-center">
                        <input
                            id="autoConnect"
                            type="checkbox"
                            checked={settings.autoConnect}
                            onChange={(e) => setSettings({ ...settings, autoConnect: e.target.checked })}
                            className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                        />
                        <label htmlFor="autoConnect" className="ml-2 block text-sm text-gray-900">
                            Auto-connect wallet on page load
                        </label>
                    </div>
                </div>
            </div>

            {/* App Information */}
            <div className="bg-blue-50 border border-blue-200 rounded-lg p-6">
                <div className="flex">
                    <div className="flex-shrink-0">
                        <Info className="h-5 w-5 text-blue-400" />
                    </div>
                    <div className="ml-3">
                        <h3 className="text-sm font-medium text-blue-800">
                            Application Information
                        </h3>
                        <div className="mt-2 text-sm text-blue-700">
                            <dl className="grid grid-cols-1 gap-x-4 gap-y-2 sm:grid-cols-2">
                                <div>
                                    <dt className="font-medium">App Name:</dt>
                                    <dd>{import.meta.env.VITE_APP_NAME || 'SSI Identity Manager'}</dd>
                                </div>
                                <div>
                                    <dt className="font-medium">Version:</dt>
                                    <dd>{import.meta.env.VITE_APP_VERSION || '1.0.0'}</dd>
                                </div>
                                <div>
                                    <dt className="font-medium">Environment:</dt>
                                    <dd>{import.meta.env.MODE || 'development'}</dd>
                                </div>
                                <div>
                                    <dt className="font-medium">Network:</dt>
                                    <dd>{settings.network}</dd>
                                </div>
                            </dl>
                        </div>
                    </div>
                </div>
            </div>

            {/* User Guide */}
            <div className="card">
                <div className="flex items-center justify-between mb-4">
                    <div className="flex items-center space-x-2">
                        <Book className="h-5 w-5 text-blue-600" />
                        <h2 className="text-lg font-bold text-gray-900">User Guide</h2>
                    </div>
                    <HelpCircle className="h-5 w-5 text-gray-400" />
                </div>

                <div className="space-y-3">
                    {/* Getting Started */}
                    <div className="border border-gray-200 rounded-lg">
                        <button
                            onClick={() => toggleSection('getting_started')}
                            className="w-full flex items-center justify-between p-4 text-left hover:bg-gray-50"
                        >
                            <div className="flex items-center space-x-3">
                                <div className="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center">
                                    <span className="text-blue-600 font-semibold text-sm">1</span>
                                </div>
                                <span className="font-medium text-gray-900">Getting Started</span>
                            </div>
                            {expandedSections.getting_started ? (
                                <ChevronDown className="h-4 w-4 text-gray-500" />
                            ) : (
                                <ChevronRight className="h-4 w-4 text-gray-500" />
                            )}
                        </button>
                        {expandedSections.getting_started && (
                            <div className="px-4 pb-4 border-t border-gray-100">
                                <div className="space-y-3 mt-3">
                                    <div className="flex items-start space-x-2">
                                        <CheckCircle className="h-4 w-4 text-green-500 mt-0.5" />
                                        <span className="text-sm text-gray-700">Connect your MetaMask wallet first</span>
                                    </div>
                                    <div className="flex items-start space-x-2">
                                        <CheckCircle className="h-4 w-4 text-green-500 mt-0.5" />
                                        <span className="text-sm text-gray-700">Make sure you're on Sepolia testnet</span>
                                    </div>
                                    <div className="flex items-start space-x-2">
                                        <CheckCircle className="h-4 w-4 text-green-500 mt-0.5" />
                                        <span className="text-sm text-gray-700">Have some Sepolia ETH for transactions</span>
                                    </div>
                                    <div className="bg-blue-50 p-3 rounded-md">
                                        <p className="text-sm text-blue-800">
                                            <strong>Tip:</strong> Get free Sepolia ETH from{' '}
                                            <a href="https://sepoliafaucet.com/" target="_blank" rel="noopener noreferrer" className="underline">
                                                Sepolia Faucet
                                            </a>
                                        </p>
                                    </div>
                                </div>
                            </div>
                        )}
                    </div>

                    {/* DID Management */}
                    <div className="border border-gray-200 rounded-lg">
                        <button
                            onClick={() => toggleSection('did_management')}
                            className="w-full flex items-center justify-between p-4 text-left hover:bg-gray-50"
                        >
                            <div className="flex items-center space-x-3">
                                <div className="w-8 h-8 bg-green-100 rounded-full flex items-center justify-center">
                                    <User className="h-4 w-4 text-green-600" />
                                </div>
                                <span className="font-medium text-gray-900">DID Management</span>
                            </div>
                            {expandedSections.did_management ? (
                                <ChevronDown className="h-4 w-4 text-gray-500" />
                            ) : (
                                <ChevronRight className="h-4 w-4 text-gray-500" />
                            )}
                        </button>
                        {expandedSections.did_management && (
                            <div className="px-4 pb-4 border-t border-gray-100">
                                <div className="space-y-3 mt-3">
                                    <h4 className="font-medium text-gray-900">How to register your DID:</h4>
                                    <ol className="list-decimal list-inside space-y-2 text-sm text-gray-700">
                                        <li>Go to <strong>DID Management</strong> page</li>
                                        <li>Enter your unique <strong>Organization ID</strong> (e.g., "company_name")</li>
                                        <li>Click <strong>"Check DID"</strong> to see if it exists</li>
                                        <li>If not exists, click <strong>"Register DID"</strong></li>
                                        <li>Fill in your organization data (JSON format)</li>
                                        <li>Confirm the transaction in MetaMask</li>
                                    </ol>
                                    <div className="bg-yellow-50 p-3 rounded-md">
                                        <p className="text-sm text-yellow-800">
                                            <strong>Note:</strong> Organization ID must be unique and cannot be changed later
                                        </p>
                                    </div>
                                </div>
                            </div>
                        )}
                    </div>

                    {/* VC Operations */}
                    <div className="border border-gray-200 rounded-lg">
                        <button
                            onClick={() => toggleSection('vc_operations')}
                            className="w-full flex items-center justify-between p-4 text-left hover:bg-gray-50"
                        >
                            <div className="flex items-center space-x-3">
                                <div className="w-8 h-8 bg-purple-100 rounded-full flex items-center justify-center">
                                    <Shield className="h-4 w-4 text-purple-600" />
                                </div>
                                <span className="font-medium text-gray-900">VC Operations</span>
                            </div>
                            {expandedSections.vc_operations ? (
                                <ChevronDown className="h-4 w-4 text-gray-500" />
                            ) : (
                                <ChevronRight className="h-4 w-4 text-gray-500" />
                            )}
                        </button>
                        {expandedSections.vc_operations && (
                            <div className="px-4 pb-4 border-t border-gray-100">
                                <div className="space-y-4 mt-3">
                                    <div>
                                        <h4 className="font-medium text-gray-900 mb-2">Issue Verifiable Credential:</h4>
                                        <ol className="list-decimal list-inside space-y-1 text-sm text-gray-700">
                                            <li>Ensure your DID is active</li>
                                            <li>Go to <strong>VC Operations</strong> page</li>
                                            <li>Click <strong>"Issue VC"</strong></li>
                                            <li>Enter credential data (JSON format)</li>
                                            <li>Confirm transaction</li>
                                        </ol>
                                    </div>
                                    <div>
                                        <h4 className="font-medium text-gray-900 mb-2">Verify Credential:</h4>
                                        <ol className="list-decimal list-inside space-y-1 text-sm text-gray-700">
                                            <li>Enter VC index and hash</li>
                                            <li>Click <strong>"Verify VC"</strong></li>
                                            <li>Or scan QR code for auto-verification</li>
                                        </ol>
                                    </div>
                                    <div className="bg-green-50 p-3 rounded-md">
                                        <p className="text-sm text-green-800">
                                            <strong>Tip:</strong> Use QR codes to easily share and verify credentials
                                        </p>
                                    </div>
                                </div>
                            </div>
                        )}
                    </div>

                    {/* QR Scanner */}
                    <div className="border border-gray-200 rounded-lg">
                        <button
                            onClick={() => toggleSection('qr_scanner')}
                            className="w-full flex items-center justify-between p-4 text-left hover:bg-gray-50"
                        >
                            <div className="flex items-center space-x-3">
                                <div className="w-8 h-8 bg-orange-100 rounded-full flex items-center justify-center">
                                    <QrCode className="h-4 w-4 text-orange-600" />
                                </div>
                                <span className="font-medium text-gray-900">QR Scanner</span>
                            </div>
                            {expandedSections.qr_scanner ? (
                                <ChevronDown className="h-4 w-4 text-gray-500" />
                            ) : (
                                <ChevronRight className="h-4 w-4 text-gray-500" />
                            )}
                        </button>
                        {expandedSections.qr_scanner && (
                            <div className="px-4 pb-4 border-t border-gray-100">
                                <div className="space-y-3 mt-3">
                                    <h4 className="font-medium text-gray-900">Supported QR Types:</h4>
                                    <div className="space-y-2">
                                        <div className="flex items-center space-x-2">
                                            <div className="w-2 h-2 bg-blue-500 rounded-full"></div>
                                            <span className="text-sm text-gray-700"><strong>DID QR:</strong> Organization identity information</span>
                                        </div>
                                        <div className="flex items-center space-x-2">
                                            <div className="w-2 h-2 bg-green-500 rounded-full"></div>
                                            <span className="text-sm text-gray-700"><strong>VC QR:</strong> Verifiable credential data</span>
                                        </div>
                                        <div className="flex items-center space-x-2">
                                            <div className="w-2 h-2 bg-purple-500 rounded-full"></div>
                                            <span className="text-sm text-gray-700"><strong>Verification Request:</strong> Request to verify a credential</span>
                                        </div>
                                    </div>
                                    <div className="bg-orange-50 p-3 rounded-md">
                                        <p className="text-sm text-orange-800">
                                            <strong>Camera Access:</strong> Allow camera permission when prompted
                                        </p>
                                    </div>
                                </div>
                            </div>
                        )}
                    </div>

                    {/* Troubleshooting */}
                    <div className="border border-gray-200 rounded-lg">
                        <button
                            onClick={() => toggleSection('troubleshooting')}
                            className="w-full flex items-center justify-between p-4 text-left hover:bg-gray-50"
                        >
                            <div className="flex items-center space-x-3">
                                <div className="w-8 h-8 bg-red-100 rounded-full flex items-center justify-center">
                                    <AlertCircle className="h-4 w-4 text-red-600" />
                                </div>
                                <span className="font-medium text-gray-900">Troubleshooting</span>
                            </div>
                            {expandedSections.troubleshooting ? (
                                <ChevronDown className="h-4 w-4 text-gray-500" />
                            ) : (
                                <ChevronRight className="h-4 w-4 text-gray-500" />
                            )}
                        </button>
                        {expandedSections.troubleshooting && (
                            <div className="px-4 pb-4 border-t border-gray-100">
                                <div className="space-y-4 mt-3">
                                    <div>
                                        <h4 className="font-medium text-gray-900 mb-2">Common Issues:</h4>
                                        <div className="space-y-3">
                                            <div>
                                                <p className="text-sm font-medium text-red-600">Cannot connect MetaMask</p>
                                                <ul className="list-disc list-inside text-sm text-gray-700 ml-4">
                                                    <li>Install MetaMask extension</li>
                                                    <li>Switch to Sepolia network</li>
                                                    <li>Refresh the page</li>
                                                </ul>
                                            </div>
                                            <div>
                                                <p className="text-sm font-medium text-red-600">Transaction failed</p>
                                                <ul className="list-disc list-inside text-sm text-gray-700 ml-4">
                                                    <li>Check if you have enough ETH</li>
                                                    <li>Increase gas limit</li>
                                                    <li>Make sure you're the DID owner</li>
                                                </ul>
                                            </div>
                                            <div>
                                                <p className="text-sm font-medium text-red-600">QR Scanner not working</p>
                                                <ul className="list-disc list-inside text-sm text-gray-700 ml-4">
                                                    <li>Allow camera permissions</li>
                                                    <li>Use HTTPS connection</li>
                                                    <li>Try different browser</li>
                                                </ul>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        )}
                    </div>
                </div>

                {/* Quick Links */}
                <div className="mt-6 p-4 bg-gray-50 rounded-lg">
                    <h3 className="font-medium text-gray-900 mb-3">Quick Links</h3>
                    <div className="grid grid-cols-2 gap-2">
                        <a
                            href="https://sepoliafaucet.com/"
                            target="_blank"
                            rel="noopener noreferrer"
                            className="text-sm text-blue-600 hover:text-blue-700 underline"
                        >
                            Sepolia Faucet
                        </a>
                        <a
                            href="https://metamask.io/"
                            target="_blank"
                            rel="noopener noreferrer"
                            className="text-sm text-blue-600 hover:text-blue-700 underline"
                        >
                            MetaMask Download
                        </a>
                        <a
                            href="https://sepolia.etherscan.io/"
                            target="_blank"
                            rel="noopener noreferrer"
                            className="text-sm text-blue-600 hover:text-blue-700 underline"
                        >
                            Sepolia Explorer
                        </a>
                        <a
                            href="https://docs.metamask.io/"
                            target="_blank"
                            rel="noopener noreferrer"
                            className="text-sm text-blue-600 hover:text-blue-700 underline"
                        >
                            MetaMask Docs
                        </a>
                    </div>
                </div>
            </div>

            {/* Action Buttons */}
            <div className="flex justify-end space-x-3">
                <button
                    onClick={handleResetSettings}
                    className="btn-secondary"
                >
                    <RefreshCw className="h-4 w-4 mr-2" />
                    Reset to Defaults
                </button>
                <button
                    onClick={handleSaveSettings}
                    className="btn-primary"
                >
                    <Save className="h-4 w-4 mr-2" />
                    Save Settings
                </button>
            </div>
        </div>
    );
};

export default Settings;
