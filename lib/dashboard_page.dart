import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:proyekpos2/daftarMaster/daftarKaryawan_page.dart';
import 'package:proyekpos2/daftarMaster/daftarStok_page.dart';
import 'package:proyekpos2/laporan/detailPenjualan_page.dart';
import 'package:proyekpos2/laporan/laporanPelanggan_page.dart';
import 'package:proyekpos2/laporan/penjualanKategori_page.dart';
import 'package:proyekpos2/laporan/penjualanProduk_page.dart';
import 'package:proyekpos2/laporan/ringkasanPenjualan_page.dart';
import 'template/dashboard_layout.dart';
import 'profile_page.dart';
import 'daftarMaster/daftarProduk_page.dart';
import 'daftarMaster/daftarKategori_page.dart';
import 'daftarMaster/daftarPelanggan_page.dart';
import 'daftarMaster/daftarKupon_page.dart';
import 'daftarMaster/daftarOutlet_page.dart';
import 'profileBusiness_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kashierku Dashboard',
      theme: ThemeData(
        primaryColor: const Color(0xFF279E9E),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        fontFamily: 'Inter',
      ),
      debugShowCheckedModeBanner: false,
      home: const DashboardHost(),
    );
  }
}

class DashboardHost extends StatefulWidget {
  const DashboardHost({super.key});

  @override
  State<DashboardHost> createState() => _DashboardHostState();
}

