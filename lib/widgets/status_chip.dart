import 'package:flutter/material.dart';

Widget buildStatusChip(String status) {
  Color color;
  switch (status.toLowerCase()) {
    case 'delivered':
      color = Colors.green;
      break;
    case 'pending':
      color = Colors.orange;
      break;
    case 'received':
      color = Colors.blue;
      break;
    default:
      color = Colors.grey;
  }

  return Chip(
    label: Text(
      status,
      style: const TextStyle(color: Colors.white, fontSize: 12),
    ),
    backgroundColor: color,
    padding: const EdgeInsets.symmetric(horizontal: 8),
  );
} 