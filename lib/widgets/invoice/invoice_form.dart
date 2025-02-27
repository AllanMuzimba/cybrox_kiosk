import 'package:flutter/material.dart';
import '../../models/invoice.dart';
import '../../models/invoice_template.dart';

class InvoiceForm extends StatefulWidget {
  final Invoice invoice;
  final Function(Invoice) onUpdate;

  const InvoiceForm({
    Key? key,
    required this.invoice,
    required this.onUpdate,
  }) : super(key: key);

  @override
  _InvoiceFormState createState() => _InvoiceFormState();
}

class _InvoiceFormState extends State<InvoiceForm> {
  late TextEditingController companyNameController;
  late TextEditingController companyAddressController;
  late TextEditingController billToController;
  late TextEditingController billToAddressController;
  late TextEditingController shipToController;
  late TextEditingController shipToAddressController;
  late TextEditingController notesController;

  @override
  void initState() {
    super.initState();
    initializeControllers();
  }

  void initializeControllers() {
    companyNameController = TextEditingController(text: widget.invoice.companyName);
    companyAddressController = TextEditingController(text: widget.invoice.companyAddress);
    billToController = TextEditingController(text: widget.invoice.billTo);
    billToAddressController = TextEditingController(text: widget.invoice.billToAddress);
    shipToController = TextEditingController(text: widget.invoice.shipTo);
    shipToAddressController = TextEditingController(text: widget.invoice.shipToAddress);
    notesController = TextEditingController(text: widget.invoice.notes);
  }

