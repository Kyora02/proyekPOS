import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:html' as html;

final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

class DenahMejaPage extends StatefulWidget {
  final String outletId;
  const DenahMejaPage({super.key, required this.outletId});
  @override
  State<DenahMejaPage> createState() => _DenahMejaPageState();
}

class _DenahMejaPageState extends State<DenahMejaPage> {
  final String _baseUrl = kIsWeb
      ? 'http://localhost:3000/api'
      : 'https://kashierku.ngelantour.cloud/api';

  Map<String, dynamic>? _outletData;

  @override
  void initState() {
    super.initState();
    _fetchOutletData();
  }

  Future<void> _fetchOutletData() async {
    try {
      final outletDoc = await FirebaseFirestore.instance.collection('outlets').doc(widget.outletId).get();
      if (outletDoc.exists && mounted) {
        setState(() {
          _outletData = outletDoc.data();
        });
      }
    } catch (e) {
      debugPrint('Error fetching outlet data: $e');
    }
  }

  Future<String> _getAuthToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Pengguna tidak login.');
    }
    final String? token = await user.getIdToken();
    if (token == null) {
      throw Exception('Gagal mendapatkan token otentikasi.');
    }
    return token;
  }

  void _showPaymentSelectionDialog(Map<String, dynamic> orderData, String tableId) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Pilih Metode Pembayaran",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F7F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Total Pembayaran",
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormatter.format(orderData['totalAmount']),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: Color(0xFF00A3A3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  _closeBill(orderData['orderId'], tableId, "Tunai", orderData);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.green, width: 2),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.money, color: Colors.green, size: 28),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        "TUNAI / CASH",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  _closeBill(orderData['orderId'], tableId, "EDC", orderData);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue, width: 2),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.credit_card, color: Colors.blue, size: 28),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        "EDC / KARTU",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Batal",
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _closeBill(String orderId, String tableId, String method, Map<String, dynamic> orderData) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final token = await _getAuthToken();

      final response = await http.post(
        Uri.parse('$_baseUrl/payment/close-bill-pos'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          'orderId': orderId,
          'tableId': tableId,
          'paymentMethod': method,
        }),
      );

      if (mounted) Navigator.pop(context);

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success']) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Pembayaran Berhasil & Meja Kosong"),
                backgroundColor: Colors.green,
              ),
            );
            _showPrintReceiptDialog(orderId, orderData, method);
          }
        } else {
          throw Exception(result['message'] ?? 'Payment failed');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPrintReceiptDialog(String orderId, Map<String, dynamic> orderData, String paymentMethod) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Transaksi Berhasil",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Apakah Anda ingin mencetak struk belanja?",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "TUTUP",
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A3A3),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _printReceipt(orderId, orderData, paymentMethod);
                      },
                      child: const Text(
                        "CETAK STRUK",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _printReceipt(String orderId, Map<String, dynamic> orderData, String paymentMethod) async {
    try {
      final outletName = _outletData?['name'] ?? 'Outlet';
      final outletAddress = _outletData?['alamat'] ?? '';
      final transactionId = orderId;
      final date = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
      final customerName = orderData['customerName'] ?? 'Guest';
      final tableNumber = orderData['tableNumber'] ?? '-';

      final List<dynamic> items = orderData['items'] ?? [];

      int totalQty = 0;
      for (var item in items) {
        totalQty += (item['quantity'] as int);
      }

      final subtotal = orderData['subTotal'] ?? orderData['totalAmount'] ?? 0;
      final tax = orderData['tax'] ?? 0;
      final total = orderData['totalAmount'] ?? 0;

      String receiptHtml = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Struk Pembayaran</title>
  <style>
    @page {
      size: 80mm auto;
      margin: 0;
    }
    body {
      font-family: 'Courier New', monospace;
      font-size: 12px;
      width: 80mm;
      margin: 0 auto;
      padding: 10mm;
    }
    .center {
      text-align: center;
    }
    .bold {
      font-weight: bold;
    }
    .line {
      border-top: 1px dashed #000;
      margin: 5px 0;
    }
    .item-row {
      display: flex;
      justify-content: space-between;
      margin: 3px 0;
    }
    .total-section {
      margin-top: 10px;
      border-top: 2px solid #000;
      padding-top: 5px;
    }
    .variant-text {
      font-size: 10px;
      color: #555;
      margin-left: 10px;
      font-style: italic;
    }
    .note-text {
      font-size: 10px;
      color: #666;
      margin-left: 10px;
      margin-top: 2px;
    }
  </style>
</head>
<body>
  <div class="center bold" style="font-size: 14px;">$outletName</div>
  <div class="center" style="font-size: 10px; margin-bottom: 5px;">$outletAddress</div>
  <div class="line"></div>
  <div>No. Transaksi: $transactionId</div>
  <div>Tanggal: $date</div>
  <div>Meja: $tableNumber</div>
  <div>Pelanggan: $customerName</div>
  <div class="line"></div>
''';

      for (var item in items) {
        final name = item['name'] ?? '';
        final qty = item['quantity'] ?? 1;
        final price = (item['sellingPrice'] ?? item['price'] ?? 0).toDouble();
        final itemTotal = (item['total'] ?? (price * qty)).toDouble();
        final variants = item['variants'] as Map<String, dynamic>?;
        final note = item['note'] as String?;

        receiptHtml += '''
  <div class="item-row">
    <span>${qty}x $name</span>
    <span>${currencyFormatter.format(itemTotal)}</span>
  </div>
''';
        if (variants != null && variants.isNotEmpty) {
          for (var entry in variants.entries) {
            receiptHtml += '''
  <div class="variant-text">+ ${entry.key}: ${entry.value}</div>
''';
          }
        }

        if (note != null && note.isNotEmpty) {
          receiptHtml += '''
  <div class="note-text">Catatan: $note</div>
''';
        }
      }

      receiptHtml += '''
  <div class="line"></div>
  <div class="item-row">
    <span>Total Item ($totalQty)</span>
    <span></span>
  </div>
  <div class="item-row">
    <span>Subtotal</span>
    <span>${currencyFormatter.format(subtotal)}</span>
  </div>
''';

      if (tax > 0) {
        receiptHtml += '''
  <div class="item-row">
    <span>Pajak (10%)</span>
    <span>${currencyFormatter.format(tax)}</span>
  </div>
''';
      }

      receiptHtml += '''
  <div class="total-section">
    <div class="item-row bold" style="font-size: 14px;">
      <span>TOTAL</span>
      <span>${currencyFormatter.format(total)}</span>
    </div>
  </div>
  <div class="line"></div>
  <div class="center">Metode Pembayaran: $paymentMethod</div>
  <div class="center" style="margin-top: 10px;">Terima Kasih!</div>
  <script>
    window.onload = function() {
      window.print();
    }
  </script>
</body>
</html>
''';

      if (kIsWeb) {
        final blob = html.Blob([receiptHtml], 'text/html');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.window.open(url, '_blank');
        html.Url.revokeObjectUrl(url);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Struk berhasil dicetak"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error printing: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    return status.toLowerCase() == 'terisi' ? Colors.redAccent : Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Denah Meja Resto"),
        backgroundColor: const Color(0xFF00A3A3),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('meja')
            .where('outletId', isEqualTo: widget.outletId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada meja. Tambahkan meja terlebih dahulu.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(24),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 180,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final String status = data['status'] ?? 'tersedia';
              final tableNumber = data['number'] ?? (index + 1);
              return InkWell(
                onTap: () => _handleTableAction(
                    docs[index].id,
                    tableNumber.toString(),
                    status,
                    data['activeOrderId']
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.table_bar_rounded, color: Colors.white, size: 48),
                      Text(
                          "Meja $tableNumber",
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold
                          )
                      ),
                      Text(
                          status.toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10
                          )
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

  void _showOccupiedMenu(String id, String nomor, String? orderId) async {
    Map<String, dynamic>? orderData;

    if (orderId != null && orderId.isNotEmpty) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('transactions')
            .doc(orderId)
            .get();

        if (doc.exists) {
          orderData = doc.data();
          if (orderData != null && !orderData.containsKey('totalAmount')) {
            orderData['totalAmount'] = orderData['grossAmount'] ?? 0;
          }
          if (orderData != null) {
            orderData['orderId'] = orderId;
          }
        } else {
          print('Order document not found: $orderId');
        }
      } catch (e) {
        print('Error fetching order: $e');
      }
    } else {
      print('No activeOrderId found for table $nomor');
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))
      ),
      backgroundColor: Colors.white,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  "Meja $nomor (Terisi)",
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold
                  )
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
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                ),
                const SizedBox(height: 8),

                ...((orderData['items'] as List?)?.map((item) {
                  final variants = item['variants'] as Map<String, dynamic>?;
                  final note = item['note'] as String?;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                  "${item['quantity']}x ${item['name']}",
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)
                              ),
                            ),
                            Text(
                                currencyFormatter.format(
                                    (item['total'] ?? (item['price'] ?? item['sellingPrice'] ?? 0) * item['quantity'])
                                ),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)
                            ),
                          ],
                        ),
                        if (variants != null && variants.isNotEmpty) ...[
                          ...variants.entries.map((entry) => Padding(
                            padding: const EdgeInsets.only(left: 16, top: 2),
                            child: Text(
                                "• ${entry.key}: ${entry.value}",
                                style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)
                            ),
                          )),
                        ],
                        if (note != null && note.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 16, top: 2),
                            child: Text(
                                "Catatan: $note",
                                style: const TextStyle(fontSize: 12, color: Colors.grey)
                            ),
                          ),
                      ],
                    ),
                  );
                }) ?? []),

                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                        "Total:",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
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

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle),
                    label: const Text("PROSES CHECKOUT / BAYAR"),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A3A3),
                        foregroundColor: Colors.white
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _showPaymentSelectionDialog(orderData!, id);
                    },
                  ),
                ),
                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.clean_hands_outlined),
                    label: const Text("Kosongkan Meja (Selesai)"),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey
                    ),
                    onPressed: () async {
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
                ),
              ] else ...[
                const SizedBox(height: 10),
                Text(
                  orderId != null && orderId.isNotEmpty
                      ? "Order ID: $orderId tidak ditemukan"
                      : "Tidak ada pesanan aktif untuk meja ini",
                  style: const TextStyle(color: Colors.orange),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('meja')
                        .doc(id)
                        .update({
                      'status': 'tersedia',
                      'activeOrderId': null
                    });
                    Navigator.pop(context);
                  },
                  child: const Text("Kosongkan Meja"),
                ),
              ],
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  void _showAvailableMenu(String id, String nomor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text("Buka Meja $nomor"),
        content: const Text("Tandai meja ini sebagai terisi?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("BATAL")
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('meja')
                  .doc(id)
                  .update({'status': 'terisi'});
              Navigator.pop(context);
            },
            child: const Text("BUKA"),
          )
        ],
      ),
    );
  }
}