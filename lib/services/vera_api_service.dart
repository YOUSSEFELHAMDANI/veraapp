import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:typed_data';

import '../core/auth_session.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// VÉRA API SERVICE — Complete 57-group Postman Collection Coverage
// Base URL: https://veraapp.app (via VERA_API_BASE_URL env var)
// ═══════════════════════════════════════════════════════════════════════════════

// ─── Helpers ─────────────────────────────────────────────────────────────────

String _titleCase(String input) {
  if (input.isEmpty) return input;
  return input
      .split(' ')
      .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
      .join(' ');
}

/// Safe numeric parser: accepts num or string (e.g. Postgres NUMERIC
/// returned as "120.00") and never throws.
double _toDouble(Object? raw, {double fallback = 0.0}) {
  if (raw == null) return fallback;
  if (raw is num) return raw.toDouble();
  if (raw is String) {
    final t = raw.trim();
    if (t.isEmpty) return fallback;
    return double.tryParse(t) ?? fallback;
  }
  return fallback;
}

// ─── Auth Models ─────────────────────────────────────────────────────────────

class VeraUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String avatarUrl;
  final String city;
  final int ordersCount;
  final int bookingsCount;
  final double walletBalance;
  final int loyaltyPoints;
  final String role; // buyer | provider | admin | staff

  const VeraUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.avatarUrl,
    required this.city,
    this.ordersCount = 0,
    this.bookingsCount = 0,
    this.walletBalance = 0,
    this.loyaltyPoints = 0,
    this.role = 'buyer',
  });

  factory VeraUser.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json['user'] ?? json['profile'] ?? json;
    return VeraUser(
      id: data['id']?.toString() ?? '',
      name: data['name'] ?? data['full_name'] ?? data['username'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? data['mobile'] ?? '',
      avatarUrl:
          data['avatar'] ?? data['avatar_url'] ?? data['profile_image'] ?? '',
      city: data['city'] ?? data['location'] ?? '',
      ordersCount: data['orders_count'] ?? data['total_orders'] ?? 0,
      bookingsCount: data['bookings_count'] ?? data['total_bookings'] ?? 0,
      walletBalance: _toDouble(data['wallet_balance'] ?? data['balance']),
      loyaltyPoints: data['loyalty_points'] ?? data['points'] ?? 0,
      role: data['role'] ?? data['user_type'] ?? 'buyer',
    );
  }

  VeraUser copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    String? city,
    int? ordersCount,
    int? bookingsCount,
    double? walletBalance,
    int? loyaltyPoints,
    String? role,
  }) {
    return VeraUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      city: city ?? this.city,
      ordersCount: ordersCount ?? this.ordersCount,
      bookingsCount: bookingsCount ?? this.bookingsCount,
      walletBalance: walletBalance ?? this.walletBalance,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      role: role ?? this.role,
    );
  }
}

// ─── Banner Model ─────────────────────────────────────────────────────────────

class VeraBanner {
  final String id;
  final String title;
  final String subtitle;
  final String ctaText;
  final String imageUrl;
  final String bgColorHex;
  final String targetRoute;

  const VeraBanner({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.ctaText,
    required this.imageUrl,
    required this.bgColorHex,
    required this.targetRoute,
  });

  factory VeraBanner.fromJson(Map<String, dynamic> json) {
    var img = json['image'] ?? json['image_url'] ?? json['banner_image'] ?? '';
    if (img is String && img.startsWith('/')) img = 'https://veraapp.app$img';
    return VeraBanner(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? json['name'] ?? '',
      subtitle: json['subtitle'] ?? json['description'] ?? '',
      ctaText: json['cta_text'] ?? json['button_text'] ?? 'Explore',
      imageUrl: img,
      bgColorHex: json['bg_color'] ?? json['color'] ?? '#EFA9B8',
      targetRoute:
          json['route'] ??
          json['link'] ??
          json['url'] ??
          json['link_url'] ??
          '',
    );
  }
}

// ─── Category Model ───────────────────────────────────────────────────────────

class VeraCategory {
  final String id;
  final String name;
  final String enName;
  final String imageUrl;
  final String slug;
  final int itemCount;
  final String parentId;

  const VeraCategory({
    required this.id,
    required this.name,
    required this.enName,
    required this.imageUrl,
    required this.slug,
    this.itemCount = 0,
    this.parentId = '',
  });

  factory VeraCategory.fromJson(Map<String, dynamic> json) {
    final rawCount = json['count'] ?? json['items_count'] ?? json['item_count'];
    return VeraCategory(
      id: json['id']?.toString() ?? json['slug'] ?? '',
      name:
          json['label_ar'] ??
          json['label'] ??
          json['name'] ??
          json['title'] ??
          json['slug'] ??
          '',
      enName:
          json['label'] ??
          json['name'] ??
          json['title'] ??
          json['label_ar'] ??
          json['slug'] ??
          '',
      imageUrl:
          json['logo_url'] ??
          json['image'] ??
          json['image_url'] ??
          json['banner'] ??
          '',
      slug: json['slug'] ?? json['key'] ?? json['id']?.toString() ?? '',
      itemCount: rawCount is int ? rawCount : 0,
      parentId: json['parent_id']?.toString() ?? '',
    );
  }
}

// ─── Listing / Service / Product unified model ────────────────────────────────

class VeraListing {
  final String id;
  final String name;
  final String category;
  final String categorySlug;
  final String price;
  final double rating;
  final int reviewCount;
  final int followers;
  final String imageUrl;
  final String location;
  final String type;
  final String listingType;
  final bool isFeatured;
  final bool isVerified;
  final String description;
  final String providerName;
  final String providerAvatar;
  final String providerCity;
  final int bedrooms;
  final int bathrooms;
  final String area;
  final String jobType;
  final String salary;
  final int viewCount;
  final int orderCount;
  final String duration;
  final String badge;

  const VeraListing({
    required this.id,
    required this.name,
    required this.category,
    required this.categorySlug,
    required this.price,
    required this.rating,
    required this.reviewCount,
    this.followers = 0,
    required this.imageUrl,
    required this.location,
    required this.type,
    this.listingType = '',
    this.isFeatured = false,
    this.isVerified = false,
    this.description = '',
    this.providerName = '',
    this.providerAvatar = '',
    this.providerCity = '',
    this.bedrooms = 0,
    this.bathrooms = 0,
    this.area = '',
    this.jobType = '',
    this.salary = '',
    this.viewCount = 0,
    this.orderCount = 0,
    this.duration = '',
    this.badge = '',
  });

  factory VeraListing.fromJson(Map<String, dynamic> json) {
    final categoryValue = json['category'];
    final listingType = (json['listing_type'] ?? json['listingType'] ?? '')
        .toString();
    final String categoryName;
    final String categorySlugValue;
    if (categoryValue is Map<String, dynamic>) {
      categoryName = categoryValue['name']?.toString() ?? '';
      categorySlugValue = categoryValue['slug']?.toString() ?? '';
    } else if (categoryValue != null) {
      categoryName = categoryValue.toString();
      categorySlugValue = categoryValue.toString();
    } else {
      categoryName =
          (json['category_name'] ??
                  json['category_slug'] ??
                  json['subcategory'] ??
                  '')
              .toString();
      categorySlugValue = (json['category_slug'] ?? json['subcategory'] ?? '')
          .toString();
    }
    return VeraListing(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? json['title'] ?? '',
      category: _isPropertyType(listingType) && _isGenericCategory(categoryName)
          ? 'real-estate'
          : categoryName,
      categorySlug:
          _isPropertyType(listingType) && _isGenericCategory(categorySlugValue)
          ? 'real-estate'
          : categorySlugValue,
      price: _parsePrice(json),
      rating: _parseRating(json['rating'] ?? json['average_rating'] ?? 0.0),
      reviewCount:
          (json['reviewCount'] ??
                  json['reviews_count'] ??
                  json['review_count'] ??
                  json['reviews'] ??
                  0)
              .toInt(),
      imageUrl: _parseImage(json),
      location:
          json['location'] ??
          json['provider_city'] ??
          json['city'] ??
          json['address'] ??
          '',
      type: json['listing_type'] ?? json['type'] ?? 'service',
      listingType: listingType.isNotEmpty
          ? listingType
          : (json['type'] ?? '').toString(),
      isFeatured: json['is_featured'] ?? json['featured'] ?? false,
      isVerified:
          json['is_verified'] ??
          json['verified'] ??
          json['provider_verified'] ??
          false,
      description: json['description'] ?? json['details'] ?? '',
      providerName:
          json['providerName'] ??
          json['provider']?['name'] ??
          json['provider_name'] ??
          json['store_name'] ??
          '',
      providerAvatar:
          json['provider_avatar'] ??
          json['providerAvatar'] ??
          json['provider']?['avatar'] ??
          '',
      providerCity: (json['provider_city'] ?? json['city'] ?? '').toString(),
      bedrooms: (json['bedrooms'] ?? json['beds'] ?? 0).toInt(),
      bathrooms: (json['bathrooms'] ?? json['baths'] ?? 0).toInt(),
      area: (json['area'] ?? json['size_sqft'] ?? '').toString(),
      jobType: (json['job_type'] ?? json['employment_type'] ?? '').toString(),
      salary: (json['salary'] ?? '').toString(),
      viewCount: (json['view_count'] ?? json['views'] ?? 0).toInt(),
      orderCount: (json['order_count'] ?? json['orders'] ?? 0).toInt(),
      duration: (json['duration_minutes'] ?? json['duration'] ?? '').toString(),
      badge: (json['badge'] ?? '').toString(),
    );
  }

  /// Builds the flat map shape expected by the legacy detail screens.
  Map<String, dynamic> toCardMap() {
    final sub = category.isNotEmpty ? _titleCase(category) : categorySlug;
    return {
      'id': id,
      'name': name,
      'title': name,
      'category': sub,
      'categorySlug': categorySlug.isNotEmpty ? categorySlug : category,
      'subcategory': sub,
      'location': location,
      'rating': rating,
      'reviews': reviewCount,
      'price': price,
      'image': imageUrl,
      'badge': badge.isNotEmpty ? badge : sub,
      'badgeColor': 0xFFC8A96A,
      'isOpen': true,
      'isSaved': false,
      'waitTime': null,
      'providerType': sub,
      'provider': providerName,
      'providerName': providerName,
      'providerAvatar': providerAvatar,
      'providerVerified': isVerified,
      'description': description,
      'originalPrice': price,
      'type': type,
      'listing_type': listingType.isNotEmpty ? listingType : type,
      'company': providerName,
      'salary': salary.isNotEmpty ? salary : price,
      'logo': imageUrl,
      'jobCategory': sub,
      'brand': providerName,
      'propertyType': sub,
      'beds': bedrooms,
      'baths': bathrooms,
      'area': area,
      'jobType': jobType,
      'viewCount': viewCount,
      'orderCount': orderCount,
    };
  }

  static double _parseRating(Object? raw) {
    if (raw is num) return raw.toDouble();
    if (raw is String) return double.tryParse(raw) ?? 0.0;
    return 0.0;
  }

  static String _parsePrice(Map<String, dynamic> json) {
    final raw = json['price'] ?? json['starting_price'] ?? json['min_price'];
    if (raw == null) return 'Price on request';
    final priceType =
        (json['price_type'] ?? json['price_period'] ?? json['period'] ?? '')
            .toString();
    String periodStr = '';
    if (priceType == 'month') {
      periodStr = '/month';
    } else if (priceType == 'year') {
      periodStr = '/year';
    }
    final numVal = raw is num
        ? raw.toDouble()
        : double.tryParse(raw.toString()) ?? 0;
    final formatted = numVal == numVal.roundToDouble()
        ? numVal.toStringAsFixed(0)
        : numVal.toStringAsFixed(2);
    final withCommas = formatted.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return 'AED $withCommas$periodStr';
  }

  static String _parseImage(Map<String, dynamic> json) {
    if (json['images'] is List && (json['images'] as List).isNotEmpty) {
      final img = (json['images'] as List).first;
      return img is String ? img : img['url'] ?? img['path'] ?? '';
    }
    return json['image'] ??
        json['imageUrl'] ??
        json['image_url'] ??
        json['thumbnail'] ??
        json['cover_image'] ??
        '';
  }

  static bool _isPropertyType(String value) {
    final normalized = value.toLowerCase().replaceAll('_', '-');
    return normalized == 'property' ||
        normalized == 'real-estate' ||
        normalized == 'realestate';
  }

  static bool _isGenericCategory(String value) {
    final normalized = value.toLowerCase().replaceAll('_', '-');
    return normalized.isEmpty ||
        normalized == 'service' ||
        normalized == 'services' ||
        normalized == 'listing';
  }
}

// ─── Provider Model ───────────────────────────────────────────────────────────

class VeraProvider {
  final String id;
  final String name;
  final String category;
  final String city;
  final double rating;
  final int reviewCount;
  final int followers;
  final String imageUrl;
  final bool isVerified;
  final String description;
  final String phone;
  final String email;

  const VeraProvider({
    required this.id,
    required this.name,
    required this.category,
    required this.city,
    required this.rating,
    required this.reviewCount,
    this.followers = 0,
    required this.imageUrl,
    this.isVerified = false,
    this.description = '',
    this.phone = '',
    this.email = '',
  });

  factory VeraProvider.fromJson(Map<String, dynamic> json) {
    final categoryValue = json['category'];
    final String categoryName;
    if (categoryValue is Map<String, dynamic>) {
      categoryName = categoryValue['name']?.toString() ?? '';
    } else if (categoryValue != null) {
      categoryName = categoryValue.toString();
    } else {
      categoryName = (json['category_name'] ?? json['type'] ?? '').toString();
    }
    return VeraProvider(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? json['store_name'] ?? json['business_name'] ?? '',
      category: categoryName,
      city: json['city'] ?? json['location'] ?? '',
      rating: VeraListing._parseRating(
        json['rating'] ?? json['average_rating'],
      ),
      reviewCount:
          json['reviews_count'] ??
          json['review_count'] ??
          json['serviceCount'] ??
          0,
      followers:
          json['followers_count'] ??
          json['followers'] ??
          json['follower_count'] ??
          0,
      imageUrl: json['logo'] ?? json['image'] ?? json['avatar'] ?? '',
      isVerified: json['is_verified'] ?? json['verified'] ?? false,
      description: json['description'] ?? json['bio'] ?? '',
      phone: json['phone'] ?? json['mobile'] ?? '',
      email: json['email'] ?? '',
    );
  }
}

// ─── Account Manager Model ────────────────────────────────────────────────

class VeraAccountManager {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String avatarUrl;

  const VeraAccountManager({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',
    this.role = '',
    this.avatarUrl = '',
  });

  factory VeraAccountManager.fromJson(Map<String, dynamic> json) {
    return VeraAccountManager(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      avatarUrl: json['avatar_url'] ?? json['avatarUrl'] ?? '',
    );
  }
}

// ─── Job Model ────────────────────────────────────────────────────────────────

class VeraJob {
  final String id;
  final String title;
  final String company;
  final String location;
  final String salary;
  final String type;
  final String logoUrl;
  final String postedAt;
  final bool isNew;
  final List<String> tags;
  final String description;

  const VeraJob({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.salary,
    required this.type,
    required this.logoUrl,
    required this.postedAt,
    this.isNew = false,
    this.tags = const [],
    this.description = '',
  });

  factory VeraJob.fromJson(Map<String, dynamic> json) {
    final tags = <String>[];
    if (json['tags'] is List) {
      for (final t in json['tags'] as List) {
        tags.add(t is String ? t : t['name']?.toString() ?? '');
      }
    } else if (json['skills'] is List) {
      for (final t in json['skills'] as List) {
        tags.add(t is String ? t : t['name']?.toString() ?? '');
      }
    }
    return VeraJob(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? json['job_title'] ?? json['name'] ?? '',
      company:
          json['company'] ?? json['company_name'] ?? json['employer'] ?? '',
      location: json['location'] ?? json['city'] ?? json['address'] ?? '',
      salary:
          json['salary'] ??
          json['salary_range'] ??
          json['compensation'] ??
          'Competitive',
      type:
          json['type'] ??
          json['job_type'] ??
          json['employment_type'] ??
          'Full-time',
      logoUrl: json['logo'] ?? json['company_logo'] ?? json['image'] ?? '',
      postedAt: json['posted_at'] ?? json['created_at'] ?? json['date'] ?? '',
      isNew: json['is_new'] ?? json['new'] ?? false,
      tags: tags,
      description: json['description'] ?? json['details'] ?? '',
    );
  }
}

// ─── Course Model ─────────────────────────────────────────────────────────────

class VeraCourse {
  final String id;
  final String title;
  final String provider;
  final String duration;
  final String level;
  final String price;
  final double rating;
  final String students;
  final String imageUrl;
  final String category;

  const VeraCourse({
    required this.id,
    required this.title,
    required this.provider,
    required this.duration,
    required this.level,
    required this.price,
    required this.rating,
    required this.students,
    required this.imageUrl,
    this.category = '',
  });

  factory VeraCourse.fromJson(Map<String, dynamic> json) {
    return VeraCourse(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? json['name'] ?? json['course_title'] ?? '',
      provider:
          json['provider'] ?? json['instructor'] ?? json['organization'] ?? '',
      duration: json['duration'] ?? json['length'] ?? '',
      level: json['level'] ?? json['difficulty'] ?? 'Beginner',
      price: json['price']?.toString() ?? json['cost']?.toString() ?? 'Free',
      rating: _toDouble(json['rating'] ?? json['average_rating']),
      students:
          json['students']?.toString() ?? json['enrolled']?.toString() ?? '0',
      imageUrl: json['image'] ?? json['thumbnail'] ?? json['cover'] ?? '',
      category: json['category']?['name'] ?? json['category_name'] ?? '',
    );
  }
}

// ─── Product Model ────────────────────────────────────────────────────────────

