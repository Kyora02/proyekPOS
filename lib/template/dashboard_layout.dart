import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardLayout extends StatefulWidget {
  final Widget child;
  final Function(String) onNavigate;
  final Map<String, dynamic>? userData;
  final bool isLoading;
  final VoidCallback onRefreshUserData;

  const DashboardLayout({
    super.key,
    required this.child,
    required this.onNavigate,
    required this.userData,
    required this.isLoading,
    required this.onRefreshUserData,
  });

  @override
  State<DashboardLayout> createState() => _DashboardLayoutState();
}

class _DashboardLayoutState extends State<DashboardLayout> {
  bool _isSidebarCollapsed = false;

  void _toggleSidebar() {
    setState(() {
      _isSidebarCollapsed = !_isSidebarCollapsed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth > 800;

        if (isDesktop) {
          return Scaffold(
            body: Row(
              children: [
                SideNavBar(
                  isCollapsed: _isSidebarCollapsed,
                  userData: widget.userData,
                  isLoading: widget.isLoading,
                  onNavigate: widget.onNavigate,
                  onRefreshUserData: widget.onRefreshUserData,
                ),
                Expanded(
                  child: Column(
                    children: [
                      TopAppBar(
                        onMenuPressed: _toggleSidebar,
                        isDesktop: true,
                        userData: widget.userData,
                        isLoading: widget.isLoading,
                        onProfileSettingsTap: () =>
                            widget.onNavigate('Profile'),
                        onBusinessSettingsTap: () =>
                            widget.onNavigate('Pengaturan Bisnis'),
                      ),
                      Expanded(
                        child: widget.child,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          return Scaffold(
            appBar: TopAppBar(
              isDesktop: false,
              userData: widget.userData,
              isLoading: widget.isLoading,
              onProfileSettingsTap: () => widget.onNavigate('Profile'),
              onBusinessSettingsTap: () =>
                  widget.onNavigate('Pengaturan Bisnis'),
            ),
            drawer: SideNavBar(
              isCollapsed: false,
              userData: widget.userData,
              isLoading: widget.isLoading,
              onNavigate: widget.onNavigate,
              onRefreshUserData: widget.onRefreshUserData,
            ),
            body: widget.child,
          );
        }
      },
    );
  }
}

class TopAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onMenuPressed;
  final bool isDesktop;
  final Map<String, dynamic>? userData;
  final bool isLoading;
  final VoidCallback onProfileSettingsTap;
  final GlobalKey _profileMenuKey = GlobalKey();
  final VoidCallback onBusinessSettingsTap;

  TopAppBar({
    super.key,
    this.onMenuPressed,
    required this.isDesktop,
    this.userData,
    required this.isLoading,
    required this.onProfileSettingsTap,
    required this.onBusinessSettingsTap,
  });

  void _showProfileMenu(BuildContext context) {
    final RenderBox renderBox =
    _profileMenuKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) {
        return Stack(
          children: [
            Positioned(
              top: offset.dy + size.height + 5,
              right: isDesktop
                  ? (MediaQuery.of(context).size.width -
                  offset.dx -
                  size.width)
                  : 5.0,
              left: isDesktop ? (offset.dx + size.width - 300) : null,
              child: FadeTransition(
                opacity: anim1,
                child: Material(
                  type: MaterialType.transparency,
                  child: ProfileMenuDialog(
                    userData: userData,
                    isLoading: isLoading,
                    onProfileSettingsTap: onProfileSettingsTap,
                    onBusinessSettingsTap: onBusinessSettingsTap,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String getInitials(String name) {
      if (name.isEmpty) return '?';
      List<String> names = name.split(" ");
      String initials = "";
      int numWords = names.length > 2 ? 2 : names.length;
      for (var i = 0; i < numWords; i++) {
        if (names[i].isNotEmpty) initials += names[i][0];
      }
      return initials.toUpperCase();
    }

    final String userName = userData?['name'] ?? 'Pengguna';
    final String userInitials = getInitials(userName);

    if (isDesktop) {
      return Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          border:
          Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1)),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.menu),
              color: Colors.grey[600],
              onPressed: onMenuPressed,
            ),
            const SizedBox(width: 16),
            const Text(
              'Kashierku',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF279E9E),
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.notifications_none_outlined),
              color: Colors.grey[600],
              onPressed: () {},
            ),
            const SizedBox(width: 16),
            UserProfile(
                isLoading: isLoading,
                userName: userName,
                userInitials: userInitials),
            const SizedBox(width: 8),
            IconButton(
              key: _profileMenuKey,
              icon: Icon(Icons.more_vert, color: Colors.grey[600]),
              onPressed: () => _showProfileMenu(context),
            ),
          ],
        ),
      );
    } else {
      return AppBar(
        title: const Text(
          'Kashierku',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF279E9E),
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF279E9E)),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined),
            color: Colors.grey[600],
            onPressed: () {
            },
          ),
          IconButton(
            key: _profileMenuKey,
            icon: Icon(Icons.more_vert, color: Colors.grey[600]),
            onPressed: () => _showProfileMenu(context),
          ),
          const SizedBox(width: 8),
        ],
      );
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(60.0);
}

