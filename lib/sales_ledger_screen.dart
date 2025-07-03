import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'services/api_service.dart';
import 'package:http/http.dart' as http;

class SalesLedgerScreen extends StatefulWidget {
  const SalesLedgerScreen({super.key});

  @override
  State<SalesLedgerScreen> createState() => _SalesLedgerScreenState();
}

class _SalesLedgerScreenState extends State<SalesLedgerScreen> {
  DateTime? fromDate;
  DateTime? toDate;
  String searchQuery = '';
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
      final data = await ApiService.getSalesLedger(
        fromDate: DateFormat('yyyy-MM-dd').format(fromDate!),
        toDate: DateFormat('yyyy-MM-dd').format(toDate!),
        search: searchQuery,
      );
      debugPrint('Fetched ledger data: ' + data.toString());
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
        errorMessage = 'Error loading sales ledger: $e';
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
                          ? const Center(child: Text('No sales ledger found.'))
                          : RefreshIndicator(
                              onRefresh: _fetchLedger,
                              child: ListView.separated(
                                itemCount: ledgerList.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final ledger = ledgerList[index];
                                  final salesDate = (ledger is Map && ledger['sales_date'] is String)
                                      ? ledger['sales_date']
                                      : '-';
                                  final invoiceNumber = (ledger is Map && ledger['invoice_number'] is String)
                                      ? ledger['invoice_number']
                                      : '-';
                                  final userName = (ledger is Map && ledger['user'] is Map && ledger['user']['name'] is String)
                                      ? ledger['user']['name']
                                      : '-';
                                  final paymentStatus = (ledger is Map && ledger['payment_status'] is String)
                                      ? ledger['payment_status']
                                      : '-';
                                  final productPrice = (ledger is Map && ledger['total_product_price'] != null)
                                      ? ledger['total_product_price'].toString()
                                      : '-';
                                  final customerPrice = (ledger is Map && ledger['total_customer_price'] != null)
                                      ? ledger['total_customer_price'].toString()
                                      : '-';
                                  Color statusColor;
                                  switch (paymentStatus.toLowerCase()) {
                                    case 'paid':
                                      statusColor = Colors.green;
                                      break;
                                    case 'pending':
                                      statusColor = Colors.orange;
                                      break;
                                    case 'failed':
                                      statusColor = Colors.red;
                                      break;
                                    default:
                                      statusColor = Colors.grey;
                                  }
                                  return InkWell(
                                    onTap: () async {
                                      // Always fetch the latest details before opening the detail screen
                                      final details = await ApiService.getSalesLedgerById(ledger['id']);
                                      final ledgerData = (details?['data'] ?? details) as Map? ?? ledger;
                                      final result = await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => SalesLedgerDetailScreen(ledger: ledgerData),
                                        ),
                                      );
                                      if (result == 'edited' || result == 'deleted') {
                                        await Future.delayed(const Duration(seconds: 1));
                                        _fetchLedger();
                                      }
                                    },
                                    child: Card(
                                      elevation: 4,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        salesDate,
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        userName,
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.w500,
                                                          fontSize: 15,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.end,
                                                  children: [
                                                    Text(
                                                      invoiceNumber,
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: statusColor.withOpacity(0.1),
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: Text(
                                                        paymentStatus.toUpperCase(),
                                                        style: TextStyle(
                                                          color: statusColor,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 16),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      const Text(
                                                        'Product Price',
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        '₹$productPrice',
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 15,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      const Text(
                                                        'Customer Price',
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        '₹$customerPrice',
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 15,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddSalesScreen()),
          );
          if (result != null) {
            _fetchLedger();
          }
        },
        child: const Icon(Icons.add),
        tooltip: 'Add New Sale',
      ),
    );
  }
}

class AddSalesScreen extends StatefulWidget {
  final Map? ledger;
  const AddSalesScreen({super.key, this.ledger});

