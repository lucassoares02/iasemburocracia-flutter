import 'purchase_goal_entity.dart';

double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

DateTime? _toDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}

class PurchaseGoalCategoryModel extends PurchaseGoalCategoryEntity {
  PurchaseGoalCategoryModel({super.id, super.name});

  factory PurchaseGoalCategoryModel.fromJson(Map<String, dynamic> j) {
    return PurchaseGoalCategoryModel(
      id: j['id'] as int?,
      name: j['name']?.toString(),
    );
  }
}

class PurchaseGoalModel extends PurchaseGoalEntity {
  PurchaseGoalModel({
    super.id,
    super.companyId,
    super.name,
    super.description,
    super.discountPercentage,
    super.isActive,
    super.createdAt,
    super.updatedAt,
    super.categories,
  });

  factory PurchaseGoalModel.fromJson(Map<String, dynamic> j) {
    return PurchaseGoalModel(
      id: j['id'] as int?,
      companyId: j['company_id'] as int?,
      name: (j['name'] ?? '').toString(),
      description: j['description']?.toString(),
      discountPercentage: _toDouble(j['discount_percentage']),
      isActive: j['is_active'] == null ? true : j['is_active'] as bool,
      createdAt: _toDate(j['created_at']),
      updatedAt: _toDate(j['updated_at']),
      categories: ((j['categories'] as List?) ?? [])
          .map((e) => PurchaseGoalCategoryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toCreateJson({required int companyId}) => {
        'company_id': companyId,
        'name': name,
        'description': description,
        'discount_percentage': discountPercentage,
        'is_active': isActive,
        'category_ids': categories.map((c) => c.id).whereType<int>().toList(),
      };

  Map<String, dynamic> toUpdateJson({required int companyId}) => {
        'company_id': companyId,
        'name': name,
        'description': description,
        'discount_percentage': discountPercentage,
        'is_active': isActive,
        'category_ids': categories.map((c) => c.id).whereType<int>().toList(),
      };
}

class PurchaseGoalSuggestionModel extends PurchaseGoalSuggestionEntity {
  PurchaseGoalSuggestionModel({
    required super.goalId,
    required super.goalName,
    super.goalDescription,
    required super.discountPercentage,
    required super.missingCategoryId,
    required super.missingCategoryName,
    required super.productId,
    required super.productName,
    super.productDescription,
    super.productImageUrl,
    required super.originalPrice,
    required super.finalPrice,
    required super.discountAmount,
    super.categoryId,
    super.categoryName,
    super.hasOptions,
    super.prepTimeMinutes,
  });

  static PurchaseGoalSuggestionModel? fromJson(Map<String, dynamic>? root) {
    if (root == null) return null;
    final s = root['suggestion'] as Map<String, dynamic>?;
    if (s == null) return null;
    final goal = (s['goal'] as Map<String, dynamic>?) ?? {};
    final missing = (s['missing_category'] as Map<String, dynamic>?) ?? {};
    final product = (s['product'] as Map<String, dynamic>?) ?? {};
    final goalId = _toInt(goal['id']);
    final missingId = _toInt(missing['id']);
    final productId = _toInt(product['id']);
    if (goalId == 0 || missingId == 0 || productId == 0) return null;
    return PurchaseGoalSuggestionModel(
      goalId: goalId,
      goalName: (goal['name'] ?? '').toString(),
      goalDescription: goal['description']?.toString(),
      discountPercentage: _toDouble(goal['discount_percentage']),
      missingCategoryId: missingId,
      missingCategoryName: (missing['name'] ?? '').toString(),
      productId: productId,
      productName: (product['name'] ?? '').toString(),
      productDescription: product['description']?.toString(),
      productImageUrl: product['image_url']?.toString(),
      originalPrice: _toDouble(product['original_price']),
      finalPrice: _toDouble(product['final_price']),
      discountAmount: _toDouble(product['discount_amount']),
      categoryId: product['category_id'] as int?,
      categoryName: product['category_name']?.toString(),
      hasOptions: product['has_options'] == true,
      prepTimeMinutes: product['prep_time_minutes'] as int?,
    );
  }
}
