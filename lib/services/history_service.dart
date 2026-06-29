import 'dart:convert';
import 'package:http/http.dart' as http;

class HistoryEvent {
  final String year;
  final String text;

  HistoryEvent({required this.year, required this.text});

  factory HistoryEvent.fromJson(Map<String, dynamic> json) {
    return HistoryEvent(
      year: json['year']?.toString() ?? '',
      text: json['text'] as String? ?? '',
    );
  }
}

class HistoryService {
  static Future<List<HistoryEvent>> fetchEvents(int month, int day) async {
    final m = month.toString().padLeft(2, '0');
    final d = day.toString().padLeft(2, '0');
    final url = Uri.parse('https://de.wikipedia.org/api/rest_v1/feed/onthisday/events/$m/$d');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final eventsJson = data['events'] as List;
        List<HistoryEvent> events = eventsJson.map((e) => HistoryEvent.fromJson(e)).toList();
        
        // Zufällige 5 Ereignisse auswählen (wie in Anforderung JS-Kalenderblatt 1/3)
        events.shuffle();
        return events.take(5).toList();
      } else {
        throw Exception('API Fehler: Statuscode ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Fehler beim Abrufen der Historie: $e');
    }
  }
}
