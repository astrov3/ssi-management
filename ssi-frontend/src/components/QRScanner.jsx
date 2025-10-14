import { Html5QrcodeScanner } from 'html5-qrcode';
import { AlertCircle, Camera, X } from 'lucide-react';
import { useEffect, useState } from 'react';
import { parseQRCodeData, validateQRCodeData } from '../utils/qrCode';

const QRScanner = ({ onScan, onClose, title = "Scan QR Code" }) => {
    const [isScanning, setIsScanning] = useState(false);
    const [error, setError] = useState(null);
    const [scanner, setScanner] = useState(null);

    useEffect(() => {
        const initializeScanner = () => {
            try {
                const html5QrcodeScanner = new Html5QrcodeScanner(
                    "qr-reader",
                    {
                        fps: 10,
                        qrbox: { width: 250, height: 250 },
                        aspectRatio: 1.0,
                        showTorchButtonIfSupported: true,
                        showZoomSliderIfSupported: true,
                        defaultZoomValueIfSupported: 2,
                        useBarCodeDetectorIfSupported: true,
                    },
                    false
                );

                html5QrcodeScanner.render(
                    (decodedText) => {
                        try {
                            const parsedData = parseQRCodeData(decodedText);

                            if (!validateQRCodeData(parsedData)) {
                                setError('Invalid QR code format');
                                return;
                            }

                            onScan(parsedData);
                            html5QrcodeScanner.clear();
                            setIsScanning(false);
                        } catch (error) {
                            setError('Failed to parse QR code data: ' + error.message);
                        }
                    },
                    (error) => {
                        // Handle scan errors (but don't show them as they're usually just "no QR code found")
                        if (error && !error.includes('NotFoundException')) {
                            console.warn('QR scan error:', error);
                        }
                    }
                );

                setScanner(html5QrcodeScanner);
                setIsScanning(true);
                setError(null);
            } catch (error) {
                console.error('Error initializing QR scanner:', error);
                setError('Failed to initialize camera. Please check permissions.');
            }
        };

        // Small delay to ensure the DOM element is ready
        const timer = setTimeout(initializeScanner, 100);

        return () => {
            clearTimeout(timer);
            if (scanner) {
                scanner.clear();
            }
        };
    }, [onScan]);

    const handleClose = () => {
        if (scanner) {
            scanner.clear();
        }
        onClose();
    };

    return (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
            <div className="bg-white rounded-lg p-4 sm:p-6 max-w-sm sm:max-w-md w-full relative">
                {/* Header */}
                <div className="flex items-center justify-between mb-4">
                    <div className="flex items-center space-x-2">
                        <Camera className="w-5 h-5 text-blue-600" />
                        <h3 className="text-base sm:text-lg font-semibold text-gray-900">{title}</h3>
                    </div>
                    <button
                        onClick={handleClose}
                        className="p-1 hover:bg-gray-100 rounded-full transition-colors"
                    >
                        <X className="w-5 h-5 text-gray-500" />
                    </button>
                </div>

                {/* Scanner */}
                <div className="relative">
                    <div id="qr-reader" className="w-full"></div>

                    {error && (
                        <div className="mt-4 p-3 bg-red-50 border border-red-200 rounded-md flex items-start space-x-2">
                            <AlertCircle className="w-5 h-5 text-red-500 mt-0.5 flex-shrink-0" />
                            <div>
                                <p className="text-sm text-red-800">{error}</p>
                                <button
                                    onClick={() => setError(null)}
                                    className="text-xs text-red-600 hover:text-red-800 underline mt-1"
                                >
                                    Dismiss
                                </button>
                            </div>
                        </div>
                    )}
                </div>

                {/* Instructions */}
                <div className="mt-4 text-sm text-gray-600">
                    <p>Point your camera at a QR code to scan it.</p>
                    <p className="mt-1">Make sure the QR code is clearly visible and well-lit.</p>
                </div>

                {/* Status */}
                {isScanning && (
                    <div className="mt-4 flex items-center justify-center space-x-2 text-sm text-blue-600">
                        <div className="w-2 h-2 bg-blue-600 rounded-full animate-pulse"></div>
                        <span>Scanning...</span>
                    </div>
                )}
            </div>
        </div>
    );
};

export default QRScanner;
