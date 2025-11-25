import {
    AlertCircle,
    CheckCircle,
    Eye,
    Plus,
    QrCode,
    Trash2,
    XCircle
} from 'lucide-react';
import { useEffect, useMemo, useState } from 'react';
import toast from 'react-hot-toast';
import QRDisplay from '../components/QRDisplay';
import QRScanner from '../components/QRScanner';
import { useStore } from '../store/useStore';

const DIDManagement = () => {
    const {
        isConnected,
        connectWallet,
        account,
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
    const [showUpdateForm, setShowUpdateForm] = useState(false);
    const [showScanner, setShowScanner] = useState(false);
    const [formData, setFormData] = useState({
        orgID: '',
        serviceEndpoint: '',
        alsoKnownAs: '',
        description: ''
    });
    const [metadataFields, setMetadataFields] = useState([
        { key: 'name', value: '' },
        { key: 'email', value: '' }
    ]);
    const [orgIdError, setOrgIdError] = useState('');

    useEffect(() => {
        if (!isConnected) {
            connectWallet();
        }
    }, [isConnected, connectWallet]);

    const orgIdPattern = useMemo(() => /^[a-zA-Z0-9_.-]{3,64}$|^0x[a-fA-F0-9]{40}$/, []);

    const validateOrgId = (value) => {
        if (!value.trim()) {
            setOrgIdError('Organization ID is required');
            return false;
        }

        if (!orgIdPattern.test(value.trim())) {
            setOrgIdError('Use 3-64 characters (letters, numbers, ".", "-", "_") or a wallet address');
            return false;
        }

        setOrgIdError('');
        return true;
    };

    const handleUseWalletAddress = () => {
        if (!account) {
            toast.error('Connect wallet first');
            return;
        }

        setFormData((prev) => ({
            ...prev,
            orgID: account
        }));
        setOrgIdError('');
        toast.success('Organization ID set to your wallet address');
    };

    const handleMetadataChange = (index, field, value) => {
        setMetadataFields((prev) => {
            const next = [...prev];
            next[index] = {
                ...next[index],
                [field]: value
            };
            return next;
        });
    };

    const handleAddMetadataField = () => {
        setMetadataFields((prev) => [...prev, { key: '', value: '' }]);
    };

    const handleRemoveMetadataField = (index) => {
        setMetadataFields((prev) => prev.filter((_, i) => i !== index));
    };

    const handleRegisterDID = async (e) => {
        e.preventDefault();

        if (!validateOrgId(formData.orgID)) {
            return;
        }

        const customData = metadataFields.reduce((acc, field) => {
            const key = field.key.trim();
            const value = field.value.trim();
            if (key && value) {
                acc[key] = value;
            }
            return acc;
        }, {});

        const payload = {
            serviceEndpoint: formData.serviceEndpoint.trim() || undefined,
            description: formData.description.trim() || undefined,
            alsoKnownAs: formData.alsoKnownAs
                ? formData.alsoKnownAs
                    .split(',')
                    .map((item) => item.trim())
                    .filter(Boolean)
                : undefined,
            ...customData
        };

        const success = await registerDID(formData.orgID.trim(), payload);
        if (success) {
            setCurrentOrgID(formData.orgID.trim());
            setShowRegisterForm(false);
            setFormData({
                orgID: '',
                serviceEndpoint: '',
                alsoKnownAs: '',
                description: ''
            });
            setMetadataFields([
                { key: 'name', value: '' },
                { key: 'email', value: '' }
            ]);
            toast.success('DID registered successfully');
        }
    };

    const handleCheckDID = async (e) => {
        e.preventDefault();

        if (!validateOrgId(formData.orgID)) {
            return;
        }

        const did = await checkDID(formData.orgID.trim());
        if (did) {
            setCurrentOrgID(formData.orgID.trim());
            toast.success('DID checked successfully');
        }
    };

    const handleQRScan = (data) => {
        if (data.type === 'DID') {
            setFormData({
                orgID: data.orgID,
                serviceEndpoint: '',
                alsoKnownAs: '',
                description: ''
            });
            setMetadataFields([
                { key: 'name', value: '' },
                { key: 'email', value: '' }
            ]);
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
                            onChange={(e) => {
                                const value = e.target.value;
                                setFormData({ ...formData, orgID: value });
                                if (orgIdError) {
                                    validateOrgId(value);
                                }
                            }}
                            className="form-input"
                            placeholder="Enter your organization ID"
                            disabled={!isConnected || loading}
                        />
                        {orgIdError && (
                            <p className="mt-1 text-xs text-error">
                                {orgIdError}
                            </p>
                        )}
                    </div>

                    <div className="flex flex-wrap gap-3">
                        <button
                            type="submit"
                            disabled={!isConnected || loading}
                            className="btn-secondary"
                        >
                            {loading ? 'Checking...' : 'Check DID'}
                            <Eye className="h-4 w-4 ml-2" />
                        </button>
                        <button
                            type="button"
                            onClick={handleUseWalletAddress}
                            disabled={!isConnected || loading || !account}
                            className="btn-outline"
                        >
                            Use wallet address
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
                            <button
                                onClick={() => setShowUpdateForm(true)}
                                className="inline-flex items-center px-3 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                            >
                                <Plus className="h-4 w-4 mr-2" />
                                Update DID
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
                <div
                    className="fixed inset-0 bg-black/50 overflow-y-auto h-full w-full z-50"
                    onClick={(event) => {
                        if (event.target === event.currentTarget) {
                            setShowRegisterForm(false);
                        }
                    }}
                >
                    <div className="relative top-16 mx-auto p-6 border w-full max-w-2xl shadow-lg rounded-lg bg-white">
                        <div className="flex items-start justify-between mb-4">
                            <div>
                                <h3 className="text-lg font-bold text-gray-900">Register New DID</h3>
                                <p className="text-sm text-gray-600 mt-1">
                                    Structure your DID document with friendly form controls. Optional fields help enrich the DID metadata.
                                </p>
                            </div>
                            <button
                                type="button"
                                onClick={() => setShowRegisterForm(false)}
                                className="text-gray-400 hover:text-gray-600 transition-colors"
                                aria-label="Close"
                            >
                                <XCircle className="w-5 h-5" />
                            </button>
                        </div>

                        <form onSubmit={handleRegisterDID} className="space-y-5">
                            <div>
                                <label htmlFor="registerOrgID" className="form-label">
                                    Organization ID
                                </label>
                                <input
                                    type="text"
                                    id="registerOrgID"
                                    value={formData.orgID}
                                    onChange={(e) => {
                                        const value = e.target.value;
                                        setFormData({ ...formData, orgID: value });
                                        if (orgIdError) {
                                            validateOrgId(value);
                                        }
                                    }}
                                    className="form-input"
                                    placeholder="Enter organization ID"
                                    required
                                />
                                <p className="mt-1 text-xs text-gray-500">
                                    Use 3-64 characters (letters, numbers, \".\", \"-\", \"_\") or your wallet address.
                                </p>
                            </div>

                            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                                <div>
                                    <label htmlFor="serviceEndpoint" className="form-label">
                                        Service Endpoint (optional)
                                    </label>
                                    <input
                                        id="serviceEndpoint"
                                        type="url"
                                        value={formData.serviceEndpoint}
                                        onChange={(e) => setFormData({ ...formData, serviceEndpoint: e.target.value })}
                                        className="form-input"
                                        placeholder="https://example.com/ssi"
                                    />
                                    <p className="mt-1 text-xs text-gray-500">
                                        Provide a URL where verifiers can reach your SSI services.
                                    </p>
                                </div>
                                <div>
                                    <label htmlFor="alsoKnownAs" className="form-label">
                                        Also Known As (optional)
                                    </label>
                                    <input
                                        id="alsoKnownAs"
                                        type="text"
                                        value={formData.alsoKnownAs}
                                        onChange={(e) => setFormData({ ...formData, alsoKnownAs: e.target.value })}
                                        className="form-input"
                                        placeholder="Comma-separated domains or handles"
                                    />
                                    <p className="mt-1 text-xs text-gray-500">
                                        Example: org.com, twitter.com/yourorg, github.com/yourorg
                                    </p>
                                </div>
                            </div>

                            <div>
                                <label htmlFor="didDescription" className="form-label">
                                    Organization Description
                                </label>
                                <textarea
                                    id="didDescription"
                                    rows={3}
                                    value={formData.description}
                                    onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                                    className="form-input"
                                    placeholder="Brief description about your organization"
                                />
                            </div>

                            <div>
                                <div className="flex items-center justify-between mb-2">
                                    <label className="form-label mb-0">Contact & Metadata</label>
                                    <button
                                        type="button"
                                        onClick={handleAddMetadataField}
                                        className="btn-ghost btn-sm inline-flex items-center gap-1"
                                    >
                                        <Plus className="w-4 h-4" />
                                        Add field
                                    </button>
                                </div>
                                <div className="space-y-3">
                                    {metadataFields.map((field, index) => (
                                        <div key={`metadata-${index}`} className="grid grid-cols-1 sm:grid-cols-[1fr_1fr_auto] gap-3 items-center">
                                            <input
                                                type="text"
                                                value={field.key}
                                                onChange={(e) => handleMetadataChange(index, 'key', e.target.value)}
                                                className="form-input"
                                                placeholder="Field name (e.g., phone, supportEmail)"
                                            />
                                            <input
                                                type="text"
                                                value={field.value}
                                                onChange={(e) => handleMetadataChange(index, 'value', e.target.value)}
                                                className="form-input"
                                                placeholder="Field value"
                                            />
                                            <button
                                                type="button"
                                                onClick={() => handleRemoveMetadataField(index)}
                                                className="btn-ghost text-error px-3 py-2 rounded-md hover:bg-error/10"
                                                aria-label="Remove field"
                                            >
                                                <Trash2 className="w-4 h-4" />
                                            </button>
                                        </div>
                                    ))}
                                </div>
                                <p className="mt-1 text-xs text-gray-500">
                                    These fields become part of the DID metadata (e.g., contact email, support phone).
                                </p>
                            </div>

                            <div className="flex justify-end gap-3 pt-2">
                                <button
                                    type="button"
                                    onClick={() => setShowRegisterForm(false)}
                                    className="btn-secondary btn-sm"
                                >
                                    Cancel
                                </button>
                                <button
                                    type="submit"
                                    disabled={loading}
                                    className="btn-primary btn-sm"
                                >
                                    {loading ? 'Registering...' : 'Register DID'}
                                </button>
                            </div>
                        </form>
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

            {/* Update DID Modal */}
            {showUpdateForm && (
                <div
                    className="fixed inset-0 bg-black/50 overflow-y-auto h-full w-full z-50"
                    onClick={(event) => {
                        if (event.target === event.currentTarget) {
                            setShowUpdateForm(false);
                        }
                    }}
                >
                    <div className="relative top-16 mx-auto p-6 border w-full max-w-2xl shadow-lg rounded-lg bg-white">
                        <div className="flex items-start justify-between mb-4">
                            <div>
                                <h3 className="text-lg font-bold text-gray-900">Update DID</h3>
                                <p className="text-sm text-gray-600 mt-1">
                                    Add or modify metadata. This will upload a new DID Document and update the on-chain hash and URI.
                                </p>
                            </div>
                            <button
                                type="button"
                                onClick={() => setShowUpdateForm(false)}
                                className="text-gray-400 hover:text-gray-600 transition-colors"
                                aria-label="Close"
                            >
                                <XCircle className="w-5 h-5" />
                            </button>
                        </div>

                        <form
                            onSubmit={async (e) => {
                                e.preventDefault();
                                const customData = metadataFields.reduce((acc, field) => {
                                    const key = field.key.trim();
                                    const value = field.value.trim();
                                    if (key && value) acc[key] = value;
                                    return acc;
                                }, {});

                                const payload = {
                                    serviceEndpoint: formData.serviceEndpoint.trim() || undefined,
                                    description: formData.description.trim() || undefined,
                                    alsoKnownAs: formData.alsoKnownAs
                                        ? formData.alsoKnownAs
                                            .split(',')
                                            .map((item) => item.trim())
                                            .filter(Boolean)
                                        : undefined,
                                    ...customData
                                };

                                const ok = await useStore.getState().updateDID(currentOrgID, payload);
                                if (ok) {
                                    setShowUpdateForm(false);
                                    toast.success('DID updated');
                                }
                            }}
                            className="space-y-5"
                        >
                            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                                <div>
                                    <label htmlFor="updServiceEndpoint" className="form-label">
                                        Service Endpoint (optional)
                                    </label>
                                    <input
                                        id="updServiceEndpoint"
                                        type="url"
                                        value={formData.serviceEndpoint}
                                        onChange={(e) => setFormData({ ...formData, serviceEndpoint: e.target.value })}
                                        className="form-input"
                                        placeholder="https://example.com/ssi"
                                    />
                                </div>
                                <div>
                                    <label htmlFor="updAlsoKnownAs" className="form-label">
                                        Also Known As (optional)
                                    </label>
                                    <input
                                        id="updAlsoKnownAs"
                                        type="text"
                                        value={formData.alsoKnownAs}
                                        onChange={(e) => setFormData({ ...formData, alsoKnownAs: e.target.value })}
                                        className="form-input"
                                        placeholder="Comma-separated domains or handles"
                                    />
                                </div>
                            </div>

                            <div>
                                <label htmlFor="updDescription" className="form-label">
                                    Organization Description
                                </label>
                                <textarea
                                    id="updDescription"
                                    rows={3}
                                    value={formData.description}
                                    onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                                    className="form-input"
                                    placeholder="Brief description or updates"
                                />
                            </div>

                            <div>
                                <div className="flex items-center justify-between mb-2">
                                    <label className="form-label mb-0">Contact & Metadata</label>
                                    <button
                                        type="button"
                                        onClick={handleAddMetadataField}
                                        className="btn-ghost btn-sm inline-flex items-center gap-1"
                                    >
                                        <Plus className="w-4 h-4" />
                                        Add field
                                    </button>
                                </div>
                                <div className="space-y-3">
                                    {metadataFields.map((field, index) => (
                                        <div key={`upd-metadata-${index}`} className="grid grid-cols-1 sm:grid-cols-[1fr_1fr_auto] gap-3 items-center">
                                            <input
                                                type="text"
                                                value={field.key}
                                                onChange={(e) => handleMetadataChange(index, 'key', e.target.value)}
                                                className="form-input"
                                                placeholder="Field name (e.g., phone, supportEmail)"
                                            />
                                            <input
                                                type="text"
                                                value={field.value}
                                                onChange={(e) => handleMetadataChange(index, 'value', e.target.value)}
                                                className="form-input"
                                                placeholder="Field value"
                                            />
                                            <button
                                                type="button"
                                                onClick={() => handleRemoveMetadataField(index)}
                                                className="btn-ghost text-error px-3 py-2 rounded-md hover:bg-error/10"
                                                aria-label="Remove field"
                                            >
                                                <Trash2 className="w-4 h-4" />
                                            </button>
                                        </div>
                                    ))}
                                </div>
                            </div>

                            <div className="flex justify-end gap-3 pt-2">
                                <button
                                    type="button"
                                    onClick={() => setShowUpdateForm(false)}
                                    className="btn-secondary btn-sm"
                                >
                                    Cancel
                                </button>
                                <button
                                    type="submit"
                                    disabled={loading}
                                    className="btn-primary btn-sm"
                                >
                                    {loading ? 'Updating...' : 'Update DID'}
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
        </div>
    );
};

export default DIDManagement;
