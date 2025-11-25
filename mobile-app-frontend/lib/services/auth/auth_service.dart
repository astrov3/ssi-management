import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();
  static final _localAuth = LocalAuthentication();
  
  static const String _passwordHashKey = 'password_hash';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _hasStoredCredentialsKey = 'has_stored_credentials';

  /// Check if biometric authentication is available on the device
  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable || isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Check if user has stored credentials (wallet)
  Future<bool> hasStoredCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_hasStoredCredentialsKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Check if biometric authentication is enabled
  Future<bool> isBiometricEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_biometricEnabledKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Set up password authentication
  Future<void> setupPassword(String password) async {
    try {
      final hash = _hashPassword(password);
      await _storage.write(key: _passwordHashKey, value: hash);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasStoredCredentialsKey, true);
    } catch (e) {
      throw Exception('Failed to set up password: $e');
    }
  }

  /// Verify password
  Future<bool> verifyPassword(String password) async {
    try {
      final storedHash = await _storage.read(key: _passwordHashKey);
      if (storedHash == null) return false;
      
      final inputHash = _hashPassword(password);
      return storedHash == inputHash;
    } catch (e) {
      return false;
    }
  }

  /// Enable biometric authentication
  Future<void> enableBiometric() async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        throw Exception('Biometric authentication is not available on this device');
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_biometricEnabledKey, true);
    } catch (e) {
      throw Exception('Failed to enable biometric: $e');
    }
  }

  /// Disable biometric authentication
  Future<void> disableBiometric() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_biometricEnabledKey, false);
    } catch (e) {
      throw Exception('Failed to disable biometric: $e');
    }
  }

  /// Authenticate using biometric
  Future<bool> authenticateWithBiometric() async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        return false;
      }

      final isEnabled = await isBiometricEnabled();
      if (!isEnabled) {
        return false;
      }

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access your wallet',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      return didAuthenticate;
    } catch (e) {
      return false;
    }
  }

  /// Authenticate using password
  Future<bool> authenticateWithPassword(String password) async {
    return await verifyPassword(password);
  }

  /// Clear all authentication data (for logout)
  Future<void> clearAuthData() async {
    try {
      await _storage.delete(key: _passwordHashKey);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_biometricEnabledKey);
      await prefs.remove(_hasStoredCredentialsKey);
    } catch (e) {
      // Ignore errors during cleanup
    }
  }

  /// Hash password using SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}

