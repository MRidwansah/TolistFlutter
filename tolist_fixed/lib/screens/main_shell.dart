import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../models/models.dart';
import '../services/storage_service.dart';
import 'home_screen.dart';
import 'todolist_screen.dart';
import 'bookmarked_screen.dart';
import 'upload_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  final User user;
  const MainShell({super.key, required this.user});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  late User _currentUser; // State untuk menyimpan user agar bisa di-update

  static const _tabTitles = ['Home', 'Papan Tugas', 'Tersimpan', 'Upload', 'Profil'];

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user; // Set data awal dari login
  }

  // Fungsi ini akan dipanggil oleh ProfileScreen jika ada perubahan foto
  Future<void> _refreshUserData() async {
    final updatedUser = await StorageService.getUserProfile();
    if (updatedUser != null && mounted) {
      setState(() {
        _currentUser = updatedUser;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pass _currentUser ke semua screen
    final screens = [
      HomeScreen(user: _currentUser),
      TodolistScreen(user: _currentUser),
      BookmarkedScreen(user: _currentUser),
      UploadScreen(user: _currentUser),
      ProfileScreen(
        user: _currentUser, 
        onProfileUpdated: _refreshUserData, // Kirim fungsi refresh ke ProfileScreen
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: _buildAppBar(),
      body: screens[_currentIndex],
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final isProfile = _currentIndex == 4;
    final hasAvatar = _currentUser.avatarUrl != null && _currentUser.avatarUrl!.isNotEmpty;

    return PreferredSize(
      preferredSize: const Size.fromHeight(72),
      child: Container(
        color: AppColors.bgPrimary,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentIndex == 0)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: GoogleFonts.inter(color: AppColors.textWhite, fontWeight: FontWeight.w700, fontSize: 22),
                            children: [
                              const TextSpan(text: 'To'),
                              const TextSpan(text: 'List', style: TextStyle(color: AppColors.indigo)),
                            ],
                          ),
                        ),
                        Text(
                          'Halo, ${_currentUser.username}! 👋',
                          style: GoogleFonts.inter(color: AppColors.textSlate500, fontSize: 12),
                        ),
                      ],
                    )
                  else
                    Text(
                      _tabTitles[_currentIndex],
                      style: GoogleFonts.inter(color: AppColors.textWhite, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.3),
                    ),

                  if (!isProfile)
                    GestureDetector(
                      onTap: () => setState(() => _currentIndex = 4),
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          gradient: hasAvatar ? null : const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFA855F7)]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: hasAvatar
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(_currentUser.avatarUrl!, fit: BoxFit.cover),
                              )
                            : Center(
                                child: Text(
                                  _currentUser.username.isNotEmpty ? _currentUser.username[0].toUpperCase() : 'U',
                                  style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                                ),
                              ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: AppColors.borderSlate800.withOpacity(0.6), height: 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.home_outlined, 'activeIcon': Icons.home_rounded, 'label': 'Home'},
      {'icon': Icons.checklist_outlined, 'activeIcon': Icons.checklist_rounded, 'label': 'Tugas'},
      {'icon': Icons.bookmark_outline, 'activeIcon': Icons.bookmark_rounded, 'label': 'Simpan'},
      {'icon': Icons.upload_file_outlined, 'activeIcon': Icons.upload_file_rounded, 'label': 'Upload'},
      {'icon': Icons.person_outline_rounded, 'activeIcon': Icons.person_rounded, 'label': 'Profil'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        border: Border(top: BorderSide(color: AppColors.borderSlate800.withOpacity(0.6))),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final isActive = _currentIndex == i;
              return GestureDetector(
                onTap: () => setState(() => _currentIndex = i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.indigo.withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isActive ? items[i]['activeIcon'] as IconData : items[i]['icon'] as IconData,
                        color: isActive ? AppColors.indigo : AppColors.textSlate500,
                        size: 22,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        items[i]['label'] as String,
                        style: GoogleFonts.inter(
                          color: isActive ? AppColors.indigo : AppColors.textSlate500,
                          fontSize: 9,
                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}