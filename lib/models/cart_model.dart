class CartItem {
  final String id;
  final String name;
  final double price;
  final String? imageUrl;
  int quantity;
  final String note;
  final Map<String, String> selectedVariants;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    this.imageUrl,
    this.quantity = 1,
    this.note = '',
    this.selectedVariants = const {},
  });

  double get total => price * quantity;
}