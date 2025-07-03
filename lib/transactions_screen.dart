import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'dart:convert';
import 'expense_ledger_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  bool isLoading = true;
  String? errorMessage;
  List<dynamic> transactions = [];
  String search = '';

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    setState(() { isLoading = true; errorMessage = null; });
    try {
      final data = await ApiService.getTransactions(search: search);
      List<dynamic> parsedList = [];
      if (data['data'] is List) {
        parsedList = data['data'] as List;
      } else if (data['data'] is Map && data['data']['data'] is List) {
        parsedList = data['data']['data'] as List;
      }
      setState(() {
        transactions = parsedList;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading transactions: $e';
        isLoading = false;
      });
    }
  }

  void _showAddEditDialog({Map<String, dynamic>? transaction}) async {
    final result = await showDialog(
      context: context,
      builder: (context) => AddEditTransactionDialog(transaction: transaction),
    );
    if (result == true) {
      _fetchTransactions();
    }
  }

  void _showDetails(Map<String, dynamic> transaction) async {
    await showDialog(
      context: context,
      builder: (context) => TransactionDetailDialog(transaction: transaction, onEdit: () => _showAddEditDialog(transaction: transaction), onDelete: () async {
        final confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Transaction'),
            content: const Text('Are you sure you want to delete this transaction?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
            ],
          ),
        );
        if (confirm == true) {
          try {
            await ApiService.deleteTransaction(transaction['id']);
            if (context.mounted) Navigator.pop(context); // Close details dialog
            _fetchTransactions();
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
          }
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final latest = transactions.isNotEmpty ? transactions[0] : null;
    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!, style: const TextStyle(color: Colors.red)))
              : Column(
                  children: [
                    if (latest != null)
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Card(
                          color: Colors.blue[50],
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Current Bank Balance', style: TextStyle(fontWeight: FontWeight.bold)),
                                    Text('${latest['bank_balance']}', style: const TextStyle(fontSize: 18, color: Colors.blue)),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Current Cash in Hand', style: TextStyle(fontWeight: FontWeight.bold)),
                                    Text('${latest['cash_in_hand']}', style: const TextStyle(fontSize: 18, color: Colors.green)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Card(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('No transactions yet', style: TextStyle(color: Colors.grey)),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Search',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) {
                          setState(() => search = v);
                          _fetchTransactions();
                        },
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        itemCount: transactions.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final t = transactions[index];
                          return ListTile(
                            title: Text('Bank: ${t['bank_balance']}, Cash: ${t['cash_in_hand']}'),
                            subtitle: Text(t['reason'] ?? '-'),
                            trailing: IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: () => _showDetails(t),
                            ),
                            onTap: () => _showDetails(t),
                          );
                        },
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.add),
        tooltip: 'Add Transaction',
      ),
    );
  }
}

class AddEditTransactionDialog extends StatefulWidget {
  final Map<String, dynamic>? transaction;
  const AddEditTransactionDialog({super.key, this.transaction});

  @override
  State<AddEditTransactionDialog> createState() => _AddEditTransactionDialogState();
}

class _AddEditTransactionDialogState extends State<AddEditTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController bankController = TextEditingController();
  final TextEditingController cashController = TextEditingController();
  final TextEditingController reasonController = TextEditingController();
  final TextEditingController salesLedgerController = TextEditingController();
  final TextEditingController expenseLedgerController = TextEditingController();
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      bankController.text = widget.transaction?['bank_balance']?.toString() ?? '';
      cashController.text = widget.transaction?['cash_in_hand']?.toString() ?? '';
      reasonController.text = widget.transaction?['reason'] ?? '';
      salesLedgerController.text = widget.transaction?['sales_ledger_id']?.toString() ?? '';
      expenseLedgerController.text = widget.transaction?['expense_ledger_id']?.toString() ?? '';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { isSaving = true; });
    final body = {
      'bank_balance': double.tryParse(bankController.text) ?? 0,
      'cash_in_hand': double.tryParse(cashController.text) ?? 0,
      if (reasonController.text.isNotEmpty) 'reason': reasonController.text.trim(),
      if (salesLedgerController.text.isNotEmpty) 'sales_ledger_id': int.tryParse(salesLedgerController.text),
      if (expenseLedgerController.text.isNotEmpty) 'expense_ledger_id': int.tryParse(expenseLedgerController.text),
    };
    try {
      if (widget.transaction != null && widget.transaction?['id'] != null) {
        await ApiService.updateTransaction(widget.transaction!['id'], body);
      } else {
        await ApiService.createTransaction(body);
      }
      if (context.mounted) Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    } finally {
      setState(() { isSaving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.transaction != null ? 'Edit Transaction' : 'Add Transaction'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: bankController,
                decoration: const InputDecoration(labelText: 'Bank Balance'),
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.isEmpty) ? 'Enter bank balance' : null,
              ),
              TextFormField(
                controller: cashController,
                decoration: const InputDecoration(labelText: 'Cash in Hand'),
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.isEmpty) ? 'Enter cash in hand' : null,
              ),
              TextFormField(
                controller: reasonController,
                decoration: const InputDecoration(labelText: 'Reason (optional)'),
              ),
              TextFormField(
                controller: salesLedgerController,
                decoration: const InputDecoration(labelText: 'Sales Ledger ID (optional)'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: expenseLedgerController,
                decoration: const InputDecoration(labelText: 'Expense Ledger ID (optional)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
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

class TransactionDetailDialog extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const TransactionDetailDialog({super.key, required this.transaction, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final expenseLedgerId = transaction['expense_ledger_id'];
    return AlertDialog(
      title: const Text('Transaction Details'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ID: ${transaction['id'] ?? '-'}'),
          Text('Bank Balance: ${transaction['bank_balance'] ?? '-'}'),
          Text('Cash in Hand: ${transaction['cash_in_hand'] ?? '-'}'),
          Text('Reason: ${transaction['reason'] ?? '-'}'),
          Text('Sales Ledger ID: ${transaction['sales_ledger_id'] ?? '-'}'),
          if (expenseLedgerId != null)
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ExpenseLedgerDetailScreen(ledgerId: expenseLedgerId),
                  ),
                );
              },
              child: Row(
                children: [
                  const Text('Expense Ledger ID: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    expenseLedgerId.toString(),
                    style: const TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.open_in_new, size: 16, color: Colors.blue),
                ],
              ),
            )
          else
            Text('Expense Ledger ID: -'),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        TextButton(onPressed: onEdit, child: const Text('Edit')),
        TextButton(onPressed: onDelete, child: const Text('Delete', style: TextStyle(color: Colors.red))),
      ],
    );
  }
} 