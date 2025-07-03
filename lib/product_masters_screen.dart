import 'package:flutter/material.dart';
import 'services/api_service.dart';

class ProductMastersScreen extends StatefulWidget {
  const ProductMastersScreen({super.key});

  @override
  State<ProductMastersScreen> createState() => _ProductMastersScreenState();
}

class _ProductMastersScreenState extends State<ProductMastersScreen> {
  List<dynamic> productMasters = [];
  List<dynamic> categories = [];
  int? selectedCategoryId;
  String search = '';
  int currentPage = 1;
  int totalPages = 1;
  bool isLoading = true;
  String? errorMessage;
  final TextEditingController searchController = TextEditingController();
  bool _userChangedTotalPiece = false;
  String _lastQtyValue = '';
  late TextEditingController batchNumberController;

  @override
  void initState() {
    super.initState();
    _fetchCategoriesAndProductMasters();
  }

  Future<void> _fetchCategoriesAndProductMasters() async {
    setState(() { isLoading = true; errorMessage = null; });
    try {
      final catResp = await ApiService.getCategories(perPage: 100);
      final cats = catResp['data'] as List? ?? [];
      setState(() { categories = cats; });
      await _fetchProductMasters();
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load categories: $e';
      });
    }
  }

  Future<void> _fetchProductMasters({int? page}) async {
    setState(() { isLoading = true; errorMessage = null; });
    try {
      final resp = await ApiService.getProductMasters(
        search: search.isNotEmpty ? search : null,
        categoryId: selectedCategoryId,
        perPage: 15,
        page: page ?? currentPage,
      );
      final data = resp['data'] as List? ?? [];
      setState(() {
        productMasters = data;
        isLoading = false;
        currentPage = resp['meta']?['current_page'] ?? 1;
        totalPages = resp['meta']?['last_page'] ?? 1;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load product masters: $e';
      });
    }
  }

  void _onCategoryChanged(int? catId) {
    setState(() { selectedCategoryId = catId; currentPage = 1; });
    _fetchProductMasters();
  }

  void _onSearchChanged(String value) {
    setState(() { search = value; currentPage = 1; });
    _fetchProductMasters();
  }

  void _onPageChanged(int newPage) {
    if (newPage < 1 || newPage > totalPages) return;
    setState(() { currentPage = newPage; });
    _fetchProductMasters(page: newPage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product Masters')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    value: selectedCategoryId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Filter by Category',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('All Categories'),
                      ),
                      ...categories.map<DropdownMenuItem<int?>>((cat) => DropdownMenuItem(
                        value: cat['id'],
                        child: Text(cat['name'] ?? ''),
                      )),
                    ],
                    onChanged: (catId) {
                      setState(() {
                        selectedCategoryId = catId;
                        currentPage = 1;
                      });
                      _fetchProductMasters();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      if (v.length >= 2 || v.isEmpty) _onSearchChanged(v);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator())),
            if (!isLoading && errorMessage != null)
              Expanded(
                child: Center(
                  child: Text(errorMessage!, style: const TextStyle(color: Colors.red)),
                ),
              ),
            if (!isLoading && errorMessage == null)
              productMasters.isEmpty
                  ? const Expanded(child: Center(child: Text('No product masters found.')))
                  : Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: ListView.separated(
                              itemCount: productMasters.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final pm = productMasters[index];
                                return InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (ctx) => ProductMasterDetailScreen(productMaster: pm, categories: categories),
                                      ),
                                    );
                                    if (result == true) _fetchProductMasters();
                                  },
                                  child: Card(
                                    elevation: 0,
                                    color: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: BorderSide(color: Colors.grey[300]!, width: 1),
                                    ),
                                    margin: EdgeInsets.zero,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            pm['name'] ?? '-',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.2),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Text('Batch: ', style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500)),
                                              Text(pm['batch_number'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600)),
                                              const SizedBox(width: 16),
                                              Text('Exp. ', style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500)),
                                              _ExpireBadge(date: pm['expire_date'], small: true),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [
                                              Text('Avail. Qty: ', style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500)),
                                              Text('${pm['total_piece'] ?? pm['quantity_purchased'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                              const SizedBox(width: 24),
                                              Text('Per Unit: ', style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500)),
                                              Text('₹${_calcPerUnitCost(pm)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left),
                                onPressed: currentPage > 1 ? () => _onPageChanged(currentPage - 1) : null,
                              ),
                              Text('Page $currentPage of $totalPages'),
                              IconButton(
                                icon: const Icon(Icons.chevron_right),
                                onPressed: currentPage < totalPages ? () => _onPageChanged(currentPage + 1) : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => ProductMasterFormScreen(categories: categories, onSaved: (data) async {
                await ApiService.createProductMaster(data);
              }),
            ),
          );
          if (result == true) _fetchProductMasters();
        },
        child: const Icon(Icons.add),
        tooltip: 'Add Product Master',
      ),
    );
  }

  String _getCategoryName(int? id) {
    if (id == null) return '-';
    final cat = categories.firstWhere((c) => c['id'] == id, orElse: () => null);
    return cat != null ? cat['name'] ?? '-' : '-';
  }

  String _formatDate(dynamic date) {
    if (date == null) return '-';
    final d = DateTime.tryParse(date.toString());
    if (d == null) return date.toString();
    return '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
  }

  String _calcPerUnitCost(Map pm) {
    final purchase = (pm['purchase_price'] is num) ? pm['purchase_price'] : double.tryParse(pm['purchase_price']?.toString() ?? '') ?? 0;
    final transport = (pm['transportation_cost'] is num) ? pm['transportation_cost'] : double.tryParse(pm['transportation_cost']?.toString() ?? '') ?? 0;
    final qty = (pm['quantity_purchased'] is num) ? pm['quantity_purchased'] : double.tryParse(pm['quantity_purchased']?.toString() ?? '') ?? 0;
    if (qty == 0) return '-';
    final perUnit = (purchase + transport) / qty;
    return perUnit.toStringAsFixed(2);
  }
}

