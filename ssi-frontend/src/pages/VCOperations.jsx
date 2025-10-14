import {
    AlertCircle,
    CheckCircle,
    Plus,
    QrCode,
    Shield,
    Trash2,
    UserPlus,
    XCircle
} from 'lucide-react';
import { useEffect, useState } from 'react';
import toast from 'react-hot-toast';
import QRDisplay from '../components/QRDisplay';
import QRScanner from '../components/QRScanner';
import { useStore } from '../store/useStore';

const VCOperations = () => {
    const {
        isConnected,
        connectWallet,
        currentOrgID,
        didActive,
        vcLength,
        getVCCount,
        issueVC,
        verifyVC,
        revokeVC,
        getVC,
        authorizeIssuer,
        loading
    } = useStore();

    const [vcs, setVCs] = useState([]);
    const [showIssueForm, setShowIssueForm] = useState(false);
    const [showQRDisplay, setShowQRDisplay] = useState(false);
    const [showScanner, setShowScanner] = useState(false);
    const [showAuthorizeForm, setShowAuthorizeForm] = useState(false);
    const [selectedVC, setSelectedVC] = useState(null);
    const [formData, setFormData] = useState({
        vcData: '',
        issuerAddress: ''
    });
    const [verificationData, setVerificationData] = useState({
        vcIndex: '',
        providedHash: ''
    });

    useEffect(() => {
        if (!isConnected) {
            connectWallet();
        }
    }, [isConnected, connectWallet]);

    useEffect(() => {
        if (currentOrgID && isConnected) {
            loadVCs();
        }
    }, [currentOrgID, isConnected]);

    const loadVCs = async () => {
        if (!currentOrgID) return;

        const count = await getVCCount(currentOrgID);
        const vcList = [];

        for (let i = 0; i < count; i++) {
            const vc = await getVC(currentOrgID, i);
            if (vc) {
                vcList.push({ ...vc, index: i });
            }
        }

        setVCs(vcList);
    };

    const handleIssueVC = async (e) => {
        e.preventDefault();

        if (!formData.vcData.trim()) {
            toast.error('Please fill in VC data');
            return;
        }

        if (!didActive) {
            toast.error('DID must be active to issue VCs');
            return;
        }

        const success = await issueVC(currentOrgID, formData.vcData);
        if (success) {
            setShowIssueForm(false);
            setFormData({ vcData: '', issuerAddress: '' });
            await loadVCs(); // Reload VCs
            toast.success('VC issued successfully');
        }
    };

    const handleAuthorizeIssuer = async (e) => {
        e.preventDefault();

        if (!formData.issuerAddress.trim()) {
            toast.error('Please enter issuer address');
            return;
        }

        const success = await authorizeIssuer(currentOrgID, formData.issuerAddress);
        if (success) {
            setShowAuthorizeForm(false);
            setFormData({ vcData: '', issuerAddress: '' });
            toast.success('Issuer authorized successfully');
        }
    };

    const handleVerifyVC = async (e) => {
        e.preventDefault();

        if (!verificationData.vcIndex || !verificationData.providedHash.trim()) {
            toast.error('Please fill in all verification fields');
            return;
        }

        const isValid = await verifyVC(
            currentOrgID,
            parseInt(verificationData.vcIndex),
            verificationData.providedHash
        );

        toast.success(isValid ? 'VC is valid' : 'VC is invalid');
    };

    const handleRevokeVC = async (index) => {
        if (!window.confirm('Are you sure you want to revoke this VC?')) {
            return;
        }

        const success = await revokeVC(currentOrgID, index);
        if (success) {
            await loadVCs(); // Reload VCs
            toast.success('VC revoked successfully');
        }
    };

    const handleQRScan = (data) => {
        if (data.type === 'VC') {
            setVerificationData({
                vcIndex: '0', // Default to first VC for verification
                providedHash: data.hashCredential
            });
            toast.success('VC data loaded from QR code');
        } else if (data.type === 'VERIFICATION_REQUEST') {
            setVerificationData({
                vcIndex: data.vcIndex.toString(),
                providedHash: ''
            });
            toast.success('Verification request loaded from QR code');
        } else {
            toast.error('Invalid QR code type for VC operations');
        }
        setShowScanner(false);
    };

    const generateVCQRData = (vc) => {
        return {
            type: 'VC',
            orgID: currentOrgID,
            hashCredential: vc.hashCredential,
            issuer: vc.issuer,
            uri: vc.uri,
            valid: vc.valid,
            index: vc.index,
            timestamp: Date.now()
        };
    };

    const formatAddress = (address) => {
        return `${address.slice(0, 6)}...${address.slice(-4)}`;
    };

    return (
        <div className="space-responsive-y">
            {/* Header */}
            <div className="flex-responsive sm:items-center sm:justify-between gap-responsive">
                <div>
                    <h1 className="text-responsive-2xl font-bold text-gray-900">VC Operations</h1>
                    <p className="mt-1 text-sm text-gray-700">
                        Issue, verify, and manage Verifiable Credentials
                    </p>
                </div>
                <div className="flex-responsive gap-responsive-sm">
                    <button
                        onClick={() => setShowScanner(true)}
                        disabled={!isConnected}
                        className="btn-secondary btn-sm"
                    >
                        <QrCode className="h-4 w-4 mr-2" />
                        Scan QR
                    </button>
                    <button
                        onClick={() => setShowAuthorizeForm(true)}
                        disabled={!isConnected || !currentOrgID}
                        className="btn-secondary btn-sm"
                    >
                        <UserPlus className="h-4 w-4 mr-2" />
                        Authorize Issuer
                    </button>
                    <button
                        onClick={() => setShowIssueForm(true)}
                        disabled={!isConnected || !currentOrgID || !didActive}
                        className="btn-primary btn-sm"
                    >
                        <Plus className="h-4 w-4 mr-2" />
                        Issue VC
                    </button>
                </div>
            </div>

            {/* Status Checks */}
            {
                !isConnected && (
                    <div className="alert alert-warning">
                        <div className="flex">
                            <div className="flex-shrink-0">
                                <AlertCircle className="h-5 w-5" />
                            </div>
                            <div className="ml-3">
                                <h3 className="text-sm font-medium">
                                    Wallet Required
                                </h3>
                                <div className="mt-2 text-sm">
                                    <p>Please connect your wallet to manage VCs.</p>
                                </div>
                            </div>
                        </div>
                    </div>
                )
            }

            {
                isConnected && !currentOrgID && (
                    <div className="alert alert-warning">
                        <div className="flex">
                            <div className="flex-shrink-0">
                                <AlertCircle className="h-5 w-5" />
                            </div>
                            <div className="ml-3">
                                <h3 className="text-sm font-medium">
                                    DID Required
                                </h3>
                                <div className="mt-2 text-sm">
                                    <p>Please register or select a DID first.</p>
                                </div>
                            </div>
                        </div>
                    </div>
                )
            }

            {
                isConnected && currentOrgID && !didActive && (
                    <div className="alert alert-error">
                        <div className="flex">
                            <div className="flex-shrink-0">
                                <XCircle className="h-5 w-5" />
                            </div>
                            <div className="ml-3">
                                <h3 className="text-sm font-medium">
                                    DID Inactive
                                </h3>
                                <div className="mt-2 text-sm">
                                    <p>Your DID is inactive. VCs cannot be issued for inactive DIDs.</p>
                                </div>
                            </div>
                        </div>
                    </div>
                )
            }

            {/* VC List */}
            {
                currentOrgID && (
                    <div className="card">
                        <div className="px-6 py-4 border-b border-gray-200 -m-6 mb-6">
                            <h2 className="text-lg font-bold text-gray-900">
                                Verifiable Credentials ({vcLength})
                            </h2>
                        </div>

                        {vcs.length === 0 ? (
                            <div className="px-6 py-12 text-center">
                                <Shield className="mx-auto h-12 w-12 text-gray-400" />
                                <h3 className="mt-2 text-sm font-semibold text-gray-900">No VCs</h3>
                                <p className="mt-1 text-sm text-gray-700">
                                    Get started by issuing your first verifiable credential.
                                </p>
                            </div>
                        ) : (
                            <div className="divide-y divide-base-300">
                                {vcs.map((vc, index) => (
                                    <div key={index} className="px-responsive py-4">
                                        <div className="flex-responsive sm:items-center sm:justify-between gap-responsive">
                                            <div className="flex-1">
                                                <div className="flex-responsive sm:items-center gap-responsive-sm">
                                                    <span className={`badge ${vc.valid
                                                        ? 'badge-success'
                                                        : 'badge-error'
                                                        }`}>
                                                        {vc.valid ? (
                                                            <>
                                                                <CheckCircle className="w-3 h-3 mr-1" />
                                                                Valid
                                                            </>
                                                        ) : (
                                                            <>
                                                                <XCircle className="w-3 h-3 mr-1" />
                                                                Revoked
                                                            </>
                                                        )}
                                                    </span>
                                                    <span className="text-sm text-base-content/70">
                                                        Index: {vc.index}
                                                    </span>
                                                </div>

                                                <div className="mt-2 grid-responsive-3 gap-responsive-sm">
                                                    <div>
                                                        <dt className="text-xs font-semibold text-gray-700">Issuer</dt>
                                                        <dd className="text-sm text-gray-900 font-mono">
                                                            {formatAddress(vc.issuer)}
                                                        </dd>
                                                    </div>
                                                    <div>
                                                        <dt className="text-xs font-semibold text-gray-700">Hash</dt>
                                                        <dd className="text-sm text-gray-900 font-mono break-all">
                                                            {vc.hashCredential.slice(0, 20)}...
                                                        </dd>
                                                    </div>
                                                </div>
                                            </div>

                                            <div className="flex space-x-2 ml-4">
                                                <button
                                                    onClick={() => {
                                                        setSelectedVC(vc);
                                                        setShowQRDisplay(true);
                                                    }}
                                                    className="btn btn-ghost btn-sm text-base-content/60 hover:text-base-content"
                                                    title="Show QR Code"
                                                >
                                                    <QrCode className="h-4 w-4" />
                                                </button>

                                                <button
                                                    onClick={() => handleRevokeVC(vc.index)}
                                                    disabled={!vc.valid}
                                                    className="btn btn-ghost btn-sm text-base-content/60 hover:text-error disabled:opacity-50 disabled:cursor-not-allowed"
                                                    title="Revoke VC"
                                                >
                                                    <Trash2 className="h-4 w-4" />
                                                </button>
                                            </div>
                                        </div>
                                    </div>
                                ))}
                            </div>
                        )}
                    </div>
                )
            }

            {/* Verification Form */}
            {
                currentOrgID && (
                    <div className="card">
                        <h2 className="text-responsive-lg font-bold text-gray-900 mb-4">Verify VC</h2>

                        <form onSubmit={handleVerifyVC} className="space-responsive-y">
                            <div className="grid-responsive-3 gap-responsive">
                                <div>
                                    <label htmlFor="vcIndex" className="form-label">
                                        VC Index
                                    </label>
                                    <input
                                        type="number"
                                        id="vcIndex"
                                        value={verificationData.vcIndex}
                                        onChange={(e) => setVerificationData({ ...verificationData, vcIndex: e.target.value })}
                                        className="form-input"
                                        placeholder="Enter VC index"
                                        min="0"
                                    />
                                </div>

                                <div>
                                    <label htmlFor="providedHash" className="form-label">
                                        Provided Hash
                                    </label>
                                    <input
                                        type="text"
                                        id="providedHash"
                                        value={verificationData.providedHash}
                                        onChange={(e) => setVerificationData({ ...verificationData, providedHash: e.target.value })}
                                        className="form-input"
                                        placeholder="Enter hash to verify"
                                    />
                                </div>
                            </div>

                            <div className="flex justify-end">
                                <button
                                    type="submit"
                                    disabled={loading}
                                    className="btn-primary btn-sm"
                                >
                                    {loading ? 'Verifying...' : 'Verify VC'}
                                    <CheckCircle className="h-4 w-4 ml-2" />
                                </button>
                            </div>
                        </form>
                    </div>
                )
            }

            {/* Issue VC Modal */}
            {
                showIssueForm && (
                    <div className="modal">
                        <div className="modal-content">
                            <div className="mt-3">
                                <h3 className="text-responsive-lg font-bold text-gray-900 mb-4">Issue New VC</h3>

                                <form onSubmit={handleIssueVC} className="space-responsive-y">
                                    <div>
                                        <label htmlFor="vcData" className="form-label">
                                            VC Data
                                        </label>
                                        <textarea
                                            id="vcData"
                                            rows={4}
                                            value={formData.vcData}
                                            onChange={(e) => setFormData({ ...formData, vcData: e.target.value })}
                                            className="form-input"
                                            placeholder="Enter VC data (JSON or text)"
                                            required
                                        />
                                    </div>

                                    <div className="flex justify-end gap-responsive-sm pt-4">
                                        <button
                                            type="button"
                                            onClick={() => setShowIssueForm(false)}
                                            className="btn-secondary btn-sm"
                                        >
                                            Cancel
                                        </button>
                                        <button
                                            type="submit"
                                            disabled={loading}
                                            className="btn-primary btn-sm"
                                        >
                                            {loading ? 'Issuing...' : 'Issue VC'}
                                        </button>
                                    </div>
                                </form>
                            </div>
                        </div>
                    </div>
                )
            }

            {/* Authorize Issuer Modal */}
            {
                showAuthorizeForm && (
                    <div className="modal">
                        <div className="modal-content">
                            <div className="mt-3">
                                <h3 className="text-responsive-lg font-bold text-gray-900 mb-4">Authorize Issuer</h3>

                                <form onSubmit={handleAuthorizeIssuer} className="space-responsive-y">
                                    <div>
                                        <label htmlFor="issuerAddress" className="form-label">
                                            Issuer Address
                                        </label>
                                        <input
                                            type="text"
                                            id="issuerAddress"
                                            value={formData.issuerAddress}
                                            onChange={(e) => setFormData({ ...formData, issuerAddress: e.target.value })}
                                            className="form-input"
                                            placeholder="Enter issuer wallet address"
                                            required
                                        />
                                    </div>

                                    <div className="flex justify-end gap-responsive-sm pt-4">
                                        <button
                                            type="button"
                                            onClick={() => setShowAuthorizeForm(false)}
                                            className="btn-secondary btn-sm"
                                        >
                                            Cancel
                                        </button>
                                        <button
                                            type="submit"
                                            disabled={loading}
                                            className="btn-primary btn-sm"
                                        >
                                            {loading ? 'Authorizing...' : 'Authorize Issuer'}
                                        </button>
                                    </div>
                                </form>
                            </div>
                        </div>
                    </div>
                )
            }

            {/* QR Display Modal */}
            {
                showQRDisplay && selectedVC && (
                    <div className="modal">
                        <div className="modal-content-responsive max-w-md">
                            <div className="mt-3">
                                <QRDisplay
                                    data={generateVCQRData(selectedVC)}
                                    title="VC QR Code"
                                    showData={true}
                                />
                                <div className="mt-4 flex justify-end">
                                    <button
                                        onClick={() => setShowQRDisplay(false)}
                                        className="btn-responsive-sm btn-outline btn-neutral"
                                    >
                                        Close
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                )
            }

            {/* QR Scanner Modal */}
            {
                showScanner && (
                    <QRScanner
                        onScan={handleQRScan}
                        onClose={() => setShowScanner(false)}
                        title="Scan VC QR Code"
                    />
                )
            }
        </div>
    )
};

export default VCOperations;
