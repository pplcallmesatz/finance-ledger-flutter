import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'services/api_service.dart';
import 'dart:convert';

class ExpenseLedgerScreen extends StatefulWidget {
  const ExpenseLedgerScreen({super.key});

  @override
  State<ExpenseLedgerScreen> createState() => _ExpenseLedgerScreenState();
}

class _ExpenseLedgerScreenState extends State<ExpenseLedgerScreen> {
  DateTime? fromDate;
  DateTime? toDate;
  bool isLoading = true;
  String? errorMessage;
  List<dynamic> ledgerList = [];

  @override
  void initState() {
    super.initState();
    _setDefaultMonth();
    _fetchLedger();
  }

  void _setDefaultMonth() {
    final now = DateTime.now();
    fromDate = DateTime(now.year, now.month, 1);
    toDate = DateTime(now.year, now.month + 1, 0);
  }

  Future<void> _fetchLedger() async {
    setState(() { isLoading = true; errorMessage = null; });
    try {
      final data = await ApiService.getExpenseLedgers(
        startDate: fromDate != null ? DateFormat('yyyy-MM-dd').format(fromDate!) : null,
        endDate: toDate != null ? DateFormat('yyyy-MM-dd').format(toDate!) : null,
      );
      List<dynamic> parsedList = [];
      if (data?['data'] is List) {
        parsedList = data?['data'] as List;
      } else if (data?['data'] is Map && data?['data']['data'] is List) {
        parsedList = data?['data']['data'] as List;
      } else {
        setState(() {
          errorMessage = 'Unexpected data format from server.';
          isLoading = false;
        });
        return;
      }
      setState(() {
        ledgerList = parsedList;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading expense ledger: $e';
        isLoading = false;
      });
    }
  }

  void _showDateFilterDialog() async {
    DateTime? tempFrom = fromDate;
    DateTime? tempTo = toDate;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Select Date Range'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('From'),
                    subtitle: Text(
                      tempFrom != null
                          ? DateFormat('yyyy-MM-dd').format(tempFrom!)
                          : '-',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: tempFrom ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            tempFrom = picked;
                          });
                        }
                      },
                    ),
                  ),
                  ListTile(
                    title: const Text('To'),
                    subtitle: Text(
                      tempTo != null
                          ? DateFormat('yyyy-MM-dd').format(tempTo!)
                          : '-',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: tempTo ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            tempTo = picked;
                          });
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
                    this.setState(() {
                      fromDate = tempFrom;
                      toDate = tempTo;
                    });
                    Navigator.pop(context);
                    _fetchLedger();
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          fromDate != null && toDate != null
              ? '${DateFormat('yyyy-MM-dd').format(fromDate!)} to ${DateFormat('yyyy-MM-dd').format(toDate!)}'
              : '',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            tooltip: 'Filter by Date',
            onPressed: _showDateFilterDialog,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : errorMessage != null
                      ? Center(child: Text(errorMessage!, style: const TextStyle(color: Colors.red)))
                      : ledgerList.isEmpty
                          ? const Center(child: Text('No expense ledger found.'))
                          : ListView.separated(
                              itemCount: ledgerList.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final ledger = ledgerList[index];
                                final purchaseDate = (ledger is Map && ledger['purchase_date'] is String)
                                    ? ledger['purchase_date']
                                    : '-';
                                final name = (ledger is Map && ledger['name'] != null)
                                    ? ledger['name'].toString()
                                    : '-';
                                final invoiceNumber = (ledger is Map && ledger['invoice_number'] != null)
                                    ? ledger['invoice_number'].toString()
                                    : '-';
                                final purchasePrice = (ledger is Map && ledger['purchase_price'] != null)
                                    ? ledger['purchase_price'].toString()
                                    : '-';
                                return Card(
                                  elevation: 2,
                                  margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(18),
                                    onTap: () async {
                                      final result = await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => ExpenseLedgerDetailScreen(ledgerId: ledger['id']),
                                        ),
                                      );
                                      if (result == true) {
                                        _fetchLedger();
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // First row: Date and Invoice Number with icon
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                purchaseDate.length >= 10 ? purchaseDate.substring(0, 10) : purchaseDate,
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                                              ),
                                              Row(
                                                children: [
                                                  Icon(Icons.receipt_long, size: 16, color: Theme.of(context).colorScheme.secondary),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    invoiceNumber,
                                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          // Second row: Name with icon
                                          Row(
                                            children: [
                                              Icon(Icons.person, size: 18, color: Theme.of(context).colorScheme.secondary),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  name,
                                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          // Third row: Amount
                                          Text(
                                            '₹$purchasePrice',
                                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context).colorScheme.primary,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddExpenseLedgerScreen()),
          );
          if (result == true) {
            _fetchLedger();
          }
        },
        child: const Icon(Icons.add),
        tooltip: 'Add New Expense',
      ),
    );
  }
}

