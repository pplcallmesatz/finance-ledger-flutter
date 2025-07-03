import 'package:flutter/material.dart';
import 'services/api_service.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<dynamic> products = [];
  List<dynamic> categories = [];
  int? selectedCategoryId;
  String search = '';
  int currentPage = 1;
  int totalPages = 1;
  bool isLoading = true;
  String? errorMessage;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCategoriesAndProducts();
  }

  Future<void> _fetchCategoriesAndProducts() async {
    setState(() { isLoading = true; errorMessage = null; });
    try {
      final catResp = await ApiService.getCategories(perPage: 100);
      final cats = catResp['data'] as List? ?? [];
      setState(() { categories = cats; });
      await _fetchProducts();
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load categories: $e';
      });
    }
  }

  Future<void> _fetchProducts({int? page}) async {
    setState(() { isLoading = true; errorMessage = null; });
    try {
      final resp = await ApiService.getProducts(
        search: search.isNotEmpty ? search : null,
        categoryId: selectedCategoryId,
        perPage: 15,
        page: page ?? currentPage,
      );
      final data = resp['data'] as List? ?? [];
      setState(() {
        products = data;
        isLoading = false;
        currentPage = resp['current_page'] ?? 1;
        totalPages = resp['last_page'] ?? 1;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load products: $e';
      });
    }
  }

  void _onCategoryChanged(int? catId) {
    setState(() { selectedCategoryId = catId; currentPage = 1; });
    _fetchProducts();
  }

  void _onSearchChanged(String value) {
    setState(() { search = value; currentPage = 1; });
    _fetchProducts();
  }

  void _onPageChanged(int newPage) {
    if (newPage < 1 || newPage > totalPages) return;
    setState(() { currentPage = newPage; });
    _fetchProducts(page: newPage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: selectedCategoryId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Filter by Category',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem<int>(
                        value: null,
                        child: Text('All Categories'),
                      ),
                      ...categories.map<DropdownMenuItem<int>>((cat) => DropdownMenuItem(
                        value: cat['id'],
                        child: Text(cat['name'] ?? ''),
                      )),
                    ],
                    onChanged: _onCategoryChanged,
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
              products.isEmpty
                  ? const Expanded(child: Center(child: Text('No products found.')))
                  : Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: ListView.separated(
                              itemCount: products.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final p = products[index];
                                return Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (ctx) => ProductDetailScreen(product: p),
                                        ),
                                      );
                                      if (result == true) _fetchProducts();
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(p['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                                const SizedBox(height: 4),
                                                Text('Category: ${p['category_master']?['name'] ?? '-'}'),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            '₹${p['selling_price'] ?? '-'}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.green),
                                          ),
                                          const SizedBox(width: 8),
                                          PopupMenuButton<String>(
                                            onSelected: (value) async {
                                              if (value == 'edit') {
                                                final result = await Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (ctx) => ProductFormScreen(
                                                      categories: categories,
                                                      initial: p,
                                                      onSaved: (data) async {
                                                        await ApiService.updateProduct(p['id'], data);
                                                      },
                                                    ),
                                                  ),
                                                );
                                                if (result == true) _fetchProducts();
                                              } else if (value == 'delete') {
                                                final confirm = await showDialog<bool>(
                                                  context: context,
                                                  builder: (ctx) => AlertDialog(
                                                    title: const Text('Delete Product'),
                                                    content: const Text('Are you sure you want to delete this product?'),
                                                    actions: [
                                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                                      ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                                                    ],
                                                  ),
                                                );
                                                if (confirm == true) {
                                                  await ApiService.deleteProduct(p['id']);
                                                  _fetchProducts();
                                                }
                                              }
                                            },
                                            itemBuilder: (context) => [
                                              const PopupMenuItem(
                                                value: 'edit',
                                                child: ListTile(
                                                  leading: Icon(Icons.edit, color: Colors.blue),
                                                  title: Text('Edit'),
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'delete',
                                                child: ListTile(
                                                  leading: Icon(Icons.delete, color: Colors.red),
                                                  title: Text('Delete'),
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
              builder: (ctx) => ProductFormScreen(
                categories: categories,
                onSaved: (data) async {
                  await ApiService.createProduct(data);
                },
              ),
            ),
          );
          if (result == true) _fetchProducts();
        },
        child: const Icon(Icons.add),
        tooltip: 'Add Product',
      ),
    );
  }
}

