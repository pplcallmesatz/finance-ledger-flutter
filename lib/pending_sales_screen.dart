import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class PendingSalesScreen extends StatefulWidget {
  const PendingSalesScreen({super.key});

  @override
  State<PendingSalesScreen> createState() => _PendingSalesScreenState();
}

class _PendingSalesScreenState extends State<PendingSalesScreen> {
  bool isLoading = true;
  String? errorMessage;
  List<dynamic> pendingList = [];
  num totalPending = 0;
  final Map<int, String> _userNameCache = {};

  @override
  void initState() {
    super.initState();
    _fetchPending();
  }

  Future<void> _fetchPending() async {
    setState(() { isLoading = true; errorMessage = null; });
    try {
      final data = await ApiService.getAllPendingSalesLedgers();
      List<dynamic> parsedList = [];
      if (data['data'] is List) {
        parsedList = data['data'] as List;
      }
      setState(() {
        pendingList = parsedList;
        totalPending = data['total_pending'] ?? 0;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading pending sales: $e';
        isLoading = false;
      });
    }
  }

  void _showDetail(Map ledger) async {
    final result = await showDialog(
      context: context,
      builder: (context) => PendingSalesDetailDialog(ledger: ledger),
    );
    if (result is Map && result['ledger'] != null) {
      _fetchPending();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Payments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: isLoading ? null : _fetchPending,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!, style: const TextStyle(color: Colors.red)))
              : Column(
                  children: [
                    Card(
                      margin: const EdgeInsets.all(12),
                      color: Colors.orange[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Pending Amount:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('₹${totalPending.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, color: Colors.orange)),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: pendingList.isEmpty
                          ? const Center(child: Text('No pending sales found.'))
                          : ListView.separated(
                              itemCount: pendingList.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final ledger = pendingList[index];
                                final user = ledger['user'];
                                String customerName = '-';
                                if (user != null && user is Map && user['name'] != null && user['name'].toString().trim().isNotEmpty) {
                                  customerName = user['name'];
                                } else if (ledger['name'] != null && ledger['name'].toString().trim().isNotEmpty) {
                                  customerName = ledger['name'];
                                } else if (ledger['user_id'] != null) {
                                  final int userId = ledger['user_id'] is int ? ledger['user_id'] : int.tryParse(ledger['user_id'].toString()) ?? 0;
                                  if (userId > 0) {
                                    if (_userNameCache.containsKey(userId)) {
                                      customerName = _userNameCache[userId]!;
                                    } else {
                                      customerName = 'Loading...';
                                      _fetchAndCacheUserName(userId);
                                    }
                                  }
                                }
                                final pendingAmount = ledger['total_customer_price'] ?? 0;
                                final invoiceNumber = ledger['invoice_number'] ?? '-';
                                final dateRaw = ledger['sales_date'] ?? ledger['created_at'] ?? null;
                                String dateStr = '-';
                                if (dateRaw != null && dateRaw is String && dateRaw.isNotEmpty) {
                                  try {
                                    dateStr = DateFormat('yyyy-MM-dd').format(DateTime.parse(dateRaw));
                                  } catch (_) {
                                    dateStr = dateRaw;
                                  }
                                }
                                return ListTile(
                                  title: Text('Invoice: $invoiceNumber'),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Date: $dateStr'),
                                      Text('Customer: $customerName'),
                                      Text('Pending: ₹$pendingAmount'),
                                    ],
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () => _showDetail(ledger),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }

  void _fetchAndCacheUserName(int userId) async {
    if (_userNameCache.containsKey(userId)) return;
    try {
      final data = await ApiService.getUserById(userId);
      final name = data['data']?['name'] ?? data['name'] ?? '-';
      setState(() {
        _userNameCache[userId] = name;
      });
    } catch (_) {
      setState(() {
        _userNameCache[userId] = '-';
      });
    }
  }
}

class PendingSalesDetailDialog extends StatefulWidget {
  final Map ledger;
  const PendingSalesDetailDialog({super.key, required this.ledger});

  @override
  State<PendingSalesDetailDialog> createState() => _PendingSalesDetailDialogState();
}

class _PendingSalesDetailDialogState extends State<PendingSalesDetailDialog> {
  late String paymentStatus;
  late String paymentMethod;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    paymentStatus = (widget.ledger['payment_status'] ?? 'pending').toString().capitalize();
    paymentMethod = (widget.ledger['payment_method'] ?? 'Cash').toString().capitalize();
  }

  Future<void> _save() async {
    setState(() { isSaving = true; });
    try {
      final response = await ApiService.patchSalesLedgerPaymentInfo(widget.ledger['id'], {
        'payment_status': paymentStatus.toLowerCase(),
        'payment_method': paymentMethod.toLowerCase(),
      });
      if (context.mounted) Navigator.of(context).pop({'ledger': response['data'], 'transaction': response['transaction']});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
    } finally {
      setState(() { isSaving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update Payment'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Invoice: ${widget.ledger['invoice_number'] ?? '-'}'),
          Text('Customer: ${widget.ledger['user']?['name'] ?? '-'}'),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: paymentStatus,
            decoration: const InputDecoration(labelText: 'Payment Status'),
            items: const [
              DropdownMenuItem(value: 'Paid', child: Text('Paid')),
              DropdownMenuItem(value: 'Pending', child: Text('Pending')),
            ],
            onChanged: (v) => setState(() => paymentStatus = v!),
          ),
          DropdownButtonFormField<String>(
            value: paymentMethod,
            decoration: const InputDecoration(labelText: 'Payment Method'),
            items: const [
              DropdownMenuItem(value: 'Cash', child: Text('Cash')),
              DropdownMenuItem(value: 'Bank', child: Text('Bank')),
              DropdownMenuItem(value: 'Website', child: Text('Website')),
            ],
            onChanged: (v) => setState(() => paymentMethod = v!),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: isSaving ? null : _save,
          child: isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
        ),
      ],
    );
  }
}

extension StringCasingExtension on String {
  String capitalize() => isEmpty ? this : '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
} 