class ProductOptionItemEntity {
  int? id;
  int? groupId;
  String name;
  double additionalPrice;
  int sortOrder;
  bool isActive;
  String? imageUrl;

  ProductOptionItemEntity({
    this.id,
    this.groupId,
    this.name = '',
    this.additionalPrice = 0,
    this.sortOrder = 0,
    this.isActive = true,
    this.imageUrl,
  });
}

enum ProductOptionGroupType { single, multiple, quantity }

ProductOptionGroupType parseGroupType(String? raw) {
  switch ((raw ?? '').toLowerCase()) {
    case 'multiple':
      return ProductOptionGroupType.multiple;
    case 'quantity':
      return ProductOptionGroupType.quantity;
    default:
      return ProductOptionGroupType.single;
  }
}

String serializeGroupType(ProductOptionGroupType t) {
  switch (t) {
    case ProductOptionGroupType.multiple:
      return 'multiple';
    case ProductOptionGroupType.quantity:
      return 'quantity';
    case ProductOptionGroupType.single:
      return 'single';
  }
}

class ProductOptionGroupEntity {
  int? id;
  int? companyId;
  int? productId;
  String name;
  ProductOptionGroupType type;
  int minSelection;
  int maxSelection;
  bool isRequired;
  int sortOrder;
  List<ProductOptionItemEntity> items;

  ProductOptionGroupEntity({
    this.id,
    this.companyId,
    this.productId,
    this.name = '',
    this.type = ProductOptionGroupType.single,
    this.minSelection = 0,
    this.maxSelection = 1,
    this.isRequired = false,
    this.sortOrder = 0,
    List<ProductOptionItemEntity>? items,
  }) : items = items ?? <ProductOptionItemEntity>[];
}
