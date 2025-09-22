import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:frontend/features/stats/service/stats_service.dart';

class StatsSupplierScreen extends StatefulWidget {
  const StatsSupplierScreen({super.key});

  @override
  State<StatsSupplierScreen> createState() => _StatsSupplierScreenState();
}

class _StatsSupplierScreenState extends State<StatsSupplierScreen> {
  Map<String, dynamic>? stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final data = await StatisticsService.loadStatistics();
      if (mounted) {
        setState(() {
          stats = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi tải thống kê: $e")),
        );
      }
    }
  }


  String _formatCurrency(dynamic value) {
    if (value == null) return '0đ';
    final numValue = value is String ? double.tryParse(value) ?? 0 : (value as num).toDouble();
    return '${numValue.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}đ';
  }


  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirm':
        return Colors.blue;
      case 'processing':
        return Colors.teal;
      case 'shipped':
        return Colors.green;
      case 'delivered':
        return Colors.green.shade700;
      case 'cancelled':
        return Colors.red;
      case 'returned_to_sender':
        return Colors.purple;
      case 'refunded':
        return Colors.grey;
      default:
        return Colors.blue.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thống kê"),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: stats == null
                    ? const Center(
                        child: Column(
                          children: [
                            Icon(Icons.error_outline, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text("Không có dữ liệu thống kê", style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : Builder(
                        builder: (context) {
                          final overview = stats!["overview"];
                          final statusDistribution = stats!["status_distribution"];
                          final trend = stats!["trend"];
                          final topProducts = stats!["top_products"];
                          final topRated = stats!["top_rated"];

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              
                              _buildSectionTitle("Tổng quan"),
                              const SizedBox(height: 12),
                              GridView(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 1.8,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                                children: [
                                  _buildStatCard(
                                    title: "Đơn hôm nay",
                                    value: overview["orders_today"]?.toString() ?? "0",
                                    icon: Icons.shopping_cart,
                                    color: Colors.blue,
                                  ),
                                  _buildStatCard(
                                    title: "Đơn trong tháng",
                                    value: overview["orders_this_month"]?.toString() ?? "0",
                                    icon: Icons.calendar_month,
                                    color: Colors.green,
                                  ),
                                  _buildStatCard(
                                    title: "Doanh thu hôm nay",
                                    value: _formatCurrency(overview["revenue_today"]),
                                    icon: Icons.attach_money,
                                    color: Colors.orange,
                                  ),
                                  _buildStatCard(
                                    title: "Doanh thu tháng",
                                    value: _formatCurrency(overview["revenue_this_month"]),
                                    icon: Icons.bar_chart,
                                    color: Colors.purple,
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),


                              _buildSectionTitle("Trạng thái đơn"),
                              const SizedBox(height: 12),
                              Container(
                                height: 220,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(16),
                                child: PieChart(
                                  PieChartData(
                                    sections: [
                                      for (var s in statusDistribution)
                                        PieChartSectionData(
                                          value: (s["count"] as num).toDouble(),
                                          title: s["delivery_status"],
                                          color: _getStatusColor(s["delivery_status"]),
                                          radius: 60,
                                          titleStyle: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                    ],
                                    centerSpaceRadius: 40,
                                    sectionsSpace: 2,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),


                              _buildSectionTitle("Xu hướng đơn hàng"),
                              const SizedBox(height: 12),
                              Container(
                                height: 220,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(16),
                                child: BarChart(
                                  BarChartData(
                                    alignment: BarChartAlignment.spaceAround,
                                    barGroups: [
                                      for (var t in trend)
                                        BarChartGroupData(
                                          x: DateTime.parse(t["day"]).day,
                                          barRods: [
                                            BarChartRodData(
                                              toY: (t["total_orders"] as num).toDouble(),
                                              color: Colors.blue.shade700,
                                              width: 16,
                                              borderRadius: BorderRadius.circular(4),
                                            )
                                          ],
                                        )
                                    ],
                                    titlesData: FlTitlesData(
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (value, meta) {
                                            return Padding(
                                              padding: const EdgeInsets.only(top: 8.0),
                                              child: Text(
                                                value.toInt().toString(),
                                                style: const TextStyle(fontSize: 10),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (value, meta) {
                                            return Text(
                                              value.toInt().toString(),
                                              style: const TextStyle(fontSize: 10),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    gridData: FlGridData(show: true),
                                    borderData: FlBorderData(show: false),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),


                              _buildSectionTitle("Top sản phẩm bán chạy"),
                              const SizedBox(height: 12),
                              ...topProducts.map((p) => Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      leading: const Icon(Icons.star, color: Colors.amber),
                                      title: Text(
                                        p["product__product__name"] ?? "Không có tên",
                                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
                                      ),
                                      subtitle: Text(
                                        "SL: ${p["total_qty"]} | Doanh thu: ${_formatCurrency(p["revenue"])}",
                                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 10),
                                      ),
                                    ),
                                  )),

                              const SizedBox(height: 24),


                              _buildSectionTitle("Top đánh giá cao"),
                              const SizedBox(height: 12),
                              ...topRated.map((r) => Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      leading: const Icon(Icons.thumb_up, color: Colors.green),
                                      title: Text(
                                        r["product__name"] ?? "Không có tên",
                                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
                                      
                                      ),
                                      subtitle: Text(
                                        "Số đánh giá cao từ 4-5 sao: ${r["count"]}",
                                         style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 10),
                                      ),
                                    ),
                                  )),

                              const SizedBox(height: 20),
                            ],
                          );
                        },
                      ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.blue,
      ),
    );
  }

Widget _buildStatCard({
  required String title,
  required String value,
  required IconData icon,
  required Color color,
}) {
  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: color), 
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 2), 
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}



}
