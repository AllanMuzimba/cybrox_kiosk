import 'dart:io';
import 'package:sunmi_printer_plus/core/sunmi/sunmi_printer.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PrinterService {
  static Future<void> printDocument({
    required String title,
    required Map<String, dynamic> data,
    required bool isInvoice,
  }) async {
    try {
      if (Platform.isAndroid) {
        await _printOnSunmi(title: title, data: data);
      } else {
        await _printPDF(title: title, data: data);
      }
    } catch (e) {
      throw Exception('Error printing: $e');
    }
  }

  static Future<void> _printOnSunmi({
    required String title,
    required Map<String, dynamic> data,
  }) async {
    await SunmiPrinter.startTransactionPrint(true);
    
    await SunmiPrinter.printText('Kiosk HQ Office\n');
    await SunmiPrinter.lineWrap(2);
    
    await SunmiPrinter.printText('$title\n');
    await SunmiPrinter.lineWrap(2);

    for (var entry in data.entries) {
      await SunmiPrinter.printText('${entry.key}: ${entry.value}\n');
    }
    
    await SunmiPrinter.lineWrap(3);
    await SunmiPrinter.printText(
      'Kiosk Management System\npowered by Cybrox-AllanWebApp\n'
    );
    await SunmiPrinter.lineWrap(1);
    await SunmiPrinter.cut();
  }

  static Future<void> _printPDF({
    required String title,
    required Map<String, dynamic> data,
  }) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('Kiosk HQ Office', 
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)
              ),
              pw.SizedBox(height: 20),
              pw.Text(title,
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)
              ),
              pw.SizedBox(height: 20),
              ...data.entries.map((entry) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                child: pw.Text('${entry.key}: ${entry.value}'),
              )),
              pw.SizedBox(height: 30),
              pw.Text(
                'Kiosk Management System\npowered by Cybrox-AllanWebApp',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
      name: '${title.toLowerCase().replaceAll(' ', '_')}.pdf',
      usePrinterSettings: true,
    );
  }
} 