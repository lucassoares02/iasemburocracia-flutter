part of 'home_page.dart';

// ─── Charts row ───────────────────────────────────────────────────────────────
class _ChartsRow extends StatelessWidget {
  final List<SalesPointModel> sales;
  final List<StatusBreakdownModel> statusBreakdown;
  final List<TopProductModel> top5;
  final Color brand;
  final bool wide;
  final bool medium;
  const _ChartsRow({
    required this.sales,
    required this.statusBreakdown,
    required this.top5,
    required this.brand,
    required this.wide,
    required this.medium,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: 'Análise visual',
          subtitle: 'Métricas dos últimos 7 dias',
          icon: LucideIcons.barChart,
          iconColor: const Color(0xFF7C3AED),
        ),
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _SalesChartCard(sales: sales, brand: brand),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatusChartCard(items: statusBreakdown),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TopProductsChartCard(items: top5, brand: brand),
              ),
            ],
          )
        else if (medium)
          Column(
            children: [
              _SalesChartCard(sales: sales, brand: brand),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _StatusChartCard(items: statusBreakdown)),
                  const SizedBox(width: 12),
                  Expanded(child: _TopProductsChartCard(items: top5, brand: brand)),
                ],
              ),
            ],
          )
        else
          Column(
            children: [
              _SalesChartCard(sales: sales, brand: brand),
              const SizedBox(height: 12),
              _StatusChartCard(items: statusBreakdown),
              const SizedBox(height: 12),
              _TopProductsChartCard(items: top5, brand: brand),
            ],
          ),
      ],
    );
  }
}

// ─── Sales chart (last 7 days line/bar) ───────────────────────────────────────
class _SalesChartCard extends StatelessWidget {
  final List<SalesPointModel> sales;
  final Color brand;
  const _SalesChartCard({required this.sales, required this.brand});

  @override
  Widget build(BuildContext context) {
    final hasData = sales.any((s) => s.revenue > 0);
    final maxY = sales.fold<double>(0, (m, s) => s.revenue > m ? s.revenue : m);
    final double yMax = maxY == 0 ? 100.0 : (maxY * 1.2).ceilToDouble();

    return _Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Vendas dos últimos 7 dias',
                  style: TextStyle(
                    fontSize: 13,
                    color: _DS.ink,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: brand.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  _currFmt.format(sales.fold<double>(0, (s, e) => s + e.revenue)),
                  style: TextStyle(
                    fontSize: 11,
                    color: brand,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 200,
            child: hasData
                ? _buildLineChart(yMax)
                : Center(
                    child: _SectionEmpty(
                      icon: LucideIcons.barChart,
                      message: 'Sem vendas nos últimos 7 dias',
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart(double yMax) {
    final spots = <FlSpot>[];
    for (var i = 0; i < sales.length; i++) {
      spots.add(FlSpot(i.toDouble(), sales[i].revenue));
    }
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (sales.length - 1).toDouble(),
        minY: 0,
        maxY: yMax,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: yMax / 4,
          getDrawingHorizontalLine: (_) => const FlLine(
            color: _DS.hairlineSoft,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              interval: yMax / 4,
              getTitlesWidget: (v, _) => Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  _shortCurrency(v),
                  style: const TextStyle(
                    fontSize: 10,
                    color: _DS.stone,
                  ),
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (v, _) {
                final idx = v.toInt();
                if (idx < 0 || idx >= sales.length) return const SizedBox();
                final date = sales[idx].date;
                if (date == null) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _dateChartFmt.format(date),
                    style: const TextStyle(
                      fontSize: 10,
                      color: _DS.stone,
                    ),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => _DS.ink,
            tooltipRoundedRadius: 8,
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            getTooltipItems: (spots) {
              return spots.map((s) {
                final idx = s.x.toInt();
                final date = sales[idx].date;
                return LineTooltipItem(
                  '${date != null ? _dateChartFmt.format(date) : ""}\n${_currFmt.format(s.y)}',
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.25,
            color: brand,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                radius: 3.5,
                color: brand,
                strokeWidth: 2,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  brand.withValues(alpha: 0.25),
                  brand.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _shortCurrency(double v) {
    if (v >= 1000) return 'R\$${(v / 1000).toStringAsFixed(1)}k';
    return 'R\$${v.toStringAsFixed(0)}';
  }
}

// ─── Status pie chart ─────────────────────────────────────────────────────────
class _StatusChartCard extends StatelessWidget {
  final List<StatusBreakdownModel> items;
  const _StatusChartCard({required this.items});

  @override
  Widget build(BuildContext context) {
    final total = items.fold<int>(0, (s, e) => s + e.count);
    return _Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pedidos por status',
            style: TextStyle(
              fontSize: 13,
              color: _DS.ink,
            ),
          ),
          const SizedBox(height: 18),
          if (total == 0)
            SizedBox(
              height: 180,
              child: Center(
                child: _SectionEmpty(
                  icon: LucideIcons.pieChart,
                  message: 'Sem dados para exibir',
                ),
              ),
            )
          else
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 36,
                        startDegreeOffset: -90,
                        sections: items.map((it) {
                          final color = _statusColor(it.status);
                          final pct = total > 0 ? (it.count / total) * 100 : 0;
                          return PieChartSectionData(
                            color: color,
                            value: it.count.toDouble(),
                            title: '${pct.toStringAsFixed(0)}%',
                            radius: 38,
                            titleStyle: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: items
                          .map((it) => _legendRow(
                                _statusColor(it.status),
                                _statusLabel(it.status),
                                it.count,
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _legendRow(Color color, String label, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: _DS.slate,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 11,
              color: _DS.ink,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Top products bar chart ───────────────────────────────────────────────────
class _TopProductsChartCard extends StatelessWidget {
  final List<TopProductModel> items;
  final Color brand;
  const _TopProductsChartCard({required this.items, required this.brand});

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top 5 produtos',
            style: TextStyle(
              fontSize: 13,
              color: _DS.ink,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Por unidades vendidas (30d)',
            style: TextStyle(fontSize: 11, color: _DS.stone),
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            SizedBox(
              height: 160,
              child: Center(
                child: _SectionEmpty(
                  icon: LucideIcons.trophy,
                  message: 'Sem vendas no período',
                ),
              ),
            )
          else
            ...items.map((p) {
              final maxQty = items.fold<int>(0, (m, e) => e.quantity > m ? e.quantity : m).clamp(1, double.maxFinite.toInt());
              final ratio = p.quantity / maxQty;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            p.name ?? '—',
                            style: const TextStyle(
                              fontSize: 12,
                              color: _DS.ink,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${p.quantity} un',
                          style: const TextStyle(
                            fontSize: 11,
                            color: _DS.slate,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    LayoutBuilder(builder: (context, c) {
                      final w = (c.maxWidth * ratio).clamp(0, c.maxWidth);
                      return Stack(
                        children: [
                          Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: _DS.hairlineSoft,
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            height: 6,
                            width: w.toDouble(),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  brand,
                                  brand.withValues(alpha: 0.7),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
