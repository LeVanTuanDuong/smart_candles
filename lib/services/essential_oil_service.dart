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
        name: 'Lavender',
        description: 'Lavender essential oil is known for its calming and relaxing properties. It helps reduce anxiety, promote sleep, and relieve stress.',
        imageType: 'lavender',
        isInLibrary: false,
      ),
      EssentialOil(
        id: 'sweet_orange',
        name: 'Sweet Orange',
        description: 'Sweet Orange essential oil has uplifting and energizing properties. It helps improve mood, reduce stress, and boost energy levels.',
        imageType: 'orange',
        isInLibrary: false,
      ),
      EssentialOil(
        id: 'chamomile',
        name: 'Chamomile',
        description: 'Chamomile essential oil is renowned for its soothing and calming effects. It helps with sleep, reduces anxiety, and promotes relaxation.',
        imageType: 'chamomile',
        isInLibrary: false,
      ),
      EssentialOil(
        id: 'peppermint',
        name: 'Peppermint',
        description: 'Peppermint essential oil is invigorating and refreshing. It helps improve focus, reduce fatigue, and relieve headaches.',
        imageType: 'peppermint',
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

