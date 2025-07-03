import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'package:intl/intl.dart';
import 'sales_ledger_screen.dart';

class UserDetailScreen extends StatefulWidget {
  final Map user;
  const UserDetailScreen({super.key, required this.user});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  bool isLoading = true;
  String? errorMessage;
  List<dynamic> pendingSales = [];
  List<dynamic> paidSales = [];
  num totalPending = 0;
  num totalPaid = 0;
  Map userDetails = {};

  @override
  void initState() {
    super.initState();
    _fetchUserSales();
  }

  Future<void> _fetchUserSales() async {
    setState(() { isLoading = true; errorMessage = null; });
    try {
      final details = await ApiService.getUserDetails(widget.user['id']);
      setState(() {
        userDetails = details['user'] ?? {};
        totalPending = details['total_pending'] ?? 0;
        totalPaid = details['total_paid'] ?? 0;
        pendingSales = details['pending_entries'] ?? [];
        paidSales = details['paid_entries'] ?? [];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load sales: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = userDetails.isNotEmpty ? userDetails : widget.user;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('User Details')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!, style: const TextStyle(color: Colors.red)))
              : RefreshIndicator(
                  onRefresh: () async => _fetchUserSales(),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // User Info Card
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const CircleAvatar(
                                    child: Icon(Icons.person, size: 28),
                                    radius: 28,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(user['name'] ?? '', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                                        if ((user['created_at'] ?? '').toString().isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 2.0),
                                            child: Text(
                                              'Created: ${user['created_at'].toString().substring(0, 10)}',
                                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey, fontSize: 12),
                                            ),
                                          ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.phone, size: 16, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text(user['phone'] ?? '-', style: theme.textTheme.bodyMedium),
                                          ],
                                        ),
                                        if ((user['email'] ?? '').toString().isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              const Icon(Icons.email, size: 16, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text(user['email'], style: theme.textTheme.bodyMedium),
                                            ],
                                          ),
                                        ],
                                        if ((user['remarks'] ?? user['remark'] ?? '').toString().isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              const Icon(Icons.notes, size: 16, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Flexible(child: Text(user['remarks'] ?? user['remark'], style: theme.textTheme.bodyMedium)),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Totals Card
                      Card(
                        color: theme.colorScheme.surfaceVariant,
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Column(
                                children: [
                                  const Text('Total Pending', style: TextStyle(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Text('₹$totalPending', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
                                ],
                              ),
                              Container(width: 1, height: 32, color: Colors.grey[300]),
                              Column(
                                children: [
                                  const Text('Total Paid', style: TextStyle(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Text('₹$totalPaid', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Pending Sales Section
                      Text('Pending Sales', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.red)),
                      const SizedBox(height: 8),
                      pendingSales.isEmpty
                          ? const Text('No pending sales.', style: TextStyle(color: Colors.grey))
                          : Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              child: ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: pendingSales.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, idx) {
                                  final sale = pendingSales[idx];
                                  return ListTile(
                                    leading: const Icon(Icons.pending_actions, color: Colors.red),
                                    title: Text('Invoice: ${sale['invoice_number'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Date: ${sale['sales_date'] ?? '-'}'),
                                        Text('Pending: ₹${sale['total_customer_price'] ?? 0}', style: const TextStyle(color: Colors.red)),
                                        if ((sale['remarks'] ?? '').toString().isNotEmpty)
                                          Text('Remarks: ${sale['remarks']}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                      ],
                                    ),
                                    onTap: () async {
                                      final id = sale['id'];
                                      if (id != null) {
                                        try {
                                          final details = await ApiService.getSalesLedgerById(id);
                                          final ledgerData = (details?['data'] ?? details) as Map? ?? sale;
                                          // ignore: use_build_context_synchronously
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => SalesLedgerDetailScreen(ledger: ledgerData),
                                            ),
                                          );
                                        } catch (e) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Failed to load details: $e')),
                                          );
                                        }
                                      }
                                    },
                                  );
                                },
                              ),
                            ),
                      const SizedBox(height: 24),
                      // Paid Sales Section
                      Text('Paid Sales', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.green)),
                      const SizedBox(height: 8),
                      paidSales.isEmpty
                          ? const Text('No paid sales.', style: TextStyle(color: Colors.grey))
                          : Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              child: ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: paidSales.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, idx) {
                                  final sale = paidSales[idx];
                                  return ListTile(
                                    leading: const Icon(Icons.check_circle, color: Colors.green),
                                    title: Text('Invoice: ${sale['invoice_number'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Date: ${sale['sales_date'] ?? '-'}'),
                                        Text('Paid: ₹${sale['total_customer_price'] ?? 0}', style: const TextStyle(color: Colors.green)),
                                        if ((sale['remarks'] ?? '').toString().isNotEmpty)
                                          Text('Remarks: ${sale['remarks']}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                      ],
                                    ),
                                    onTap: () async {
                                      final id = sale['id'];
                                      if (id != null) {
                                        try {
                                          final details = await ApiService.getSalesLedgerById(id);
                                          final ledgerData = (details?['data'] ?? details) as Map? ?? sale;
                                          // ignore: use_build_context_synchronously
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => SalesLedgerDetailScreen(ledger: ledgerData),
                                            ),
                                          );
                                        } catch (e) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Failed to load details: $e')),
                                          );
                                        }
                                      }
                                    },
                                  );
                                },
                              ),
                            ),
                    ],
                  ),
                ),
    );
  }
} 