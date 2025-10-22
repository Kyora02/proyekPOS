import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardLayout extends StatefulWidget {
  final Widget child;
  final Function(String) onNavigate;
  final Map<String, dynamic>? userData;
  final bool isLoading;

  const DashboardLayout({
    super.key,
    required this.child,
    required this.onNavigate,
    required this.userData,
    required this.isLoading,
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
                ),
                Expanded(
                  child: Column(
                    children: [
                      TopAppBar(
                        onMenuPressed: _toggleSidebar,
                        isDesktop: true,
                        userData: widget.userData,
                        isLoading: widget.isLoading,
                        onProfileSettingsTap: () => widget.onNavigate('Profile'),
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
            ),
            drawer: SideNavBar(
              isCollapsed: false,
              userData: widget.userData,
              isLoading: widget.isLoading,
              onNavigate: widget.onNavigate,
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

  TopAppBar({
    super.key,
    this.onMenuPressed,
    required this.isDesktop,
    this.userData,
    required this.isLoading,
    required this.onProfileSettingsTap,
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
              left: offset.dx + size.width - 300,
              child: FadeTransition(
                opacity: anim1,
                child: Material(
                  type: MaterialType.transparency,
                  child: ProfileMenuDialog(
                    userData: userData,
                    isLoading: isLoading,
                    onProfileSettingsTap: onProfileSettingsTap,
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
        actions: const [],
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

  const ProfileMenuDialog({
    super.key,
    required this.userData,
    required this.isLoading,
    required this.onProfileSettingsTap,
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
            onTap: () {},
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
  final EdgeInsetsGeometry? padding;
  final bool isSelected;
  final VoidCallback onTap;

  const NavListTile({
    super.key,
    required this.isCollapsed,
    required this.item,
    this.padding,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<NavListTile> createState() => _NavListTileState();
}

class _NavListTileState extends State<NavListTile> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Container(
        decoration: BoxDecoration(
          color:
          _isHovering ? Colors.white.withOpacity(0.1) : Colors.transparent,
          border: Border(
            right: BorderSide(
              color: widget.isSelected
                  ? const Color(0xFFFFC107)
                  : Colors.transparent,
              width: 4.0,
            ),
          ),
        ),
        child: widget.isCollapsed
            ? Tooltip(
          message: item.title,
          child: InkWell(
            onTap: widget.onTap,
            child: SizedBox(
              height: 48.0,
              child: Center(
                child: Icon(item.icon, color: Colors.white, size: 22),
              ),
            ),
          ),
        )
            : item.children.isEmpty
            ? ListTile(
          contentPadding: widget.padding ??
              const EdgeInsets.symmetric(horizontal: 24),
          leading: Icon(item.icon, color: Colors.white, size: 22),
          title: Text(item.title,
              style:
              const TextStyle(color: Colors.white, fontSize: 15)),
          onTap: widget.onTap,
        )
            : Theme(
          data: Theme.of(context)
              .copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: widget.padding ??
                const EdgeInsets.symmetric(horizontal: 24),
            leading: Icon(item.icon, color: Colors.white, size: 22),
            title: Text(item.title,
                style:
                const TextStyle(color: Colors.white, fontSize: 15)),
            trailing: const Icon(Icons.keyboard_arrow_down,
                color: Colors.white),
            children: item.children
                .map((child) => NavListTile(
              isCollapsed: widget.isCollapsed,
              item: child,
              isSelected: false,
              onTap: () {},
              padding: const EdgeInsets.only(left: 48.0),
            ))
                .toList(),
          ),
        ),
      ),
    );
  }
}

class SideNavBar extends StatefulWidget {
  final bool isCollapsed;
  final Map<String, dynamic>? userData;
  final bool isLoading;
  final Function(String) onNavigate;

  const SideNavBar({
    super.key,
    required this.isCollapsed,
    this.userData,
    required this.isLoading,
    required this.onNavigate,
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
        NavItem(title: 'Laporan Penjualan', icon: Icons.point_of_sale),
        NavItem(title: 'Laporan Pembelian', icon: Icons.shopping_bag),
        NavItem(title: 'Laporan Produk', icon: Icons.inventory_2_rounded),
        NavItem(title: 'Laporan Customer', icon: Icons.people_alt_rounded),
        NavItem(title: 'Laporan Karyawan', icon: Icons.people_alt_rounded),
        NavItem(title: 'Laporan Neraca', icon: Icons.balance)
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
    ),
    NavItem(
        title: 'Pelanggan',
        icon: Icons.people_alt_rounded,
        children: [NavItem(title: 'Daftar Pelanggan', icon: Icons.people)]),
    NavItem(
        title: 'Kupon',
        icon: Icons.sell_rounded,
        children: [
          NavItem(title: 'Daftar Kupon', icon: Icons.local_offer_rounded),
          NavItem(title: 'Tambah Kupon', icon: Icons.add_circle_outline_rounded)
        ]),
    NavItem(
        title: 'Outlet',
        icon: Icons.storefront_rounded,
        children: [
          NavItem(title: 'Daftar Outlet', icon: Icons.store)
        ]),
    NavItem(
        title: 'Karyawan', 
        icon: Icons.person_outline,
        children: [
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
                  // MODIFIED: Removed userData parameter
                  child: OutletSelectionDialog(),
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

                if (item.children.isEmpty) {
                  return NavListTile(
                    isCollapsed: widget.isCollapsed,
                    item: item,
                    isSelected: _selectedItem == item.title,
                    onTap: () {
                      setState(() {
                        _selectedItem = item.title;
                      });
                      widget.onNavigate(item.title);
                    },
                  );
                } else {
                  if (widget.isCollapsed) {
                    return Tooltip(
                      message: item.title,
                      child: SizedBox(
                        height: 48.0,
                        child: Center(
                          child:
                          Icon(item.icon, color: Colors.white, size: 22),
                        ),
                      ),
                    );
                  } else {
                    return Theme(
                      data: Theme.of(context)
                          .copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        key: PageStorageKey(item.title),
                        tilePadding:
                        const EdgeInsets.symmetric(horizontal: 24),
                        leading: Icon(item.icon, color: Colors.white, size: 22),
                        title: Text(item.title,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 15)),
                        trailing: const Icon(Icons.keyboard_arrow_down,
                            color: Colors.white),
                        children: item.children.map((child) {
                          return NavListTile(
                            isCollapsed: widget.isCollapsed,
                            item: child,
                            isSelected: _selectedItem == child.title,
                            padding: const EdgeInsets.only(left: 48.0),
                            onTap: () {
                              setState(() {
                                _selectedItem = child.title;
                              });
                              widget.onNavigate(child.title);
                            },
                          );
                        }).toList(),
                      ),
                    );
                  }
                }
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

// =========================================================================
// REPLACED OutletSelectionDialog
// =========================================================================

class OutletSelectionDialog extends StatefulWidget {
  const OutletSelectionDialog({super.key});

  @override
  State<OutletSelectionDialog> createState() => _OutletSelectionDialogState();
}

class _OutletSelectionDialogState extends State<OutletSelectionDialog> {
  String? _selectedOutletId;
  bool _isLoading = true;
  List<QueryDocumentSnapshot> _outlets = [];
  final String _allOutletsValue = 'Semua Outlet'; // Constant for the "All" option

  @override
  void initState() {
    super.initState();
    _selectedOutletId = _allOutletsValue; // Default selection
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
        return; // Not logged in
      }

      // Query the 'outlets' collection based on the 'userId' field
      final querySnapshot = await FirebaseFirestore.instance
          .collection('outlets')
          .where('userId', isEqualTo: user.uid)
          .get();

      if (mounted) {
        setState(() {
          _outlets = querySnapshot.docs;
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

            // "All Outlets" Radio Button
            RadioListTile<String>(
              title: const Text('Semua Outlet'),
              secondary: Text(
                '${_outlets.length} Outlet',
                style: TextStyle(color: Colors.grey[600]),
              ),
              value: _allOutletsValue,
              groupValue: _selectedOutletId,
              onChanged: (value) => setState(() => _selectedOutletId = value),
              activeColor: const Color(0xFF279E9E),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const Divider(),

            // Conditional list for outlets
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
            // This ConstrainedBox prevents the dialog from growing too tall
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

                    // Get outlet name, default to 'Unnamed' if null
                    final outletName =
                        outletData['name'] ?? 'Outlet Tanpa Nama';
                    final outletId = outletDoc.id;

                    return RadioListTile<String>(
                      title: Text(outletName),
                      value: outletId, // Use the document ID as the unique value
                      groupValue: _selectedOutletId,
                      onChanged: (value) {
                        setState(() => _selectedOutletId = value);
                        // You can add logic here to notify the rest of the app
                        // that the selected outlet has changed.
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