import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:store_manager/models/cart.dart';

String _formatMoneyFromTotals(String raw, CartTotals totals) {
  final minor = totals.currencyMinorUnit;
  final intVal = int.tryParse(raw) ?? 0;
  final divisor = math.pow(10, minor);
  final value = intVal / divisor;
  final amount = value.toStringAsFixed(minor);
  final prefix = totals.currencyPrefix;
  final suffix = totals.currencySuffix;
  final symbol = totals.currencySymbol;
  if (prefix.isNotEmpty) return '$prefix$amount';
  if (suffix.isNotEmpty) return '$amount$suffix';
  return symbol.isNotEmpty ? '$amount $symbol' : amount;
}

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
    // Parse total price to get initial values in minor units
    final totals = widget.cart.totals;
    final minor = totals.currencyMinorUnit;
    final intVal = int.tryParse(totals.totalPrice) ?? 0;
    _netto = (intVal / math.pow(10, minor)).toDouble();

    _coefficientController = TextEditingController(text: '1.23');
    _calculateBrutto(notifyParent: false);
    _coefficientController.addListener(() => _calculateBrutto(notifyParent: true));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.onValuesChanged != null) {
        widget.onValuesChanged!(_netto, _brutto);
      }
    });
  }

  @override
  void dispose() {
    _coefficientController.dispose();
    super.dispose();
  }

  void _calculateBrutto({bool notifyParent = true}) {
    final coefficient = double.tryParse(_coefficientController.text) ?? 1.23;
    if (mounted) {
      setState(() {
        _brutto = _netto * coefficient;
      });
    }
    if (notifyParent && mounted && widget.onValuesChanged != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.onValuesChanged != null) {
          widget.onValuesChanged!(_netto, _brutto);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totals = widget.cart.totals;
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
              _buildSummaryRow('Tổng số phụ', _formatMoneyFromTotals(totals.totalItems, totals)),
              const SizedBox(height: 8),
              if (totals.totalTax.isNotEmpty && totals.totalTax != '0') ...[
                _buildSummaryRow('Thuế', _formatMoneyFromTotals(totals.totalTax, totals)),
                const SizedBox(height: 8),
              ],
              if (totals.totalShipping != null && totals.totalShipping!.isNotEmpty) ...[
                _buildSummaryRow('Phí vận chuyển', _formatMoneyFromTotals(totals.totalShipping!, totals)),
                const SizedBox(height: 8),
              ],
              _buildSummaryRow('Tổng cộng', _formatMoneyFromTotals(totals.totalPrice, totals), isTotal: true),
              const SizedBox(height: 16),
              Container(height: 1, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              _buildEditableRow('Hệ số', _coefficientController, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              const SizedBox(height: 8),
              _buildSummaryRow('Netto', '${_netto.toStringAsFixed(totals.currencyMinorUnit)} ${totals.currencySymbol}'),
              const SizedBox(height: 8),
              _buildSummaryRow('Brutto', '${_brutto.toStringAsFixed(totals.currencyMinorUnit)} ${totals.currencySymbol}', isTotal: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
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
          value,
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
