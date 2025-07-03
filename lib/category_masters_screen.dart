import 'package:flutter/material.dart';
import 'services/api_service.dart';

class CategoryMastersScreen extends StatefulWidget {
  @override
  _CategoryMastersScreenState createState() => _CategoryMastersScreenState();
}

class _CategoryMastersScreenState extends State<CategoryMastersScreen> {
  List categories = [];
  bool isLoading = true;
  String search = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    setState(() { isLoading = true; });
    final resp = await ApiService.getCategories(
      perPage: 100,
      search: search.isNotEmpty ? search : null,
    );
    setState(() {
      categories = resp['data'] ?? [];
      isLoading = false;
    });
  }

  void onEdit(category) {
    // TODO: Implement edit functionality (navigate to edit screen or show dialog)
  }

  void onDelete(category) async {
    FocusScope.of(context).unfocus();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Category'),
        content: Text('Are you sure you want to delete this category?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ApiService.deleteCategory(category['id']);
      fetchCategories();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by name or symbol',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        suffixIcon: search.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() { search = ''; });
                                  fetchCategories();
                                },
                              )
                            : null,
                      ),
                      onChanged: (val) {
                        setState(() { search = val; });
                        fetchCategories();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.refresh),
                    tooltip: 'Refresh',
                    onPressed: () {
                      fetchCategories();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await fetchCategories();
                  },
                  child: isLoading
                      ? Center(child: CircularProgressIndicator())
                      : categories.isEmpty
                          ? Center(child: Text('No categories found.'))
                          : ListView.builder(
                              itemCount: categories.length,
                              itemBuilder: (context, index) {
                                final cat = categories[index];
                                return GestureDetector(
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CategoryDetailScreen(categoryId: cat['id']),
                                      ),
                                    );
                                  },
                                  child: Card(
                                    margin: const EdgeInsets.symmetric(vertical: 6),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  cat['name'] ?? '',
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                ),
                                                const SizedBox(height: 1),
                                                Transform.scale(
                                                  scale: 0.8,
                                                  alignment: Alignment.centerLeft,
                                                  child: Chip(
                                                    label: Text(
                                                      (cat['symbol'] ?? '').toString(),
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.bold,
                                                        letterSpacing: 1.2,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    backgroundColor: Theme.of(context).colorScheme.primary,
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                                    visualDensity: VisualDensity.compact,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text('Self Life'),
                                              Text(
                                                cat['self_life']?.toString() ?? '-',
                                                style: TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                          PopupMenuButton<String>(
                                            onSelected: (value) {
                                              if (value == 'edit') onEdit(cat);
                                              if (value == 'delete') onDelete(cat);
                                            },
                                            itemBuilder: (context) => [
                                              PopupMenuItem(value: 'edit', child: Text('Edit')),
                                              PopupMenuItem(value: 'delete', child: Text('Delete')),
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddCategoryScreen()),
          );
          if (result == true) fetchCategories();
        },
        child: Icon(Icons.add),
        tooltip: 'Add Category',
      ),
    );
  }
}

class AddCategoryScreen extends StatefulWidget {
  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _symbolController = TextEditingController();
  final TextEditingController _selfLifeController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _symbolController.addListener(() {
      final text = _symbolController.text;
      if (text != text.toUpperCase()) {
        final selection = _symbolController.selection;
        _symbolController.value = TextEditingValue(
          text: text.toUpperCase(),
          selection: selection,
        );
      }
    });
  }

  @override
  void dispose() {
    _symbolController.dispose();
    _nameController.dispose();
    _descController.dispose();
    _selfLifeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      await ApiService.createCategory({
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'symbol': _symbolController.text.trim().toUpperCase(),
        'self_life': _selfLifeController.text.trim(),
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      setState(() { _error = errorMsg; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg, style: const TextStyle(color: Colors.white))),
        );
      }
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Category'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                      child: Icon(Icons.category_outlined, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Text('Add Category', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.label_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(Icons.description_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _symbolController,
                  decoration: InputDecoration(
                    labelText: 'Symbol',
                    prefixIcon: Icon(Icons.code),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _selfLifeController,
                  decoration: InputDecoration(
                    labelText: 'Self Life (months)',
                    prefixIcon: Icon(Icons.timelapse_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
                ],
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _submit,
                      icon: _isLoading
                          ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Icon(Icons.check),
                      label: const Text('Add'),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CategoryDetailScreen extends StatefulWidget {
  final int categoryId;
  const CategoryDetailScreen({Key? key, required this.categoryId}) : super(key: key);

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  Map<String, dynamic>? category;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchCategory();
  }

  Future<void> fetchCategory() async {
    setState(() { isLoading = true; error = null; });
    try {
      final resp = await ApiService.getCategoryById(widget.categoryId);
      setState(() {
        category = resp['data'];
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Category Details'),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : category == null
                  ? Center(child: Text('No details found.'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Center(
                        child: Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  category!['name'] ?? '',
                                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 10),
                                Chip(
                                  label: Text(
                                    (category!['symbol'] ?? '').toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                      fontSize: 13,
                                    ),
                                  ),
                                  backgroundColor: theme.colorScheme.primary,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                  visualDensity: VisualDensity.compact,
                                ),
                                const SizedBox(height: 24),
                                if (category!['description'] != null && (category!['description'] as String).isNotEmpty)
                                  Column(
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.description_outlined, color: theme.colorScheme.primary, size: 20),
                                          const SizedBox(width: 8),
                                          Text('Description', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          category!['description'],
                                          style: theme.textTheme.bodyLarge,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                    ],
                                  ),
                                Row(
                                  children: [
                                    Icon(Icons.timelapse_outlined, size: 20, color: theme.colorScheme.primary),
                                    const SizedBox(width: 8),
                                    Text('Self Life:', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 4),
                                    Text(category!['self_life']?.toString() ?? '-', style: theme.textTheme.bodyMedium),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Divider(height: 32, thickness: 1, color: Colors.grey[200]),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today, size: 20, color: Colors.grey[600]),
                                    const SizedBox(width: 8),
                                    Text('Created:', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 4),
                                    Text(_formatDate(category!['created_at'])),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Icon(Icons.update, size: 20, color: Colors.grey[600]),
                                    const SizedBox(width: 8),
                                    Text('Updated:', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 4),
                                    Text(_formatDate(category!['updated_at'])),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '-';
    try {
      final d = DateTime.parse(date.toString());
      return '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
    } catch (_) {
      return date.toString();
    }
  }
} 