class ProductFormScreen extends StatefulWidget {
  final List categories;
  final Map? initial;
  final Future<void> Function(Map<String, dynamic>) onSaved;
  const ProductFormScreen({super.key, required this.categories, this.initial, required this.onSaved});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController purchasePriceController;
  late TextEditingController packingPriceController;
  late TextEditingController sellingPriceController;
  late TextEditingController descriptionController;
  late TextEditingController barcodeController;
  late TextEditingController barcodeVendorController;
  late TextEditingController unitsController;
  late TextEditingController remarksController;
  int? categoryId;

  @override
  void initState() {
    final i = widget.initial ?? {};
    nameController = TextEditingController(text: i['name']?.toString() ?? '');
    purchasePriceController = TextEditingController(text: i['purchase_price']?.toString() ?? '');
    packingPriceController = TextEditingController(text: i['packing_price']?.toString() ?? '');
    sellingPriceController = TextEditingController(text: i['selling_price']?.toString() ?? '');
    descriptionController = TextEditingController(text: i['description']?.toString() ?? '');
    barcodeController = TextEditingController(text: i['barcode']?.toString() ?? '');
    barcodeVendorController = TextEditingController(text: i['barcode_vendor']?.toString() ?? '');
    unitsController = TextEditingController(text: i['units']?.toString() ?? '');
    remarksController = TextEditingController(text: i['remarks']?.toString() ?? '');
    categoryId = i['category_master_id'] is int
        ? i['category_master_id']
        : int.tryParse(i['category_master_id']?.toString() ?? '');
    if (widget.initial != null && categoryId != null) {
      final exists = widget.categories.any((cat) => cat['id'] == categoryId);
      if (!exists && widget.initial!['category_master'] != null) {
        widget.categories.add({
          'id': categoryId,
          'name': widget.initial!['category_master']['name'] ?? 'Unknown',
        });
      }
    }
    super.initState();
  }

