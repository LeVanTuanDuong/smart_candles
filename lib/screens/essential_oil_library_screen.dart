import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/essential_oil.dart';
import '../services/essential_oil_service.dart';
import 'essential_oil_detail_screen.dart';
import 'essential_oil_guide_screen.dart';

class EssentialOilLibraryScreen extends StatefulWidget {
  const EssentialOilLibraryScreen({super.key});

  @override
  State<EssentialOilLibraryScreen> createState() =>
      _EssentialOilLibraryScreenState();
}

class _EssentialOilLibraryScreenState extends State<EssentialOilLibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<EssentialOil> _libraryOils = [];
  List<EssentialOil> _suggestedOils = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadOils();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOils() async {
    setState(() {
      _isLoading = true;
    });

    final library = await EssentialOilService.loadLibrary();
    final suggestions = await EssentialOilService.getSuggestions();

    setState(() {
      _libraryOils = library;
      _suggestedOils = suggestions;
      _isLoading = false;
    });
  }

  Future<void> _addToLibrary(EssentialOil oil) async {
    await EssentialOilService.addToLibrary(oil);
    await _loadOils();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã thêm ${oil.name} vào thư viện'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _removeFromLibrary(String oilId) async {
    await EssentialOilService.removeFromLibrary(oilId);
    await _loadOils();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xóa khỏi thư viện'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showEditOilDialog(EssentialOil oil) {
    final nameController = TextEditingController(text: oil.name);
    final descriptionController = TextEditingController(text: oil.description);
    String selectedImageType = oil.imageType;
    XFile? selectedImage;
    String? currentImagePath = oil.imagePath;
    final ImagePicker picker = ImagePicker();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Chỉnh sửa tinh dầu'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên tinh dầu',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                // Image selection section
                const Text(
                  'Chọn hình ảnh:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Thư viện'),
                        onPressed: () async {
                          final XFile? image = await picker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 80,
                          );
                          if (image != null) {
                            setDialogState(() {
                              selectedImage = image;
                              currentImagePath = null;
                              selectedImageType = 'custom';
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Chụp ảnh'),
                        onPressed: () async {
                          final XFile? image = await picker.pickImage(
                            source: ImageSource.camera,
                            imageQuality: 80,
                          );
                          if (image != null) {
                            setDialogState(() {
                              selectedImage = image;
                              currentImagePath = null;
                              selectedImageType = 'custom';
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                // Show current or selected image preview
                if (currentImagePath != null &&
                    File(currentImagePath!).existsSync() &&
                    selectedImage == null) ...[
                  const SizedBox(height: 12),
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(currentImagePath!),
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setDialogState(() {
                                currentImagePath = null;
                                selectedImageType = 'lavender';
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (selectedImage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(selectedImage!.path),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      setDialogState(() {
                        selectedImage = null;
                        currentImagePath = oil.imagePath;
                        selectedImageType = oil.imageType;
                      });
                    },
                    child: const Text('Xóa ảnh'),
                  ),
                ],
                const SizedBox(height: 16),
                const Text('Hoặc chọn loại hình ảnh mặc định:'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildImageTypeOption(
                      'lavender',
                      'Oải Hương',
                      selectedImageType,
                      (type) {
                        setDialogState(() {
                          selectedImageType = type;
                          selectedImage = null;
                          currentImagePath = null;
                        });
                      },
                    ),
                    _buildImageTypeOption(
                      'huong tram',
                      'Hương Trầm',
                      selectedImageType,
                      (type) {
                        setDialogState(() {
                          selectedImageType = type;
                          selectedImage = null;
                          currentImagePath = null;
                        });
                      },
                    ),
                    _buildImageTypeOption(
                      'bac ha',
                      'Bạc Hà',
                      selectedImageType,
                      (type) {
                        setDialogState(() {
                          selectedImageType = type;
                          selectedImage = null;
                          currentImagePath = null;
                        });
                      },
                    ),
                    _buildImageTypeOption(
                      'khuynh diep',
                      'Khuynh Diệp',
                      selectedImageType,
                      (type) {
                        setDialogState(() {
                          selectedImageType = type;
                          selectedImage = null;
                          currentImagePath = null;
                        });
                      },
                    ),
                    _buildImageTypeOption(
                      'tram tra',
                      'Tràm Trà',
                      selectedImageType,
                      (type) {
                        setDialogState(() {
                          selectedImageType = type;
                          selectedImage = null;
                          currentImagePath = null;
                        });
                      },
                    ),
                    _buildImageTypeOption('buoi', 'Bưởi', selectedImageType, (
                      type,
                    ) {
                      setDialogState(() {
                        selectedImageType = type;
                        selectedImage = null;
                        currentImagePath = null;
                      });
                    }),
                    _buildImageTypeOption(
                      'cam ngot',
                      'Cam Ngọt',
                      selectedImageType,
                      (type) {
                        setDialogState(() {
                          selectedImageType = type;
                          selectedImage = null;
                          currentImagePath = null;
                        });
                      },
                    ),
                    _buildImageTypeOption(
                      'sa chanh',
                      'Sả Chanh',
                      selectedImageType,
                      (type) {
                        setDialogState(() {
                          selectedImageType = type;
                          selectedImage = null;
                          currentImagePath = null;
                        });
                      },
                    ),
                    _buildImageTypeOption('gung', 'Gừng', selectedImageType, (
                      type,
                    ) {
                      setDialogState(() {
                        selectedImageType = type;
                        selectedImage = null;
                        currentImagePath = null;
                      });
                    }),
                    _buildImageTypeOption(
                      'ngoc lan tay',
                      'Ngọc Lan Tây',
                      selectedImageType,
                      (type) {
                        setDialogState(() {
                          selectedImageType = type;
                          selectedImage = null;
                          currentImagePath = null;
                        });
                      },
                    ),
                    _buildImageTypeOption(
                      'hoa nhai',
                      'Hoa Nhài',
                      selectedImageType,
                      (type) {
                        setDialogState(() {
                          selectedImageType = type;
                          selectedImage = null;
                          currentImagePath = null;
                        });
                      },
                    ),
                    _buildImageTypeOption('chanh', 'Chanh', selectedImageType, (
                      type,
                    ) {
                      setDialogState(() {
                        selectedImageType = type;
                        selectedImage = null;
                        currentImagePath = null;
                      });
                    }),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isNotEmpty) {
                  String? imagePath = currentImagePath;

                  // Save new image if selected
                  if (selectedImage != null) {
                    try {
                      // Delete old image if exists
                      if (oil.imagePath != null &&
                          File(oil.imagePath!).existsSync()) {
                        try {
                          await File(oil.imagePath!).delete();
                        } catch (e) {
                          // Removed print statement: 'Error deleting old image: $e');
                        }
                      }

                      // Save new image
                      final appDir = await getApplicationDocumentsDirectory();
                      final fileName =
                          'oil_${DateTime.now().millisecondsSinceEpoch}${path.extension(selectedImage!.path)}';
                      final savedImage = File(path.join(appDir.path, fileName));
                      await File(selectedImage!.path).copy(savedImage.path);
                      imagePath = savedImage.path;
                    } catch (e) {
                      // Removed print statement: 'Error saving image: $e');
                    }
                  } else if (selectedImageType != 'custom' &&
                      currentImagePath == null) {
                    // If switching to default image type, delete custom image
                    if (oil.imagePath != null &&
                        File(oil.imagePath!).existsSync()) {
                      try {
                        await File(oil.imagePath!).delete();
                      } catch (e) {
                        // Removed print statement: 'Error deleting old image: $e');
                      }
                    }
                    imagePath = null;
                  }

                  final updatedOil = oil.copyWith(
                    name: nameController.text.trim(),
                    description: descriptionController.text.trim(),
                    imageType: selectedImageType,
                    imagePath: imagePath,
                  );

                  await EssentialOilService.updateOil(updatedOil);

                  if (mounted) {
                    Navigator.of(context).pop();
                    _loadOils();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã cập nhật tinh dầu'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddOilDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedImageType = 'lavender';
    XFile? selectedImage;
    final ImagePicker picker = ImagePicker();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Thêm tinh dầu'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên tinh dầu',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                // Image selection section
                const Text(
                  'Chọn hình ảnh:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Thư viện'),
                        onPressed: () async {
                          final XFile? image = await picker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 80,
                          );
                          if (image != null) {
                            setDialogState(() {
                              selectedImage = image;
                              selectedImageType = 'custom';
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Chụp ảnh'),
                        onPressed: () async {
                          final XFile? image = await picker.pickImage(
                            source: ImageSource.camera,
                            imageQuality: 80,
                          );
                          if (image != null) {
                            setDialogState(() {
                              selectedImage = image;
                              selectedImageType = 'custom';
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                // Show selected image preview
                if (selectedImage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(selectedImage!.path),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      setDialogState(() {
                        selectedImage = null;
                        selectedImageType = 'lavender';
                      });
                    },
                    child: const Text('Xóa ảnh'),
                  ),
                ],
                const SizedBox(height: 16),
                const Text('Hoặc chọn loại hình ảnh mặc định:'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildImageTypeOption(
                      'lavender',
                      'Oải Hương',
                      selectedImageType,
                      (type) {
                        setDialogState(() {
                          selectedImageType = type;
                          selectedImage = null;
                        });
                      },
                    ),
                    _buildImageTypeOption(
                      'huong tram',
                      'Hương Trầm',
                      selectedImageType,
                      (type) {
                        setDialogState(() {
                          selectedImageType = type;
                          selectedImage = null;
                        });
                      },
                    ),
                    _buildImageTypeOption(
                      'bac ha',
                      'Bạc Hà',
                      selectedImageType,
                      (type) {
                        setDialogState(() {
                          selectedImageType = type;
                          selectedImage = null;
                        });
                      },
                    ),
                    _buildImageTypeOption(
                      'khuynh diep',
                      'Khuynh Diệp',
                      selectedImageType,
                      (type) {
                        setDialogState(() {
                          selectedImageType = type;
                          selectedImage = null;
                        });
                      },
                    ),
                    _buildImageTypeOption(
                      'tram tra',
                      'Tràm Trà',
                      selectedImageType,
                      (type) {
                        setDialogState(() {
                          selectedImageType = type;
                          selectedImage = null;
                        });
                      },
                    ),
                    _buildImageTypeOption('buoi', 'Bưởi', selectedImageType, (
                      type,
                    ) {
                      setDialogState(() {
                        selectedImageType = type;
                        selectedImage = null;
                      });
                    }),
                    _buildImageTypeOption(
                      'cam ngot',
                      'Cam Ngọt',
                      selectedImageType,
                      (type) {
                        setDialogState(() {
                          selectedImageType = type;
                          selectedImage = null;
                        });
                      },
                    ),
                    _buildImageTypeOption(
                      'sa chanh',
                      'Sả Chanh',
                      selectedImageType,
                      (type) {
                        setDialogState(() {
                          selectedImageType = type;
                          selectedImage = null;
                        });
                      },
                    ),
                    _buildImageTypeOption('gung', 'Gừng', selectedImageType, (
                      type,
                    ) {
                      setDialogState(() {
                        selectedImageType = type;
                        selectedImage = null;
                      });
                    }),
                    _buildImageTypeOption(
                      'ngoc lan tay',
                      'Ngọc Lan Tây',
                      selectedImageType,
                      (type) {
                        setDialogState(() {
                          selectedImageType = type;
                          selectedImage = null;
                        });
                      },
                    ),
                    _buildImageTypeOption(
                      'hoa nhai',
                      'Hoa Nhài',
                      selectedImageType,
                      (type) {
                        setDialogState(() {
                          selectedImageType = type;
                          selectedImage = null;
                        });
                      },
                    ),
                    _buildImageTypeOption('chanh', 'Chanh', selectedImageType, (
                      type,
                    ) {
                      setDialogState(() {
                        selectedImageType = type;
                        selectedImage = null;
                      });
                    }),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isNotEmpty) {
                  String? imagePath;

                  // Save image if selected
                  if (selectedImage != null) {
                    try {
                      final appDir = await getApplicationDocumentsDirectory();
                      final fileName =
                          'oil_${DateTime.now().millisecondsSinceEpoch}${path.extension(selectedImage!.path)}';
                      final savedImage = File(path.join(appDir.path, fileName));
                      await File(selectedImage!.path).copy(savedImage.path);
                      imagePath = savedImage.path;
                    } catch (e) {
                      // Removed print statement: 'Error saving image: $e');
                    }
                  }

                  final oil = EssentialOil(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text.trim(),
                    description: descriptionController.text.trim(),
                    imageType: selectedImageType,
                    imagePath: imagePath,
                    isInLibrary: true,
                    addedDate: DateTime.now(),
                  );
                  await EssentialOilService.addToLibrary(oil);

                  if (mounted) {
                    Navigator.of(context).pop();
                    _loadOils();
                  }
                }
              },
              child: const Text('Thêm'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageTypeOption(
    String type,
    String label,
    String selected,
    Function(String) onTap,
  ) {
    final isSelected = type == selected;
    return GestureDetector(
      onTap: () => onTap(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Thư viện Tinh dầu',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[600],
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const EssentialOilGuideScreen(),
                ),
              );
            },
            tooltip: 'Hướng dẫn sử dụng',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Thư viện'),
            Tab(text: 'Tinh dầu'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Library Tab
                _buildLibraryTab(),
                // Suggestions Tab
                _buildSuggestionsTab(),
              ],
            ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: _showAddOilDialog,
              backgroundColor: Colors.blue[600],
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildLibraryTab() {
    if (_libraryOils.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Thư viện trống',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Nhấn nút + để thêm tinh dầu',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: _libraryOils.length,
      itemBuilder: (context, index) {
        return _buildOilCard(_libraryOils[index], isInLibrary: true);
      },
    );
  }

  Widget _buildSuggestionsTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: _suggestedOils.length,
      itemBuilder: (context, index) {
        return _buildOilCard(_suggestedOils[index], isInLibrary: false);
      },
    );
  }

  Widget _buildOilCard(EssentialOil oil, {required bool isInLibrary}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Navigate to detail screen
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => EssentialOilDetailScreen(oil: oil),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Show custom image if available, otherwise show default image type
                        oil.imagePath != null &&
                                File(oil.imagePath!).existsSync()
                            ? Image.file(
                                File(oil.imagePath!),
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : _buildOilImage(oil.imageType),
                      ],
                    ),
                  ),
                ),
                // Content
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          oil.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Flexible(
                          child: Text(
                            oil.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!isInLibrary) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            height: 32,
                            child: ElevatedButton(
                              onPressed: () => _addToLibrary(oil),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[600],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                              ),
                              child: const Text(
                                'Thêm vào thư viện',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Delete button for library items (top left)
            if (isInLibrary)
              Positioned(
                top: 8,
                left: 8,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Xóa tinh dầu'),
                          content: Text(
                            'Bạn có chắc muốn xóa ${oil.name} khỏi thư viện?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Hủy'),
                            ),
                            TextButton(
                              onPressed: () {
                                _removeFromLibrary(oil.id);
                                Navigator.of(context).pop();
                              },
                              child: const Text(
                                'Xóa',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            // Edit button for library items (top right)
            if (isInLibrary)
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showEditOilDialog(oil),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.blue,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOilImage(String imageType) {
    // Map imageType to asset path
    String? assetPath = _getAssetPathForImageType(imageType);

    if (assetPath != null) {
      // Use image from assets
      return Image.asset(
        assetPath,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to gradient if image not found
          return _buildGradientFallback(imageType);
        },
      );
    } else {
      // Fallback to gradient for old image types
      return _buildGradientFallback(imageType);
    }
  }

  String? _getAssetPathForImageType(String imageType) {
    // Map imageType to asset path in assets/images/tinh dau/
    final imageTypeLower = imageType.toLowerCase().trim();

    switch (imageTypeLower) {
      case 'lavender':
        return 'assets/images/tinh dau/lavender.png';
      case 'huong tram':
      case 'huongtram':
      case 'frankincense':
        return 'assets/images/tinh dau/huong tram.png';
      case 'bac ha':
      case 'bacha':
      case 'peppermint':
        return 'assets/images/tinh dau/bac ha.png';
      case 'khuynh diep':
      case 'khuynhdiep':
      case 'eucalyptus':
        return 'assets/images/tinh dau/khuynh diep.png';
      case 'tram tra':
      case 'tramtra':
      case 'tea tree':
        return 'assets/images/tinh dau/tram tra.png';
      case 'buoi':
      case 'grapefruit':
        return 'assets/images/tinh dau/buoi.png';
      case 'cam ngot':
      case 'camngot':
      case 'orange':
      case 'sweet orange':
        return 'assets/images/tinh dau/cam ngot.png';
      case 'sa chanh':
      case 'sachanh':
      case 'lemongrass':
        return 'assets/images/tinh dau/sa chanh.png';
      case 'gung':
      case 'ginger':
        return 'assets/images/tinh dau/gung.png';
      case 'ngoc lan tay':
      case 'ngoclantay':
      case 'ylang-ylang':
      case 'ylang ylang':
        return 'assets/images/tinh dau/ngoc lan tay.png';
      case 'hoa nhai':
      case 'hoanhai':
      case 'jasmine':
        return 'assets/images/tinh dau/hoa nhai.png';
      case 'chanh':
      case 'lemon':
        return 'assets/images/tinh dau/chanh.png';
      default:
        return null;
    }
  }

  Widget _buildGradientFallback(String imageType) {
    // Legacy gradient fallback for old image types
    switch (imageType.toLowerCase()) {
      case 'lavender':
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.purple[200]!, Colors.purple[400]!],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 10,
                left: 20,
                child: Icon(
                  Icons.local_florist,
                  size: 30,
                  color: Colors.purple[700],
                ),
              ),
              Positioned(
                top: 15,
                right: 15,
                child: Icon(
                  Icons.local_florist,
                  size: 25,
                  color: Colors.purple[600],
                ),
              ),
            ],
          ),
        );
      case 'orange':
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.orange[200]!, Colors.orange[400]!],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 10,
                left: 20,
                child: Icon(Icons.circle, size: 30, color: Colors.orange[700]),
              ),
              Positioned(
                top: 15,
                right: 15,
                child: Icon(Icons.circle, size: 25, color: Colors.orange[600]),
              ),
            ],
          ),
        );
      case 'chamomile':
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.yellow[200]!, Colors.yellow[400]!],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 10,
                left: 20,
                child: Icon(
                  Icons.wb_sunny,
                  size: 30,
                  color: Colors.yellow[700],
                ),
              ),
              Positioned(
                top: 15,
                right: 15,
                child: Icon(
                  Icons.wb_sunny,
                  size: 25,
                  color: Colors.yellow[600],
                ),
              ),
            ],
          ),
        );
      case 'peppermint':
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.green[200]!, Colors.green[400]!],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 10,
                left: 20,
                child: Icon(Icons.eco, size: 30, color: Colors.green[700]),
              ),
              Positioned(
                top: 15,
                right: 15,
                child: Icon(Icons.eco, size: 25, color: Colors.green[600]),
              ),
            ],
          ),
        );
      default:
        return Container(color: Colors.grey[300]);
    }
  }
}
