import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// AI-powered user interest tracker.
/// Tracks detailed user behavior: searches, product views, saves, bookings,
/// price preferences, keywords, colors, and styles to build a smart
/// recommendation profile — similar to Facebook/TikTok algorithms.
class UserInterestTracker {
  static const String _searchKey = 'vera_ai_search_history';
  static const String _categoryKey = 'vera_ai_category_views';
  static const String _productViewsKey = 'vera_ai_product_views';
  static const String _savedProductsKey = 'vera_ai_saved_products';
  static const String _bookedProductsKey = 'vera_ai_booked_products';
  static const String _keywordsKey = 'vera_ai_keywords';
  static const String _priceRangesKey = 'vera_ai_price_ranges';
  static const String _interestsKey = 'vera_ai_interests';

  static final UserInterestTracker instance = UserInterestTracker._();
  UserInterestTracker._();

  List<String> _searchHistory = [];
  Map<String, int> _categoryViews = {};
  List<Map<String, dynamic>> _productViews = [];
  List<String> _savedProducts = [];
  List<String> _bookedProducts = [];
  Map<String, int> _keywords = {};
  Map<String, List<double>> _priceRanges = {};
  Map<String, double> _interests = {};

  // Arabic & English common stop words to filter out
  static const Set<String> _stopWords = {
    'من', 'في', 'على', 'هذا', 'هذه', 'التي', 'الذي', 'عن', 'مع', 'أن', 'لا', 'ما', 'كيف', 'وين', 'كم', 'ليش', '咦', '的', '了',
    'the', 'a', 'an', 'is', 'are', 'was', 'were', 'be', 'been', 'being',
    'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'could',
    'should', 'may', 'might', 'shall', 'can', 'need', 'dare', 'ought',
    'to', 'of', 'in', 'for', 'on', 'with', 'at', 'by', 'from', 'as',
    'into', 'through', 'during', 'before', 'after', 'above', 'below',
    'between', 'out', 'off', 'over', 'under', 'again', 'further', 'then',
    'once', 'here', 'there', 'when', 'where', 'why', 'how', 'all', 'both',
    'each', 'few', 'more', 'most', 'other', 'some', 'such', 'no', 'nor',
    'not', 'only', 'own', 'same', 'so', 'than', 'too', 'very', 'just',
    'and', 'but', 'or', 'if', 'because', 'that', 'this', 'these', 'those',
  };

