import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:proyekpos2/bloc/cart/cart_bloc.dart';
import 'package:proyekpos2/bloc/menu/menu_bloc.dart';
import 'package:proyekpos2/service/api_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:proyekpos2/payment/payment_webview_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

class SelfOrderPage extends StatefulWidget {
  final String? outletId;
  final String? tableId;
  final String? tableNumber;

  const SelfOrderPage({
    super.key,
    this.outletId,
    this.tableId,
    this.tableNumber
  });

  @override
  State<SelfOrderPage> createState() => _SelfOrderPageState();
}

class _SelfOrderPageState extends State<SelfOrderPage> {
  final TextEditingController _nameController = TextEditingController();
  String _selectedPaymentType = 'Online';

  @override
  void initState() {
    super.initState();
    if (widget.outletId != null) {
      context.read<MenuBloc>().add(FetchMenu(widget.outletId!));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.outletId == null || widget.tableId == null) {
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
      bottomNavigationBar: _buildBottomCartBar(context),
    );
  }

  Widget _buildContent(BuildContext context, MenuLoaded state) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          automaticallyImplyLeading: false,
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
                  Text("Meja No. ${widget.tableNumber}",
                      style: const TextStyle(fontSize: 14, color: Colors.teal)),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 10),
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: state.categories.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
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
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
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
    List<dynamic> variantsList = [];
    var variantsRaw = product['variants'];
    if (variantsRaw is List) {
      variantsList = variantsRaw;
    } else if (variantsRaw is String && variantsRaw.isNotEmpty) {
      try {
        variantsList = json.decode(variantsRaw);
      } catch (e) {
        variantsList = [];
      }
    }

    return GestureDetector(
      onTap: () => _showProductDetail(context, product),
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
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: GestureDetector(
                  onTap: () {
                    if (variantsList.isNotEmpty) {
                      _showProductDetail(context, product);
                    } else {
                      context.read<CartBloc>().add(AddCartItem(
                        product: product,
                        note: '',
                        variants: {},
                      ));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Masuk keranjang"), duration: Duration(seconds: 1)),
                      );
                    }
                  },
                  child: CircleAvatar(
                    backgroundColor: Colors.teal,
                    radius: 14,
                    child: Icon(
                      variantsList.isNotEmpty ? Icons.arrow_forward : Icons.add,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
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
    Map<String, String> selectedVariants = {};

    List<dynamic> variantsList = [];
    var variantsRaw = product['variants'];

    if (variantsRaw is List) {
      variantsList = variantsRaw;
    } else if (variantsRaw is String && variantsRaw.isNotEmpty) {
      try {
        variantsList = json.decode(variantsRaw);
      } catch (e) {
        variantsList = [];
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        image: product['imageUrl'] != null && product['imageUrl'] != ''
                            ? DecorationImage(image: NetworkImage(product['imageUrl']), fit: BoxFit.cover)
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

                          ...variantsList.map((group) {
                            if (group == null || group['groupName'] == null) return const SizedBox.shrink();

                            String groupName = group['groupName'].toString();
                            String optionsStr = (group['options'] ?? '').toString();
                            List<String> options = optionsStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

                            if (options.isEmpty) return const SizedBox.shrink();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(groupName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: options.map((opt) {
                                    bool isSelected = selectedVariants[groupName] == opt;
                                    return ChoiceChip(
                                      label: Text(opt),
                                      selected: isSelected,
                                      selectedColor: Colors.teal.withOpacity(0.2),
                                      onSelected: (val) {
                                        setModalState(() {
                                          selectedVariants[groupName] = opt;
                                        });
                                      },
                                      labelStyle: TextStyle(
                                        color: isSelected ? Colors.teal : Colors.black87,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 16),
                              ],
                            );
                          }).toList(),

                          const Text("Catatan Pesanan", style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: noteController,
                            decoration: InputDecoration(
                              hintText: "",
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
                                for (var group in variantsList) {
                                  if (group != null && group['groupName'] != null) {
                                    String groupName = group['groupName'].toString();
                                    if (!selectedVariants.containsKey(groupName)) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text("Silakan pilih $groupName terlebih dahulu")),
                                      );
                                      return;
                                    }
                                  }
                                }

                                context.read<CartBloc>().add(AddCartItem(
                                  product: product,
                                  note: noteController.text,
                                  variants: selectedVariants,
                                ));
                                Navigator.pop(context);
                              },
                              child: const Text("Tambah ke Pesanan", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
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
          child: StatefulBuilder(
              builder: (context, setModalState) {
                return BlocBuilder<CartBloc, CartState>(
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
                                    width: 50,
                                    height: 50,
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
                                      if (item.selectedVariants.isNotEmpty) ...[
                                        ...item.selectedVariants.entries.map((e) =>
                                            Text("• ${e.key}: ${e.value}", style: const TextStyle(fontSize: 11, color: Colors.grey))
                                        ),
                                      ],
                                      if (item.note.isNotEmpty)
                                        Text("Catatan: ${item.note}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
                                    const Text("Total Pesanan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                                        : () => _submitOrder(parentContext, state), // Langsung panggil submit
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
                );
              }
          ),
        );
      },
    );
  }

  Future<void> _submitOrder(BuildContext context, CartState state) async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mohon isi nama Anda")));
      return;
    }

    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

    try {
      final itemsMap = state.items.map((e) => {
        'id': e.id,
        'name': e.name,
        'quantity': e.quantity,
        'sellingPrice': e.price,
        'total': e.total,
        'note': e.note,
        'variants': e.selectedVariants
      }).toList();

      await ApiService().submitSelfOrder(
          outletId: widget.outletId!,
          tableId: widget.tableId!,
          tableNumber: widget.tableNumber ?? '-',
          customerName: _nameController.text,
          items: itemsMap,
          totalAmount: state.totalAmount,
          paymentType: _selectedPaymentType,
      );

      if (mounted) {
        Navigator.pop(context);
        Navigator.pop(context);
        context.read<CartBloc>().add(ClearCart());
        _showOrderSentDialog();
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e"), backgroundColor: Colors.red));
    }
  }

  void _showOrderSentDialog() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Icon(Icons.check_circle_outline, color: Colors.teal, size: 60),
          content: const Text("Pesanan Berhasil Dikirim!\n\nSilakan konfirmasi pembayaran ke kasir setelah selesai makan.", textAlign: TextAlign.center),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))
          ],
        )
    );
  }

  void _showCheckStatusDialog(BuildContext context, String orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text("Menunggu Pembayaran"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  const Text("Silakan selesaikan pembayaran Anda."),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        final status = await ApiService().checkPublicTransactionStatus(orderId);
                        if (status['status'] == 'processing' || status['status'] == 'success') {
                          Navigator.pop(context);
                          context.read<CartBloc>().add(ClearCart());
                          _showSuccessDialog();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pembayaran belum terkonfirmasi/selesai.")));
                        }
                      } catch(e) {
                        print(e);
                      }
                    },
                    child: const Text(" Saya Sudah Bayar"),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSuccessDialog() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
          content: const Text("Pembayaran Berhasil!\nPesanan Anda sedang di proses.", textAlign: TextAlign.center),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))
          ],
        )
    );
  }
}