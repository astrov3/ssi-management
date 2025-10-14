import { Copy, Download, Eye, EyeOff } from 'lucide-react';
import { useEffect, useState } from 'react';
import toast from 'react-hot-toast';
import { generateQRCode } from '../utils/qrCode';

const QRDisplay = ({ data, title = "QR Code", showData = false, className = "" }) => {
    const [qrCodeDataURL, setQrCodeDataURL] = useState(null);
    const [loading, setLoading] = useState(false);
    const [showRawData, setShowRawData] = useState(showData);

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
                            title={showRawData ? "Hide data" : "Show data"}
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
                {showRawData && (
                    <div className="w-full max-w-md">
                        <div className="bg-gray-50 border border-gray-200 rounded-lg p-3">
                            <h4 className="text-sm font-medium text-gray-700 mb-2">Raw Data:</h4>
                            <pre className="text-xs text-gray-600 whitespace-pre-wrap break-all overflow-auto max-h-32">
                                {typeof data === 'string' ? data : JSON.stringify(data, null, 2)}
                            </pre>
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
