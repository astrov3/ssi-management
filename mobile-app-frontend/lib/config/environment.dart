// ignore_for_file: constant_identifier_names

class Environment {
  // Defaults (used as fallbacks when .env is missing values)
  static const String CONTRACT_ADDRESS = '0x98e6c0Cbd5409e630D759F02ADfc8a9827E2D9ea';
  static const String SEPOLIA_RPC_URL = 'https://sepolia.infura.io/v3/0434eceeae73452a806d7f2669a1f6e1';
  static const int SEPOLIA_CHAIN_ID = 11155111;
  static const String SEPOLIA_CHAIN_NAME = 'Sepolia Testnet';
  static const String SEPOLIA_CHAIN_EIP155 = 'eip155:11155111';
  static const String SEPOLIA_EXPLORER_URL = 'https://sepolia.etherscan.io';
  static const String ETHEREUM_MAINNET_EIP155 = 'eip155:1';
  static const String WALLETCONNECT_PROJECT_ID_DEFAULT = '4343ecc74a801058250d1bd2dfbf8488';
  static const String VITE_PINATA_PROJECT_ID='0c8300f2fe13f80bc87f';
  static const String VITE_PINATA_PROJECT_SECRET='7cebeef0e9f10c0ad61399b48e0c199e3e89e687f17e359221c7082f77116d66';
  static const String VITE_PINATA_PROJECT_JWT='eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySW5mb3JtYXRpb24iOnsiaWQiOiJhZjkxNDRhZS02MDQyLTRiMWUtODQxNC0yZGVmZDFlZWIzNWEiLCJlbWFpbCI6InNvbm5nb2RldkBnbWFpbC5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwicGluX3BvbGljeSI6eyJyZWdpb25zIjpbeyJkZXNpcmVkUmVwbGljYXRpb25Db3VudCI6MSwiaWQiOiJGUkExIn0seyJkZXNpcmVkUmVwbGljYXRpb25Db3VudCI6MSwiaWQiOiJOWUMxIn1dLCJ2ZXJzaW9uIjoxfSwibWZhX2VuYWJsZWQiOmZhbHNlLCJzdGF0dXMiOiJBQ1RJVkUifSwiYXV0aGVudGljYXRpb25UeXBlIjoic2NvcGVkS2V5Iiwic2NvcGVkS2V5S2V5IjoiMGM4MzAwZjJmZTEzZjgwYmM4N2YiLCJzY29wZWRLZXlTZWNyZXQiOiI3Y2ViZWVmMGU5ZjEwYzBhZDYxMzk5YjQ4ZTBjMTk5ZTNlODllNjg3ZjE3ZTM1OTIyMWM3MDgyZjc3MTE2ZDY2IiwiZXhwIjoxNzkxOTkxNzk5fQ.SK0XfuaO8gaEAVOfTAWGhhak7_oVdlYx9McL5pXmFpM';

  static bool get isProduction => const bool.fromEnvironment('dart.vm.product');

  static String get rpcUrl {
    return SEPOLIA_RPC_URL;
  }

  static String get contractAddress {
    return CONTRACT_ADDRESS;
  }

  static int get chainId {
    return SEPOLIA_CHAIN_ID;
  }

  static String get walletConnectProjectId {
    return WALLETCONNECT_PROJECT_ID_DEFAULT;
  }

  static String get pinataProjectId {
    return VITE_PINATA_PROJECT_ID;
  }

  static String get pinataProjectSecret {
    return VITE_PINATA_PROJECT_SECRET;
  }

  static String get pinataProjectJwt {
    return VITE_PINATA_PROJECT_JWT;
  }

  // Sepolia chain configuration (for development)
  static String get sepoliaChainEip155 {
    final chainId = Environment.chainId;
    return 'eip155:$chainId';
  }

  static String get sepoliaChainIdHex {
    final chainId = Environment.chainId;
    return '0x${chainId.toRadixString(16)}';
  }

  static String get sepoliaChainName {
    return SEPOLIA_CHAIN_NAME;
  }

  static String get sepoliaExplorerUrl {
    return SEPOLIA_EXPLORER_URL;
  }

  // Ethereum mainnet (fallback chain)
  static String get ethereumMainnetEip155 {
    return ETHEREUM_MAINNET_EIP155;
  }
}