class ExpenseLedgerDetailScreen extends StatefulWidget {
  final int ledgerId;
  const ExpenseLedgerDetailScreen({super.key, required this.ledgerId});

  @override
  State<ExpenseLedgerDetailScreen> createState() => _ExpenseLedgerDetailScreenState();
}

class _ExpenseLedgerDetailScreenState extends State<ExpenseLedgerDetailScreen> {
  bool isLoading = true;
  String? errorMessage;
  Map<String, dynamic>? ledger;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() { isLoading = true; errorMessage = null; });
    try {
      final data = await ApiService.getExpenseLedgerById(widget.ledgerId);
      setState(() {
        ledger = data?['data'] ?? data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading expense ledger: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (errorMessage != null) {
      return Scaffold(body: Center(child: Text(errorMessage!, style: const TextStyle(color: Colors.red))));
    }
    if (ledger == null) {
      return const Scaffold(body: Center(child: Text('No details found.')));
    }
    final purchaseDate = ledger?['purchase_date'] ?? '-';
    final purchasePrice = ledger?['purchase_price']?.toString() ?? '-';
    final expenseType = ledger?['expense_type']?.toString() ?? '-';
    final description = ledger?['description']?.toString() ?? '-';
    final invoiceNumber = ledger?['invoice_number']?.toString() ?? '-';
    final name = ledger?['name']?.toString() ?? '-';
    final seller = ledger?['seller']?.toString() ?? '-';
    final paymentMethod = ledger?['payment_method']?.toString() ?? '-';
    String formattedDate = purchaseDate;
    try {
      if (purchaseDate != null && purchaseDate != '-') {
        final dt = DateTime.parse(purchaseDate);
        formattedDate = DateFormat('d MMM yyyy').format(dt);
      }
    } catch (_) {}
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AddExpenseLedgerScreen(ledger: ledger),
                ),
              );
              if (result == true && context.mounted) {
                Navigator.of(context).pop(true);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Delete',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Expense'),
                  content: const Text('Are you sure you want to delete this expense?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                  ],
                ),
              );
              if (confirm == true) {
                try {
                  await ApiService.deleteExpenseLedger(widget.ledgerId);
                  if (context.mounted) Navigator.of(context).pop(true);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
                }
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailRow(Icons.receipt_long, 'Invoice Number', invoiceNumber, context),
                const SizedBox(height: 16),
                _detailRow(Icons.calendar_today, 'Purchase Date', formattedDate, context),
                const SizedBox(height: 16),
                _detailRow(Icons.person, 'Name', name, context),
                const SizedBox(height: 16),
                _detailRow(Icons.currency_rupee, 'Purchase Price', '₹$purchasePrice', context),
                const SizedBox(height: 16),
                _detailRow(Icons.store, 'Seller', seller, context),
                const SizedBox(height: 16),
                _detailRow(Icons.payment, 'Payment Method', paymentMethod, context),
                const SizedBox(height: 16),
                _detailRow(Icons.category, 'Expense Type', expenseType, context),
                const SizedBox(height: 16),
                _detailRow(Icons.description, 'Description', description, context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AddExpenseLedgerScreen extends StatefulWidget {
  final Map<String, dynamic>? ledger;
  const AddExpenseLedgerScreen({super.key, this.ledger});

  @override
  State<AddExpenseLedgerScreen> createState() => _AddExpenseLedgerScreenState();
}

class _AddExpenseLedgerScreenState extends State<AddExpenseLedgerScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime expenseDate = DateTime.now();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController invoiceController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  String paymentMethod = 'cash';
  String expenseType = 'Raw Material';
  final TextEditingController sellerController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();
  bool deduct = false;
  bool isSaving = false;

  final List<String> paymentMethods = ['cash', 'bank'];
  final List<String> expenseTypes = [
    'Raw Material',
    'Machinary',
    'Packing',
    'Marketing',
    'Travel Expense',
    'Electricity',
    'Labour',
    'Legal',
    'Research',
    'Office',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.ledger != null) {
      _prefill(widget.ledger!);
    }
  }

  void _prefill(Map<String, dynamic> ledger) {
    if (ledger['purchase_date'] != null) {
      try {
        expenseDate = DateTime.parse(ledger['purchase_date']);
      } catch (_) {}
    }
    nameController.text = ledger['name']?.toString() ?? '';
    invoiceController.text = ledger['invoice_number']?.toString() ?? '';
    amountController.text = ledger['purchase_price']?.toString() ?? '';
    paymentMethod = ledger['payment_method']?.toString() ?? 'cash';
    expenseType = ledger['expense_type']?.toString() ?? 'Raw Material';
    sellerController.text = ledger['seller']?.toString() ?? '';
    descriptionController.text = ledger['description']?.toString() ?? '';
    remarksController.text = ledger['remarks']?.toString() ?? '';
    deduct = ledger['deduct'] == 'deduct' || ledger['deduct'] == true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { isSaving = true; });
    final body = {
      'name': nameController.text.trim(),
      'invoice_number': invoiceController.text.trim(),
      'purchase_price': double.tryParse(amountController.text) ?? 0,
      'purchase_date': DateFormat('yyyy-MM-dd').format(expenseDate),
      'payment_method': paymentMethod,
      'expense_type': expenseType,
      'seller': sellerController.text.trim(),
      'description': descriptionController.text.trim(),
      'remarks': remarksController.text.trim(),
      'deduct': deduct ? 'deduct' : '0',
    };
    try {
      if (widget.ledger != null && widget.ledger?['id'] != null) {
        await ApiService.updateExpenseLedger(widget.ledger!['id'], body);
      } else {
        await ApiService.createExpenseLedger(body);
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
    final isEditing = widget.ledger != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Expense' : 'Add Expense')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Row(
                children: [
                  const Text('Date: '),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: expenseDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => expenseDate = picked);
                    },
                    child: Text(DateFormat('yyyy-MM-dd').format(expenseDate)),
                  ),
                ],
              ),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => (v == null || v.isEmpty) ? 'Enter name' : null,
              ),
              TextFormField(
                controller: invoiceController,
                decoration: const InputDecoration(labelText: 'Invoice Number'),
                validator: (v) => (v == null || v.isEmpty) ? 'Enter invoice number' : null,
              ),
              TextFormField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'Purchase Price'),
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.isEmpty) ? 'Enter purchase price' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: paymentMethod,
                decoration: const InputDecoration(labelText: 'Payment Method'),
                items: paymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(m == 'cash' ? 'Cash' : 'Bank Transfer'))).toList(),
                onChanged: (v) => setState(() => paymentMethod = v ?? 'cash'),
                validator: (v) => (v == null || v.isEmpty) ? 'Select payment method' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: expenseType,
                decoration: const InputDecoration(labelText: 'Expense Type'),
                items: expenseTypes.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => expenseType = v ?? 'Raw Material'),
                validator: (v) => (v == null || v.isEmpty) ? 'Select expense type' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: sellerController,
                decoration: const InputDecoration(labelText: 'Seller'),
                maxLines: 2,
                validator: (v) => (v == null || v.isEmpty) ? 'Enter seller' : null,
              ),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
                validator: (v) => (v == null || v.isEmpty) ? 'Enter description' : null,
              ),
              TextFormField(
                controller: remarksController,
                decoration: const InputDecoration(labelText: 'Remarks'),
                maxLines: 2,
                validator: (v) => (v == null || v.isEmpty) ? 'Enter remarks' : null,
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: deduct,
                onChanged: (v) => setState(() => deduct = v ?? false),
                title: const Text('Deduct From Account'),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton.icon(
                  icon: Icon(isEditing ? Icons.update : Icons.save),
                  label: Text(isEditing ? 'Update' : 'Save'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isSaving ? null : _save,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 