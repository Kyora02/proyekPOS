import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TambahKuponPage extends StatefulWidget {
  const TambahKuponPage({super.key});

  @override
  State<TambahKuponPage> createState() => _TambahKuponPageState();
}

class _TambahKuponPageState extends State<TambahKuponPage> {
  final _formKey = GlobalKey<FormState>();

  final _namaKuponC = TextEditingController();
  final _deskripsiC = TextEditingController();
  final _nilaiKuponC = TextEditingController();

  String? _selectedOutlet;
  String _tipeNilaiKupon = 'percent';
  DateTime? _tanggalMulai;
  DateTime? _tanggalSelesai;
  bool _kuponStatus = true;

  final List<String> _outletOptions = ['Pilih', 'Semua Outlet', 'Kashierku Pusat', 'Kashierku Cabang A'];

  @override
  void initState() {
    super.initState();
    _selectedOutlet = _outletOptions.first;
  }

  @override
  void dispose() {
    _namaKuponC.dispose();
    _deskripsiC.dispose();
    _nilaiKuponC.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, {required bool isStartDate}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (isStartDate ? _tanggalMulai : _tanggalSelesai) ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _tanggalMulai = picked;
          if (_tanggalSelesai != null && _tanggalSelesai!.isBefore(picked)) {
            _tanggalSelesai = picked;
          }
        } else {
          _tanggalSelesai = picked;
          if (_tanggalMulai != null && _tanggalMulai!.isAfter(picked)) {
            _tanggalMulai = picked;
          }
        }
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Pilih tanggal';
    }
    return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
  }

  void _saveCoupon() {
    if (_formKey.currentState!.validate()) {
      print('Daftar Outlet: $_selectedOutlet');
      print('Nama Kupon: ${_namaKuponC.text}');
      print('Deskripsi: ${_deskripsiC.text}');
      print('Status: $_kuponStatus');
      print('Tipe Nilai Kupon: $_tipeNilaiKupon');
      print('Nilai Kupon: ${_nilaiKuponC.text}');
      print('Tanggal Mulai: ${_formatDate(_tanggalMulai)}');
      print('Tanggal Selesai: ${_formatDate(_tanggalSelesai)}');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kupon berhasil disimpan!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black54),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Tambahkan Kupon',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Informasi Kupon'),
                  const SizedBox(height: 16),
                  _buildKuponInformationCard(),
                  const SizedBox(height: 24),

                  _buildSectionTitle('Nilai Kupon'),
                  const SizedBox(height: 16),
                  _buildNilaiKuponCard(),
                  const SizedBox(height: 24),

                  _buildSectionTitle('Periode Kupon'),
                  const SizedBox(height: 16),
                  _buildPeriodeKuponCard(),
                  const SizedBox(height: 32),

                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ),
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

  Widget _buildKuponInformationCard() {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDropdownField(
              label: 'Daftar Outlet',
              value: _selectedOutlet,
              items: _outletOptions,
              onChanged: (newValue) {
                setState(() {
                  _selectedOutlet = newValue;
                });
              },
              validator: (value) =>
              value == 'Pilih' || value == null ? 'Outlet wajib dipilih' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Nama Kupon',
              controller: _namaKuponC,
              hint: 'Contoh: Kupon Liburan',
              validator: (value) =>
              value == null || value.isEmpty ? 'Nama Kupon wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Deskripsi',
              controller: _deskripsiC,
              hint: 'Contoh: Kupon khusus hari libur nasional',
              maxLines: 3,
              isOptional: true,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Status',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                ),
                Switch(
                  value: _kuponStatus,
                  onChanged: (bool value) {
                    setState(() {
                      _kuponStatus = value;
                    });
                  },
                  activeColor: const Color(0xFF279E9E),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNilaiKuponCard() {
    return Card(
      elevation: 2,
      color: Colors.white, // <-- THIS LINE
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Besaran Nilai kupon',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildRadioTile(
                    label: '%',
                    value: 'percent',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildRadioTile(
                    label: 'Rp',
                    value: 'rupiah',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nilaiKuponC,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration(
                hint: _tipeNilaiKupon == 'percent' ? 'Contoh: 25' : 'Contoh: 10000',
                prefixText: _tipeNilaiKupon == 'rupiah' ? 'Rp ' : null,
                suffixText: _tipeNilaiKupon == 'percent' ? ' %' : null,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nilai kupon wajib diisi';
                }
                if (double.tryParse(value) == null) {
                  return 'Masukkan angka yang valid';
                }
                if (_tipeNilaiKupon == 'percent' && (double.parse(value) < 0 || double.parse(value) > 100)) {
                  return 'Persen harus antara 0-100';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioTile({
    required String label,
    required String value,
  }) {
    return InkWell(
      onTap: () => setState(() {
        _tipeNilaiKupon = value;
        _nilaiKuponC.clear();
      }),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _tipeNilaiKupon == value ? const Color(0xFF279E9E) : Colors.grey[300]!,
            width: _tipeNilaiKupon == value ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: _tipeNilaiKupon,
              onChanged: (newValue) => setState(() {
                _tipeNilaiKupon = newValue!;
                _nilaiKuponC.clear();
              }),
              activeColor: const Color(0xFF279E9E),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            Expanded(child: Text(label)),
          ],
        ),
      ),
    );
  }


  Widget _buildPeriodeKuponCard() {
    return Card(
      elevation: 2,
      color: Colors.white, // <-- THIS LINE
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Durasi Kupon',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final bool isWide = constraints.maxWidth > 350;
                return isWide
                    ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildDatePickerField(
                      label: 'Tanggal Mulai',
                      date: _tanggalMulai,
                      onTap: () => _selectDate(context, isStartDate: true),
                      validator: (value) => _tanggalMulai == null ? 'Tanggal mulai wajib diisi' : null,
                    )),
                    const SizedBox(width: 16),
                    Expanded(child: _buildDatePickerField(
                      label: 'Tanggal Selesai',
                      date: _tanggalSelesai,
                      onTap: () => _selectDate(context, isStartDate: false),
                      validator: (value) => _tanggalSelesai == null ? 'Tanggal selesai wajib diisi' : null,
                    )),
                  ],
                )
                    : Column(
                  children: [
                    _buildDatePickerField(
                      label: 'Tanggal Mulai',
                      date: _tanggalMulai,
                      onTap: () => _selectDate(context, isStartDate: true),
                      validator: (value) => _tanggalMulai == null ? 'Tanggal mulai wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildDatePickerField(
                      label: 'Tanggal Selesai',
                      date: _tanggalSelesai,
                      onTap: () => _selectDate(context, isStartDate: false),
                      validator: (value) => _tanggalSelesai == null ? 'Tanggal selesai wajib diisi' : null,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePickerField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: AbsorbPointer(
            child: TextFormField(
              controller: TextEditingController(text: _formatDate(date)),
              decoration: _inputDecoration(
                hint: 'Pilih tanggal',
                suffixIcon: const Icon(Icons.calendar_today_outlined, size: 20, color: Colors.grey),
              ),
              validator: validator,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey[700],
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('Batal'),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: _saveCoupon,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF279E9E),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Simpan'),
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
        Text(isOptional ? label : '$label*', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: _inputDecoration(hint: hint),
          validator: isOptional ? null : (validator ?? (value) => value == null || value.isEmpty ? '$label wajib diisi' : null),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label*', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
          onChanged: onChanged,
          decoration: _inputDecoration(hint: 'Pilih'),
          validator: validator,
          dropdownColor: Colors.white,
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({String? hint, String? prefixText, String? suffixText, Widget? suffixIcon}) {
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