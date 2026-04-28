/// Global cache service to persist data across page navigations
class CacheService {
  static final CacheService _instance = CacheService._internal();

  factory CacheService() {
    return _instance;
  }

  CacheService._internal();

  // Home page cache
  Map<String, dynamic>? _homePageCache;
  DateTime? _homePageCacheTime;

  // Map page cache
  Map<String, dynamic>? _mapPageCache;
  DateTime? _mapPageCacheTime;

  // Cache duration (5 minutes)
  static const Duration cacheDuration = Duration(minutes: 5);

  // Home page cache methods
  void setHomePageCache(Map<String, dynamic> data) {
    _homePageCache = data;
    _homePageCacheTime = DateTime.now();
  }

  Map<String, dynamic>? getHomePageCache() {
    if (_homePageCache == null) return null;
    final elapsed = DateTime.now().difference(_homePageCacheTime ?? DateTime.now());
    if (elapsed > cacheDuration) {
      clearHomePageCache();
      return null;
    }
    return _homePageCache;
  }

  void clearHomePageCache() {
    _homePageCache = null;
    _homePageCacheTime = null;
  }

  bool isHomePageCacheValid() {
    if (_homePageCache == null) return false;
    final elapsed = DateTime.now().difference(_homePageCacheTime ?? DateTime.now());
    return elapsed <= cacheDuration;
  }

  // Map page cache methods
  void setMapPageCache(Map<String, dynamic> data) {
    _mapPageCache = data;
    _mapPageCacheTime = DateTime.now();
  }

  Map<String, dynamic>? getMapPageCache() {
    if (_mapPageCache == null) return null;
    final elapsed = DateTime.now().difference(_mapPageCacheTime ?? DateTime.now());
    if (elapsed > cacheDuration) {
      clearMapPageCache();
      return null;
    }
    return _mapPageCache;
  }

  void clearMapPageCache() {
    _mapPageCache = null;
    _mapPageCacheTime = null;
  }

  bool isMapPageCacheValid() {
    if (_mapPageCache == null) return false;
    final elapsed = DateTime.now().difference(_mapPageCacheTime ?? DateTime.now());
    return elapsed <= cacheDuration;
  }

  // Clear all caches
  void clearAll() {
    clearHomePageCache();
    clearMapPageCache();
  }
}
