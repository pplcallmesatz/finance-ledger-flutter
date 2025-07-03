import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';
import 'sales_ledger_screen.dart';
import 'expense_ledger_screen.dart';
import 'transactions_screen.dart';
import 'pending_sales_screen.dart';
import 'user_screen.dart';
import 'products_screen.dart';
import 'product_masters_screen.dart';
import 'category_masters_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  String _currentPageTitle = 'Dashboard';

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      title: 'Dashboard',
      icon: Icons.dashboard,
      screen: const DashboardScreen(),
    ),
    NavigationItem(
      title: 'Sales Ledgers',
      icon: Icons.receipt_long,
      screen: const SalesLedgerScreen(),
    ),
    NavigationItem(
      title: 'Expense Ledgers',
      icon: Icons.payment,
      screen: const ExpenseLedgerScreen(),
    ),
    NavigationItem(
      title: 'Transactions',
      icon: Icons.swap_horiz,
      screen: const TransactionsScreen(),
    ),
    NavigationItem(
      title: 'Pending',
      icon: Icons.pending,
      screen: const PendingSalesScreen(),
    ),
    NavigationItem(
      title: 'Users',
      icon: Icons.people,
      screen: const UserScreen(),
    ),
    NavigationItem(
      title: 'Products',
      icon: Icons.inventory,
      screen: const ProductsScreen(),
    ),
    NavigationItem(
      title: 'Product Masters',
      icon: Icons.category,
      screen: const ProductMastersScreen(),
    ),
    NavigationItem(
      title: 'Category Masters',
      icon: Icons.category_outlined,
      screen: CategoryMastersScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentPageTitle),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          IconButton(
            onPressed: () => _showLogoutDialog(),
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _navigationItems[_selectedIndex].screen,
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.account_circle,
                    size: 40,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Ledger App',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Finance Management',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          ..._navigationItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return ListTile(
              leading: Icon(
                item.icon,
                color: _selectedIndex == index
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              title: Text(
                item.title,
                style: TextStyle(
                  fontWeight: _selectedIndex == index ? FontWeight.bold : FontWeight.normal,
                  color: _selectedIndex == index
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
              ),
              selected: _selectedIndex == index,
              onTap: () {
                setState(() {
                  _selectedIndex = index;
                  _currentPageTitle = item.title;
                });
                Navigator.pop(context); // Close drawer
              },
            );
          }).toList(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            onTap: () => _showLogoutDialog(),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    // Clear stored token
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    
    // Navigate back to login
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }
}

class NavigationItem {
  final String title;
  final IconData icon;
  final Widget screen;

  NavigationItem({
    required this.title,
    required this.icon,
    required this.screen,
  });
}

class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Coming Soon',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'This feature is under development',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
} 