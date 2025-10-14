import {
    Activity,
    CheckCircle,
    Scan,
    Shield,
    User,
    Wallet
} from 'lucide-react';
import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { useStore } from '../store/useStore';

const Dashboard = () => {
    const {
        account,
        isConnected,
        connectWallet,
        currentOrgID,
        didActive,
        vcLength,
        loading,
        message
    } = useStore();

    const [stats] = useState({
        totalDIDs: 0,
        totalVCs: 0,
        activeDIDs: 0,
        validVCs: 0
    });

    useEffect(() => {
        // Initialize wallet connection if not connected
        if (!isConnected) {
            connectWallet();
        }
    }, [isConnected, connectWallet]);

    const quickActions = [
        {
            title: 'Connect Wallet',
            description: 'Connect your MetaMask wallet',
            icon: Wallet,
            href: '#',
            onClick: connectWallet,
            disabled: isConnected,
            primary: !isConnected
        },
        {
            title: 'Manage DID',
            description: 'Register and manage your Digital Identity',
            icon: User,
            href: '/did',
            disabled: !isConnected
        },
        {
            title: 'VC Operations',
            description: 'Issue, verify, and manage Verifiable Credentials',
            icon: Shield,
            href: '/vc',
            disabled: !isConnected
        },
        {
            title: 'Scan QR Code',
            description: 'Scan QR codes to verify credentials',
            icon: Scan,
            href: '/scanner',
            disabled: !isConnected
        }
    ];

    const StatCard = ({ title, value, icon, color = "blue" }) => {
        const IconComponent = icon;
        return (
            <div className="bg-white overflow-hidden shadow rounded-lg">
                <div className="p-5">
                    <div className="flex items-center">
                        <div className="flex-shrink-0">
                            <IconComponent className={`h-6 w-6 text-${color}-600`} />
                        </div>
                        <div className="ml-5 w-0 flex-1">
                            <dl>
                                <dt className="text-sm font-semibold text-gray-700 truncate">{title}</dt>
                                <dd className="text-lg font-bold text-gray-900">{value}</dd>
                            </dl>
                        </div>
                    </div>
                </div>
            </div>
        );
    };

    return (
        <div className="space-responsive-y">
            {/* Header */}
            <div>
                <h1 className="text-responsive-2xl font-bold text-gray-900">Dashboard</h1>
                <p className="mt-1 text-sm text-gray-700">
                    Manage your Self-Sovereign Identity and Verifiable Credentials
                </p>
            </div>

            {/* Connection Status */}
            {!isConnected && (
                <div className="bg-yellow-50 border border-yellow-200 rounded-md p-4">
                    <div className="flex">
                        <div className="flex-shrink-0">
                            <Wallet className="h-5 w-5" />
                        </div>
                        <div className="ml-3">
                            <h3 className="text-sm font-medium">
                                Wallet Not Connected
                            </h3>
                            <div className="mt-2 text-sm">
                                <p>Please connect your MetaMask wallet to start using the SSI Manager.</p>
                            </div>
                            <div className="mt-4">
                                <button
                                    onClick={connectWallet}
                                    disabled={loading}
                                    className="btn-primary btn-sm"
                                >
                                    {loading ? 'Connecting...' : 'Connect Wallet'}
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            )}

            {/* Connected Status */}
            {isConnected && (
                <div className="bg-green-50 border border-green-200 rounded-md p-4">
                    <div className="flex">
                        <div className="flex-shrink-0">
                            <CheckCircle className="h-5 w-5 text-green-400" />
                        </div>
                        <div className="ml-3">
                            <h3 className="text-sm font-medium text-green-800">
                                Wallet Connected
                            </h3>
                            <div className="mt-2 text-sm text-green-700">
                                <p>Connected as: <code className="bg-green-100 px-1 rounded">{account}</code></p>
                                {message && <p className="mt-1">{message}</p>}
                            </div>
                        </div>
                    </div>
                </div>
            )}

            {/* Stats */}
            <div className="grid-responsive-1 gap-responsive-sm">
                <StatCard
                    title="Total DIDs"
                    value={stats.totalDIDs}
                    icon={User}
                    color="blue"
                />
                <StatCard
                    title="Total VCs"
                    value={stats.totalVCs}
                    icon={Shield}
                    color="green"
                />
                <StatCard
                    title="Active DIDs"
                    value={stats.activeDIDs}
                    icon={Activity}
                    color="purple"
                />
                <StatCard
                    title="Valid VCs"
                    value={stats.validVCs}
                    icon={CheckCircle}
                    color="green"
                />
            </div>

            {/* Quick Actions */}
            <div>
                <h2 className="text-base sm:text-lg font-bold text-gray-900 mb-4">Quick Actions</h2>
                <div className="grid-responsive-1 gap-responsive-sm">
                    {quickActions.map((action, index) => {
                        return (
                            <div
                                key={index}
                                className={`relative rounded-lg border border-gray-300 bg-white px-4 py-4 sm:px-6 sm:py-5 shadow-sm flex items-center space-x-3 hover:border-gray-400 focus-within:ring-2 focus-within:ring-offset-2 ${action.disabled ? 'opacity-50 cursor-not-allowed' : 'cursor-pointer'
                                    } ${action.primary ? 'focus-within:ring-blue-500' : 'focus-within:ring-blue-500'}`}
                            >
                                {action.href !== '#' ? (
                                    <Link
                                        to={action.href}
                                        className="flex-1 min-w-0"
                                        onClick={(e) => action.disabled && e.preventDefault()}
                                    >
                                        <div className="flex items-center space-x-3">
                                            <div className={`flex-shrink-0 p-2 rounded-lg ${action.primary ? 'bg-blue-100' : 'bg-gray-100'
                                                }`}>
                                                <action.icon className={`h-6 w-6 ${action.primary ? 'text-blue-600' : 'text-gray-600'
                                                    }`} />
                                            </div>
                                            <div className="flex-1 min-w-0">
                                                <p className={`text-sm font-medium ${action.primary ? 'text-blue-900' : 'text-gray-900'
                                                    }`}>
                                                    {action.title}
                                                </p>
                                                <p className="text-sm text-gray-500 truncate">
                                                    {action.description}
                                                </p>
                                            </div>
                                        </div>
                                    </Link>
                                ) : (
                                    <button
                                        onClick={action.onClick}
                                        disabled={action.disabled || loading}
                                        className="flex-1 min-w-0 text-left"
                                    >
                                        <div className="flex items-center space-x-3">
                                            <div className={`flex-shrink-0 p-2 rounded-lg ${action.primary ? 'bg-blue-100' : 'bg-gray-100'
                                                }`}>
                                                <action.icon className={`h-6 w-6 ${action.primary ? 'text-blue-600' : 'text-gray-600'
                                                    }`} />
                                            </div>
                                            <div className="flex-1 min-w-0">
                                                <p className={`text-sm font-medium ${action.primary ? 'text-blue-900' : 'text-gray-900'
                                                    }`}>
                                                    {action.title}
                                                </p>
                                                <p className="text-sm text-gray-500 truncate">
                                                    {action.description}
                                                </p>
                                            </div>
                                        </div>
                                    </button>
                                )}
                            </div>
                        );
                    })}
                </div>
            </div>

            {/* Current Status */}
            {isConnected && (currentOrgID || didActive !== null || vcLength > 0) && (
                <div>
                    <h2 className="text-lg font-bold text-gray-900 mb-4">Current Status</h2>
                    <div className="bg-white shadow rounded-lg p-6">
                        <dl className="grid grid-cols-1 gap-x-4 gap-y-6 sm:grid-cols-2">
                            {currentOrgID && (
                                <div>
                                    <dt className="text-sm font-semibold text-gray-700">Current Organization ID</dt>
                                    <dd className="mt-1 text-sm text-gray-900 font-mono bg-gray-50 p-3 rounded">
                                        {currentOrgID}
                                    </dd>
                                </div>
                            )}
                            {didActive !== null && (
                                <div>
                                    <dt className="text-sm font-semibold text-gray-700">DID Status</dt>
                                    <dd className="mt-1 text-sm text-gray-900">
                                        <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${didActive
                                            ? 'bg-green-100 text-green-800'
                                            : 'bg-red-100 text-red-800'
                                            }`}>
                                            {didActive ? 'Active' : 'Inactive'}
                                        </span>
                                    </dd>
                                </div>
                            )}
                            {vcLength > 0 && (
                                <div>
                                    <dt className="text-sm font-semibold text-gray-700">VC Count</dt>
                                    <dd className="mt-1 text-sm font-semibold text-gray-900">{vcLength}</dd>
                                </div>
                            )}
                        </dl>
                    </div>
                </div>
            )}
        </div>
    );
};

export default Dashboard;