class _DashboardHostState extends State<DashboardHost> {
  Widget _currentPage = const DashboardContent();
  String _currentRouteName = 'Dashboard';
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshDataAndState();
  }

  Future<void> _checkAndSetInitialOutlet(
      DocumentReference userRef, Map<String, dynamic> data, String userId) async {
    String? activeId = data['activeOutletId'] as String?;

    if (activeId == null || activeId.isEmpty) {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('outlets')
          .where('userId', isEqualTo: userId)
          .get();

      if (querySnapshot.docs.length == 1) {
        try {
          final firstOutletDoc = querySnapshot.docs.first;
          final firstOutletData =
          firstOutletDoc.data() as Map<String, dynamic>;
          final String firstOutletId = firstOutletDoc.id;
          final String firstOutletName =
              firstOutletData['name'] ?? 'Bisnis Anda';

          if (firstOutletId.isNotEmpty) {
            await userRef.update({
              'activeOutletId': firstOutletId,
              'businessName': firstOutletName,
            });

            data['activeOutletId'] = firstOutletId;
            data['businessName'] = firstOutletName;
          }
        } catch (e) {
          debugPrint("Error auto-setting active outlet: $e");
        }
      }
    }
  }

  Future<void> _refreshDataAndState() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
        final doc = await userRef.get();
        if (doc.exists && mounted) {
          Map<String, dynamic> data = doc.data()!;

          await _checkAndSetInitialOutlet(userRef, data, user.uid);

          setState(() {
            _userData = data;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _handleNavigation(_currentRouteName);
      }
    }
  }

  Future<void> _fetchUserData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
        final doc = await userRef.get();
        if (doc.exists && mounted) {
          Map<String, dynamic> data = doc.data()!;

          await _checkAndSetInitialOutlet(userRef, data, user.uid);

          setState(() {
            _userData = data;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleProfileBusinessUpdate() async {
    await _fetchUserData();
    if (mounted) {
      _handleNavigation('Dashboard');
    }
  }

  void _handleNavigation(String route) {
    final String? activeOutletId = _userData?['activeOutletId'];
    final Map<String, dynamic>? currentData = _userData;

    if (_isLoading && _userData == null) {
      _currentPage = const Center(child: CircularProgressIndicator());
      return;
    }

    const Widget noOutletSelected = Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Text(
          "Silakan pilih outlet terlebih dahulu dari menu di sidebar.",
          style: TextStyle(fontSize: 18, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ),
    );

    setState(() {
      _currentRouteName = route;
      switch (route) {
        case 'Dashboard':
          _currentPage = (activeOutletId != null)
              ? const DashboardContent()
              : noOutletSelected;
          break;

        case 'Daftar Produk':
          _currentPage = (activeOutletId != null)
              ? DaftarProdukPage(outletId: activeOutletId)
              : noOutletSelected;
          break;
        case 'Daftar Kategori':
          _currentPage = (activeOutletId != null)
              ? DaftarKategoriPage(outletId: activeOutletId)
              : noOutletSelected;
          break;
        case 'Daftar Kupon':
          _currentPage = (activeOutletId != null)
              ? DaftarKuponPage(outletId: activeOutletId)
              : noOutletSelected;
          break;
        case 'Daftar Karyawan':
          _currentPage = (activeOutletId != null)
              ? DaftarKaryawanPage(outletId: activeOutletId)
              : noOutletSelected;
          break;
        case 'Daftar Stok':
          _currentPage = (activeOutletId != null)
              ? DaftarStokPage(outletId: activeOutletId)
              : noOutletSelected;
          break;
        case 'Ringkasan Penjualan':
          _currentPage = (activeOutletId != null)
              ? const RingkasanPenjualanPage()
              : noOutletSelected;
          break;
        case 'Detail Penjualan':
          _currentPage = (activeOutletId != null)
              ? const DetailPenjualanPage()
              : noOutletSelected;
          break;
        case 'Penjualan Produk':
          _currentPage = (activeOutletId != null)
              ? const PenjualanProdukPage()
              : noOutletSelected;
          break;
        case 'Penjualan Kategori':
          _currentPage = (activeOutletId != null)
              ? const PenjualanKategoriPage()
              : noOutletSelected;
          break;
        case 'Laporan Pelanggan':
          _currentPage = (activeOutletId != null)
              ? const LaporanPelangganPage()
              : noOutletSelected;
          break;

        case 'Daftar Pelanggan':
          _currentPage = (activeOutletId != null)
              ? DaftarPelangganPage(outletId: activeOutletId)
              : noOutletSelected;
          break;
        case 'Daftar Outlet':
          _currentPage = const DaftarOutletPage();
          break;

        case 'Profile':
          _currentPage = ProfilePage(
            userData: currentData ?? {},
            onProfileUpdated: _fetchUserData,
          );
          break;
        case 'Pengaturan Bisnis':
          _currentPage = (activeOutletId != null && currentData != null)
              ? ProfileBusinessPage(
            userData: currentData,
            outletId: activeOutletId,
            onProfileUpdated: _handleProfileBusinessUpdate,
          )
              : noOutletSelected;
          break;

        default:
          _currentPage = (activeOutletId != null)
              ? const DashboardContent()
              : noOutletSelected;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      userData: _userData,
      isLoading: _isLoading,
      onNavigate: _handleNavigation,
      onRefreshUserData: _refreshDataAndState,
      child: _currentPage,
    );
  }
}

class DashboardContent extends StatelessWidget {
  const DashboardContent({super.key});
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard Penjualan',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333)),
          ),
          const SizedBox(height: 4),
          Text(
            'Diperbarui 10 Oktober 2025, 21:57',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 24),
          const FilterButtons(),
          const SizedBox(height: 24),
          _buildStatsGrid(),
          const SizedBox(height: 24),
          const MainSalesChart(),
          const SizedBox(height: 24),
          const PurchasesChart(),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final List<Map<String, dynamic>> stats = [
      {
        'title': 'Total Pendapatan',
        'value': 'Rp 1.250.000',
        'chart': const SmallLineChart(isPositive: true)
      },
      {
        'title': 'Total Penjualan',
        'value': 'Rp 875.000',
        'chart': const SmallLineChart(isPositive: false)
      },
      {'title': 'Jumlah Transaksi Hari Ini', 'value': '42', 'chart': null},
      {'title': 'Produk Terjual', 'value': '112', 'chart': null},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 320,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 1.2,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return StatCard(
          title: stat['title'],
          value: stat['value'],
          chart: stat['chart'],
        );
      },
    );
  }
}

class FilterButtons extends StatefulWidget {
  const FilterButtons({super.key});
  @override
  State<FilterButtons> createState() => _FilterButtonsState();
}

class _FilterButtonsState extends State<FilterButtons> {
  int _selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildFilterButton('Harian', 0),
        const SizedBox(width: 8),
        _buildFilterButton('Mingguan', 1),
        const SizedBox(width: 8),
        _buildFilterButton('Bulan', 2),
      ],
    );
  }

  Widget _buildFilterButton(String text, int index) {
    final isSelected = _selectedIndex == index;
    return ElevatedButton(
      onPressed: () => setState(() => _selectedIndex = index),
      style: ElevatedButton.styleFrom(
        foregroundColor: isSelected ? Colors.white : const Color(0xFF279E9E),
        backgroundColor: isSelected ? const Color(0xFF279E9E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
      child: Text(text),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Widget? chart;

  const StatCard(
      {super.key, required this.title, required this.value, this.chart});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              maxLines: 1,
            ),
          ),
          if (chart != null)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: chart,
              ),
            ),
        ],
      ),
    );
  }
}

