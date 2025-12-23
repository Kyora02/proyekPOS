import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyekpos2/service/api_service.dart';
import 'package:intl/intl.dart';

final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
class DenahMejaPage extends StatefulWidget {
  final String outletId;

  const DenahMejaPage({super.key, required this.outletId});

  @override
  State<DenahMejaPage> createState() => _DenahMejaPageState();
}

class _DenahMejaPageState extends State<DenahMejaPage> {
  final ApiService _apiService = ApiService();

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'terisi':
        return Colors.redAccent;
      case 'tersedia':
      default:
        return Colors.green;
    }
  }

  Future<void> _navigateToCashierPayment(String? orderId) async {
    if (orderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ID Pesanan tidak ditemukan")),
      );
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('transactions')
          .doc(orderId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;

        if (mounted) {
          Navigator.pop(context, {
            'orderId': orderId,
            'items': data['items'],
            'customerName': data['customerName'],
            'totalAmount': data['totalAmount'],
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Data pesanan tidak ditemukan di database")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal memuat data: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Denah Meja Aktif"),
        backgroundColor: const Color(0xFF00A3A3),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('meja')
            .where('outletId', isEqualTo: widget.outletId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Tidak ada meja tersedia'));
          }

          final docs = snapshot.data!.docs;
          docs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;

            final aNumber = aData['number'] ?? 0;
            final bNumber = bData['number'] ?? 0;

            return aNumber.compareTo(bNumber);
          });

          return GridView.builder(
            padding: const EdgeInsets.all(24),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 180,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final String id = docs[index].id;
              final String nomor = (data['number'] ??
                  data['nomor'] ??
                  data['name'] ??
                  data['no_meja'] ??
                  '-').toString();
              final String status = data['status'] ?? 'Tersedia';
              final String? orderId = data['activeOrderId'];

              return InkWell(
                onTap: () => _handleTableAction(id, nomor, status, orderId),
                child: Container(
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.table_bar_rounded, color: Colors.white, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        "$nomor",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _handleTableAction(String id, String nomor, String status, String? orderId) {
    if (status.toLowerCase() == 'terisi') {
      _showOccupiedMenu(id, nomor, orderId);
    } else {
      _showAvailableMenu(id, nomor);
    }
  }

  void _showAvailableMenu(String id, String nomor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Buka $nomor"),
        content: const Text("Apakah Anda ingin menandai meja ini sebagai terisi?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal")
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A3A3)
            ),
            onPressed: () async {
              try {
                // Gunakan lowercase 'terisi'
                await FirebaseFirestore.instance
                    .collection('meja')
                    .doc(id)
                    .update({
                  'status': 'terisi',  // lowercase!
                  'updatedAt': FieldValue.serverTimestamp(),
                });

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Meja berhasil dibuka"),
                        backgroundColor: Colors.green,
                      )
                  );
                }
              } catch (e) {
                print('Error updating table: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Error: $e"),
                        backgroundColor: Colors.red,
                      )
                  );
                }
              }
            },
            child: const Text("Ya, Buka"),
          ),
        ],
      ),
    );
  }

  void _showOccupiedMenu(String id, String nomor, String? orderId) async {
    Map<String, dynamic>? orderData;
    if (orderId != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('transactions')
            .doc(orderId)
            .get();
        if (doc.exists) {
          orderData = doc.data() as Map<String, dynamic>;
        }
      } catch (e) {
        print('Error fetching order: $e');
      }
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))
      ),
      builder: (context) =>
          Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      "$nomor (Terisi)",
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 8),

                  if (orderData != null) ...[
                    Text(
                        "Pelanggan: ${orderData['customerName'] ?? '-'}",
                        style: const TextStyle(fontSize: 14, color: Colors.grey)
                    ),
                    const SizedBox(height: 16),
                    const Text(
                        "Pesanan:",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)
                    ),
                    const SizedBox(height: 8),

                    ...((orderData['items'] as List?)?.map((item) =>
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                    "${item['quantity']}x ${item['name']}",
                                    style: const TextStyle(fontSize: 14)
                                ),
                              ),
                              Text(
                                  currencyFormatter.format(item['total']),
                                  style: const TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.w500)
                              ),
                            ],
                          ),
                        )) ?? []),

                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                            "Total:",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)
                        ),
                        Text(
                            currencyFormatter.format(orderData['totalAmount']),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF00A3A3)
                            )
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  ListTile(
                    leading: const Icon(
                        Icons.payments_outlined, color: Color(0xFF00A3A3)),
                    title: const Text("Proses Checkout / Bayar"),
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToCashierPayment(orderId);
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                        Icons.clean_hands_outlined, color: Colors.grey),
                    title: const Text("Kosongkan Meja (Selesai)"),
                    onTap: () async {
                      try {
                        await FirebaseFirestore.instance
                            .collection('meja')
                            .doc(id)
                            .update({
                          'status': 'tersedia',
                          'activeOrderId': null,
                          'updatedAt': FieldValue.serverTimestamp(),
                        });

                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Meja berhasil dikosongkan"),
                                backgroundColor: Colors.green,
                              )
                          );
                        }
                      } catch (e) {
                        print('Error clearing table: $e');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Error: $e"),
                                backgroundColor: Colors.red,
                              )
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
    );
  }
}