  void _autoCalc() {
    final purchase = double.tryParse(purchasePriceController.text) ?? 0;
    final packing = double.tryParse(packingPriceController.text) ?? 0;
    final productPrice = purchase + packing;
    if (widget.initial == null) {
      sellingPriceController.text = (productPrice * 2).toStringAsFixed(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.initial == null ? 'Add Product' : 'Edit Product')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              DropdownButtonFormField<int>(
                value: categoryId,
                decoration: const InputDecoration(labelText: 'Category'),
                items: widget.categories.map<DropdownMenuItem<int>>((cat) => DropdownMenuItem(
                  value: cat['id'],
                  child: Text(cat['name'] ?? ''),
                )).toList(),
                onChanged: (v) => setState(() => categoryId = v),
              ),
              TextFormField(
                controller: purchasePriceController,
                decoration: const InputDecoration(labelText: 'Purchase Price'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(_autoCalc),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: packingPriceController,
                decoration: const InputDecoration(labelText: 'Packing Price'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(_autoCalc),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: sellingPriceController,
                decoration: const InputDecoration(labelText: 'Selling Price (editable)'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextFormField(
                controller: barcodeController,
                decoration: const InputDecoration(labelText: 'Barcode'),
              ),
              TextFormField(
                controller: barcodeVendorController,
                decoration: const InputDecoration(labelText: 'Barcode Vendor'),
              ),
              TextFormField(
                controller: unitsController,
                decoration: const InputDecoration(labelText: 'Units'),
              ),
              TextFormField(
                controller: remarksController,
                decoration: const InputDecoration(labelText: 'Remarks (optional)'),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState?.validate() != true) return;
                      final purchase = double.tryParse(purchasePriceController.text) ?? 0;
                      final packing = double.tryParse(packingPriceController.text) ?? 0;
                      final productPrice = purchase + packing;
                      final selling = double.tryParse(sellingPriceController.text) ?? (productPrice * 2);
                      final data = {
                        'name': nameController.text.trim(),
                        'product_price': productPrice,
                        'selling_price': selling,
                        'category_master_id': categoryId,
                        'purchase_price': purchase,
                        'packing_price': packing,
                        'description': descriptionController.text.trim(),
                        'barcode': barcodeController.text.trim(),
                        'barcode_vendor': barcodeVendorController.text.trim(),
                        'units': unitsController.text.trim(),
                        'remarks': remarksController.text.trim(),
                      };
                      await widget.onSaved(data);
                      Navigator.of(context).pop(true);
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProductDetailScreen extends StatelessWidget {
  final Map product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final p = product;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(p['name'] ?? 'Product Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            tooltip: 'Edit',
            onPressed: () async {
              final categories = await ApiService.getCategories(perPage: 100);
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => ProductFormScreen(
                    categories: categories['data'] as List? ?? [],
                    initial: p,
                    onSaved: (data) async {
                      await ApiService.updateProduct(p['id'], data);
                      if (ctx.mounted && Navigator.canPop(context)) {
                        Navigator.of(ctx).pop(true);
                      }
                    },
                  ),
                ),
              );
              if (result == true && context.mounted && Navigator.canPop(context)) {
                Navigator.of(context).pop(true);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            tooltip: 'Delete',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Product'),
                  content: const Text('Are you sure you want to delete this product?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                  ],
                ),
              );
              if (confirm == true) {
                await ApiService.deleteProduct(p['id']);
                if (context.mounted) Navigator.of(context).pop(true);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.inventory, color: theme.primaryColor, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            p['name'] ?? '-',
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.category, size: 20, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          p['category_master']?['name'] ?? '-',
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Selling Price (large)
                    Row(
                      children: [
                        const Icon(Icons.sell, color: Colors.green, size: 22),
                        const SizedBox(width: 6),
                        Text(
                          '₹${p['selling_price'] ?? '-'}',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.green[700], fontWeight: FontWeight.bold, fontSize: 28),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Product Price
                    Row(
                      children: [
                        const Icon(Icons.attach_money, color: Colors.blue, size: 22),
                        const SizedBox(width: 4),
                        Text('Product Price: ', style: theme.textTheme.bodyMedium),
                        Text('₹${p['product_price'] ?? '-'}', style: theme.textTheme.bodyLarge),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Purchase Price
                    Row(
                      children: [
                        const Icon(Icons.shopping_cart, color: Colors.orange, size: 22),
                        const SizedBox(width: 4),
                        Text('Purchase Price: ', style: theme.textTheme.bodyMedium),
                        Text('₹${p['purchase_price'] ?? '-'}', style: theme.textTheme.bodyLarge),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Packing Price
                    Row(
                      children: [
                        const Icon(Icons.all_inbox, color: Colors.brown, size: 22),
                        const SizedBox(width: 4),
                        Text('Packing Price: ', style: theme.textTheme.bodyMedium),
                        Text('₹${p['packing_price'] ?? '-'}', style: theme.textTheme.bodyLarge),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if ((p['barcode'] != null && p['barcode'].toString().isNotEmpty) ||
                (p['barcode_vendor'] != null && p['barcode_vendor'].toString().isNotEmpty) ||
                (p['units'] != null && p['units'].toString().isNotEmpty) ||
                (p['description'] != null && p['description'].toString().isNotEmpty) ||
                (p['remarks'] != null && p['remarks'].toString().isNotEmpty))
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (p['barcode'] != null && p['barcode'].toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              const Icon(Icons.qr_code, size: 20, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text('Barcode: ', style: theme.textTheme.bodyMedium),
                              Text(p['barcode'], style: theme.textTheme.bodyLarge),
                            ],
                          ),
                        ),
                      if (p['barcode_vendor'] != null && p['barcode_vendor'].toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              const Icon(Icons.store, size: 20, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text('Barcode Vendor: ', style: theme.textTheme.bodyMedium),
                              Text(p['barcode_vendor'], style: theme.textTheme.bodyLarge),
                            ],
                          ),
                        ),
                      if (p['units'] != null && p['units'].toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              const Icon(Icons.straighten, size: 20, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text('Units: ', style: theme.textTheme.bodyMedium),
                              Text(p['units'], style: theme.textTheme.bodyLarge),
                            ],
                          ),
                        ),
                      if (p['description'] != null && p['description'].toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.description, size: 20, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text('Description: ', style: theme.textTheme.bodyMedium),
                              Expanded(child: Text(p['description'], style: theme.textTheme.bodyLarge)),
                            ],
                          ),
                        ),
                      if (p['remarks'] != null && p['remarks'].toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.note, size: 20, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text('Remarks: ', style: theme.textTheme.bodyMedium),
                              Expanded(child: Text(p['remarks'], style: theme.textTheme.bodyLarge)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 