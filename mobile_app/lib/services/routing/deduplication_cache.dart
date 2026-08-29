import 'dart:collection';
import '../../core/constants/app_constants.dart';

class DeduplicationCache {
  final LinkedHashMap<String, DateTime> _cache = LinkedHashMap();

  /// Check if packet has already been seen; if not, add to cache
  bool isDuplicate(String packetId) {
    _evictExpired();

    if (_cache.containsKey(packetId)) {
      return true; // Duplicate! Drop packet to prevent loops
    }

    _cache[packetId] = DateTime.now();

    // Maintain max size
    if (_cache.length > AppConstants.dedupeCacheMaxEntries) {
      _cache.remove(_cache.keys.first);
    }

    return false;
  }

  void _evictExpired() {
    final now = DateTime.now();
    _cache.removeWhere((key, timestamp) => now.difference(timestamp) > AppConstants.dedupeCacheTtl);
  }

  int get cachedCount => _cache.length;

  void clear() => _cache.clear();
}
