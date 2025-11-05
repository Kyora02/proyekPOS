import 'package:flutter/material.dart';
import 'package:proyekpos2/service/api_service.dart';

class TambahProdukPage extends StatefulWidget {
  final Map<String, dynamic>? product;
  final String outletId;

  const TambahProdukPage({
    super.key,
    this.product,
    required this.outletId,
  });

  @override
  State<TambahProdukPage> createState() => _TambahProdukPageState();
}

class _TambahProdukPageState extends State<TambahProdukPage> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  bool _isLoading = false;
  bool _isFetchingData = true;

  final _namaProdukController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _skuController = TextEditingController();
  final _hargaJualController = TextEditingController();
  final _hargaBeliController = TextEditingController();

  // Hapus semua state yang berhubungan dengan multi-select
  List<Map<String, dynamic>> _outletOptions = [];
  List<Map<String, dynamic>> _kategoriOptions = [];
  String? _selectedKategoriId;
  String _activeOutletName = 'Memuat outlet...';

  bool get _isEditMode => widget.product != null;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isFetchingData = true);
    try {
      final outlets = await _apiService.getOutlets();
      final categories =
      await _apiService.getCategories(outletId: widget.outletId);

      if (mounted) {
        setState(() {
          _outletOptions = outlets;
          _kategoriOptions = categories;

          try {
            _activeOutletName = _outletOptions
                .firstWhere((opt) => opt['id'] == widget.outletId)['name'];
          } catch (e) {
            _activeOutletName = 'Outlet Tidak Ditemukan';
          }

          if (_isEditMode) {
            _populateFieldsForEdit();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to load data: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isFetchingData = false);
      }
    }
  }

  void _populateFieldsForEdit() {
    final product = widget.product!;
    _namaProdukController.text = product['name'] ?? '';
    _deskripsiController.text = product['description'] ?? '';
    _skuController.text = product['sku'] ?? '';
    _hargaJualController.text = product['sellingPrice']?.toString() ?? '';
    _hargaBeliController.text = product['costPrice']?.toString() ?? '0';

    final savedCategoryId = product['categoryId'];
    if (_kategoriOptions.any((cat) => cat['id'] == savedCategoryId)) {
      _selectedKategoriId = savedCategoryId;
    }

  }

  @override
  void dispose() {
    _namaProdukController.dispose();
    _deskripsiController.dispose();
    _skuController.dispose();
    _hargaJualController.dispose();
    _hargaBeliController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    // Hapus validasi _selectedOutlets
    if (_selectedKategoriId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Kategori harus dipilih'), backgroundColor: Colors.red),
      );
      return;
    }

    final isFormValid = _formKey.currentState!.validate();
    if (!isFormValid) return;

    setState(() => _isLoading = true);

    Map<String, dynamic>? activeOutlet;
    try {
      activeOutlet =
          _outletOptions.firstWhere((opt) => opt['id'] == widget.outletId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error: Outlet aktif tidak valid. $e'),
            backgroundColor: Colors.red),
      );
      setState(() => _isLoading = false);
      return;
    }

    // Buat daftar outlet yang akan disimpan (selalu hanya 1)
    final List<Map<String, dynamic>> outletsToSave = [activeOutlet];

    try {
      final sellingPrice = double.tryParse(_hargaJualController.text) ?? 0.0;
      final costPrice = double.tryParse(_hargaBeliController.text);

      if (_isEditMode) {
        await _apiService.updateProduct(
          id: widget.product!['id'],
          name: _namaProdukController.text,
          description: _deskripsiController.text,
          sku: _skuController.text,
          sellingPrice: sellingPrice,
          costPrice: costPrice,
          categoryId: _selectedKategoriId!,
          outlets: outletsToSave,
        );
      } else {
        await _apiService.addProduct(
          name: _namaProdukController.text,
          description: _deskripsiController.text,
          sku: _skuController.text,
          sellingPrice: sellingPrice,
          costPrice: costPrice,
          categoryId: _selectedKategoriId!,
          outlets: outletsToSave,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Product saved successfully!'),
              backgroundColor: Colors.green),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to save product: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    // Hapus GestureDetector
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          _isEditMode ? 'Edit Produk' : 'Tambahkan Produk',
          style: const TextStyle(
            color: Color(0xFF333333),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black87),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: _isFetchingData
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionCard(
                    title: 'Informasi Produk',
                    child: Column(
                      children: [
                        // Selalu tampilkan _buildActiveOutletDisplay
                        _buildActiveOutletDisplay(),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _namaProdukController,
                          label: 'Nama Produk',
                          hint: 'Contoh: Kopi Susu Gula Aren',
                          isRequired: true,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _deskripsiController,
                          label: 'Deskripsi Produk',
                          hint:
                          'Contoh: Perpaduan kopi, susu, dan gula aren',
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        _buildImagePicker(),
                        const SizedBox(height: 16),
                        _buildCategoryDropdownField(
                          label: 'Kategori Produk',
                          value: _selectedKategoriId,
                          items: _kategoriOptions,
                          hint: 'Pilih kategori',
                          onChanged: (value) {
                            setState(() {
                              _selectedKategoriId = value;
                            });
                          },
                          isRequired: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionCard(
                    title: 'Harga dan SKU',
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _skuController,
                          label: 'SKU (Stock Keeping Unit)',
                          hint: 'Contoh: KS-001',
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _hargaBeliController,
                                label: 'Harga Beli',
                                hint: '0',
                                keyboardType: TextInputType.number,
                                prefixText: 'Rp ',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                controller: _hargaJualController,
                                label: 'Harga Jual',
                                hint: '0',
                                isRequired: true,
                                keyboardType: TextInputType.number,
                                prefixText: 'Rp ',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: _isLoading ? null : _saveProduct,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00A3A3),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                          disabledBackgroundColor: Colors.grey,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2))
                            : const Text('Simpan'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget ini sekarang hanya menampilkan nama outlet aktif
  Widget _buildActiveOutletDisplay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Text('Outlet', style: TextStyle(fontWeight: FontWeight.w600)),
            Text(' *', style: TextStyle(color: Colors.red)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[200], // Buat terlihat non-aktif
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(
            _isFetchingData ? 'Memuat outlet...' : _activeOutletName,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Produk akan diatur untuk outlet yang sedang aktif.',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        )
      ],
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Card(
      color: Colors.white,
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isRequired = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? prefixText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            if (isRequired)
              const Text(' *', style: TextStyle(color: Colors.red)),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefixText,
            filled: true,
            fillColor: Colors.white,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          validator: (value) {
            if (isRequired && (value == null || value.isEmpty)) {
              return '$label tidak boleh kosong';
            }
            if (keyboardType == TextInputType.number &&
                value != null &&
                value.isNotEmpty &&
                double.tryParse(value) == null) {
              return 'Masukkan angka yang valid';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCategoryDropdownField({
    required String label,
    required String? value,
    required List<Map<String, dynamic>> items,
    required String hint,
    required ValueChanged<String?> onChanged,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            if (isRequired)
              const Text(' *', style: TextStyle(color: Colors.red)),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          hint: Text(hint, style: TextStyle(color: Colors.grey[600])),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          items: items.map((Map<String, dynamic> item) {
            return DropdownMenuItem<String>(
              value: item['id'],
              child: Text(item['name']),
            );
          }).toList(),
          onChanged: onChanged,
          validator: (value) {
            if (isRequired && value == null) {
              return '$label harus dipilih';
            }
            return null;
          },
        ),
      ],
    );
  }

  // Hapus _buildMultiSelectOutletField

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Foto Produk', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Buka galeri... (fitur belum ada)')),
            );
          },
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_upload_outlined,
                    size: 40, color: Colors.grey[600]),
                const SizedBox(height: 8),
                Text('Pilih atau letakkan berkas di sini',
                    style: TextStyle(color: Colors.grey[700])),
              ],
            ),
          ),
        ),
      ],
    );
  }
}