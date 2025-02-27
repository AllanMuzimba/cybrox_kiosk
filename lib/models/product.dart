class Product {
  final int? id; // Make id nullable
  final String name;
  final String description;
  final double price;
  final String barcode;
  final int stockQuantity;
  final double taxRate;
  final double sellPrice; // New sellPrice field

  Product({
    this.id, // Make id optional
    required this.name,
    required this.description,
    required this.price,
    required this.barcode,
    required this.stockQuantity,
    required this.taxRate,
    required this.sellPrice, // Include sellPrice in the constructor
  });

  double get cost => sellPrice;

  double get totalSellPrice => sellPrice + (sellPrice * taxRate / 100);

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'], // Allow null value
      name: json['name'],
      description: json['description'],
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      barcode: json['barcode'],
      stockQuantity: json['stock_quantity'],
      taxRate: (json['tax_rate'] as num?)?.toDouble() ?? 0.0,
      sellPrice: (json['sell_price'] as num?)?.toDouble() ?? 0.0, // Handle the new sellPrice column
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id, // Only include id if it's not null
      'name': name,
      'description': description,
      'price': price,
      'barcode': barcode,
      'stock_quantity': stockQuantity,
      'tax_rate': taxRate,
      'sell_price': sellPrice, // Include sellPrice in the JSON representation
    };
  }

   // Getter to fetch product name by ID
  static String getProductNameById(int productId, List<Product> products) {
    final product = products.firstWhere(
      (product) => product.id == productId,
      orElse: () => Product(name: '', description: '', price:0, barcode: '', stockQuantity: 0, taxRate: 0, sellPrice: 0),
    );
    return product.name;
  }
}