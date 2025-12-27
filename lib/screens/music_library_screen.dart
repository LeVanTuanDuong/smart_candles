import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/music_track.dart';
import '../services/music_service.dart';
import '../services/global_music_player_service.dart';

class MusicLibraryScreen extends StatefulWidget {
  const MusicLibraryScreen({super.key});

  @override
  State<MusicLibraryScreen> createState() => _MusicLibraryScreenState();
}

class _MusicLibraryScreenState extends State<MusicLibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, List<MusicTrack>> _tracksByCategory = {};
  List<MusicTrack> _uploadedTracks = [];
  bool _isLoading = true;
  final GlobalMusicPlayerService _globalMusicPlayer =
      GlobalMusicPlayerService();
  String? _currentlyPlayingId;
  bool _isLoadingTrack = false; // Prevent multiple simultaneous play requests

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      // Only rebuild if tab actually changed
      if (_tabController.indexIsChanging ||
          _tabController.index != _tabController.previousIndex) {
        setState(() {});
      }
    });
    // Listen to global music player changes
    _globalMusicPlayer.addListener(_onMusicPlayerChanged);
    _loadTracks();
  }

  void _onMusicPlayerChanged() {
    if (mounted) {
      setState(() {
        _currentlyPlayingId = _globalMusicPlayer.currentTrack?.id;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _globalMusicPlayer.removeListener(_onMusicPlayerChanged);
    super.dispose();
  }

  Future<void> _loadTracks() async {
    setState(() {
      _isLoading = true;
    });

    final tracksByCategory = await MusicService.getAllTracksByCategory();
    final uploadedTracks = await MusicService.loadUploadedTracks();

    setState(() {
      _tracksByCategory = tracksByCategory;
      _uploadedTracks = uploadedTracks;
      _isLoading = false;
    });
  }

  void _showAddMusicDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedCategory = MusicService.getDefaultCategories().first;
    XFile? selectedImage;
    PlatformFile? selectedAudio;
    final ImagePicker imagePicker = ImagePicker();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Thêm nhạc'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên nhạc',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                // Category selection
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Thể loại',
                    border: OutlineInputBorder(),
                  ),
                  items: MusicService.getDefaultCategories()
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedCategory = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                // Image selection
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
                          final XFile? image = await imagePicker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 80,
                          );
                          if (image != null) {
                            setDialogState(() => selectedImage = image);
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
                          final XFile? image = await imagePicker.pickImage(
                            source: ImageSource.camera,
                            imageQuality: 80,
                          );
                          if (image != null) {
                            setDialogState(() => selectedImage = image);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                if (selectedImage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    height: 100,
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
                ],
                const SizedBox(height: 16),
                // Audio file selection - only allow file upload
                const Text(
                  'Chọn file nhạc:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Builder(
                  builder: (context) {
                    bool isPickingFile = false;
                    return StatefulBuilder(
                      builder: (context, setButtonState) {
                        return OutlinedButton.icon(
                          icon: isPickingFile
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.upload_file),
                          label: Text(
                            isPickingFile
                                ? 'Đang chọn...'
                                : 'Chọn file nhạc từ thư viện',
                          ),
                          onPressed: isPickingFile
                              ? null
                              : () async {
                                  setButtonState(() => isPickingFile = true);
                                  try {
                                    FilePickerResult? result = await FilePicker
                                        .platform
                                        .pickFiles(type: FileType.audio);
                                    if (result != null &&
                                        result.files.single.path != null) {
                                      setDialogState(() {
                                        selectedAudio = result.files.single;
                                      });
                                    }
                                  } catch (e) {
                                    // Handle multiple_request exception gracefully
                                    if (e.toString().contains(
                                      'multiple_request',
                                    )) {
                                      // User cancelled or another request started - ignore silently
                                      print(
                                        'File picker cancelled or multiple request',
                                      );
                                    } else {
                                      // Show error for other exceptions
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Lỗi khi chọn file: ${e.toString()}',
                                            ),
                                            duration: const Duration(
                                              seconds: 2,
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  } finally {
                                    setButtonState(() => isPickingFile = false);
                                  }
                                },
                        );
                      },
                    );
                  },
                ),
                if (selectedAudio != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.audio_file, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            selectedAudio!.name,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            setDialogState(() => selectedAudio = null);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
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
                // Validate: need name and audio file
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng nhập tên nhạc'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return;
                }

                if (selectedAudio == null || selectedAudio!.path == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng chọn file nhạc từ thư viện'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return;
                }

                String? imagePath;
                String? audioPath;

                // Save image if selected
                if (selectedImage != null) {
                  try {
                    final appDir = await getApplicationDocumentsDirectory();
                    final fileName =
                        'music_${DateTime.now().millisecondsSinceEpoch}${path.extension(selectedImage!.path)}';
                    final savedImage = File(path.join(appDir.path, fileName));
                    await File(selectedImage!.path).copy(savedImage.path);
                    imagePath = savedImage.path;
                  } catch (e) {
                    print('Error saving image: $e');
                  }
                }

                // Save audio file
                try {
                  final appDir = await getApplicationDocumentsDirectory();
                  final fileName =
                      'audio_${DateTime.now().millisecondsSinceEpoch}${path.extension(selectedAudio!.path!)}';
                  final savedAudio = File(path.join(appDir.path, fileName));
                  await File(selectedAudio!.path!).copy(savedAudio.path);
                  audioPath = savedAudio.path;
                } catch (e) {
                  print('Error saving audio file: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi khi lưu file nhạc: $e'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  return;
                }

                final track = MusicTrack(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim(),
                  imagePath: imagePath,
                  audioPath: audioPath,
                  audioUrl: null, // No URL, only local file
                  category: selectedCategory,
                  isUploaded: true,
                  addedDate: DateTime.now(),
                );

                await MusicService.addUploadedTrack(track);

                if (mounted) {
                  Navigator.of(context).pop();
                  _loadTracks();
                }
              },
              child: const Text('Thêm'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditMusicDialog(MusicTrack track) {
    final nameController = TextEditingController(text: track.name);
    final descriptionController = TextEditingController(
      text: track.description,
    );
    String selectedCategory = track.category;
    XFile? selectedImage;
    String? currentImagePath = track.imagePath;
    PlatformFile? selectedAudio;
    final ImagePicker imagePicker = ImagePicker();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Chỉnh sửa nhạc'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên nhạc',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Thể loại',
                    border: OutlineInputBorder(),
                  ),
                  items: MusicService.getDefaultCategories()
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedCategory = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
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
                          final XFile? image = await imagePicker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 80,
                          );
                          if (image != null) {
                            setDialogState(() {
                              selectedImage = image;
                              currentImagePath = null;
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
                          final XFile? image = await imagePicker.pickImage(
                            source: ImageSource.camera,
                            imageQuality: 80,
                          );
                          if (image != null) {
                            setDialogState(() {
                              selectedImage = image;
                              currentImagePath = null;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                if (currentImagePath != null &&
                    File(currentImagePath!).existsSync() &&
                    selectedImage == null) ...[
                  const SizedBox(height: 12),
                  Container(
                    height: 100,
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
                              setDialogState(() => currentImagePath = null);
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
                    height: 100,
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
                ],
                const SizedBox(height: 16),
                // Audio file selection - only allow file upload
                const Text(
                  'Chọn file nhạc mới (tùy chọn):',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                if (track.audioPath != null) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.audio_file,
                          size: 20,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'File hiện tại: ${path.basename(track.audioPath!)}',
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Builder(
                  builder: (context) {
                    bool isPickingFile = false;
                    return StatefulBuilder(
                      builder: (context, setButtonState) {
                        return OutlinedButton.icon(
                          icon: isPickingFile
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.upload_file),
                          label: Text(
                            isPickingFile
                                ? 'Đang chọn...'
                                : 'Chọn file nhạc mới từ thư viện',
                          ),
                          onPressed: isPickingFile
                              ? null
                              : () async {
                                  setButtonState(() => isPickingFile = true);
                                  try {
                                    FilePickerResult? result = await FilePicker
                                        .platform
                                        .pickFiles(type: FileType.audio);
                                    if (result != null &&
                                        result.files.single.path != null) {
                                      setDialogState(() {
                                        selectedAudio = result.files.single;
                                      });
                                    }
                                  } catch (e) {
                                    // Handle multiple_request exception gracefully
                                    if (e.toString().contains(
                                      'multiple_request',
                                    )) {
                                      // User cancelled or another request started - ignore silently
                                      print(
                                        'File picker cancelled or multiple request',
                                      );
                                    } else {
                                      // Show error for other exceptions
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Lỗi khi chọn file: ${e.toString()}',
                                            ),
                                            duration: const Duration(
                                              seconds: 2,
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  } finally {
                                    setButtonState(() => isPickingFile = false);
                                  }
                                },
                        );
                      },
                    );
                  },
                ),
                if (selectedAudio != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.audio_file, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            selectedAudio!.name,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            setDialogState(() => selectedAudio = null);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
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
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng nhập tên nhạc'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return;
                }

                String? imagePath = currentImagePath;
                String? audioPath = track
                    .audioPath; // Keep existing audio if no new file selected

                // Save new image if selected
                if (selectedImage != null) {
                  try {
                    // Delete old image
                    if (track.imagePath != null &&
                        File(track.imagePath!).existsSync()) {
                      try {
                        await File(track.imagePath!).delete();
                      } catch (e) {
                        print('Error deleting old image: $e');
                      }
                    }

                    final appDir = await getApplicationDocumentsDirectory();
                    final fileName =
                        'music_${DateTime.now().millisecondsSinceEpoch}${path.extension(selectedImage!.path)}';
                    final savedImage = File(path.join(appDir.path, fileName));
                    await File(selectedImage!.path).copy(savedImage.path);
                    imagePath = savedImage.path;
                  } catch (e) {
                    print('Error saving image: $e');
                  }
                }

                // Save new audio file if selected
                if (selectedAudio != null && selectedAudio!.path != null) {
                  try {
                    // Delete old audio file if exists
                    if (track.audioPath != null &&
                        File(track.audioPath!).existsSync()) {
                      try {
                        await File(track.audioPath!).delete();
                      } catch (e) {
                        print('Error deleting old audio file: $e');
                      }
                    }

                    final appDir = await getApplicationDocumentsDirectory();
                    final fileName =
                        'audio_${DateTime.now().millisecondsSinceEpoch}${path.extension(selectedAudio!.path!)}';
                    final savedAudio = File(path.join(appDir.path, fileName));
                    await File(selectedAudio!.path!).copy(savedAudio.path);
                    audioPath = savedAudio.path;
                  } catch (e) {
                    print('Error saving audio file: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lỗi khi lưu file nhạc: $e'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    return;
                  }
                }

                final updatedTrack = track.copyWith(
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim(),
                  imagePath: imagePath,
                  audioPath: audioPath,
                  audioUrl: null, // Remove URL, only use local file
                  category: selectedCategory,
                );

                await MusicService.updateUploadedTrack(updatedTrack);

                if (mounted) {
                  Navigator.of(context).pop();
                  _loadTracks();
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteTrack(String trackId) async {
    await MusicService.deleteUploadedTrack(trackId);
    await _loadTracks();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xóa nhạc'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _playTrack(MusicTrack track) async {
    if (!mounted) return;

    // Allow switching tracks even if one is loading - this is user intent
    // Reset loading state first to allow new track to play
    if (_isLoadingTrack) {
      print('🔄 Switching to new track while previous one was loading...');
      _isLoadingTrack = false;
    }

    // If clicking the same track that's already playing, toggle pause/play
    if (_currentlyPlayingId == track.id && _globalMusicPlayer.isPlaying) {
      await _globalMusicPlayer.togglePlayPause();
      return;
    }

    setState(() {
      _isLoadingTrack = true;
      _currentlyPlayingId =
          track.id; // Update immediately to show loading state
    });

    try {
      // Use global music player service to play track
      // This will sync with the Home screen music control
      final globalPlayer = GlobalMusicPlayerService();
      await globalPlayer.playTrack(track);

      // Update local state to show which track is playing
      if (mounted) {
        setState(() {
          _currentlyPlayingId = track.id;
          _isLoadingTrack = false;
        });
      }

      print('✅ Started playing via global player: ${track.name}');
    } catch (e) {
      print('Error playing track: $e');
      if (mounted) {
        // Provide user-friendly error message
        String errorMessage = 'Không thể phát nhạc. Vui lòng thử lại.';
        final errorStr = e.toString().toLowerCase();

        if (errorStr.contains('offline') ||
            errorStr.contains('network') ||
            errorStr.contains('connection') ||
            errorStr.contains('socketexception') ||
            errorStr.contains('failed host lookup')) {
          errorMessage =
              'Không có kết nối internet. Vui lòng kiểm tra mạng và thử lại.';
        } else if (errorStr.contains('not found') || errorStr.contains('404')) {
          errorMessage = 'Không tìm thấy file nhạc. Vui lòng chọn track khác.';
        } else if (errorStr.contains('cannot play') ||
            errorStr.contains('youtube')) {
          errorMessage =
              'Track này không thể phát được. Vui lòng chọn track khác.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      if (mounted) {
        setState(() {
          // Only clear current track if it's the one that failed
          if (_currentlyPlayingId == track.id) {
            _currentlyPlayingId = null;
          }
          _isLoadingTrack = false;
        });
      }
    }
  }

  Future<void> _pauseTrack() async {
    if (!mounted) return;
    try {
      await _globalMusicPlayer.togglePlayPause();
    } catch (e) {
      print('Error pausing track: $e');
    }
  }

  Future<void> _stopTrack() async {
    if (!mounted) return;
    try {
      await _globalMusicPlayer.stop();
      if (mounted) {
        setState(() {
          _currentlyPlayingId = null;
          _isLoadingTrack = false;
        });
      }
    } catch (e) {
      print('Error stopping track: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange[50],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Thư viện Nhạc',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange.shade600,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Thư viện'),
            Tab(text: 'Tải lên'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [_buildLibraryTab(), _buildUploadTab()],
            ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton(
              onPressed: _showAddMusicDialog,
              backgroundColor: Colors.orange.shade600,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildLibraryTab() {
    if (_tracksByCategory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_note, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Chưa có nhạc',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tracksByCategory.length,
      // Use keys to optimize rebuilds
      itemBuilder: (context, index) {
        final category = _tracksByCategory.keys.elementAt(index);
        final tracks = _tracksByCategory[category]!;

        if (tracks.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 12, top: index > 0 ? 24 : 0),
              child: Text(
                category,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            ...tracks.map(
              (track) => _buildMusicCard(
                track,
                isUploaded: track.isUploaded,
                key: ValueKey(track.id),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUploadTab() {
    if (_uploadedTracks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.upload_file, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Chưa có nhạc đã tải lên',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Nhấn nút + để thêm nhạc',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _uploadedTracks.length,
      itemBuilder: (context, index) {
        final track = _uploadedTracks[index];
        return _buildMusicCard(
          track,
          isUploaded: true,
          key: ValueKey(track.id),
        );
      },
    );
  }

  Widget _buildMusicCard(
    MusicTrack track, {
    required bool isUploaded,
    Key? key,
  }) {
    final isCurrentlyPlaying =
        _currentlyPlayingId == track.id && _globalMusicPlayer.isPlaying;
    final isLoadingThisTrack =
        _currentlyPlayingId == track.id &&
        (_isLoadingTrack || _globalMusicPlayer.isLoading);

    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Image
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              color: Colors.grey[200],
            ),
            child: _buildTrackImage(track),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  track.description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Play button
          IconButton(
            icon: isLoadingThisTrack
                ? const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    isCurrentlyPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    color: Colors.red.shade600,
                    size: 32,
                  ),
            onPressed: () {
              // Allow switching tracks even if one is loading
              // Only prevent if clicking the same track that's loading
              if (_isLoadingTrack && _currentlyPlayingId == track.id) {
                return; // Prevent multiple taps on the same loading track
              }

              if (isCurrentlyPlaying) {
                _pauseTrack();
              } else {
                // Stop current track if playing a different one
                if (_currentlyPlayingId != null &&
                    _currentlyPlayingId != track.id) {
                  _stopTrack();
                }
                _playTrack(track);
              }
            },
          ),
          // Edit/Delete buttons for uploaded tracks
          if (isUploaded)
            PopupMenuButton(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Chỉnh sửa'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Xóa', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditMusicDialog(track);
                } else if (value == 'delete') {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Xóa nhạc'),
                      content: Text('Bạn có chắc muốn xóa ${track.name}?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Hủy'),
                        ),
                        TextButton(
                          onPressed: () {
                            _deleteTrack(track.id);
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
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTrackImage(MusicTrack track) {
    // Check if imagePath exists
    if (track.imagePath != null && track.imagePath!.isNotEmpty) {
      // Check if it's an asset path (starts with "assets/")
      if (track.imagePath!.startsWith('assets/')) {
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            bottomLeft: Radius.circular(12),
          ),
          child: Image.asset(
            track.imagePath!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildDefaultImage(track.category);
            },
          ),
        );
      }
      // Check if it's a URL
      else if (track.imagePath!.startsWith('http://') ||
          track.imagePath!.startsWith('https://')) {
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            bottomLeft: Radius.circular(12),
          ),
          child: Image.network(
            track.imagePath!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildDefaultImage(track.category);
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: Colors.grey[200],
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
          ),
        );
      }
      // Local file (user uploaded)
      else {
        if (File(track.imagePath!).existsSync()) {
          return ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
            child: Image.file(File(track.imagePath!), fit: BoxFit.cover),
          );
        }
      }
    }
    // Default image based on category
    return _buildDefaultImage(track.category);
  }

  Widget _buildDefaultImage(String category) {
    switch (category) {
      case 'Thiên nhiên':
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.green[400]!, Colors.green[600]!],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
          ),
          child: const Icon(Icons.nature, color: Colors.white, size: 40),
        );
      case 'Nhạc Piano':
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.brown[400]!, Colors.brown[600]!],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
          ),
          child: const Icon(Icons.piano, color: Colors.white, size: 40),
        );
      case 'Thiền':
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.orange[300]!, Colors.pink[300]!],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
          ),
          child: const Icon(
            Icons.self_improvement,
            color: Colors.white,
            size: 40,
          ),
        );
      default:
        return Container(
          color: Colors.grey[300],
          child: const Icon(Icons.music_note, color: Colors.white, size: 40),
        );
    }
  }
}
