import 'package:flutter/foundation.dart';

import 'package:ssi_app/services/ipfs/pinata_service.dart';

class CredentialMetadataCache {
  CredentialMetadataCache._internal() : _pinataService = PinataService();

  static final CredentialMetadataCache _instance =
      CredentialMetadataCache._internal();

  factory CredentialMetadataCache() => _instance;

  final PinataService _pinataService;
  final Map<String, _CacheEntry> _cache = {};
  Duration cacheTtl = const Duration(minutes: 5);

  Future<Map<String, dynamic>?> get(String? uri) async {
    if (uri == null || uri.isEmpty) return null;

    final entry = _cache[uri];
    if (entry != null && !_isExpired(entry.timestamp)) {
      return entry.data;
    }

    try {
      final data = await _pinataService.getJSON(uri);
      _cache[uri] = _CacheEntry(data);
      return data;
    } catch (e) {
      debugPrint('[CredentialMetadataCache] Error fetching $uri: $e');
      return null;
    }
  }

  void invalidate(String uri) => _cache.remove(uri);

  void clear() => _cache.clear();

  bool _isExpired(DateTime timestamp) {
    return DateTime.now().difference(timestamp) > cacheTtl;
  }
}

class _CacheEntry {
  _CacheEntry(this.data) : timestamp = DateTime.now();

  final Map<String, dynamic> data;
  final DateTime timestamp;
}