  List<String> get searchHistory => List.unmodifiable(_searchHistory);
  Map<String, int> get keywords => Map.unmodifiable(_keywords);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _searchHistory = prefs.getStringList(_searchKey) ?? [];
    _savedProducts = prefs.getStringList(_savedProductsKey) ?? [];
    _bookedProducts = prefs.getStringList(_bookedProductsKey) ?? [];
    final catJson = prefs.getString(_categoryKey);
    if (catJson != null) {
      try { _categoryViews = Map<String, int>.from(jsonDecode(catJson)); } catch (_) {}
    }
    final viewsJson = prefs.getString(_productViewsKey);
    if (viewsJson != null) {
      try { _productViews = List<Map<String, dynamic>>.from(jsonDecode(viewsJson)); } catch (_) {}
    }
    final kwJson = prefs.getString(_keywordsKey);
    if (kwJson != null) {
      try { _keywords = Map<String, int>.from(jsonDecode(kwJson)); } catch (_) {}
    }
    final priceJson = prefs.getString(_priceRangesKey);
    if (priceJson != null) {
      try {
        final m = jsonDecode(priceJson) as Map<String, dynamic>;
        _priceRanges = m.map((k, v) => MapEntry(k, List<double>.from(v)));
      } catch (_) {}
    }
    final intJson = prefs.getString(_interestsKey);
    if (intJson != null) {
      try { _interests = Map<String, double>.from(jsonDecode(intJson)); } catch (_) {}
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_searchKey, _searchHistory);
    await prefs.setStringList(_savedProductsKey, _savedProducts);
    await prefs.setStringList(_bookedProductsKey, _bookedProducts);
    await prefs.setString(_categoryKey, jsonEncode(_categoryViews));
    await prefs.setString(_productViewsKey, jsonEncode(_productViews));
    await prefs.setString(_keywordsKey, jsonEncode(_keywords));
    await prefs.setString(_priceRangesKey, jsonEncode(_priceRanges));
    await prefs.setString(_interestsKey, jsonEncode(_interests));
  }

  // ─── Record Events ────────────────────────────────────────────────────────

  Future<void> recordSearch(String query) async {
    if (query.trim().isEmpty) return;
    final q = query.trim().toLowerCase();
    _searchHistory.remove(q);
    _searchHistory.insert(0, q);
    if (_searchHistory.length > 50) _searchHistory = _searchHistory.sublist(0, 50);
    _extractKeywords(q);
    _boostInterests(q);
    await _save();
  }

  Future<void> recordCategoryView(String category) async {
    if (category.trim().isEmpty) return;
    final c = category.trim().toLowerCase();
    _categoryViews[c] = (_categoryViews[c] ?? 0) + 1;
    _interests[c] = (_interests[c] ?? 0) + 1.0;
    await _save();
  }

  Future<void> recordProductView(Map<String, dynamic> product) async {
    final entry = {
      'title': product['title']?.toString() ?? product['name']?.toString() ?? '',
      'category': product['category']?.toString() ?? product['categorySlug']?.toString() ?? '',
      'price': product['priceNumeric'] ?? product['price'],
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    _productViews.insert(0, entry);
    if (_productViews.length > 100) _productViews = _productViews.sublist(0, 100);
    final title = entry['title']?.toString().toLowerCase() ?? '';
    _extractKeywords(title);
    final cat = entry['category']?.toString().toLowerCase() ?? '';
    if (cat.isNotEmpty) _interests[cat] = (_interests[cat] ?? 0) + 0.5;
    final price = (entry['price'] as num?)?.toDouble();
    if (price != null && price > 0) _recordPriceRange(cat, price);
    await _save();
  }

  Future<void> recordProductSave(String productId) async {
    if (!_savedProducts.contains(productId)) {
      _savedProducts.insert(0, productId);
      if (_savedProducts.length > 50) _savedProducts = _savedProducts.sublist(0, 50);
      await _save();
    }
  }

  Future<void> recordProductBooking(String productId) async {
    if (!_bookedProducts.contains(productId)) {
      _bookedProducts.insert(0, productId);
      if (_bookedProducts.length > 50) _bookedProducts = _bookedProducts.sublist(0, 50);
      await _save();
    }
  }

  // ─── Keyword Extraction ───────────────────────────────────────────────────

  void _extractKeywords(String text) {
    final words = text.split(RegExp(r'[\s,.\-!?؟]+'));
    for (final w in words) {
      final word = w.trim();
      if (word.length < 2 || _stopWords.contains(word)) continue;
      _keywords[word] = (_keywords[word] ?? 0) + 1;
    }
    if (_keywords.length > 200) {
      final sorted = _keywords.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      _keywords = Map.fromEntries(sorted.take(100));
    }
  }

  void _boostInterests(String query) {
    final arabicFashion = {'فستان', 'فساتين', 'حجاب', 'عباية', 'نيود', 'أزياء', 'ملابس', 'تنورة', 'بلوزة', ';tops', 'heels'};
    final arabicHome = {'عقار', 'شقة', 'فيلا', 'بنتهاوس', 'بقرشية', 'ácre'};
    final englishFashion = {'dress', 'fashion', 'clothing', 'shoes', 'bag', 'women', 'luxury', 'heels', 'gown'};
    final englishTech = {'phone', 'laptop', 'computer', 'tablet', 'airpods'};

    final q = query.toLowerCase();
    if (arabicFashion.any(q.contains) || englishFashion.any(q.contains)) {
      _interests['fashion'] = (_interests['fashion'] ?? 0) + 2.0;
    }
    if (arabicHome.any(q.contains)) {
      _interests['real-estate'] = (_interests['real-estate'] ?? 0) + 2.0;
    }
    if (englishTech.any(q.contains)) {
      _interests['fashion'] = (_interests['fashion'] ?? 0) + 1.0;
    }
  }

  void _recordPriceRange(String category, double price) {
    final key = category.isNotEmpty ? category : 'general';
    _priceRanges[key] ??= [];
    _priceRanges[key]!.add(price);
    if (_priceRanges[key]!.length > 20) {
      _priceRanges[key] = _priceRanges[key]!.sublist(_priceRanges[key]!.length - 20);
    }
  }

  // ─── Recommendation Logic ─────────────────────────────────────────────────

  /// Returns top keywords with their weights.
  List<MapEntry<String, int>> topKeywords({int limit = 20}) {
    final sorted = _keywords.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).toList();
  }

  /// Returns the top N most-viewed category slugs.
  List<String> topCategories({int limit = 5}) {
    final sorted = _categoryViews.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).map((e) => e.key).toList();
  }

  /// Returns the user's interest scores.
  Map<String, double> get interestScores {
    final sorted = _interests.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted.take(10));
  }

  /// Returns preferred price range for a category.
  ({double min, double max, double avg})? priceRangeFor(String category) {
    final prices = _priceRanges[category] ?? _priceRanges['general'];
    if (prices == null || prices.isEmpty) return null;
    final sorted = prices..sort();
    return (min: sorted.first, max: sorted.last, avg: sorted.reduce((a, b) => a + b) / sorted.length);
  }

  /// Smart relevance scoring — returns a score from 0 to 100.
  /// Higher score = more relevant to the user's interests.
  double scoreRelevance(Map<String, dynamic> service) {
    double score = 0;
    final title = (service['title']?.toString() ?? service['name']?.toString() ?? '').toLowerCase();
    final cat = (service['category']?.toString() ?? service['categorySlug']?.toString() ?? '').toLowerCase();
    final price = (service['priceNumeric'] as num?)?.toDouble() ?? (double.tryParse(service['price']?.toString() ?? '') ?? 0);

    // 1. Category match (up to 30 points)
    for (final entry in _interests.entries) {
      if (cat.contains(entry.key) || entry.key.contains(cat)) {
        score += (entry.value * 5).clamp(0, 30);
        break;
      }
    }

    // 2. Keyword match in title (up to 40 points)
    int matchedKeywords = 0;
    for (final kw in _keywords.entries) {
      if (title.contains(kw.key) || kw.key.contains(title)) {
        score += (kw.value * 2).clamp(0, 8);
        matchedKeywords++;
      }
    }
    score = score.clamp(0, 40) + (matchedKeywords > 0 ? 10 : 0);

    // 3. Price range match (up to 15 points)
    if (price > 0) {
      final range = priceRangeFor(cat);
      if (range != null) {
        if (price >= range.min * 0.5 && price <= range.max * 2) {
          score += 15;
        } else if (price >= range.min && price <= range.max * 1.5) {
          score += 8;
        }
      }
    }

    // 4. View history boost (up to 15 points)
    final views = _productViews.where((v) {
      final vCat = v['category']?.toString().toLowerCase() ?? '';
      return vCat == cat || vCat.contains(cat);
    }).length;
    score += (views * 2).clamp(0, 15);

    return score.clamp(0, 100);
  }

  /// Sorts a list of services by relevance score.
  List<Map<String, dynamic>> rankByRelevance(List<Map<String, dynamic>> services) {
    final scored = services.map((s) => (service: s, score: scoreRelevance(s))).toList();
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.map((e) => e.service).toList();
  }
}
