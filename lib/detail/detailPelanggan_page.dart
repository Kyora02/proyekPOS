import 'package:flutter/material.dart';

class DetailPelangganPage extends StatelessWidget {
  final Map<String, dynamic> pelanggan;

  const DetailPelangganPage({
    super.key,
    required this.pelanggan,
  });

  @override
  Widget build(BuildContext context) {
    final String name = pelanggan['name'] ?? '-';
    final String email = pelanggan['email'] ?? '-';
    final String phone = pelanggan['phone'] ?? '-';
    final String address = pelanggan['address'] ?? '-';
    final String gender = pelanggan['gender'] ?? '-';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          'Detail Pelanggan',
          style: TextStyle(
            color: Color(0xFF333333),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey[200]!),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFF279E9E).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          size: 40,
                          color: Color(0xFF279E9E),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildReadOnlyField(
                      label: 'Nama Pelanggan',
                      value: name,
                      icon: Icons.person,
                    ),
                    const SizedBox(height: 20),
                    _buildReadOnlyField(
                      label: 'Email',
                      value: email,
                      icon: Icons.email_outlined,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildReadOnlyField(
                            label: 'No. Telepon',
                            value: phone,
                            icon: Icons.phone_outlined,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _buildReadOnlyField(
                            label: 'Jenis Kelamin',
                            value: gender,
                            icon: Icons.wc,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildReadOnlyField(
                      label: 'Alamat',
                      value: address,
                      icon: Icons.location_on_outlined,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF279E9E)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Kembali',
                          style: TextStyle(
                            color: Color(0xFF279E9E),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
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

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: Colors.grey[500]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}