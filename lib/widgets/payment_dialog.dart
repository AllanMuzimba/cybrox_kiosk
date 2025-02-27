import 'package:cybrox_kiosk_management/models/company.dart';
import 'package:flutter/material.dart';

class PaymentDialog extends StatefulWidget {
  final Company company;
  final double outstandingBalance;
  final Function(double amount, String method) onSubmit;

  const PaymentDialog({
    super.key,
    required this.company,
    required this.outstandingBalance,
    required this.onSubmit,
  });

  @override
  _PaymentDialogState createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  String _paymentMethod = 'Cash';
  final _amountController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Payment for ${widget.company.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Outstanding Balance: \$${widget.outstandingBalance.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _paymentMethod,
            items: const [
              DropdownMenuItem(value: 'Cash', child: Text('Cash')),
              DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer')),
              DropdownMenuItem(value: 'Card', child: Text('Card')),
            ],
            onChanged: (value) => setState(() => _paymentMethod = value!),
            decoration: const InputDecoration(labelText: 'Payment Method'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            decoration: const InputDecoration(
              labelText: 'Amount',
              prefixText: '\$',
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final amount = double.tryParse(_amountController.text);
            if (amount == null || amount <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter a valid amount')),
              );
              return;
            }
            widget.onSubmit(amount, _paymentMethod);
            Navigator.pop(context);
          },
          child: const Text('Submit Payment'),
        ),
      ],
    );
  }
}