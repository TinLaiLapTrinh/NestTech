import 'package:flutter/material.dart';
import 'package:frontend/features/stats/service/stats_service.dart';


class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  _StatsScreenState createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Map<String, dynamic>? stats;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final data = await StatisticsService.loadStatistics();
      setState(() {
        stats = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        body: Center(child: Text('Error: $error')),
      );
    }


    final isSupplier = stats!.containsKey('revenue');
    final fields = isSupplier
        ? ['total_orders_this_month', 'delivered_today', 'not_delivered', 'revenue']
        : ['delivered_today', 'total_this_month', 'shipped', 'cancelled'];

    return Scaffold(
      appBar: AppBar(
        title: Text(isSupplier ? 'Supplier Statistics' : 'Delivery Person Statistics'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: fields.map((key) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                title: Text(key.replaceAll('_', ' ').toUpperCase()),
                trailing: Text(stats![key].toString()),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
