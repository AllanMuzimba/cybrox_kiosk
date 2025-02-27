import 'package:flutter/material.dart';
import '../../models/invoice.dart';

class InvoiceItemForm extends StatefulWidget {
  final InvoiceItem item;
  final Function(InvoiceItem) onUpdate;
  final VoidCallback onDelete;

  const InvoiceItemForm({
    Key? key,
    required this.item,
    required this.onUpdate,
    required this.onDelete,
  }) : super(key: key);

  @override
  _InvoiceItemFormState createState() => _InvoiceItemFormState();
}

class _InvoiceItemFormState extends State<InvoiceItemForm> {
  final _formKey = GlobalKey<FormState>();
  
  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextFormField(
              initialValue: widget.item.description,
              decoration: const InputDecoration(labelText: 'Description'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
              onChanged: (value) {
                widget.item.description = value;
                widget.onUpdate(widget.item);
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              initialValue: widget.item.quantity.toString(),
              decoration: const InputDecoration(labelText: 'Quantity'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Required';
                }
                if (double.tryParse(value) == null) {
                  return 'Invalid number';
                }
                if (double.parse(value) <= 0) {
                  return 'Must be > 0';
                }
                return null;
              },
              onChanged: (value) {
                widget.item.quantity = double.tryParse(value) ?? 0;
                widget.onUpdate(widget.item);
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              initialValue: widget.item.unitPrice.toString(),
              decoration: const InputDecoration(labelText: 'Unit Price'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Required';
                }
                if (double.tryParse(value) == null) {
                  return 'Invalid number';
                }
                if (double.parse(value) < 0) {
                  return 'Must be ≥ 0';
                }
                return null;
              },
              onChanged: (value) {
                widget.item.unitPrice = double.tryParse(value) ?? 0;
                widget.onUpdate(widget.item);
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              initialValue: widget.item.itemNumber,
              decoration: const InputDecoration(labelText: 'Item #'),
              onChanged: (value) {
                widget.item.itemNumber = value;
                widget.onUpdate(widget.item);
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<double>(
              value: widget.item.taxRate,
              decoration: const InputDecoration(labelText: 'Tax Rate'),
              items: [
                DropdownMenuItem(value: 0.0, child: Text('0%')),
                DropdownMenuItem(value: 0.10, child: Text('10%')),
                DropdownMenuItem(value: 0.15, child: Text('15%')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    widget.item.taxRate = value;
                  });
                  widget.onUpdate(widget.item);
                }
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: widget.onDelete,
          ),
        ],
      ),
    );
  }
} 