class CacheEntry<T> {
  final T data;
  final DateTime timestamp;
  final Duration ttl;

  CacheEntry({required this.data, required this.ttl})
    : timestamp = DateTime.now();

  bool get isExpired => DateTime.now().difference(timestamp) > ttl;
}

class CacheService {
  final Map<String, CacheEntry<dynamic>> _cache = {};

  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null || entry.isExpired) {
      _cache.remove(key);
      return null;
    }
    return entry.data as T;
  }

  void set<T>(String key, T data, Duration ttl) {
    _cache[key] = CacheEntry<T>(data: data, ttl: ttl);
  }

  void remove(String key) {
    _cache.remove(key);
  }

  void removeByPrefix(String prefix) {
    _cache.removeWhere((key, _) => key.startsWith(prefix));
  }

  void clear() {
    _cache.clear();
  }
}
