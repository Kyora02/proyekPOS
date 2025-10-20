import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'template/dashboard_layout.dart';
import 'profile_page.dart';
import 'daftarProduk_page.dart';
import 'daftarKategori_page.dart';
import 'daftarPelanggan_page.dart';
import 'daftarKupo_page.dart';
import 'daftarTambahKupon_page.dart';
import 'daftarOutlet_page.dart';

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
  Widget _currentPage = const DashboardContent(); // The current page content
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    // Fetches data only ONCE
    if (!mounted) return;
    setState(() { _isLoading = true; });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && mounted) {
          setState(() { _userData = doc.data(); });
        }
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  void _handleNavigation(String route) {
    setState(() {
      switch (route) {
        case 'Dashboard':
          _currentPage = const DashboardContent();
          break;
        case 'Daftar Produk':
          _currentPage = const DaftarProdukPage();
          break;
        case 'Daftar Kategori':
          _currentPage = const DaftarKategoriPage();
          break;
        case 'Profile':
          if (_userData != null) {
            _currentPage = ProfilePage(
              userData: _userData!,
              onProfileUpdated: _fetchUserData,
            );
          }
          break;
        case 'Daftar Pelanggan':
          _currentPage = const DaftarPelangganPage();
          break;
        case 'Daftar Kupon':
          _currentPage = const DaftarKuponPage();
          break;
        case 'Tambah Kupon':
          _currentPage = const DaftarTambahKuponPage();
          break;
        case 'Daftar Outlet':
          _currentPage = const DaftarOutletPage();
          break;
        default:
          _currentPage = const DashboardContent();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      userData: _userData,
      isLoading: _isLoading,
      onNavigate: _handleNavigation,
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
        childAspectRatio: 1.8,
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          const SizedBox(height: 8),
          Text(value,
              style:
              const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          if (chart != null)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: SizedBox(height: 40, child: chart),
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