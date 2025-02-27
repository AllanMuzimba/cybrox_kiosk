import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/invoice.dart';
import 'package:intl/intl.dart';

class PdfGenerator {
  static Future<pw.Document> generateInvoice(Invoice invoice) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Container(
          padding: const pw.EdgeInsets.all(40),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(invoice),
              pw.SizedBox(height: 40),
              _buildBillTo(invoice),
              pw.SizedBox(height: 30),
              _buildItemsTable(invoice),
              pw.SizedBox(height: 30),
              _buildFooter(invoice),
            ],
          ),
        ),
      ),
    );

    return pdf;
  }

  static pw.Widget _buildHeader(Invoice invoice) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'Invoice',
          style: pw.TextStyle(
            fontSize: 40,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.indigo900,
          ),
        ),
        pw.Row(
          children: [
            pw.Container(
              width: 20,
              height: 20,
              decoration: pw.BoxDecoration(
                color: PdfColors.green,
                shape: pw.BoxShape.circle,
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Text(
              'Garden Delights',
              style: pw.TextStyle(
                fontSize: 24,
                color: PdfColors.black,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildBillTo(Invoice invoice) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Bill to',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.indigo900,
          ),
        ),
        pw.SizedBox(height: 20),
        _buildInfoRow('Client Name', invoice.billTo),
        _buildInfoRow('Company Name', invoice.companyName),
        _buildInfoRow('Client Address', invoice.billToAddress),
        _buildInfoRow('Contact Person', invoice.billToContactPerson),
        _buildInfoRow('Contact Number', invoice.billToContactNumber),
      ],
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(
                color: PdfColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildItemsTable(Invoice invoice) {
    return pw.Table(
      border: pw.TableBorder.all(
        color: PdfColors.grey300,
        width: 1,
      ),
      columnWidths: {
        0: const pw.FlexColumnWidth(1), // Quantity
        1: const pw.FlexColumnWidth(1), // Item #
        2: const pw.FlexColumnWidth(3), // Description
        3: const pw.FlexColumnWidth(1), // Unit Price
        4: const pw.FlexColumnWidth(1), // Total
      },
      children: [
        // Header
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: PdfColors.indigo900,
          ),
          children: [
            _buildTableHeader('Quantity'),
            _buildTableHeader('Item #'),
            _buildTableHeader('Description'),
            _buildTableHeader('Unit Price'),
            _buildTableHeader('Total'),
          ],
        ),
        // Items
        ...invoice.items.map((item) => pw.TableRow(
          children: [
            _buildTableCell(item.quantity.toString()),
            _buildTableCell(item.itemNumber ?? ''),
            _buildTableCell(item.description),
            _buildTableCell('\$${item.unitPrice.toStringAsFixed(2)}'),
            _buildTableCell('\$${item.total.toStringAsFixed(2)}'),
          ],
        )),
        // Empty rows
        ...List.generate(10 - invoice.items.length, (index) => pw.TableRow(
          children: List.generate(5, (index) => _buildTableCell('')),
        )),
      ],
    );
  }

  static pw.Widget _buildTableHeader(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _buildTableCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(text),
    );
  }

  static pw.Widget _buildFooter(Invoice invoice) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Notes:'),
                pw.Container(
                  width: 300,
                  child: pw.Text(
                    invoice.notes,
                    style: const pw.TextStyle(
                      color: PdfColors.grey700,
                    ),
                  ),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                _buildTotalRow('Subtotal', invoice.subtotal),
                _buildTotalRow('Sales Tax', invoice.taxTotal),
                pw.Container(
                  color: PdfColors.indigo900,
                  padding: const pw.EdgeInsets.all(8),
                  child: _buildTotalRow('TOTAL', invoice.total, isTotal: true),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 40),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _buildSignatureLine('Signature'),
            _buildSignatureLine('Printed Name'),
            _buildSignatureLine('Date'),
            _buildSignatureLine('Payment method'),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          'Terms & Conditions',
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          invoice.terms ?? 'Standard terms and conditions apply.',
          style: const pw.TextStyle(
            color: PdfColors.grey700,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTotalRow(String label, double amount, {bool isTotal = false}) {
    return pw.Container(
      width: 200,
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              color: isTotal ? PdfColors.white : PdfColors.black,
            ),
          ),
          pw.Text(
            '\$${amount.toStringAsFixed(2)}',
            style: pw.TextStyle(
              fontWeight: isTotal ? pw.FontWeight.bold : null,
              color: isTotal ? PdfColors.white : PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSignatureLine(String label) {
    return pw.Column(
      children: [
        pw.Container(
          width: 120,
          height: 1,
          color: PdfColors.black,
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          label,
          style: const pw.TextStyle(
            color: PdfColors.grey700,
          ),
        ),
      ],
    );
  }
} 