  @override
  State<AddSalesScreen> createState() => _AddSalesScreenState();
}

class _AddSalesScreenState extends State<AddSalesScreen> {
  String userType = 'existing';
  String? selectedUser;
  List<Map<String, dynamic>> users = [];
  bool usersLoading = true;
  String usersError = '';
  String userSearch = '';
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController userRemarksController = TextEditingController();

  // Sales details
  DateTime salesDate = DateTime.now();
  final TextEditingController remarksController = TextEditingController();
  final TextEditingController companyAddressController = TextEditingController();
  String paymentStatus = 'Paid';
  String paymentMethod = 'Cash';

  // Products
  List<Map<String, dynamic>> products = [];
  bool productsLoading = true;
  String productsError = '';
  String? selectedProductId;
  final List<Map<String, dynamic>> selectedProducts = [];

  // Mock product master for batch numbers by category
  final Map<String, List<String>> productMasterBatches = {
    'Tea': ['BATCH-001', 'BATCH-002', 'BATCH-004'],
    'Honey': ['BATCH-003', 'BATCH-005'],
  };

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _fetchProducts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.ledger != null && !_initialized) {
      _prefillFromLedger(widget.ledger!);
      _initialized = true;
    }
  }

  bool _initialized = false;
  void _prefillFromLedger(Map ledger) async {
    // User
    if (ledger['user'] != null && ledger['user']['id'] != null) {
      setState(() {
        userType = 'existing';
        selectedUser = ledger['user']['id'].toString();
      });
    }
    // New user scenario (if userCheck/new user fields present)
    if (ledger['userCheck'] == 'new' || (ledger['user'] == null && ledger['name'] != null)) {
      setState(() {
        userType = 'new';
        nameController.text = ledger['name'] ?? '';
        emailController.text = ledger['email'] ?? '';
        phoneController.text = ledger['phone'] ?? '';
        userRemarksController.text = ledger['remarks'] ?? '';
      });
    }
    // Date
    if (ledger['sales_date'] != null) {
      try {
        salesDate = DateTime.parse(ledger['sales_date']);
      } catch (_) {}
    }
    // Remarks, company address
    remarksController.text = ledger['remarks'] ?? '';
    companyAddressController.text = ledger['company_address'] ?? '';
    // Payment
    paymentStatus = (ledger['payment_status'] ?? 'Paid').toString().capitalize();
    paymentMethod = (ledger['payment_method'] ?? 'Cash').toString().capitalize();
    // Products
    final prods = ledger['products'] ?? ledger['sales_ledger_products'] ?? [];
    selectedProducts.clear();
    for (final p in prods) {
      // Find product in products list (wait for fetch if needed)
      final prod = products.firstWhere(
        (pr) => pr['id'].toString() == (p['product_id']?.toString() ?? p['id']?.toString()),
        orElse: () => {},
      );
      // Fetch batch list for this product
      List<Map<String, dynamic>> batchList = [];
      final int? categoryId = prod['category_master_id'] ?? prod['category_id'] ?? p['category_master_id'] ?? p['category_id'];
      if (categoryId != null) {
        try {
          final headers = await ApiService.getApiHeaders();
          final uri = Uri.parse('${ApiService.baseUrl}/category-masters/$categoryId/product-masters');
          final response = await http.get(uri, headers: headers);
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final List masters = (data['data'] as List?) ?? [];
            batchList = masters
              .where((m) => m['batch_number'] != null && m['id'] != null)
              .map<Map<String, dynamic>>((m) => {
                'id': m['id'],
                'batch_number': m['batch_number'].toString(),
              })
              .toList();
          }
        } catch (e) {}
      }
      // Use pivot data if present
      final pivot = p['pivot'] ?? {};
      // Determine batch id from all possible fields
      final batchId = (p['product_master_id'] ?? p['batch'] ?? pivot['product_master_id'])?.toString();
      String batchCodeLabel = batchId ?? '';
      if (batchId != null && batchId.isNotEmpty) {
        final found = batchList.firstWhere(
          (b) => b['id'].toString() == batchId,
          orElse: () => {},
        );
        if (found.isNotEmpty && found['batch_number'] != null) {
          batchCodeLabel = found['batch_number'].toString();
        } else {
          // fallback: try to get from pivot or product fields
          batchCodeLabel = p['batch_code'] ?? p['batch_number'] ?? pivot['batch_code'] ?? pivot['batch_number'] ?? batchId;
          // If still not found, fetch from product master API
          if (batchCodeLabel == batchId) {
            try {
              final headers = await ApiService.getApiHeaders();
              final uri = Uri.parse('${ApiService.baseUrl}/product-masters/$batchId');
              final response = await http.get(uri, headers: headers);
              if (response.statusCode == 200) {
                final data = jsonDecode(response.body);
                final master = data['data'] ?? {};
                if (master['batch_number'] != null) {
                  batchCodeLabel = master['batch_number'].toString();
                }
              }
            } catch (e) {}
          }
        }
        debugPrint('Product: [32m${p['name'] ?? p['product_name'] ?? ''}[0m, Batch ID: $batchId, Batch Code: $batchCodeLabel');
        if (batchList.every((b) => b['id'].toString() != batchId)) {
          batchList.insert(0, {
            'id': batchId,
            'batch_number': batchCodeLabel,
          });
        }
      }
      selectedProducts.add({
        ...prod,
        ...p,
        'name': p['name'] ?? p['product_name'] ?? prod['name'] ?? '',
        'purchase_price': p['purchase_price'] ?? p['product_price'] ?? prod['purchase_price'] ?? pivot['product_price'] ?? 0,
        'selling_price': p['selling_price'] ?? prod['selling_price'] ?? pivot['selling_price'] ?? 0,
        'customer_price': p['customer_price'] ?? pivot['customer_price'] ?? prod['selling_price'] ?? 0,
        'quantity': p['quantity'] ?? pivot['quantity'] ?? 1,
        'batch': batchId ?? (batchList.isNotEmpty ? batchList[0]['id'].toString() : ''),
        'batchList': batchList,
      });
    }
    setState(() {});
  }

  Future<void> _fetchUsers() async {
    setState(() {
      usersLoading = true;
      usersError = '';
    });
    try {
      final data = await ApiService.getUsers();
      final list = (data['data'] as List?) ?? [];
      users = list.cast<Map<String, dynamic>>();
      setState(() {
        usersLoading = false;
      });
    } catch (e) {
      setState(() {
        usersError = 'Failed to load users';
        usersLoading = false;
      });
    }
  }

  Future<void> _fetchProducts() async {
    setState(() {
      productsLoading = true;
      productsError = '';
    });
    try {
      final data = await ApiService.getProducts();
      final list = (data['data'] as List?) ?? [];
      products = list.cast<Map<String, dynamic>>();
      setState(() {
        productsLoading = false;
      });
    } catch (e) {
      setState(() {
        productsError = 'Failed to load products';
        productsLoading = false;
      });
    }
  }

  void addProduct() async {
    final product = products.firstWhere((p) => p['id'].toString() == selectedProductId, orElse: () => {});
    if (product.isNotEmpty && !selectedProducts.any((sp) => sp['id'].toString() == product['id'].toString())) {
      final int? categoryId = product['category_master_id'] ?? product['category_id'];
      List<Map<String, dynamic>> batchList = [];
      if (categoryId != null) {
        try {
          final headers = await ApiService.getApiHeaders();
          final uri = Uri.parse('${ApiService.baseUrl}/category-masters/$categoryId/product-masters');
          final response = await http.get(uri, headers: headers);
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final List masters = (data['data'] as List?) ?? [];
            batchList = masters
              .where((m) => m['batch_number'] != null && m['id'] != null)
              .map<Map<String, dynamic>>((m) => {
                'id': m['id'],
                'batch_number': m['batch_number'].toString(),
              })
              .toList();
          }
        } catch (e) {
          // ignore error, fallback to empty batch list
        }
      }
      setState(() {
        selectedProducts.add({
          ...product,
          'batch': batchList.isNotEmpty ? batchList[0]['id'].toString() : '', // store product master ID as String
          'batchList': batchList, // list of {id, batch_number}
          'customer_price': product['selling_price'] ?? 0,
          'quantity': 1,
        });
      });
    }
  }

  double get overallTotal {
    double total = 0;
    for (final p in selectedProducts) {
      final price = (p['customer_price'] as num?) ?? 0;
      final qty = (p['quantity'] as num?) ?? 0;
      total += price * qty;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.ledger != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Sale' : 'Add New Sale')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User selection
            Row(
              children: [
                Radio<String>(
                  value: 'existing',
                  groupValue: userType,
                  onChanged: (v) => setState(() => userType = v!),
                ),
                const Text('Existing User'),
                const SizedBox(width: 16),
                Radio<String>(
                  value: 'new',
                  groupValue: userType,
                  onChanged: (v) => setState(() => userType = v!),
                ),
                const Text('New User'),
              ],
            ),
            if (userType == 'existing')
              usersLoading
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : usersError.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(usersError, style: const TextStyle(color: Colors.red)),
                        )
                      : GestureDetector(
                          onTap: () async {
                            final result = await Navigator.of(context).push<String>(
                              MaterialPageRoute(
                                builder: (context) => SelectUserScreen(users: users),
                              ),
                            );
                            if (result != null) {
                              setState(() => selectedUser = result);
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'Select User'),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  selectedUser != null
                                      ? users.firstWhere((u) => u['id'].toString() == selectedUser)['name'] ?? ''
                                      : 'Tap to select user',
                                  style: TextStyle(
                                    color: selectedUser != null ? Colors.black : Colors.grey[600],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
            if (userType == 'new') ...[
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              TextFormField(
                controller: userRemarksController,
                decoration: const InputDecoration(labelText: 'Remarks'),
              ),
            ],
            const SizedBox(height: 16),
            // Sales details
            Row(
              children: [
                const Text('Sales Date: '),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: salesDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => salesDate = picked);
                  },
                  child: Text(DateFormat('yyyy-MM-dd').format(salesDate)),
                ),
              ],
            ),
            TextFormField(
              controller: remarksController,
              decoration: const InputDecoration(labelText: 'Remarks'),
              maxLines: 2,
            ),
            TextFormField(
              controller: companyAddressController,
              decoration: const InputDecoration(labelText: 'Company Address'),
            ),
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
            const SizedBox(height: 16),
            // Product selection
            productsLoading
                ? const Center(child: CircularProgressIndicator())
                : productsError.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(productsError, style: const TextStyle(color: Colors.red)),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final result = await Navigator.of(context).push<String>(
                                  MaterialPageRoute(
                                    builder: (context) => SelectProductScreen(products: products),
                                  ),
                                );
                                if (result != null) {
                                  setState(() => selectedProductId = result);
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(labelText: 'Choose Product'),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      selectedProductId != null
                                          ? products.firstWhere((p) => p['id'].toString() == selectedProductId)['name'] ?? ''
                                          : 'Tap to select product',
                                      style: TextStyle(
                                        color: selectedProductId != null ? Colors.black : Colors.grey[600],
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: selectedProductId == null ? null : addProduct,
                            child: const Text('Add'),
                          ),
                        ],
                      ),
            const SizedBox(height: 16),
            // Product list
            if (selectedProducts.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Products:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: selectedProducts.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, idx) {
                        final p = selectedProducts[idx];
                        final name = p['name'] ?? p['product_name'] ?? '-';
                        final qty = p['quantity'] ?? 1;
                        final price = p['purchase_price'] ?? 0;
                        final sellingPrice = p['selling_price'] ?? 0;
                        final customerPrice = p['customer_price'] ?? sellingPrice;
                        final total = (double.tryParse(customerPrice.toString()) ?? 0) * (double.tryParse(qty.toString()) ?? 0);
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text('Product Price: ₹$price'),
                                const SizedBox(height: 4),
                                Text('Selling Price: ₹$sellingPrice'),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Text('Customer Price: ₹'),
                                    SizedBox(
                                      width: 100,
                                      child: TextFormField(
                                        initialValue: customerPrice.toString(),
                                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                                          border: OutlineInputBorder(),
                                        ),
                                        onChanged: (val) {
                                          setState(() {
                                            selectedProducts[idx]['customer_price'] = double.tryParse(val) ?? 0;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Text('Qty:'),
                                    SizedBox(
                                      width: 70,
                                      child: TextFormField(
                                        initialValue: qty.toString(),
                                        keyboardType: TextInputType.numberWithOptions(decimal: false),
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                                          border: OutlineInputBorder(),
                                        ),
                                        onChanged: (val) {
                                          setState(() {
                                            selectedProducts[idx]['quantity'] = int.tryParse(val) ?? 1;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text('Total: ₹$total', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Overall Total: ₹${selectedProducts.fold<double>(0, (sum, p) {
                        final qty = p['quantity'] ?? 1;
                        final customerPrice = p['customer_price'] ?? p['selling_price'] ?? 0;
                        return sum + (double.tryParse(customerPrice.toString()) ?? 0) * (double.tryParse(qty.toString()) ?? 0);
                      }).toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                icon: Icon(widget.ledger != null ? Icons.update : Icons.save),
                label: Text(widget.ledger != null ? 'Update' : 'Save'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  // Save or update sales ledger
                  try {
                    final headers = await ApiService.getApiHeaders();
                    final isEditing = widget.ledger != null && widget.ledger?['id'] != null;
                    final uri = isEditing
                        ? Uri.parse('${ApiService.baseUrl}/sales-ledgers/${widget.ledger!['id']}')
                        : Uri.parse('${ApiService.baseUrl}/sales-ledgers');
                    Map<String, dynamic> bodyMap = {
                      'sales_date': DateFormat('yyyy-MM-dd').format(salesDate),
                      'payment_method': paymentMethod.toLowerCase(),
                      'payment_status': paymentStatus.toLowerCase(),
                      'remarks': remarksController.text,
                      'products': selectedProducts.map((p) => {
                        'product_id': p['id'],
                        'product_name': p['name'],
                        'product_price': p['purchase_price'],
                        'selling_price': p['selling_price'],
                        'customer_price': p['customer_price'],
                        'quantity': p['quantity'],
                        'product_master_id': p['batch'],
                        'selected': true,
                      }).toList(),
                    };
                    if (userType == 'new') {
                      bodyMap['userCheck'] = 'new';
                      bodyMap['name'] = nameController.text.trim();
                      bodyMap['email'] = emailController.text.trim();
                      bodyMap['phone'] = phoneController.text.trim();
                      bodyMap['remarks'] = userRemarksController.text.trim();
                    } else {
                      final userId = selectedUser ?? users.firstOrNull?['id']?.toString();
                      if (userId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please select a user.')),
                        );
                        return;
                      }
                      bodyMap['user_id'] = userId;
                    }
                    final body = jsonEncode(bodyMap);
                    final response = isEditing
                        ? await http.put(
                            uri,
                            headers: {
                              ...headers,
                              'Content-Type': 'application/json',
                            },
                            body: body,
                          )
                        : await http.post(
                            uri,
                            headers: {
                              ...headers,
                              'Content-Type': 'application/json',
                            },
                            body: body,
                          );
                    if (response.statusCode == 200 || response.statusCode == 201) {
                      final updated = jsonDecode(response.body);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(isEditing ? 'Sale updated successfully!' : 'Sale saved successfully!')),
                      );
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context, updated['data'] ?? updated);
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to save sale: ${response.body}')),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Product'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: selectedProductId == null ? null : addProduct,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension StringCasingExtension on String {
  String capitalize() => isEmpty ? this : '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
}

num toNum(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v;
  return num.tryParse(v.toString()) ?? 0;
}

String getBatchCode(Map p) {
  final pivot = p['pivot'] ?? {};
  return p['batch_code']?.toString()
      ?? p['batch_number']?.toString()
      ?? pivot['batch_code']?.toString()
      ?? pivot['batch_number']?.toString()
      ?? p['product_master_id']?.toString()
      ?? '-';
}

Future<String> getBatchCodeAsync(Map p) async {
  final pivot = p['pivot'] ?? {};
  final batchId = (p['product_master_id'] ?? p['batch'] ?? pivot['product_master_id'])?.toString();
  if (batchId != null && batchId.isNotEmpty) {
    try {
      final headers = await ApiService.getApiHeaders();
      final uri = Uri.parse('${ApiService.baseUrl}/product-masters/$batchId');
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final master = data['data'] ?? {};
        final batchNumber = master['batch_number']?.toString();
        if (batchNumber != null) {
          return batchNumber;
        }
      }
    } catch (e) {}
  }
  return '-';
}

class SalesLedgerDetailScreen extends StatefulWidget {
  final Map ledger;
  const SalesLedgerDetailScreen({super.key, required this.ledger});

  @override
  State<SalesLedgerDetailScreen> createState() => _SalesLedgerDetailScreenState();
}

class _SalesLedgerDetailScreenState extends State<SalesLedgerDetailScreen> {
  late Map ledger;
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    ledger = widget.ledger;
  }

  Future<void> _refreshLedger() async {
    setState(() { isLoading = true; errorMessage = null; });
    try {
      final details = await ApiService.getSalesLedgerById(ledger['id']);
      setState(() {
        ledger = (details?['data'] ?? details) as Map? ?? ledger;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load details: \\${e.toString()}';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final salesDate = ledger['sales_date'] ?? '-';
    final invoiceNumber = ledger['invoice_number'] ?? '-';
    final userName = ledger['user']?['name'] ?? ledger['name'] ?? '-';
    final paymentStatus = (ledger['payment_status'] ?? '-').toString();
    final paymentMethod = (ledger['payment_method'] ?? '-').toString();
    final remarks = ledger['remarks'] ?? '-';
    final companyAddress = ledger['company_address'] ?? '-';
    final products = ledger['products'] ?? ledger['sales_ledger_products'] ?? [];
    double overallTotal = 0;
    for (final p in products) {
      final qty = p['quantity'] ?? p['pivot']?['quantity'] ?? 1;
      final price = p['customer_price'] ?? p['pivot']?['customer_price'] ?? p['selling_price'] ?? 0;
      final total = (double.tryParse(price.toString()) ?? 0) * (double.tryParse(qty.toString()) ?? 0);
      overallTotal += total;
    }
    Color statusColor;
    switch (paymentStatus.toLowerCase()) {
      case 'paid':
        statusColor = Colors.green;
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'failed':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }
    final userCreatedAt = ledger['user']?['created_at'] ?? null;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sale Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
            onPressed: () async {
              // Fetch latest details from API before editing
              try {
                final details = await ApiService.getSalesLedgerById(ledger['id']);
                final ledgerData = (details?['data'] ?? details) as Map? ?? ledger;
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AddSalesScreen(ledger: ledgerData),
                  ),
                );
                if (result != null && mounted) {
                  setState(() {
                    ledger = result as Map;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sale updated!')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to load details: \\${e.toString()}')),
                );
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
                  title: const Text('Delete Sale'),
                  content: const Text('Are you sure you want to delete this sale?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                  ],
                ),
              );
              if (confirm == true) {
                try {
                  final headers = await ApiService.getApiHeaders();
                  final id = ledger['id'];
                  final uri = Uri.parse('${ApiService.baseUrl}/sales-ledgers/$id');
                  final response = await http.delete(uri, headers: headers);
                  if (response.statusCode == 200 || response.statusCode == 204) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sale deleted successfully.')));
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context, 'deleted');
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: \\${response.body}')));
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: \\${e.toString()}')));
                }
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!, style: const TextStyle(color: Colors.red)))
              : RefreshIndicator(
                  onRefresh: _refreshLedger,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Invoice & User Info
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
                                  const Icon(Icons.receipt_long, size: 28, color: Colors.blue),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Invoice: $invoiceNumber', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Text('Date: $salesDate', style: theme.textTheme.bodyMedium),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          paymentStatus.toLowerCase() == 'paid' ? Icons.check_circle : Icons.pending,
                                          color: statusColor,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(paymentStatus.capitalize(), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.person, size: 20, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Expanded(child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(userName, style: theme.textTheme.bodyLarge),
                                      if (userCreatedAt != null && userCreatedAt.toString().isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2.0),
                                          child: Text(
                                            'Created: ${userCreatedAt.toString().substring(0, 10)}',
                                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey, fontSize: 12),
                                          ),
                                        ),
                                    ],
                                  )),
                                ],
                              ),
                              if (companyAddress != null && companyAddress.toString().trim().isNotEmpty && companyAddress != '-') ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 18, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Expanded(child: Text(companyAddress, style: theme.textTheme.bodyMedium)),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Payment Info
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
                                  const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        paymentMethod.toLowerCase() == 'cash' ? Icons.payments : Icons.account_balance,
                                        color: Colors.blue,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(paymentMethod.capitalize(), style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Remarks
                      if (remarks != null && remarks.toString().trim().isNotEmpty && remarks != '-') ...[
                        Card(
                          elevation: 0,
                          color: Colors.yellow[50],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.notes, color: Colors.amber, size: 20),
                                const SizedBox(width: 8),
                                Expanded(child: Text(remarks, style: const TextStyle(fontSize: 15))),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Product List
                      Text('Product List', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: products.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, idx) {
                            final p = products[idx];
                            final name = p['name'] ?? p['product_name'] ?? '-';
                            final qty = p['quantity'] ?? p['pivot']?['quantity'] ?? 1;
                            final price = p['customer_price'] ?? p['pivot']?['customer_price'] ?? p['selling_price'] ?? 0;
                            final total = (double.tryParse(price.toString()) ?? 0) * (double.tryParse(qty.toString()) ?? 0);
                            return ListTile(
                              leading: const Icon(Icons.shopping_bag, color: Colors.blue),
                              title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text('Qty: $qty  |  Price: ₹$price'),
                              trailing: Text('₹$total', style: const TextStyle(fontWeight: FontWeight.bold)),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text('Overall Total: ₹${overallTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class SelectUserScreen extends StatefulWidget {
  final List<Map<String, dynamic>> users;
  const SelectUserScreen({super.key, required this.users});
  @override
  State<SelectUserScreen> createState() => _SelectUserScreenState();
}

class _SelectUserScreenState extends State<SelectUserScreen> {
  String search = '';
  @override
  Widget build(BuildContext context) {
    final filteredUsers = widget.users.where((u) =>
      search.isEmpty ||
      (u['name']?.toLowerCase().contains(search.toLowerCase()) ?? false) ||
      (u['email']?.toLowerCase().contains(search.toLowerCase()) ?? false) ||
      (u['phone']?.contains(search) ?? false)
    ).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Select User')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search User',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => search = v),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: filteredUsers.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final u = filteredUsers[index];
                return ListTile(
                  title: Text(u['name'] ?? ''),
                  subtitle: Text('${u['email'] ?? ''} | ${u['phone'] ?? ''}'),
                  onTap: () => Navigator.pop(context, u['id'].toString()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class SelectProductScreen extends StatefulWidget {
  final List<Map<String, dynamic>> products;
  const SelectProductScreen({super.key, required this.products});
  @override
  State<SelectProductScreen> createState() => _SelectProductScreenState();
}

class _SelectProductScreenState extends State<SelectProductScreen> {
  String search = '';
  @override
  Widget build(BuildContext context) {
    final filteredProducts = widget.products.where((p) =>
      search.isEmpty ||
      (p['name']?.toLowerCase().contains(search.toLowerCase()) ?? false)
    ).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Select Product')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search Product',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => search = v),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: filteredProducts.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final p = filteredProducts[index];
                return ListTile(
                  title: Text(p['name'] ?? ''),
                  subtitle: Text('₹${p['selling_price']}'),
                  onTap: () => Navigator.pop(context, p['id'].toString()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 