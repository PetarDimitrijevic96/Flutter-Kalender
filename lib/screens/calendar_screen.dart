import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../services/history_service.dart';
import '../services/notes_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _displayedMonth = DateTime.now();
  bool _isInit = false;
  bool _isWeekView = false;
  
  Future<List<HistoryEvent>>? _historyFuture;
  Set<DateTime> _daysWithNotes = {};
  List<String> _currentNotes = [];
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('de_DE', null).then((_) {
      setState(() {
        _isInit = true;
        _fetchMonthData(_displayedMonth);
        _fetchDayData(_selectedDate);
      });
    });
  }
  
  void _fetchMonthData(DateTime month) async {
    final notes = await NotesService.getDaysWithNotes(month.year, month.month);
    setState(() {
      _daysWithNotes = notes;
    });
  }

  void _fetchDayData(DateTime date) async {
    setState(() {
      _historyFuture = HistoryService.fetchEvents(date.month, date.day);
    });
    final notes = await NotesService.getNotes(date);
    setState(() {
      _currentNotes = notes;
      _noteController.clear();
    });
  }

  void _saveNote() async {
    if (_noteController.text.trim().isEmpty) return;
    
    final noteText = _noteController.text;
    final textLower = noteText.toLowerCase();
    final isCatEasterEgg = textLower.contains('katz') || textLower.contains('miau') || textLower.contains('meow');
    
    await NotesService.addNote(_selectedDate, noteText);
    _noteController.clear();
    _fetchMonthData(_displayedMonth);
    _fetchDayData(_selectedDate);
    if (!mounted) return;
    
    if (isCatEasterEgg) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey.shade900,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('🐱 Miau!', style: TextStyle(color: Colors.white, fontSize: 24)),
          content: const Text(
            'Du hast meine Katze gefunden 🐱!\n\nLiebe Grüße an Anastasia! 🐾', 
            style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5)
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Schnurr...', style: TextStyle(color: Colors.redAccent, fontSize: 16)),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notiz gespeichert', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
      );
    }
  }

  void _deleteNote(int index) async {
    await NotesService.deleteNote(_selectedDate, index);
    _fetchMonthData(_displayedMonth);
    _fetchDayData(_selectedDate);
  }

  String _generateInfoText() {
    int count = 0;
    for (int i = 1; i <= _selectedDate.day; i++) {
      DateTime d = DateTime(_selectedDate.year, _selectedDate.month, i);
      if (d.weekday == _selectedDate.weekday) {
        count++;
      }
    }
    final dayOfWeek = DateFormat('EEEE', 'de_DE').format(_selectedDate);
    bool isHoliday = _selectedDate.day == 6 && _selectedDate.month == 8; 
    String holidayText = isHoliday ? "ein" : "kein";

    return "Der ${DateFormat('d. MMMM y', 'de_DE').format(_selectedDate)} ist ein $dayOfWeek "
        "und zwar der $count. $dayOfWeek im Monat ${DateFormat('MMMM', 'de_DE').format(_selectedDate)} "
        "des Jahres ${_selectedDate.year}. Heute ist $holidayText gesetzlicher Feiertag.";
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInit) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final titleDate = DateFormat('dd.MM.yyyy', 'de_DE').format(_selectedDate);
    const isDark = true;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(color: isDark ? Colors.black.withOpacity(0.5) : const Color(0xFFF2F2F7).withOpacity(0.5)),
          ),
        ),
        title: Text('Kalenderblatt vom $titleDate'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildModernCard(
                    child: Text(
                      _generateInfoText(),
                      style: TextStyle(fontSize: 14, height: 1.5, color: isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildModernCard(
                    child: _buildCalendarGrid(),
                  ),
                  const SizedBox(height: 20),
                  _buildModernCard(
                    child: _buildTimelineSection(),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernCard({required Widget child}) {
    const isDark = true;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade900.withOpacity(0.6) : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: child,
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _displayedMonth,
      firstDate: DateTime(1900, 1),
      lastDate: DateTime(2100, 12),
    );
    if (picked != null && picked != _displayedMonth) {
      setState(() {
        _displayedMonth = DateTime(picked.year, picked.month, 1);
        _fetchMonthData(_displayedMonth);
      });
    }
  }

  Widget _buildCalendarGrid() {
    int emptyDays = DateTime(_displayedMonth.year, _displayedMonth.month, 1).weekday - 1;
    int totalDays = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;
    final weekdays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    
    // Week View Logic
    int startDayIndex = 0;
    int endDayIndex = emptyDays + totalDays;
    if (_isWeekView && _selectedDate.year == _displayedMonth.year && _selectedDate.month == _displayedMonth.month) {
       int selectedDayIndex = emptyDays + _selectedDate.day - 1;
       startDayIndex = selectedDayIndex - (selectedDayIndex % 7);
       endDayIndex = startDayIndex + 7;
    } else if (_isWeekView) {
      // If week view but selected date not in this month, just show first week
      endDayIndex = 7;
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                setState(() {
                  _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1, 1);
                  _fetchMonthData(_displayedMonth);
                });
              },
            ),
            GestureDetector(
              onTap: () => _selectDate(context),
              child: Text(
                DateFormat('MMMM yyyy', 'de_DE').format(_displayedMonth), 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                setState(() {
                  _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 1);
                  _fetchMonthData(_displayedMonth);
                });
              },
            ),
            IconButton(
              icon: Icon(_isWeekView ? Icons.unfold_more : Icons.unfold_less),
              tooltip: _isWeekView ? 'Monatsansicht' : 'Wochenansicht',
              onPressed: () {
                setState(() {
                  _isWeekView = !_isWeekView;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: weekdays.map((day) => _buildDayLabel(day)).toList(),
        ),
        const SizedBox(height: 10),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1.2,
            ),
            itemCount: endDayIndex - startDayIndex,
            itemBuilder: (context, index) {
              int actualIndex = startDayIndex + index;
              if (actualIndex < emptyDays || actualIndex >= emptyDays + totalDays) {
                 return const SizedBox();
              }
              
              int day = actualIndex - emptyDays + 1;
              DateTime dateForCell = DateTime(_displayedMonth.year, _displayedMonth.month, day);
              bool isSelected = DateUtils.isSameDay(dateForCell, _selectedDate);
              bool isToday = DateUtils.isSameDay(dateForCell, DateTime.now());
              bool isHoliday = dateForCell.day == 6 && dateForCell.month == 8; 
              bool hasNote = _daysWithNotes.contains(dateForCell);
              
              return _buildCalendarCell(dateForCell, day, isSelected, isToday, isHoliday, hasNote);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDayLabel(String title) {
    const isDark = true;
    return Expanded(
      child: Center(
        child: Text(
          title,
          style: TextStyle(
            color: isDark ? Colors.white54 : Colors.black.withOpacity(0.5),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarCell(DateTime dateForCell, int day, bool isSelected, bool isToday, bool isHoliday, bool hasNote) {
    const isDark = true;
    Color bgColor = Colors.transparent;
    Color txtColor = isDark ? Colors.white : Colors.black87;

    if (isSelected) {
      bgColor = isToday ? Colors.redAccent : (isDark ? Colors.white : Colors.black87);
      txtColor = isDark ? Colors.black : Colors.white;
    } else if (isToday) {
      txtColor = Colors.redAccent;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          _selectedDate = dateForCell;
        });
        _fetchDayData(dateForCell);
      },
      child: Center(
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                day.toString(),
                style: TextStyle(
                  color: txtColor,
                  fontSize: 14,
                  fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isHoliday && !isSelected)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      width: 4, height: 4,
                      decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle),
                    ),
                  if (hasNote && !isSelected)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      width: 4, height: 4,
                      decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                    ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineSection() {
    const isDark = true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Tagesansicht & Notizen",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                _noteController.text = "Miau";
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('🐾 Speicher die Notiz!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    backgroundColor: Colors.blueAccent.shade700,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Opacity(
                  opacity: 0.9,
                  child: const Text('🐾', style: TextStyle(fontSize: 22)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Notizen Eingabe
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _noteController,
                decoration: InputDecoration(
                  hintText: 'Persönliche Notiz hinzufügen...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.black26 : Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                maxLines: null,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _saveNote,
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(14),
                backgroundColor: isDark ? Colors.white : Colors.black87,
                foregroundColor: isDark ? Colors.black : Colors.white,
              ),
              child: const Icon(Icons.save),
            ),
          ],
        ),
        if (_currentNotes.isNotEmpty) ...[
          const SizedBox(height: 16),
          ...List.generate(_currentNotes.length, (index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.only(left: 16, right: 8, top: 8, bottom: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900.withOpacity(0.5) : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _currentNotes[index],
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87, height: 1.4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                    onPressed: () => _deleteNote(index),
                    tooltip: 'Notiz löschen',
                  ),
                ],
              ),
            );
          }),
        ],
        const SizedBox(height: 20),
        // History Events in Timeline Style
        FutureBuilder<List<HistoryEvent>>(
          future: _historyFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator()));
            } else if (snapshot.hasError) {
              return Text('Fehler: ${snapshot.error}', style: const TextStyle(color: Colors.red));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Text('Keine historischen Ereignisse gefunden.', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54));
            }

            final events = snapshot.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: events.map((e) {
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            margin: const EdgeInsets.only(top: 4, bottom: 4),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent,
                              shape: BoxShape.circle,
                              border: Border.all(color: isDark ? Colors.grey.shade900 : Colors.white, width: 2),
                            ),
                          ),
                          Expanded(
                            child: Container(width: 2, color: Colors.blueAccent.withOpacity(0.3)),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.year,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                e.text,
                                style: TextStyle(
                                  color: isDark ? Colors.white70 : Colors.black54,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