class ProductMasterFormScreen extends StatefulWidget {
  final List categories;
  final Map? initial;
  final Future<void> Function(Map<String, dynamic>) onSaved;
  const ProductMasterFormScreen({super.key, required this.categories, this.initial, required this.onSaved});

  @override
  State<ProductMasterFormScreen> createState() => _ProductMasterFormScreenState();
}

class _ProductMasterFormScreenState extends State<ProductMasterFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController purchasePriceController;
  late TextEditingController purchaseDateController;
  late TextEditingController manufacturingDateController;
  late TextEditingController transportationCostController;
  late TextEditingController invoiceNumberController;
  late TextEditingController quantityPurchasedController;
  late TextEditingController vendorController;
  late TextEditingController expireDateController;
  late TextEditingController totalPieceController;
  late TextEditingController batchNumberController;
  int? categoryId;
  int? selfLifeMonths;
  bool _userChangedTotalPiece = false;
  String _lastQtyValue = '';
  late List _categoriesForDropdown;

  @override
  void initState() {
    final i = widget.initial ?? {};
    nameController = TextEditingController(text: i['name']?.toString() ?? '');
    purchasePriceController = TextEditingController(text: i['purchase_price']?.toString() ?? '');
    purchaseDateController = TextEditingController(text: _dateOnly(i['purchase_date']?.toString()));
    manufacturingDateController = TextEditingController(text: _dateOnly(i['manufacturing_date']?.toString()));
    transportationCostController = TextEditingController(text: i['transportation_cost']?.toString() ?? '');
    invoiceNumberController = TextEditingController(text: i['invoice_number']?.toString() ?? '');
    quantityPurchasedController = TextEditingController(text: i['quantity_purchased']?.toString() ?? '');
    vendorController = TextEditingController(text: i['vendor']?.toString() ?? '');
    expireDateController = TextEditingController(text: _dateOnly(i['expire_date']?.toString()));
    totalPieceController = TextEditingController(text: i['total_piece']?.toString() ?? '');
    // Batch number: auto-generate if adding new
    if (widget.initial == null) {
      final now = DateTime.now();
      final batchCode = 'BATCH-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-'
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
      batchNumberController = TextEditingController(text: batchCode);
    } else {
      batchNumberController = TextEditingController(text: i['batch_number']?.toString() ?? '');
    }
    categoryId = i['category_id'] is int ? i['category_id'] : int.tryParse(i['category_id']?.toString() ?? '');
    // Set selfLifeMonths from initial category (for edit mode)
    if (categoryId != null) {
      final cat = widget.categories.firstWhere(
        (c) => c['id'] == categoryId,
        orElse: () => null,
      );
      if (cat != null) {
        selfLifeMonths = cat['self_life'] is int ? cat['self_life'] : int.tryParse(cat['self_life']?.toString() ?? '');
      }
    }
    if (i['quantity_purchased'] != null && (i['total_piece'] == null || i['total_piece'].toString().isEmpty)) {
      totalPieceController.text = i['quantity_purchased'].toString();
    }
    _categoriesForDropdown = List.from(widget.categories);
    if (categoryId != null && _categoriesForDropdown.where((c) => c['id'] == categoryId).isEmpty) {
      String? catName;
      if (widget.categories.isNotEmpty) {
        final found = widget.categories.firstWhere(
          (c) => c['id'].toString() == categoryId.toString(),
          orElse: () => null,
        );
        if (found != null) catName = found['name'];
      }
      catName ??= (i['category']?['name'] ?? i['category_master']?['name']);
      catName ??= 'Unknown';
      _categoriesForDropdown.add({
        'id': categoryId,
        'name': catName,
      });
    }
    manufacturingDateController.addListener(_autoCalcExpireDate);
    if (manufacturingDateController.text.isNotEmpty && selfLifeMonths != null) {
      _autoCalcExpireDate();
    }
    super.initState();
  }

  @override
  void dispose() {
    manufacturingDateController.removeListener(_autoCalcExpireDate);
    super.dispose();
  }

  void _autoCalcExpireDate() {
    if (manufacturingDateController.text.isEmpty || selfLifeMonths == null) return;
    final mfg = DateTime.tryParse(manufacturingDateController.text);
    if (mfg == null) return;
    final expMonth = DateTime(mfg.year, mfg.month + selfLifeMonths!, mfg.day);
    final exp = expMonth.subtract(const Duration(days: 1));
    expireDateController.text =
      '${exp.year.toString().padLeft(4, '0')}-${exp.month.toString().padLeft(2, '0')}-${exp.day.toString().padLeft(2, '0')}';
  }

  void _onCategoryChanged(int? v) {
    setState(() {
      categoryId = v;
      final cat = _categoriesForDropdown.firstWhere((c) => c['id'] == v, orElse: () => null);
      selfLifeMonths = cat != null ? (cat['self_life'] is int ? cat['self_life'] : int.tryParse(cat['self_life']?.toString() ?? '')) : null;
      _autoCalcExpireDate();
    });
  }

  Widget _sectionHeader(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16.0),
    child: Row(
      children: [
        Icon(Icons.label_important, color: Theme.of(context).primaryColor),
        const SizedBox(width: 8),
        Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.initial == null ? 'Add Product Master' : 'Edit Product Master')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionHeader('Product Info'),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Product Name',
                        prefixIcon: Icon(Icons.shopping_bag),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    // Only show batch number field in edit mode
                    if (widget.initial != null) ...[
                      TextFormField(
                        controller: batchNumberController,
                        decoration: const InputDecoration(labelText: 'Batch Number'),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                    ],
                    DropdownButtonFormField<int>(
                      value: categoryId,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: _categoriesForDropdown.map<DropdownMenuItem<int>>((cat) => DropdownMenuItem(
                        value: cat['id'],
                        child: Text(cat['name'] ?? ''),
                      )).toList(),
                      onChanged: _onCategoryChanged,
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 24),
                    _sectionHeader('Dates'),
                    TextFormField(
                      controller: purchaseDateController,
                      decoration: const InputDecoration(
                        labelText: 'Purchase Date',
                        prefixIcon: Icon(Icons.event),
                        hintText: 'YYYY-MM-DD',
                      ),
                      onTap: () async {
                        FocusScope.of(context).requestFocus(FocusNode());
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          purchaseDateController.text = '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                        }
                      },
                      readOnly: true,
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: manufacturingDateController,
                      decoration: const InputDecoration(
                        labelText: 'Manufacturing Date',
                        prefixIcon: Icon(Icons.precision_manufacturing),
                        hintText: 'YYYY-MM-DD',
                      ),
                      onTap: () async {
                        FocusScope.of(context).requestFocus(FocusNode());
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          manufacturingDateController.text = '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                        }
                      },
                      readOnly: true,
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: expireDateController,
                      decoration: InputDecoration(
                        labelText: 'Expire Date',
                        prefixIcon: const Icon(Icons.hourglass_bottom),
                        hintText: 'YYYY-MM-DD',
                        helperText: selfLifeMonths != null ? 'Auto: Manufacturing Date + $selfLifeMonths months (from category)' : 'Auto-calculated from category',
                      ),
                      onTap: () async {
                        FocusScope.of(context).requestFocus(FocusNode());
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          expireDateController.text = '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                        }
                      },
                      readOnly: true,
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 24),
                    _sectionHeader('Quantities & Cost'),
                    TextFormField(
                      controller: purchasePriceController,
                      decoration: const InputDecoration(
                        labelText: 'Purchase Price',
                        prefixIcon: Icon(Icons.currency_rupee),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.right,
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: transportationCostController,
                      decoration: const InputDecoration(
                        labelText: 'Transportation Cost',
                        prefixIcon: Icon(Icons.local_shipping),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.right,
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: quantityPurchasedController,
                      decoration: const InputDecoration(
                        labelText: 'Quantity Purchased',
                        prefixIcon: Icon(Icons.confirmation_number),
                      ),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.right,
                      onChanged: (v) {
                        if (!_userChangedTotalPiece) {
                          totalPieceController.text = v;
                        }
                      },
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: totalPieceController,
                      decoration: const InputDecoration(
                        labelText: 'Total Piece (Available Qty)',
                        prefixIcon: Icon(Icons.inventory_2),
                      ),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.right,
                      onChanged: (v) {
                        _userChangedTotalPiece = v.isNotEmpty;
                      },
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: invoiceNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Invoice Number',
                        prefixIcon: Icon(Icons.receipt_long),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: vendorController,
                      decoration: const InputDecoration(
                        labelText: 'Vendor',
                        prefixIcon: Icon(Icons.store),
                        helperText: 'Supplier or vendor name',
                      ),
                      maxLines: 2,
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.save),
                          onPressed: () async {
                            if (_formKey.currentState?.validate() != true) return;
                            final data = {
                              'name': nameController.text.trim(),
                              'batch_number': batchNumberController.text.trim(), // always send, but only editable in edit mode
                              'purchase_price': double.tryParse(purchasePriceController.text) ?? 0,
                              'purchase_date': purchaseDateController.text.trim(),
                              'manufacturing_date': manufacturingDateController.text.trim(),
                              'transportation_cost': double.tryParse(transportationCostController.text) ?? 0,
                              'invoice_number': invoiceNumberController.text.trim(),
                              'quantity_purchased': int.tryParse(quantityPurchasedController.text) ?? 0,
                              'vendor': vendorController.text.trim(),
                              'category_id': categoryId,
                              'expire_date': expireDateController.text.trim(),
                              'total_piece': totalPieceController.text.trim(),
                            };
                            await widget.onSaved(data);
                            Navigator.of(context).pop(true);
                          },
                          label: const Text('Save'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _dateOnly(String? val) {
    if (val == null) return '';
    if (val.contains('T')) return val.split('T').first;
    return val;
  }
}

class ProductMasterDetailScreen extends StatelessWidget {
  final Map productMaster;
  final List categories;
  const ProductMasterDetailScreen({super.key, required this.productMaster, required this.categories});

  String _formatDate(dynamic date) {
    if (date == null) return '-';
    final d = DateTime.tryParse(date.toString());
    if (d == null) return date.toString();
    return '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
  }

  String _calcPerUnitCost(Map pm) {
    final purchase = (pm['purchase_price'] is num) ? pm['purchase_price'] : double.tryParse(pm['purchase_price']?.toString() ?? '') ?? 0;
    final transport = (pm['transportation_cost'] is num) ? pm['transportation_cost'] : double.tryParse(pm['transportation_cost']?.toString() ?? '') ?? 0;
    final qty = (pm['quantity_purchased'] is num) ? pm['quantity_purchased'] : double.tryParse(pm['quantity_purchased']?.toString() ?? '') ?? 0;
    if (qty == 0) return '-';
    final perUnit = (purchase + transport) / qty;
    return perUnit.toStringAsFixed(2);
  }

  Future<void> _edit(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => ProductMasterFormScreen(
          categories: categories,
          initial: productMaster,
          onSaved: (data) async {
            await ApiService.updateProductMaster(productMaster['id'], data);
          },
        ),
      ),
    );
    if (result == true && context.mounted) {
      // Refresh the detail screen with updated data before popping
      final updated = await ApiService.getProductMasterById(productMaster['id']);
      if (context.mounted) {
        Navigator.of(context).pop(true); // Signal to refresh list
        // Optionally, you could pushReplacement with updated data for a seamless UX
        // Navigator.of(context).pushReplacement(MaterialPageRoute(
        //   builder: (ctx) => ProductMasterDetailScreen(productMaster: updated, categories: categories),
        // ));
      }
    }
  }

  Future<void> _delete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product Master'),
        content: const Text('Are you sure you want to delete this product master?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await ApiService.deleteProductMaster(productMaster['id']);
      if (context.mounted) Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pm = productMaster;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(pm['name'] ?? 'Product Master Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            tooltip: 'Edit',
            onPressed: () => _edit(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            tooltip: 'Delete',
            onPressed: () => _delete(context),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header card
                Card(
                  elevation: 2,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 26),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          pm['name'] ?? '-',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: 0.2),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        Center(
                          child: Text(
                            'Batch: ${pm['batch_number'] ?? '-'}',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Exp. ', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w400, fontSize: 15)),
                              _ExpireBadge(date: pm['expire_date'], small: false),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Divider(thickness: 0.8, height: 32),
                // Details section with soft background
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FA),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeader('Product Details'),
                      _detailRow('Product Invoice Number', pm['invoice_number']),
                      _detailRow('Purchase Date', _formatDate(pm['purchase_date'])),
                      _detailRow('Manufacturing Date', _formatDate(pm['manufacturing_date'])),
                      _detailRow('Expire Date', _formatDate(pm['expire_date'])),
                      _sectionHeader('Stock & Cost'),
                      _detailRow('Quantity Purchased', pm['quantity_purchased']),
                      _detailRow('Total Purchase Price', pm['purchase_price']),
                      _detailRow('Transportation Cost', pm['transportation_cost']),
                      _detailRow('Per Unit Cost', '₹${_calcPerUnitCost(pm)}'),
                      _sectionHeader('Vendor'),
                      _detailRow('Vendor', pm['vendor']),
                    ].expand((w) => [w, const SizedBox(height: 14)]).toList()..removeLast(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String text) => Padding(
    padding: const EdgeInsets.only(top: 10, bottom: 2),
    child: Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF6A6A6A), letterSpacing: 0.2),
    ),
  );

  Widget _detailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w400, color: Color(0xFF888888), fontSize: 14)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value?.toString() ?? '-',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: Color(0xFF222222)),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpireBadge extends StatelessWidget {
  final dynamic date;
  final bool small;
  const _ExpireBadge({Key? key, this.date, this.small = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final d = DateTime.tryParse(date?.toString() ?? '');
    final now = DateTime.now();
    Color bg = Colors.green[50]!;
    Color fg = Colors.green[800]!;
    String label = '';
    if (d != null) {
      if (d.isBefore(now)) {
        bg = Colors.red[50]!;
        fg = Colors.red[800]!;
        label = 'Expired';
      } else if (d.difference(now).inDays < 30) {
        bg = Colors.orange[50]!;
        fg = Colors.orange[800]!;
        label = 'Expiring Soon';
      } else {
        label = 'Valid';
      }
    }
    return Container(
      padding: small
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 3)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event, size: small ? 13 : 16, color: fg),
          const SizedBox(width: 3),
          Text(
            date == null ? '-' : '${d!.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}',
            style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: small ? 12 : 14),
          ),
          if (!small && label.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12)),
          ],
        ],
      ),
    );
  }
} 