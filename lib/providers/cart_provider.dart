import 'package:flutter_riverpod/flutter_riverpod.dart';

class CartItem {
  final String id;
  final String name;
  final String provider;
  final double price;
  int quantity;
  final String imageUrl;
  final String semanticLabel;
  final String category;
  final double? weightKg;
  final double? lengthCm;
  final double? widthCm;
  final double? heightCm;

  CartItem({
    required this.id,
    required this.name,
    required this.provider,
    required this.price,
    this.quantity = 1,
    required this.imageUrl,
    required this.semanticLabel,
    required this.category,
    this.weightKg,
    this.lengthCm,
    this.widthCm,
    this.heightCm,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'provider': provider,
    'price': price,
    'quantity': quantity,
    'imageUrl': imageUrl,
    'semanticLabel': semanticLabel,
    'category': category,
    'weightKg': weightKg,
    'lengthCm': lengthCm,
    'widthCm': widthCm,
    'heightCm': heightCm,
  };

  CartItem copyWith({int? quantity}) => CartItem(
    id: id,
    name: name,
    provider: provider,
    price: price,
    quantity: quantity ?? this.quantity,
    imageUrl: imageUrl,
    semanticLabel: semanticLabel,
    category: category,
    weightKg: weightKg,
    lengthCm: lengthCm,
    widthCm: widthCm,
    heightCm: heightCm,
  );
}

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addItem(CartItem item) {
    final existingIndex = state.indexWhere((e) => e.id == item.id);
    if (existingIndex >= 0) {
      final updated = List<CartItem>.from(state);
      updated[existingIndex] = updated[existingIndex].copyWith(
        quantity: updated[existingIndex].quantity + item.quantity,
      );
      state = updated;
    } else {
      state = [...state, item];
    }
  }

  void removeItem(String id) {
    state = state.where((e) => e.id != id).toList();
  }

  void updateQuantity(String id, int delta) {
    final updated = List<CartItem>.from(state);
    final idx = updated.indexWhere((e) => e.id == id);
    if (idx >= 0) {
      final newQty = updated[idx].quantity + delta;
      if (newQty <= 0) {
        updated.removeAt(idx);
      } else {
        updated[idx] = updated[idx].copyWith(quantity: newQty);
      }
      state = updated;
    }
  }

  void clearCart() {
    state = [];
  }

  int get totalCount => state.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal =>
      state.fold(0, (sum, item) => sum + item.price * item.quantity);
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});

final cartCountProvider = Provider<int>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0, (sum, item) => sum + item.quantity);
});
