import 'product_options_entity.dart';

double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

int _toInt(dynamic v, [int fallback = 0]) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? fallback;
}

class ProductOptionItemModel extends ProductOptionItemEntity {
  ProductOptionItemModel({
    super.id,
    super.groupId,
    super.name,
    super.additionalPrice,
    super.sortOrder,
    super.isActive,
    super.imageUrl,
  });

  factory ProductOptionItemModel.fromJson(Map<String, dynamic> j) {
    return ProductOptionItemModel(
      id: j['id'] as int?,
      groupId: j['group_id'] as int?,
      name: (j['name'] ?? '').toString(),
      additionalPrice: _toDouble(j['additional_price']),
      sortOrder: _toInt(j['sort_order']),
      isActive: j['is_active'] == null ? true : j['is_active'] as bool,
      imageUrl: j['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'name': name,
        'additional_price': additionalPrice,
        'sort_order': sortOrder,
        'is_active': isActive,
        if (imageUrl != null) 'image_url': imageUrl,
      };
}

class ProductOptionGroupModel extends ProductOptionGroupEntity {
  ProductOptionGroupModel({
    super.id,
    super.companyId,
    super.productId,
    super.name,
    super.type,
    super.minSelection,
    super.maxSelection,
    super.isRequired,
    super.sortOrder,
    super.items,
  });

  factory ProductOptionGroupModel.fromJson(Map<String, dynamic> j) {
    return ProductOptionGroupModel(
      id: j['id'] as int?,
      companyId: j['company_id'] as int?,
      productId: j['product_id'] as int?,
      name: (j['name'] ?? '').toString(),
      type: parseGroupType(j['type']?.toString()),
      minSelection: _toInt(j['min_selection']),
      maxSelection: _toInt(j['max_selection'], 1),
      isRequired: j['is_required'] == true,
      sortOrder: _toInt(j['sort_order']),
      items: ((j['items'] as List?) ?? [])
          .map((e) => ProductOptionItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toCreateJson({required int companyId, required int productId}) => {
        'company_id': companyId,
        'product_id': productId,
        'name': name,
        'type': serializeGroupType(type),
        'min_selection': minSelection,
        'max_selection': maxSelection,
        'is_required': isRequired,
        'sort_order': sortOrder,
        'items': items.map((it) => (it as ProductOptionItemModel).toJson()).toList(),
      };

  Map<String, dynamic> toUpdateJson({required int companyId}) => {
        'company_id': companyId,
        'name': name,
        'type': serializeGroupType(type),
        'min_selection': minSelection,
        'max_selection': maxSelection,
        'is_required': isRequired,
        'sort_order': sortOrder,
        'items': items.map((it) => (it as ProductOptionItemModel).toJson()).toList(),
      };
}
