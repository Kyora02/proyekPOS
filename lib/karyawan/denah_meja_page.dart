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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Metode Pembayaran",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Text("Total Tagihan", style: TextStyle(fontSize: 12, color: Colors.black54)),
                      const SizedBox(height: 4),
                      Text(
                        currencyFormatter.format(orderData['totalAmount']),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Color(0xFF00A3A3)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildPaymentOption(
                  icon: Icons.payments_outlined,
                  label: "TUNAI",
                  color: Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    _closeBill(orderData['orderId'], tableId, "Tunai", orderData);
                  },
                ),
                const SizedBox(height: 12),
                _buildPaymentOption(
                  icon: Icons.credit_card_outlined,
                  label: "EDC / TRANSFER",
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    _closeBill(orderData['orderId'], tableId, "EDC", orderData);
                  },
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Batal", style: TextStyle(color: Colors.grey, fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 16),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
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
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
        body: jsonEncode({'orderId': orderId, 'tableId': tableId, 'paymentMethod': method}),
      );

      if (mounted) Navigator.pop(context);

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success']) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Pembayaran Berhasil"), backgroundColor: Colors.green),
            );
            _showPrintReceiptDialog(orderId, orderData, method);
          }
        } else {
          throw Exception(result['message'] ?? 'Gagal');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    }
  }

  void _showPrintReceiptDialog(String orderId, Map<String, dynamic> orderData, String paymentMethod) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Transaksi Berhasil", textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: const Text("Cetak struk belanja?", textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.only(bottom: 16),
        actions: [
          SizedBox(
            width: 100,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("TUTUP", style: TextStyle(color: Colors.grey)),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A3A3),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(context);
                _printReceipt(orderId, orderData, paymentMethod);
              },
              child: const Text("CETAK"),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _printReceipt(String orderId, Map<String, dynamic> orderData, String paymentMethod) async {
    try {
      final outletName = _outletData?['name'] ?? 'Outlet';
      final outletAddress = _outletData?['alamat'] ?? '';
      final date = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
      final customerName = orderData['customerName'] ?? 'Guest';
      final tableNumber = orderData['tableNumber'] ?? '-';
      final List<dynamic> items = orderData['items'] ?? [];
      final subtotal = orderData['subTotal'] ?? orderData['totalAmount'] ?? 0;
      final tax = orderData['tax'] ?? 0;
      final total = orderData['totalAmount'] ?? 0;

      String receiptHtml = '''
<!DOCTYPE html>
<html>
<head>
  <style>
    @page { size: 80mm auto; margin: 0; }
    body { font-family: 'Courier New', monospace; font-size: 12px; width: 80mm; padding: 5mm; margin: 0; }
    .center { text-align: center; }
    .line { border-top: 1px dashed #000; margin: 5px 0; }
    .item-row { display: flex; justify-content: space-between; margin: 2px 0; }
  </style>
</head>
<body>
  <div class="center" style="font-weight:bold">$outletName</div>
  <div class="center" style="font-size:10px">$outletAddress</div>
  <div class="line"></div>
  <div>Tgl: $date</div>
  <div>Meja: $tableNumber</div>
  <div>Plg: $customerName</div>
  <div class="line"></div>
''';

      for (var item in items) {
        receiptHtml += '''
  <div class="item-row">
    <span>${item['quantity']}x ${item['name']}</span>
    <span>${currencyFormatter.format(item['total'] ?? 0)}</span>
  </div>''';
      }

      receiptHtml += '''
  <div class="line"></div>
  <div class="item-row"><span>Subtotal</span><span>${currencyFormatter.format(subtotal)}</span></div>
  <div class="item-row"><span>Pajak</span><span>${currencyFormatter.format(tax)}</span></div>
  <div class="item-row" style="font-weight:bold"><span>TOTAL</span><span>${currencyFormatter.format(total)}</span></div>
  <div class="line"></div>
  <div class="center">Bayar: $paymentMethod</div>
  <div class="center" style="margin-top:10px">Terima Kasih</div>
  <script>window.onload = function() { window.print(); }</script>
</body>
</html>''';

      if (kIsWeb) {
        final blob = html.Blob([receiptHtml], 'text/html');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.window.open(url, '_blank');
        html.Url.revokeObjectUrl(url);
      }
    } catch (e) {
      debugPrint("Print error: $e");
    }
  }

  Color _getStatusColor(String status, String? activeOrderId) {
    return (status.toLowerCase() == 'terisi' || activeOrderId != null) ? Colors.redAccent : Colors.green;
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

          if (docs.isEmpty) return const Center(child: Text('Belum ada meja.'));

          return GridView.builder(
            padding: const EdgeInsets.all(24),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 180,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final String firestoreId = doc.id;
              final String status = data['status'] ?? 'tersedia';
              final String displayTableNumber = (data['tableNumber'] ?? data['number'] ?? (index + 1)).toString();
              final String? activeOrderId = data['activeOrderId'];

              return InkWell(
                onTap: () => _handleTableAction(firestoreId, displayTableNumber, status, activeOrderId),
                child: Container(
                  decoration: BoxDecoration(
                    color: _getStatusColor(status, activeOrderId),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.table_bar_rounded, color: Colors.white, size: 48),
                      Text("Meja $displayTableNumber", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text(status.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10)),
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
    if (status.toLowerCase() == 'terisi' || orderId != null) {
      _showOccupiedMenu(id, nomor, orderId);
    } else {
      _showAvailableMenu(id, nomor);
    }
  }

  void _showOccupiedMenu(String id, String nomor, String? orderId) async {
    Map<String, dynamic>? orderData;
    if (orderId != null && orderId.isNotEmpty) {
      try {
        final doc = await FirebaseFirestore.instance.collection('transactions').doc(orderId).get();
        if (doc.exists) {
          orderData = doc.data();
          orderData?['orderId'] = orderId;
          if (orderData != null && !orderData.containsKey('totalAmount')) {
            orderData['totalAmount'] = orderData['grossAmount'] ?? 0;
          }
        }
      } catch (e) {
        debugPrint('Error: $e');
      }
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Meja $nomor", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            if (orderData != null) ...[
              const SizedBox(height: 12),
              Text("Pelanggan: ${orderData['customerName'] ?? '-'}", style: const TextStyle(color: Colors.black54)),
              const Divider(height: 32),
              ...(orderData['items'] as List).map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${item['quantity']}x ${item['name']}", style: const TextStyle(fontSize: 15)),
                    Text(currencyFormatter.format(item['total'] ?? 0), style: const TextStyle(fontSize: 15)),
                  ],
                ),
              )),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("TOTAL", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(currencyFormatter.format(orderData['totalAmount']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF00A3A3))),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A3A3),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _showPaymentSelectionDialog(orderData!, id);
                },
                child: const Text("PROSES BAYAR", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ] else
              const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Text("Pesanan tidak ditemukan.", style: TextStyle(color: Colors.red))),
            const SizedBox(height: 12),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                side: const BorderSide(color: Colors.red),
              ),
              onPressed: () async {
                await FirebaseFirestore.instance.collection('meja').doc(id).update({'status': 'tersedia', 'activeOrderId': null});
                if (mounted) Navigator.pop(context);
              },
              child: const Text("KOSONGKAN MEJA", style: TextStyle(color: Colors.red, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAvailableMenu(String id, String nomor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text("Meja $nomor"),
        content: const Text("Buka meja ini?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("BATAL", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A3A3),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('meja').doc(id).update({'status': 'terisi'});
              if (mounted) Navigator.pop(context);
            },
            child: const Text("BUKA"),
          ),
        ],
      ),
    );
  }
}