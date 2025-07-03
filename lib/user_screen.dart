import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/api_service.dart';
import 'user_detail_screen.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  List<dynamic> users = [];
  bool isLoading = true;
  String? errorMessage;
  String searchQuery = '';
  int currentPage = 1;
  int totalPages = 1;
  int perPage = 15;
  int totalUsers = 0;
  final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers({int? page, String? search}) async {
    setState(() { isLoading = true; errorMessage = null; });
    try {
      final data = await ApiService.getUsers(
        page: page ?? currentPage,
        perPage: perPage,
        search: search ?? searchQuery,
      );
      setState(() {
        users = data['data'] ?? [];
        // Laravel pagination structure: meta: { current_page, last_page, total }
        if (data['meta'] != null) {
          currentPage = data['meta']['current_page'] ?? 1;
          totalPages = data['meta']['last_page'] ?? 1;
          totalUsers = data['meta']['total'] ?? 0;
        } else {
          currentPage = 1;
          totalPages = 1;
          totalUsers = users.length;
        }
        if (search != null) searchQuery = search;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load users: $e';
        isLoading = false;
      });
    }
  }

  void _showUserForm({Map<String, dynamic>? user}) async {
    final isEditing = user != null;
    final nameController = TextEditingController(text: user?['name'] ?? '');
    final emailController = TextEditingController(text: user?['email'] ?? '');
    final phoneController = TextEditingController(text: user?['phone'] ?? '');
    final remarkController = TextEditingController(text: user?['remark'] ?? user?['remarks'] ?? '');
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit User' : 'Add User'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Name'),
                        validator: (v) => (v == null || v.isEmpty) ? 'Enter name' : null,
                      ),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(labelText: 'Email (optional)'),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      TextFormField(
                        controller: phoneController,
                        decoration: const InputDecoration(labelText: 'Phone'),
                        keyboardType: TextInputType.phone,
                        validator: (v) => (v == null || v.isEmpty) ? 'Enter phone' : null,
                      ),
                      TextFormField(
                        controller: remarkController,
                        decoration: const InputDecoration(labelText: 'Remark'),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setState(() => isSaving = true);
                          try {
                            final body = {
                              'name': nameController.text.trim(),
                              'email': emailController.text.trim(),
                              'phone': phoneController.text.trim(),
                              'remarks': remarkController.text.trim(),
                            };
                            if (isEditing) {
                              final resp = await ApiService.updateUser(user!['id'], body);
                              if (resp is Map && (resp['error'] != null || resp['message'] != null || resp['errors'] != null)) {
                                String? msg;
                                if (resp['message'] != null && resp['message'] is String) {
                                  msg = resp['message'];
                                } else if (resp['errors'] != null && resp['errors'] is Map) {
                                  final errors = resp['errors'] as Map;
                                  if (errors.isNotEmpty) {
                                    final firstError = errors.values.first;
                                    if (firstError is List && firstError.isNotEmpty) {
                                      msg = firstError.first;
                                    } else if (firstError is String) {
                                      msg = firstError;
                                    }
                                  }
                                } else if (resp['error'] != null) {
                                  msg = resp['error'].toString();
                                }
                                throw msg ?? 'Failed to update user';
                              }
                            } else {
                              final resp = await ApiService.createUser(body);
                              if (resp is Map && (resp['error'] != null || resp['message'] != null || resp['errors'] != null)) {
                                String? msg;
                                if (resp['message'] != null && resp['message'] is String) {
                                  msg = resp['message'];
                                } else if (resp['errors'] != null && resp['errors'] is Map) {
                                  final errors = resp['errors'] as Map;
                                  if (errors.isNotEmpty) {
                                    final firstError = errors.values.first;
                                    if (firstError is List && firstError.isNotEmpty) {
                                      msg = firstError.first;
                                    } else if (firstError is String) {
                                      msg = firstError;
                                    }
                                  }
                                } else if (resp['error'] != null) {
                                  msg = resp['error'].toString();
                                }
                                throw msg ?? 'Failed to create user';
                              }
                            }
                            if (context.mounted) {
                              Navigator.pop(context);
                              _fetchUsers();
                              rootScaffoldMessengerKey.currentState?.showSnackBar(
                                SnackBar(content: Text(isEditing ? 'User updated' : 'User added')),
                              );
                            }
                          } catch (e) {
                            setState(() => isSaving = false);
                            String msg = 'Failed to save user';
                            if (e is String) {
                              msg = e;
                            } else if (e is Exception) {
                              msg = e.toString().replaceFirst('Exception: ', '');
                            }
                            rootScaffoldMessengerKey.currentState?.showSnackBar(
                              SnackBar(content: Text(msg)),
                            );
                          }
                        },
                  child: isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(isEditing ? 'Update' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteUser(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: const Text('Are you sure you want to delete this user?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await ApiService.deleteUser(id);
        _fetchUsers();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete user: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: isLoading ? null : () => _fetchUsers(page: 1),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!, style: const TextStyle(color: Colors.red)))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: searchController,
                              decoration: InputDecoration(
                                hintText: 'Enter name or phone',
                                filled: true,
                                fillColor: Colors.grey[100],
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                                ),
                              ),
                              textInputAction: TextInputAction.search,
                              onSubmitted: (value) {
                                FocusScope.of(context).unfocus();
                                _fetchUsers(page: 1, search: value.trim());
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Material(
                            color: Theme.of(context).primaryColor,
                            shape: const CircleBorder(),
                            elevation: 2,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () {
                                FocusScope.of(context).unfocus();
                                _fetchUsers(page: 1, search: searchController.text.trim());
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(14.0),
                                child: Icon(Icons.search, color: Colors.white, size: 24),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (totalUsers > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total: $totalUsers users'),
                            Text('Page $currentPage of $totalPages'),
                          ],
                        ),
                      ),
                    Expanded(
                      child: users.isEmpty
                          ? const Center(child: Text('No users found.'))
                          : ListView.separated(
                              itemCount: users.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final user = users[index];
                                final name = user['name'] ?? '';
                                final phone = user['phone'] ?? '';
                                return ListTile(
                                  title: Text(name),
                                  subtitle: Text(phone),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () => _showUserForm(user: user),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _deleteUser(user['id']),
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => UserDetailScreen(user: user),
                                      ),
                                    );
                                  },
                                  onLongPress: () async {
                                    if (phone.isNotEmpty) {
                                      await Clipboard.setData(ClipboardData(text: phone));
                                      rootScaffoldMessengerKey.currentState?.showSnackBar(
                                        SnackBar(content: Text('Phone number copied: $phone')),
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                    ),
                    if (totalPages > 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.chevron_left),
                              label: const Text('Prev'),
                              onPressed: currentPage > 1 && !isLoading
                                  ? () => _fetchUsers(page: currentPage - 1)
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.chevron_right),
                              label: const Text('Next'),
                              onPressed: currentPage < totalPages && !isLoading
                                  ? () => _fetchUsers(page: currentPage + 1)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUserForm(),
        child: const Icon(Icons.add),
        tooltip: 'Add User',
      ),
    );
  }
} 