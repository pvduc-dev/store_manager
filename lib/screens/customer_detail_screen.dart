import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:store_manager/providers/customer_provider.dart';
import 'package:store_manager/models/order.dart';
import 'package:store_manager/services/order_service.dart';
import 'package:store_manager/utils/currency_formatter.dart';

class CustomerDetailScreen extends StatefulWidget {
  final String customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Order> _customerOrders = [];
  bool _isLoadingOrders = false;
  bool _hasLoadingError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final customerId = int.tryParse(widget.customerId);
      if (customerId != null) {
        _checkCustomerInCache(customerId);
      } else {
        setState(() {
          _hasLoadingError = true;
          _errorMessage = 'Nieprawidłowy identyfikator klienta';
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _checkCustomerInCache(int customerId) {
    final customerProvider = context.read<CustomerProvider>();
    final customer = customerProvider.getCustomerById(customerId);
    
    if (customer == null) {
      setState(() {
        _hasLoadingError = true;
        _errorMessage = 'Nie znaleziono informacji o kliencie.\nProszę powrócić do listy klientów.';
      });
      return;
    }
    
    // Load orders if customer is in cache
    _loadCustomerOrders(customerId);
  }

  Future<void> _loadCustomerOrders(int customerId) async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingOrders = true;
    });

    try {
      final orders = await OrderService.getOrdersByCustomerId(customerId);
      if (!mounted) return;
      
      setState(() {
        _customerOrders = orders;
        _isLoadingOrders = false;
      });
    } catch (e) {
      print('Error loading customer orders: $e');
      if (!mounted) return;
      
      setState(() {
        _customerOrders = [];
        _isLoadingOrders = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final customerId = int.tryParse(widget.customerId);

    if (customerId == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () {
              context.go('/customers');
            },
            icon: const Icon(Icons.arrow_back),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
          title: const Text('Informacje o kliencie'),
        ),
        body: const Center(child: Text('Nieprawidłowy identyfikator klienta')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            context.go('/customers');
          },
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Informacje o kliencie'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              _showOptionsBottomSheet(context, customerId);
            },
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Consumer<CustomerProvider>(
        builder: (context, customerProvider, child) {
          final customer = customerProvider.getCustomerById(customerId);

          // Display error if exists
          if (_hasLoadingError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          context.go('/customers');
                        },
                        child: const Text('Powrót do listy'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _hasLoadingError = false;
                            _errorMessage = '';
                          });
                          _checkCustomerInCache(customerId);
                        },
                        child: const Text('Spróbuj ponownie'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }

          if (customer == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Customer basic info card - always visible
              _buildCustomerBasicInfo(customer),
              
              // TabBar
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.blue,
                  unselectedLabelColor: Colors.grey[600],
                  indicatorColor: Colors.blue,
                  tabs: const [
                    Tab(text: 'Informacje kontaktowe'),
                    Tab(text: 'Zamówienia'),
                  ],
                ),
              ),
              
              // TabBarView
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Contact Information
                    _buildContactInfoTabContent(customer),
                    // Tab 2: Orders
                    _buildOrdersTab(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showOptionsBottomSheet(BuildContext context, int customerId) {
    final customer = context.read<CustomerProvider>().getCustomerById(customerId);
    if (customer == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Edit option
            InkWell(
              onTap: () {
                Navigator.pop(context);
                context.push('/customers/$customerId/edit');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.edit, color: Colors.blue),
                    const SizedBox(width: 12),
                    const Text(
                      'Edytuj klienta',
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),
            
            Divider(
              height: 1,
              thickness: 1,
              color: Colors.grey[300],
              indent: 24,
              endIndent: 24,
            ),
            
            // Delete option
            InkWell(
              onTap: customer.orderCount > 0 
                ? null
                : () {
                    Navigator.pop(context);
                    _showDeleteConfirmationDialog(context, customer);
                  },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.delete_outline,
                          color: customer.orderCount > 0 ? Colors.grey : Colors.red,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Usuń klienta',
                          style: TextStyle(
                            fontSize: 16,
                            color: customer.orderCount > 0 ? Colors.grey : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    if (customer.orderCount > 0) ...[
                      const SizedBox(height: 4),
                      const Text(
                        'Nie można usunąć klienta z zamówieniami',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text(
          'Usuń klienta',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Czy na pewno chcesz usunąć klienta?'),
            const SizedBox(height: 8),
            Text(
              '"${customer.fullName}"',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ta akcja jest nieodwracalna.',
              style: TextStyle(
                color: Colors.red,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteCustomer(context, customer.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCustomer(BuildContext context, int customerId) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      await context.read<CustomerProvider>().deleteCustomer(customerId);
      
      // Hide loading dialog
      if (mounted) {
        Navigator.pop(context);
        
        // Show success message and navigate back
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Klient został pomyślnie usunięty'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate back to customer list
        context.go('/customers');
      }
    } catch (e) {
      // Hide loading dialog
      if (mounted) {
        Navigator.pop(context);
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd podczas usuwania klienta: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildCustomerBasicInfo(customer) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        color: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    child: Text(
                      customer.fullName.isNotEmpty ? customer.fullName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: Colors.grey[600],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.fullName.isNotEmpty
                              ? customer.fullName
                              : 'Brak nazwy',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          customer.email,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'ID',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          customer.id.toString(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Zamówienia',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          customer.orderCount.toString(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: customer.orderCount > 0
                                ? Colors.green
                                : Colors.grey[600],
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
  }

  Widget _buildContactInfoTabContent(customer) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        color: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Informacje o kliencie',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (customer.nip.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.business),
                  title: const Text('NIP'),
                  subtitle: Text(customer.nip),
                ),
              if (customer.phone.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.phone),
                  title: const Text('Telefon'),
                  subtitle: Text(customer.phone),
                ),
              if (customer.address.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.location_on),
                  title: const Text('Adres'),
                  subtitle: Text(customer.address),
                ),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Data rejestracji'),
                subtitle: Text(customer.formattedRegisteredDate),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersTab() {
    if (_isLoadingOrders) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_customerOrders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Brak zamówień',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _customerOrders.length,
      itemBuilder: (context, index) {
        final order = _customerOrders[index];
        return Card(
          color: Colors.white,
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(order.status),
              child: Text(
                '#${order.number}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              'Zamówienie #${order.number}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Status: ${_getStatusDisplayName(order.status)}'),
                Text('Data utworzenia: ${_formatDate(order.dateCreated.toIso8601String())}'),
                Text('Całkowity: ${CurrencyFormatter.formatPLN(order.total)}'),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              context.push('/orders/${order.id}');
            },
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'processing':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'refunded':
        return Colors.purple;
      case 'failed':
        return Colors.red;
      case 'on-hold':
        return Colors.yellow[700]!;
      default:
        return Colors.grey;
    }
  }

  String _getStatusDisplayName(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Zakończone';
      case 'processing':
        return 'Przetwarzanie';
      case 'pending':
        return 'Oczekujące';
      case 'cancelled':
        return 'Anulowane';
      case 'refunded':
        return 'Zwrócone';
      case 'failed':
        return 'Nieudane';
      case 'on-hold':
        return 'Wstrzymane';
      default:
        return status;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
