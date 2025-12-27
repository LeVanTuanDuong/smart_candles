import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../services/auth_service.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _selectedImage;
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _authService.currentUser;
      if (user != null) {
        // Load from Firestore first
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data()!;
          _nameController.text = data['displayName'] ?? user.displayName ?? '';
        } else {
          _nameController.text = user.displayName ?? '';
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi chọn ảnh: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi chụp ảnh: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Prepare data to save
      final displayName = _nameController.text.trim();

      // Update display name in Firebase Auth
      if (displayName.isNotEmpty) {
        await user.updateDisplayName(displayName);
        await user.reload();
      }

      // Upload image to Firebase Storage if a new image was selected
      String? photoURL = user.photoURL;
      if (_selectedImage != null) {
        try {
          // Create a reference to the location you want to upload to
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('user_profiles')
              .child(
                  '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');

          // Upload the file
          await storageRef.putFile(File(_selectedImage!.path));

          // Get the download URL
          photoURL = await storageRef.getDownloadURL();

          // Update photoURL in Firebase Auth
          await user.updatePhotoURL(photoURL);
          await user.reload();
        } catch (e) {
          print('Error uploading image: $e');
          // Continue without photoURL if upload fails
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lỗi khi upload ảnh: ${e.toString()}'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }

      // Prepare Firestore update data
      final Map<String, dynamic> updateData = {
        'displayName': displayName,
        'email': user.email ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add photoURL if available
      if (photoURL != null && photoURL.isNotEmpty) {
        updateData['photoURL'] = photoURL;
      }

      // Check if document exists, if not create it
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);

      final docSnapshot = await userRef.get();

      if (docSnapshot.exists) {
        // Update existing document
        await userRef.update(updateData);
      } else {
        // Create new document with all user data
        updateData['uid'] = user.uid;
        updateData['createdAt'] = FieldValue.serverTimestamp();
        await userRef.set(updateData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật thông tin thành công!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Wait a bit before navigating to ensure data is saved
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          // Return true to indicate successful save, so ProfileScreen can reload
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      print('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi cập nhật: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildAvatar() {
    final user = _authService.currentUser;
    final photoURL = user?.photoURL;

    // Determine the background image
    ImageProvider? backgroundImage;
    if (_selectedImage != null) {
      backgroundImage = FileImage(File(_selectedImage!.path));
    } else if (photoURL != null && photoURL.isNotEmpty) {
      backgroundImage = NetworkImage(photoURL);
    }

    return Stack(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: Colors.purple[100],
          backgroundImage: backgroundImage,
          child: backgroundImage == null
              ? Text(
                  _getInitials(),
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[600],
                  ),
                )
              : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.purple[600],
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
              onSelected: (value) {
                if (value == 'gallery') {
                  _pickImage();
                } else if (value == 'camera') {
                  _takePhoto();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'gallery',
                  child: Row(
                    children: [
                      Icon(Icons.photo_library),
                      SizedBox(width: 8),
                      Text('Chọn từ thư viện'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'camera',
                  child: Row(
                    children: [
                      Icon(Icons.camera_alt),
                      SizedBox(width: 8),
                      Text('Chụp ảnh'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getInitials() {
    final user = _authService.currentUser;
    final displayName = user?.displayName ?? '';
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
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Thông tin cá nhân'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final user = _authService.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Thông tin cá nhân'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Lưu',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildAvatar(),
              const SizedBox(height: 32),
              // Name field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Họ và tên',
                  hintText: 'Nhập họ và tên của bạn',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập họ và tên';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Email field (read-only)
              TextFormField(
                initialValue: user?.email ?? '',
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                  enabled: false,
                ),
              ),
              const SizedBox(height: 20),
              // User ID (read-only)
              TextFormField(
                initialValue: user?.uid ?? '',
                decoration: InputDecoration(
                  labelText: 'User ID',
                  prefixIcon: const Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                  enabled: false,
                ),
              ),
              const SizedBox(height: 32),
              // Save button at bottom
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Lưu thông tin',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
