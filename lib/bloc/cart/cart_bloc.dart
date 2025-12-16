import 'package:flutter_bloc/flutter_bloc.dart';

class CartItem {
  final String id;
  final String name;
  final double price;
  final String? imageUrl;
  final int quantity;
  final String note;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    this.imageUrl,
    this.quantity = 1,
    this.note = '',
  });

  double get total => price * quantity;

  CartItem copyWith({int? quantity}) {
    return CartItem(
      id: id,
      name: name,
      price: price,
      imageUrl: imageUrl,
      quantity: quantity ?? this.quantity,
      note: note,
    );
  }
}

abstract class CartEvent {}

class AddCartItem extends CartEvent {
  final Map<String, dynamic> product;
  final String note;

  AddCartItem({required this.product, this.note = ''});
}

class UpdateCartItemQuantity extends CartEvent {
  final String productId;
  final String note;
  final int change;

  UpdateCartItemQuantity({required this.productId, required this.note, required this.change});
}

class ClearCart extends CartEvent {}

class CartState {
  final List<CartItem> items;

  CartState({this.items = const []});

  double get totalAmount => items.fold(0, (sum, item) => sum + item.total);
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
}

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(CartState()) {
    on<AddCartItem>(_onAddItem);
    on<UpdateCartItemQuantity>(_onUpdateQuantity);
    on<ClearCart>(_onClearCart);
  }

  void _onAddItem(AddCartItem event, Emitter<CartState> emit) {
    final existingIndex = state.items.indexWhere(
            (item) => item.id == event.product['id'] && item.note == event.note
    );

    List<CartItem> updatedList = List.from(state.items);

    if (existingIndex >= 0) {
      final currentItem = updatedList[existingIndex];
      updatedList[existingIndex] = currentItem.copyWith(quantity: currentItem.quantity + 1);
    } else {
      updatedList.add(CartItem(
        id: event.product['id'],
        name: event.product['name'],
        price: (event.product['sellingPrice'] as num).toDouble(),
        imageUrl: event.product['imageUrl'],
        note: event.note,
      ));
    }

    emit(CartState(items: updatedList));
  }

  void _onUpdateQuantity(UpdateCartItemQuantity event, Emitter<CartState> emit) {
    final index = state.items.indexWhere(
            (item) => item.id == event.productId && item.note == event.note
    );

    if (index == -1) return;

    List<CartItem> updatedList = List.from(state.items);
    final currentItem = updatedList[index];
    final newQuantity = currentItem.quantity + event.change;

    if (newQuantity <= 0) {
      updatedList.removeAt(index);
    } else {
      updatedList[index] = currentItem.copyWith(quantity: newQuantity);
    }

    emit(CartState(items: updatedList));
  }

  void _onClearCart(ClearCart event, Emitter<CartState> emit) {
    emit(CartState(items: []));
  }
}