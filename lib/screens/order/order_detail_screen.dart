import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../services/pdf_invoice_service.dart';
import '../../providers/order_provider.dart';
import '../../widgets/pdf_download_button.dart';

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
          'Chi tiết đơn hàng',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          Consumer<OrderProvider>(
            builder: (context, orderProvider, child) {
              final orderId = int.tryParse(widget.orderId);
              if (orderId == null) return const SizedBox.shrink();

              final order = orderProvider.getOrderById(orderId);
              if (order == null) return const SizedBox.shrink();

              return TextButton(
                child: const Text(
                  'Sửa',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () {
                  // Navigate to edit screen
                  context.push('/orders/${order.id}/edit', extra: order);
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
          if (orderProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final orderId = int.tryParse(widget.orderId);
          if (orderId == null) {
            return const Center(child: Text('ID đơn hàng không hợp lệ'));
          }

          final order = orderProvider.getOrderById(orderId);
          if (order == null) {
            return const Center(child: Text('Không tìm thấy đơn hàng'));
          }

          // Lấy subtotal từ metadata
          String subtotal =
              (order.metaData.firstWhere(
                        (e) => e['key'] == 'GIA_THUONG_LUONG',
                        orElse: () => {'key': '', 'value': '0'},
                      )['value'] ??
                      0)
                  .toString();
          String total_tax =
              (order.metaData.firstWhere(
                        (e) => e['key'] == 'total_tax',
                        orElse: () => {'key': '', 'value': '0'},
                      )['value'] ??
                      0)
                  .toString();
          String total =
              (order.metaData.firstWhere(
                        (e) => e['key'] == 'total',
                        orElse: () => {'key': '', 'value': '0'},
                      )['value'] ??
                      0)
                  .toString();

          // Debug: In toàn bộ thông tin đơn hàng
          print('=== DEBUG ORDER DETAILS ===');
          print('Order ID: ${order.id}');
          print('Order Number: ${order.number}');
          print('Order Key: ${order.orderKey}');
          print('Status: ${order.status}');
          print('Customer ID: ${order.customerId}');
          print('Date Created: ${order.dateCreated}');
          print('Date Modified: ${order.dateModified}');
          print('Date Paid: ${order.datePaid}');
          print('Date Completed: ${order.dateCompleted}');
          print('Currency: ${order.currency}');
          print('Currency Symbol: ${order.currencySymbol}');
          print('Prices Include Tax: ${order.pricesIncludeTax}');
          print('Version: ${order.version}');
          print('Parent ID: ${order.parentId}');
          print('Cart Hash: ${order.cartHash}');
          print('Created Via: ${order.createdVia}');
          print('Customer Note: ${order.customerNote}');
          print('Customer IP: ${order.customerIpAddress}');
          print('Customer User Agent: ${order.customerUserAgent}');
          print('Payment Method: ${order.paymentMethod}');
          print('Payment Method Title: ${order.paymentMethodTitle}');
          print('Transaction ID: ${order.transactionId}');
          print('--- FINANCIAL INFO ---');
          print('Subtotal (from metadata): $subtotal');
          print('Discount Total: ${order.discountTotal}');
          print('Discount Tax: ${order.discountTax}');
          print('Shipping Total: ${order.shippingTotal}');
          print('Shipping Tax: ${order.shippingTax}');
          print('Cart Tax: ${order.cartTax}');
          print('Total: ${order.total}');
          print('Total Tax: ${order.totalTax}');
          print('--- BILLING INFO ---');
          print('Billing First Name: ${order.billing.firstName}');
          print('Billing Last Name: ${order.billing.lastName}');
          print('Billing Company: ${order.billing.company}');
          print('Billing Address 1: ${order.billing.address1}');
          print('Billing Address 2: ${order.billing.address2}');
          print('Billing City: ${order.billing.city}');
          print('Billing State: ${order.billing.state}');
          print('Billing Postcode: ${order.billing.postcode}');
          print('Billing Country: ${order.billing.country}');
          print('Billing Email: ${order.billing.email}');
          print('Billing Phone: ${order.billing.phone}');
          print('--- SHIPPING INFO ---');
          print('Shipping First Name: ${order.shipping.firstName}');
          print('Shipping Last Name: ${order.shipping.lastName}');
          print('Shipping Company: ${order.shipping.company}');
          print('Shipping Address 1: ${order.shipping.address1}');
          print('Shipping Address 2: ${order.shipping.address2}');
          print('Shipping City: ${order.shipping.city}');
          print('Shipping State: ${order.shipping.state}');
          print('Shipping Postcode: ${order.shipping.postcode}');
          print('Shipping Country: ${order.shipping.country}');
          print('Shipping Phone: ${order.shipping.phone}');
          print('--- LINE ITEMS ---');
          print('Number of line items: ${order.lineItems.length}');
          for (int i = 0; i < order.lineItems.length; i++) {
            var item = order.lineItems[i];
            print('  Item $i:');
            print('    ID: ${item.id}');
            print('    Product ID: ${item.productId}');
            print('    Variation ID: ${item.variationId}');
            print('    Name: ${item.name}');
            print('    SKU: ${item.sku}');
            print('    Quantity: ${item.quantity}');
            print('    Price: ${item.price}');
            print('    Subtotal: ${item.subtotal}');
            print('    Subtotal Tax: ${item.subtotalTax}');
            print('    Total: ${item.total}');
            print('    Total Tax: ${item.totalTax}');
            print('    Tax Class: ${item.taxClass}');
            print('    Image: ${item.image?.src ?? 'No image'}');
            print('    Meta Data Count: ${item.metaData.length}');
            if (item.metaData.isNotEmpty) {
              print('    Meta Data: ${item.metaData}');
            }
          }
          print('--- META DATA ---');
          print('Meta Data Count: ${order.metaData.length}');
          if (order.metaData.isNotEmpty) {
            print('Meta Data: ${order.metaData}');
          }
          print('=== END DEBUG ===');

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
                              color: Colors.black.withValues(alpha: 0.05),
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
                                    'Đơn hàng #${order.number.isNotEmpty ? order.number : order.id}',
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
                            _buildInfoRow(
                              'Netto',
                              '',
                              '${subtotal}${order.currencySymbol}',
                              Colors.black,
                            ),
                            if (double.parse(total_tax) > 0)
                              _buildInfoRow(
                                'Thuế',
                                '',
                                '${total_tax}${order.currencySymbol}',
                                Colors.orange,
                              ),
                            if (double.parse(order.shippingTotal) > 0)
                              _buildInfoRow(
                                'Phí vận chuyển',
                                '',
                                '${double.parse(order.shippingTotal).toInt()}${order.currencySymbol}',
                                Colors.blue,
                              ),

                            const Divider(height: 20, thickness: 1),
                            _buildInfoRow(
                              'Brutto',
                              '',
                              '${total}${order.currencySymbol}',
                              Colors.red,
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              'Số sản phẩm',
                              '',
                              '${order.lineItems.length} sản phẩm',
                              Colors.black,
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              'Thời gian đặt hàng',
                              '',
                              _formatDateTime(order.dateCreated),
                              Colors.black,
                            ),
                            if (order.datePaid != null)
                              _buildInfoRow(
                                'Thời gian thanh toán',
                                '',
                                _formatDateTime(order.datePaid!),
                                Colors.green,
                              ),
                            if (order.dateCompleted != null)
                              _buildInfoRow(
                                'Thời gian hoàn thành',
                                '',
                                _formatDateTime(order.dateCompleted!),
                                Colors.green,
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Customer Information Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.green[600],
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Thông tin khách hàng',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Customer ID
                            _buildInfoRow(
                              'Mã khách hàng',
                              '',
                              '#${order.customerId}',
                              Colors.blue,
                            ),

                            // Customer Name
                            if (order.billing.firstName.isNotEmpty ||
                                order.billing.lastName.isNotEmpty)
                              _buildInfoRow(
                                'Họ và tên',
                                '',
                                '${order.billing.firstName} ${order.billing.lastName}'
                                    .trim(),
                                Colors.black,
                              ),

                            // Company
                            if (order.billing.company.isNotEmpty)
                              _buildInfoRow(
                                'Công ty',
                                '',
                                order.billing.company,
                                Colors.black,
                              ),

                            // Email
                            if (order.billing.email.isNotEmpty)
                              _buildInfoRow(
                                'Email',
                                '',
                                order.billing.email,
                                Colors.black,
                              ),

                            // Phone
                            if (order.billing.phone.isNotEmpty)
                              _buildInfoRow(
                                'Số điện thoại',
                                '',
                                order.billing.phone,
                                Colors.black,
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Payment & Shipping Information Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.purple[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.payment,
                                    color: Colors.purple[600],
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Thông tin thanh toán & giao hàng',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Payment Method
                            if (order.paymentMethodTitle.isNotEmpty)
                              _buildInfoRow(
                                'Phương thức thanh toán',
                                '',
                                order.paymentMethodTitle,
                                Colors.black,
                              ),

                            // Transaction ID
                            if (order.transactionId.isNotEmpty)
                              _buildInfoRow(
                                'Mã giao dịch',
                                '',
                                order.transactionId,
                                Colors.blue,
                              ),

                            // Order Key
                            if (order.orderKey.isNotEmpty)
                              _buildInfoRow(
                                'Mã đơn hàng',
                                '',
                                order.orderKey,
                                Colors.grey,
                              ),

                            // Customer Note
                            if (order.customerNote.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                'Ghi chú khách hàng',
                                '',
                                '',
                                Colors.black,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 16,
                                  top: 4,
                                ),
                                child: Text(
                                  order.customerNote,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],

                            // Additional Order Info
                            if (order.customerIpAddress.isNotEmpty)
                              _buildInfoRow(
                                'IP khách hàng',
                                '',
                                order.customerIpAddress,
                                Colors.grey,
                              ),

                            // Shipping Address (if different from billing)
                            if (order.shipping.address1.isNotEmpty ||
                                order.shipping.city.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              _buildInfoRow(
                                'Địa chỉ giao hàng',
                                '',
                                '',
                                Colors.black,
                              ),
                              if (order.shipping.address1.isNotEmpty)
                                Container(
                                  width: double.infinity,
                                  child: Text(
                                    order.shipping.address1,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              if (order.shipping.address2.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 16,
                                    top: 2,
                                  ),
                                  child: Text(
                                    order.shipping.address2,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              if (order.shipping.city.isNotEmpty ||
                                  order.shipping.state.isNotEmpty ||
                                  order.shipping.postcode.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 16,
                                    top: 2,
                                  ),
                                  child: Text(
                                    '${order.shipping.city.isNotEmpty ? order.shipping.city : ''}${order.shipping.state.isNotEmpty ? ', ${order.shipping.state}' : ''}${order.shipping.postcode.isNotEmpty ? ' ${order.shipping.postcode}' : ''}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              if (order.shipping.country.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 16,
                                    top: 2,
                                  ),
                                  child: Text(
                                    order.shipping.country,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                            ],
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
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: SizedBox(
                    width: double.infinity,
                    child: PdfDownloadButton(
                      filename: 'invoice_${order.number.isNotEmpty ? order.number : order.id}.pdf',
                      generatePdf: () => PdfInvoiceService.generateInvoicePdf(order: order),
                      onSuccess: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('PDF đã được tải về thành công!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      onError: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Không thể tải PDF. Vui lòng thử lại.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String prefix,
    String value,
    Color valueColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: valueColor,
                fontWeight: valueColor == Colors.red
                    ? FontWeight.w600
                    : FontWeight.normal,
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
            color: Colors.black.withValues(alpha: 0.05),
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
                      placeholder: (context, url) => Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      errorWidget: (context, url, error) =>
                          Icon(Icons.image, color: Colors.grey[400], size: 30),
                    ),
                  )
                : Icon(Icons.image, color: Colors.grey[400], size: 30),
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
                  'Số lượng: ${item.quantity}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Giá: ${item.price.toInt()} zł',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,

                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }


}
