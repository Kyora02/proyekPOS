import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TambahProdukPage extends StatefulWidget {
  const TambahProdukPage({super.key});

  @override
  State<TambahProdukPage> createState() => _TambahProdukPageState();
}

class _TambahProdukPageState extends State<TambahProdukPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final _namaProdukController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _skuController = TextEditingController();
  final _hargaJualController = TextEditingController();
  final _hargaBeliController = TextEditingController();

  List<String> _selectedOutlets = [];
  String? _selectedKategori;

  final List<String> _outletOptions = ['Outlet Pusat', 'Outlet Cabang A', 'Outlet Gudang'];
  final List<String> _kategoriOptions = ['Minuman Kopi', 'Makanan Ringan', 'Teh & Lainnya'];

  // State for custom overlay dropdown
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  bool _isOutletOverlayOpen = false;

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

  // --- MODIFIED: Methods now accept a BuildContext ---
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
    setState(() {
      _isOutletOverlayOpen = false;
    });
  }

  OverlayEntry _createOutletOverlayEntry(BuildContext targetContext) {
    // --- FIXED: Get RenderBox from the correct context ---
    final RenderBox renderBox = targetContext.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 4), // Position below the field
          child: Material(
            elevation: 4.0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.grey[300]!),
            ),
            child: StatefulBuilder(
              builder: (context, setDialogState) {
                final isAllSelected = _selectedOutlets.length == _outletOptions.length;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                      return CheckboxListTile(
                        title: Text(outlet),
                        value: _selectedOutlets.contains(outlet),
                        onChanged: (bool? value) {
                          setDialogState(() {
                            if (value == true) {
                              if (!_selectedOutlets.contains(outlet)) {
                                _selectedOutlets.add(outlet);
                              }
                            } else {
                              _selectedOutlets.remove(outlet);
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
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.black87),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Tambahkan Produk',
            style: TextStyle(
              color: Color(0xFF333333),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Form(
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
                            hint: 'Contoh: Perpaduan kopi, susu, dan gula aren',
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),
                          _buildImagePicker(),
                          const SizedBox(height: 16),
                          _buildDropdownField(
                            label: 'Kategori Produk',
                            value: _selectedKategori,
                            items: _kategoriOptions,
                            hint: 'Pilih kategori',
                            onChanged: (value) {
                              setState(() {
                                _selectedKategori = value;
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
                                  isRequired: true,
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text(
                            'Batal',
                            style: TextStyle(color: Color(0xFF00A3A3)),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            final isFormValid = _formKey.currentState!.validate();
                            if (_selectedOutlets.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Outlet harus dipilih'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            if (isFormValid) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Menyimpan produk...')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00A3A3),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          ),
                          child: const Text('Simpan'),
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
          validator: (value) {
            if (isRequired && (value == null || value.isEmpty)) {
              return '$label tidak boleh kosong';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
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
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
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
        // --- MODIFIED: Wrapped in a Builder to get the correct context ---
        Builder(
          builder: (context) {
            return CompositedTransformTarget(
              link: _layerLink,
              child: GestureDetector(
                onTap: () => _toggleOutletOverlay(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _isOutletOverlayOpen ? const Color(0xFF00A3A3) : Colors.grey[300]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _selectedOutlets.isEmpty
                          ? Text('Pilih', style: TextStyle(color: Colors.grey[600], fontSize: 16))
                          : Expanded(
                        child: Wrap(
                          spacing: 6.0,
                          runSpacing: 6.0,
                          children: _selectedOutlets
                              .map((outlet) => Chip(
                            label: Text(outlet),
                            onDeleted: () {
                              setState(() {
                                _selectedOutlets.remove(outlet);
                              });
                            },
                            deleteIconColor: Colors.grey[700],
                            backgroundColor: Colors.grey[200],
                          ))
                              .toList(),
                        ),
                      ),
                      Icon(
                        _isOutletOverlayOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
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
              const SnackBar(content: Text('Buka galeri...')),
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
                Icon(Icons.cloud_upload_outlined, size: 40, color: Colors.grey[600]),
                const SizedBox(height: 8),
                Text('Pilih atau letakkan berkas di sini', style: TextStyle(color: Colors.grey[700])),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

