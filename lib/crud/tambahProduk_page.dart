import 'package:flutter/material.dart';
import 'package:proyekpos2/service/api_service.dart';

class TambahProdukPage extends StatefulWidget {
  final Map<String, dynamic>? product;

  const TambahProdukPage({super.key, this.product});

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

  List<Map<String, dynamic>> _outletOptions = [];
  List<Map<String, dynamic>> _kategoriOptions = [];
  List<Map<String, dynamic>> _selectedOutlets = [];
  String? _selectedKategoriId;

  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  bool _isOutletOverlayOpen = false;

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
      final categories = outlets.isNotEmpty
          ? await _apiService.getCategories(outletId: outlets.first['id'])
          : <Map<String, dynamic>>[];

      if (mounted) {
        setState(() {
          _outletOptions = outlets;
          _kategoriOptions = categories;
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
    _selectedKategoriId = product['categoryId'];

    final List<String> outletIds =
    List<String>.from(product['outletIds'] ?? []);
    _selectedOutlets =
        _outletOptions.where((opt) => outletIds.contains(opt['id'])).toList();
  }

  @override
  void dispose() {
    _namaProdukController.dispose();
    _deskripsiController.dispose();
    _skuController.dispose();
    _hargaJualController.dispose();
    _hargaBeliController.dispose();
    _removeOutletOverlay();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    final isFormValid = _formKey.currentState!.validate();
    if (_selectedOutlets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Outlet harus dipilih'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_selectedKategoriId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Kategori harus dipilih'), backgroundColor: Colors.red),
      );
      return;
    }

    if (!isFormValid) return;

    setState(() => _isLoading = true);
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
          outlets: _selectedOutlets,
        );
      } else {
        await _apiService.addProduct(
          name: _namaProdukController.text,
          description: _deskripsiController.text,
          sku: _skuController.text,
          sellingPrice: sellingPrice,
          costPrice: costPrice,
          categoryId: _selectedKategoriId!,
          outlets: _selectedOutlets,
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

  void _toggleOutletOverlay(BuildContext targetContext) {
    if (_isOutletOverlayOpen) {
      _removeOutletOverlay();
    } else {
      _overlayEntry = _createOutletOverlayEntry(targetContext);
      Overlay.of(context).insert(_overlayEntry!);
      setState(() {
        _isOutletOverlayOpen = true;
      });
    }
  }

  void _removeOutletOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() {
        _isOutletOverlayOpen = false;
      });
    }
  }

  OverlayEntry _createOutletOverlayEntry(BuildContext targetContext) {
    final RenderBox renderBox = targetContext.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 4),
          child: Material(
            elevation: 4.0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.grey[300]!),
            ),
            child: StatefulBuilder(
              builder: (context, setDialogState) {
                final isAllSelected =
                    _selectedOutlets.length == _outletOptions.length;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_outletOptions.length > 1)
                      CheckboxListTile(
                        title: const Text('Pilih Semua'),
                        value: isAllSelected,
                        onChanged: (bool? value) {
                          setDialogState(() {
                            if (value == true) {
                              _selectedOutlets = List.from(_outletOptions);
                            } else {
                              _selectedOutlets.clear();
                            }
                            setState(() {});
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: const Color(0xFF00A3A3),
                      ),
                    ..._outletOptions.map((outlet) {
                      final isSelected = _selectedOutlets
                          .any((item) => item['id'] == outlet['id']);
                      return CheckboxListTile(
                        title: Text(outlet['name']),
                        value: isSelected,
                        onChanged: (bool? value) {
                          setDialogState(() {
                            if (value == true) {
                              _selectedOutlets.add(outlet);
                            } else {
                              _selectedOutlets.removeWhere(
                                      (item) => item['id'] == outlet['id']);
                            }
                            setState(() {});
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: const Color(0xFF00A3A3),
                      );
                    }).toList(),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _removeOutletOverlay,
      child: Scaffold(
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
                          _buildMultiSelectOutletField(),
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
      ),
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

  Widget _buildMultiSelectOutletField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Text('Atur Outlet', style: TextStyle(fontWeight: FontWeight.w600)),
            Text(' *', style: TextStyle(color: Colors.red)),
          ],
        ),
        const SizedBox(height: 8),
        Builder(
          builder: (context) {
            return CompositedTransformTarget(
              link: _layerLink,
              child: GestureDetector(
                onTap: () => _toggleOutletOverlay(context),
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: _isOutletOverlayOpen
                            ? const Color(0xFF00A3A3)
                            : Colors.grey[300]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _selectedOutlets.isEmpty
                          ? Text('Pilih',
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 16))
                          : Expanded(
                        child: Wrap(
                          spacing: 6.0,
                          runSpacing: 6.0,
                          children: _selectedOutlets
                              .map((outlet) => Chip(
                            label: Text(outlet['name']),
                            onDeleted: () {
                              setState(() {
                                _selectedOutlets.removeWhere(
                                        (item) =>
                                    item['id'] ==
                                        outlet['id']);
                              });
                            },
                            deleteIconColor: Colors.grey[700],
                            backgroundColor: Colors.grey[200],
                          ))
                              .toList(),
                        ),
                      ),
                      Icon(
                        _isOutletOverlayOpen
                            ? Icons.arrow_drop_up
                            : Icons.arrow_drop_down,
                        color: Colors.grey[700],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

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