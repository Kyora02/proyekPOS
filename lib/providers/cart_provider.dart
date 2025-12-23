import 'package:flutter/material.dart';
import 'package:proyekpos2/models/cart_model.dart';

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalAmount => _items.fold(0, (sum, item) => sum + item.total);

  // void addItem(String id, String name, double price, String? imageUrl, {String note = ''}) {
  //   final existingIndex = _items.indexWhere((item) => item.id == id && item.note == note);
  //
  //   if (existingIndex >= 0) {
  //     _items[existingIndex].quantity += 1;
  //   } else {
  //     _items.add(CartItem(
  //       id: id,
  //       name: name,
  //       price: price,
  //       imageUrl: imageUrl,
  //       note: note,
  //     ));
  //   }
  //   notifyListeners();
  // }

  void addItem(String id, String name, double price, String? imageUrl,
      {String note = '', Map<String, String> variants = const {}}) {

    final existingIndex = _items.indexWhere((item) =>
    item.id == id &&
        item.note == note &&
        item.selectedVariants.toString() == variants.toString()
    );

    if (existingIndex >= 0) {
      _items[existingIndex].quantity += 1;
    } else {
      _items.add(CartItem(
        id: id,
        name: name,
        price: price,
        imageUrl: imageUrl,
        note: note,
        selectedVariants: variants,
      ));
    }
    notifyListeners();
  }

  void removeItem(String id, {String note = ''}) {
    final existingIndex = _items.indexWhere((item) => item.id == id && item.note == note);
    if (existingIndex >= 0) {
      if (_items[existingIndex].quantity > 1) {
        _items[existingIndex].quantity -= 1;
      } else {
        _items.removeAt(existingIndex);
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}