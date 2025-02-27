import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import '../../models/invoice.dart';
import '../../widgets/invoice/invoice_form.dart';
import '../../services/pdf_generator.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class InvoiceScreen extends StatefulWidget {
  const InvoiceScreen({Key? key}) : super(key: key);

  @override
  _InvoiceScreenState createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  Invoice? currentInvoice;
  bool isLoading = false;
  List<String> savedInvoices = [];
  
  @override
  void initState() {
    super.initState();
    loadSavedInvoicesList();
  }

  Future<void> loadSavedInvoicesList() async {
    try {
      setState(() => isLoading = true);
      final directory = await getApplicationDocumentsDirectory();
      final invoiceDir = Directory('${directory.path}/invoices');
      if (!await invoiceDir.exists()) {
        await invoiceDir.create(recursive: true);
        return;
      }

      final files = await invoiceDir.list().toList();
      setState(() {
        savedInvoices = files
            .where((file) => file.path.endsWith('.json'))
            .map((file) => file.path.split('/').last.replaceAll('.json', ''))
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading saved invoices: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> saveInvoice(Invoice invoice, String fileName) async {
    try {
      setState(() => isLoading = true);
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/invoices/$fileName.json');
      await file.create(recursive: true);
      await file.writeAsString(jsonEncode(invoice.toJson()));
      
      await loadSavedInvoicesList();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice saved successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving invoice: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> loadInvoice(String fileName) async {
    try {
      setState(() => isLoading = true);
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/invoices/$fileName.json');
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        setState(() {
          currentInvoice = Invoice.fromJson(jsonDecode(jsonString));
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading invoice: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> deleteInvoice(String fileName) async {
    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete invoice "$fileName"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      setState(() => isLoading = true);
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/invoices/$fileName.json');
      if (await file.exists()) {
        await file.delete();
        await loadSavedInvoicesList();
        
        // Clear current invoice if it's the one being deleted
        if (currentInvoice?.invoiceNumber == fileName) {
          setState(() => currentInvoice = null);
        }
      }
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice deleted successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting invoice: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showLoadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Saved Invoices'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: savedInvoices.isEmpty
              ? const Center(child: Text('No saved invoices found'))
              : ListView.builder(
                  itemCount: savedInvoices.length,
                  itemBuilder: (context, index) {
                    final fileName = savedInvoices[index];
                    return ListTile(
                      title: Text(fileName),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              Navigator.pop(context);
                              deleteInvoice(fileName);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.file_open),
                            onPressed: () {
                              Navigator.pop(context);
                              loadInvoice(fileName);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
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

  void _showSaveDialog() {
    final TextEditingController nameController = TextEditingController(
      text: currentInvoice?.invoiceNumber ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Invoice'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Invoice Name',
            hintText: 'Enter a name for this invoice',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(context);
                if (currentInvoice != null) {
                  currentInvoice!.invoiceNumber = name;
                  saveInvoice(currentInvoice!, name);
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ).then((_) => nameController.dispose());
  }

  Future<void> exportToPdf(Invoice invoice) async {
    try {
      setState(() => isLoading = true);
      final pdf = await PdfGenerator.generateInvoice(invoice);
      
      if (!mounted) return;
      
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Invoice_${invoice.invoiceNumber}',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: isLoading
                ? null
                : () {
                    setState(() {
                      currentInvoice = Invoice(
                        invoiceNumber: DateTime.now().millisecondsSinceEpoch.toString(),
                        date: DateTime.now(),
                      );
                    });
                  },
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: (isLoading || currentInvoice == null)
                ? null
                : _showSaveDialog,
          ),
          IconButton(
            icon: const Icon(Icons.folder),
            onPressed: isLoading ? null : _showLoadDialog,
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: (isLoading || currentInvoice == null)
                ? null
                : () => exportToPdf(currentInvoice!),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (currentInvoice == null)
            const Center(child: Text('Create or load an invoice'))
          else
            InvoiceForm(
              invoice: currentInvoice!,
              onUpdate: (invoice) {
                setState(() {
                  currentInvoice = invoice;
                });
              },
            ),
          if (isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
} 