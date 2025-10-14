import {
    AlertCircle,
    CheckCircle,
    Copy,
    Download,
    Eye,
    QrCode,
    XCircle
} from 'lucide-react';
import { useState } from 'react';
import toast from 'react-hot-toast';
import QRScanner from '../components/QRScanner';
import { useStore } from '../store/useStore';
import { parseQRCodeData, validateQRCodeData } from '../utils/qrCode';

const QRScannerPage = () => {
    const {
        isConnected,
        connectWallet,
        currentOrgID,
        checkDID,
        verifyVC,
        loading
    } = useStore();

    const [scannedData, setScannedData] = useState(null);
    const [showScanner, setShowScanner] = useState(false);
    const [verificationResult, setVerificationResult] = useState(null);

    const handleQRScan = async (data) => {
        try {
            const parsedData = parseQRCodeData(JSON.stringify(data));

            if (!validateQRCodeData(parsedData)) {
                toast.error('Invalid QR code format');
                return;
            }

            setScannedData(parsedData);

            // Auto-process based on type
            await processScannedData(parsedData);

        } catch (error) {
            console.error('Error processing QR code:', error);
            toast.error('Failed to process QR code: ' + error.message);
        }
    };

    const processScannedData = async (data) => {
        switch (data.type) {
            case 'DID':
                await processDID(data);
                break;
            case 'VC':
                await processVC(data);
                break;
            case 'VERIFICATION_REQUEST':
                await processVerificationRequest(data);
                break;
            default:
                toast.error('Unknown QR code type');
        }
    };

    const processDID = async (data) => {
        try {
            const did = await checkDID(data.orgID);
            if (did) {
                toast.success('DID information loaded successfully');
            } else {
                toast.error('DID not found or invalid');
            }
        } catch (error) {
            toast.error('Failed to process DID: ' + error.message);
        }
    };

    const processVC = async () => {
        toast.success('VC information loaded. You can now verify it if needed.');
    };

    const processVerificationRequest = async () => {
        toast.success('Verification request loaded. You can now verify the VC.');
    };

    const handleVerifyVC = async () => {
        if (!scannedData || scannedData.type !== 'VC') {
            toast.error('No VC data to verify');
            return;
        }

        try {
            // For demonstration, we'll verify against the first VC index
            // In a real app, you might want to let the user specify the index
            const isValid = await verifyVC(currentOrgID, 0, scannedData.hashCredential);
            setVerificationResult(isValid);

            if (isValid) {
                toast.success('VC verification successful');
            } else {
                toast.error('VC verification failed');
            }
        } catch (error) {
            toast.error('Verification error: ' + error.message);
        }
    };

    const handleCopyData = () => {
        if (!scannedData) return;

        const dataString = JSON.stringify(scannedData, null, 2);
        navigator.clipboard.writeText(dataString).then(() => {
            toast.success('Data copied to clipboard');
        }).catch(() => {
            toast.error('Failed to copy data');
        });
    };

    const handleDownloadData = () => {
        if (!scannedData) return;

        const dataString = JSON.stringify(scannedData, null, 2);
        const blob = new Blob([dataString], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        link.download = `qr-data-${Date.now()}.json`;
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        URL.revokeObjectURL(url);

        toast.success('Data downloaded');
    };

    const getQRTypeIcon = (type) => {
        switch (type) {
            case 'DID':
                return <Eye className="w-5 h-5 text-blue-600" />;
            case 'VC':
                return <CheckCircle className="w-5 h-5 text-green-600" />;
            case 'VERIFICATION_REQUEST':
                return <QrCode className="w-5 h-5 text-purple-600" />;
            default:
                return <AlertCircle className="w-5 h-5 text-gray-600" />;
        }
    };

    const getQRTypeColor = (type) => {
        switch (type) {
            case 'DID':
                return 'bg-blue-100 text-blue-800';
            case 'VC':
                return 'bg-green-100 text-green-800';
            case 'VERIFICATION_REQUEST':
                return 'bg-purple-100 text-purple-800';
            default:
                return 'bg-gray-100 text-gray-800';
        }
    };

    return (
        <div className="space-y-4 lg:space-y-6">
            {/* Header */}
            <div className="text-center">
                <h1 className="text-xl sm:text-2xl lg:text-3xl font-bold text-gray-900">QR Code Scanner</h1>
                <p className="mt-1 text-sm text-gray-700">
                    Scan QR codes to load DID and VC information
                </p>
            </div>

            {/* Connection Status */}
            {!isConnected && (
                <div className="bg-yellow-50 border border-yellow-200 rounded-md p-4">
                    <div className="flex">
                        <div className="flex-shrink-0">
                            <AlertCircle className="h-5 w-5 text-yellow-400" />
                        </div>
                        <div className="ml-3">
                            <h3 className="text-sm font-medium text-yellow-800">
                                Wallet Required
                            </h3>
                            <div className="mt-2 text-sm text-yellow-700">
                                <p>Please connect your wallet to use the QR scanner.</p>
                            </div>
                            <div className="mt-4">
                                <button
                                    onClick={connectWallet}
                                    disabled={loading}
                                    className="btn-secondary btn-sm"
                                >
                                    {loading ? 'Connecting...' : 'Connect Wallet'}
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            )}

            {/* Scanner Button */}
            <div className="text-center">
                <button
                    onClick={() => setShowScanner(true)}
                    disabled={!isConnected}
                    className="btn-primary text-base sm:text-lg px-6 py-3 sm:px-8 sm:py-4"
                >
                    <QrCode className="h-5 w-5 sm:h-6 sm:w-6 mr-2 sm:mr-3" />
                    {isConnected ? 'Scan QR Code' : 'Connect Wallet First'}
                </button>
            </div>

            {/* Scanned Data Display */}
            {scannedData && (
                <div className="card">
                    <div className="flex items-center justify-between mb-4">
                        <div className="flex items-center space-x-3">
                            {getQRTypeIcon(scannedData.type)}
                            <h2 className="text-lg font-bold text-gray-900">
                                Scanned {scannedData.type}
                            </h2>
                        </div>
                        <div className="flex space-x-2">
                            <button
                                onClick={handleCopyData}
                                className="btn-secondary btn-sm"
                            >
                                <Copy className="h-4 w-4 mr-2" />
                                Copy
                            </button>
                            <button
                                onClick={handleDownloadData}
                                className="btn-secondary btn-sm"
                            >
                                <Download className="h-4 w-4 mr-2" />
                                Download
                            </button>
                        </div>
                    </div>

                    {/* QR Type Badge */}
                    <div className="mb-4">
                        <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getQRTypeColor(scannedData.type)}`}>
                            {scannedData.type}
                        </span>
                    </div>

                    {/* Data Display */}
                    <div className="space-y-4">
                        {scannedData.type === 'DID' && (
                            <div className="grid grid-cols-1 gap-x-4 gap-y-4 sm:grid-cols-2">
                                <div>
                                    <dt className="text-sm font-semibold text-gray-700">Organization ID</dt>
                                    <dd className="mt-1 text-sm text-gray-900 font-mono bg-gray-50 p-3 rounded">
                                        {scannedData.orgID}
                                    </dd>
                                </div>
                                <div>
                                    <dt className="text-sm font-semibold text-gray-700">Owner</dt>
                                    <dd className="mt-1 text-sm text-gray-900 font-mono bg-gray-50 p-3 rounded">
                                        {scannedData.owner}
                                    </dd>
                                </div>
                                <div>
                                    <dt className="text-sm font-semibold text-gray-700">Status</dt>
                                    <dd className="mt-1">
                                        <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${scannedData.active
                                            ? 'bg-green-100 text-green-800'
                                            : 'bg-red-100 text-red-800'
                                            }`}>
                                            {scannedData.active ? 'Active' : 'Inactive'}
                                        </span>
                                    </dd>
                                </div>
                                <div>
                                    <dt className="text-sm font-semibold text-gray-700">Data Hash</dt>
                                    <dd className="mt-1 text-sm text-gray-900 font-mono bg-gray-50 p-3 rounded break-all">
                                        {scannedData.hashData}
                                    </dd>
                                </div>
                                <div className="sm:col-span-2">
                                    <dt className="text-sm font-semibold text-gray-700">URI</dt>
                                    <dd className="mt-1 text-sm text-gray-900 font-mono bg-gray-50 p-3 rounded break-all">
                                        {scannedData.uri}
                                    </dd>
                                </div>
                            </div>
                        )}

                        {scannedData.type === 'VC' && (
                            <div className="grid grid-cols-1 gap-x-4 gap-y-4 sm:grid-cols-2">
                                <div>
                                    <dt className="text-sm font-semibold text-gray-700">Organization ID</dt>
                                    <dd className="mt-1 text-sm text-gray-900 font-mono bg-gray-50 p-3 rounded">
                                        {scannedData.orgID}
                                    </dd>
                                </div>
                                <div>
                                    <dt className="text-sm font-semibold text-gray-700">Issuer</dt>
                                    <dd className="mt-1 text-sm text-gray-900 font-mono bg-gray-50 p-3 rounded">
                                        {scannedData.issuer}
                                    </dd>
                                </div>
                                <div>
                                    <dt className="text-sm font-semibold text-gray-700">Status</dt>
                                    <dd className="mt-1">
                                        <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${scannedData.valid
                                            ? 'bg-green-100 text-green-800'
                                            : 'bg-red-100 text-red-800'
                                            }`}>
                                            {scannedData.valid ? 'Valid' : 'Invalid'}
                                        </span>
                                    </dd>
                                </div>
                                <div>
                                    <dt className="text-sm font-semibold text-gray-700">Credential Hash</dt>
                                    <dd className="mt-1 text-sm text-gray-900 font-mono bg-gray-50 p-3 rounded break-all">
                                        {scannedData.hashCredential}
                                    </dd>
                                </div>
                                <div className="sm:col-span-2">
                                    <dt className="text-sm font-semibold text-gray-700">URI</dt>
                                    <dd className="mt-1 text-sm text-gray-900 font-mono bg-gray-50 p-3 rounded break-all">
                                        {scannedData.uri}
                                    </dd>
                                </div>

                                {/* Verification Button */}
                                <div className="sm:col-span-2">
                                    <button
                                        onClick={handleVerifyVC}
                                        disabled={loading || !currentOrgID}
                                        className="btn-primary"
                                    >
                                        {loading ? 'Verifying...' : 'Verify VC'}
                                        <CheckCircle className="h-4 w-4 ml-2" />
                                    </button>
                                </div>

                                {/* Verification Result */}
                                {verificationResult !== null && (
                                    <div className="sm:col-span-2">
                                        <div className={`p-3 rounded-md ${verificationResult
                                            ? 'bg-green-50 border border-green-200'
                                            : 'bg-red-50 border border-red-200'
                                            }`}>
                                            <div className="flex">
                                                <div className="flex-shrink-0">
                                                    {verificationResult ? (
                                                        <CheckCircle className="h-5 w-5 text-green-400" />
                                                    ) : (
                                                        <XCircle className="h-5 w-5 text-red-400" />
                                                    )}
                                                </div>
                                                <div className="ml-3">
                                                    <p className={`text-sm font-medium ${verificationResult ? 'text-green-800' : 'text-red-800'
                                                        }`}>
                                                        {verificationResult ? 'VC Verification Successful' : 'VC Verification Failed'}
                                                    </p>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                )}
                            </div>
                        )}

                        {scannedData.type === 'VERIFICATION_REQUEST' && (
                            <div className="grid grid-cols-1 gap-x-4 gap-y-4 sm:grid-cols-2">
                                <div>
                                    <dt className="text-sm font-semibold text-gray-700">Organization ID</dt>
                                    <dd className="mt-1 text-sm text-gray-900 font-mono bg-gray-50 p-3 rounded">
                                        {scannedData.orgID}
                                    </dd>
                                </div>
                                <div>
                                    <dt className="text-sm font-semibold text-gray-700">VC Index</dt>
                                    <dd className="mt-1 text-sm text-gray-900 font-mono bg-gray-50 p-3 rounded">
                                        {scannedData.vcIndex}
                                    </dd>
                                </div>
                            </div>
                        )}

                        {/* Raw Data */}
                        <div className="border-t border-gray-200 pt-4">
                            <h4 className="text-sm font-medium text-gray-700 mb-2">Raw Data:</h4>
                            <pre className="text-xs text-gray-600 bg-gray-50 p-3 rounded overflow-auto max-h-40">
                                {JSON.stringify(scannedData, null, 2)}
                            </pre>
                        </div>
                    </div>
                </div>
            )}

            {/* Instructions */}
            <div className="alert alert-success">
                <div className="flex">
                    <div className="flex-shrink-0">
                        <QrCode className="h-5 w-5 text-blue-400" />
                    </div>
                    <div className="ml-3">
                        <h3 className="text-sm font-medium text-blue-800">
                            How to Use
                        </h3>
                        <div className="mt-2 text-sm text-blue-700">
                            <ul className="list-disc list-inside space-y-1">
                                <li>Click "Scan QR Code" to open the camera scanner</li>
                                <li>Point your camera at a QR code containing DID or VC data</li>
                                <li>The system will automatically process the scanned data</li>
                                <li>For VCs, you can verify them using the verify button</li>
                                <li>You can copy or download the scanned data for reference</li>
                            </ul>
                        </div>
                    </div>
                </div>
            </div>

            {/* QR Scanner Modal */}
            {showScanner && (
                <QRScanner
                    onScan={handleQRScan}
                    onClose={() => setShowScanner(false)}
                    title="Scan QR Code"
                />
            )}
        </div>
    );
};

export default QRScannerPage;
