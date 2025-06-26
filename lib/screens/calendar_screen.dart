import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/training_note.dart';
import '../services/storage_service.dart';
import 'note_creation_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final ValueNotifier<List<TrainingNote>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final StorageService _storageService = StorageService();
  Map<DateTime, List<TrainingNote>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
    _loadNotes();
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    // Clean up duplicates first
    await _storageService.cleanupDuplicateDates();
    
    final notes = await _storageService.getNotes();
    final Map<DateTime, List<TrainingNote>> events = {};
    
    for (final note in notes) {
      final date = DateTime(note.date.year, note.date.month, note.date.day);
      events[date] = [note]; // Only one note per date
    }
    
    setState(() {
      _events = events;
      _selectedEvents.value = _getEventsForDay(_selectedDay!);
    });
  }

  List<TrainingNote> _getEventsForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return _events[date] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📅 トレーニングカレンダー'),
        backgroundColor: const Color(0xFF8B4513),
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final selectedDate = _selectedDay ?? DateTime.now();
              final existingNote = await _storageService.getNoteForDate(selectedDate);
              
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NoteCreationScreen(
                    existingNote: existingNote,
                    selectedDate: selectedDate,
                  ),
                ),
              );
              _loadNotes(); // Refresh notes after returning
            },
          ),
        ],
      ),
      backgroundColor: const Color(0xFFFAF6F0),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TableCalendar<TrainingNote>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              eventLoader: _getEventsForDay,
              startingDayOfWeek: StartingDayOfWeek.monday,
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                weekendTextStyle: const TextStyle(color: Colors.red),
                holidayTextStyle: const TextStyle(color: Colors.red),
                selectedDecoration: const BoxDecoration(
                  color: Color(0xFF8B4513),
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: const Color(0xFF8B4513).withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                markerDecoration: const BoxDecoration(
                  color: Color(0xFFFF6B6B),
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 1,
                canMarkersOverflow: false,
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                formatButtonShowsNext: false,
                formatButtonDecoration: BoxDecoration(
                  color: Color(0xFF8B4513),
                  borderRadius: BorderRadius.all(Radius.circular(12.0)),
                ),
                formatButtonTextStyle: TextStyle(
                  color: Colors.white,
                ),
              ),
              onDaySelected: (selectedDay, focusedDay) {
                if (!isSameDay(_selectedDay, selectedDay)) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  _selectedEvents.value = _getEventsForDay(selectedDay);
                }
              },
              onFormatChanged: (format) {
                if (_calendarFormat != format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                }
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
            ),
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              child: ValueListenableBuilder<List<TrainingNote>>(
                valueListenable: _selectedEvents,
                builder: (context, value, _) {
                  if (value.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_note,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _selectedDay != null
                                ? '${DateFormat('M月d日').format(_selectedDay!)}のトレーニング記録はありません'
                                : 'トレーニング記録はありません',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontFamily: 'serif',
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final selectedDate = _selectedDay ?? DateTime.now();
                              final existingNote = await _storageService.getNoteForDate(selectedDate);
                              
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => NoteCreationScreen(
                                    existingNote: existingNote,
                                    selectedDate: selectedDate,
                                  ),
                                ),
                              );
                              _loadNotes();
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('新しいノートを作成'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8B4513),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: value.length,
                    itemBuilder: (context, index) {
                      final note = value[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(
                            color: const Color(0xFFE8E1D9),
                            width: 1,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: const BoxDecoration(
                              color: Color(0xFF8B4513),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.fitness_center,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          title: Text(
                            DateFormat('HH:mm').format(note.date),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'serif',
                              color: Color(0xFF5D4037),
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                note.bodyWeight != null ? '体重: ${note.bodyWeight}kg' : '体重: 記録なし',
                                style: const TextStyle(
                                  fontFamily: 'serif',
                                  color: Color(0xFF8B4513),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${note.exercises.where((e) => e.name.isNotEmpty).length}種目',
                                style: const TextStyle(
                                  fontFamily: 'serif',
                                  color: Color(0xFF8B4513),
                                ),
                              ),
                            ],
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            color: Color(0xFF8B4513),
                            size: 16,
                          ),
                          onTap: () {
                            final noteDate = DateTime(note.date.year, note.date.month, note.date.day);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NoteCreationScreen(
                                  existingNote: note,
                                  selectedDate: noteDate,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}