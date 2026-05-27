class PurchaseGoalCategoryEntity {
  int? id;
  String? name;

  PurchaseGoalCategoryEntity({this.id, this.name});
}

class PurchaseGoalEntity {
  int? id;
  int? companyId;
  String name;
  String? description;
  double discountPercentage;
  bool isActive;
  DateTime? createdAt;
  DateTime? updatedAt;
  List<PurchaseGoalCategoryEntity> categories;

  PurchaseGoalEntity({
    this.id,
    this.companyId,
    this.name = '',
    this.description,
    this.discountPercentage = 0,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    List<PurchaseGoalCategoryEntity>? categories,
  }) : categories = categories ?? <PurchaseGoalCategoryEntity>[];
}

/// Snapshot retornado pelo endpoint público de sugestão.
class PurchaseGoalSuggestionEntity {
  final int goalId;
  final String goalName;
  final String? goalDescription;
  final double discountPercentage;
  final int missingCategoryId;
  final String missingCategoryName;
  final int productId;
  final String productName;
  final String? productDescription;
  final String? productImageUrl;
  final double originalPrice;
  final double finalPrice;
  final double discountAmount;
  final int? categoryId;
  final String? categoryName;
  final bool hasOptions;
  final int? prepTimeMinutes;

  PurchaseGoalSuggestionEntity({
    required this.goalId,
    required this.goalName,
    this.goalDescription,
    required this.discountPercentage,
    required this.missingCategoryId,
    required this.missingCategoryName,
    required this.productId,
    required this.productName,
    this.productDescription,
    this.productImageUrl,
    required this.originalPrice,
    required this.finalPrice,
    required this.discountAmount,
    this.categoryId,
    this.categoryName,
    this.hasOptions = false,
    this.prepTimeMinutes,
  });
}
