import 'dart:io';
import 'package:flutter/material.dart';
import '../services/essential_oil_service.dart';
import '../services/music_service.dart';
import '../models/essential_oil.dart';
import '../models/music_track.dart';
import 'essential_oil_library_screen.dart';
import 'music_library_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<EssentialOil> _favoriteOils = [];
  List<MusicTrack> _favoriteTracks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFavorites();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load favorite oils (oils in library)
      final allOils = await EssentialOilService.getAllOils();
      _favoriteOils = allOils.where((oil) => oil.isInLibrary).toList();

      // Load favorite tracks (uploaded tracks)
      final allTracksByCategory = await MusicService.getAllTracksByCategory();
      _favoriteTracks = [];
      for (final tracks in allTracksByCategory.values) {
        _favoriteTracks.addAll(tracks.where((track) => track.isUploaded));
      }
    } catch (e) {
      // Removed print statement: 'Error loading favorites: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Sở thích'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Tinh dầu yêu thích'),
            Tab(text: 'Nhạc yêu thích'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOilsTab(),
                _buildTracksTab(),
              ],
            ),
    );
  }

  Widget _buildOilsTab() {
    if (_favoriteOils.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Chưa có tinh dầu yêu thích',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Thêm tinh dầu vào thư viện để xem ở đây',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const EssentialOilLibraryScreen(),
                  ),
                ).then((_) => _loadFavorites());
              },
              icon: const Icon(Icons.add),
              label: const Text('Thêm tinh dầu'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFavorites,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemCount: _favoriteOils.length,
        itemBuilder: (context, index) {
          final oil = _favoriteOils[index];
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: _buildOilImage(oil),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    oil.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTracksTab() {
    if (_favoriteTracks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_note_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Chưa có nhạc yêu thích',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Tải nhạc lên để xem ở đây',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const MusicLibraryScreen(),
                  ),
                ).then((_) => _loadFavorites());
              },
              icon: const Icon(Icons.add),
              label: const Text('Tải nhạc lên'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFavorites,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _favoriteTracks.length,
        itemBuilder: (context, index) {
          final track = _favoriteTracks[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildTrackImage(track),
              ),
              title: Text(
                track.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${track.category} • ${track.description}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const MusicLibraryScreen(),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildOilImage(EssentialOil oil) {
    // Use the same logic as EssentialOilLibraryScreen
    if (oil.imagePath != null && oil.imagePath!.isNotEmpty) {
      return Image.file(
        File(oil.imagePath!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildGradientFallback();
        },
      );
    }

    // Try to get asset path based on imageType
    final imageType = oil.imageType;
    if (imageType.isNotEmpty) {
      String? assetPath;
      switch (imageType.toLowerCase()) {
        case 'lavender':
        case 'oải hương':
          assetPath = 'assets/images/tinh dau/lavender.png';
          break;
        case 'huong tram':
        case 'hương trầm':
          assetPath = 'assets/images/tinh dau/huong tram.png';
          break;
        case 'bac ha':
        case 'bạc hà':
          assetPath = 'assets/images/tinh dau/bac ha.png';
          break;
        case 'khuynh diep':
        case 'khuynh diệp':
          assetPath = 'assets/images/tinh dau/khuynh diep.png';
          break;
        case 'tram tra':
        case 'tràm trà':
          assetPath = 'assets/images/tinh dau/tram tra.png';
          break;
        case 'buoi':
        case 'bưởi':
          assetPath = 'assets/images/tinh dau/buoi.png';
          break;
        case 'huong cam':
        case 'hương cam':
          assetPath = 'assets/images/tinh dau/huong cam.png';
          break;
        case 'sa chanh':
        case 'sả chanh':
          assetPath = 'assets/images/tinh dau/sa chanh.png';
          break;
        case 'gung':
        case 'gừng':
          assetPath = 'assets/images/tinh dau/gung.png';
          break;
        case 'ngoc lan tay':
        case 'ngọc lan tây':
          assetPath = 'assets/images/tinh dau/ngoc lan tay.png';
          break;
        case 'hoa nhai':
        case 'hoa nhài':
          assetPath = 'assets/images/tinh dau/hoa nhai.png';
          break;
        case 'chanh':
          assetPath = 'assets/images/tinh dau/chanh.png';
          break;
      }

      if (assetPath != null) {
        return Image.asset(
          assetPath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildGradientFallback();
          },
        );
      }
    }

    return _buildGradientFallback();
  }

  Widget _buildGradientFallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[200]!, Colors.green[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(Icons.spa, size: 40, color: Colors.white),
    );
  }

  Widget _buildTrackImage(MusicTrack track) {
    // Similar to MusicLibraryScreen
    if (track.imagePath != null && track.imagePath!.startsWith('assets/')) {
      return Image.asset(
        track.imagePath!,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 50,
            height: 50,
            color: Colors.grey[200],
            child: Icon(Icons.music_note, color: Colors.grey[400]),
          );
        },
      );
    }
    return Container(
      width: 50,
      height: 50,
      color: Colors.grey[200],
      child: Icon(Icons.music_note, color: Colors.grey[400]),
    );
  }
}

