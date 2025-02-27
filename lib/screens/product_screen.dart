import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cybrox_kiosk_management/services/supabase_service.dart';
import 'package:cybrox_kiosk_management/models/product.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import 'package:pdf/widgets.dart' as pw;

class ProductScreen extends StatefulWidget {
  final bool isAdmin;
  static const routeName = '/product';

  const ProductScreen({super.key, this.isAdmin = false});

  @override
  _ProductScreenState createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Product> _products = [];
  bool _isLoading = false;
  bool _isCardView = true;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _purchasePriceController = TextEditingController();
  final TextEditingController _sellPriceController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _stockQuantityController = TextEditingController();
  final TextEditingController _taxRateController = TextEditingController();
  final TextEditingController _addQuantityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _taxRateController.text = '0';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _purchasePriceController.dispose();
    _sellPriceController.dispose();
    _barcodeController.dispose();
    _stockQuantityController.dispose();
    _taxRateController.dispose();
    _addQuantityController.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final products = await _supabaseService.fetchProducts();
      setState(() {
        _products = products;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load products: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showAddProductDialog() {
    _clearFields();
    _barcodeController.text = _generateUniqueBarcode();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Product'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                TextField(
                  controller: _purchasePriceController,
                  decoration: const InputDecoration(labelText: 'Purchase Price'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _sellPriceController,
                  decoration: const InputDecoration(labelText: 'Sell Price'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _barcodeController,
                  decoration: const InputDecoration(labelText: 'Barcode'),
                  readOnly: true,
                ),
                TextField(
                  controller: _stockQuantityController,
                  decoration: const InputDecoration(labelText: 'Stock Quantity'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _taxRateController,
                  decoration: const InputDecoration(labelText: 'Tax Rate (%)'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _addProduct,
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showProductDetails(Product product) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(product.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Description: ${product.description}'),
              Text('Purchase Price: \$${product.price.toStringAsFixed(2)}'),
              Text('Sell Price: \$${product.sellPrice.toStringAsFixed(2)}'),
              Text('Barcode: ${product.barcode}'),
              Text('Stock Quantity: ${product.stockQuantity}'),
              Text('Tax Rate: ${product.taxRate}%'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            if (widget.isAdmin) ...[
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showEditProductDialog(product);
                },
                child: const Text('Edit'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteProduct(product.id!);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ],
        );
      },
    );
  }

  void _showEditProductDialog(Product product) {
    _nameController.text = product.name;
    _descriptionController.text = product.description;
    _purchasePriceController.text = product.price.toString();
    _sellPriceController.text = product.sellPrice.toString();
    _barcodeController.text = product.barcode;
    _stockQuantityController.text = product.stockQuantity.toString();
    _taxRateController.text = product.taxRate.toString();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Product'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                TextField(
                  controller: _purchasePriceController,
                  decoration: const InputDecoration(labelText: 'Purchase Price'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _sellPriceController,
                  decoration: const InputDecoration(labelText: 'Sell Price'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _barcodeController,
                  decoration: const InputDecoration(labelText: 'Barcode'),
                  readOnly: true,
                ),
                TextField(
                  controller: _stockQuantityController,
                  decoration: const InputDecoration(labelText: 'Stock Quantity'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _taxRateController,
                  decoration: const InputDecoration(labelText: 'Tax Rate (%)'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _updateProduct(product.id!),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _updateProduct(int productId) async {
    if (!_validateInputs()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedProduct = Product(
        id: productId,
        name: _nameController.text,
        description: _descriptionController.text,
        price: double.parse(_purchasePriceController.text),
        sellPrice: double.parse(_sellPriceController.text),
        barcode: _barcodeController.text,
        stockQuantity: int.parse(_stockQuantityController.text),
        taxRate: double.parse(_taxRateController.text),
      );

      await _supabaseService.updateProduct(updatedProduct);

      setState(() {
        final index = _products.indexWhere((p) => p.id == productId);
        if (index != -1) {
          _products[index] = updatedProduct;
        }
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update product: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _deleteProduct(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _supabaseService.deleteProduct(id);
        setState(() {
          _products.removeWhere((product) => product.id == id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete product: ${e.toString()}')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showAddQuantityDialog(Product product) {
    _addQuantityController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Quantity'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Product: ${product.name}'),
            Text('Current Stock: ${product.stockQuantity}'),
            TextField(
              controller: _addQuantityController,
              decoration: const InputDecoration(labelText: 'Additional Quantity'),
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
            onPressed: () async {
              final additionalQuantity = int.tryParse(_addQuantityController.text);
              if (additionalQuantity == null || additionalQuantity <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid positive number')),
                );
                return;
              }

              setState(() {
                _isLoading = true;
              });

              try {
                final updatedProduct = Product(
                  id: product.id,
                  name: product.name,
                  description: product.description,
                  price: product.price,
                  barcode: product.barcode,
                  stockQuantity: product.stockQuantity + additionalQuantity,
                  taxRate: product.taxRate,
                  sellPrice: product.sellPrice,
                );

                await _supabaseService.updateProduct(updatedProduct);

                setState(() {
                  final index = _products.indexWhere((p) => p.id == product.id);
                  if (index != -1) {
                    _products[index] = updatedProduct;
                  }
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Quantity added successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to add quantity: ${e.toString()}')),
                );
              } finally {
                setState(() {
                  _isLoading = false;
                });
              }
            },
            child: _isLoading ? const CircularProgressIndicator() : const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addProduct() async {
    if (!_validateInputs()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final barcode = _generateUniqueBarcode();
      final purchasePrice = double.parse(_purchasePriceController.text);
      final sellPrice = double.parse(_sellPriceController.text);
      final stockQuantity = int.parse(_stockQuantityController.text);
      final taxRate = double.parse(_taxRateController.text);

      final product = Product(
        name: _nameController.text,
        description: _descriptionController.text,
        price: purchasePrice,
        barcode: barcode,
        stockQuantity: stockQuantity,
        taxRate: taxRate,
        sellPrice: sellPrice,
      );

      final addedProduct = await _supabaseService.addProduct(context, product);

      setState(() {
        _products.add(addedProduct);
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product added successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add product: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _validateInputs() {
    String? errorMessage;

    if (_nameController.text.isEmpty) {
      errorMessage = 'Name cannot be empty';
    } else if (_barcodeController.text.isEmpty) {
      errorMessage = 'Barcode cannot be empty';
    } else {
      try {
        double.parse(_purchasePriceController.text);
        double.parse(_sellPriceController.text);
        int.parse(_stockQuantityController.text);
        double.parse(_taxRateController.text);
      } catch (e) {
        errorMessage = 'Please enter valid numbers for price, quantity, and tax rate';
      }
    }

    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
      return false;
    }

    return true;
  }

  String _generateUniqueBarcode() {
    String barcode;
    do {
      // Generate the first 7 digits randomly
      final random = Random();
      final firstSevenDigits = List.generate(7, (index) => random.nextInt(10)).join();
      
      // Calculate the check digit
      final checkDigit = _calculateEAN8CheckDigit(firstSevenDigits);
      
      // Combine the digits to form the EAN-8 barcode
      barcode = '$firstSevenDigits$checkDigit';
    } while (_products.any((product) => product.barcode == barcode));
    
    return barcode;
  }

  int _calculateEAN8CheckDigit(String digits) {
    int sum = 0;

    // Calculate the sum based on the EAN-8 algorithm
    for (int i = 0; i < digits.length; i++) {
      int digit = int.parse(digits[i]);
      if (i % 2 == 0) {
        sum += digit; // Add odd position digits (0-based index)
      } else {
        sum += digit * 3; // Add even position digits (0-based index) multiplied by 3
      }
    }

    // Calculate the check digit
    int checkDigit = (10 - (sum % 10)) % 10;
    return checkDigit;
  }

  void _clearFields() {
    _nameController.clear();
    _descriptionController.clear();
    _purchasePriceController.clear();
    _sellPriceController.clear();
    _barcodeController.clear();
    _stockQuantityController.clear();
    _taxRateController.text = '0';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddProductDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchProducts,
          ),
          IconButton(
            icon: Icon(_isCardView ? Icons.list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isCardView = !_isCardView;
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? const Center(child: Text('No products available'))
              : _isCardView
                  ? _buildCardView()
                  : _buildTableView(),
    );
  }


Widget _buildCardView() {
  return GridView.builder(
    padding: const EdgeInsets.all(16),
    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 200,
      childAspectRatio: 0.75, // Adjusted ratio to accommodate the bottom buttons
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
    ),
    itemCount: _products.length,
    itemBuilder: (context, index) {
      final product = _products[index];
      return _ProductCard(
        product: product,
        onTap: () => _showProductDetails(product),
        onAddQuantity: () => _showAddQuantityDialog(product),
        onDelete: widget.isAdmin ? () => _deleteProduct(product.id!) : null,
      );
    },
  );
}


  Widget _buildTableView() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: _generatePdf,
            ),
          ],
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 16,
            dividerThickness: 2,
            headingRowHeight: 50,
            headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
            headingRowColor: WidgetStateProperty.resolveWith<Color>((states) => Colors.grey[200]!),
            border: TableBorder.all(color: Colors.black, width: 2),
            columns: const [
              DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Stock', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Barcode', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Purchase Price', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Sell Price', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Tax Rate', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Total Cost', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Total Gross', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Total Net', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
              DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: _products.map((product) {
              return DataRow(
                cells: [
                  DataCell(Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text('${product.stockQuantity}')),
                  DataCell(Text(product.barcode)),
                  DataCell(Text('\$${product.price.toStringAsFixed(2)}')),
                  DataCell(Text('\$${product.sellPrice.toStringAsFixed(2)}')),
                  DataCell(Text('${product.taxRate}%')),
                  DataCell(Text('\$${(product.price * product.stockQuantity * (1 + product.taxRate / 100)).toStringAsFixed(2)}')),
                  DataCell(Text('\$${(product.sellPrice * product.stockQuantity * (1 + product.taxRate / 100)).toStringAsFixed(2)}')),
                  DataCell(Text('\$${(product.sellPrice * product.stockQuantity * (1 + product.taxRate / 100) - product.price * product.stockQuantity * (1 + product.taxRate / 100)).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                  DataCell(
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => _showAddQuantityDialog(product),
                        ),
                        if (widget.isAdmin)
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteProduct(product.id!),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _generatePdf() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Table.fromTextArray(
            data: <List<String>>[
              <String>['Name', 'Stock', 'Barcode', 'Purchase Price', 'Sell Price', 'Tax Rate', 'Total Cost', 'Total Gross', 'Total Net'],
              ..._products.map((product) {
                return [
                  product.name,
                  product.stockQuantity.toString(),
                  product.barcode,
                  '\$${product.price.toStringAsFixed(2)}',
                  '\$${product.sellPrice.toStringAsFixed(2)}',
                  '${product.taxRate}%',
                  '\$${(product.price * product.stockQuantity * (1 + product.taxRate / 100)).toStringAsFixed(2)}',
                  '\$${(product.sellPrice * product.stockQuantity * (1 + product.taxRate / 100)).toStringAsFixed(2)}',
                  '\$${(product.sellPrice * product.stockQuantity * (1 + product.taxRate / 100) - product.price * product.stockQuantity * (1 + product.taxRate / 100)).toStringAsFixed(2)}',
                ];
              }),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onAddQuantity;
  final VoidCallback? onDelete;

  const _ProductCard({
    required this.product,
    required this.onTap,
    required this.onAddQuantity,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: Colors.lightBlue[100],
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space between content and buttons
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Content section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Text(
                          product.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Stock: ${product.stockQuantity}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        'Code: ${product.barcode}',
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  
                  // Buttons section at bottom
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton(
                        onPressed: onAddQuantity,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          minimumSize: const Size(double.infinity, 36),
                        ),
                        child: const Text('Add Quantity'),
                      ),
                      if (onDelete != null) ...[
                        const SizedBox(height: 4),
                        Center(
                          child: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: onDelete,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}