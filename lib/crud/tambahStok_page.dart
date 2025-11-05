import 'package:flutter/material.dart';
import 'package:proyekpos2/service/api_service.dart';

class TambahStokPage extends StatefulWidget {
  final String outletId;
  final Map<String, dynamic>? s; // <-- ADDED: Untuk menerima data stok saat edit

  const TambahStokPage({
    super.key,
    required this.outletId,
    this.s, // <-- ADDED
  });

  @override
  State<TambahStokPage> createState() => _TambahStokPageState();
}

class _TambahStokPageState extends State<TambahStokPage> {
  final _formKey = GlobalKey<FormState>();

  final ApiService _apiService = ApiService();

  final TextEditingController _skuController = TextEditingController();
  final TextEditingController _stokController = TextEditingController();

  List<Map<String, dynamic>> _products = [];
  Map<String, dynamic>? _selectedProduct;

  bool _isProductLoading = true; // <-- MODIFIED: Start as true
  bool _isSaving = false;
  bool _isEditMode = false; // <-- ADDED
  String? _productIdToEdit; // <-- ADDED

  @override
  void initState() {
    super.initState();

    // <-- MODIFIED: Logic to handle Edit vs Add mode
    if (widget.s != null) {
      // ** EDIT MODE **
      setState(() {
        _isEditMode = true;
        _productIdToEdit = widget.s!['id']; // Asumsi 'id' adalah productId
        _skuController.text = widget.s!['sku'] ?? '';
        _stokController.text = widget.s!['stok']?.toString() ?? '';

        // Buat item placeholder untuk ditampilkan di dropdown
        _selectedProduct = {
          'id': widget.s!['id'],
          'name': widget.s!['name'],
          'sku': widget.s!['sku'],
        };
        // Masukkan ke list agar dropdown valid
        _products = [_selectedProduct!];
        _isProductLoading = false; // Selesai loading
      });
    } else {
      // ** ADD MODE **
      _fetchProducts(widget.outletId);
    }
  }

  @override
  void dispose() {
    _skuController.dispose();
    _stokController.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts(String outletId) async {
    // State loading sudah di-set di initState atau logic sebelumnya
    setState(() {
      _isProductLoading = true;
      _products = [];
      _selectedProduct = null;
      _skuController.text = "";
    });

    try {
      final List<Map<String, dynamic>> data =
      await _apiService.getStockProducts(outletId);
      setState(() {
        _products = data;
        _isProductLoading = false;
      });
    } catch (e) {
      setState(() {
        _isProductLoading = false;
      });
      _showErrorSnackbar("Terjadi kesalahan: $e");
    }
  }

  Future<void> _simpanStok() async {
    if (_formKey.currentState!.validate() && !_isSaving) {
      setState(() {
        _isSaving = true;
      });

      try {
        if (_isEditMode) {
          await _apiService.updateStock(
            outletId: widget.outletId,
            productId: _productIdToEdit!,
            newStock: _stokController.text,
          );
        } else {
          // ** PANGGIL API ADD STOK (YANG SUDAH ADA) **
          await _apiService.addStock(
            outletId: widget.outletId,
            productId: _selectedProduct!['id'],
            stokToAdd: _stokController.text,
          );
        }

        if (mounted) {
          // Kirim 'true' untuk memberi tahu DaftarStokPage agar refresh
          Navigator.of(context).pop(true); // <-- MODIFIED
        }
      } catch (e) {
        _showErrorSnackbar("Terjadi kesalahan: $e");
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        title: Text(
          // <-- MODIFIED: Title berubah sesuai mode
          _isEditMode ? 'Ubah Stok' : 'Tambahkan Stok',
          style: const TextStyle(
            color: Color(0xFF333333),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF828282)),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Container(
            width: 550,
            padding: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informasi Stok',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildDropdownField<Map<String, dynamic>>(
                    label: 'Pilih Produk',
                    hint:
                    _isProductLoading ? "Memuat produk..." : "Pilih Produk",
                    value: _selectedProduct,
                    items: _products.map((product) {
                      return DropdownMenuItem<Map<String, dynamic>>(
                        value: product,
                        // Pastikan 'name' di-cast sebagai String
                        child: Text(product['name']?.toString() ?? 'Nama Tidak Ada'),
                      );
                    }).toList(),
                    // <-- MODIFIED: Nonaktifkan dropdown jika loading atau edit mode
                    onChanged: (_isProductLoading || _isEditMode)
                        ? null
                        : (Map<String, dynamic>? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedProduct = newValue;
                          _skuController.text = newValue['sku'] ?? '';
                        });
                      }
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Produk harus dipilih';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _skuController,
                    label: 'SKU',
                    hint: 'SKU akan terisi otomatis',
                    readOnly: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'SKU tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _stokController,
                    // <-- MODIFIED: Label berubah sesuai mode
                    label: _isEditMode
                        ? 'Stok (Nilai Baru)'
                        : 'Jumlah Stok (Akan Ditambahkan)',
                    hint: _isEditMode ? 'Contoh: 25' : 'Contoh: 50',
                    keyboardType: TextInputType.number,
                    // <-- MODIFIED: Validator lebih fleksibel untuk edit mode
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Stok tidak boleh kosong';
                      }
                      final n = int.tryParse(value);
                      if (n == null) {
                        return 'Stok harus berupa angka';
                      }
                      if (!_isEditMode && n <= 0) {
                        return 'Stok (penambahan) harus lebih dari 0';
                      }
                      if (_isEditMode && n < 0) {
                        return 'Stok tidak boleh negatif';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _simpanStok,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF279E9E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 16),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : Text(
                        // <-- MODIFIED: Teks tombol berubah
                        _isEditMode ? 'Update Stok' : 'Simpan',
                        style:
                        const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required String hint,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
    FormFieldValidator<T>? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label *',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          hint: Text(hint, style: const TextStyle(color: Color(0xFFBDBDBD))),
          items: items,
          onChanged: onChanged,
          validator: validator,
          decoration: InputDecoration(
            filled: true,
            // <-- MODIFIED: Warna abu-abu jika nonaktif
            fillColor:
            onChanged == null ? const Color(0xFFF5F5F5) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF279E9E), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            // <-- ADDED: Border khusus untuk state disabled
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFF0F0F0)),
            ),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    FormFieldValidator<String>? validator,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label *',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          readOnly: readOnly,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFBDBDBD)),
            filled: true,
            fillColor: readOnly ? const Color(0xFFF5F5F5) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF279E9E), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            // <-- ADDED: Border khusus untuk state readOnly/disabled
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFF0F0F0)),
            ),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}