class VeraProduct {
  final String id;
  final String name;
  final String brand;
  final double price;
  final double originalPrice;
  final double rating;
  final int reviews;
  final String imageUrl;
  final String badge;
  final int badgeColor;
  final bool isFavorite;
  final List<String> colors;
  final String category;
  final String description;

  const VeraProduct({
    required this.id,
    required this.name,
    required this.brand,
    required this.price,
    required this.originalPrice,
    required this.rating,
    required this.reviews,
    required this.imageUrl,
    this.badge = '',
    this.badgeColor = 0xFFEFA9B8,
    this.isFavorite = false,
    this.colors = const [],
    this.category = '',
    this.description = '',
  });

  factory VeraProduct.fromJson(Map<String, dynamic> json) {
    final colors = <String>[];
    if (json['colors'] is List) {
      for (final c in json['colors'] as List) {
        colors.add(c is String ? c : c['name']?.toString() ?? '');
      }
    } else if (json['variants'] is List) {
      for (final v in json['variants'] as List) {
        if (v['color'] != null) colors.add(v['color'].toString());
      }
    }
    final price = _toDouble(json['price'] ?? json['sale_price']);
    final originalPrice = _toDouble(
      json['original_price'] ?? json['regular_price'] ?? json['price'] ?? price,
    );
    return VeraProduct(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? json['title'] ?? json['product_name'] ?? '',
      brand:
          json['brand'] ?? json['brand_name'] ?? json['store']?['name'] ?? '',
      price: price,
      originalPrice: originalPrice,
      rating: _toDouble(json['rating'] ?? json['average_rating']),
      reviews:
          json['reviews_count'] ?? json['review_count'] ?? json['reviews'] ?? 0,
      imageUrl: VeraListing._parseImage(json),
      badge: json['badge'] ?? json['label'] ?? '',
      badgeColor: json['badge_color'] ?? 0xFFEFA9B8,
      isFavorite: json['is_favorite'] ?? json['in_wishlist'] ?? false,
      colors: colors,
      category: json['category']?['name'] ?? json['category_name'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

// ─── Service/Booking Model ────────────────────────────────────────────────────

class VeraService {
  final String id;
  final String name;
  final String provider;
  final String category;
  final String categorySlug;
  final String listingType;
  final String subcategory;
  final double price;
  final String currency;
  final String duration;
  final double rating;
  final int reviews;
  final String imageUrl;
  final List<String> gallery;
  final String description;
  final String longDescription;
  final String providerCity;
  final String providerAvatar;
  final bool providerVerified;
  final int viewCount;
  final int orderCount;
  final String priceType;
  final String providerBio;
  final double providerRating;
  final int providerCompletedOrders;
  final String deliveryTime;
  final int revisions;
  final List<String> features;
  final List<String> tags;
  final String jobType;
  final String propertyType;
  final int bedrooms;
  final int bathrooms;
  final String area;
  final List<String> sizes;
  final List<String> colors;
  final String status;
  final String address;
  final String phone;
  final String providerPhone;
  final Map<String, dynamic> workingHours;
  final double? latitude;
  final double? longitude;

  const VeraService({
    required this.id,
    required this.name,
    required this.provider,
    required this.category,
    this.categorySlug = '',
    this.listingType = '',
    required this.price,
    required this.duration,
    required this.rating,
    required this.reviews,
    required this.imageUrl,
    this.gallery = const [],
    this.subcategory = '',
    this.currency = 'AED',
    this.description = '',
    this.longDescription = '',
    this.providerCity = '',
    this.providerAvatar = '',
    this.providerVerified = false,
    this.viewCount = 0,
    this.orderCount = 0,
    this.priceType = 'fixed',
    this.providerBio = '',
    this.providerRating = 0.0,
    this.providerCompletedOrders = 0,
    this.deliveryTime = '',
    this.revisions = 0,
    this.features = const [],
    this.tags = const [],
    this.jobType = '',
    this.propertyType = '',
    this.bedrooms = 0,
    this.bathrooms = 0,
    this.area = '',
    this.sizes = const [],
    this.colors = const [],
    this.status = 'pending',
    this.address = '',
    this.phone = '',
    this.providerPhone = '',
    this.workingHours = const {},
    this.latitude,
    this.longitude,
  });

  /// Builds the flat map shape expected by the legacy list-card builders.
  /// Covers all six category screens (clinics, salons, gym, fashion,
  /// real-estate, jobs).
  Map<String, dynamic> toCardMap() {
    String periodStr = '';
    if (priceType == 'month') {
      periodStr = '/month';
    } else if (priceType == 'year') {
      periodStr = '/year';
    }
    final formatted = price == price.roundToDouble()
        ? price.toStringAsFixed(0)
        : price.toStringAsFixed(2);
    final withCommas = formatted.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    final priceStr = price > 0
        ? 'AED $withCommas$periodStr'
        : 'Price on request';
    final sub = subcategory.isNotEmpty
        ? _titleCase(subcategory)
        : _titleCase(category);
    return {
      'id': id,
      'name': name,
      'title': name,
      'category': sub,
      'categorySlug': categorySlug.isNotEmpty ? categorySlug : category,
      'listing_type': listingType.isNotEmpty ? listingType : categorySlug,
      'subcategory': sub,
      'subcategorySlug': subcategory,
      'location': address.isNotEmpty ? address : providerCity,
      'rating': rating,
      'reviews': reviews,
      'price': priceStr,
      'image': imageUrl,
      'images': [if (imageUrl.isNotEmpty) imageUrl, ...gallery],
      'badge': sub,
      'badgeColor': 0xFFC8A96A,
      'isOpen': true,
      'isSaved': false,
      'waitTime': null,
      'providerType': sub,
      'provider': provider,
      'providerName': provider,
      'providerPhone': providerPhone,
      'providerAvatar': providerAvatar,
      'providerVerified': providerVerified,
      'description': description.isNotEmpty ? description : longDescription,
      'originalPrice': priceStr,
      'type': listingType.isNotEmpty ? listingType : categorySlug,
      'company': provider,
      'salary': priceStr,
      'logo': imageUrl,
      'jobCategory': sub,
      'brand': provider,
      'propertyType': propertyType.isNotEmpty ? propertyType : sub,
      'beds': bedrooms,
      'baths': bathrooms,
      'area': area,
      'jobType': jobType,
      'sizes': sizes,
      'colors': colors,
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone,
      'address': address,
    };
  }

  /// Builds the flat map shape expected by the legacy detail screens.
  Map<String, dynamic> toDetailsMap() {
    String periodStr = '';
    if (priceType == 'month') {
      periodStr = '/month';
    } else if (priceType == 'year') {
      periodStr = '/year';
    }
    final formatted = price == price.roundToDouble()
        ? price.toStringAsFixed(0)
        : price.toStringAsFixed(2);
    final withCommas = formatted.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    final priceStr = price > 0
        ? 'AED $withCommas$periodStr'
        : 'Price on request';
    final sub = subcategory.isNotEmpty
        ? _titleCase(subcategory)
        : _titleCase(category);
    return {
      'id': id,
      'name': name,
      'title': name,
      'category': sub,
      'categorySlug': categorySlug.isNotEmpty ? categorySlug : category,
      'listing_type': listingType.isNotEmpty ? listingType : categorySlug,
      'location': address.isNotEmpty ? address : providerCity,
      'city': providerCity,
      'rating': rating,
      'reviews': reviews,
      'price': priceStr,
      'image': imageUrl,
      'images': [if (imageUrl.isNotEmpty) imageUrl, ...gallery],
      'gallery': gallery,
      'isOpen': true,
      'isSaved': false,
      'badge': sub,
      'provider': provider,
      'providerName': provider,
      'providerAvatar': providerAvatar,
      'providerVerified': providerVerified,
      'providerBio': providerBio,
      'providerRating': providerRating,
      'providerCompletedOrders': providerCompletedOrders,
      'description': description.isNotEmpty ? description : longDescription,
      'longDescription': longDescription.isNotEmpty
          ? longDescription
          : description,
      'duration': duration,
      'deliveryTime': deliveryTime,
      'revisions': revisions,
      'features': features,
      'tags': tags,
      'subcategory': sub,
      'subcategorySlug': subcategory,
      'services': [if (name.isNotEmpty) name],
      'hours': '',
      'phone': phone,
      'providerPhone': providerPhone,
      'currency': currency,
      'viewCount': viewCount,
      'orderCount': orderCount,
      'status': status,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'workingHours': workingHours,
      'priceNumeric': price,
      'durationMinutes': duration.replaceAll(RegExp(r'[^0-9]'), ''),
    };
  }

  factory VeraService.fromJson(Map<String, dynamic> json) {
    final categoryValue = json['category'];
    final String categoryName;
    if (categoryValue is Map<String, dynamic>) {
      categoryName = categoryValue['name']?.toString() ?? '';
    } else if (categoryValue != null) {
      categoryName = categoryValue.toString();
    } else {
      categoryName =
          (json['category_name'] ??
                  json['category_slug'] ??
                  json['subcategory'] ??
                  '')
              .toString();
    }
    final listingType = (json['listing_type'] ?? json['listingType'] ?? '')
        .toString();
    final rawPrice = json['price'] ?? json['starting_price'] ?? 0;
    final double priceValue = rawPrice is num
        ? rawPrice.toDouble()
        : double.tryParse('$rawPrice') ?? 0.0;
    final rawDuration =
        json['duration_minutes'] ?? json['durationMinutes'] ?? json['duration'];
    String durationValue = '';
    if (rawDuration != null) {
      if (rawDuration is num) {
        durationValue = '${rawDuration.toInt()} min';
      } else {
        durationValue = rawDuration.toString();
      }
    }
    final gallery = <String>[];
    if (json['gallery'] is List) {
      for (final g in json['gallery'] as List) {
        gallery.add(g is String ? g : g['url'] ?? g['path'] ?? '');
      }
    }
    if (gallery.isEmpty && json['images'] is List) {
      for (final image in json['images'] as List) {
        final value = image is String
            ? image
            : image is Map
            ? (image['url'] ?? image['path'] ?? '').toString()
            : '';
        if (value.isNotEmpty) gallery.add(value);
      }
    }
    final primaryImage = VeraListing._parseImage(json);
    if (gallery.isNotEmpty && gallery.first == primaryImage) {
      gallery.removeAt(0);
    }
    final featureList = <String>[];
    if (json['features'] is List) {
      for (final f in json['features'] as List) {
        featureList.add(f is String ? f : f['name']?.toString() ?? '');
      }
    }
    final tagList = <String>[];
    if (json['tags'] is List) {
      for (final t in json['tags'] as List) {
        tagList.add(t.toString());
      }
    }
    final sizeList = <String>[];
    final rawSizes = json['sizes'] ?? json['available_sizes'] ?? json['size'];
    if (rawSizes is List) {
      for (final s in rawSizes) {
        final v = s is String
            ? s
            : (s['name'] ?? s['size'] ?? s['label'] ?? '').toString();
        if (v.isNotEmpty) sizeList.add(v);
      }
    } else if (rawSizes != null && rawSizes.toString().isNotEmpty) {
      sizeList.add(rawSizes.toString());
    }
    final colorList = <String>[];
    final rawColors = json['colors'] ?? json['available_colors'];
    if (rawColors is List) {
      for (final c in rawColors) {
        final v = c is String
            ? c
            : (c['name'] ?? c['color'] ?? c['code'] ?? '').toString();
        if (v.isNotEmpty) colorList.add(v);
      }
    }
    final rawType = json['type'];
    final typeStr = rawType is String ? rawType : '';
    final rawJobType = json['job_type'] ?? json['employment_type'] ?? '';
    final jobTypeValue = rawJobType.toString().isNotEmpty
        ? rawJobType.toString()
        : (typeStr.isNotEmpty &&
              !{
                'product',
                'service',
                'listing',
                'facility',
                'property',
                'appointment',
              }.contains(typeStr.toLowerCase()))
        ? typeStr
        : '';
    int intOf(Object? v) {
      if (v is num) return v.toInt();
      return int.tryParse('$v') ?? 0;
    }

    double? doubleOrNull(Object? v) {
      if (v is num) return v.toDouble();
      return double.tryParse('$v');
    }

    return VeraService(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? json['title'] ?? json['service_name'] ?? '',
      provider:
          json['providerName'] ??
          json['provider']?['name'] ??
          json['provider_name'] ??
          json['clinic_name'] ??
          json['salon_name'] ??
          '',
      category:
          VeraListing._isPropertyType(listingType) &&
              VeraListing._isGenericCategory(categoryName)
          ? 'real-estate'
          : categoryName,
      categorySlug:
          (json['category_slug'] ??
                  json['categorySlug'] ??
                  (VeraListing._isPropertyType(listingType)
                      ? 'real-estate'
                      : categoryName))
              .toString(),
      listingType: listingType,
      subcategory: (json['subcategory'] ?? json['sub_category'] ?? '')
          .toString(),
      price: priceValue,
      currency: json['currency'] ?? 'AED',
      duration: durationValue,
      rating: VeraListing._parseRating(
        json['rating'] ?? json['average_rating'] ?? json['providerRating'],
      ),
      reviews: intOf(
        json['reviews_count'] ?? json['review_count'] ?? json['reviews'],
      ),
      imageUrl: primaryImage,
      gallery: gallery,
      description: json['description'] ?? '',
      longDescription:
          json['longDescription'] ?? json['long_description'] ?? '',
      providerCity: (json['provider_city'] ?? json['provider']?['city'] ?? '')
          .toString(),
      providerAvatar:
          (json['providerAvatar'] ??
                  json['provider_avatar'] ??
                  json['provider']?['avatar'] ??
                  '')
              .toString(),
      providerVerified:
          json['provider_verified'] ??
          json['provider']?['is_verified'] ??
          false,
      viewCount: intOf(json['view_count'] ?? json['views']),
      orderCount: intOf(json['order_count'] ?? json['orders']),
      priceType: json['price_type'] ?? 'fixed',
      providerBio: (json['providerBio'] ?? json['provider_bio'] ?? '')
          .toString(),
      providerRating: VeraListing._parseRating(
        json['providerRating'] ?? json['provider_rating'],
      ),
      providerCompletedOrders: intOf(
        json['providerCompletedOrders'] ?? json['provider_completed_orders'],
      ),
      deliveryTime: (json['deliveryTime'] ?? json['delivery_time'] ?? '')
          .toString(),
      revisions: intOf(json['revisions']),
      features: featureList,
      tags: tagList,
      jobType: jobTypeValue,
      propertyType: (json['property_type'] ?? json['listing_type'] ?? '')
          .toString(),
      bedrooms: intOf(json['bedrooms'] ?? json['beds'] ?? json['num_bedrooms']),
      bathrooms: intOf(
        json['bathrooms'] ?? json['baths'] ?? json['num_bathrooms'],
      ),
      area:
          (json['area'] ??
                  json['size_sqft'] ??
                  json['sqft'] ??
                  json['size_area'] ??
                  '')
              .toString(),
      sizes: sizeList,
      colors: colorList,
      status: (json['status'] ?? 'pending').toString(),
      address: (json['address'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      providerPhone: (json['providerPhone'] ?? json['provider_phone'] ?? '')
          .toString(),
      latitude: doubleOrNull(json['latitude']),
      longitude: doubleOrNull(json['longitude']),
      workingHours: json['working_hours'] is Map<String, dynamic>
          ? json['working_hours']
          : {},
    );
  }
}

// ─── Order Model ──────────────────────────────────────────────────────────────

class VeraOrder {
  final String id;
  final String orderNumber;
  final String status;
  final double total;
  final String date;
  final List<String> itemNames;
  final String imageUrl;
  final String category;
  final String trackingNumber;
  final String deliveryProvider;

  const VeraOrder({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.total,
    required this.date,
    this.itemNames = const [],
    this.imageUrl = '',
    this.category = '',
    this.trackingNumber = '',
    this.deliveryProvider = '',
  });

  factory VeraOrder.fromJson(Map<String, dynamic> json) {
    final items = <String>[];
    if (json['items'] is List) {
      for (final item in json['items'] as List) {
        items.add(
          item['name'] ?? item['product_name'] ?? item['service_name'] ?? '',
        );
      }
    }
    return VeraOrder(
      id: json['id']?.toString() ?? '',
      orderNumber:
          json['order_number'] ?? json['reference'] ?? '#${json['id']}',
      status: json['status'] ?? json['order_status'] ?? 'pending',
      total: _toDouble(json['total'] ?? json['total_amount'] ?? json['amount']),
      date: json['created_at'] ?? json['date'] ?? json['order_date'] ?? '',
      itemNames: items,
      imageUrl: VeraListing._parseImage(json),
      category: json['category'] ?? json['type'] ?? '',
      trackingNumber: json['tracking_number'] ?? json['tracking_id'] ?? '',
      deliveryProvider: json['delivery_provider'] ?? json['courier'] ?? '',
    );
  }
}

// ─── Booking Model ────────────────────────────────────────────────────────────

class VeraBooking {
  final String id;
  final String serviceName;
  final String providerName;
  final String date;
  final String time;
  final String status;
  final double price;
  final String imageUrl;
  final String category;

  const VeraBooking({
    required this.id,
    required this.serviceName,
    required this.providerName,
    required this.date,
    required this.time,
    required this.status,
    required this.price,
    this.imageUrl = '',
    this.category = '',
  });

  factory VeraBooking.fromJson(Map<String, dynamic> json) {
    return VeraBooking(
      id: json['id']?.toString() ?? '',
      serviceName:
          json['service']?['name'] ??
          json['service_name'] ??
          json['title'] ??
          '',
      providerName:
          json['provider']?['name'] ??
          json['provider_name'] ??
          json['clinic_name'] ??
          '',
      date:
          json['date'] ??
          json['booking_date'] ??
          json['appointment_date'] ??
          '',
      time:
          json['time'] ??
          json['booking_time'] ??
          json['appointment_time'] ??
          '',
      status: json['status'] ?? json['booking_status'] ?? 'upcoming',
      price: _toDouble(json['price'] ?? json['amount'] ?? json['total']),
      imageUrl: VeraListing._parseImage(json),
      category:
          json['category']?['name'] ??
          json['category_name'] ??
          json['type'] ??
          '',
    );
  }
}

// ─── Notification Model ───────────────────────────────────────────────────────

class VeraNotification {
  final String id;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final String createdAt;
  final String icon;

  const VeraNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.icon = '',
  });

  factory VeraNotification.fromJson(Map<String, dynamic> json) {
    return VeraNotification(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? json['subject'] ?? '',
      body: json['body'] ?? json['message'] ?? json['content'] ?? '',
      type: json['type'] ?? json['category'] ?? 'general',
      isRead: json['is_read'] ?? json['read'] ?? false,
      createdAt: json['created_at'] ?? json['date'] ?? json['timestamp'] ?? '',
      icon: json['icon'] ?? '',
    );
  }
}

// ─── Wishlist Item Model ──────────────────────────────────────────────────────

class VeraWishlistItem {
  final String id;
  final String name;
  final String category;
  final double price;
  final double originalPrice;
  final double rating;
  final String imageUrl;
  final bool inStock;
  final String type;

  const VeraWishlistItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.originalPrice,
    required this.rating,
    required this.imageUrl,
    this.inStock = true,
    this.type = 'product',
  });

  factory VeraWishlistItem.fromJson(Map<String, dynamic> json) {
    final item = json['item'] ?? json['product'] ?? json['service'] ?? json;
    final price = _toDouble(item['price'] ?? item['sale_price']);
    return VeraWishlistItem(
      id: json['id']?.toString() ?? item['id']?.toString() ?? '',
      name: item['name'] ?? item['title'] ?? '',
      category: item['category']?['name'] ?? item['category_name'] ?? '',
      price: price,
      originalPrice: _toDouble(
        item['original_price'] ?? item['regular_price'] ?? price,
      ),
      rating: _toDouble(item['rating'] ?? item['average_rating']),
      imageUrl: VeraListing._parseImage(item),
      inStock: item['in_stock'] ?? item['available'] ?? true,
      type: json['type'] ?? item['type'] ?? 'product',
    );
  }
}

// ─── Cart Item Model ──────────────────────────────────────────────────────────

class VeraCartItem {
  final String id;
  final String name;
  final String provider;
  final double price;
  final int quantity;
  final String imageUrl;
  final String category;

  const VeraCartItem({
    required this.id,
    required this.name,
    required this.provider,
    required this.price,
    required this.quantity,
    required this.imageUrl,
    this.category = '',
  });

  factory VeraCartItem.fromJson(Map<String, dynamic> json) {
    final item = json['item'] ?? json['product'] ?? json['service'] ?? json;
    return VeraCartItem(
      id: json['id']?.toString() ?? item['id']?.toString() ?? '',
      name: item['name'] ?? item['title'] ?? json['name'] ?? '',
      provider:
          item['provider']?['name'] ??
          item['provider_name'] ??
          item['store_name'] ??
          '',
      price: _toDouble(json['price'] ?? item['price'] ?? json['unit_price']),
      quantity: json['quantity'] ?? json['qty'] ?? 1,
      imageUrl: VeraListing._parseImage(item.isNotEmpty ? item : json),
      category: item['category']?['name'] ?? item['category_name'] ?? '',
    );
  }
}

// ─── Review Model ─────────────────────────────────────────────────────────────

class VeraReview {
  final String id;
  final String authorName;
  final String authorAvatar;
  final double rating;
  final String comment;
  final String createdAt;
  final String targetId;
  final String targetType;

  const VeraReview({
    required this.id,
    required this.authorName,
    required this.authorAvatar,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.targetId = '',
    this.targetType = '',
  });

  factory VeraReview.fromJson(Map<String, dynamic> json) {
    return VeraReview(
      id: json['id']?.toString() ?? '',
      authorName:
          json['user']?['name'] ??
          json['author'] ??
          json['reviewer'] ??
          'Anonymous',
      authorAvatar: json['user']?['avatar'] ?? json['author_avatar'] ?? '',
      rating: _toDouble(json['rating'] ?? json['stars']),
      comment: json['comment'] ?? json['review'] ?? json['body'] ?? '',
      createdAt: json['created_at'] ?? json['date'] ?? '',
      targetId:
          json['target_id']?.toString() ?? json['service_id']?.toString() ?? '',
      targetType: json['target_type'] ?? json['type'] ?? '',
    );
  }
}

// ─── Wallet Model ─────────────────────────────────────────────────────────────

class VeraWallet {
  final double balance;
  final String currency;
  final List<VeraWalletTransaction> transactions;

  const VeraWallet({
    required this.balance,
    required this.currency,
    this.transactions = const [],
  });

  factory VeraWallet.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json['wallet'] ?? json;
    final txList = <VeraWalletTransaction>[];
    final rawTx = data['transactions'] ?? json['transactions'] ?? [];
    if (rawTx is List) {
      for (final t in rawTx) {
        if (t is Map<String, dynamic>) {
          txList.add(VeraWalletTransaction.fromJson(t));
        }
      }
    }
    return VeraWallet(
      balance: _toDouble(data['balance'] ?? data['wallet_balance']),
      currency: data['currency'] ?? 'AED',
      transactions: txList,
    );
  }
}

class VeraWalletTransaction {
  final String id;
  final String type; // credit | debit
  final double amount;
  final String description;
  final String createdAt;

