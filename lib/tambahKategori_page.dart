import 'package:flutter/material.dart';
import 'package:proyekpos2/service/api_service.dart';

class TambahKategoriPage extends StatefulWidget {
  // 1. Add this field to accept an optional category for editing
  final Map<String, dynamic>? kategori;

  // 2. Update the constructor
  const TambahKategoriPage({
    super.key,
    this.kategori, // Make it an optional parameter
  });

  @override
  State<TambahKategoriPage> createState() => _TambahKategoriPageState();
}

class _TambahKategoriPageState extends State<TambahKategoriPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaKategoriController = TextEditingController();
  final _urutanController = TextEditingController();

  List<Map<String, dynamic>> _selectedOutlets = [];
  List<Map<String, dynamic>> _outletOptions = [];
  String? _outletError;

  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  bool _isOutletOverlayOpen = false;
  bool _isSaving = false;

  // 3. Add a getter to easily check if we are in "Edit Mode"
  bool get _isEditMode => widget.kategori != null;

  @override
  void initState() {
    super.initState();
    // 4. Modify initState to fetch outlets and *then* populate fields if editing
    _fetchOutlets().then((_) {
      if (_isEditMode && mounted) {
        // If we are editing, populate the form
        final kategori = widget.kategori!;
        _namaKategoriController.text = kategori['name'] ?? '';
        _urutanController.text = kategori['order']?.toString() ?? '';

        // Match the saved outletIds with the full outlet objects
        final List<String> outletIds =
        List<String>.from(kategori['outletIds'] ?? []);

        setState(() {
          _selectedOutlets = _outletOptions.where((option) {
            return outletIds.contains(option['id']);
          }).toList();
        });
      }
    });
  }

  Future<void> _fetchOutlets() async {
    try {
      final apiService = ApiService();
      final fetchedOutlets = await apiService.getOutlets();
      if (mounted) {
        setState(() {
          _outletOptions = fetchedOutlets;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _outletError = "Gagal memuat outlet.";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_outletError!), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _namaKategoriController.dispose();
    _urutanController.dispose();
    _removeOutletOverlay();
    super.dispose();
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
                    // This is your fix from before
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
                      // Check if the current outlet is in the selected list
                      final isSelected = _selectedOutlets.any(
                            (selected) => selected['id'] == outlet['id'],
                      );
                      return CheckboxListTile(
                        title: Text(outlet['name']),
                        value: isSelected,
                        onChanged: (bool? value) {
                          setDialogState(() {
                            if (value == true) {
                              _selectedOutlets.add(outlet);
                            } else {
                              _selectedOutlets.removeWhere(
                                    (selected) => selected['id'] == outlet['id'],
                              );
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

  Future<void> _saveCategory() async {
    final isFormValid = _formKey.currentState!.validate();
    if (_selectedOutlets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Outlet harus dipilih'), backgroundColor: Colors.red),
      );
      return;
    }

    if (isFormValid) {
      setState(() {
        _isSaving = true;
      });

      try {
        final apiService = ApiService();
        final order = int.tryParse(_urutanController.text) ?? 0;
        if (_isEditMode) {
          await apiService.updateCategory(
            id: widget.kategori!['id'],
            name: _namaKategoriController.text,
            order: order,
            outlets: _selectedOutlets,
          );
        } else {
          await apiService.addCategory(
            name: _namaKategoriController.text,
            order: order,
            outlets: _selectedOutlets,
            productQty: 0,
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Kategori berhasil disimpan!'),
                backgroundColor: Colors.green),
          );
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Gagal menyimpan: ${e.toString()}'),
                backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
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
          // 6. Make the AppBar title dynamic
          title: Text(
            _isEditMode ? 'Edit Kategori' : 'Tambahkan Kategori',
            style: const TextStyle(
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
                      title: 'Informasi Kategori',
                      child: Column(
                        children: [
                          _buildMultiSelectOutletField(),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _namaKategoriController,
                            label: 'Nama Kategori',
                            hint: 'Contoh: Snack',
                            isRequired: true,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _urutanController,
                            label: 'Urutan',
                            hint: 'Contoh: 1',
                            isRequired: true,
                            keyboardType: TextInputType.number,
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
                          onPressed: _isSaving ? null : _saveCategory,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00A3A3),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 16),
                            disabledBackgroundColor: Colors.grey,
                          ),
                          child: _isSaving
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
    TextInputType keyboardType = TextInputType.text,
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
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
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
                onTap: () {
                  if (_outletError == null && _outletOptions.isNotEmpty) {
                    _toggleOutletOverlay(context);
                  }
                },
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
                          ? Text(
                        _outletError != null
                            ? _outletError!
                            : _outletOptions.isEmpty
                            ? 'Tidak ada outlet'
                            : 'Pilih',
                        style: TextStyle(
                          color: _outletError != null
                              ? Colors.red
                              : Colors.grey[600],
                          fontSize: 16,
                        ),
                      )
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
                                      (o) => o['id'] == outlet['id'],
                                );
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
}