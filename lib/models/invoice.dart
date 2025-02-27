import 'package:flutter/material.dart';

class InvoiceItem {
  String description;
  double quantity;
  double unitPrice;
  double taxRate; // 0.15, 0.10, or 0.0
  String? itemNumber;

  InvoiceItem({
    this.description = '',
    this.quantity = 0,
    this.unitPrice = 0,
    this.taxRate = 0,
    this.itemNumber,
  });

  double get subtotal => quantity * unitPrice;
  double get taxAmount => subtotal * taxRate;
  double get total => subtotal + taxAmount;

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'taxRate': taxRate,
      'itemNumber': itemNumber,
    };
  }

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      description: json['description'],
      quantity: json['quantity'],
      unitPrice: json['unitPrice'],
      taxRate: json['taxRate'],
      itemNumber: json['itemNumber'],
    );
  }
}

class Invoice {
  String invoiceNumber;
  DateTime date;
  String companyName;
  String companyAddress;
  String companyContactPerson;
  String companyContactNumber;
  String billTo;
  String billToAddress;
  String billToContactPerson;
  String billToContactNumber;
  String shipTo;
  String shipToAddress;
  List<InvoiceItem> items;
  String notes;
  TextStyle? customFont;
  String? phoneNumber;
  String? terms;

  Invoice({
    required this.invoiceNumber,
    required this.date,
    this.companyName = '',
    this.companyAddress = '',
    this.companyContactPerson = '',
    this.companyContactNumber = '',
    this.billTo = '',
    this.billToAddress = '',
    this.billToContactPerson = '',
    this.billToContactNumber = '',
    this.shipTo = '',
    this.shipToAddress = '',
    List<InvoiceItem>? items,
    this.notes = '',
    this.customFont,
    this.phoneNumber,
    this.terms,
  }) : items = items ?? [];

  double get subtotal => items.fold(0, (sum, item) => sum + item.subtotal);
  double get taxTotal => items.fold(0, (sum, item) => sum + item.taxAmount);
  double get total => subtotal + taxTotal;

  Map<String, dynamic> toJson() {
    return {
      'invoiceNumber': invoiceNumber,
      'date': date.toIso8601String(),
      'companyName': companyName,
      'companyAddress': companyAddress,
      'companyContactPerson': companyContactPerson,
      'companyContactNumber': companyContactNumber,
      'billTo': billTo,
      'billToAddress': billToAddress,
      'billToContactPerson': billToContactPerson,
      'billToContactNumber': billToContactNumber,
      'shipTo': shipTo,
      'shipToAddress': shipToAddress,
      'items': items.map((item) => item.toJson()).toList(),
      'notes': notes,
      'phoneNumber': phoneNumber,
      'terms': terms,
    };
  }

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      invoiceNumber: json['invoiceNumber'],
      date: DateTime.parse(json['date']),
      companyName: json['companyName'],
      companyAddress: json['companyAddress'],
      companyContactPerson: json['companyContactPerson'] ?? '',
      companyContactNumber: json['companyContactNumber'] ?? '',
      billTo: json['billTo'],
      billToAddress: json['billToAddress'],
      billToContactPerson: json['billToContactPerson'] ?? '',
      billToContactNumber: json['billToContactNumber'] ?? '',
      shipTo: json['shipTo'],
      shipToAddress: json['shipToAddress'],
      items: (json['items'] as List)
          .map((item) => InvoiceItem.fromJson(item))
          .toList(),
      notes: json['notes'],
      phoneNumber: json['phoneNumber'],
      terms: json['terms'],
    );
  }
}