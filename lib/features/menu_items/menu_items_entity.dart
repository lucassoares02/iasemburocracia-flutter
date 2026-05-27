class MenuItemsEntity {
  int? id;
  int? companyId;
  int? categoryId;
  String? name;
  String? description;
  double? price;
  bool? available;
  String? imageUrl;
  bool? featured;
  int? displayOrder;
  int? prepTimeMinutes;
  String? sku;
  String? categoryName;

  MenuItemsEntity({
    this.id,
    this.companyId,
    this.categoryId,
    this.name,
    this.description,
    this.price,
    this.available,
    this.imageUrl,
    this.featured,
    this.displayOrder,
    this.prepTimeMinutes,
    this.sku,
    this.categoryName,
  });
}
