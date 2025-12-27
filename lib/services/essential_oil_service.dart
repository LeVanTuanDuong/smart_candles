import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/essential_oil.dart';

class EssentialOilService {
  static const String _libraryKey = 'essential_oil_library';
  static SharedPreferences? _prefs;

  // Get SharedPreferences instance
  static Future<SharedPreferences?> _getPreferences() async {
    if (_prefs != null) return _prefs;
    
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      _prefs = await SharedPreferences.getInstance();
      return _prefs;
    } catch (e) {
      print('Error getting SharedPreferences: $e');
      try {
        await Future.delayed(const Duration(milliseconds: 500));
        _prefs = await SharedPreferences.getInstance();
        return _prefs;
      } catch (e2) {
        print('Error getting SharedPreferences on retry: $e2');
        return null;
      }
    }
  }

  // Get default AI suggested oils
  static List<EssentialOil> getDefaultSuggestions() {
    return [
      EssentialOil(
        id: 'lavender',
        name: 'Tinh dầu Oải Hương',
        description: 'Tinh dầu Oải Hương có tác dụng thư giãn và làm dịu. Giúp giảm lo âu, thúc đẩy giấc ngủ và giảm căng thẳng.',
        imageType: 'lavender',
        isInLibrary: false,
      ),
      EssentialOil(
        id: 'huong_tram',
        name: 'Tinh dầu Hương Trầm',
        description: 'Tinh dầu Hương Trầm có tác dụng làm dịu tinh thần, giảm căng thẳng và hỗ trợ thiền định.',
        imageType: 'huong tram',
        isInLibrary: false,
      ),
      EssentialOil(
        id: 'bac_ha',
        name: 'Tinh dầu Bạc Hà',
        description: 'Tinh dầu Bạc Hà giúp tỉnh táo, cải thiện tập trung, giảm mệt mỏi và giảm đau đầu.',
        imageType: 'bac ha',
        isInLibrary: false,
      ),
      EssentialOil(
        id: 'khuynh_diep',
        name: 'Tinh dầu Khuynh Diệp',
        description: 'Tinh dầu Khuynh Diệp có tác dụng thông mũi, làm sạch không khí và hỗ trợ hô hấp.',
        imageType: 'khuynh diep',
        isInLibrary: false,
      ),
      EssentialOil(
        id: 'tram_tra',
        name: 'Tinh dầu Tràm Trà',
        description: 'Tinh dầu Tràm Trà có đặc tính kháng khuẩn, làm sạch và thanh lọc không khí.',
        imageType: 'tram tra',
        isInLibrary: false,
      ),
      EssentialOil(
        id: 'buoi',
        name: 'Tinh dầu Bưởi',
        description: 'Tinh dầu Bưởi có tác dụng nâng cao tinh thần, tạo cảm giác tươi mới và tràn đầy năng lượng.',
        imageType: 'buoi',
        isInLibrary: false,
      ),
      EssentialOil(
        id: 'cam_ngot',
        name: 'Tinh dầu Hương Cam',
        description: 'Tinh dầu Hương Cam có tác dụng nâng cao tinh thần, giảm căng thẳng và tăng cường năng lượng.',
        imageType: 'cam ngot',
        isInLibrary: false,
      ),
      EssentialOil(
        id: 'sa_chanh',
        name: 'Tinh dầu Sả Chanh',
        description: 'Tinh dầu Sả Chanh giúp thư giãn, giảm căng thẳng và tạo cảm giác thanh mát.',
        imageType: 'sa chanh',
        isInLibrary: false,
      ),
      EssentialOil(
        id: 'gung',
        name: 'Tinh dầu Gừng',
        description: 'Tinh dầu Gừng có tác dụng làm ấm cơ thể, giảm buồn nôn và hỗ trợ tiêu hóa.',
        imageType: 'gung',
        isInLibrary: false,
      ),
      EssentialOil(
        id: 'ngoc_lan_tay',
        name: 'Tinh dầu Ngọc Lan Tây',
        description: 'Tinh dầu Ngọc Lan Tây có tác dụng làm dịu, giảm căng thẳng và tạo cảm giác yên bình.',
        imageType: 'ngoc lan tay',
        isInLibrary: false,
      ),
      EssentialOil(
        id: 'hoa_nhai',
        name: 'Tinh dầu Hoa Nhài',
        description: 'Tinh dầu Hoa Nhài có tác dụng nâng cao tâm trạng, giảm lo âu và thúc đẩy cảm xúc tích cực.',
        imageType: 'hoa nhai',
        isInLibrary: false,
      ),
      EssentialOil(
        id: 'chanh',
        name: 'Tinh dầu Chanh',
        description: 'Tinh dầu Chanh giúp tỉnh táo, làm sạch không khí và tạo cảm giác tươi mới.',
        imageType: 'chanh',
        isInLibrary: false,
      ),
    ];
  }

  // Load library oils (user-added)
  static Future<List<EssentialOil>> loadLibrary() async {
    try {
      final prefs = await _getPreferences();
      if (prefs == null) return [];

      final jsonString = prefs.getString(_libraryKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> oilsList = jsonDecode(jsonString);
      return oilsList.map((item) => EssentialOil.fromMap(item)).toList();
    } catch (e) {
      print('Error loading essential oil library: $e');
      return [];
    }
  }

  // Save library oils
  static Future<void> saveLibrary(List<EssentialOil> oils) async {
    try {
      final prefs = await _getPreferences();
      if (prefs == null) return;

      final oilsList = oils.map((oil) => oil.toMap()).toList();
      final jsonString = jsonEncode(oilsList);
      await prefs.setString(_libraryKey, jsonString);
    } catch (e) {
      print('Error saving essential oil library: $e');
    }
  }

  // Add oil to library
  static Future<void> addToLibrary(EssentialOil oil) async {
    final library = await loadLibrary();
    final updatedOil = oil.copyWith(
      isInLibrary: true,
      addedDate: DateTime.now(),
    );
    
    // Check if already exists
    final existingIndex = library.indexWhere((o) => o.id == oil.id);
    if (existingIndex >= 0) {
      library[existingIndex] = updatedOil;
    } else {
      library.add(updatedOil);
    }
    
    await saveLibrary(library);
  }

  // Update oil in library
  static Future<void> updateOil(EssentialOil updatedOil) async {
    final library = await loadLibrary();
    final index = library.indexWhere((oil) => oil.id == updatedOil.id);
    if (index >= 0) {
      library[index] = updatedOil;
      await saveLibrary(library);
    }
  }

  // Remove oil from library
  static Future<void> removeFromLibrary(String oilId) async {
    final library = await loadLibrary();
    library.removeWhere((oil) => oil.id == oilId);
    await saveLibrary(library);
  }

  // Get all oils (library + suggestions, excluding duplicates)
  static Future<List<EssentialOil>> getAllOils() async {
    final library = await loadLibrary();
    final suggestions = getDefaultSuggestions();
    
    // Get library IDs
    final libraryIds = library.map((o) => o.id).toSet();
    
    // Add suggestions that are not in library
    final allOils = <EssentialOil>[...library];
    for (var suggestion in suggestions) {
      if (!libraryIds.contains(suggestion.id)) {
        allOils.add(suggestion);
      }
    }
    
    return allOils;
  }

  // Get only suggestions (not in library)
  static Future<List<EssentialOil>> getSuggestions() async {
    final library = await loadLibrary();
    final libraryIds = library.map((o) => o.id).toSet();
    final suggestions = getDefaultSuggestions();
    
    return suggestions.where((oil) => !libraryIds.contains(oil.id)).toList();
  }
}

