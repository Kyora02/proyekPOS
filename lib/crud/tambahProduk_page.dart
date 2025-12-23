import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  List<Map<String, dynamic>> _variants = [];
  final _namaProdukController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _skuController = TextEditingController();
  final _hargaJualController = TextEditingController();
  final _hargaBeliController = TextEditingController();
  final _stokController = TextEditingController();

  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();
  String? _existingImageUrl;

  bool _showInMenu = true;

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
    } finally {
      if (mounted) setState(() => _isFetchingData = false);
    }
  }

  void _addVariantGroup() {
    setState(() {
      _variants.add({'groupName': '', 'options': ''});
    });
  }

  void _populateFieldsForEdit() {
    final product = widget.product!;
    _namaProdukController.text = product['name'] ?? '';
    _deskripsiController.text = product['description'] ?? '';
    _skuController.text = product['sku'] ?? '';
    _hargaJualController.text = product['sellingPrice']?.toString() ?? '';
    _hargaBeliController.text = product['costPrice']?.toString() ?? '0';
    _stokController.text = product['stok']?.toString() ?? '0';
    _existingImageUrl = product['imageUrl'];
    _showInMenu = product['showInMenu'] ?? true;

    if (product['variants'] != null) {
      _variants = List<Map<String, dynamic>>.from(product['variants']);
    }

    final savedCategoryId = product['categoryId'];
    if (_kategoriOptions.any((cat) => cat['id'] == savedCategoryId)) {
      _selectedKategoriId = savedCategoryId;
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile =
    await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
    }
  }

  Future<void> _saveProduct() async {
    if (_selectedKategoriId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Kategori harus dipilih'),
            backgroundColor: Colors.red),
      );
      return;
    }

    final isFormValid = _formKey.currentState!.validate();
    if (!isFormValid) return;

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> activeOutlet =
      _outletOptions.firstWhere((opt) => opt['id'] == widget.outletId);
      final List<Map<String, dynamic>> outletsToSave = [activeOutlet];

      final sellingPrice = double.tryParse(_hargaJualController.text) ?? 0.0;
      final costPrice = double.tryParse(_hargaBeliController.text);
      final stok = int.tryParse(_stokController.text) ?? 0;

      if (_isEditMode) {
        await _apiService.updateProduct(
          id: widget.product!['id'],
          name: _namaProdukController.text,
          description: _deskripsiController.text,
          sku: _skuController.text,
          sellingPrice: sellingPrice,
          costPrice: costPrice,
          stok: stok,
          variants: _variants,
          categoryId: _selectedKategoriId!,
          outlets: outletsToSave,
          imageFile: _imageFile,
          showInMenu: _showInMenu,
        );
      } else {
        await _apiService.addProduct(
          name: _namaProdukController.text,
          description: _deskripsiController.text,
          sku: _skuController.text,
          sellingPrice: sellingPrice,
          costPrice: costPrice,
          stok: stok,
          categoryId: _selectedKategoriId!,
          outlets: outletsToSave,
          variants: _variants,
          imageFile: _imageFile,
          showInMenu: _showInMenu,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _namaProdukController.dispose();
    _deskripsiController.dispose();
    _skuController.dispose();
    _hargaJualController.dispose();
    _hargaBeliController.dispose();
    _stokController.dispose();
    super.dispose();
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Foto Produk',
            style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickImage,
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _buildImageDisplay(),
          ),
        ),
      ],
    );
  }

  Widget _buildImageDisplay() {
    if (_imageFile != null) {
      if (kIsWeb) {
        return Image.network(_imageFile!.path, fit: BoxFit.cover);
      } else {
        return Image.file(File(_imageFile!.path), fit: BoxFit.cover);
      }
    } else if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
      return Image.network(_existingImageUrl!, fit: BoxFit.cover);
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_upload_outlined,
              size: 40, color: Colors.grey[600]),
          const SizedBox(height: 8),
          Text('Pilih Foto', style: TextStyle(color: Colors.grey[700])),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                        _buildActiveOutletDisplay(),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SwitchListTile(
                            title: const Text(
                              "Tampilkan di Menu",
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15),
                            ),
                            subtitle: const Text(
                              "Produk ini akan muncul di halaman kasir",
                              style: TextStyle(fontSize: 12),
                            ),
                            activeColor: const Color(0xFF00A3A3),
                            value: _showInMenu,
                            onChanged: (bool value) {
                              setState(() {
                                _showInMenu = value;
                              });
                            },
                          ),
                        ),
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
                          'Contoh: Perpaduan kopi...',
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
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _stokController,
                          label: 'Stok Produk',
                          hint: '0',
                          keyboardType: TextInputType.number,
                          isRequired: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildVariantSection(),
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
                                color: Colors.white, strokeWidth: 2))
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
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(
            _isFetchingData ? 'Memuat outlet...' : _activeOutletName,
            style: const TextStyle(color: Colors.black54, fontSize: 16),
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
            Text(title,
                style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
    ValueChanged<String>? onChanged,
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
                borderSide: BorderSide(color: Colors.grey[300]!)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!)),
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
          dropdownColor: Colors.white,
          hint: Text(hint, style: TextStyle(color: Colors.grey[600])),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!)),
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

  Widget _buildVariantSection() {
    return _buildSectionCard(
      title: 'Konfigurasi Varian (Add-ons)',
      child: Column(
        children: [
          ..._variants.asMap().entries.map((entry) {
            int index = entry.key;
            Map<String, dynamic> variant = entry.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Nama Grup', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        TextFormField(
                          initialValue: variant['groupName'] ?? '',
                          decoration: InputDecoration(
                            hintText: 'Misal: Level Es',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                          onChanged: (value) {
                            _variants[index]['groupName'] = value;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Opsi', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        TextFormField(
                          initialValue: variant['options'] ?? '',
                          decoration: InputDecoration(
                            hintText: 'Normal, Less, No',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                          onChanged: (value) {
                            _variants[index]['options'] = value;
                          },
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => setState(() => _variants.removeAt(index)),
                  ),
                ],
              ),
            );
          }).toList(),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _addVariantGroup,
            icon: const Icon(Icons.add),
            label: const Text('Tambah Grup Varian'),
          ),
        ],
      ),
    );
  }
}