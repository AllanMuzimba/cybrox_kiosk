import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class ReceiptService {
  static Future<void> generateAndPrintReceipt({
    required int receiptNumber,
    required String companyName,
    required double amount,
    required double balance,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'Kiosk HQ Finance',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Receipt #: $receiptNumber'),
              pw.Text('Date: ${DateFormat('MM/dd/yyyy').format(DateTime.now())}'),
              pw.Text('Company: $companyName'),
              pw.SizedBox(height: 20),
              pw.Text('Amount Paid: \$${amount.toStringAsFixed(2)}'),
              pw.Text('Remaining Balance: \$${balance.toStringAsFixed(2)}'),
              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Text('Thank you for your payment!'),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }
} 