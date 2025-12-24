import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:just_audio/just_audio.dart';
import '../models/music_track.dart';
import '../services/music_service.dart';

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
  AudioPlayer? _audioPlayer;
  String? _currentlyPlayingId;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Rebuild when tab changes
    });
    _loadTracks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _audioPlayer?.dispose();
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
    final urlController = TextEditingController();
    String selectedCategory = MusicService.getDefaultCategories().first;
    XFile? selectedImage;
    PlatformFile? selectedAudio;
    final ImagePicker imagePicker = ImagePicker();
    bool useUrl = false;

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
                      .map((category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ))
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
                // Audio source selection
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Tải lên file'),
                        selected: !useUrl,
                        onSelected: (selected) {
                          setDialogState(() {
                            useUrl = false;
                            urlController.clear();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Link nhạc'),
                        selected: useUrl,
                        onSelected: (selected) {
                          setDialogState(() {
                            useUrl = true;
                            selectedAudio = null;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (!useUrl)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Chọn file nhạc'),
                    onPressed: () async {
                      FilePickerResult? result = await FilePicker.platform.pickFiles(
                        type: FileType.audio,
                      );
                      if (result != null && result.files.single.path != null) {
                        setDialogState(() {
                          selectedAudio = result.files.single;
                        });
                      }
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
                if (useUrl)
                  TextField(
                    controller: urlController,
                    decoration: const InputDecoration(
                      labelText: 'Link nhạc (URL)',
                      border: OutlineInputBorder(),
                      hintText: 'https://...',
                    ),
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
                if (nameController.text.trim().isNotEmpty &&
                    (!useUrl || urlController.text.trim().isNotEmpty)) {
                  String? imagePath;
                  String? audioPath;
                  String? audioUrl;

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

                  // Handle audio
                  if (useUrl) {
                    audioUrl = urlController.text.trim();
                  } else if (selectedAudio != null && selectedAudio!.path != null) {
                    try {
                      // Save audio file
                      final appDir = await getApplicationDocumentsDirectory();
                      final fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}${path.extension(selectedAudio!.path!)}';
                      final savedAudio = File(path.join(appDir.path, fileName));
                      await File(selectedAudio!.path!).copy(savedAudio.path);
                      audioPath = savedAudio.path;
                    } catch (e) {
                      print('Error saving audio file: $e');
                    }
                  }

                  final track = MusicTrack(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text.trim(),
                    description: descriptionController.text.trim(),
                    imagePath: imagePath,
                    audioPath: audioPath,
                    audioUrl: audioUrl,
                    category: selectedCategory,
                    isUploaded: true,
                    addedDate: DateTime.now(),
                  );

                  await MusicService.addUploadedTrack(track);

                  if (mounted) {
                    Navigator.of(context).pop();
                    _loadTracks();
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

  void _showEditMusicDialog(MusicTrack track) {
    final nameController = TextEditingController(text: track.name);
    final descriptionController = TextEditingController(text: track.description);
    final urlController = TextEditingController(text: track.audioUrl ?? '');
    String selectedCategory = track.category;
    XFile? selectedImage;
    String? currentImagePath = track.imagePath;
    final ImagePicker imagePicker = ImagePicker();
    bool useUrl = track.audioUrl != null;

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
                      .map((category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ))
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
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Tải lên file'),
                        selected: !useUrl,
                        onSelected: (selected) {
                          setDialogState(() {
                            useUrl = false;
                            urlController.clear();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Link nhạc'),
                        selected: useUrl,
                        onSelected: (selected) {
                          setDialogState(() => useUrl = selected);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (useUrl)
                  TextField(
                    controller: urlController,
                    decoration: const InputDecoration(
                      labelText: 'Link nhạc (URL)',
                      border: OutlineInputBorder(),
                      hintText: 'https://...',
                    ),
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
                  String? audioUrl;

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

                  if (useUrl) {
                    audioUrl = urlController.text.trim();
                  }

                  final updatedTrack = track.copyWith(
                    name: nameController.text.trim(),
                    description: descriptionController.text.trim(),
                    imagePath: imagePath,
                    audioUrl: audioUrl,
                    category: selectedCategory,
                  );

                  await MusicService.updateUploadedTrack(updatedTrack);

                  if (mounted) {
                    Navigator.of(context).pop();
                    _loadTracks();
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
    try {
      // Stop current playback if playing
      if (_audioPlayer != null && _isPlaying) {
        await _audioPlayer!.stop();
        await _audioPlayer!.dispose();
      }

      // Get audio URL
      String? audioUrl = track.audioUrl;
      if (audioUrl == null || audioUrl.isEmpty) {
        if (track.audioPath != null && File(track.audioPath!).existsSync()) {
          // Play from local file
          _audioPlayer = AudioPlayer();
          await _audioPlayer!.setFilePath(track.audioPath!);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không tìm thấy file nhạc'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
      } else {
        // Play from URL
        _audioPlayer = AudioPlayer();
        
        // Handle Openwhyd URL format
        if (audioUrl.startsWith('https://openwhyd.org/')) {
          // Try to get the actual stream URL from Openwhyd
          // For now, try direct URL
          try {
            await _audioPlayer!.setUrl(audioUrl);
          } catch (e) {
            print('Error playing Openwhyd URL: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Không thể phát nhạc từ link này'),
                duration: Duration(seconds: 2),
              ),
            );
            return;
          }
        } else {
          await _audioPlayer!.setUrl(audioUrl);
        }
      }

      setState(() {
        _currentlyPlayingId = track.id;
        _isPlaying = true;
      });

      // Play audio
      await _audioPlayer!.play();

      // Listen for playback completion
      _audioPlayer!.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          setState(() {
            _isPlaying = false;
            _currentlyPlayingId = null;
          });
        }
      });
    } catch (e) {
      print('Error playing track: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi phát nhạc: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      setState(() {
        _isPlaying = false;
        _currentlyPlayingId = null;
      });
    }
  }

  Future<void> _pauseTrack() async {
    if (_audioPlayer != null && _isPlaying) {
      await _audioPlayer!.pause();
      setState(() {
        _isPlaying = false;
      });
    }
  }

  Future<void> _stopTrack() async {
    if (_audioPlayer != null) {
      await _audioPlayer!.stop();
      await _audioPlayer!.dispose();
      _audioPlayer = null;
      setState(() {
        _isPlaying = false;
        _currentlyPlayingId = null;
      });
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
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
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
              children: [
                _buildLibraryTab(),
                _buildUploadTab(),
              ],
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
            ...tracks.map((track) => _buildMusicCard(track, isUploaded: track.isUploaded)),
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
        return _buildMusicCard(_uploadedTracks[index], isUploaded: true);
      },
    );
  }

  Widget _buildMusicCard(MusicTrack track, {required bool isUploaded}) {
    return Container(
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
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (track.audioUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(Icons.link, size: 12, color: Colors.blue.shade600),
                        const SizedBox(width: 4),
                        Text(
                          'Phát trực tiếp',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Play button
          IconButton(
            icon: Icon(
              _currentlyPlayingId == track.id && _isPlaying
                  ? Icons.pause_circle_filled
                  : Icons.play_circle_filled,
              color: Colors.red.shade600,
              size: 32,
            ),
            onPressed: () {
              if (_currentlyPlayingId == track.id && _isPlaying) {
                _pauseTrack();
              } else {
                if (_currentlyPlayingId != null) {
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
                          child: const Text('Xóa', style: TextStyle(color: Colors.red)),
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
    // Check if imagePath is a URL or local file
    if (track.imagePath != null && track.imagePath!.isNotEmpty) {
      // Check if it's a URL
      if (track.imagePath!.startsWith('http://') || 
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
      } else {
        // Local file
        if (File(track.imagePath!).existsSync()) {
          return ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
            child: Image.file(
              File(track.imagePath!),
              fit: BoxFit.cover,
            ),
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
          child: const Icon(Icons.self_improvement, color: Colors.white, size: 40),
        );
      default:
        return Container(
          color: Colors.grey[300],
          child: const Icon(Icons.music_note, color: Colors.white, size: 40),
        );
    }
  }
}

