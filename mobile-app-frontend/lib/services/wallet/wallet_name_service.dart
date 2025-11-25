import 'package:shared_preferences/shared_preferences.dart';

class WalletNameService {
  static const String _prefsKeyPrefix = 'wallet_name_';

  /// Save a name for a wallet address
  Future<void> saveWalletName(String address, String name) async {
    if (name.trim().isEmpty) {
      await deleteWalletName(address);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefsKeyPrefix${address.toLowerCase()}', name.trim());
  }

  /// Get the name for a wallet address
  Future<String?> getWalletName(String address) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_prefsKeyPrefix${address.toLowerCase()}');
  }

  /// Delete the name for a wallet address
  Future<void> deleteWalletName(String address) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefsKeyPrefix${address.toLowerCase()}');
  }

  /// Get display name (returns name if exists, otherwise returns shortened address)
  Future<String> getDisplayName(String address, {int shortenLength = 6}) async {
    final name = await getWalletName(address);
    if (name != null && name.isNotEmpty) {
      return name;
    }
    return _shortenAddress(address, shortenLength);
  }

  /// Get display name synchronously (for immediate use)
  /// Note: This will return shortened address if name is not yet loaded
  String getDisplayNameSync(String address, {int shortenLength = 6}) {
    return _shortenAddress(address, shortenLength);
  }

  String _shortenAddress(String address, int length) {
    if (address.length < length * 2 + 2) return address;
    return '${address.substring(0, length + 2)}...${address.substring(address.length - length)}';
  }

  /// Get all saved wallet names
  Future<Map<String, String>> getAllWalletNames() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith(_prefsKeyPrefix));
    final result = <String, String>{};
    
    for (final key in keys) {
      final address = key.replaceFirst(_prefsKeyPrefix, '');
      final name = prefs.getString(key);
      if (name != null) {
        result[address] = name;
      }
    }
    
    return result;
  }
}

