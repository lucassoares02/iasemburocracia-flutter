class DashboardEntity {
  CompanyInfoEntity? company;
  PeriodStatsEntity? today;
  MonthStatsEntity? month;
  OperationStatsEntity? operation;
  ProductsSectionEntity? products;
  List<RecentOrderEntity>? recentOrders;
  ClientsSectionEntity? clients;
  List<SalesPointEntity>? salesChart;
  List<StatusBreakdownEntity>? statusBreakdown;
  List<InsightEntity>? insights;
}

class CompanyInfoEntity {
  int? id;
  String? name;
  String? description;
  String? logoUrl;
  String? bannerUrl;
  String? brandColor;
  bool isOpen = false;
}

class PeriodStatsEntity {
  int orders = 0;
  double revenue = 0;
  double avgTicket = 0;
  int newClients = 0;
}

class MonthStatsEntity {
  int orders = 0;
  double revenue = 0;
  double avgTicket = 0;
  double growthPct = 0;
}

class OperationStatsEntity {
  int inProgress = 0;
  int completed = 0;
  int cancelled = 0;
  int total = 0;
  double cancellationRate = 0;
}

class ProductSummaryEntity {
  int? id;
  String? name;
  String? imageUrl;
  int quantitySold = 0;
  double? revenue;
}

class TopProductEntity {
  int? id;
  String? name;
  int quantity = 0;
  double? revenue;
}

class ProductsSectionEntity {
  ProductSummaryEntity? topSeller;
  ProductSummaryEntity? worstSeller;
  List<ProductSummaryEntity> withoutSales = [];
  List<TopProductEntity> top5 = [];
}

class RecentOrderEntity {
  int? id;
  String? status;
  double? total;
  DateTime? createdAt;
  String? clientName;
  int itemsCount = 0;
}

class TopSpenderEntity {
  int? id;
  String? name;
  double totalSpent = 0;
  int ordersCount = 0;
}

class ClientsSectionEntity {
  int total = 0;
  int recurring = 0;
  int newMonth = 0;
  TopSpenderEntity? topSpender;
}

class SalesPointEntity {
  DateTime? date;
  double revenue = 0;
  int ordersCount = 0;
}

class StatusBreakdownEntity {
  String? status;
  int count = 0;
}

class InsightEntity {
  String? type; // positive | negative | info
  String? icon;
  String? title;
  String? text;
}
