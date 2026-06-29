import 'package:shared_preferences/shared_preferences.dart';

class NotesService {
  static const String _oldKeyPrefix = 'note_';
  static const String _keyPrefix = 'notes_list_';

  static String _getKey(DateTime date) {
    return '$_keyPrefix${date.year}_${date.month}_${date.day}';
  }
  
  static String _getOldKey(DateTime date) {
    return '$_oldKeyPrefix${date.year}_${date.month}_${date.day}';
  }

  static Future<void> addNote(DateTime date, String note) async {
    if (note.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    List<String> notes = await getNotes(date);
    notes.add(note.trim());
    await prefs.setStringList(_getKey(date), notes);
  }

  static Future<void> deleteNote(DateTime date, int index) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> notes = await getNotes(date);
    if (index >= 0 && index < notes.length) {
      notes.removeAt(index);
      if (notes.isEmpty) {
        await prefs.remove(_getKey(date));
      } else {
        await prefs.setStringList(_getKey(date), notes);
      }
    }
  }

  static Future<List<String>> getNotes(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Migration: If old single note exists, migrate to list
    final oldKey = _getOldKey(date);
    if (prefs.containsKey(oldKey)) {
      try {
        final oldNote = prefs.getString(oldKey);
        if (oldNote != null && oldNote.trim().isNotEmpty) {
          final newKey = _getKey(date);
          List<String> existingNewNotes = prefs.getStringList(newKey) ?? [];
          existingNewNotes.insert(0, oldNote);
          await prefs.setStringList(newKey, existingNewNotes);
        }
      } catch (e) {
        // Ignore parsing errors for old notes
      }
      await prefs.remove(oldKey);
    }

    return prefs.getStringList(_getKey(date)) ?? [];
  }

  static Future<bool> hasNote(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    // Check new keys
    final hasNew = prefs.containsKey(_getKey(date)) && (prefs.getStringList(_getKey(date))?.isNotEmpty ?? false);
    if (hasNew) return true;
    
    // Check old keys (in case they haven't been migrated yet)
    final hasOld = prefs.containsKey(_getOldKey(date));
    return hasOld;
  }

  static Future<Set<DateTime>> getDaysWithNotes(int year, int month) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    
    Set<DateTime> days = {};
    
    for (String k in keys) {
      if (k.startsWith('$_keyPrefix${year}_${month}_') || k.startsWith('$_oldKeyPrefix${year}_${month}_')) {
        final parts = k.split('_');
        try {
          if (k.startsWith(_keyPrefix)) {
            days.add(DateTime(int.parse(parts[2]), int.parse(parts[3]), int.parse(parts[4])));
          } else {
            days.add(DateTime(int.parse(parts[1]), int.parse(parts[2]), int.parse(parts[3])));
          }
        } catch (e) {
           // ignore parsing errors
        }
      }
    }
    return days;
  }
}
