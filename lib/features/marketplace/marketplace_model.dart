/// Modelos do marketplace público de restaurantes (`/order`).
library;

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

int? _toInt(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

class MarketplaceRestaurantModel {
  final int id;
  final String name;
  final String? description;
  final String? logoUrl;
  final String? bannerUrl;
  final String? brandColor;
  final String? cuisineType;
  final int ordersCount;
  final double revenueTotal;
  final int? avgPrepMinutes;
  final int itemsCount;
  final double? minPriceOrder;
  final double? minTaxDelivery;
  final bool hasPromotions;
  final bool isOpen;

  MarketplaceRestaurantModel.fromJson(Map<String, dynamic> j)
      : id = _toInt(j['id']) ?? 0,
        name = (j['name'] ?? '').toString(),
        description = j['description']?.toString(),
        logoUrl = j['logo_url']?.toString(),
        bannerUrl = j['banner_url']?.toString(),
        brandColor = j['brand_color']?.toString(),
        cuisineType = j['cuisine_type']?.toString(),
        ordersCount = _toInt(j['orders_count']) ?? 0,
        revenueTotal = _toDouble(j['revenue_total']) ?? 0,
        avgPrepMinutes = _toInt(j['avg_prep_minutes']),
        itemsCount = _toInt(j['items_count']) ?? 0,
        minPriceOrder = _toDouble(j['min_price_order']),
        minTaxDelivery = _toDouble(j['min_tax_delivery']),
        hasPromotions = j['has_promotions'] == true,
        isOpen = j['is_open'] == true;
}

class MarketplacePromotionModel {
  final int id;
  final int companyId;
  final String name;
  final String? imageUrl;
  final double? discountPercent;
  final double? originalPrice;
  final double? finalPrice;
  final String companyName;
  final String? companyLogo;

  MarketplacePromotionModel.fromJson(Map<String, dynamic> j)
      : id = _toInt(j['id']) ?? 0,
        companyId = _toInt(j['company_id']) ?? 0,
        name = (j['name'] ?? '').toString(),
        imageUrl = j['image_url']?.toString(),
        discountPercent = _toDouble(j['discount_percent']),
        originalPrice = _toDouble(j['original_price']),
        finalPrice = _toDouble(j['final_price']),
        companyName = (j['company_name'] ?? '').toString(),
        companyLogo = j['company_logo']?.toString();

  /// % de desconto efetivo (cadastrado ou derivado dos preços).
  int get effectiveDiscountPct {
    if ((discountPercent ?? 0) > 0) return discountPercent!.round();
    final orig = originalPrice ?? 0;
    final fin = finalPrice ?? 0;
    if (orig <= 0 || fin <= 0 || fin >= orig) return 0;
    return (((orig - fin) / orig) * 100).round();
  }
}

class MarketplaceData {
  final List<MarketplaceRestaurantModel> restaurants;
  final List<MarketplacePromotionModel> promotions;

  MarketplaceData.fromJson(Map<String, dynamic> j)
      : restaurants = ((j['restaurants'] as List?) ?? [])
            .map((e) => MarketplaceRestaurantModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        promotions = ((j['promotions'] as List?) ?? [])
            .map((e) => MarketplacePromotionModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
}
