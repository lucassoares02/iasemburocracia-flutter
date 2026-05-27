import 'home_entity.dart';

double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0;
  return 0;
}

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

DateTime? _toDate(dynamic v) {
  if (v == null) return null;
  if (v is String) return DateTime.tryParse(v);
  return null;
}

class DashboardModel extends DashboardEntity {
  DashboardModel.fromJson(Map<String, dynamic> json) {
    company = json['company'] != null
        ? CompanyInfoModel.fromJson(json['company'] as Map<String, dynamic>)
        : null;
    today = json['today'] != null
        ? PeriodStatsModel.fromJson(json['today'] as Map<String, dynamic>)
        : null;
    month = json['month'] != null
        ? MonthStatsModel.fromJson(json['month'] as Map<String, dynamic>)
        : null;
    operation = json['operation'] != null
        ? OperationStatsModel.fromJson(
            json['operation'] as Map<String, dynamic>)
        : null;
    products = json['products'] != null
        ? ProductsSectionModel.fromJson(
            json['products'] as Map<String, dynamic>)
        : null;
    recentOrders = (json['recent_orders'] as List? ?? [])
        .map((e) => RecentOrderModel.fromJson(e as Map<String, dynamic>))
        .toList();
    clients = json['clients'] != null
        ? ClientsSectionModel.fromJson(json['clients'] as Map<String, dynamic>)
        : null;
    salesChart = (json['sales_chart'] as List? ?? [])
        .map((e) => SalesPointModel.fromJson(e as Map<String, dynamic>))
        .toList();
    statusBreakdown = (json['status_breakdown'] as List? ?? [])
        .map((e) => StatusBreakdownModel.fromJson(e as Map<String, dynamic>))
        .toList();
    insights = (json['insights'] as List? ?? [])
        .map((e) => InsightModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

class CompanyInfoModel extends CompanyInfoEntity {
  CompanyInfoModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    description = json['description'];
    logoUrl = json['logo_url'];
    bannerUrl = json['banner_url'];
    brandColor = json['brand_color'];
    isOpen = json['is_open'] as bool? ?? false;
  }
}

class PeriodStatsModel extends PeriodStatsEntity {
  PeriodStatsModel.fromJson(Map<String, dynamic> json) {
    orders = _toInt(json['orders']);
    revenue = _toDouble(json['revenue']);
    avgTicket = _toDouble(json['avg_ticket']);
    newClients = _toInt(json['new_clients']);
  }
}

class MonthStatsModel extends MonthStatsEntity {
  MonthStatsModel.fromJson(Map<String, dynamic> json) {
    orders = _toInt(json['orders']);
    revenue = _toDouble(json['revenue']);
    avgTicket = _toDouble(json['avg_ticket']);
    growthPct = _toDouble(json['growth_pct']);
  }
}

class OperationStatsModel extends OperationStatsEntity {
  OperationStatsModel.fromJson(Map<String, dynamic> json) {
    inProgress = _toInt(json['in_progress']);
    completed = _toInt(json['completed']);
    cancelled = _toInt(json['cancelled']);
    total = _toInt(json['total']);
    cancellationRate = _toDouble(json['cancellation_rate']);
  }
}

class ProductSummaryModel extends ProductSummaryEntity {
  ProductSummaryModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    imageUrl = json['image_url'];
    quantitySold = _toInt(json['quantity_sold']);
    revenue = json['revenue'] != null ? _toDouble(json['revenue']) : null;
  }
}

class TopProductModel extends TopProductEntity {
  TopProductModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    quantity = _toInt(json['quantity']);
    revenue = json['revenue'] != null ? _toDouble(json['revenue']) : null;
  }
}

class ProductsSectionModel extends ProductsSectionEntity {
  ProductsSectionModel.fromJson(Map<String, dynamic> json) {
    topSeller = json['top_seller'] != null
        ? ProductSummaryModel.fromJson(
            json['top_seller'] as Map<String, dynamic>)
        : null;
    worstSeller = json['worst_seller'] != null
        ? ProductSummaryModel.fromJson(
            json['worst_seller'] as Map<String, dynamic>)
        : null;
    withoutSales = (json['without_sales'] as List? ?? [])
        .map((e) => ProductSummaryModel.fromJson(e as Map<String, dynamic>))
        .toList();
    top5 = (json['top_5'] as List? ?? [])
        .map((e) => TopProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

class RecentOrderModel extends RecentOrderEntity {
  RecentOrderModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    status = json['status'];
    total = json['total'] != null ? _toDouble(json['total']) : null;
    createdAt = _toDate(json['created_at']);
    clientName = json['client_name'];
    itemsCount = _toInt(json['items_count']);
  }
}

class TopSpenderModel extends TopSpenderEntity {
  TopSpenderModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    totalSpent = _toDouble(json['total_spent']);
    ordersCount = _toInt(json['orders_count']);
  }
}

class ClientsSectionModel extends ClientsSectionEntity {
  ClientsSectionModel.fromJson(Map<String, dynamic> json) {
    total = _toInt(json['total']);
    recurring = _toInt(json['recurring']);
    newMonth = _toInt(json['new_month']);
    topSpender = json['top_spender'] != null
        ? TopSpenderModel.fromJson(
            json['top_spender'] as Map<String, dynamic>)
        : null;
  }
}

class SalesPointModel extends SalesPointEntity {
  SalesPointModel.fromJson(Map<String, dynamic> json) {
    date = _toDate(json['date']);
    revenue = _toDouble(json['revenue']);
    ordersCount = _toInt(json['orders_count']);
  }
}

class StatusBreakdownModel extends StatusBreakdownEntity {
  StatusBreakdownModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    count = _toInt(json['count']);
  }
}

class InsightModel extends InsightEntity {
  InsightModel.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    icon = json['icon'];
    title = json['title'];
    text = json['text'];
  }
}
