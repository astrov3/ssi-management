import {
    AlertCircle,
    CheckCircle,
    Eye,
    Plus,
    QrCode,
    XCircle
} from 'lucide-react';
import { useEffect, useState } from 'react';
import toast from 'react-hot-toast';
import QRDisplay from '../components/QRDisplay';
import QRScanner from '../components/QRScanner';
import { useStore } from '../store/useStore';

const DIDManagement = () => {
    const {
        isConnected,
        connectWallet,
        currentOrgID,
        setCurrentOrgID,
        didData,
        didActive,
        checkDID,
        registerDID,
        loading
    } = useStore();

    const [showRegisterForm, setShowRegisterForm] = useState(false);
    const [showQRDisplay, setShowQRDisplay] = useState(false);
    const [showScanner, setShowScanner] = useState(false);
    const [formData, setFormData] = useState({
        orgID: '',
        data: ''
    });

    useEffect(() => {
        if (!isConnected) {
            connectWallet();
        }
    }, [isConnected, connectWallet]);

    const handleRegisterDID = async (e) => {
        e.preventDefault();

        if (!formData.orgID.trim() || !formData.data.trim()) {
            toast.error('Please fill in all fields');
            return;
        }

        const success = await registerDID(formData.orgID, formData.data);
        if (success) {
            setCurrentOrgID(formData.orgID);
            setShowRegisterForm(false);
            setFormData({ orgID: '', data: '' });
            toast.success('DID registered successfully');
        }
    };

    const handleCheckDID = async (e) => {
        e.preventDefault();

        if (!formData.orgID.trim()) {
            toast.error('Please enter an Organization ID');
            return;
        }

        const did = await checkDID(formData.orgID);
        if (did) {
            setCurrentOrgID(formData.orgID);
            toast.success('DID checked successfully');
        }
    };

    const handleQRScan = (data) => {
        if (data.type === 'DID') {
            setFormData({
                orgID: data.orgID,
                data: ''
            });
            setCurrentOrgID(data.orgID);
            toast.success('DID data loaded from QR code');
        } else {
            toast.error('Invalid QR code type for DID management');
        }
        setShowScanner(false);
    };

    const generateDIDQRData = () => {
        if (!didData || !currentOrgID) return null;

        return {
            type: 'DID',
            orgID: currentOrgID,
            owner: didData.owner,
            hashData: didData.hashData,
            uri: didData.uri,
            active: didData.active,
            timestamp: Date.now()
        };
    };

    return (
        <div className="space-responsive-y">
            {/* Header */}
            <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
                <div>
                    <h1 className="text-responsive-2xl font-bold text-gray-900">DID Management</h1>
                    <p className="mt-1 text-sm text-gray-700">
                        Register and manage your Digital Identity Documents
                    </p>
                </div>
                <div className="flex flex-col sm:flex-row gap-responsive-sm">
                    <button
                        onClick={() => setShowScanner(true)}
                        disabled={!isConnected}
                        className="btn-secondary"
                    >
                        <QrCode className="h-4 w-4 mr-2" />
                        Scan QR
                    </button>
                    <button
                        onClick={() => setShowRegisterForm(true)}
                        disabled={!isConnected}
                        className="btn-primary"
                    >
                        <Plus className="h-4 w-4 mr-2" />
                        Register DID
                    </button>
                </div>
            </div>

            {/* Connection Status */}
            {!isConnected && (
                <div className="alert alert-warning">
                    <div className="flex">
                        <div className="flex-shrink-0">
                            <AlertCircle className="h-5 w-5 text-yellow-400" />
                        </div>
                        <div className="ml-3">
                            <h3 className="text-sm font-medium text-yellow-800">
                                Wallet Required
                            </h3>
                            <div className="mt-2 text-sm text-yellow-700">
                                <p>Please connect your wallet to manage DIDs.</p>
                            </div>
                        </div>
                    </div>
                </div>
            )}

            {/* DID Form */}
            <div className="card">
                <h2 className="text-lg font-bold text-gray-900 mb-4">Check or Register DID</h2>

                <form onSubmit={handleCheckDID} className="space-y-4">
                    <div>
                        <label htmlFor="orgID" className="form-label">
                            Organization ID
                        </label>
                        <input
                            type="text"
                            id="orgID"
                            value={formData.orgID}
                            onChange={(e) => setFormData({ ...formData, orgID: e.target.value })}
                            className="form-input"
                            placeholder="Enter your organization ID"
                            disabled={!isConnected || loading}
                        />
                    </div>

                    <div className="flex space-x-3">
                        <button
                            type="submit"
                            disabled={!isConnected || loading}
                            className="btn-secondary"
                        >
                            {loading ? 'Checking...' : 'Check DID'}
                            <Eye className="h-4 w-4 ml-2" />
                        </button>
                    </div>
                </form>
            </div>

            {/* Current DID Status */}
            {didData && currentOrgID && (
                <div className="card">
                    <div className="flex items-center justify-between mb-4">
                        <h2 className="text-lg font-bold text-gray-900">Current DID Status</h2>
                        <div className="flex space-x-2">
                            <button
                                onClick={() => setShowQRDisplay(true)}
                                className="inline-flex items-center px-3 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                            >
                                <QrCode className="h-4 w-4 mr-2" />
                                Show QR
                            </button>
                        </div>
                    </div>

                    <dl className="grid grid-cols-1 gap-x-4 gap-y-6 sm:grid-cols-2">
                        <div>
                            <dt className="text-sm font-semibold text-gray-700">Organization ID</dt>
                            <dd className="mt-1 text-sm text-gray-900 font-mono bg-gray-50 p-3 rounded">
                                {currentOrgID}
                            </dd>
                        </div>

                        <div>
                            <dt className="text-sm font-semibold text-gray-700">Owner Address</dt>
                            <dd className="mt-1 text-sm text-gray-900 font-mono bg-gray-50 p-3 rounded">
                                {didData.owner}
                            </dd>
                        </div>

                        <div>
                            <dt className="text-sm font-semibold text-gray-700">Status</dt>
                            <dd className="mt-1">
                                <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${didActive
                                    ? 'bg-green-100 text-green-800'
                                    : 'bg-red-100 text-red-800'
                                    }`}>
                                    {didActive ? (
                                        <>
                                            <CheckCircle className="w-3 h-3 mr-1" />
                                            Active
                                        </>
                                    ) : (
                                        <>
                                            <XCircle className="w-3 h-3 mr-1" />
                                            Inactive
                                        </>
                                    )}
                                </span>
                            </dd>
                        </div>

                        <div>
                            <dt className="text-sm font-semibold text-gray-700">Data Hash</dt>
                            <dd className="mt-1 text-sm text-gray-900 font-mono bg-gray-50 p-3 rounded break-all">
                                {didData.hashData}
                            </dd>
                        </div>

                        <div className="sm:col-span-2">
                            <dt className="text-sm font-semibold text-gray-700">URI</dt>
                            <dd className="mt-1 text-sm text-gray-900 font-mono bg-gray-50 p-3 rounded break-all">
                                {didData.uri}
                            </dd>
                        </div>
                    </dl>
                </div>
            )}

            {/* Register DID Modal */}
            {showRegisterForm && (
                <div className="fixed inset-0 bg-black/50 overflow-y-auto h-full w-full z-50">
                    <div className="relative top-20 mx-auto p-5 border w-96 shadow-lg rounded-md bg-white">
                        <div className="mt-3">
                            <h3 className="text-lg font-bold text-gray-900 mb-4">Register New DID</h3>

                            <form onSubmit={handleRegisterDID} className="space-y-4">
                                <div>
                                    <label htmlFor="registerOrgID" className="form-label">
                                        Organization ID
                                    </label>
                                    <input
                                        type="text"
                                        id="registerOrgID"
                                        value={formData.orgID}
                                        onChange={(e) => setFormData({ ...formData, orgID: e.target.value })}
                                        className="form-input"
                                        placeholder="Enter organization ID"
                                        required
                                    />
                                </div>

                                <div>
                                    <label htmlFor="didData" className="form-label">
                                        DID Data
                                    </label>
                                    <textarea
                                        id="didData"
                                        rows={3}
                                        value={formData.data}
                                        onChange={(e) => setFormData({ ...formData, data: e.target.value })}
                                        className="form-input"
                                        placeholder="Enter DID data (JSON or text)"
                                        required
                                    />
                                </div>

                                <div className="flex justify-end space-x-3 pt-4">
                                    <button
                                        type="button"
                                        onClick={() => setShowRegisterForm(false)}
                                        className="px-4 py-2 border border-gray-300 rounded-md text-sm font-medium text-gray-700 bg-white hover:bg-gray-50"
                                    >
                                        Cancel
                                    </button>
                                    <button
                                        type="submit"
                                        disabled={loading}
                                        className="px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50"
                                    >
                                        {loading ? 'Registering...' : 'Register DID'}
                                    </button>
                                </div>
                            </form>
                        </div>
                    </div>
                </div>
            )}

            {/* QR Display Modal */}
            {showQRDisplay && (
                <div className="fixed inset-0 bg-black/50 overflow-y-auto h-full w-full z-50">
                    <div className="relative top-10 mx-auto p-5 border w-auto shadow-lg rounded-md bg-white max-w-md">
                        <div className="mt-3">
                            <QRDisplay
                                data={generateDIDQRData()}
                                title="DID QR Code"
                                showData={true}
                            />
                            <div className="mt-4 flex justify-end">
                                <button
                                    onClick={() => setShowQRDisplay(false)}
                                    className="px-4 py-2 border border-gray-300 rounded-md text-sm font-medium text-gray-700 bg-white hover:bg-gray-50"
                                >
                                    Close
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            )}

            {/* QR Scanner Modal */}
            {showScanner && (
                <QRScanner
                    onScan={handleQRScan}
                    onClose={() => setShowScanner(false)}
                    title="Scan DID QR Code"
                />
            )}
        </div>
    );
};

export default DIDManagement;
