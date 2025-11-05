import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:proyekpos2/service/api_service.dart';

class TambahOutletPage extends StatefulWidget {
  final Map<String, dynamic>? outlet;

  const TambahOutletPage({super.key, this.outlet});

  @override
  State<TambahOutletPage> createState() => _TambahOutletPageState();
}

class _TambahOutletPageState extends State<TambahOutletPage> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  final TextEditingController _namaOutletC = TextEditingController();
  final TextEditingController _alamatC = TextEditingController();
  final TextEditingController _kotaC = TextEditingController();
  final TextEditingController _ownerNameC = TextEditingController();

  String? _selectedLamaOperasi;
  bool _isLoading = false;

  bool get _isEditMode => widget.outlet != null;

  final List<String> _lamaOperasiOptions = [
    '< 1 Tahun',
    '1-3 Tahun',
    '> 3 Tahun',
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final outlet = widget.outlet!;
      _namaOutletC.text = outlet['name'] ?? '';
      _alamatC.text = outlet['alamat'] ?? '';
      _kotaC.text = outlet['city'] ?? '';
      _ownerNameC.text = outlet['ownerName'] ?? '';
      _selectedLamaOperasi = outlet['operationDuration'];
    } else {
      _loadOwnerInfo();
    }
  }

  void _loadOwnerInfo() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _ownerNameC.text = user.displayName ?? user.email ?? 'Unknown User';
    }
  }

  Future<void> _saveOutlet() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedLamaOperasi == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Lama Operasi wajib dipilih'),
              backgroundColor: Colors.red),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        if (_isEditMode) {
          await _apiService.updateOutlet(
            id: widget.outlet!['id'],
            name: _namaOutletC.text,
            alamat: _alamatC.text,
            city: _kotaC.text,
            operationDuration: _selectedLamaOperasi!,
          );
        } else {
          await _apiService.addOutlet(
            name: _namaOutletC.text,
            alamat: _alamatC.text,
            city: _kotaC.text,
            ownerName: _ownerNameC.text,
            operationDuration: _selectedLamaOperasi!,
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
            Text('Outlet berhasil ${_isEditMode ? 'diupdate' : 'disimpan'}!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal menyimpan outlet: $e'),
              backgroundColor: Colors.red),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _namaOutletC.dispose();
    _alamatC.dispose();
    _kotaC.dispose();
    _ownerNameC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false,
        title: Text(
          _isEditMode ? 'Edit Outlet' : 'Tambahkan Outlet',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black54),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Informasi Outlet'),
                      const SizedBox(height: 16),
                      _buildOutletInformationCard(),
                      const SizedBox(height: 32),
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withAlpha(128),
              child: const Center(
                  child: CircularProgressIndicator(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF333333),
      ),
    );
  }

  Widget _buildOutletInformationCard() {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(
              label: 'Nama Outlet',
              controller: _namaOutletC,
              hint: 'Contoh: Outlet Utama',
              validator: (value) => value == null || value.isEmpty
                  ? 'Nama Outlet wajib diisi'
                  : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Alamat',
              controller: _alamatC,
              hint: 'Contoh: Jl. Merdeka No. 10',
              validator: (value) => value == null || value.isEmpty
                  ? 'Alamat wajib diisi'
                  : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Kota',
              controller: _kotaC,
              hint: 'Contoh: Jakarta',
              validator: (value) =>
              value == null || value.isEmpty ? 'Kota wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            _buildOwnerField(),
            const SizedBox(height: 16),
            _buildLamaOperasiDropdown(),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnerField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Owner*',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _ownerNameC,
          readOnly: true,
          decoration: _inputDecoration(
            hint: 'Email Owner',
          ).copyWith(
            fillColor: Colors.grey[200],
            filled: true,
          ),
        ),
      ],
    );
  }

  Widget _buildLamaOperasiDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Lama Operasi*',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedLamaOperasi,
          items: _lamaOperasiOptions.map((String option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(option),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _selectedLamaOperasi = newValue;
            });
          },
          decoration: _inputDecoration(hint: 'Pilih Lama Operasi'),
          validator: (value) =>
          value == null ? 'Lama Operasi wajib dipilih' : null,
          dropdownColor: Colors.white,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton(
          onPressed: _isLoading ? null : _saveOutlet,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF279E9E),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child:
          _isLoading ? const Text('Menyimpan...') : Text(_isEditMode ? 'Update' : 'Simpan'),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
    bool isOptional = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(isOptional ? label : '$label*',
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: _inputDecoration(hint: hint),
          validator: isOptional
              ? null
              : (validator ??
                  (value) => value == null || value.isEmpty
                  ? '$label wajib diisi'
                  : null),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    String? hint,
    String? prefixText,
    String? suffixText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixText: prefixText,
      suffixText: suffixText,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF279E9E), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }
}