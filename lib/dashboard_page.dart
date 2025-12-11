import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:proyekpos2/karyawan/daftarAbsensi_page.dart';
import 'package:proyekpos2/daftarMaster/daftarKaryawan_page.dart';
import 'package:proyekpos2/daftarMaster/daftarStok_page.dart';
import 'package:proyekpos2/karyawan/manajemenGaji_page.dart';
import 'package:proyekpos2/laporan/detailPembelian_page.dart';
import 'package:proyekpos2/laporan/detailPenjualan_page.dart';
import 'package:proyekpos2/laporan/laporanKaryawan_page.dart';
import 'package:proyekpos2/laporan/laporanNeraca_page.dart';
import 'package:proyekpos2/laporan/laporanPelanggan_page.dart';
import 'package:proyekpos2/laporan/penjualanKategori_page.dart';
import 'package:proyekpos2/laporan/penjualanPerPeriode_page.dart';
import 'package:proyekpos2/laporan/penjualanProduk_page.dart';
import 'package:proyekpos2/laporan/ringkasanPembelian_page.dart';
import 'package:proyekpos2/laporan/ringkasanPenjualan_page.dart';
import 'package:proyekpos2/daftarMaster/pengeluaran_page.dart';
import 'package:proyekpos2/service/api_service.dart';
import 'template/dashboard_layout.dart';
import 'profile/profile_page.dart';
import 'daftarMaster/daftarProduk_page.dart';
import 'daftarMaster/daftarKategori_page.dart';
import 'daftarMaster/daftarPelanggan_page.dart';
import 'daftarMaster/daftarKupon_page.dart';
import 'daftarMaster/daftarOutlet_page.dart';
import 'profile/profileBusiness_page.dart';

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
  Widget _currentPage = const Center(child: CircularProgressIndicator());
  String _currentRouteName = 'Dashboard';
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshDataAndState();
  }

  Future<void> _checkAndSetInitialOutlet(DocumentReference userRef,
      Map<String, dynamic> data, String userId) async {
    try {
      String? activeId = data['activeOutletId'] as String?;

      if (activeId == null || activeId.isEmpty) {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('outlets')
            .where('userId', isEqualTo: userId)
            .get();

        if (querySnapshot.docs.length == 1) {
          final firstOutletDoc = querySnapshot.docs.first;
          final firstOutletData = firstOutletDoc.data();
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
        }
      }
    } catch (e) {
      debugPrint("Error auto-setting active outlet: $e");
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

          if (mounted) {
            setState(() {
              _userData = data;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _userData = {};
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _userData = null;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
      if (mounted) {
        setState(() {
          _userData = {};
        });
      }
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

          if (mounted) {
            setState(() {
              _userData = data;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _userData = {};
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
      if (mounted) {
        setState(() {
          _userData = {};
        });
      }
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
      setState(() {
        _currentPage = const Center(child: CircularProgressIndicator());
      });
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
              ? DashboardContent(
            outletId: activeOutletId,
            onNavigate: _handleNavigation,
          )
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
        case 'Daftar Bahan Baku':
          _currentPage = (activeOutletId != null)
              ? DaftarStokPage(outletId: activeOutletId)
              : noOutletSelected;
          break;
        case 'Ringkasan Penjualan':
          _currentPage = (activeOutletId != null)
              ? RingkasanPenjualanPage(outletId: activeOutletId)
              : noOutletSelected;
          break;
        case 'Detail Penjualan':
          _currentPage = (activeOutletId != null)
              ? DetailPenjualanPage(outletId: activeOutletId)
              : noOutletSelected;
          break;
        case 'Penjualan Per Periode':
          _currentPage = (activeOutletId != null)
              ? LaporanPenjualanPerPeriodePage(outletId: activeOutletId)
              : noOutletSelected;
          break;
        case 'Penjualan Produk':
          _currentPage = (activeOutletId != null)
              ? PenjualanProdukPage(outletId: activeOutletId)
              : noOutletSelected;
          break;
        case 'Penjualan Kategori':
          _currentPage = (activeOutletId != null)
              ? PenjualanKategoriPage(outletId: activeOutletId)
              : noOutletSelected;
          break;
        case 'Ringkasan Pembelian':
          _currentPage = (activeOutletId != null)
              ? RingkasanPembelianPage(outletId: activeOutletId)
              : noOutletSelected;
          break;
        case 'Detail Pembelian':
          _currentPage = (activeOutletId != null)
              ? DetailPembelianPage(outletId: activeOutletId)
              : noOutletSelected;
        case 'Laporan Pelanggan':
          _currentPage = (activeOutletId != null)
              ? LaporanPelangganPage(outletId: activeOutletId)
              : noOutletSelected;
          break;
        case 'Laporan Karyawan':
          _currentPage = (activeOutletId != null)
              ? LaporanKaryawanPage(outletId: activeOutletId)
              : noOutletSelected;
          break;
        case 'Laporan Neraca':
          _currentPage = (activeOutletId != null)
              ? LaporanNeracaPage(outletId: activeOutletId)
              :noOutletSelected;
          break;
        case 'Daftar Pengeluaran':
          _currentPage = (activeOutletId != null)
              ? PengeluaranPage(outletId: activeOutletId)
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
        case 'Daftar Absensi':
          _currentPage = (activeOutletId != null)
              ? DaftarAbsensiPage(outletId: activeOutletId)
              : noOutletSelected;
          break;
        case 'Manajemen Gaji':
          _currentPage = (activeOutletId != null)
              ? ManajemenGajiPage(outletId: activeOutletId)
              : noOutletSelected;
          break;
        default:
          _currentPage = (activeOutletId != null)
              ? DashboardContent(
            outletId: activeOutletId,
            onNavigate: _handleNavigation,
          )
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

class DashboardContent extends StatefulWidget {
  final String outletId;
  final Function(String) onNavigate;

  const DashboardContent({
    super.key,
    required this.outletId,
    required this.onNavigate,
  });

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  final ApiService _apiService = ApiService();
  int _selectedFilterIndex = 0;
  bool _isLoading = true;

  double _totalPendapatan = 0;
  double _totalPengeluaran = 0;
  int _jumlahTransaksi = 0;
  int _produkTerjual = 0;

  List<FlSpot> _salesSpots = [];
  List<FlSpot> _purchasesSpots = [];
  double _maxYSales = 3;
  double _maxYPurchases = 3;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  @override
  void didUpdateWidget(covariant DashboardContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.outletId != widget.outletId) {
      _fetchDashboardData();
    }
  }

  double _parseSafeDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  int _parseSafeInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      DateTime startDate;
      DateTime endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

      if (_selectedFilterIndex == 0) {
        startDate = DateTime(now.year, now.month, now.day, 0, 0, 0);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
      } else if (_selectedFilterIndex == 1) {
        startDate = DateTime(now.year, now.month, now.day, 0, 0, 0).subtract(const Duration(days: 7));
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
      } else {
        startDate = DateTime(now.year, now.month, 1, 0, 0, 0);
        endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      }

      final transactions = await _apiService.getSalesDetail(
        outletId: widget.outletId,
        startDate: startDate,
        endDate: endDate,
      );

      double tempRevenue = 0;
      int tempTxCount = 0;
      int tempSold = 0;

      Map<int, double> salesByHour = {};
      for (int i = 0; i < 24; i++) {
        salesByHour[i] = 0;
      }

      for (var tx in transactions) {
        String? status = tx['status'];

        if (status == 'success' || status == 'settlement' || status == 'capture' || status == null) {
          double amount = _parseSafeDouble(tx['grossAmount'] ?? tx['gross_amount']);
          tempRevenue += amount;
          tempTxCount++;

          if (tx['items'] != null && tx['items'] is List) {
            for (var item in tx['items']) {
              tempSold += _parseSafeInt(item['quantity'] ?? item['qty']);
            }
          }

          try {
            DateTime txDate;

            if (tx['timestamp'] != null) {
              if (tx['timestamp'] is int) {
                txDate = DateTime.fromMillisecondsSinceEpoch(tx['timestamp']);
              } else if (tx['timestamp'] is DateTime) {
                txDate = tx['timestamp'];
              } else {
                txDate = DateTime.parse(tx['timestamp'].toString());
              }
            } else if (tx['date'] != null) {
              if (tx['date'] is String) {
                txDate = DateTime.parse(tx['date']);
              } else if (tx['date'] is DateTime) {
                txDate = tx['date'];
              } else {
                continue;
              }
            } else {
              continue;
            }

            int hour = txDate.hour;
            salesByHour[hour] = (salesByHour[hour] ?? 0) + (amount / 1000000);
          } catch (e) {
            debugPrint("Error parsing transaction date: $e");
          }
        }
      }

      final rawMaterials = await _apiService.getRawMaterials(widget.outletId);

      double tempExpenses = 0;
      Map<int, double> purchasesByHour = {};
      for (int i = 0; i < 24; i++) {
        purchasesByHour[i] = 0;
      }

      for (var material in rawMaterials) {
        if (material['date'] != null) {
          try {
            DateTime matDate;

            if (material['date'] is String) {
              matDate = DateTime.parse(material['date']);
            } else if (material['date'] is DateTime) {
              matDate = material['date'];
            } else {
              continue;
            }

            final matDateOnly = DateTime.utc(matDate.year, matDate.month, matDate.day);
            final startDateOnly = DateTime.utc(startDate.year, startDate.month, startDate.day);
            final endDateOnly = DateTime.utc(endDate.year, endDate.month, endDate.day);

            final isInRange = matDateOnly.millisecondsSinceEpoch >= startDateOnly.millisecondsSinceEpoch &&
                matDateOnly.millisecondsSinceEpoch <= endDateOnly.millisecondsSinceEpoch;


            if (isInRange) {
              double price = _parseSafeDouble(material['price']);
              tempExpenses += price;

              int hour = matDate.hour;
              purchasesByHour[hour] = (purchasesByHour[hour] ?? 0) + (price / 1000000);
            }
          } catch (e) {
            debugPrint("Error parsing material date: $e");
          }
        } else {
        }
      }

      List<FlSpot> salesSpots = [];
      List<FlSpot> purchasesSpots = [];
      double maxSales = 0;
      double maxPurchases = 0;

      for (int hour = 0; hour < 24; hour++) {
        double salesValue = salesByHour[hour] ?? 0;
        double purchasesValue = purchasesByHour[hour] ?? 0;

        salesSpots.add(FlSpot(hour.toDouble(), salesValue));
        purchasesSpots.add(FlSpot(hour.toDouble(), purchasesValue));

        if (salesValue > maxSales) maxSales = salesValue;
        if (purchasesValue > maxPurchases) maxPurchases = purchasesValue;
      }

      if (mounted) {
        setState(() {
          _totalPendapatan = tempRevenue;
          _jumlahTransaksi = tempTxCount;
          _produkTerjual = tempSold;
          _totalPengeluaran = tempExpenses;
          _salesSpots = salesSpots;
          _purchasesSpots = purchasesSpots;
          _maxYSales = maxSales > 0 ? (maxSales * 1.2).ceilToDouble() : 3;
          _maxYPurchases = maxPurchases > 0 ? (maxPurchases * 1.2).ceilToDouble() : 3;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading dashboard data: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat('d MMMM y, HH:mm', 'id_ID').format(now);

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
            'Diperbarui $dateStr',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 24),
          FilterButtons(
            selectedIndex: _selectedFilterIndex,
            onChanged: (index) {
              setState(() {
                _selectedFilterIndex = index;
              });
              _fetchDashboardData();
            },
          ),
          const SizedBox(height: 24),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            _buildStatsGrid(),
          const SizedBox(height: 24),
          MainSalesChart(
            onSeeDetails: () {
              widget.onNavigate('Detail Penjualan');
            },
            salesSpots: _salesSpots,
            maxY: _maxYSales,
          ),
          const SizedBox(height: 24),
          PurchasesChart(
            onSeeDetails: () {
              widget.onNavigate('Daftar Stok');
            },
            purchasesSpots: _purchasesSpots,
            maxY: _maxYPurchases,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final List<Map<String, dynamic>> stats = [
      {
        'title': 'Total Pendapatan',
        'value': _formatCurrency(_totalPendapatan),
        'isBigNumber': false,
      },
      {
        'title': 'Total Pengeluaran',
        'value': _formatCurrency(_totalPengeluaran),
        'isBigNumber': false,
      },
      {
        'title': 'Jumlah Transaksi',
        'value': '$_jumlahTransaksi',
        'chart': null,
        'isBigNumber': true,
      },
      {
        'title': 'Produk Terjual',
        'value': '$_produkTerjual',
        'chart': null,
        'isBigNumber': true,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 320,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 1.4,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return StatCard(
          title: stat['title'],
          value: stat['value'],
          chart: stat['chart'],
          isBigNumber: stat['isBigNumber'] ?? false,
        );
      },
    );
  }
}

class FilterButtons extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onChanged;

  const FilterButtons({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

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
    final isSelected = selectedIndex == index;
    return ElevatedButton(
      onPressed: () => onChanged(index),
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
  final bool isBigNumber;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.chart,
    this.isBigNumber = false,
  });

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
              style: TextStyle(
                fontSize: isBigNumber ? 32 : 28,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF333333),
              ),
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
  final VoidCallback onSeeDetails;
  final List<FlSpot> salesSpots;
  final double maxY;

  const MainSalesChart({
    super.key,
    required this.onSeeDetails,
    required this.salesSpots,
    required this.maxY,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 350,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Penjualan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              OutlinedButton(
                onPressed: onSeeDetails,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Lihat Detail'),
              )
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: salesSpots.isEmpty
                ? const Center(child: Text('Tidak ada data penjualan'))
                : LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 4,
                      getTitlesWidget: _bottomTitleWidgets,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => _leftTitleWidgets(value, meta, maxY),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: salesSpots,
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
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class PurchasesChart extends StatelessWidget {
  final VoidCallback onSeeDetails;
  final List<FlSpot> purchasesSpots;
  final double maxY;

  const PurchasesChart({
    super.key,
    required this.onSeeDetails,
    required this.purchasesSpots,
    required this.maxY,
  });

  @override
  Widget build(BuildContext context) {
    const purchaseColor = Colors.blueAccent;
    return Container(
        height: 350,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Pembelian',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            OutlinedButton(
              onPressed: onSeeDetails,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[700],
                side: BorderSide(color: Colors.grey[300]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Lihat Detail'),
            )
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
        child: purchasesSpots.isEmpty
        ? const Center(child: Text('Tidak ada data pembelian'))
        : LineChart(
    LineChartData(
    gridData: const FlGridData(show: false),
    titlesData: FlTitlesData(
    topTitles: const AxisTitles(
    sideTitles: SideTitles(showTitles: false),
    ),
    rightTitles: const AxisTitles(
    sideTitles: SideTitles(showTitles: false),
    ),
    bottomTitles: AxisTitles(
    sideTitles: SideTitles(
      showTitles: true,
      reservedSize: 30,
      interval: 4,
      getTitlesWidget: _bottomTitleWidgets,
    ),
    ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          getTitlesWidget: (value, meta) => _leftTitleWidgets(value, meta, maxY),
        ),
      ),
    ),
      borderData: FlBorderData(show: false),
      minY: 0,
      maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          spots: purchasesSpots,
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
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    ),
        ),
        )
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
    axisSide: meta.axisSide,
    space: 10,
    child: Text(text, style: style),
  );
}

Widget _leftTitleWidgets(double value, TitleMeta meta, double maxY) {
  const style = TextStyle(color: Colors.grey, fontSize: 12);

  if (value == 0) {
    return const Text('0', style: style, textAlign: TextAlign.center);
  }

  if (maxY <= 1) {
    if (value == 0.5) {
      return const Text('500K', style: style, textAlign: TextAlign.center);
    } else if (value == 1) {
      return const Text('1 Jt', style: style, textAlign: TextAlign.center);
    }
  } else if (maxY <= 3) {
    if (value == 1) {
      return const Text('1 Jt', style: style, textAlign: TextAlign.center);
    } else if (value == 2) {
      return const Text('2 Jt', style: style, textAlign: TextAlign.center);
    } else if (value == 3) {
      return const Text('3 Jt', style: style, textAlign: TextAlign.center);
    }
  } else {
    int interval = (maxY / 3).ceil();
    if (value % interval == 0 && value != 0) {
      return Text(
        '${(value).toInt()} Jt',
        style: style,
        textAlign: TextAlign.center,
      );
    }
  }

  return Container();
}