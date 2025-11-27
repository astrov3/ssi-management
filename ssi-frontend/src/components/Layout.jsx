import {
    CheckCircle,
    Home,
    Menu,
    Settings,
    Shield,
    User,
    Wallet,
    X
} from 'lucide-react';
import { useState } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { useStore } from '../store/useStore';

const Layout = ({ children }) => {
    const [sidebarOpen, setSidebarOpen] = useState(false);
    const location = useLocation();
    const { account, isConnected, message, walletState } = useStore();

    const navigation = [
        { name: 'Dashboard', href: '/', icon: Home },
        { name: 'DID Management', href: '/did', icon: User },
        { name: 'VC Operations', href: '/vc', icon: Shield },
        { name: 'Settings', href: '/settings', icon: Settings },
    ];

    const isCurrentPath = (path) => {
        if (path === '/') {
            return location.pathname === '/';
        }
        return location.pathname.startsWith(path);
    };

    const displayName = walletState?.displayName ?? account;
    const defaultWalletMessage = account ? `Connected: ${account}` : '';

    return (
        <div className="min-h-screen bg-gray-50">
            {/* Mobile sidebar */}
            <div className={`fixed inset-0 flex z-40 lg:hidden ${sidebarOpen ? '' : 'hidden'}`}>
                <div className="fixed inset-0 bg-gray-600 bg-opacity-75" onClick={() => setSidebarOpen(false)} />
                <div className="relative flex-1 flex flex-col max-w-xs w-full bg-white">
                    <div className="absolute top-0 right-0 -mr-12 pt-2">
                        <button
                            className="ml-1 flex items-center justify-center h-10 w-10 rounded-full focus:outline-none focus:ring-2 focus:ring-inset focus:ring-white"
                            onClick={() => setSidebarOpen(false)}
                        >
                            <X className="h-6 w-6 text-white" />
                        </button>
                    </div>
                    <div className="flex-1 h-0 pt-5 pb-4 overflow-y-auto">
                        <div className="flex-shrink-0 flex items-center px-4">
                            <Shield className="h-8 w-8 text-blue-600" />
                            <span className="ml-2 text-xl font-bold text-gray-900">SSI Manager</span>
                        </div>
                        <nav className="mt-5 px-2 space-y-1">
                            {navigation.map((item) => {
                                const Icon = item.icon;
                                return (
                                    <Link
                                        key={item.name}
                                        to={item.href}
                                        className={`${isCurrentPath(item.href)
                                            ? 'bg-blue-100 text-blue-900'
                                            : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'
                                            } group flex items-center px-2 py-2 text-base font-medium rounded-md`}
                                        onClick={() => setSidebarOpen(false)}
                                    >
                                        <Icon className="mr-4 h-6 w-6" />
                                        {item.name}
                                    </Link>
                                );
                            })}
                        </nav>
                    </div>
                    {/* Wallet status */}
                    <div className="flex-shrink-0 flex border-t border-gray-200 p-4">
                        <div className="flex items-center">
                            <div className="flex-shrink-0">
                                <Wallet className="h-8 w-8 text-gray-400" />
                            </div>
                            <div className="ml-3">
                                <p className="text-sm font-medium text-gray-700">
                                    {isConnected ? 'Connected' : 'Disconnected'}
                                </p>
                                {displayName && (
                                    <p className="text-xs text-gray-500">
                                        {displayName}
                                    </p>
                                )}
                                {account && displayName !== account && (
                                    <p className="text-[11px] text-gray-400">
                                        {account.slice(0, 6)}...{account.slice(-4)}
                                    </p>
                                )}
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            {/* Desktop sidebar */}
            <div className="hidden lg:flex lg:w-64 lg:flex-col lg:fixed lg:inset-y-0">
                <div className="flex-1 flex flex-col min-h-0 border-r border-gray-200 bg-white">
                    <div className="flex-1 flex flex-col pt-5 pb-4 overflow-y-auto">
                        <div className="flex items-center flex-shrink-0 px-4">
                            <Shield className="h-8 w-8 text-blue-600" />
                            <span className="ml-2 text-xl font-bold text-gray-900">SSI Manager</span>
                        </div>
                        <nav className="mt-5 flex-1 px-2 space-y-1">
                            {navigation.map((item) => {
                                const Icon = item.icon;
                                return (
                                    <Link
                                        key={item.name}
                                        to={item.href}
                                        className={`${isCurrentPath(item.href)
                                            ? 'bg-blue-100 text-blue-900'
                                            : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'
                                            } group flex items-center px-2 py-2 text-sm font-medium rounded-md`}
                                    >
                                        <Icon className="mr-3 h-6 w-6" />
                                        {item.name}
                                    </Link>
                                );
                            })}
                        </nav>
                    </div>
                    {/* Wallet status */}
                    <div className="flex-shrink-0 flex border-t border-gray-200 p-4">
                        <div className="flex items-center w-full">
                            <div className="flex-shrink-0">
                                {isConnected ? (
                                    <CheckCircle className="h-8 w-8 text-green-500" />
                                ) : (
                                    <Wallet className="h-8 w-8 text-gray-400" />
                                )}
                            </div>
                            <div className="ml-3 flex-1">
                                <p className="text-sm font-medium text-gray-700">
                                    {isConnected ? 'Connected' : 'Disconnected'}
                                </p>
                                {account && (
                                    <>
                                        <p className="text-xs text-gray-500 break-all">
                                            {displayName || account}
                                        </p>
                                        {displayName && displayName !== account && (
                                            <p className="text-[11px] text-gray-400">
                                                {account.slice(0, 10)}...{account.slice(-6)}
                                            </p>
                                        )}
                                    </>
                                )}
                                {message && message !== defaultWalletMessage && (
                                    <p className="text-xs text-blue-600 mt-1">{message}</p>
                                )}
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            {/* Main content */}
            <div className="lg:pl-64 flex flex-col flex-1">
                {/* Top bar */}
                <div className="sticky top-0 z-10 lg:hidden pl-1 pt-1 sm:pl-3 sm:pt-3 bg-gray-50">
                    <button
                        className="-ml-0.5 -mt-0.5 h-12 w-12 inline-flex items-center justify-center rounded-md text-gray-500 hover:text-gray-900 focus:outline-none focus:ring-2 focus:ring-inset focus:ring-blue-500"
                        onClick={() => setSidebarOpen(true)}
                    >
                        <Menu className="h-6 w-6" />
                    </button>
                </div>

                {/* Page content */}
                <main className="flex-1">
                    <div className="py-4 lg:py-6">
                        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                            {children}
                        </div>
                    </div>
                </main>
            </div>
        </div>
    );
};

export default Layout;
