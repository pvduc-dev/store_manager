import 'package:flutter/material.dart';
import 'package:store_manager/models/cart.dart';


class OrderSummaryWidget extends StatefulWidget {
  final Cart cart;
  final Function(double netto, double brutto)? onValuesChanged;

  const OrderSummaryWidget({
    super.key,
    required this.cart,
    this.onValuesChanged,
  });

  @override
  State<OrderSummaryWidget> createState() => _OrderSummaryWidgetState();
}

class _OrderSummaryWidgetState extends State<OrderSummaryWidget> {
  late TextEditingController _coefficientController;
  double _brutto = 0.0;
  late double _netto;

  @override
  void initState() {
    super.initState();
    
    // Parse total price to get initial values
    double totalPrice = 0.0;
    try {
      totalPrice = double.tryParse(widget.cart.totals.totalPrice.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
    } catch (e) {
      totalPrice = 0.0;
    }
    
    _coefficientController = TextEditingController(text: '1.23');
    _netto = totalPrice;
    
    // Calculate initial brutto without calling callback
    _calculateBrutto(notifyParent: false);
    
    // Add listeners
    _coefficientController.addListener(() => _calculateBrutto(notifyParent: true));
    
    // Notify parent after build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.onValuesChanged != null) {
        // Sử dụng addPostFrameCallback để tránh gọi callback trong build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && widget.onValuesChanged != null) {
            // Sử dụng addPostFrameCallback để tránh gọi callback trong build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && widget.onValuesChanged != null) {
                // Sử dụng addPostFrameCallback để tránh gọi callback trong build
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && widget.onValuesChanged != null) {
                    // Sử dụng addPostFrameCallback để tránh gọi callback trong build
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && widget.onValuesChanged != null) {
                        // Sử dụng addPostFrameCallback để tránh gọi callback trong build
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted && widget.onValuesChanged != null) {
                            widget.onValuesChanged!(_netto, _brutto);
                          }
                        });
                      }
                    });
                  }
                });
              }
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _coefficientController.dispose();
    super.dispose();
  }

  void _calculateBrutto({bool notifyParent = true}) {
    try {
      double coefficient = double.tryParse(_coefficientController.text) ?? 1.23;
      if (mounted) {
        setState(() {
          _brutto = _netto * coefficient;
        });
      }
      
      // Chỉ gọi callback nếu được yêu cầu và không phải trong initState
      if (notifyParent && mounted && widget.onValuesChanged != null) {
        // Sử dụng addPostFrameCallback để tránh gọi callback trong build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && widget.onValuesChanged != null) {
            // Sử dụng addPostFrameCallback để tránh gọi callback trong build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && widget.onValuesChanged != null) {
                // Sử dụng addPostFrameCallback để tránh gọi callback trong build
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && widget.onValuesChanged != null) {
                    // Sử dụng addPostFrameCallback để tránh gọi callback trong build
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && widget.onValuesChanged != null) {
                        // Sử dụng addPostFrameCallback để tránh gọi callback trong build
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted && widget.onValuesChanged != null) {
                            widget.onValuesChanged!(_netto, _brutto);
                          }
                        });
                      }
                    });
                  }
                });
              }
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _brutto = 0.0;
        });
      }
      
      // Chỉ gọi callback nếu được yêu cầu và không phải trong initState
      if (notifyParent && mounted && widget.onValuesChanged != null) {
        // Sử dụng addPostFrameCallback để tránh gọi callback trong build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && widget.onValuesChanged != null) {
            widget.onValuesChanged!(_netto, 0.0);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thông tin đơn hàng',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              // Subtotal
              _buildSummaryRow('Tổng số phụ', widget.cart.totals.totalItems),
              const SizedBox(height: 8),
              
              // Tax
              if (widget.cart.totals.totalTax.isNotEmpty && widget.cart.totals.totalTax != '0') ...[
                _buildSummaryRow('Thuế', widget.cart.totals.totalTax),
                const SizedBox(height: 8),
              ],
              
              // Shipping
              if (widget.cart.totals.totalShipping != null && widget.cart.totals.totalShipping!.isNotEmpty) ...[
                _buildSummaryRow('Phí vận chuyển', widget.cart.totals.totalShipping!),
                const SizedBox(height: 8),
              ],
              
              
              // Total
              _buildSummaryRow(
                'Tổng cộng',
                widget.cart.totals.totalPrice,
                isTotal: true,
              ),
              const SizedBox(height: 16),
              
              // Divider
              Container(
                height: 1,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              
              // Coefficient
              _buildEditableRow(
                'Hệ số',
                _coefficientController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 8),
              
              // Netto (fixed value)
              _buildSummaryRow(
                'Netto',
                '${(_netto / 100.0).toStringAsFixed(2)} zł',
              ),
              const SizedBox(height: 8),
              
              // Brutto (calculated)
              _buildSummaryRow(
                'Brutto',
                '${(_brutto / 100.0).toStringAsFixed(2)} zł',
                isTotal: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    // Format currency value
    String formattedValue = value;
    try {
      // Try to parse as number and format as currency
      double? numericValue = double.tryParse(value.replaceAll(RegExp(r'[^\d.]'), ''));
      if (numericValue != null) {
                    formattedValue = '${(numericValue / 100.0).toStringAsFixed(2)} zł';
      }
    } catch (e) {
      // If parsing fails, use original value
      formattedValue = value;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            color: isTotal ? Colors.black : Colors.grey[700],
          ),
        ),
        Text(
          formattedValue,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildEditableRow(String label, TextEditingController controller, {TextInputType? keyboardType}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        SizedBox(
          width: 120,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType ?? TextInputType.text,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }
}
