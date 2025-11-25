import { Copy, Download, Eye, EyeOff } from 'lucide-react';
import { useEffect, useMemo, useState } from 'react';
import toast from 'react-hot-toast';
import { generateQRCode } from '../utils/qrCode';

const QRDisplay = ({ data, title = "QR Code", showData = false, className = "" }) => {
    const [qrCodeDataURL, setQrCodeDataURL] = useState(null);
    const [loading, setLoading] = useState(false);
    const [showRawData, setShowRawData] = useState(false);

    const parsedData = useMemo(() => {
        if (!data) return null;

        if (typeof data === 'string') {
            try {
                return JSON.parse(data);
            } catch {
                return null;
            }
        }

        if (typeof data === 'object') {
            return data;
        }

        return null;
    }, [data]);

    const formatBoolean = (value) => (value ? 'Yes' : 'No');

    const formatTimestamp = (value) => {
        const date = typeof value === 'number' ? new Date(value) : new Date(String(value));
        if (Number.isNaN(date.getTime())) {
            return String(value);
        }
        return date.toLocaleString();
    };

    const summaryItems = useMemo(() => {
        if (!parsedData || typeof parsedData !== 'object') {
            return [];
        }

        const type = parsedData.type;
        const items = [];

        if (type === 'DID') {
            items.push({ label: 'Type', value: 'DID Document' });
            if (parsedData.orgID) items.push({ label: 'Organization ID', value: parsedData.orgID });
            if (parsedData.owner) items.push({ label: 'Owner Address', value: parsedData.owner });
            if (parsedData.hashData) items.push({ label: 'Data Hash', value: parsedData.hashData });
            if (parsedData.uri) items.push({ label: 'IPFS URI', value: parsedData.uri });
            if (parsedData.active !== undefined) items.push({ label: 'Status', value: parsedData.active ? 'Active' : 'Inactive' });
            if (parsedData.timestamp) items.push({ label: 'Generated At', value: formatTimestamp(parsedData.timestamp) });
            return items;
        }

        if (type === 'VC') {
            items.push({ label: 'Type', value: 'Verifiable Credential' });
            if (parsedData.orgID) items.push({ label: 'Organization ID', value: parsedData.orgID });
            if (parsedData.index !== undefined) items.push({ label: 'Credential Index', value: parsedData.index });
            if (parsedData.issuer) items.push({ label: 'Issuer Address', value: parsedData.issuer });
            if (parsedData.hashCredential) items.push({ label: 'Credential Hash', value: parsedData.hashCredential });
            if (parsedData.uri) items.push({ label: 'Credential URI', value: parsedData.uri });
            if (parsedData.valid !== undefined) items.push({ label: 'On-chain Status', value: parsedData.valid ? 'Valid' : 'Revoked' });
            if (parsedData.timestamp) items.push({ label: 'Generated At', value: formatTimestamp(parsedData.timestamp) });
            return items;
        }

        if (type === 'VERIFICATION_REQUEST') {
            items.push({ label: 'Type', value: 'Verification Request' });
            if (parsedData.orgID) items.push({ label: 'Organization ID', value: parsedData.orgID });
            if (parsedData.vcIndex !== undefined) items.push({ label: 'VC Index', value: parsedData.vcIndex });
            if (parsedData.timestamp) items.push({ label: 'Requested At', value: formatTimestamp(parsedData.timestamp) });
            return items;
        }

        // Fallback for other payloads: list first few keys
        return Object.entries(parsedData)
            .slice(0, 8)
            .map(([key, value]) => ({
                label: key,
                value: typeof value === 'boolean' ? formatBoolean(value) : typeof value === 'object' ? JSON.stringify(value) : String(value)
            }));
    }, [parsedData]);

    useEffect(() => {
        const generateQR = async () => {
            if (!data) return;

            setLoading(true);
            try {
                const qrCode = await generateQRCode(data);
                setQrCodeDataURL(qrCode);
            } catch (error) {
                console.error('Error generating QR code:', error);
                toast.error('Failed to generate QR code');
            } finally {
                setLoading(false);
            }
        };

        generateQR();
    }, [data]);

    const handleDownload = () => {
        if (!qrCodeDataURL) return;

        const link = document.createElement('a');
        link.download = `qr-code-${Date.now()}.png`;
        link.href = qrCodeDataURL;
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);

        toast.success('QR code downloaded');
    };

    const handleCopy = () => {
        if (!data) return;

        const dataString = typeof data === 'string' ? data : JSON.stringify(data, null, 2);

        navigator.clipboard.writeText(dataString).then(() => {
            toast.success('Data copied to clipboard');
        }).catch(() => {
            toast.error('Failed to copy data');
        });
    };

    if (!data) {
        return null;
    }

    return (
        <div className={`bg-white rounded-lg border border-gray-200 p-3 sm:p-4 ${className}`}>
            {/* Header */}
            <div className="flex items-center justify-between mb-4">
                <h3 className="text-base sm:text-lg font-semibold text-gray-900">{title}</h3>
                <div className="flex items-center space-x-2">
                    {showData && (
                        <button
                            onClick={() => setShowRawData(!showRawData)}
                            className="p-1 hover:bg-gray-100 rounded-full transition-colors"
                            title={showRawData ? "Hide details" : "Show details"}
                        >
                            {showRawData ? (
                                <EyeOff className="w-4 h-4 text-gray-600" />
                            ) : (
                                <Eye className="w-4 h-4 text-gray-600" />
                            )}
                        </button>
                    )}
                    <button
                        onClick={handleCopy}
                        className="p-1 hover:bg-gray-100 rounded-full transition-colors"
                        title="Copy data"
                    >
                        <Copy className="w-4 h-4 text-gray-600" />
                    </button>
                    <button
                        onClick={handleDownload}
                        className="p-1 hover:bg-gray-100 rounded-full transition-colors"
                        title="Download QR code"
                    >
                        <Download className="w-4 h-4 text-gray-600" />
                    </button>
                </div>
            </div>

            {/* QR Code */}
            <div className="flex flex-col items-center space-y-4">
                {loading ? (
                    <div className="w-40 h-40 sm:w-48 sm:h-48 bg-gray-100 rounded-lg flex items-center justify-center">
                        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
                    </div>
                ) : qrCodeDataURL ? (
                    <div className="w-40 h-40 sm:w-48 sm:h-48 bg-white border border-gray-200 rounded-lg p-2">
                        <img
                            src={qrCodeDataURL}
                            alt="QR Code"
                            className="w-full h-full object-contain"
                        />
                    </div>
                ) : (
                    <div className="w-40 h-40 sm:w-48 sm:h-48 bg-gray-100 rounded-lg flex items-center justify-center">
                        <span className="text-gray-500 text-sm">Failed to generate QR code</span>
                    </div>
                )}

                {/* Raw Data */}
                {showRawData && summaryItems.length > 0 && (
                    <div className="w-full max-w-md">
                        <div className="bg-gray-50 border border-gray-200 rounded-lg p-3">
                            <h4 className="text-sm font-medium text-gray-700 mb-3">Quick Details</h4>
                            <dl className="space-y-2">
                                {summaryItems.map((item, index) => (
                                    <div key={`${item.label}-${index}`} className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-1">
                                        <dt className="text-xs font-semibold text-gray-500 uppercase tracking-wide">
                                            {item.label}
                                        </dt>
                                        <dd className="text-sm text-gray-900 break-all sm:text-right">
                                            {item.value}
                                        </dd>
                                    </div>
                                ))}
                            </dl>
                        </div>
                    </div>
                )}
            </div>

            {/* Instructions */}
            <div className="mt-4 text-sm text-gray-600 text-center">
                <p>Scan this QR code with your camera or QR code reader</p>
            </div>
        </div>
    );
};

export default QRDisplay;
