import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:proyekpos2/bloc/cart/cart_bloc.dart';
import 'package:proyekpos2/bloc/menu/menu_bloc.dart';
import 'package:proyekpos2/service/api_service.dart';

final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

class SelfOrderPage extends StatefulWidget {
  const SelfOrderPage({super.key});

  @override
  State<SelfOrderPage> createState() => _SelfOrderPageState();
}

class _SelfOrderPageState extends State<SelfOrderPage> {
  String? outletId;
  String? tableId;
  String? tableNumber;

  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 1. Ambil Parameter dari URL Browser
    // Contoh URL: http://domain.com/self-order?outletId=123&tableId=456&tableNumber=12
    final uri = Uri.base;
    outletId = uri.queryParameters['outletId'];
    tableId = uri.queryParameters['tableId'];
    tableNumber = uri.queryParameters['tableNumber'];

    // 2. Panggil MenuBloc jika outletId ada
    if (outletId != null) {
      context.read<MenuBloc>().add(FetchMenu(outletId!));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Jika dibuka tanpa scan QR yang valid
    if (outletId == null || tableId == null) {
      return const Scaffold(
        body: Center(child: Text("QR Code tidak valid atau URL salah.")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: BlocBuilder<MenuBloc, MenuState>(
        builder: (context, state) {
          if (state is MenuLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is MenuError) {
            return Center(child: Text("Error: ${state.message}"));
          } else if (state is MenuLoaded) {
            return _buildContent(context, state);
          }
          return const SizedBox();
        },
      ),
      // Tombol Keranjang Melayang di Bawah
      bottomNavigationBar: _buildBottomCartBar(context),
    );
  }

  Widget _buildContent(BuildContext context, MenuLoaded state) {
    return CustomScrollView(
      slivers: [
        // Header Restoran & Meja
        SliverAppBar(
          expandedHeight: 120.0,
          floating: false,
          pinned: true,
          backgroundColor: Colors.white,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
            title: Text(
              state.outletName,
              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
            ),
            background: Container(
              color: Colors.teal[50],
              padding: const EdgeInsets.fromLTRB(16, 40, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.table_restaurant, color: Colors.teal),
                  const SizedBox(width: 8),
                  Text("Meja No. $tableNumber",
                      style: const TextStyle(fontSize: 14, color: Colors.teal)),
                ],
              ),
            ),
          ),
        ),

        // Kategori Selector
        SliverToBoxAdapter(
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 10),
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: state.categories.length + 1, // +1 untuk "Semua"
              itemBuilder: (context, index) {
                if (index == 0) {
                  // Tombol "Semua"
                  final isSelected = state.selectedCategoryId == 'all';
                  return _buildCategoryChip(
                    label: 'Semua',
                    isSelected: isSelected,
                    onTap: () => context.read<MenuBloc>().add(FilterMenuByCategory('all')),
                  );
                }
                final category = state.categories[index - 1];
                final isSelected = state.selectedCategoryId == category['id'];
                return _buildCategoryChip(
                  label: category['name'],
                  isSelected: isSelected,
                  onTap: () => context.read<MenuBloc>().add(FilterMenuByCategory(category['id'])),
                );
              },
            ),
          ),
        ),

        // Daftar Produk Grid
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200, // Responsive grid
              childAspectRatio: 0.75,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final product = state.filteredProducts[index];
                return _buildProductCard(context, product);
              },
              childCount: state.filteredProducts.length,
            ),
          ),
        ),

        // Spacer agar konten tidak tertutup bottom bar
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  Widget _buildCategoryChip({required String label, required bool isSelected, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: Colors.teal,
        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
        backgroundColor: Colors.grey[200],
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, dynamic product) {
    return GestureDetector(
      onTap: () {
        _showProductDetail(context, product);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar Produk
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  image: product['imageUrl'] != null && product['imageUrl'] != ''
                      ? DecorationImage(
                      image: NetworkImage(product['imageUrl']), fit: BoxFit.cover)
                      : null,
                ),
                child: product['imageUrl'] == null || product['imageUrl'] == ''
                    ? const Icon(Icons.fastfood, color: Colors.grey, size: 40)
                    : null,
              ),
            ),
            // Info Produk
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormatter.format(product['sellingPrice']),
                    style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            // Tombol Add (Kecil)
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.teal,
                  radius: 14,
                  child: const Icon(Icons.add, color: Colors.white, size: 16),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBottomCartBar(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, state) {
        if (state.totalItems == 0) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -2))],
          ),
          child: SafeArea(
            child: Row(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${state.totalItems} Item", style: const TextStyle(color: Colors.grey)),
                    Text(
                      currencyFormatter.format(state.totalAmount),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _showCartModal(context),
                  icon: const Icon(Icons.shopping_cart_checkout),
                  label: const Text("Lihat Pesanan"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }


  void _showProductDetail(BuildContext context, dynamic product) {
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Gambar Header
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  image: product['imageUrl'] != null && product['imageUrl'] != ''
                      ? DecorationImage(
                      image: NetworkImage(product['imageUrl']), fit: BoxFit.cover)
                      : null,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product['name'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(currencyFormatter.format(product['sellingPrice']),
                        style: const TextStyle(fontSize: 18, color: Colors.teal, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    const Text("Catatan Pesanan (Opsional)", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: noteController,
                      decoration: InputDecoration(
                        hintText: "Contoh: Jangan pedas, es dikit...",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                        ),
                        onPressed: () {
                          context.read<CartBloc>().add(AddCartItem(
                            product: product,
                            note: noteController.text,
                          ));
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Masuk keranjang"), duration: Duration(seconds: 1)),
                          );
                        },
                        child: const Text("Tambah ke Pesanan", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCartModal(BuildContext parentContext) {
    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return BlocProvider.value(
          value: parentContext.read<CartBloc>(),
          child: BlocBuilder<CartBloc, CartState>(
            builder: (context, state) {
              return FractionallySizedBox(
                heightFactor: 0.9,
                child: Column(
                  children: [
                    AppBar(
                      title: const Text("Konfirmasi Pesanan"),
                      centerTitle: true,
                      automaticallyImplyLeading: false,
                      actions: [
                        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))
                      ],
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      elevation: 0,
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: state.items.length,
                        itemBuilder: (context, index) {
                          final item = state.items[index];
                          return ListTile(
                            leading: Container(
                              width: 50, height: 50,
                              decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                  image: item.imageUrl != null
                                      ? DecorationImage(image: NetworkImage(item.imageUrl!), fit: BoxFit.cover)
                                      : null
                              ),
                            ),
                            title: Text(item.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (item.note.isNotEmpty) Text("Catatan: ${item.note}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                Text(currencyFormatter.format(item.price)),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () => context.read<CartBloc>().add(
                                      UpdateCartItemQuantity(productId: item.id, note: item.note, change: -1)
                                  ),
                                ),
                                Text("${item.quantity}"),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, color: Colors.teal),
                                  onPressed: () => context.read<CartBloc>().add(
                                      UpdateCartItemQuantity(productId: item.id, note: item.note, change: 1)
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))]
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                                labelText: "Nama Pemesan",
                                border: OutlineInputBorder(),
                                hintText: "Masukkan nama Anda"
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Total Bayar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              Text(currencyFormatter.format(state.totalAmount), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                              ),
                              onPressed: state.items.isEmpty
                                  ? null
                                  : () => _submitOrder(parentContext, state),
                              child: const Text("Pesan Sekarang", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _submitOrder(BuildContext context, CartState state) async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mohon isi nama pemesan")));
      return;
    }

    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

    try {
      final itemsMap = state.items.map((e) => {
        'id': e.id,
        'name': e.name,
        'quantity': e.quantity,
        'price': e.price,
        'total': e.total,
        'note': e.note
      }).toList();

      await ApiService().submitSelfOrder(
          outletId: outletId!,
          tableId: tableId!,
          tableNumber: tableNumber ?? '-',
          customerName: _nameController.text,
          items: itemsMap,
          totalAmount: state.totalAmount
      );

      if (mounted) {
        Navigator.pop(context);
        Navigator.pop(context);
        context.read<CartBloc>().add(ClearCart());

        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => AlertDialog(
              title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
              content: const Text("Pesanan berhasil dikirim ke dapur! Mohon tunggu pesanan Anda.", textAlign: TextAlign.center),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))
              ],
            )
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Tutup Loading
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e"), backgroundColor: Colors.red));
      }
    }
  }
}