  const VeraWalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.createdAt,
  });

  factory VeraWalletTransaction.fromJson(Map<String, dynamic> json) {
    return VeraWalletTransaction(
      id: json['id']?.toString() ?? '',
      type: json['type'] ?? json['transaction_type'] ?? 'credit',
      amount: _toDouble(json['amount']),
      description: json['description'] ?? json['note'] ?? '',
      createdAt: json['created_at'] ?? json['date'] ?? '',
    );
  }
}

// ─── Loyalty Model ────────────────────────────────────────────────────────────

class VeraLoyalty {
  final int points;
  final String tier;
  final int pointsToNextTier;
  final List<Map<String, dynamic>> history;

  const VeraLoyalty({
    required this.points,
    required this.tier,
    this.pointsToNextTier = 0,
    this.history = const [],
  });

  factory VeraLoyalty.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json['loyalty'] ?? json;
    final hist = <Map<String, dynamic>>[];
    final rawHist = data['history'] ?? data['transactions'] ?? [];
    if (rawHist is List) {
      for (final h in rawHist) {
        if (h is Map<String, dynamic>) hist.add(h);
      }
    }
    return VeraLoyalty(
      points: data['points'] ?? data['loyalty_points'] ?? data['balance'] ?? 0,
      tier: data['tier'] ?? data['level'] ?? data['rank'] ?? 'Bronze',
      pointsToNextTier:
          data['points_to_next_tier'] ?? data['next_tier_points'] ?? 0,
      history: hist,
    );
  }
}

// ─── Subscription Plan Model ──────────────────────────────────────────────────

class VeraSubscriptionPlan {
  final String id;
  final String name;
  final double price;
  final String period;
  final List<String> features;
  final bool isPopular;

  const VeraSubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.period,
    this.features = const [],
    this.isPopular = false,
  });

  factory VeraSubscriptionPlan.fromJson(Map<String, dynamic> json) {
    final features = <String>[];
    if (json['features'] is List) {
      for (final f in json['features'] as List) {
        features.add(f is String ? f : f['name']?.toString() ?? '');
      }
    }
    return VeraSubscriptionPlan(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? json['title'] ?? json['plan_name'] ?? '',
      price: _toDouble(json['price'] ?? json['amount']),
      period:
          json['period'] ??
          json['billing_cycle'] ??
          json['interval'] ??
          'monthly',
      features: features,
      isPopular:
          json['is_popular'] ?? json['popular'] ?? json['recommended'] ?? false,
    );
  }
}

class VeraAdPackage {
  final String id;
  final String code;
  final String name;
  final String nameAr;
  final double price;
  final int impressionLimit;
  final int durationDays;
  final double packageWeight;
  final int frequencyCap;
  final List<String> placements;

  const VeraAdPackage({
    required this.id,
    required this.code,
    required this.name,
    required this.nameAr,
    required this.price,
    required this.impressionLimit,
    required this.durationDays,
    required this.packageWeight,
    required this.frequencyCap,
    required this.placements,
  });

  factory VeraAdPackage.fromJson(Map<String, dynamic> json) => VeraAdPackage(
    id: json['id']?.toString() ?? '',
    code: json['code']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    nameAr: json['name_ar']?.toString() ?? '',
    price: _toDouble(json['price']),
    impressionLimit:
        int.tryParse(json['impression_limit']?.toString() ?? '') ?? 0,
    durationDays: int.tryParse(json['duration_days']?.toString() ?? '') ?? 0,
    packageWeight: _toDouble(json['package_weight']),
    frequencyCap: int.tryParse(json['frequency_cap']?.toString() ?? '') ?? 3,
    placements: (json['placements'] is List)
        ? (json['placements'] as List).map((e) => e.toString()).toList()
        : const [],
  );
}

// ─── Country Model ────────────────────────────────────────────────────────────

class VeraCountry {
  final String id;
  final String name;
  final String code;
  final String flag;
  final String dialCode;

  const VeraCountry({
    required this.id,
    required this.name,
    required this.code,
    this.flag = '',
    this.dialCode = '',
  });

  factory VeraCountry.fromJson(Map<String, dynamic> json) {
    return VeraCountry(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? json['country_name'] ?? '',
      code: json['code'] ?? json['iso_code'] ?? json['country_code'] ?? '',
      flag: json['flag'] ?? json['flag_url'] ?? '',
      dialCode: json['dial_code'] ?? json['phone_code'] ?? '',
    );
  }
}

// ─── Delivery Shipment Model ──────────────────────────────────────────────────

class VeraShipment {
  final String id;
  final String trackingNumber;
  final String status;
  final String provider; // aramex | smsa | jeebly | quiqup
  final String estimatedDelivery;
  final List<Map<String, dynamic>> events;

  const VeraShipment({
    required this.id,
    required this.trackingNumber,
    required this.status,
    required this.provider,
    this.estimatedDelivery = '',
    this.events = const [],
  });

  factory VeraShipment.fromJson(
    Map<String, dynamic> json, {
    String provider = '',
  }) {
    final events = <Map<String, dynamic>>[];
    final rawEvents =
        json['events'] ?? json['tracking_events'] ?? json['history'] ?? [];
    if (rawEvents is List) {
      for (final e in rawEvents) {
        if (e is Map<String, dynamic>) events.add(e);
      }
    }
    return VeraShipment(
      id: json['id']?.toString() ?? '',
      trackingNumber:
          json['tracking_number'] ?? json['awb'] ?? json['waybill'] ?? '',
      status: json['status'] ?? json['shipment_status'] ?? 'pending',
      provider: provider.isNotEmpty
          ? provider
          : (json['provider'] ?? json['courier'] ?? ''),
      estimatedDelivery: json['estimated_delivery'] ?? json['eta'] ?? '',
      events: events,
    );
  }
}

// ─── Payment Model ────────────────────────────────────────────────────────────

class VeraPayment {
  final String id;
  final String method;
  final double amount;
  final String status;
  final String currency;
  final String createdAt;
  final String reference;

  const VeraPayment({
    required this.id,
    required this.method,
    required this.amount,
    required this.status,
    required this.currency,
    required this.createdAt,
    this.reference = '',
  });

  factory VeraPayment.fromJson(Map<String, dynamic> json) {
    return VeraPayment(
      id: json['id']?.toString() ?? '',
      method: json['method'] ?? json['payment_method'] ?? json['gateway'] ?? '',
      amount: _toDouble(json['amount'] ?? json['total']),
      status: json['status'] ?? json['payment_status'] ?? 'pending',
      currency: json['currency'] ?? 'AED',
      createdAt: json['created_at'] ?? json['date'] ?? '',
      reference:
          json['reference'] ??
          json['transaction_id'] ??
          json['payment_id'] ??
          '',
    );
  }
}

// ─── Dashboard Stats Model ────────────────────────────────────────────────────

class VeraDashboardStats {
  final int totalOrders;
  final int totalBookings;
  final double totalRevenue;
  final int totalUsers;
  final int totalProviders;
  final double walletBalance;
  final int loyaltyPoints;

  const VeraDashboardStats({
    this.totalOrders = 0,
    this.totalBookings = 0,
    this.totalRevenue = 0,
    this.totalUsers = 0,
    this.totalProviders = 0,
    this.walletBalance = 0,
    this.loyaltyPoints = 0,
  });

