import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

abstract class MenuEvent {}

class FetchMenu extends MenuEvent {
  final String outletId;
  FetchMenu(this.outletId);
}

class FilterMenuByCategory extends MenuEvent {
  final String categoryId;
  FilterMenuByCategory(this.categoryId);
}

abstract class MenuState {}

class MenuInitial extends MenuState {}

class MenuLoading extends MenuState {}

class MenuLoaded extends MenuState {
  final String outletName;
  final List<dynamic> categories;
  final List<dynamic> allProducts;
  final List<dynamic> filteredProducts;
  final String selectedCategoryId;

  MenuLoaded({
    required this.outletName,
    required this.categories,
    required this.allProducts,
    required this.filteredProducts,
    this.selectedCategoryId = 'all',
  });

  MenuLoaded copyWith({
    String? selectedCategoryId,
    List<dynamic>? filteredProducts,
  }) {
    return MenuLoaded(
      outletName: outletName,
      categories: categories,
      allProducts: allProducts,
      filteredProducts: filteredProducts ?? this.filteredProducts,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
    );
  }
}

class MenuError extends MenuState {
  final String message;
  MenuError(this.message);
}

class MenuBloc extends Bloc<MenuEvent, MenuState> {
  MenuBloc() : super(MenuInitial()) {
    on<FetchMenu>(_onFetchMenu);
    on<FilterMenuByCategory>(_onFilterCategory);
  }

  Future<void> _onFetchMenu(FetchMenu event, Emitter<MenuState> emit) async {
    emit(MenuLoading());
    try {
      final baseUrl = "http://localhost:3000";

      final responses = await Future.wait([
        http.get(Uri.parse('$baseUrl/public/outlet/${event.outletId}')),
        http.get(Uri.parse('$baseUrl/public/menu/${event.outletId}')),
      ]);

      final outletRes = responses[0];
      final menuRes = responses[1];

      if (outletRes.statusCode != 200 || menuRes.statusCode != 200) {
        throw Exception("Failed to load menu data");
      }

      final outletData = json.decode(outletRes.body);
      final menuData = json.decode(menuRes.body);

      emit(MenuLoaded(
        outletName: outletData['name'] ?? 'Restoran',
        categories: menuData['categories'] ?? [],
        allProducts: menuData['products'] ?? [],
        filteredProducts: menuData['products'] ?? [],
      ));
    } catch (e) {
      emit(MenuError(e.toString()));
    }
  }

  void _onFilterCategory(FilterMenuByCategory event, Emitter<MenuState> emit) {
    if (state is MenuLoaded) {
      final currentState = state as MenuLoaded;
      final filtered = event.categoryId == 'all'
          ? currentState.allProducts
          : currentState.allProducts
          .where((p) => p['categoryId'] == event.categoryId)
          .toList();

      emit(currentState.copyWith(
        selectedCategoryId: event.categoryId,
        filteredProducts: filtered,
      ));
    }
  }
}