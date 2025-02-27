import 'package:flutter/material.dart';
import 'invoice.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class InvoiceTemplate {
  final String name;
  final String companyName;
  final String companyAddress;
  final String notes;
  final TextStyle? headerStyle;
  final TextStyle? bodyStyle;
  final TextStyle? footerStyle;

  InvoiceTemplate({
    required this.name,
    required this.companyName,
    required this.companyAddress,
    this.notes = '',
    this.headerStyle,
    this.bodyStyle,
    this.footerStyle,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'companyName': companyName,
      'companyAddress': companyAddress,
      'notes': notes,
      'headerStyle': headerStyle != null
          ? {
              'fontSize': headerStyle!.fontSize,
              'fontWeight': headerStyle!.fontWeight?.index,
              'color': headerStyle!.color?.value,
            }
          : null,
      // Similar for bodyStyle and footerStyle
    };
  }

  static TextStyle? _styleFromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return TextStyle(
      fontSize: json['fontSize'],
      fontWeight: json['fontWeight'] != null
          ? FontWeight.values[json['fontWeight']]
          : null,
      color: json['color'] != null ? Color(json['color']) : null,
    );
  }

  factory InvoiceTemplate.fromJson(Map<String, dynamic> json) {
    return InvoiceTemplate(
      name: json['name'],
      companyName: json['companyName'],
      companyAddress: json['companyAddress'],
      notes: json['notes'],
      headerStyle: _styleFromJson(json['headerStyle']),
      bodyStyle: _styleFromJson(json['bodyStyle']),
      footerStyle: _styleFromJson(json['footerStyle']),
    );
  }

  static Future<void> saveTemplate(InvoiceTemplate template) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/templates/${template.name}.json');
    await file.create(recursive: true);
    await file.writeAsString(jsonEncode(template.toJson()));
  }

  static Future<List<InvoiceTemplate>> loadTemplates() async {
    final directory = await getApplicationDocumentsDirectory();
    final templateDir = Directory('${directory.path}/templates');
    if (!await templateDir.exists()) {
      return [];
    }

    final templates = <InvoiceTemplate>[];
    await for (final file in templateDir.list()) {
      if (file is File && file.path.endsWith('.json')) {
        final jsonString = await file.readAsString();
        templates.add(InvoiceTemplate.fromJson(jsonDecode(jsonString)));
      }
    }
    return templates;
  }
} 