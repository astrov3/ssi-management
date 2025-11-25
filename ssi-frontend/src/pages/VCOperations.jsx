import {
    AlertCircle,
    CheckCircle,
    Copy,
    Clock,
    Plus,
    QrCode,
    Shield,
    Trash2,
    UserPlus,
    XCircle,
    BadgeCheck,
    Send,
    X,
    Settings
} from 'lucide-react';
import { useEffect, useState, useCallback } from 'react';
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
        requestVerification,
        verifyCredential,
        setTrustedVerifier,
        isTrustedVerifier,
        getAdmin,
        account,
        loading
    } = useStore();

    const [vcs, setVCs] = useState([]);
    const [showIssueForm, setShowIssueForm] = useState(false);
    const [showQRDisplay, setShowQRDisplay] = useState(false);
    const [showScanner, setShowScanner] = useState(false);
    const [showAuthorizeForm, setShowAuthorizeForm] = useState(false);
    const [showVerificationRequestForm, setShowVerificationRequestForm] = useState(false);
    const [showAdminPanel, setShowAdminPanel] = useState(false);
    const [selectedVC, setSelectedVC] = useState(null);
    const [isAdmin, setIsAdmin] = useState(false);
    const [isVerifier, setIsVerifier] = useState(false);
    const [formData, setFormData] = useState({
        issuerAddress: '',
        expirationDate: '',
        vcType: 'Credential',
        notes: ''
    });
    const [claimsFields, setClaimsFields] = useState([
        { key: 'name', value: '' },
        { key: 'title', value: '' }
    ]);
    const [verificationData, setVerificationData] = useState({
        vcIndex: '',
        providedHash: ''
    });
    const [verificationRequestData, setVerificationRequestData] = useState({
        vcIndex: '',
        targetVerifier: '',
        metadataUri: ''
    });
    const [adminData, setAdminData] = useState({
        verifierAddress: '',
        allowed: true
    });

    const handleClaimFieldChange = (index, field, value) => {
        setClaimsFields((prev) => {
            const next = [...prev];
            next[index] = {
                ...next[index],
                [field]: value
            };
            return next;
        });
    };

    const handleAddClaimField = () => {
        setClaimsFields((prev) => [...prev, { key: '', value: '' }]);
    };

    const handleRemoveClaimField = (index) => {
        setClaimsFields((prev) => prev.filter((_, i) => i !== index));
    };

    const resetIssueForm = () => {
        setFormData((prev) => ({
            ...prev,
            expirationDate: '',
            vcType: 'Credential',
            notes: ''
        }));
        setClaimsFields([
            { key: 'name', value: '' },
            { key: 'title', value: '' }
        ]);
    };

    useEffect(() => {
        if (!isConnected) {
            connectWallet();
        }
    }, [isConnected, connectWallet]);

    const loadVCs = useCallback(async () => {
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
    }, [currentOrgID, getVCCount, getVC]);

    useEffect(() => {
        if (currentOrgID && isConnected) {
            loadVCs();
            checkAdminAndVerifierStatus();
        }
    }, [currentOrgID, isConnected, loadVCs]); // eslint-disable-line react-hooks/exhaustive-deps

    const checkAdminAndVerifierStatus = async () => {
        if (!account) return;
        try {
            const admin = await getAdmin();
            setIsAdmin(admin && admin.toLowerCase() === account.toLowerCase());
            
            const isVerifierCheck = await isTrustedVerifier(account);
            setIsVerifier(isVerifierCheck);
        } catch (error) {
            console.error('Error checking admin/verifier status:', error);
        }
    };

    const handleIssueVC = async (e) => {
        e.preventDefault();

        const claims = claimsFields.reduce((acc, field) => {
            const key = field.key.trim();
            const value = field.value.trim();
            if (key && value) {
                acc[key] = value;
            }
            return acc;
        }, {});

        if (formData.notes.trim()) {
            claims.notes = formData.notes.trim();
        }

        if (Object.keys(claims).length === 0) {
            toast.error('Please add at least one claim field');
            return;
        }

        if (!didActive) {
            toast.error('DID must be active to issue VCs');
            return;
        }

        // Prepare VC data with expiration date and type
        const vcData = {
            claims,
            type: formData.vcType || 'Credential',
            expirationDate: formData.expirationDate || null
        };

        const success = await issueVC(currentOrgID, vcData);
        if (success) {
            setShowIssueForm(false);
            resetIssueForm();
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
            setFormData((prev) => ({ ...prev, issuerAddress: '' }));
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

    const handleRequestVerification = async (e) => {
        e.preventDefault();
        if (!verificationRequestData.vcIndex || !verificationRequestData.metadataUri.trim()) {
            toast.error('Please fill in VC index and metadata URI');
            return;
        }

        const vcIndex = parseInt(verificationRequestData.vcIndex);
        if (isNaN(vcIndex) || vcIndex < 0) {
            toast.error('Invalid VC index');
            return;
        }

        const success = await requestVerification(
            currentOrgID,
            vcIndex,
            verificationRequestData.targetVerifier.trim() || null,
            verificationRequestData.metadataUri.trim()
        );
        
        if (success) {
            setShowVerificationRequestForm(false);
            setVerificationRequestData({ vcIndex: '', targetVerifier: '', metadataUri: '' });
            await loadVCs();
            toast.success('Verification request created successfully');
        }
    };

    const handleVerifyCredential = async (index) => {
        if (!window.confirm('Are you sure you want to verify this credential?')) {
            return;
        }

        const success = await verifyCredential(currentOrgID, index);
        if (success) {
            await loadVCs();
            toast.success('Credential verified successfully');
        }
    };

    const handleSetTrustedVerifier = async (e) => {
        e.preventDefault();
        if (!adminData.verifierAddress.trim()) {
            toast.error('Please enter verifier address');
            return;
        }

        const success = await setTrustedVerifier(adminData.verifierAddress.trim(), adminData.allowed);
        if (success) {
            setShowAdminPanel(false);
            setAdminData({ verifierAddress: '', allowed: true });
            await checkAdminAndVerifierStatus();
            toast.success(`Trusted verifier ${adminData.allowed ? 'added' : 'removed'} successfully`);
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

    const handleCopyToClipboard = async (value, label = 'Copied') => {
        if (!value) {
            toast.error('No data to copy');
            return;
        }

        try {
            await navigator.clipboard.writeText(value);
            toast.success(`${label} to clipboard`);
        } catch (error) {
            console.error('Clipboard copy failed', error);
            toast.error('Failed to copy');
        }
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
                    {isAdmin && (
                        <button
                            onClick={() => setShowAdminPanel(true)}
                            disabled={!isConnected}
                            className="btn-secondary btn-sm"
                        >
                            <Settings className="h-4 w-4 mr-2" />
                            Admin Panel
                        </button>
                    )}
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
                                <div className="mt-6">
                                    <button
                                        onClick={() => setShowIssueForm(true)}
                                        disabled={!isConnected || !currentOrgID || !didActive}
                                        className="btn btn-primary"
                                    >
                                        <Plus className="h-4 w-4 mr-2" />
                                        Issue Your First VC
                                    </button>
                                </div>
                            </div>
                        ) : (
                            <div className="divide-y divide-base-300">
                                {vcs.map((vc, index) => (
                                    <div key={index} className="px-responsive py-4">
                                        <div className="flex-responsive sm:items-center sm:justify-between gap-responsive">
                                            <div className="flex-1">
                                                <div className="flex-responsive sm:items-center gap-responsive-sm flex-wrap">
                                                    <span className={`badge ${vc.valid && !vc.isExpired
                                                        ? 'badge-success'
                                                        : 'badge-error'
                                                        }`}>
                                                        {vc.valid && !vc.isExpired ? (
                                                            <>
                                                                <CheckCircle className="w-3 h-3 mr-1" />
                                                                Valid
                                                            </>
                                                        ) : vc.isExpired ? (
                                                            <>
                                                                <XCircle className="w-3 h-3 mr-1" />
                                                                Expired
                                                            </>
                                                        ) : (
                                                            <>
                                                                <XCircle className="w-3 h-3 mr-1" />
                                                                Revoked
                                                            </>
                                                        )}
                                                    </span>
                                                    {vc.verified && (
                                                        <span className="badge badge-success">
                                                            <BadgeCheck className="w-3 h-3 mr-1" />
                                                            Verified
                                                        </span>
                                                    )}
                                                    {vc.signatureValid !== undefined && (
                                                        <span className={`badge ${vc.signatureValid
                                                            ? 'badge-success'
                                                            : 'badge-warning'
                                                            }`}>
                                                            {vc.signatureValid ? (
                                                                <>
                                                                    <Shield className="w-3 h-3 mr-1" />
                                                                    Signed
                                                                </>
                                                            ) : (
                                                                <>
                                                                    <AlertCircle className="w-3 h-3 mr-1" />
                                                                    Invalid Sig
                                                                </>
                                                            )}
                                                        </span>
                                                    )}
                                                    <span className="text-sm text-base-content/70">
                                                        Index: {vc.index}
                                                    </span>
                                                </div>

                                                <div className="mt-2 grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3">
                                                    <div>
                                                        <dt className="text-xs font-semibold text-gray-700">Issuer</dt>
                                                        <dd className="text-sm text-gray-900 font-mono">
                                                            {formatAddress(vc.issuer)}
                                                        </dd>
                                                    </div>
                                                    <div>
                                                        <dt className="text-xs font-semibold text-gray-700">Issued At</dt>
                                                        <dd className="text-sm text-gray-900">
                                                            {vc.issuedAt ? new Date(vc.issuedAt).toLocaleDateString() : 'N/A'}
                                                        </dd>
                                                    </div>
                                                    <div>
                                                        <dt className="text-xs font-semibold text-gray-700">Expiration</dt>
                                                        <dd className="text-sm text-gray-900">
                                                            {vc.expirationDate 
                                                                ? new Date(vc.expirationDate).toLocaleDateString()
                                                                : 'Never'
                                                            }
                                                        </dd>
                                                    </div>
                                                    <div>
                                                        <dt className="text-xs font-semibold text-gray-700">Hash</dt>
                                                        <dd className="text-sm text-gray-900 font-mono break-all">
                                                            <div className="flex items-center gap-2">
                                                                <span className="truncate">
                                                                    {vc.hashCredential ? vc.hashCredential : 'N/A'}
                                                                </span>
                                                                {vc.hashCredential && (
                                                                    <button
                                                                        type="button"
                                                                        onClick={() => handleCopyToClipboard(vc.hashCredential, 'Hash copied')}
                                                                        className="inline-flex items-center justify-center p-1 rounded hover:bg-gray-100 transition-colors"
                                                                        title="Copy hash"
                                                                    >
                                                                        <Copy className="w-4 h-4 text-gray-600" />
                                                                    </button>
                                                                )}
                                                            </div>
                                                        </dd>
                                                    </div>
                                                </div>
                                                {vc.verified && (
                                                    <div className="mt-2 grid grid-cols-1 sm:grid-cols-2 gap-3">
                                                        <div>
                                                            <dt className="text-xs font-semibold text-gray-700">Verified By</dt>
                                                            <dd className="text-sm text-gray-900 font-mono">
                                                                {vc.verifier ? formatAddress(vc.verifier) : 'N/A'}
                                                            </dd>
                                                        </div>
                                                        <div>
                                                            <dt className="text-xs font-semibold text-gray-700">Verified At</dt>
                                                            <dd className="text-sm text-gray-900">
                                                                {vc.verifiedAt ? new Date(vc.verifiedAt).toLocaleDateString() : 'N/A'}
                                                            </dd>
                                                        </div>
                                                    </div>
                                                )}
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
                                                {!vc.verified && vc.valid && (
                                                    <button
                                                        onClick={() => {
                                                            setVerificationRequestData({
                                                                vcIndex: vc.index.toString(),
                                                                targetVerifier: '',
                                                                metadataUri: ''
                                                            });
                                                            setShowVerificationRequestForm(true);
                                                        }}
                                                        className="btn btn-ghost btn-sm text-base-content/60 hover:text-blue-600"
                                                        title="Request Verification"
                                                    >
                                                        <Send className="h-4 w-4" />
                                                    </button>
                                                )}
                                                {isVerifier && !vc.verified && vc.valid && (
                                                    <button
                                                        onClick={() => handleVerifyCredential(vc.index)}
                                                        className="btn btn-ghost btn-sm text-base-content/60 hover:text-green-600"
                                                        title="Verify Credential"
                                                    >
                                                        <BadgeCheck className="h-4 w-4" />
                                                    </button>
                                                )}
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
            {showIssueForm && (
                <div
                    className="modal"
                    onClick={(event) => {
                        if (event.target === event.currentTarget) {
                            resetIssueForm();
                            setShowIssueForm(false);
                        }
                    }}
                >
                    <div className="modal-content max-w-2xl relative">
                        <div className="flex items-start justify-between mb-4">
                            <div>
                                <h3 className="text-responsive-lg font-bold text-gray-900">Issue New VC</h3>
                                <p className="text-sm text-gray-600 mt-1">
                                    Provide credential metadata using friendly fields. Values are signed and stored in the VC document.
                                </p>
                            </div>
                            <button
                                type="button"
                                onClick={() => {
                                    resetIssueForm();
                                    setShowIssueForm(false);
                                }}
                                className="text-gray-400 hover:text-gray-600 transition-colors"
                                aria-label="Close"
                            >
                                <XCircle className="w-5 h-5" />
                            </button>
                        </div>

                        <form onSubmit={handleIssueVC} className="space-responsive-y">
                            <div>
                                    <label htmlFor="vcType" className="form-label">
                                        VC Type
                                    </label>
                                    <select
                                        id="vcType"
                                        value={formData.vcType}
                                        onChange={(e) => {
                                            const value = e.target.value;
                                            setFormData({ ...formData, vcType: value });
                                            // Prefill claims based on template
                                            const templates = {
                                                Credential: [{ key: 'name', value: '' }],
                                                IdentityCredential: [
                                                    { key: 'fullName', value: '' },
                                                    { key: 'nationalId', value: '' },
                                                    { key: 'dob', value: '' },
                                                    { key: 'issuerName', value: '' }
                                                ],
                                                PassportCredential: [
                                                    { key: 'fullName', value: '' },
                                                    { key: 'passportNumber', value: '' },
                                                    { key: 'nationality', value: '' },
                                                    { key: 'dateOfIssue', value: '' }
                                                ],
                                                EmployeeCredential: [
                                                    { key: 'employeeName', value: '' },
                                                    { key: 'employeeId', value: '' },
                                                    { key: 'department', value: '' },
                                                    { key: 'position', value: '' }
                                                ],
                                                EducationalCredential: [
                                                    { key: 'studentName', value: '' },
                                                    { key: 'degree', value: '' },
                                                    { key: 'institution', value: '' },
                                                    { key: 'graduationDate', value: '' }
                                                ]
                                            };
                                            setClaimsFields(templates[value] || [{ key: 'name', value: '' }]);
                                        }}
                                        className="form-input"
                                    >
                                        <option value="Credential">Generic Credential</option>
                                        <option value="IdentityCredential">Identity Credential (CCCD)</option>
                                        <option value="PassportCredential">Passport Credential</option>
                                        <option value="EmployeeCredential">Employee Credential</option>
                                        <option value="EducationalCredential">Educational Credential</option>
                                    </select>
                                <p className="mt-1 text-xs text-gray-500">
                                    Type of credential (e.g., EducationalCredential, IdentityCredential)
                                </p>
                            </div>

                            <div>
                                <div className="flex items-center justify-between mb-2">
                                    <label className="form-label mb-0">
                                        Credential Claims
                                    </label>
                                    <button
                                        type="button"
                                        onClick={handleAddClaimField}
                                        className="btn-ghost btn-sm inline-flex items-center gap-1"
                                    >
                                        <Plus className="w-4 h-4" />
                                        Add claim
                                    </button>
                                </div>
                                <div className="space-y-3">
                                    {claimsFields.map((field, index) => (
                                        <div
                                            key={`claim-${index}`}
                                            className="grid grid-cols-1 sm:grid-cols-[1fr_1fr_auto] gap-3 items-center"
                                        >
                                            <input
                                                type="text"
                                                value={field.key}
                                                onChange={(e) => handleClaimFieldChange(index, 'key', e.target.value)}
                                                className="form-input"
                                                placeholder="Claim key (e.g., name, degree)"
                                            />
                                            <input
                                                type="text"
                                                value={field.value}
                                                onChange={(e) => handleClaimFieldChange(index, 'value', e.target.value)}
                                                className="form-input"
                                                placeholder="Claim value"
                                            />
                                            <button
                                                type="button"
                                                onClick={() => handleRemoveClaimField(index)}
                                                className="btn-ghost text-error px-3 py-2 rounded-md hover:bg-error/10 disabled:opacity-50 disabled:cursor-not-allowed"
                                                aria-label="Remove claim"
                                                disabled={claimsFields.length <= 1}
                                            >
                                                <Trash2 className="w-4 h-4" />
                                            </button>
                                        </div>
                                    ))}
                                </div>
                                <p className="mt-1 text-xs text-gray-500">
                                    Define the attributes that will appear inside the credential subject. Add more rows as needed.
                                </p>
                            </div>

                            <div>
                                <label htmlFor="vcNotes" className="form-label">
                                    Additional Notes (optional)
                                </label>
                                <textarea
                                    id="vcNotes"
                                    rows={3}
                                    value={formData.notes}
                                    onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
                                    className="form-input"
                                    placeholder="Additional details that will be included as a notes field"
                                />
                            </div>

                            <div>
                                <label htmlFor="expirationDate" className="form-label">
                                    Expiration Date (Optional)
                                </label>
                                <input
                                    type="datetime-local"
                                    id="expirationDate"
                                    value={formData.expirationDate}
                                    onChange={(e) => setFormData({ ...formData, expirationDate: e.target.value })}
                                    className="form-input"
                                    min={new Date().toISOString().slice(0, 16)}
                                />
                                <p className="mt-1 text-xs text-gray-500">
                                    Leave empty for credentials that never expire
                                </p>
                            </div>

                            <div className="flex justify-end gap-responsive-sm pt-4">
                                <button
                                    type="button"
                                    onClick={() => {
                                        resetIssueForm();
                                        setShowIssueForm(false);
                                    }}
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
            )}

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
                    <div
                        className="modal"
                        onClick={(event) => {
                            if (event.target === event.currentTarget) {
                                setShowQRDisplay(false);
                            }
                        }}
                    >
                        <div className="modal-content-responsive max-w-md relative">
                            <button
                                type="button"
                                onClick={() => setShowQRDisplay(false)}
                                className="absolute top-5 right-0 p-2 rounded-full hover:bg-gray-100 transition-colors"
                                aria-label="Close"
                            >
                                <XCircle className="h-5 w-5 text-gray-500" />
                            </button>
                            <div className="mt-5">
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

            {/* Verification Request Form Modal */}
            {
                showVerificationRequestForm && (
                    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
                        <div className="bg-white rounded-lg shadow-xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
                            <div className="px-6 py-4 border-b border-gray-200 flex items-center justify-between">
                                <h2 className="text-lg font-bold text-gray-900">Request Verification</h2>
                                <button
                                    onClick={() => {
                                        setShowVerificationRequestForm(false);
                                        setVerificationRequestData({ vcIndex: '', targetVerifier: '', metadataUri: '' });
                                    }}
                                    className="text-gray-400 hover:text-gray-600"
                                >
                                    <X className="h-5 w-5" />
                                </button>
                            </div>
                            <form onSubmit={handleRequestVerification} className="p-6 space-y-4">
                                <div>
                                    <label htmlFor="requestVcIndex" className="form-label">
                                        VC Index *
                                    </label>
                                    <input
                                        type="number"
                                        id="requestVcIndex"
                                        value={verificationRequestData.vcIndex}
                                        onChange={(e) => setVerificationRequestData({ ...verificationRequestData, vcIndex: e.target.value })}
                                        className="form-input"
                                        placeholder="Enter VC index"
                                        min="0"
                                        required
                                    />
                                </div>
                                <div>
                                    <label htmlFor="targetVerifier" className="form-label">
                                        Target Verifier (Optional)
                                    </label>
                                    <input
                                        type="text"
                                        id="targetVerifier"
                                        value={verificationRequestData.targetVerifier}
                                        onChange={(e) => setVerificationRequestData({ ...verificationRequestData, targetVerifier: e.target.value })}
                                        className="form-input"
                                        placeholder="Leave empty to allow any trusted verifier"
                                    />
                                    <p className="mt-1 text-xs text-gray-500">
                                        Leave empty to allow any trusted verifier to verify this credential
                                    </p>
                                </div>
                                <div>
                                    <label htmlFor="metadataUri" className="form-label">
                                        Metadata URI (IPFS) *
                                    </label>
                                    <input
                                        type="text"
                                        id="metadataUri"
                                        value={verificationRequestData.metadataUri}
                                        onChange={(e) => setVerificationRequestData({ ...verificationRequestData, metadataUri: e.target.value })}
                                        className="form-input"
                                        placeholder="ipfs://Qm..."
                                        required
                                    />
                                    <p className="mt-1 text-xs text-gray-500">
                                        IPFS URI containing metadata/files/links for verification
                                    </p>
                                </div>
                                <div className="flex justify-end space-x-3 pt-4">
                                    <button
                                        type="button"
                                        onClick={() => {
                                            setShowVerificationRequestForm(false);
                                            setVerificationRequestData({ vcIndex: '', targetVerifier: '', metadataUri: '' });
                                        }}
                                        className="btn btn-outline"
                                    >
                                        Cancel
                                    </button>
                                    <button
                                        type="submit"
                                        disabled={loading}
                                        className="btn btn-primary"
                                    >
                                        {loading ? 'Requesting...' : 'Request Verification'}
                                        <Send className="h-4 w-4 ml-2" />
                                    </button>
                                </div>
                            </form>
                        </div>
                    </div>
                )
            }

            {/* Admin Panel Modal */}
            {
                showAdminPanel && (
                    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
                        <div className="bg-white rounded-lg shadow-xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
                            <div className="px-6 py-4 border-b border-gray-200 flex items-center justify-between">
                                <h2 className="text-lg font-bold text-gray-900">Admin Panel - Manage Trusted Verifiers</h2>
                                <button
                                    onClick={() => {
                                        setShowAdminPanel(false);
                                        setAdminData({ verifierAddress: '', allowed: true });
                                    }}
                                    className="text-gray-400 hover:text-gray-600"
                                >
                                    <X className="h-5 w-5" />
                                </button>
                            </div>
                            <form onSubmit={handleSetTrustedVerifier} className="p-6 space-y-4">
                                <div>
                                    <label htmlFor="verifierAddress" className="form-label">
                                        Verifier Address *
                                    </label>
                                    <input
                                        type="text"
                                        id="verifierAddress"
                                        value={adminData.verifierAddress}
                                        onChange={(e) => setAdminData({ ...adminData, verifierAddress: e.target.value })}
                                        className="form-input"
                                        placeholder="0x..."
                                        required
                                    />
                                </div>
                                <div>
                                    <label className="form-label">Action</label>
                                    <div className="flex space-x-4">
                                        <label className="flex items-center">
                                            <input
                                                type="radio"
                                                checked={adminData.allowed}
                                                onChange={() => setAdminData({ ...adminData, allowed: true })}
                                                className="mr-2"
                                            />
                                            Add/Enable Verifier
                                        </label>
                                        <label className="flex items-center">
                                            <input
                                                type="radio"
                                                checked={!adminData.allowed}
                                                onChange={() => setAdminData({ ...adminData, allowed: false })}
                                                className="mr-2"
                                            />
                                            Remove/Disable Verifier
                                        </label>
                                    </div>
                                </div>
                                <div className="flex justify-end space-x-3 pt-4">
                                    <button
                                        type="button"
                                        onClick={() => {
                                            setShowAdminPanel(false);
                                            setAdminData({ verifierAddress: '', allowed: true });
                                        }}
                                        className="btn btn-outline"
                                    >
                                        Cancel
                                    </button>
                                    <button
                                        type="submit"
                                        disabled={loading}
                                        className="btn btn-primary"
                                    >
                                        {loading ? 'Processing...' : adminData.allowed ? 'Add Verifier' : 'Remove Verifier'}
                                        <Settings className="h-4 w-4 ml-2" />
                                    </button>
                                </div>
                            </form>
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