  factory VeraDashboardStats.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json['stats'] ?? json['dashboard'] ?? json;
    return VeraDashboardStats(
      totalOrders:
          data['total_orders'] ?? data['orders_count'] ?? data['orders'] ?? 0,
      totalBookings:
          data['total_bookings'] ??
          data['bookings_count'] ??
          data['bookings'] ??
          0,
      totalRevenue: _toDouble(
        data['total_revenue'] ?? data['revenue'] ?? data['earnings'],
      ),
      totalUsers:
          data['total_users'] ?? data['users_count'] ?? data['users'] ?? 0,
      totalProviders:
          data['total_providers'] ??
          data['providers_count'] ??
          data['providers'] ??
          0,
      walletBalance: _toDouble(data['wallet_balance'] ?? data['balance']),
      loyaltyPoints: data['loyalty_points'] ?? data['points'] ?? 0,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// AUTH EXCEPTION
// ═══════════════════════════════════════════════════════════════════════════════

class VeraAuthException implements Exception {
  final int statusCode;
  final String message;

  const VeraAuthException(this.statusCode, this.message);

  @override
  String toString() => message;
}

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN API SERVICE CLASS
// ═══════════════════════════════════════════════════════════════════════════════

class VeraApiService {
  static const String _baseUrl = String.fromEnvironment(
    'VERA_API_BASE_URL',
    defaultValue: 'https://veraapp.app/api',
  );

  /// Base URL of the API (e.g. https://veraapp.app/api).
  static String get baseUrl => _baseUrl;

  /// Origin (scheme + host) used to resolve relative asset paths
  /// returned by the API (e.g. /uploads/banners/....jpg).
  static String get baseOrigin => Uri.parse(_baseUrl).origin;

  /// Resolves a relative asset path returned by the API (e.g.
  /// "/uploads/banners/x.jpg" or "uploads/x.jpg") into a full URL against
  /// the API origin. Absolute http(s) URLs, file paths and bundled
  /// "assets/..." keys are returned unchanged.
  static String resolveAssetUrl(String path) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return trimmed;
    if (trimmed.startsWith('http://') ||
        trimmed.startsWith('https://') ||
        trimmed.startsWith('www.') ||
        trimmed.startsWith('file://') ||
        trimmed.startsWith('assets/')) {
      return trimmed;
    }
    final slash = trimmed.startsWith('/') ? '' : '/';
    return '$baseOrigin$slash$trimmed';
  }

  static VeraApiService? _instance;
  late final Dio _dio;
  String? _authToken;
  String? _providerToken;
  bool _guestMode = false;
  bool _onboardingDone = false;
  bool _tokensLoaded = false;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final Map<String, List<VeraService>> _publicServicesCache = {};

  /// In-flight requests. Cancelled wholesale on logout / session expiry.
  final Set<CancelToken> _activeRequests = <CancelToken>{};

  /// Guards against re-entrant forced logouts (e.g. several requests failing
  /// with 401 at the same time).
  bool _sessionExpiryInProgress = false;

  VeraApiService._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 25),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          await _loadToken();
          final path = options.path;
          final isProviderPath =
              path.contains('/provider/') ||
              path.contains('/provider-auth/') ||
              path.contains('/upload/');
          final token = isProviderPath
              ? (_providerToken ?? _authToken)
              : _authToken;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          final cancelToken = CancelToken();
          _activeRequests.add(cancelToken);
          options.cancelToken = cancelToken;
          handler.next(options);
        },
        onResponse: (response, handler) {
          final token = response.requestOptions.cancelToken;
          if (token != null) _activeRequests.remove(token);
          handler.next(response);
        },
        onError: (error, handler) {
          final token = error.requestOptions.cancelToken;
          if (token != null) _activeRequests.remove(token);
          if (!_sessionExpiryInProgress) {
            _handleUnauthorized(error);
          }
          debugPrint(
            'VeraAPI [${error.requestOptions.path}]: ${error.message}',
          );
          handler.next(error);
        },
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(requestBody: false, responseBody: false, error: true),
      );
    }

    _loadToken();
  }

  static VeraApiService get instance {
    _instance ??= VeraApiService._();
    return _instance!;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SESSION EXPIRY / REQUEST CANCELLATION
  // ══════════════════════════════════════════════════════════════════════════

  /// Cancels every pending authenticated request so stale responses cannot
  /// populate the UI after a session is gone.
  void cancelActiveRequests() {
    for (final token in _activeRequests) {
      if (!token.isCancelled) {
        token.cancel('Session expired');
      }
    }
    _activeRequests.clear();
  }

  /// True for auth endpoints where a 401 means "bad credentials" rather than
  /// "session expired" and must never trigger a forced logout.
  bool _isAuthEndpoint(String path) {
    return path.contains('/login') ||
        path.contains('/register') ||
        path.contains('/logout') ||
        path.contains('/forgot-password') ||
        path.contains('/reset-password') ||
        path.contains('/otp') ||
        path.contains('/password/forgot') ||
        path.contains('/password/reset') ||
        path.contains('/upload');
  }

  void _handleUnauthorized(DioException error) {
    final status = error.response?.statusCode;
    if (status != 401 && status != 403) return;
    final path = error.requestOptions.path;
    if (_isAuthEndpoint(path)) return;
    // A push-token registration can legitimately 401 when posted to the wrong
    // role endpoint (e.g. a buyer token hitting /provider/push-token). That is
    // a routing artifact, not a session expiry — never force a logout here.
    if (path.contains('/push-token')) return;
    // Only force a logout when there actually is a session to lose. Public
    // routes must never kick guests to the login screen.
    if (!isAuthenticated && !isProviderAuthenticated) return;
    final isProviderPath =
        path.startsWith('/provider/') || path.startsWith('/provider-auth/');
    // A provider hitting a buyer endpoint (e.g. /buyer/profile) is expected
    // to get 401 — that does NOT mean the provider session is expired.
    // Only force logout when a provider path returns 401 (provider token expired)
    // or when a buyer path returns 401 (buyer token expired).
    if (!isProviderPath && isProviderAuthenticated) return;
    _sessionExpiryInProgress = true;
    AuthSession.instance.forceLogout(isProvider: isProviderPath).whenComplete(
      () {
        _sessionExpiryInProgress = false;
      },
    );
  }

  /// Validates the stored buyer token against the server. Returns false when
  /// the token is rejected (401/403/404). Network failures keep the session.
  Future<bool> validateBuyerSession({bool suppressAutoLogout = false}) async {
    if (!isAuthenticated) return false;
    final prev = _sessionExpiryInProgress;
    if (suppressAutoLogout) _sessionExpiryInProgress = true;
    try {
      final res = await _dio.get('/buyer-auth/me');
      return res.statusCode == 200;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401 || status == 403 || status == 404) return false;
      return true;
    } catch (_) {
      return true;
    } finally {
      _sessionExpiryInProgress = prev;
    }
  }

  /// Validates the stored provider token against the server. Returns false
  /// when the token is rejected. Network failures keep the session.
  Future<bool> validateProviderSession({
    bool suppressAutoLogout = false,
  }) async {
    if (!isProviderAuthenticated) return false;
    final prev = _sessionExpiryInProgress;
    if (suppressAutoLogout) _sessionExpiryInProgress = true;
    try {
      final res = await _dio.get('/provider-auth/me');
      return res.statusCode == 200;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401 || status == 403 || status == 404) return false;
      return true;
    } catch (_) {
      return true;
    } finally {
      _sessionExpiryInProgress = prev;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TOKEN MANAGEMENT
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _loadToken() async {
    if (_tokensLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _authToken = await _secureStorage.read(key: 'vera_auth_token');
      _providerToken = await _secureStorage.read(key: 'vera_provider_token');
      // Migrate legacy plaintext sessions once, then remove them.
      if (_authToken == null) {
        final legacy = prefs.getString('vera_auth_token');
        if (legacy != null && legacy.isNotEmpty) {
          _authToken = legacy;
          await _secureStorage.write(key: 'vera_auth_token', value: legacy);
          await prefs.remove('vera_auth_token');
        }
      }
      if (_providerToken == null) {
        final legacy = prefs.getString('vera_provider_token');
        if (legacy != null && legacy.isNotEmpty) {
          _providerToken = legacy;
          await _secureStorage.write(key: 'vera_provider_token', value: legacy);
          await prefs.remove('vera_provider_token');
        }
      }
      _guestMode = prefs.getBool('vera_guest_mode') ?? false;
      _onboardingDone = prefs.getBool('vera_onboarding_done') ?? false;
      _tokensLoaded = true;
      _reRegisterPushToken();
    } catch (_) {}
  }

  String? _cachedFcmToken;

  /// Stores the FCM token so we can re-register after login.
  void cacheFcmToken(String token) => _cachedFcmToken = token;

  /// Re-registers the push token with the newly-set auth credentials.
  Future<void> _reRegisterPushToken() async {
    final t = _cachedFcmToken;
    if (t != null && t.isNotEmpty) {
      await registerPushToken(t);
    }
  }

  Future<void> setToken(String token) async {
    _authToken = token;
    try {
      await _secureStorage.write(key: 'vera_auth_token', value: token);
    } catch (_) {}
    AuthSession.instance.refresh();
    _reRegisterPushToken();
  }

  Future<void> clearToken() async {
    _authToken = null;
    try {
      await _secureStorage.delete(key: 'vera_auth_token');
    } catch (_) {}
    AuthSession.instance.refresh();
  }

  /// Persists the provider token in a separate slot so buyer and provider
  /// sessions can coexist and survive app restarts.
  Future<void> setProviderToken(String token) async {
    _providerToken = token;
    try {
      await _secureStorage.write(key: 'vera_provider_token', value: token);
    } catch (_) {}
    AuthSession.instance.refresh();
    _reRegisterPushToken();
  }

  Future<void> clearProviderToken() async {
    _providerToken = null;
    try {
      await _secureStorage.delete(key: 'vera_provider_token');
    } catch (_) {}
    AuthSession.instance.refresh();
  }

  bool get isAuthenticated => _authToken != null && _authToken!.isNotEmpty;

  bool get isProviderAuthenticated =>
      _providerToken != null && _providerToken!.isNotEmpty;

  /// Whether the user chose to browse as a guest. Persisted across restarts.
  bool get isGuestMode => _guestMode;

  Future<void> setGuestMode(bool value) async {
    _guestMode = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('vera_guest_mode', value);
    } catch (_) {}
  }

  /// Whether the user has completed the first-time setup. Persisted so the
  /// onboarding flow is never shown again after the initial entry.
  bool get isOnboardingDone => _onboardingDone;

  Future<void> setOnboardingDone() async {
    _onboardingDone = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('vera_onboarding_done', true);
    } catch (_) {}
  }

  /// Loads the persisted session once. Returns true when the token slots have
  /// been restored (they may still be empty).
  Future<bool> ensureBooted() async {
    await _loadToken();
    return true;
  }

  /// Ensures the persisted token has been loaded. Returns true if a valid
  /// buyer session exists.
  Future<bool> ensureAuthenticated() async {
    if (_authToken != null && _authToken!.isNotEmpty) return true;
    await _loadToken();
    return _authToken != null && _authToken!.isNotEmpty;
  }

  /// Ensures the persisted provider token has been loaded. Returns true if a
  /// provider session exists.
  Future<bool> ensureProviderAuthenticated() async {
    if (_providerToken != null && _providerToken!.isNotEmpty) return true;
    await _loadToken();
    return _providerToken != null && _providerToken!.isNotEmpty;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GROUP 1-4: AUTH — Buyer / Provider / Admin / Staff
  // ══════════════════════════════════════════════════════════════════════════

  /// POST /api/buyer-auth/login
  Future<Map<String, dynamic>?> loginBuyer({
    required String email,
    required String password,
  }) async {
    return _authPost(
      endpoints: ['/buyer-auth/login', '/auth/buyer/login', '/login'],
      data: {'email': email, 'password': password},
    );
  }

  /// POST /api/buyer-auth/register
  Future<Map<String, dynamic>?> registerBuyer({
    required String name,
    required String email,
    required String password,
    required String phone,
    String? country,
    String? city,
  }) async {
    return _authPost(
      endpoints: ['/buyer-auth/register', '/auth/buyer/register', '/register'],
      data: {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        if (country != null) 'country': country,
        if (city != null) 'city': city,
      },
      exposeErrors: true,
    );
  }

  /// POST /api/provider-auth/login
  Future<Map<String, dynamic>?> loginProvider({
    required String email,
    required String password,
  }) async {
    return _authPost(
      endpoints: ['/provider-auth/login', '/auth/provider/login'],
      data: {'email': email, 'password': password},
    );
  }

  /// POST /api/{buyer|provider}-auth/google — exchange a Google ID token for
  /// a verified Vera session. The account is created on first sign-in.
  Future<Map<String, dynamic>?> loginWithGoogle({
    required String idToken,
    required String role,
  }) async {
    try {
      final res = await _dio.post(
        '/$role-auth/google',
        data: {'idToken': idToken},
      );
      // ignore: avoid_print
      print('[loginWithGoogle] status=${res.statusCode} data=${res.data}');
      if (res.statusCode == 200 || res.statusCode == 201) {
        final resData = res.data;
        final token =
            resData['token'] ??
            resData['access_token'] ??
            resData['data']?['token'] ??
            resData['data']?['access_token'];
        if (token != null) {
          final isProvider = role == 'provider';
          final tokenStr = token.toString();
          if (isProvider) {
            await setProviderToken(tokenStr);
          } else {
            await setToken(tokenStr);
          }
        }
        return resData is Map<String, dynamic> ? resData : {'data': resData};
      }
    } on DioException catch (e) {
      // ignore: avoid_print
      print(
        '[loginWithGoogle] DioException: status=${e.response?.statusCode} data=${e.response?.data} msg=${e.message}',
      );
    } catch (e) {
      // ignore: avoid_print
      print('[loginWithGoogle] Error: $e');
    }
    return null;
  }

  /// POST /api/{buyer|provider}-auth/apple — exchange an Apple identity token
  /// for a verified Vera session. The account is created on first sign-in.
  /// `nonce` must be the same random value embedded in the Apple request.
  Future<Map<String, dynamic>?> loginWithApple({
    required String idToken,
    required String role,
    String? nonce,
    String? name,
  }) async {
    try {
      final res = await _dio.post(
        '/$role-auth/apple',
        data: {
          'idToken': idToken,
          if (nonce != null && nonce.isNotEmpty) 'nonce': nonce,
          if (name != null && name.isNotEmpty) 'name': name,
        },
      );
      // ignore: avoid_print
      print('[loginWithApple] status=${res.statusCode} data=${res.data}');
      if (res.statusCode == 200 || res.statusCode == 201) {
        final resData = res.data;
        final token =
            resData['token'] ??
            resData['access_token'] ??
            resData['data']?['token'] ??
            resData['data']?['access_token'];
        if (token != null) {
          final isProvider = role == 'provider';
          final tokenStr = token.toString();
          if (isProvider) {
            await setProviderToken(tokenStr);
          } else {
            await setToken(tokenStr);
          }
        }
        return resData is Map<String, dynamic> ? resData : {'data': resData};
      }
    } on DioException catch (e) {
      // ignore: avoid_print
      print(
        '[loginWithApple] DioException: status=${e.response?.statusCode} data=${e.response?.data} msg=${e.message}',
      );
    } catch (e) {
      // ignore: avoid_print
      print('[loginWithApple] Error: $e');
    }
    return null;
  }

  /// POST /api/provider-auth/register
  Future<Map<String, dynamic>?> registerProvider({
    required String name,
    required String email,
    required String password,
    required String phone,
    String? businessName,
    String? category,
  }) async {
    return _authPost(
      endpoints: ['/provider-auth/register', '/auth/provider/register'],
      data: {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        if (businessName != null) 'business_name': businessName,
        if (category != null) 'category': category,
      },
      exposeErrors: true,
    );
  }

  /// POST /api/auth/admin/login
  Future<Map<String, dynamic>?> loginAdmin({
    required String email,
    required String password,
  }) async {
    return _authPost(
      endpoints: ['/auth/admin/login', '/admin/login'],
      data: {'email': email, 'password': password},
    );
  }

  /// POST /api/auth/staff/login
  Future<Map<String, dynamic>?> loginStaff({
    required String email,
    required String password,
  }) async {
    return _authPost(
      endpoints: ['/auth/staff/login', '/staff/login'],
      data: {'email': email, 'password': password},
    );
  }

  /// POST /api/auth/logout (any role). Best-effort: clears local tokens even
  /// if the network call fails.
  Future<bool> logout() async {
    cancelActiveRequests();
    try {
      await _dio.post('/buyer-auth/logout');
    } catch (_) {}
    try {
      await _dio.post('/provider-auth/logout');
    } catch (_) {}
    await clearToken();
    await clearProviderToken();
    return true;
  }

  /// POST /api/auth/forgot-password
  Future<bool> forgotPassword(String email) async {
    try {
      final endpoints = [
        '/auth/forgot-password',
        '/auth/password/forgot',
        '/forgot-password',
      ];
      for (final ep in endpoints) {
        try {
          final res = await _dio.post(ep, data: {'email': email});
          if (res.statusCode == 200 || res.statusCode == 201) return true;
        } catch (_) {}
      }
    } catch (_) {}
    return false;
  }

  /// POST /api/auth/reset-password
  Future<bool> resetPassword({
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final endpoints = ['/auth/reset-password', '/auth/password/reset'];
      for (final ep in endpoints) {
        try {
          final res = await _dio.post(
            ep,
            data: {
              'token': token,
              'password': password,
              'password_confirmation': passwordConfirmation,
            },
          );
          if (res.statusCode == 200) return true;
        } catch (_) {}
      }
    } catch (_) {}
    return false;
  }

  /// POST /api/auth/otp/send — send (or resend) an email verification code.
  ///
  /// Purposes: register_buyer / register_provider / login_buyer /
  /// login_provider / reset_password / change_email_buyer /
  /// change_email_provider. Returns the raw body (including error responses)
  /// so callers can surface cooldown / rate-limit messages.
  Future<Map<String, dynamic>?> sendOtp({
    required String purpose,
    required String email,
    String? name,
    String? role,
  }) async {
    try {
      final res = await _dio.post(
        '/auth/otp/send',
        data: {
          'purpose': purpose,
          'email': email,
          if (name != null && name.isNotEmpty) 'name': name,
          if (role != null && role.isNotEmpty) 'role': role,
        },
      );
      if (res.data is Map<String, dynamic>) {
        return res.data as Map<String, dynamic>;
      }
      return {'success': true};
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) return data;
      return null;
    } catch (e) {
      debugPrint('VeraAPI sendOtp error: $e');
      return null;
    }
  }

  /// PUT /api/auth/otp/send — verify a code and complete the pending flow.
  ///
  /// Persists a returned session token for login/register/change-email flows.
  /// reset_password instead returns a short-lived `resetToken` that must be
  /// passed to [confirmPasswordReset]; it is never persisted.
  Future<Map<String, dynamic>?> verifyOtp({
    required String purpose,
    required String email,
    required String code,
    String? role,
  }) async {
    try {
      final res = await _dio.put(
        '/auth/otp/send',
        data: {
          'purpose': purpose,
          'email': email,
          'code': code,
          if (role != null && role.isNotEmpty) 'role': role,
        },
      );
      if (res.data is Map<String, dynamic>) {
        final data = res.data as Map<String, dynamic>;
        final token = data['token']?.toString();
        if (token != null && token.isNotEmpty) {
          final isProvider = purpose.endsWith('provider');
          if (isProvider) {
            await setProviderToken(token);
          } else {
            await setToken(token);
          }
        }
        return data;
      }
      return {'success': true};
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) return data;
      return null;
    } catch (e) {
      debugPrint('VeraAPI verifyOtp error: $e');
      return null;
    }
  }

  /// POST /api/auth/password-reset/request — request a reset code. Responds
  /// generically whether or not the account exists (no enumeration).
  Future<Map<String, dynamic>?> requestPasswordReset({
    required String email,
    String? role,
  }) async {
    try {
      final res = await _dio.post(
        '/auth/password-reset/request',
        data: {
          'email': email,
          if (role != null && role.isNotEmpty) 'role': role,
        },
      );
      if (res.data is Map<String, dynamic>) {
        return res.data as Map<String, dynamic>;
      }
      return {'success': true};
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) return data;
      return null;
    } catch (e) {
      debugPrint('VeraAPI requestPasswordReset error: $e');
      return null;
    }
  }

  /// POST /api/auth/password-reset/confirm — set a new password using the
  /// short-lived token returned by [verifyOtp] for the reset_password purpose.
  Future<Map<String, dynamic>?> confirmPasswordReset({
    required String resetToken,
    required String newPassword,
  }) async {
    try {
      final res = await _dio.post(
        '/auth/password-reset/confirm',
        data: {'token': resetToken, 'newPassword': newPassword},
      );
      if (res.data is Map<String, dynamic>) {
        return res.data as Map<String, dynamic>;
      }
      return {'success': true};
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) return data;
      return null;
    } catch (e) {
      debugPrint('VeraAPI confirmPasswordReset error: $e');
      return null;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GROUP 10: BUYER PROFILE
  // ══════════════════════════════════════════════════════════════════════════

  /// GET /api/buyer/profile
  Future<VeraUser?> fetchProfile() async {
    try {
      final endpoints = ['/buyer/profile', '/user/profile', '/profile', '/me'];
      for (final ep in endpoints) {
        try {
          final res = await _dio.get(ep);
          if (res.statusCode == 200 && res.data != null) {
            return VeraUser.fromJson(
              res.data is Map<String, dynamic> ? res.data : {'data': res.data},
            );
          }
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('VeraAPI profile: $e');
    }
    return null;
  }

  /// Provider profile – tries provider endpoints first.
  Future<VeraUser?> fetchProviderProfile() async {
    try {
      final endpoints = [
        '/provider/profile',
        '/provider/me',
        '/provider/dashboard/profile',
      ];
      for (final ep in endpoints) {
        try {
          final res = await _dio.get(ep);
          if (res.statusCode == 200 && res.data != null) {
            return VeraUser.fromJson(
              res.data is Map<String, dynamic> ? res.data : {'data': res.data},
            );
          }
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('VeraAPI provider profile: $e');
    }
    return null;
  }

  /// PUT /api/buyer/profile
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      final res = await _dio
          .put('/buyer/profile', data: data)
          .timeout(const Duration(seconds: 20));
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('VeraAPI updateProfile: $e');
    }
    return false;
  }

  Future<bool> updateProviderProfile(Map<String, dynamic> data) async {
    try {
      final endpoints = ['/provider/profile', '/provider/me'];
      for (final ep in endpoints) {
        try {
          final res = await _dio.patch(ep, data: data);
          if (res.statusCode == 200) return true;
        } catch (_) {}
      }
    } catch (_) {}
    return false;
  }

  Future<String?> uploadProviderAvatar(String filePath) async {
    if (kIsWeb) return null;
    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(filePath, filename: 'avatar.jpg'),
    });
    final endpoints = ['/provider/profile/avatar', '/provider/avatar'];
    for (final ep in endpoints) {
      try {
        final res = await _dio.post(ep, data: formData);
        if (res.statusCode == 200 || res.statusCode == 201) {
          final data = res.data;
          if (data is Map) {
            final url =
                data['avatarUrl'] ??
                data['avatar'] ??
                data['url'] ??
                data['path'] ??
                (data['data'] is Map
                    ? (data['data'] as Map)['avatarUrl'] ??
                          (data['data'] as Map)['url']
                    : null);
            if (url != null && url.toString().isNotEmpty) {
              return url.toString();
            }
          }
          debugPrint(
            'VeraAPI uploadProviderAvatar $ep: no url in response: $data',
          );
        } else {
          debugPrint(
            'VeraAPI uploadProviderAvatar $ep failed: HTTP ${res.statusCode} ${res.data}',
          );
        }
      } catch (e) {
        debugPrint('VeraAPI uploadProviderAvatar $ep error: $e');
      }
    }
    return null;
  }

  /// POST /api/buyer/profile/avatar (upload)
  /// Returns the resolved avatar URL on success, or null on failure.
  Future<String?> updateAvatar(String filePath) async {
    // File-path based upload is not supported on Flutter Web
    if (kIsWeb) return null;
    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(filePath, filename: 'avatar.jpg'),
    });
    final endpoints = [
      '/buyer/profile/avatar',
      '/user/profile/avatar',
      '/upload/avatar',
    ];
    for (final ep in endpoints) {
      try {
        final res = await _dio.post(ep, data: formData);
        if (res.statusCode == 200 || res.statusCode == 201) {
          final data = res.data;
          if (data is Map) {
            final url =
                data['avatarUrl'] ??
                data['avatar'] ??
                data['url'] ??
                data['path'] ??
                (data['data'] is Map
                    ? (data['data'] as Map)['avatarUrl'] ??
                          (data['data'] as Map)['url']
                    : null);
            if (url != null && url.toString().isNotEmpty) {
              return url.toString();
            }
          }
          debugPrint('VeraAPI updateAvatar $ep: no url in response: $data');
        } else {
          debugPrint(
            'VeraAPI updateAvatar $ep failed: HTTP ${res.statusCode} ${res.data}',
          );
        }
      } catch (e) {
        debugPrint('VeraAPI updateAvatar $ep error: $e');
      }
    }
    return null;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GROUP 4: DASHBOARD (Admin + Provider)
  // ══════════════════════════════════════════════════════════════════════════

  /// GET /api/dashboard
  Future<VeraDashboardStats?> fetchDashboard() async {
    try {
      final endpoints = [
        '/dashboard',
        '/admin/dashboard',
        '/buyer/dashboard',
        '/provider/dashboard',
      ];
      for (final ep in endpoints) {
        try {
          final res = await _dio.get(ep);
          if (res.statusCode == 200 && res.data != null) {
            return VeraDashboardStats.fromJson(
              res.data is Map<String, dynamic> ? res.data : {'data': res.data},
            );
          }
        } catch (_) {}
      }
    } catch (_) {}
    return null;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GROUP 42: HOME
  // ══════════════════════════════════════════════════════════════════════════

  /// GET /api/home/banners
  Future<List<VeraBanner>> fetchBanners() async {
    try {
      final endpoints = [
        '/home/banners',
        '/banners',
        '/promotions',
        '/sliders',
      ];
      for (final ep in endpoints) {
        try {
          final res = await _dio.get(ep);
          final data = _extractList(res.data);
          if (data.isNotEmpty) {
            return data.map((e) => VeraBanner.fromJson(e)).toList();
          }
        } catch (_) {}
      }
    } catch (_) {}
    return [];
  }

  /// GET /api/home/banners?type=<bannerType>
  Future<List<VeraBanner>> fetchBannersByType(String bannerType) async {
    try {
      final res = await _dio.get(
        '/home/banners',
        queryParameters: {'type': bannerType},
      );
      final data = _extractList(res.data);
      return data.map((e) => VeraBanner.fromJson(e)).toList();
    } catch (_) {}
    return [];
  }

  /// GET /api/home/data (featured services) + fallbacks
  Future<List<VeraListing>> fetchFeaturedListings() async {
    try {
      final endpoints = [
        '/home/data',
        '/home/featured',
        '/listings?featured=1',
        '/services?featured=1',
        '/home/services',
      ];
      for (final ep in endpoints) {
        try {
          final res = await _dio.get(ep);
          final data = _extractList(res.data, 'featuredServices');
          if (data.isNotEmpty) {
            return data.map((e) => VeraListing.fromJson(e)).toList();
          }
        } catch (_) {}
      }
    } catch (_) {}
    return [];
  }

  /// GET /api/home/stats
  Future<Map<String, dynamic>?> fetchHomeStats() async {
    try {
      final res = await _dio.get('/home/stats');
      if (res.statusCode == 200) {
        return res.data is Map<String, dynamic> ? res.data : null;
      }
    } catch (_) {}
    return null;
  }

  /// GET /api/home/data -> bestSellers section
  Future<List<VeraListing>> fetchBestSellers() =>
      _fetchHomeSection('bestSellers');

  /// GET /api/home/data -> mostViewed section
  Future<List<VeraListing>> fetchMostViewed() =>
      _fetchHomeSection('mostViewed');

  Future<List<VeraListing>> _fetchHomeSection(String key) async {
    try {
      final res = await _dio.get('/home/data');
      final data = _extractList(res.data, key);
      if (data.isNotEmpty) {
        return data.map((e) => VeraListing.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GROUP 27-28: CATEGORIES & SUB-CATEGORIES
  // ══════════════════════════════════════════════════════════════════════════

  /// GET /api/categories (public)
  Future<List<VeraCategory>> fetchCategories({String? type}) async {
    try {
      final params = <String, dynamic>{if (type != null) 'type': type};
      final endpoints = [
        '/public/categories',
        '/categories',
        '/home/categories',
        '/home/data',
      ];
      for (final ep in endpoints) {
        try {
          final res = await _dio.get(ep, queryParameters: params);
          final data = _extractList(res.data);
          if (data.isNotEmpty) {
            return data.map((e) => VeraCategory.fromJson(e)).toList();
          }
        } catch (_) {}
      }
    } catch (_) {}
    return [];
  }

  /// GET /api/categories/{id}
  Future<VeraCategory?> fetchCategory(String id) async {
    try {
      final res = await _dio.get('/categories/$id');
      if (res.statusCode == 200 && res.data != null) {
        final data = res.data is Map<String, dynamic>
            ? res.data
            : {'data': res.data};
        final item = data['data'] ?? data;
        return VeraCategory.fromJson(item);
      }
    } catch (_) {}
    return null;
  }

  /// GET /api/public/categories?slug=X&include_subs=true
  /// Returns the category plus its sub-categories in one call.
  Future<({VeraCategory category, List<VeraCategory> subs})?>
  fetchCategoryWithSubs(String slug) async {
    try {
      final res = await _dio.get(
        '/public/categories',
        queryParameters: {'slug': slug, 'include_subs': 'true'},
      );
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        final data = res.data as Map<String, dynamic>;
        final catRaw = data['category'];
        final subsRaw = data['subCategories'];
        if (catRaw is Map<String, dynamic>) {
          final category = VeraCategory.fromJson(catRaw);
          final subs = <VeraCategory>[];
          if (subsRaw is List) {
            for (final s in subsRaw) {
              if (s is Map<String, dynamic>) {
                final sub = VeraCategory.fromJson(s);
                if (sub.name.isNotEmpty && sub.slug.isNotEmpty) {
                  subs.add(sub);
                }
              }
            }
          }
          return (category: category, subs: subs);
        }
      }
    } catch (_) {}
    return null;
  }

  /// GET /api/sub-categories
  Future<List<VeraCategory>> fetchSubCategories({String? categoryId}) async {
    try {
      final params = <String, dynamic>{
        if (categoryId != null) 'category_id': categoryId,
      };
      final endpoints = [
        '/sub-categories',
        '/subcategories',
        '/categories/sub',
      ];
      for (final ep in endpoints) {
        try {
          final res = await _dio.get(ep, queryParameters: params);
          final data = _extractList(res.data);
          if (data.isNotEmpty) {
            return data.map((e) => VeraCategory.fromJson(e)).toList();
          }
        } catch (_) {}
      }
    } catch (_) {}
    return [];
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GROUP 29-30: SERVICES (Admin + Public)
  // ══════════════════════════════════════════════════════════════════════════

  /// GET /api/services (public)
  Future<List<VeraService>> fetchServices({
    String? category,
    int page = 1,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        if (category != null && category != 'All') 'category': category,
      };
      final endpoints = [
        '/public/services',
        '/services',
        '/services/public',
        '/clinics',
        '/salons',
      ];
      for (final ep in endpoints) {
        try {
          final res = await _dio.get(ep, queryParameters: params);
          final data = _extractList(res.data);
          if (data.isNotEmpty) {
            return data.map((e) => VeraService.fromJson(e)).toList();
          }
        } catch (_) {}
      }
    } catch (_) {}
    return [];
  }

  /// GET /api/services/{id}
  Future<VeraService?> fetchServiceById(String id) async {
    try {
      final endpoints = ['/services/$id', '/services/public/$id'];
      for (final ep in endpoints) {
        try {
          final res = await _dio.get(ep);
          if (res.statusCode == 200 && res.data != null) {
            final data = res.data is Map<String, dynamic>
                ? res.data
                : {'data': res.data};
            final payload = data['data'] ?? data['service'] ?? data;
            return VeraService.fromJson(
              payload is Map<String, dynamic> ? payload : {},
            );
          }
        } catch (_) {}
      }
    } catch (_) {}
    return null;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GROUP 31-32: PROVIDERS (Admin + Public)
  // ══════════════════════════════════════════════════════════════════════════

  /// GET /api/providers (public)
  Future<List<VeraProvider>> fetchTopProviders({int limit = 10}) async {
    try {
      final params = <String, dynamic>{'limit': limit, 'top': 1};
      final endpoints = [
        '/public/providers',
        '/providers',
        '/providers/public',
        '/stores',
        '/vendors',
      ];
      for (final ep in endpoints) {
        try {
          final res = await _dio.get(ep, queryParameters: params);
          final data = _extractList(res.data);
          if (data.isNotEmpty) {
            return data.map((e) => VeraProvider.fromJson(e)).toList();
          }
        } catch (_) {}
      }
    } catch (_) {}
    return [];
  }

  /// GET /api/providers/{id}
  Future<VeraProvider?> fetchProviderById(String id) async {
    try {
      final endpoints = [
        '/public/providers/$id',
        '/providers/$id',
        '/providers/public/$id',
      ];
      for (final ep in endpoints) {
        try {
          final res = await _dio.get(ep);
          if (res.statusCode == 200 && res.data != null) {
            final payload = res.data is Map<String, dynamic>
                ? res.data as Map<String, dynamic>
                : <String, dynamic>{};
            final provider =
                payload['provider'] ??
                payload['data']?['provider'] ??
                payload['data'] ??
                payload;
            if (provider is Map<String, dynamic>) {
              _publicServicesCache[id] = _parseProviderServices(
                payload['services'],
              );
              return VeraProvider.fromJson(provider);
            }
          }
        } catch (_) {}
      }
    } catch (_) {}
    return null;
  }

  /// GET /api/providers/{id}/services
  Future<List<VeraService>> fetchProviderServices(String providerId) async {
    final cached = _publicServicesCache[providerId];
    if (cached != null) return cached;
    try {
      final response = await _dio.get('/public/providers/$providerId');
      final payload = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final services = _parseProviderServices(payload['services']);
      _publicServicesCache[providerId] = services;
      return services;
    } catch (_) {}
    return [];
  }

  List<VeraService> _parseProviderServices(Object? rawServices) {
    if (rawServices is! List) return [];
    final services = <VeraService>[];
    for (final raw in rawServices) {
      if (raw is! Map<String, dynamic>) continue;
      try {
        services.add(VeraService.fromJson(raw));
      } catch (_) {}
    }
    return services;
  }

  Future<bool> followProvider(
    String providerId, {
    required bool follow,
    required String followerId,
  }) async {
    final endpoints = [
      '/public/providers/$providerId/follow',
      '/providers/$providerId/follow',
      '/providers/$providerId/followers',
      '/follows/providers/$providerId',
    ];
    for (final endpoint in endpoints) {
      try {
        final response = follow
            ? await _dio.post(endpoint, data: {'followerId': followerId})
            : await _dio.delete(endpoint, data: {'followerId': followerId});
        if (response.statusCode != null &&
            response.statusCode! >= 200 &&
            response.statusCode! < 300) {
          return true;
        }
      } catch (_) {}
    }
    return false;
  }

  Future<bool> isFollowingProvider(String providerId) async {
    try {
      final response = await _dio.get('/public/providers/$providerId/follow');
      return response.data is Map<String, dynamic> &&
          response.data['isFollowing'] == true;
    } catch (_) {
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GROUP 44: SEARCH
  // ══════════════════════════════════════════════════════════════════════════

  /// GET /api/search
  Future<List<VeraListing>> search({
    required String query,
    String category = 'all',
    int page = 1,
    Map<String, dynamic>? filters,
  }) async {
    try {
      final params = <String, dynamic>{
        'q': query,
        'page': page,
        if (category != 'all' && category.isNotEmpty) 'category': category,
        ...?filters,
      };
      final endpoints = ['/search', '/search/all', '/listings/search'];
      for (final ep in endpoints) {
        try {
          final res = await _dio.get(ep, queryParameters: params);
          final data = _extractList(res.data);
          if (data.isNotEmpty) {
            return data.map((e) => VeraListing.fromJson(e)).toList();
          }
        } catch (_) {}
      }
    } catch (_) {}
    return [];
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GROUP 49: CART
  // ══════════════════════════════════════════════════════════════════════════

  /// GET /api/cart
  Future<List<VeraCartItem>> fetchCart() async {
    try {
      final endpoints = ['/cart', '/user/cart', '/buyer/cart'];
      for (final ep in endpoints) {
        try {
          final res = await _dio.get(ep);
          final data = _extractList(res.data);
          if (data.isNotEmpty) {
            return data.map((e) => VeraCartItem.fromJson(e)).toList();
          }
        } catch (_) {}
      }
    } catch (_) {}
    return [];
  }

  /// POST /api/cart/add
  Future<bool> addToCart({
    required String itemId,
    required String itemType,
    int quantity = 1,
  }) async {
    try {
      final endpoints = ['/cart/add', '/cart', '/buyer/cart/add'];
      for (final ep in endpoints) {
        try {
          final res = await _dio.post(
            ep,
            data: {'item_id': itemId, 'type': itemType, 'quantity': quantity},
          );
          if (res.statusCode == 200 || res.statusCode == 201) return true;
        } catch (_) {}
      }
    } catch (_) {}
    return false;
  }

  /// DELETE /api/cart/{id}
  Future<bool> removeFromCart(String cartItemId) async {
    try {
      final endpoints = [
        '/cart/$cartItemId',
        '/cart/remove/$cartItemId',
        '/buyer/cart/$cartItemId',
      ];
      for (final ep in endpoints) {
        try {
          final res = await _dio.delete(ep);
          if (res.statusCode == 200 || res.statusCode == 204) return true;
        } catch (_) {}
      }
    } catch (_) {}
    return false;
  }

  /// PUT /api/cart/{id} — update quantity
  Future<bool> updateCartQuantity(String cartItemId, int quantity) async {
    try {
      final endpoints = ['/cart/$cartItemId', '/buyer/cart/$cartItemId'];
      for (final ep in endpoints) {
        try {
          final res = await _dio.put(ep, data: {'quantity': quantity});
          if (res.statusCode == 200) return true;
        } catch (_) {}
      }
    } catch (_) {}
    return false;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GROUP 11 + 23-26: ORDERS (Buyer + Management + Tracking + Public)
  // ══════════════════════════════════════════════════════════════════════════

  /// GET /api/buyer/orders
  Future<List<VeraOrder>> fetchOrders({String? status, int page = 1}) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        if (status != null) 'status': status,
      };
      final endpoints = [
        '/buyer/orders',
        '/user/orders',
        '/orders/my',
        '/orders',
      ];
      for (final ep in endpoints) {
        try {
          final res = await _dio.get(ep, queryParameters: params);
          final data = _extractList(res.data);
          if (data.isNotEmpty) {
            return data.map((e) => VeraOrder.fromJson(e)).toList();
          }
        } catch (_) {}
      }
    } catch (_) {}
    return [];
  }

  /// GET /api/orders/{id}
  Future<VeraOrder?> fetchOrderById(String orderId) async {
    try {
      final endpoints = ['/orders/$orderId', '/buyer/orders/$orderId'];
      for (final ep in endpoints) {
        try {
          final res = await _dio.get(ep);
          if (res.statusCode == 200 && res.data != null) {
            final data = res.data is Map<String, dynamic>
                ? res.data
                : {'data': res.data};
            return VeraOrder.fromJson(data['data'] ?? data);
          }
        } catch (_) {}
      }
    } catch (_) {}
    return null;
  }

  /// POST /api/buyer/orders (checkout / place order)
  Future<Map<String, dynamic>?> placeOrder({
    required String paymentMethod,
    String? promoCode,
    String? address,
    List<Map<String, dynamic>>? items,
    double? subtotal,
    double? discount,
    double? deliveryFee,
    double? vat,
    double? total,
    String? currency,
    String? orderType,
    int? providerId,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      final endpoints = [
        '/buyer/orders',
        '/orders',
        '/checkout',
        '/cart/checkout',
      ];
      for (final ep in endpoints) {
        try {
          final res = await _dio.post(
            ep,
            data: {
              'payment_method': paymentMethod,
              'paymentMethod': paymentMethod,
              if (promoCode != null && promoCode.isNotEmpty)
                'promo_code': promoCode,
              if (address != null) 'address': address,
              if (items != null) 'items': items,
              if (subtotal != null) 'subtotal': subtotal,
              if (discount != null) 'discount': discount,
              if (deliveryFee != null) 'delivery_fee': deliveryFee,
              if (vat != null) 'vat': vat,
              if (total != null) 'total': total,
              if (currency != null) 'currency': currency,
              if (orderType != null) 'order_type': orderType,
              if (providerId != null) 'provider_id': providerId,
              ...?extraData,
            },
          );
          if (res.statusCode == 200 || res.statusCode == 201) {
            return res.data is Map<String, dynamic>
                ? res.data
                : {'success': true};
          }
        } catch (_) {}
      }
    } catch (_) {}
    return null;
  }

  /// POST /api/orders/{id}/cancel
  Future<bool> cancelOrder(String orderId) async {
    try {
      final endpoints = [
        '/orders/$orderId/cancel',
        '/buyer/orders/$orderId/cancel',
      ];
      for (final ep in endpoints) {
        try {
          final res = await _dio.post(ep);
          if (res.statusCode == 200) return true;
        } catch (_) {}
      }
    } catch (_) {}
    return false;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GROUP 24-25: ORDER TRACKING
  // ══════════════════════════════════════════════════════════════════════════

  /// GET /api/orders/{id}/tracking
  Future<Map<String, dynamic>?> fetchOrderTracking(String orderId) async {
    try {
      final endpoints = [
        '/orders/$orderId/tracking',
        '/orders/tracking/$orderId',
        '/order-tracking/$orderId',
      ];
      for (final ep in endpoints) {
        try {
          final res = await _dio.get(ep);
          if (res.statusCode == 200 && res.data != null) {
            return res.data is Map<String, dynamic>
                ? res.data
                : {'data': res.data};
          }
        } catch (_) {}
      }
    } catch (_) {}
    return null;
  }

  /// GET /api/order-tracking/public/{trackingNumber}
  Future<Map<String, dynamic>?> fetchPublicOrderTracking(
    String trackingNumber,
  ) async {
    try {
      final endpoints = [
        '/order-tracking/public/$trackingNumber',
        '/track/$trackingNumber',
        '/tracking/$trackingNumber',
      ];
      for (final ep in endpoints) {
        try {
          final res = await _dio.get(ep);
          if (res.statusCode == 200 && res.data != null) {
            return res.data is Map<String, dynamic>
                ? res.data
                : {'data': res.data};
          }
        } catch (_) {}
      }
    } catch (_) {}
    return null;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BOOKINGS (from Services flow)
  // ══════════════════════════════════════════════════════════════════════════

  /// GET /api/buyer/bookings
  Future<List<VeraBooking>> fetchMyBookings({String? status}) async {
    try {
      final params = <String, dynamic>{if (status != null) 'status': status};
      final endpoints = [
        '/buyer/bookings',
        '/user/bookings',
        '/my-bookings',
        '/bookings/my',
      ];
      for (final ep in endpoints) {
        try {
          final res = await _dio.get(ep, queryParameters: params);
          final data = _extractList(res.data);
          if (data.isNotEmpty) {
            return data.map((e) => VeraBooking.fromJson(e)).toList();
          }
        } catch (_) {}
      }
    } catch (_) {}
    return [];
  }

  /// POST /api/bookings
  Future<Map<String, dynamic>?> createBooking({
    required String serviceId,
    required String date,
    required String time,
    String? notes,
    String? serviceName,
    String? providerId,
    String? providerName,
    String? category,
    double? amount,
    String? currency,
  }) async {
    try {
      final endpoints = ['/bookings', '/appointments', '/buyer/bookings'];
      for (final ep in endpoints) {
        try {
          final res = await _dio.post(
            ep,
            data: {
              'service_id': serviceId,
              'date': date,
              'time': time,
              if (notes != null) 'notes': notes,
              if (serviceName != null) 'service_name': serviceName,
              if (providerId != null) 'provider_id': providerId,
              if (providerName != null) 'provider_name': providerName,
              if (category != null) 'category': category,
              if (amount != null) 'amount': amount,
              if (currency != null) 'currency': currency,
            },
          );
          if (res.statusCode == 200 || res.statusCode == 201) {
            return res.data is Map<String, dynamic>
                ? res.data
                : {'success': true};
          }
        } catch (_) {}
      }
    } catch (_) {}
    return null;
  }

  /// GET /api/public/bookings/{bookingId}
  Future<Map<String, dynamic>?> fetchPublicBooking(String bookingId) async {
    try {
      final res = await _dio.get('/public/bookings/$bookingId');
      if (res.statusCode == 200) {
        final data = res.data;
        if (data is Map<String, dynamic>) {
          if (data['success'] == true) {
            return data['booking'] is Map<String, dynamic>
                ? data['booking'] as Map<String, dynamic>
                : data;
          }
          return data;
        }
      }
    } catch (_) {}
    return null;
  }

  /// POST /api/buyer/applications (apply for a job)
  Future<Map<String, dynamic>?> applyForJob({
    required String jobId,
    required String fullName,
    String? email,
    String? phone,
    String? location,
    String? resumeUrl,
    String? coverLetter,
    String? noticePeriod,
  }) async {
    try {
      final body = {
        'job_service_id': jobId,
        'full_name': fullName,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (location != null) 'location': location,
        if (resumeUrl != null) 'resume_url': resumeUrl,
        if (coverLetter != null) 'cover_letter': coverLetter,
        if (noticePeriod != null) 'notice_period': noticePeriod,
      };
      final endpoints = ['/buyer/applications', '/applications', '/jobs/apply'];
      for (final ep in endpoints) {
        try {
          final res = await _dio.post(ep, data: body);
          if (res.statusCode == 200 || res.statusCode == 201) {
            return res.data is Map
                ? Map<String, dynamic>.from(res.data)
                : {'success': true};
          }
        } catch (_) {}
      }
    } catch (_) {}
    return null;
  }

  /// GET /api/my/applications (job applications)
  Future<List<Map<String, dynamic>>> fetchApplications() async {
    try {
      final endpoints = [
        '/my/applications',
        '/buyer/applications',
        '/applications',
        '/jobs/my-applications',
      ];
      for (final ep in endpoints) {
        try {
          final res = await _dio.get(ep);
          final data = _extractList(res.data);
          if (data.isNotEmpty) return data;
        } catch (_) {}
      }
    } catch (_) {}
    return [];
  }

  /// POST /api/bookings/{id}/cancel
  Future<bool> cancelBooking(String bookingId) async {
    try {
      final endpoints = [
        '/bookings/$bookingId/cancel',
        '/appointments/$bookingId/cancel',
        '/buyer/bookings/$bookingId/cancel',
      ];
      for (final ep in endpoints) {
        try {
          final res = await _dio.post(ep);
          if (res.statusCode == 200) return true;
        } catch (_) {}
      }
    } catch (_) {}
    return false;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GROUP 12: BUYER WALLET
  // ══════════════════════════════════════════════════════════════════════════

  /// GET /api/buyer/wallet
  Future<VeraWallet?> fetchWallet() async {
    try {
      final endpoints = ['/buyer/wallet', '/user/wallet', '/wallet'];
      for (final ep in endpoints) {
        try {
          final res = await _dio.get(ep);
          if (res.statusCode == 200 && res.data != null) {
            return VeraWallet.fromJson(
              res.data is Map<String, dynamic> ? res.data : {'data': res.data},
            );
          }
        } catch (_) {}
      }
    } catch (_) {}
    return null;
  }

  /// POST /api/buyer/wallet/topup
  Future<Map<String, dynamic>?> topUpWallet({
    required double amount,
    required String paymentMethod,
  }) async {
    try {
      final endpoints = ['/buyer/wallet/topup', '/wallet/topup', '/wallet/add'];
      for (final ep in endpoints) {
        try {
          final res = await _dio.post(
            ep,
            data: {'amount': amount, 'payment_method': paymentMethod},
          );
          if (res.statusCode == 200 || res.statusCode == 201) {
            return res.data is Map<String, dynamic>
                ? res.data
                : {'success': true};
          }
        } catch (_) {}
      }
    } catch (_) {}
    return null;
  }

  /// GET /api/buyer/wallet/transactions
  Future<List<VeraWalletTransaction>> fetchWalletTransactions() async {
    try {
      final endpoints = [
        '/buyer/wallet/transactions',
        '/wallet/transactions',
        '/wallet/history',
      ];
      for (final ep in endpoints) {
        try {
          final res = await _dio.get(ep);
          final data = _extractList(res.data);
          if (data.isNotEmpty) {
            return data.map((e) => VeraWalletTransaction.fromJson(e)).toList();
          }
        } catch (_) {}
      }
    } catch (_) {}
    return [];
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GROUP 13: BUYER BNPL (Buy Now Pay Later)
  // ══════════════════════════════════════════════════════════════════════════

  /// GET /api/buyer/bnpl/eligibility
  Future<Map<String, dynamic>?> fetchBnplEligibility() async {
    try {
      final endpoints = [
        '/buyer/bnpl/eligibility',
        '/bnpl/eligibility',
        '/bnpl/check',
      ];
      for (final ep in endpoints) {
        try {
          final res = await _dio.get(ep);
          if (res.statusCode == 200) {
            return res.data is Map<String, dynamic> ? res.data : null;
          }
        } catch (_) {}
      }
    } catch (_) {}
    return null;
  }

  /// POST /api/buyer/bnpl/apply
  Future<Map<String, dynamic>?> applyBnpl({
    required String orderId,
    required int installments,
  }) async {
    try {
      final endpoints = ['/buyer/bnpl/apply', '/bnpl/apply'];
      for (final ep in endpoints) {
        try {
          final res = await _dio.post(
            ep,
            data: {'order_id': orderId, 'installments': installments},
          );
          if (res.statusCode == 200 || res.statusCode == 201) {
            return res.data is Map<String, dynamic>
                ? res.data
                : {'success': true};
          }
        } catch (_) {}
      }
    } catch (_) {}
    return null;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GROUP 48: LOYALTY
  // ══════════════════════════════════════════════════════════════════════════

  /// GET /api/loyalty
  Future<VeraLoyalty?> fetchLoyalty() async {
    try {
      final endpoints = [
        '/buyer/loyalty',
        '/loyalty',
        '/buyer/loyalty',
        '/user/loyalty',
        '/points',
      ];
      for (final ep in endpoints) {
        try {
          final res = await _dio.get(ep);
          if (res.statusCode == 200 && res.data != null) {
            return VeraLoyalty.fromJson(
              res.data is Map<String, dynamic> ? res.data : {'data': res.data},
            );
          }
        } catch (_) {}
      }
    } catch (_) {}
    return null;
  }

  /// POST /api/loyalty/redeem
  Future<Map<String, dynamic>?> redeemLoyaltyPoints({
    required int points,
    String? orderId,
  }) async {
    try {
      final res = await _dio.post(
        '/buyer/loyalty/redeem',
        data: {'points': points, if (orderId != null) 'order_id': orderId},
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        return res.data is Map<String, dynamic> ? res.data : {'success': true};
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        return {'success': false, 'error': data['error']?.toString() ?? ''};
      }
    } catch (_) {}
    return null;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GROUP 43: REVIEWS
  // ══════════════════════════════════════════════════════════════════════════

  /// GET /api/reviews?target_id={id}&target_type={type}
  Future<List<VeraReview>> fetchReviews({
    required String targetId,
    String targetType = 'service',
    int page = 1,
  }) async {
    try {
      final params = <String, dynamic>{
        'target_id': targetId,
        'target_type': targetType,
        'page': page,
      };
      final endpoints = ['/reviews', '/reviews/list'];
      for (final ep in endpoints) {
        try {
          final res = await _dio.get(ep, queryParameters: params);
          final data = _extractList(res.data);
          if (data.isNotEmpty) {
            return data.map((e) => VeraReview.fromJson(e)).toList();
          }
        } catch (_) {}
      }
    } catch (_) {}
    return [];
  }

  /// POST /api/reviews
  Future<bool> submitReview({
    required String targetId,
    required String targetType,
    required double rating,
    required String comment,
  }) async {
    try {
      final endpoints = ['/reviews', '/reviews/create'];
      for (final ep in endpoints) {
        try {
          final res = await _dio.post(
            ep,
            data: {
              'target_id': targetId,
              'target_type': targetType,
              'rating': rating,
              'comment': comment,
            },
          );
          if (res.statusCode == 200 || res.statusCode == 201) return true;
        } catch (_) {}
      }
    } catch (_) {}
    return false;
  }

  /// DELETE /api/reviews/{id}
  Future<bool> deleteReview(String reviewId) async {
    try {
      final res = await _dio.delete('/reviews/$reviewId');
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (_) {}
    return false;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // WISHLIST
  // ══════════════════════════════════════════════════════════════════════════

  /// GET /api/buyer/wishlist
  Future<List<VeraWishlistItem>> fetchWishlist() async {
    try {
      final endpoints = [
        '/buyer/wishlist',
        '/user/wishlist',
        '/wishlist',
        '/favorites',
      ];
      for (final ep in endpoints) {
        try {
          final res = await _dio.get(ep);
          final data = _extractList(res.data);
          if (data.isNotEmpty) {
            return data.map((e) => VeraWishlistItem.fromJson(e)).toList();
          }
        } catch (_) {}
      }
    } catch (_) {}
    return [];
  }

  /// POST /api/buyer/wishlist/add
  Future<bool> addToWishlist(String itemId, {String type = 'product'}) async {
    try {
      final endpoints = [
        '/buyer/wishlist/add',
        '/wishlist/add',
        '/favorites/add',
      ];
      for (final ep in endpoints) {
        try {
          final res = await _dio.post(
            ep,
            data: {'item_id': itemId, 'type': type},
          );
          if (res.statusCode == 200 || res.statusCode == 201) return true;
        } catch (_) {}
      }
    } catch (_) {}
    return false;
  }

  /// DELETE /api/buyer/wishlist/{id}
  Future<bool> removeFromWishlist(String itemId) async {
    try {
      final endpoints = [
        '/buyer/wishlist/$itemId',
        '/wishlist/$itemId',
        '/wishlist/remove/$itemId',
        '/favorites/$itemId',
      ];
      for (final ep in endpoints) {
        try {
          final res = await _dio.delete(ep);
          if (res.statusCode == 200 || res.statusCode == 204) return true;
        } catch (_) {}
      }
    } catch (_) {}
    return false;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // NOTIFICATIONS (Admin + Buyer)
  // ══════════════════════════════════════════════════════════════════════════

  /// GET /api/buyer/notifications
  Future<List<VeraNotification>> fetchNotifications() async {
    try {
      final endpoints = [
        '/buyer/notifications',
        '/notifications',
        '/user/notifications',
      ];
      for (final ep in endpoints) {
        try {
          final res = await _dio.get(ep);
          final data = _extractList(res.data);
          if (data.isNotEmpty) {
            return data.map((e) => VeraNotification.fromJson(e)).toList();
          }
        } catch (_) {}
      }
    } catch (_) {}
    return [];
  }

  /// GET /api/buyer/notifications/count
  Future<int> fetchUnreadNotificationCount() async {
    try {
      final res = await _dio.get('/buyer/notifications/count');
      return res.data['unread_count'] as int? ?? 0;
    } catch (_) {}
    return 0;
  }

  /// POST /api/buyer/notifications/{id}/read
  Future<bool> markNotificationRead(String notificationId) async {
    try {
      final endpoints = [
        '/buyer/notifications/$notificationId',
        '/notifications/$notificationId/read',
        '/notifications/$notificationId',
      ];
      for (final ep in endpoints) {
        try {
          final res = await _dio.post(ep);
          if (res.statusCode == 200 || res.statusCode == 204) return true;
        } catch (_) {}
      }
    } catch (_) {}
    return false;
  }

  /// POST /api/buyer/notifications/read-all
  Future<bool> markAllNotificationsRead() async {
    try {
      final endpoints = [
        '/buyer/notifications/read-all',
        '/notifications/read-all',
        '/notifications/mark-all-read',
      ];
      for (final ep in endpoints) {
        try {
          final res = await _dio.post(ep);
          if (res.statusCode == 200 || res.statusCode == 204) return true;
        } catch (_) {}
      }
    } catch (_) {}
    return false;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GROUP 35-37: PAYMENTS (Admin + Gateway + Stripe Connect)
  // ══════════════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>?> createCheckoutSession({
    required String idempotencyKey,
    required String paymentMethod,
    required double total,
    required List<Map<String, dynamic>> items,
    String kind = 'order',
    Map<String, dynamic>? booking,
    String? promoCode,
    double subtotal = 0,
    double discount = 0,
    double deliveryFee = 0,
    double vat = 0,
    String currency = 'AED',
    String? address,
  }) async {
    try {
      final response = await _dio.post(
        '/checkout/sessions',
        options: Options(headers: {'Idempotency-Key': idempotencyKey}),
        data: {
          'payment_method': paymentMethod,
          'total': total,
          'currency': currency,
          'kind': kind,
          'items': items,
          'booking': booking,
          'promo_code': promoCode,
          'subtotal': subtotal,
          'discount': discount,
          'delivery_fee': deliveryFee,
          'vat': vat,
          if (address != null && address.trim().isNotEmpty)
            'address': address.trim(),
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : null;
      }
    } catch (_) {}
    return null;
  }

  /// POST /api/buyer/wallet/pay for a wallet checkout session.
  Future<Map<String, dynamic>?> payWithWallet({
    required String checkoutSessionId,
  }) async {
    try {
      final res = await _dio.post(
        '/buyer/wallet/pay',
        data: {'checkout_session_id': checkoutSessionId},
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        return res.data is Map<String, dynamic> ? res.data : null;
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        return {'success': false, 'error': data['error']?.toString() ?? ''};
      }
    } catch (_) {}
    return null;
  }

  /// POST /api/payments/initiate for a checkout session only.
  Future<Map<String, dynamic>?> initiatePayment({
    required double amount,
    required String method,
    String? orderId,
    String? checkoutSessionId,
    String? currency,
  }) async {
    try {
      if (checkoutSessionId == null || checkoutSessionId.isEmpty) return null;
      final res = await _dio.post(
        '/payments/initiate',
        data: {
          'amount': amount,
          'method': method,
          'checkout_session_id': checkoutSessionId,
          'currency': currency ?? 'AED',
          'platform': 'app',
        },
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        return res.data is Map<String, dynamic> ? res.data : null;
      }
    } catch (_) {}
    return null;
  }

  /// POST /api/payments/verify
  Future<Map<String, dynamic>?> verifyPayment({
    required String paymentId,
    String? checkoutSessionId,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      final res = await _dio.post(
        '/payments/verify',
        data: {
          'payment_id': paymentId,
          if (checkoutSessionId != null)
            'checkout_session_id': checkoutSessionId,
          ...?extraData,
        },
      );
      if (res.statusCode == 200) {
        return res.data is Map<String, dynamic> ? res.data : null;
      }
    } catch (_) {}
    return null;
  }

  /// GET /api/public/orders/{orderId}
  Future<Map<String, dynamic>?> fetchPublicOrder(String orderId) async {
    try {
      final res = await _dio.get('/public/orders/$orderId');
      if (res.statusCode == 200) {
        final data = res.data;
        if (data is Map<String, dynamic>) {
          if (data['success'] == true) {
            return data['data'] is Map<String, dynamic>
                ? data['data'] as Map<String, dynamic>
                : data;
          }
          return data;
        }
      }
    } catch (_) {}
    return null;
  }

  /// GET /api/payments/methods
  Future<List<Map<String, dynamic>>> fetchPaymentMethods() async {
    try {
      final endpoints = [
        '/payments/methods',
        '/payment-methods',
        '/payments/gateways',
      ];
      for (final ep in endpoints) {
        try {
          final res = await _dio.get(ep);
          final data = _extractList(res.data);
          if (data.isNotEmpty) return data;
        } catch (_) {}
      }
    } catch (_) {}
    return [];
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GROUP 38-41: DELIVERY (Aramex / SMSA / Jeebly / Quiqup)
  // ══════════════════════════════════════════════════════════════════════════

  /// POST /api/delivery/aramex/create
  Future<Map<String, dynamic>?> createAramexShipment(
    Map<String, dynamic> data,
  ) async {
    try {
      final res = await _dio.post('/delivery/aramex/create', data: data);
      if (res.statusCode == 200 || res.statusCode == 201) {
        return res.data is Map<String, dynamic> ? res.data : {'success': true};
      }
    } catch (_) {}
    return null;
  }

  /// GET /api/delivery/aramex/track/{trackingNumber}
  Future<VeraShipment?> trackAramexShipment(String trackingNumber) async {
    try {
      final res = await _dio.get('/delivery/aramex/track/$trackingNumber');
      if (res.statusCode == 200 && res.data != null) {
        final data = res.data is Map<String, dynamic>
            ? res.data
            : {'data': res.data};
        return VeraShipment.fromJson(data['data'] ?? data, provider: 'aramex');
      }
    } catch (_) {}
    return null;
  }

  /// POST /api/delivery/smsa/create
  Future<Map<String, dynamic>?> createSmsaShipment(
    Map<String, dynamic> data,
  ) async {
    try {
      final res = await _dio.post('/delivery/smsa/create', data: data);
      if (res.statusCode == 200 || res.statusCode == 201) {
        return res.data is Map<String, dynamic> ? res.data : {'success': true};
      }
    } catch (_) {}
    return null;
  }

  /// GET /api/delivery/smsa/track/{trackingNumber}
  Future<VeraShipment?> trackSmsaShipment(String trackingNumber) async {
    try {
      final res = await _dio.get('/delivery/smsa/track/$trackingNumber');
      if (res.statusCode == 200 && res.data != null) {
        final data = res.data is Map<String, dynamic>
            ? res.data
            : {'data': res.data};
        return VeraShipment.fromJson(data['data'] ?? data, provider: 'smsa');
      }
    } catch (_) {}
    return null;
  }

  /// POST /api/delivery/jeebly/create
  Future<Map<String, dynamic>?> createJeeblyShipment(
    Map<String, dynamic> data,
  ) async {
    try {
      final res = await _dio.post('/delivery/jeebly/create', data: data);
      if (res.statusCode == 200 || res.statusCode == 201) {
        return res.data is Map<String, dynamic> ? res.data : {'success': true};
      }
    } catch (_) {}
    return null;
  }

  /// GET /api/delivery/jeebly/track/{trackingNumber}
  Future<VeraShipment?> trackJeeblyShipment(String trackingNumber) async {
    try {
      final res = await _dio.get('/delivery/jeebly/track/$trackingNumber');
      if (res.statusCode == 200 && res.data != null) {
        final data = res.data is Map<String, dynamic>
            ? res.data
            : {'data': res.data};
        return VeraShipment.fromJson(data['data'] ?? data, provider: 'jeebly');
      }
    } catch (_) {}
    return null;
  }

  /// POST /api/delivery/quiqup/create
  Future<Map<String, dynamic>?> createQuiqupShipment(
    Map<String, dynamic> data,
  ) async {
    try {
      final res = await _dio.post('/delivery/quiqup/create', data: data);
      if (res.statusCode == 200 || res.statusCode == 201) {
        return res.data is Map<String, dynamic> ? res.data : {'success': true};
      }
    } catch (_) {}
    return null;
  }

  /// GET /api/delivery/quiqup/track/{trackingNumber}
  Future<VeraShipment?> trackQuiqupShipment(String trackingNumber) async {
    try {
      final res = await _dio.get('/delivery/quiqup/track/$trackingNumber');
      if (res.statusCode == 200 && res.data != null) {
        final data = res.data is Map<String, dynamic>
            ? res.data
            : {'data': res.data};
        return VeraShipment.fromJson(data['data'] ?? data, provider: 'quiqup');
      }
    } catch (_) {}
    return null;
  }

  Future<VeraShipment?> trackEmxShipment(String trackingNumber) async {
    try {
      final res = await _dio.post(
        '/delivery/emx',
        data: {'action': 'track', 'awbNumber': trackingNumber},
      );
      final data = res.data is Map<String, dynamic>
          ? (res.data['data'] ?? res.data)
          : res.data;
      return data is Map<String, dynamic>
          ? VeraShipment.fromJson(data, provider: 'emx')
          : null;
    } catch (_) {
      return null;
    }
  }

  Future<double?> calculateEmxShippingRate({
    String originCity = 'Dubai',
    String destinationCity = 'Dubai',
    double weightKg = 1,
    double lengthCm = 10,
    double widthCm = 10,
    double heightCm = 10,
    bool remoteArea = false,
  }) async {
    try {
      final res = await _dio.post(
        '/shipping/emx/rate',
        data: {
          'originCity': originCity,
          'destinationCity': destinationCity,
          'destinationCountry': '971',
          'weightGrams': weightKg * 1000,
          'lengthCm': lengthCm,
          'widthCm': widthCm,
          'heightCm': heightCm,
          'remoteArea': remoteArea,
        },
      );
      final data = res.data is Map<String, dynamic>
          ? res.data as Map<String, dynamic>
          : const <String, dynamic>{};
      final value =
          data['price'] ??
          (data['data'] is Map ? (data['data'] as Map)['price'] : null);
      return value is num
          ? value.toDouble()
          : double.tryParse(value?.toString() ?? '');
    } catch (_) {
      return null;
    }
  }

  /// Universal track — tries all providers
  Future<VeraShipment?> trackShipment(String trackingNumber) async {
    final trackers = [
      () => trackEmxShipment(trackingNumber),
      () => trackAramexShipment(trackingNumber),
      () => trackSmsaShipment(trackingNumber),
      () => trackJeeblyShipment(trackingNumber),
      () => trackQuiqupShipment(trackingNumber),
    ];
    for (final tracker in trackers) {
      final result = await tracker();
      if (result != null) return result;
    }
    return null;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GROUP 46: SUBSCRIPTION PLANS
  // ══════════════════════════════════════════════════════════════════════════

  /// GET /api/subscription-plans
  Future<List<VeraSubscriptionPlan>> fetchSubscriptionPlans() async {
    try {
      final endpoints = [
        '/public/subscription-plans',
        '/subscription-plans',
        '/plans',
        '/subscriptions/plans',
      ];
      for (final ep in endpoints) {
        try {
          final res = await _dio.get(ep);
          final data = _extractList(res.data);
          if (data.isNotEmpty) {
            return data.map((e) => VeraSubscriptionPlan.fromJson(e)).toList();
          }
        } catch (_) {}
      }
    } catch (_) {}
    return [];
  }

  Future<List<VeraAdPackage>> fetchAdPackages() async {
    try {
      final res = await _dio.get('/ads/packages/public');
      final data = _extractList(res.data, 'packages');
      return data.map((e) => VeraAdPackage.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> purchaseAdPackage(String packageId) async {
    try {
      final res = await _dio.post(
        '/provider/ads/purchase',
        data: {'packageId': packageId},
      );
      return res.data is Map<String, dynamic>
          ? res.data as Map<String, dynamic>
          : null;
    } catch (_) {
      return null;
    }
  }

  /// POST /api/provider/subscription/purchase
  Future<Map<String, dynamic>?> subscribeToPlan(
    String planId, {
    String? paymentMethod,
  }) async {
    try {
      final endpoints = [
        '/provider/subscription/purchase',
        '/subscription-plans/$planId/subscribe',
        '/subscriptions/subscribe',
      ];
      for (final ep in endpoints) {
        try {
          final res = await _dio.post(
            ep,
            data: {
              'plan_id': planId,
              'planId': planId,
              if (paymentMethod != null) 'payment_method': paymentMethod,
              if (paymentMethod != null) 'paymentMethod': paymentMethod,
              'platform': 'app',
            },
          );
          if (res.statusCode == 200 || res.statusCode == 201) {
            return res.data is Map<String, dynamic>
                ? res.data
                : {'success': true};
          }
        } catch (_) {}
      }
    } catch (_) {}
    return null;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GROUP 34: COUNTRIES
  // ══════════════════════════════════════════════════════════════════════════

  /// GET /api/countries
  Future<List<VeraCountry>> fetchCountries() async {
    try {
      final endpoints = ['/countries', '/locations/countries'];
      for (final ep in endpoints) {
        try {
          final res = await _dio.get(ep);
          final data = _extractList(res.data);
          if (data.isNotEmpty) {
            return data.map((e) => VeraCountry.fromJson(e)).toList();
          }
        } catch (_) {}
      }
    } catch (_) {}
    return [];
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GROUP 45: CONFIGURATION
  // ══════════════════════════════════════════════════════════════════════════

  /// GET /api/config
  Future<Map<String, dynamic>?> fetchConfig() async {
    try {
      final endpoints = [
        '/config',
        '/configuration',
        '/settings/public',
        '/app/config',
      ];
      for (final ep in endpoints) {
        try {
          final res = await _dio.get(ep);
          if (res.statusCode == 200 && res.data != null) {
            return res.data is Map<String, dynamic>
                ? res.data
                : {'data': res.data};
          }
        } catch (_) {}
      }
    } catch (_) {}
    return null;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GROUP 50: INVOICE
  // ══════════════════════════════════════════════════════════════════════════

  /// GET /api/invoices/{orderId}
  Future<Map<String, dynamic>?> fetchInvoice(String orderId) async {
    try {
      final endpoints = ['/invoices/$orderId', '/orders/$orderId/invoice'];
      for (final ep in endpoints) {
        try {
          final res = await _dio.get(ep);
          if (res.statusCode == 200 && res.data != null) {
            return res.data is Map<String, dynamic>
                ? res.data
                : {'data': res.data};
          }
        } catch (_) {}
      }
    } catch (_) {}
    return null;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GROUP 51: EMAIL
  // ══════════════════════════════════════════════════════════════════════════

  /// POST /api/email/send
  Future<bool> sendEmail({
    required String to,
    required String subject,
    required String body,
  }) async {
    try {
      final endpoints = ['/email/send', '/emails/send'];
      for (final ep in endpoints) {
        try {
          final res = await _dio.post(
            ep,
            data: {'to': to, 'subject': subject, 'body': body},
          );
          if (res.statusCode == 200 || res.statusCode == 201) return true;
        } catch (_) {}
      }
    } catch (_) {}
    return false;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GROUP 52: REALTIME SSE
  // ══════════════════════════════════════════════════════════════════════════

  /// GET /api/sse/orders — Server-Sent Events stream URL
  String getSseOrdersUrl() => '$_baseUrl/sse/orders';

  /// GET /api/sse/notifications — SSE notifications stream URL
  String getSseNotificationsUrl() => '$_baseUrl/sse/notifications';

  /// GET /api/sse/tracking/{orderId} — SSE order tracking stream URL
  String getSseTrackingUrl(String orderId) => '$_baseUrl/sse/tracking/$orderId';

  /// GET /api/sse/provider — SSE provider dashboard stream URL
  String getSseProviderUrl() => '$_baseUrl/sse/provider';

  // ══════════════════════════════════════════════════════════════════════════
  // GROUP 54: UPLOAD
  // ══════════════════════════════════════════════════════════════════════════

  /// POST /api/upload/image
  Future<String?> uploadImage(
    String filePath, {
    String type = 'general',
  }) async {
    if (kIsWeb) return null;
    try {
      final endpoints = ['/upload/image', '/upload', '/media/upload'];
      for (final ep in endpoints) {
        try {
          final formData = FormData.fromMap({
            'file': await MultipartFile.fromFile(filePath),
            'type': type,
          });
          final res = await _dio.post(ep, data: formData);
          if (res.statusCode == 200 || res.statusCode == 201) {
            final data = res.data;
            if (data is Map) {
              final url =
                  data['url'] ??
                  data['path'] ??
                  data['image_url'] ??
                  data['data']?['url'];
              if (url != null && url.toString().isNotEmpty) {
                return resolveAssetUrl(url.toString());
              }
            }
          }
        } catch (_) {}
      }
    } catch (_) {}
    return null;
  }

  /// Uploads bytes from the platform picker. This avoids Android content/cache
  /// URI path issues that can make MultipartFile.fromFile fail before request.
  Future<String?> uploadImageBytes(
    Uint8List bytes, {
    String filename = 'image.jpg',
    String type = 'general',
  }) async {
    if (kIsWeb || bytes.isEmpty) return null;
    try {
      await _loadToken();
      final providerToken = _providerToken ?? _authToken;
      for (final endpoint in ['/provider/upload/image', '/upload/image']) {
        try {
          final formData = FormData.fromMap({
            'file': MultipartFile.fromBytes(bytes, filename: filename),
            'type': type,
          });
          final res = await _dio.post(
            endpoint,
            data: formData,
            options: Options(
              headers: providerToken == null
                  ? null
                  : {'Authorization': 'Bearer $providerToken'},
            ),
          );
          if (res.statusCode == 200 || res.statusCode == 201) {
            final data = res.data;
            if (data is Map) {
              final url =
                  data['publicUrl'] ??
                  data['url'] ??
                  data['path'] ??
                  data['image_url'] ??
                  data['data']?['url'];
              if (url != null && url.toString().isNotEmpty)
                return resolveAssetUrl(url.toString());
            }
          }
        } catch (error) {
          debugPrint('Image upload failed at $endpoint: $error');
        }
      }
    } catch (_) {}
    return null;
  }

  /// POST /api/upload/document
  Future<String?> uploadDocument(String filePath) async {
    // File-path based upload is not supported on Flutter Web
    if (kIsWeb) return null;
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
        'type': 'document',
      });
      final endpoints = ['/upload/document', '/upload', '/media/upload'];
      for (final ep in endpoints) {
        try {
          final res = await _dio.post(ep, data: formData);
          if (res.statusCode == 200 || res.statusCode == 201) {
            final data = res.data;
            if (data is Map) {
              return data['url'] ?? data['path'] ?? data['data']?['url'];
            }
          }
        } catch (_) {}
      }
    } catch (_) {}
    return null;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GROUP 47: REPORTS
  // ══════════════════════════════════════════════════════════════════════════

  /// GET /api/reports
  Future<Map<String, dynamic>?> fetchReports({
    String? type,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final params = <String, dynamic>{
        if (type != null) 'type': type,
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
      };
      final res = await _dio.get('/reports', queryParameters: params);
      if (res.statusCode == 200 && res.data != null) {
        return res.data is Map<String, dynamic> ? res.data : {'data': res.data};
      }
    } catch (_) {}
    return null;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GROUP 53: PUBLIC MISC
  // ══════════════════════════════════════════════════════════════════════════

  /// GET /api/public/terms
  Future<String?> fetchTerms() async {
    try {
      final endpoints = ['/public/terms', '/terms', '/pages/terms'];
      for (final ep in endpoints) {
        try {
          final res = await _dio.get(ep);
          if (res.statusCode == 200 && res.data != null) {
            final data = res.data;
            if (data is Map) {
              return data['content'] ?? data['body'] ?? data['text'];
            }
            return data.toString();
          }
        } catch (_) {}
      }
    } catch (_) {}
    return null;
  }

  /// GET /api/public/privacy
  Future<String?> fetchPrivacyPolicy() async {
    try {
      final endpoints = ['/public/privacy', '/privacy', '/pages/privacy'];
      for (final ep in endpoints) {
        try {
          final res = await _dio.get(ep);
          if (res.statusCode == 200 && res.data != null) {
            final data = res.data;
            if (data is Map) {
              return data['content'] ?? data['body'] ?? data['text'];
            }
            return data.toString();
          }
        } catch (_) {}
      }
    } catch (_) {}
    return null;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GROUP 56: DIAGNOSTICS
  // ══════════════════════════════════════════════════════════════════════════

  /// GET /api/diagnostics/health
  Future<bool> checkHealth() async {
    try {
      final endpoints = ['/diagnostics/health', '/health', '/ping', '/status'];
      for (final ep in endpoints) {
        try {
          final res = await _dio.get(ep);
          if (res.statusCode == 200) return true;
        } catch (_) {}
      }
    } catch (_) {}
    return false;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PROVIDER-SPECIFIC ENDPOINTS (Groups 14-22)
  // ══════════════════════════════════════════════════════════════════════════

  /// GET /api/provider/dashboard
  Future<VeraDashboardStats?> fetchProviderDashboard() async {
    try {
      final endpoints = [
        '/provider/summary',
        '/provider/dashboard',
        '/provider/stats',
      ];
      for (final ep in endpoints) {
        try {
          final res = await _dio.get(ep);
          if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
            final json = res.data as Map<String, dynamic>;
            if (ep == '/provider/summary') {
              final summary = (json['summary'] as Map<String, dynamic>?) ?? {};
              final orderStats =
                  (summary['orderStats'] as Map<String, dynamic>?) ?? {};
              final earnings =
                  (json['earnings'] as Map<String, dynamic>?) ?? {};
              return VeraDashboardStats(
                totalOrders:
                    (orderStats['total'] ??
                            summary['totalServices'] ??
                            (json['orders'] as List?)?.length ??
                            0)
                        as int,
                totalBookings: 0,
                totalRevenue: _toDouble(earnings['totalEarnings']),
                totalUsers: 0,
                totalProviders: 0,
                walletBalance: _toDouble(earnings['pendingPayout']),
                loyaltyPoints: 0,
              );
            }
            return VeraDashboardStats.fromJson(json);
          }
        } catch (_) {}
      }
    } catch (_) {}
    return null;
  }

  /// GET /api/provider/services
  Future<List<VeraService>> fetchProviderOwnServices() async {
    try {
      final endpoints = ['/provider/services', '/provider/my-services'];
      for (final ep in endpoints) {
        try {
          final res = await _dio.get(ep);
          final data = _extractList(res.data, 'services');
          debugPrint('[fetchProviderOwnServices] $ep count=${data.length}');
          if (res.statusCode != null &&
              res.statusCode! >= 200 &&
              res.statusCode! < 300) {
            return data.map((e) => VeraService.fromJson(e)).toList();
          }
        } catch (_) {}
      }
    } catch (_) {}
    return [];
  }

  /// POST /api/provider/services
  Future<Map<String, dynamic>?> createProviderService(
    Map<String, dynamic> data,
  ) async {
    try {
      final res = await _dio.post('/provider/services', data: data);
      if (res.statusCode == 200 || res.statusCode == 201) {
        return res.data is Map<String, dynamic> ? res.data : {'success': true};
      }
    } catch (_) {}
    return null;
  }

  /// PATCH /api/provider/services/[id]
  Future<bool> updateProviderService(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final res = await _dio.patch('/provider/services/$id', data: data);
      if (res.statusCode == 200 || res.statusCode == 201) return true;
    } catch (_) {}
    return false;
  }

  /// POST /api/provider/products
  Future<Map<String, dynamic>?> createProviderProduct(
    Map<String, dynamic> data,
  ) async {
    for (final endpoint in ['/provider/products', '/provider/services']) {
      try {
        final res = await _dio.post(endpoint, data: data);
        if (res.statusCode == 200 || res.statusCode == 201) {
          return res.data is Map<String, dynamic>
              ? res.data
              : {'success': true};
        }
      } catch (_) {}
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> fetchProviderProducts() async {
    for (final endpoint in [
      '/provider/products',
      '/provider/my-products',
      '/provider/listings',
    ]) {
      try {
        final response = await _dio.get(endpoint);
        final data = _extractList(response.data, 'products');
        if (data.isNotEmpty) return data;
      } catch (_) {}
    }
    return [];
  }

  Future<bool> updateProviderProduct(
    String id,
    Map<String, dynamic> data,
  ) async {
    for (final endpoint in [
      '/provider/products/$id',
      '/provider/listings/$id',
    ]) {
      try {
        final response = await _dio.patch(endpoint, data: data);
        if (response.statusCode == 200 || response.statusCode == 201)
          return true;
      } catch (_) {}
    }
    return false;
  }

  Future<bool> deleteProviderProduct(String id) async {
    for (final endpoint in [
      '/provider/products/$id',
      '/provider/listings/$id',
    ]) {
      try {
        final response = await _dio.delete(endpoint);
        if (response.statusCode == 200 || response.statusCode == 204)
          return true;
      } catch (_) {}
    }
    return false;
  }

  Future<bool> deleteProviderService(String id) async {
    for (final endpoint in [
      '/provider/services/$id',
      '/provider/listings/$id',
    ]) {
      try {
        final response = await _dio.delete(endpoint);
        if (response.statusCode == 200 || response.statusCode == 204)
          return true;
      } catch (_) {}
    }
    return false;
  }

  /// GET /api/provider/orders
  Future<List<VeraOrder>> fetchProviderOrders({String? status}) async {
    try {
      final params = <String, dynamic>{if (status != null) 'status': status};
      final endpoints = ['/provider/orders', '/provider/my-orders'];
      for (final ep in endpoints) {
        try {
          final res = await _dio.get(ep, queryParameters: params);
          final data = _extractList(res.data);
          if (data.isNotEmpty) {
            return data.map((e) => VeraOrder.fromJson(e)).toList();
          }
        } catch (_) {}
      }
    } catch (_) {}
    return [];
  }

  /// GET /api/provider/earnings
  Future<Map<String, dynamic>?> fetchProviderEarnings() async {
    try {
      final endpoints = ['/provider/earnings', '/provider/revenue'];
      for (final ep in endpoints) {
        try {
          final res = await _dio.get(ep);
          if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
            final map = Map<String, dynamic>.from(
              res.data as Map<String, dynamic>,
            );
            map.putIfAbsent('total', () => map['totalEarnings'] ?? 0);
            map.putIfAbsent('pending', () => map['pendingPayout'] ?? 0);
            return map;
          }
        } catch (_) {}
      }
    } catch (_) {}
    return null;
  }

  /// Stripe Connect status and onboarding actions shared with the web provider portal.
  Future<Map<String, dynamic>?> fetchStripeConnectStatus() async {
    try {
      final res = await _dio.get('/provider/stripe-connect');
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return Map<String, dynamic>.from(res.data as Map<String, dynamic>);
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      return {
        'success': false,
        'error': data is Map
            ? data['error']?.toString() ?? 'HTTP ${e.response?.statusCode}'
            : e.message ?? 'Network error',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
    return null;
  }

  Future<Map<String, dynamic>?> startStripeConnect({
    String country = 'AE',
  }) async {
    try {
      final res = await _dio.post(
        '/provider/stripe-connect',
        data: {'country': country},
      );
      if ((res.statusCode == 200 || res.statusCode == 201) &&
          res.data is Map<String, dynamic>) {
        return Map<String, dynamic>.from(res.data as Map<String, dynamic>);
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      return {
        'success': false,
        'error': data is Map
            ? data['error']?.toString() ?? 'HTTP ${e.response?.statusCode}'
            : e.message ?? 'Network error',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
    return null;
  }

  Future<Map<String, dynamic>?> refreshStripeConnect() async {
    try {
      final res = await _dio.patch('/provider/stripe-connect');
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return Map<String, dynamic>.from(res.data as Map<String, dynamic>);
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      return {
        'success': false,
        'error': data is Map
            ? data['error']?.toString() ?? 'HTTP ${e.response?.statusCode}'
            : e.message ?? 'Network error',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
    return null;
  }

  Future<bool> disconnectStripeConnect() async {
    try {
      final res = await _dio.delete('/provider/stripe-connect');
      return res.statusCode == 200;
    } catch (_) {}
    return false;
  }

  /// GET /api/provider/account-manager
  Future<VeraAccountManager?> fetchProviderAccountManager() async {
    try {
      final res = await _dio.get('/provider/account-manager');
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        final json = res.data as Map<String, dynamic>;
        final am = json['accountManager'];
        if (am is Map<String, dynamic>) {
          return VeraAccountManager.fromJson(am);
        }
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> fetchProviderConversation() async {
    try {
      final res = await _dio.get('/provider/conversations');
      return res.data is Map<String, dynamic>
          ? Map<String, dynamic>.from(res.data as Map<String, dynamic>)
          : null;
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> sendProviderMessage(String body) async {
    try {
      final res = await _dio.post(
        '/provider/conversations',
        data: {'body': body},
      );
      return res.data is Map<String, dynamic>
          ? Map<String, dynamic>.from(res.data as Map<String, dynamic>)
          : null;
    } catch (_) {}
    return null;
  }

  Future<void> registerPushToken(String token) async {
    _cachedFcmToken = token;
    // Post only to the endpoint matching the active role. A buyer token must
    // never be sent to the provider endpoint (and vice versa) — the server
    // rejects it and the request would otherwise look like a session expiry.
    final isProvider = isProviderAuthenticated && !isAuthenticated;
    final path = isProvider ? '/provider/push-token' : '/buyer/push-token';
    try {
      await _dio.post(
        path,
        data: {'token': token, 'platform': 'android'},
      );
    } catch (_) {}
  }

  /// POST /api/provider/payouts/request
  Future<Map<String, dynamic>?> requestPayout({required double amount}) async {
    try {
      final endpoints = ['/provider/payouts', '/provider/payouts/request'];
      for (final ep in endpoints) {
        try {
          final res = await _dio.post(ep, data: {'amount': amount});
          if (res.statusCode == 200 || res.statusCode == 201) {
            return res.data is Map<String, dynamic>
                ? res.data
                : {'success': true};
          }
        } catch (_) {}
      }
    } catch (_) {}
    return null;
  }

  /// GET /api/provider/schedule
  Future<List<Map<String, dynamic>>> fetchProviderSchedule() async {
    try {
      final endpoints = ['/provider/schedule', '/provider/availability'];
      for (final ep in endpoints) {
        try {
          final res = await _dio.get(ep);
          final data = _extractList(res.data);
          if (data.isNotEmpty) return data;
        } catch (_) {}
      }
    } catch (_) {}
    return [];
  }

  /// PUT /api/provider/schedule
  Future<bool> updateProviderSchedule(
    List<Map<String, dynamic>> schedule,
  ) async {
    try {
      final res = await _dio.put(
        '/provider/schedule',
        data: {'schedule': schedule},
      );
      return res.statusCode == 200;
    } catch (_) {}
    return false;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PROMO CODE VALIDATION
  // ══════════════════════════════════════════════════════════════════════════

  /// POST /api/promo-codes/validate
  Future<Map<String, dynamic>?> validatePromoCode(String code) async {
    try {
      final endpoints = [
        '/promo-codes/validate',
        '/coupons/validate',
        '/discounts/validate',
      ];
      for (final ep in endpoints) {
        try {
          final res = await _dio.post(ep, data: {'code': code});
          if (res.statusCode == 200) {
            return res.data is Map<String, dynamic>
                ? res.data
                : {'valid': true};
          }
        } catch (_) {}
      }
    } catch (_) {}
    return null;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FASHION / PRODUCTS
  // ══════════════════════════════════════════════════════════════════════════

  Future<List<VeraProduct>> fetchProducts({
    String? category,
    String? sortBy,
    int page = 1,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        if (category != null && category != 'All') 'category': category,
        if (sortBy != null) 'sort': sortBy,
      };
      final endpoints = ['/products', '/fashion', '/listings?category=fashion'];
      for (final ep in endpoints) {
        try {
          final res = await _dio.get(ep, queryParameters: params);
          final data = _extractList(res.data);
          if (data.isNotEmpty) {
            return data.map((e) => VeraProduct.fromJson(e)).toList();
          }
        } catch (_) {}
      }
    } catch (_) {}
    return [];
  }

  Future<List<VeraCategory>> fetchProductCategories() async {
    try {
      final endpoints = [
        '/products/categories',
        '/fashion/categories',
        '/categories?type=fashion',
      ];
      for (final ep in endpoints) {
        try {
          final res = await _dio.get(ep);
          final data = _extractList(res.data);
          if (data.isNotEmpty) {
            return data.map((e) => VeraCategory.fromJson(e)).toList();
          }
        } catch (_) {}
      }
    } catch (_) {}
    return [];
  }

  // ══════════════════════════════════════════════════════════════════════════
  // JOBS & COURSES
  // ══════════════════════════════════════════════════════════════════════════

  Future<List<VeraJob>> fetchJobs({
    String? query,
    String? type,
    int page = 1,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        if (query != null && query.isNotEmpty) 'q': query,
        if (type != null && type != 'All') 'type': type,
      };
      final endpoints = ['/jobs', '/careers', '/vacancies'];
      for (final ep in endpoints) {
        try {
          final res = await _dio.get(ep, queryParameters: params);
          final data = _extractList(res.data);
          if (data.isNotEmpty) {
            return data.map((e) => VeraJob.fromJson(e)).toList();
          }
        } catch (_) {}
      }
    } catch (_) {}
    return [];
  }

  Future<List<VeraCourse>> fetchCourses({String? query, int page = 1}) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        if (query != null && query.isNotEmpty) 'q': query,
      };
      final endpoints = ['/courses', '/training', '/training-courses'];
      for (final ep in endpoints) {
        try {
          final res = await _dio.get(ep, queryParameters: params);
          final data = _extractList(res.data);
          if (data.isNotEmpty) {
            return data.map((e) => VeraCourse.fromJson(e)).toList();
          }
        } catch (_) {}
      }
    } catch (_) {}
    return [];
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PROPERTIES
  // ══════════════════════════════════════════════════════════════════════════

  Future<List<VeraListing>> fetchProperties({
    int page = 1,
    Map<String, dynamic>? filters,
  }) async {
    try {
      final params = <String, dynamic>{'page': page, ...?filters};
      final endpoints = [
        '/properties',
        '/real-estate',
        '/listings?category=real-estate',
      ];
      for (final ep in endpoints) {
        try {
          final res = await _dio.get(ep, queryParameters: params);
          final data = _extractList(res.data);
          if (data.isNotEmpty) {
            return data.map((e) => VeraListing.fromJson(e)).toList();
          }
        } catch (_) {}
      }
    } catch (_) {}
    return [];
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LEGACY COMPAT — kept for backward compatibility
  // ══════════════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) => loginBuyer(email: email, password: password);

  Future<Map<String, dynamic>?> register({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) =>
      registerBuyer(name: name, email: email, password: password, phone: phone);

  Future<Map<String, dynamic>?> checkout({
    required String paymentMethod,
    String? promoCode,
    String? address,
  }) => placeOrder(
    paymentMethod: paymentMethod,
    promoCode: promoCode,
    address: address,
  );

  // ══════════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>?> _authPost({
    required List<String> endpoints,
    required Map<String, dynamic> data,
    bool exposeErrors = false,
  }) async {
    try {
      for (final ep in endpoints) {
        try {
          final res = await _dio.post(ep, data: data);
          if (res.statusCode == 200 || res.statusCode == 201) {
            final resData = res.data;
            final token =
                resData['token'] ??
                resData['access_token'] ??
                resData['data']?['token'] ??
                resData['data']?['access_token'];
            if (token != null) {
              final isProvider = ep.startsWith('/provider-auth/');
              final tokenStr = token.toString();
              if (isProvider) {
                await setProviderToken(tokenStr);
              } else {
                await setToken(tokenStr);
              }
            }
            return resData is Map<String, dynamic>
                ? resData
                : {'data': resData};
          }
          if (exposeErrors) {
            throw VeraAuthException(
              res.statusCode ?? 0,
              _extractErrorMessage(res.data) ?? 'auth_failed',
            );
          }
        } on DioException catch (e) {
          if (exposeErrors) {
            throw VeraAuthException(
              e.response?.statusCode ?? 0,
              _extractErrorMessage(e.response?.data) ?? 'auth_failed',
            );
          }
        } on VeraAuthException {
          rethrow;
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('VeraAPI auth error: $e');
      if (e is VeraAuthException) rethrow;
    }
    return null;
  }

  String? _extractErrorMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      for (final key in ['error', 'message', 'msg', 'detail']) {
        final v = data[key];
        if (v is String && v.trim().isNotEmpty) return v.trim();
        if (v is Map && v['message'] is String) {
          return v['message'] as String;
        }
      }
    }
    return null;
  }

  List<Map<String, dynamic>> _extractList(
    dynamic data, [
    String? preferredKey,
  ]) {
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }
    if (data is Map<String, dynamic>) {
      if (preferredKey != null &&
          data[preferredKey] is List &&
          data[preferredKey] != null) {
        final preferred = data[preferredKey] as List?;
        if (preferred != null && preferred.isNotEmpty) {
          return preferred.whereType<Map<String, dynamic>>().toList();
        }
      }
      for (final wrapper in ['data', 'result', 'payload']) {
        final nested = data[wrapper];
        if (nested is Map<String, dynamic>) {
          final extracted = _extractList(nested, preferredKey);
          if (extracted.isNotEmpty || nested.containsKey(preferredKey)) {
            return extracted;
          }
        }
      }
      for (final key in [
        'data',
        'results',
        'items',
        'records',
        'list',
        'jobs',
        'products',
        'services',
        'courses',
        'bookings',
        'orders',
        'notifications',
        'wishlist',
        'banners',
        'categories',
        'providers',
        'reviews',
        'plans',
        'countries',
        'transactions',
        'payments',
        'featuredServices',
        'featured_services',
      ]) {
        if (data[key] is List) {
          return (data[key] as List).whereType<Map<String, dynamic>>().toList();
        }
      }
    }
    return [];
  }
}
