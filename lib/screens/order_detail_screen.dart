import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:store_manager/utils/pdf_util.dart';
import '../models/order.dart';
import '../providers/order_provider.dart';
import 'package:store_manager/utils/currency_formatter.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Szczegóły zamówienia',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            color: Colors.white,
            icon: const Icon(Icons.more_vert, color: Colors.blue),
            constraints: const BoxConstraints(
              minWidth: 100,
              maxWidth: 240,
            ),
            onSelected: (value) {
              if (value == 'print') {
                _printInvoice(context);
              } else if (value == 'edit') {
                // Navigate to edit screen with orderId
                context.push('/orders/${widget.orderId}/edit');
              } else if (value == 'print_internal') {
                _printInvoice(context, isShowWarehouse: true);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'print',
                child: Row(
                  children: const [
                    Icon(Icons.print, color: Colors.blue),
                    SizedBox(width: 4), // giảm width
                    Text('Drukuj fakturę', overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'print_internal',
                child: Row(
                  children: const [
                    Icon(Icons.print, color: Colors.red),
                    SizedBox(width: 4), // giảm width
                    Text('Drukuj fakturę (wewnętrzną)', overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.red),),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: const [
                    Icon(Icons.edit, color: Colors.blue),
                    SizedBox(width: 4), // giảm width
                    Text('Edytuj', overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
          if (orderProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final orderId = int.tryParse(widget.orderId);
          if (orderId == null) {
            return const Center(
              child: Text('Nieprawidłowy ID zamówienia'),
            );
          }

          final order = orderProvider.getOrderById(orderId);
          if (order == null) {
            return const Center(
              child: Text('Nie znaleziono zamówienia'),
            );
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order Header Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Order ID Row
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.receipt_long,
                                    color: Colors.blue[600],
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '${order.id}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    order.orderStatus.displayName,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Amount Info
                            _buildInfoRow('Cena jednostkowa', '', CurrencyFormatter.formatWithSymbol(order.total, 'zł'), Colors.red),
                            _buildInfoRow('Podatek', '', CurrencyFormatter.formatWithSymbol(order.taxFeeAmount, 'zł'), Colors.orange),
                            const SizedBox(height: 8),
                            _buildInfoRow('Liczba produktów', '', '${order.lineItems.length} produktów', Colors.black),
                            const SizedBox(height: 8),
                            _buildInfoRow('Czas złożenia zamówienia', '', _formatDateTime(order.dateCreated), Colors.black),
                            const SizedBox(height: 8),
                            _buildInfoRow('Klient', '', order.billing.firstName.isNotEmpty ? order.billing.firstName : 'Klient #${order.customerId}', Colors.black),
                            _buildInfoRow('Adres dostawy', '', order.billing.address.isNotEmpty ? order.billing.address : 'Brak adresu', Colors.black),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Product List
                      ...order.lineItems.map((item) => _buildProductCard(item)),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _printInvoice(BuildContext context, {bool isShowWarehouse = false}) {
    // Lấy thông tin đơn hàng từ provider
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final orderId = int.tryParse(widget.orderId);
    if (orderId == null) return;
    
    final order = orderProvider.getOrderById(orderId);
    if (order == null) return;

    _performPrint(order, isShowWarehouse: isShowWarehouse);
  }

  void _performPrint(Order order, {bool isShowWarehouse = false}) {
    Printing.layoutPdf(onLayout: (format) {
      return PdfUtil.generateOrderPdf(order, isShowWarehouse);
    });
  }

  Widget _buildInfoRow(String label, String prefix, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: valueColor,
                fontWeight: valueColor == Colors.red ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(OrderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Product Image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: item.image != null && item.image!.src.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: item.image!.src,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      errorWidget: (context, url, error) => Image.asset(
                        'assets/images/no_image.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                : Icon(
                    Icons.image,
                    color: Colors.grey[400],
                    size: 30,
                  ),
          ),
          const SizedBox(width: 12),
          
          // Product Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.warehouse,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'x${item.quantity}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Price and Warehouse
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.formatPLN(item.price / item.quantity),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('dd.MM.yyyy HH:mm').format(dateTime);
  }
}
