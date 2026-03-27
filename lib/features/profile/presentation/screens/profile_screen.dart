import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_candles/features/auth/services/auth_service.dart';
import 'package:smart_candles/shared/models/device_status.dart';
import 'package:smart_candles/features/profile/presentation/screens/settings_screen.dart';
import 'package:smart_candles/features/profile/presentation/screens/personal_info_screen.dart';
import 'package:smart_candles/features/history/presentation/screens/usage_history_screen.dart';
import 'package:smart_candles/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:smart_candles/features/history/presentation/screens/statistics_screen.dart';
import 'package:smart_candles/features/profile/presentation/screens/help_support_screen.dart';
import 'package:smart_candles/features/profile/presentation/screens/about_screen.dart';
class ProfileScreen extends StatefulWidget {
  final DeviceStatus deviceStatus;
  final Function(DeviceStatus) onStatusChanged;

  const ProfileScreen({
    super.key,
    required this.deviceStatus,
    required this.onStatusChanged,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        // Reload user to get latest data from Firebase Auth
        await user.reload();
        final updatedUser = _authService.currentUser;

        if (updatedUser != null) {
          // Load user data from Firestore
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(updatedUser.uid)
              .get();

          if (userDoc.exists) {
            final firestoreData = userDoc.data()!;
            // Merge Firestore data with Auth data (Auth takes priority for email/photoURL)
            setState(() {
              _userData = {
                ...firestoreData,
                'displayName': updatedUser.displayName ??
                    firestoreData['displayName'] ??
                    '',
                'email': updatedUser.email ?? firestoreData['email'] ?? '',
                'photoURL': updatedUser.photoURL ?? firestoreData['photoURL'],
              };
              _isLoading = false;
            });
          } else {
            // If no Firestore data, use Auth data
            setState(() {
              _userData = {
                'displayName': updatedUser.displayName ?? '',
                'email': updatedUser.email ?? '',
                'photoURL': updatedUser.photoURL ?? '',
              };
              _isLoading = false;
            });
          }
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      // Removed print statement: 'Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildAvatar() {
    final user = _authService.currentUser;
    final photoURL = _userData?['photoURL'] ?? user?.photoURL;

    if (photoURL != null && photoURL.isNotEmpty) {
      return CircleAvatar(
        radius: 60,
        backgroundImage: NetworkImage(photoURL),
        onBackgroundImageError: (exception, stackTrace) {
          // Fallback to default avatar if image fails to load
        },
      );
    }

    return CircleAvatar(
      radius: 60,
      backgroundColor: Colors.purple[600],
      child: Text(
        _getInitials(),
        style: const TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  String _getInitials() {
    final user = _authService.currentUser;
    final displayName = _userData?['displayName'] ?? user?.displayName ?? '';
    final email = user?.email ?? '';

    if (displayName.isNotEmpty) {
      final parts = displayName.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
      } else if (parts.length == 1) {
        return parts[0][0].toUpperCase();
      }
    }

    if (email.isNotEmpty) {
      return email[0].toUpperCase();
    }

    return 'U';
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Hồ sơ'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => SettingsScreen(
                      deviceStatus: widget.deviceStatus,
                      onStatusChanged: widget.onStatusChanged,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Hồ sơ'),
        ),
        body: const Center(
          child: Text('Vui lòng đăng nhập'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Hồ sơ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Colors.grey[800]),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(
                    deviceStatus: widget.deviceStatus,
                    onStatusChanged: widget.onStatusChanged,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Avatar Section
            _buildAvatar(),
            const SizedBox(height: 16),
            // Name
            Text(
              _userData?['displayName'] ?? user.displayName ?? 'Người dùng',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            // Email
            Text(
              user.email ?? '',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            // Profile Info Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  _buildInfoCard(
                    icon: Icons.person_outline,
                    title: 'Thông tin cá nhân',
                    subtitle: 'Xem và chỉnh sửa thông tin của bạn',
                    onTap: () async {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const PersonalInfoScreen(),
                        ),
                      );
                      // Reload user data if save was successful
                      if (result == true) {
                        _loadUserData();
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.history,
                    title: 'Lịch sử sử dụng',
                    subtitle: 'Xem lịch sử nhật ký tâm trạng và hoạt động',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const UsageHistoryScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.favorite_outline,
                    title: 'Sở thích',
                    subtitle: 'Quản lý tinh dầu và nhạc yêu thích',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const FavoritesScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.analytics_outlined,
                    title: 'Thống kê',
                    subtitle: 'Xem thống kê về tâm trạng và sử dụng app',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const StatisticsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.help_outline,
                    title: 'Trợ giúp & Hỗ trợ',
                    subtitle: 'Câu hỏi thường gặp và liên hệ hỗ trợ',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const HelpSupportScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.info_outline,
                    title: 'Về ứng dụng',
                    subtitle: 'Phiên bản và thông tin ứng dụng',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AboutScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.purple[100],
          child: Icon(icon, color: Colors.purple[600]),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
        onTap: onTap,
      ),
    );
  }
}