  Future<void> _saveAsTemplate() async {
    final template = InvoiceTemplate(
      name: 'Template ${DateTime.now().millisecondsSinceEpoch}',
      companyName: widget.invoice.companyName,
      companyAddress: widget.invoice.companyAddress,
      notes: widget.invoice.notes,
      headerStyle: widget.invoice.customFont,
    );
    
    await InvoiceTemplate.saveTemplate(template);
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Template saved successfully')),
    );
  }

  Future<void> _loadTemplate() async {
    final templates = await InvoiceTemplate.loadTemplates();
    if (!mounted) return;
    
    if (templates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No templates found')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Template'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: templates.length,
            itemBuilder: (context, index) => ListTile(
              title: Text(templates[index].name),
              onTap: () {
                final template = templates[index];
                setState(() {
                  widget.invoice.companyName = template.companyName;
                  widget.invoice.companyAddress = template.companyAddress;
                  widget.invoice.notes = template.notes;
                  widget.invoice.customFont = template.headerStyle;
                });
                widget.onUpdate(widget.invoice);
                Navigator.pop(context);
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showStyleDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Style Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Font Size'),
              trailing: DropdownButton<double>(
                value: widget.invoice.customFont?.fontSize ?? 14,
                items: [12, 14, 16, 18, 20, 24]
                    .map((size) => DropdownMenuItem(
                          value: size.toDouble(),
                          child: Text(size.toString()),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    widget.invoice.customFont = (widget.invoice.customFont ?? const TextStyle()).copyWith(fontSize: value);
                  });
                  widget.onUpdate(widget.invoice);
                },
              ),
            ),
            // Add more style options as needed
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40.0), // A4 margin
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with company details
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Company Info (Left)
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'From:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: companyNameController,
                        decoration: const InputDecoration(
                          labelText: 'Company Name',
                          isDense: true,
                        ),
                        onChanged: (value) {
                          widget.invoice.companyName = value;
                          widget.onUpdate(widget.invoice);
                        },
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: companyAddressController,
                        decoration: const InputDecoration(
                          labelText: 'Company Address',
                          isDense: true,
                        ),
                        maxLines: 2,
                        onChanged: (value) {
                          widget.invoice.companyAddress = value;
                          widget.onUpdate(widget.invoice);
                        },
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Contact Person',
                          isDense: true,
                        ),
                        onChanged: (value) {
                          widget.invoice.companyContactPerson = value;
                          widget.onUpdate(widget.invoice);
                        },
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Contact Number',
                          isDense: true,
                        ),
                        keyboardType: TextInputType.phone,
                        onChanged: (value) {
                          widget.invoice.companyContactNumber = value;
                          widget.onUpdate(widget.invoice);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 40),
              // Invoice Info (Right)
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bill To:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: billToController,
                        decoration: const InputDecoration(
                          labelText: 'Client Name',
                          isDense: true,
                        ),
                        onChanged: (value) {
                          widget.invoice.billTo = value;
                          widget.onUpdate(widget.invoice);
                        },
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: billToAddressController,
                        decoration: const InputDecoration(
                          labelText: 'Billing Address',
                          isDense: true,
                        ),
                        maxLines: 2,
                        onChanged: (value) {
                          widget.invoice.billToAddress = value;
                          widget.onUpdate(widget.invoice);
                        },
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Contact Person',
                          isDense: true,
                        ),
                        onChanged: (value) {
                          widget.invoice.billToContactPerson = value;
                          widget.onUpdate(widget.invoice);
                        },
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Contact Number',
                          isDense: true,
                        ),
                        keyboardType: TextInputType.phone,
                        onChanged: (value) {
                          widget.invoice.billToContactNumber = value;
                          widget.onUpdate(widget.invoice);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(), // Empty space on the right
            ],
          ),

          const SizedBox(height: 40),

          // Items Table
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade800, width: 1.5),
            ),
            child: Column(
              children: [
                // Table Header
                Container(
                  color: Colors.grey.shade200,
                  child: Row(
                    children: [
                      _buildHeaderCell('#', flex: 1),
                      _buildHeaderCell('Description', flex: 4),
                      _buildHeaderCell('Qty', flex: 1),
                      _buildHeaderCell('Unit Price', flex: 2),
                      _buildHeaderCell('Tax', flex: 1),
                      _buildHeaderCell('Total', flex: 2),
                    ],
                  ),
                ),
                // Table Items
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.invoice.items.length,
                  itemBuilder: (context, index) {
                    final item = widget.invoice.items[index];
                    return Container(
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Row number
                          _buildCell('${index + 1}', flex: 1),
                          
                          // Description
                          Expanded(
                            flex: 4,
                            child: TextFormField(
                              initialValue: item.description,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(8),
                              ),
                              onChanged: (value) {
                                item.description = value;
                                widget.onUpdate(widget.invoice);
                              },
                            ),
                          ),
                          
                          // Quantity
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              initialValue: item.quantity.toString(),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(8),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                setState(() {
                                  item.quantity = double.tryParse(value) ?? 0;
                                });
                                widget.onUpdate(widget.invoice);
                              },
                            ),
                          ),
                          
                          // Unit Price
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              initialValue: item.unitPrice.toString(),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(8),
                                prefixText: '\$ ',
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                setState(() {
                                  item.unitPrice = double.tryParse(value) ?? 0;
                                });
                                widget.onUpdate(widget.invoice);
                              },
                            ),
                          ),
                          
                          // Tax Rate
                          Expanded(
                            flex: 1,
                            child: DropdownButtonFormField<double>(
                              value: item.taxRate,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(8),
                              ),
                              items: [
                                DropdownMenuItem(value: 0.0, child: Text('0%')),
                                DropdownMenuItem(value: 0.10, child: Text('10%')),
                                DropdownMenuItem(value: 0.15, child: Text('15%')),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    item.taxRate = value;
                                  });
                                  widget.onUpdate(widget.invoice);
                                }
                              },
                            ),
                          ),
                          
                          // Total (auto-calculated)
                          _buildCell(
                            '\$${item.total.toStringAsFixed(2)}',
                            flex: 2,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          
                          // Delete button
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                widget.invoice.items.removeAt(index);
                                widget.onUpdate(widget.invoice);
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Add Item Button
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Item'),
            onPressed: () {
              setState(() {
                widget.invoice.items.add(InvoiceItem());
                widget.onUpdate(widget.invoice);
              });
            },
          ),

          const SizedBox(height: 40),

          // Totals and Notes
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notes (Left)
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notes:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 4,
                      onChanged: (value) {
                        widget.invoice.notes = value;
                        widget.onUpdate(widget.invoice);
                      },
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Totals (Right)
              Container(
                width: 300,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildTotalRow('Subtotal:', widget.invoice.subtotal),
                    _buildTotalRow('Tax Total:', widget.invoice.taxTotal),
                    const Divider(),
                    _buildTotalRow(
                      'Total:',
                      widget.invoice.total,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCell(String text, {required int flex, TextStyle? style}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Text(
          text,
          style: style,
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, {TextStyle? style}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: style,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    companyNameController.dispose();
    companyAddressController.dispose();
    billToController.dispose();
    billToAddressController.dispose();
    shipToController.dispose();
    shipToAddressController.dispose();
    notesController.dispose();
    super.dispose();
  }
} 