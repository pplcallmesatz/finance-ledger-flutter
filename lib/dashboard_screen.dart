import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sales_ledger_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? userName;
  Map<String, dynamic>? statistics;
  bool isLoading = true;
  String? errorMessage;
  DateTime? fromDate;
  DateTime? toDate;
  List<dynamic>? categoryInventory;
  Map<String, List<dynamic>>? productsByCategory;

  @override
  void initState() {
    super.initState();
    _setDefaultFinancialYear();
    _loadUserNameAndStats();
    _loadInventoryStatus();
  }

  void _setDefaultFinancialYear() {
    final now = DateTime.now();
    final int year = now.month >= 4 ? now.year : now.year - 1;
    fromDate = DateTime(year, 4, 1);
    toDate = DateTime(year + 1, 3, 31);
  }

  Future<void> _loadInventoryStatus() async {
    try {
      final inventoryStatus = await ApiService.getInventoryStatus();
      setState(() {
        categoryInventory = (inventoryStatus?['data']?['category_inventory'] as List?)?.toList() ?? [];
        categoryInventory!.sort((a, b) {
          final int qtyA = int.tryParse(a['total_available_quantity'].toString()) ?? 0;
          final int qtyB = int.tryParse(b['total_available_quantity'].toString()) ?? 0;
          return qtyA.compareTo(qtyB);
        });
      });
    } catch (e) {
      setState(() {
        categoryInventory = null;
      });
    }
  }

  Future<void> _loadUserNameAndStats() async {
    setState(() { isLoading = true; });
    try {
      final user = await ApiService.getCurrentUserInfo();
      final overview = await ApiService.getDashboardOverview(
        startDate: DateFormat('yyyy-MM-dd').format(fromDate!),
        endDate: DateFormat('yyyy-MM-dd').format(toDate!),
      );
      setState(() {
        userName = user != null && user['name'] != null ? user['name'] : null;
        statistics = overview['data']?['statistics'];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        userName = null;
        statistics = null;
        isLoading = false;
        errorMessage = 'Error loading dashboard: $e';
      });
    }
  }

  void _showFilterDialog() async {
    DateTime? tempFrom = fromDate;
    DateTime? tempTo = toDate;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Financial Year'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('From'),
                subtitle: Text(DateFormat('yyyy-MM-dd').format(tempFrom!)),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: tempFrom!,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() { tempFrom = picked; });
                    }
                  },
                ),
              ),
              ListTile(
                title: const Text('To'),
                subtitle: Text(DateFormat('yyyy-MM-dd').format(tempTo!)),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: tempTo!,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() { tempTo = picked; });
                    }
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  fromDate = tempFrom;
                  toDate = tempTo;
                });
                Navigator.pop(context);
                _loadUserNameAndStats();
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : errorMessage != null
            ? Center(
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            userName != null ? 'Welcome, $userName' : 'Welcome',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.filter_alt),
                          tooltip: 'Filter by Financial Year',
                          onPressed: _showFilterDialog,
                        ),
                      ],
                    ),
                    if (fromDate != null && toDate != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          'Financial Year: ${DateFormat('yyyy-MM-dd').format(fromDate!)} to ${DateFormat('yyyy-MM-dd').format(toDate!)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    if (statistics != null)
                      ListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildStatCard(
                            'Total Pending',
                            '₹${_formatNumber(statistics!['total_pending'])}',
                            Icons.pending,
                            Colors.orange,
                          ),
                          _buildStatCard(
                            'Total Profit',
                            '₹${_formatNumber(statistics!['total_profit'])}',
                            Icons.account_balance_wallet,
                            Colors.blue,
                          ),
                          _buildStatCard(
                            'Total Sales',
                            '₹${_formatNumber(statistics!['total_sales'])}',
                            Icons.trending_up,
                            Colors.green,
                          ),
                          _buildStatCard(
                            'Total Expenses',
                            '₹${_formatNumber(statistics!['total_expenses'])}',
                            Icons.trending_down,
                            Colors.red,
                          ),
                        ],
                      ),
                    if (categoryInventory != null && categoryInventory!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
                        child: Text(
                          'Product Availability',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    if (categoryInventory != null && categoryInventory!.isNotEmpty)
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: categoryInventory!.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final cat = categoryInventory![index];
                          final int qty = int.tryParse(cat['total_available_quantity'].toString()) ?? 0;
                          Widget? badge;
                          if (qty < 0) {
                            badge = Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Warning',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            );
                          } else if (qty < 5) {
                            badge = Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Low Stock',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            );
                          }
                          return ListTile(
                            title: Text(cat['category_name'] ?? 'Unknown'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$qty',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                if (badge != null) ...[
                                  const SizedBox(width: 8),
                                  badge,
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
              textAlign: TextAlign.right,
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(dynamic value) {
    if (value == null) return '0.00';
    final num? number = num.tryParse(value.toString());
    if (number == null) return '0.00';
    return number.toStringAsFixed(2);
  }
} 