class MainSalesChart extends StatelessWidget {
  const MainSalesChart({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
        height: 350,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Penjualan 10 Oktober 2025',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            OutlinedButton(
              onPressed: () {},
              child: const Text('Lihat Detail'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[700],
                side: BorderSide(color: Colors.grey[300]!),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            )
          ]),
          const SizedBox(height: 20),
          Expanded(
              child: LineChart(LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              interval: 4,
                              getTitlesWidget: _bottomTitleWidgets)),
                      leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: _leftTitleWidgets))),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 1),
                        FlSpot(4, 1.2),
                        FlSpot(8, 2),
                        FlSpot(12, 3),
                        FlSpot(16, 2.9),
                        FlSpot(20, 2.2),
                        FlSpot(23, 3.2)
                      ],
                      isCurved: true,
                      color: const Color(0xFF279E9E),
                      barWidth: 4,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                            colors: [
                              const Color(0xFF279E9E).withOpacity(0.3),
                              const Color(0xFF279E9E).withOpacity(0.0)
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter),
                      ),
                    ),
                  ])))
        ]));
  }
}

class PurchasesChart extends StatelessWidget {
  const PurchasesChart({super.key});
  @override
  Widget build(BuildContext context) {
    const purchaseColor = Colors.blueAccent;
    return Container(
        height: 350,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Pembelian 10 Oktober 2025',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            OutlinedButton(
              onPressed: () {},
              child: const Text('Lihat Detail'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[700],
                side: BorderSide(color: Colors.grey[300]!),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            )
          ]),
          const SizedBox(height: 20),
          Expanded(
              child: LineChart(LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              interval: 4,
                              getTitlesWidget: _bottomTitleWidgets)),
                      leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: _leftTitleWidgets))),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 0.8),
                        FlSpot(4, 1.0),
                        FlSpot(8, 1.8),
                        FlSpot(12, 1.5),
                        FlSpot(16, 2.5),
                        FlSpot(20, 2.1),
                        FlSpot(23, 2.8)
                      ],
                      isCurved: true,
                      color: purchaseColor,
                      barWidth: 4,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                            colors: [
                              purchaseColor.withOpacity(0.3),
                              purchaseColor.withOpacity(0.0)
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter),
                      ),
                    ),
                  ])))
        ]));
  }
}

class SmallLineChart extends StatelessWidget {
  final bool isPositive;
  const SmallLineChart({super.key, required this.isPositive});

  @override
  Widget build(BuildContext context) {
    final color = isPositive ? Colors.green : Colors.red;
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: isPositive
                ? const [FlSpot(0, 1), FlSpot(1, 1.5), FlSpot(3, 2)]
                : const [FlSpot(0, 2), FlSpot(1, 1.5), FlSpot(3, 1.2)],
            isCurved: true,
            color: color,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _bottomTitleWidgets(double value, TitleMeta meta) {
  const style = TextStyle(color: Colors.grey, fontSize: 12);
  String text;
  switch (value.toInt()) {
    case 0:
      text = '00:00';
      break;
    case 4:
      text = '04:00';
      break;
    case 8:
      text = '08:00';
      break;
    case 12:
      text = '12:00';
      break;
    case 16:
      text = '16:00';
      break;
    case 20:
      text = '20:00';
      break;
    default:
      return Container();
  }
  return SideTitleWidget(
      axisSide: meta.axisSide, space: 10, child: Text(text, style: style));
}

Widget _leftTitleWidgets(double value, TitleMeta meta) {
  const style = TextStyle(color: Colors.grey, fontSize: 12);
  String text;
  switch (value.toInt()) {
    case 0:
      text = '0';
      break;
    case 1:
      text = '1 Jt';
      break;
    case 2:
      text = '2 Jt';
      break;
    case 3:
      text = '3 Jt';
      break;
    default:
      return Container();
  }
  return Text(text, style: style, textAlign: TextAlign.center);
}