class UserProfile extends StatelessWidget {
  final bool isLoading;
  final String userName;
  final String userInitials;
  const UserProfile(
      {super.key,
        required this.isLoading,
        required this.userName,
        required this.userInitials});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        isLoading
            ? const CircleAvatar(backgroundColor: Color(0xFF279E9E))
            : CircleAvatar(
          backgroundColor: const Color(0xFF279E9E),
          child: Text(userInitials,
              style: const TextStyle(color: Colors.white)),
        ),
        const SizedBox(width: 12),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isLoading ? 'Loading...' : userName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            Text(
              'Owner',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        )
      ],
    );
  }
}

class ProfileMenuDialog extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final bool isLoading;
  final VoidCallback onProfileSettingsTap;
  final VoidCallback onBusinessSettingsTap;

  const ProfileMenuDialog({
    super.key,
    required this.userData,
    required this.isLoading,
    required this.onProfileSettingsTap,
    required this.onBusinessSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    final String businessName = userData?['businessName'] ?? 'Bisnis Anda';
    final String userName = userData?['name'] ?? 'Pengguna';

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFF279E9E),
                  child: Icon(Icons.storefront, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isLoading ? 'Loading...' : businessName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        isLoading ? '...' : userName,
                        style:
                        TextStyle(color: Colors.grey[600], fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _ProfileMenuItem(
            text: 'Pengaturan Profil',
            onTap: () {
              Navigator.of(context).pop();
              onProfileSettingsTap();
            },
          ),
          _ProfileMenuItem(
            text: 'Pengaturan Bisnis',
            onTap: () {
              Navigator.of(context).pop();
              onBusinessSettingsTap();
            },
          ),
          const Divider(height: 1),
          _ProfileMenuItem(
            text: 'Keluar',
            onTap: () {
              Navigator.of(context).pop();
              FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuItem extends StatefulWidget {
  final String text;
  final VoidCallback onTap;

  const _ProfileMenuItem({required this.text, required this.onTap});

  @override
  State<_ProfileMenuItem> createState() => _ProfileMenuItemState();
}

class _ProfileMenuItemState extends State<_ProfileMenuItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          color: _isHovering
              ? const Color(0xFF279E9E).withOpacity(0.1)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Text(
                widget.text,
                style: const TextStyle(fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NavItem {
  final String title;
  final IconData icon;
  final List<NavItem> children;

  NavItem({required this.title, required this.icon, this.children = const []});
}

class NavListTile extends StatefulWidget {
  final bool isCollapsed;
  final NavItem item;
  final EdgeInsetsGeometry padding;
  final String selectedItem;
  final Function(String) onTap;

  const NavListTile({
    super.key,
    required this.isCollapsed,
    required this.item,
    required this.padding,
    required this.selectedItem,
    required this.onTap,
  });

  @override
  State<NavListTile> createState() => _NavListTileState();
}

class _NavListTileState extends State<NavListTile> {
  bool _isHovering = false;

  bool _isChildSelected(NavItem item, String selectedItem) {
    if (item.children.isEmpty) return false;
    bool containsSelected = false;
    for (var child in item.children) {
      if (child.title == selectedItem) {
        containsSelected = true;
        break;
      }
      if (child.children.isNotEmpty) {
        containsSelected = _isChildSelected(child, selectedItem);
        if (containsSelected) break;
      }
    }
    return containsSelected;
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    final bool isSelected = widget.selectedItem == item.title;

    final bool isChildSelected = _isChildSelected(item, widget.selectedItem);

    if (widget.isCollapsed) {
      return Tooltip(
        message: item.title,
        child: InkWell(
          onTap: () {
            widget.onTap(item.title);
          },
          child: Container(
            decoration: BoxDecoration(
              color: _isHovering
                  ? Colors.white.withOpacity(0.1)
                  : Colors.transparent,
              border: Border(
                right: BorderSide(
                  color: isSelected
                      ? const Color(0xFFFFC107)
                      : Colors.transparent,
                  width: 4.0,
                ),
              ),
            ),
            height: 48.0,
            child: Center(
              child: Icon(item.icon, color: Colors.white, size: 22),
            ),
          ),
        ),
      );
    }

    if (item.children.isEmpty) {
      return MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        child: Container(
          decoration: BoxDecoration(
            color: _isHovering
                ? Colors.white.withOpacity(0.1)
                : Colors.transparent,
            border: Border(
              right: BorderSide(
                color: isSelected
                    ? const Color(0xFFFFC107)
                    : Colors.transparent,
                width: 4.0,
              ),
            ),
          ),
          child: ListTile(
            contentPadding: widget.padding,
            leading: Icon(item.icon, color: Colors.white, size: 22),
            title: Text(item.title,
                style: const TextStyle(color: Colors.white, fontSize: 15)),
            onTap: () => widget.onTap(item.title),
          ),
        ),
      );
    }

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: PageStorageKey(item.title),
        initiallyExpanded: isChildSelected,
        tilePadding: widget.padding,
        leading: Icon(item.icon, color: Colors.white, size: 22),
        title: Text(item.title,
            style: const TextStyle(color: Colors.white, fontSize: 15)),
        trailing: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
        children: item.children.map((child) {
          final newPadding = EdgeInsets.only(
            left: (widget.padding as EdgeInsets).left + 24.0,
            right: (widget.padding as EdgeInsets).right,
          );

          return NavListTile(
            isCollapsed: widget.isCollapsed,
            item: child,
            padding: newPadding,
            selectedItem: widget.selectedItem,
            onTap: widget.onTap,
          );
        }).toList(),
      ),
    );
  }
}

class SideNavBar extends StatefulWidget {
  final bool isCollapsed;
  final Map<String, dynamic>? userData;
  final bool isLoading;
  final Function(String) onNavigate;
  final VoidCallback onRefreshUserData;

  const SideNavBar({
    super.key,
    required this.isCollapsed,
    this.userData,
    required this.isLoading,
    required this.onNavigate,
    required this.onRefreshUserData,
  });

  @override
  State<SideNavBar> createState() => _SideNavBarState();
}

class _SideNavBarState extends State<SideNavBar> {
  final GlobalKey _outletHeaderKey = GlobalKey();
  String _selectedItem = 'Dashboard';

  final List<NavItem> _navItems = [
    NavItem(title: 'Dashboard', icon: Icons.dashboard_rounded),
    NavItem(
      title: 'Laporan',
      icon: Icons.bar_chart_rounded,
      children: [
        NavItem(
            title: 'Laporan Penjualan',
            icon: Icons.point_of_sale,
            children: [
              NavItem(
                  title: 'Ringkasan Penjualan', icon: Icons.summarize_rounded),
              NavItem(
                  title: 'Detail Penjualan', icon: Icons.receipt_long_rounded),
              NavItem(
                  title: 'Penjualan Per Periode',
                  icon: Icons.date_range_outlined),
            ]),
        NavItem(
            title: 'Laporan Pembelian',
            icon: Icons.shopping_bag,
            children: [
              NavItem(
                  title: 'Ringkasan Pembelian',
                  icon: Icons.assessment_outlined),
              NavItem(
                  title: 'Detail Pembelian', icon: Icons.description_outlined)
            ]),
        NavItem(
            title: 'Laporan Produk',
            icon: Icons.inventory_2_rounded,
            children: [
              NavItem(title: 'Penjualan Produk', icon: Icons.sell_rounded),
              NavItem(
                  title: 'Penjualan Kategori', icon: Icons.category_rounded)
            ]),
        NavItem(
            title: 'Laporan Pelanggan',
            icon: Icons.people_alt_rounded,
            children: [
              NavItem(title: 'Laporan Pelanggan', icon: Icons.analytics_rounded)
            ]),
        NavItem(
            title: 'Laporan Karyawan',
            icon: Icons.people_alt_rounded,
            children: [
              NavItem(title: 'Absensi', icon: Icons.fingerprint_rounded)
            ]),
        NavItem(
            title: 'Laporan Keuangan',
            icon: Icons.balance,
            children: [
              NavItem(title: 'Laporan Neraca', icon: Icons.balance)
            ])
      ],
    ),
    NavItem(
      title: 'Produk',
      icon: Icons.inventory_2_rounded,
      children: [
        NavItem(title: 'Daftar Produk', icon: Icons.list_alt),
        NavItem(title: 'Daftar Kategori', icon: Icons.category),
      ],
    ),
    NavItem(
        title: 'Inventori',
        icon: Icons.inventory_2_rounded,
        children: [
          NavItem(title: 'Daftar Stok', icon: Icons.inventory_2_rounded)
        ]),
    NavItem(
        title: 'Pelanggan',
        icon: Icons.people_alt_rounded,
        children: [NavItem(title: 'Daftar Pelanggan', icon: Icons.people)]),
    NavItem(title: 'Kupon', icon: Icons.sell_rounded, children: [
      NavItem(title: 'Daftar Kupon', icon: Icons.local_offer_rounded),
    ]),
    NavItem(title: 'Outlet', icon: Icons.storefront_rounded, children: [
      NavItem(title: 'Daftar Outlet', icon: Icons.store)
    ]),
    NavItem(title: 'Karyawan', icon: Icons.person_outline, children: [
      NavItem(title: 'Daftar Karyawan', icon: Icons.person_outline),
      NavItem(title: 'Daftar Absensi', icon: Icons.how_to_reg),
      NavItem(title: 'Manajemen Gaji', icon: Icons.monetization_on)
    ])
  ];

  void _showOutletMenu(BuildContext context) {
    final RenderBox renderBox =
    _outletHeaderKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) {
        return Stack(
          children: [
            Positioned(
              top: offset.dy + size.height + 5,
              left: offset.dx,
              child: FadeTransition(
                opacity: anim1,
                child: Material(
                  type: MaterialType.transparency,
                  child: OutletSelectionDialog(
                    userData: widget.userData,
                    onRefreshUserData: widget.onRefreshUserData,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      width: widget.isCollapsed ? 80 : 250,
      color: const Color(0xFF279E9E),
      child: Column(
        children: [
          _buildOutletHeader(),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];

                return NavListTile(
                  isCollapsed: widget.isCollapsed,
                  item: item,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  selectedItem: _selectedItem,
                  onTap: (String title) {
                    setState(() {
                      _selectedItem = title;
                    });
                    widget.onNavigate(title);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutletHeader() {
    final String businessName =
        widget.userData?['businessName'] ?? 'Bisnis Anda';

    return InkWell(
      key: _outletHeaderKey,
      onTap: () {
        if (!widget.isCollapsed) {
          _showOutletMenu(context);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        height: 64,
        child: widget.isCollapsed
            ? const Center(
            child: Icon(Icons.storefront, color: Colors.white, size: 28))
            : Row(
          children: [
            const SizedBox(width: 24),
            const Icon(Icons.storefront, color: Colors.white, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Outlet',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 14)),
                    Text(
                      widget.isLoading ? 'Loading...' : businessName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: Colors.white),
            const SizedBox(width: 24),
          ],
        ),
      ),
    );
  }
}

class OutletSelectionDialog extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final VoidCallback onRefreshUserData;

  const OutletSelectionDialog({
    super.key,
    this.userData,
    required this.onRefreshUserData,
  });

  @override
  State<OutletSelectionDialog> createState() => _OutletSelectionDialogState();
}

class _OutletSelectionDialogState extends State<OutletSelectionDialog> {
  String? _selectedOutletId;
  bool _isLoading = true;
  List<QueryDocumentSnapshot> _outlets = [];

  @override
  void initState() {
    super.initState();
    _selectedOutletId = widget.userData?['activeOutletId'];
    _fetchUserOutlets();
  }

  Future<void> _fetchUserOutlets() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final querySnapshot = await FirebaseFirestore.instance
          .collection('outlets')
          .where('userId', isEqualTo: user.uid)
          .get();

      if (mounted) {
        setState(() {
          _outlets = querySnapshot.docs;
          final currentOutletId = widget.userData?['activeOutletId'];
          if (currentOutletId != null) {
            _selectedOutletId = currentOutletId;
          } else if (_outlets.isNotEmpty) {
            _selectedOutletId = _outlets.first.id;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching outlets: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daftar Outlet',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                hintText: 'Cari Outlet...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.all(10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_outlets.isEmpty)
              const Padding(
                padding:
                EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                child: Center(
                  child: Text(
                    'Anda belum memiliki outlet.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _outlets.length,
                  itemBuilder: (context, index) {
                    final outletDoc = _outlets[index];
                    final outletData =
                    outletDoc.data() as Map<String, dynamic>;

                    final outletName =
                        outletData['name'] ?? 'Outlet Tanpa Nama';
                    final outletId = outletDoc.id;

                    return RadioListTile<String>(
                      title: Text(outletName),
                      value: outletId,
                      groupValue: _selectedOutletId,
                      onChanged: (value) async {
                        if (value == null || value == _selectedOutletId) return;

                        setState(() {
                          _selectedOutletId = value;
                        });

                        try {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) throw Exception("No user logged in");

                          final outletDoc =
                          _outlets.firstWhere((doc) => doc.id == value);
                          final outletData =
                          outletDoc.data() as Map<String, dynamic>;
                          final newBusinessName = outletData['name'];
                          final String newOutletId = outletDoc.id;

                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .update({
                            'businessName': newBusinessName,
                            'activeOutletId': newOutletId,
                          });

                          widget.onRefreshUserData();

                          if (mounted) {
                            Navigator.of(context).pop();
                          }
                        } catch (e) {
                          debugPrint("Error switching outlet: $e");
                        }
                      },
                      activeColor: const Color(0xFF279E9E),
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}