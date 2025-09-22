import 'dart:async'; // Required for StreamSubscription
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  // State variable to hold the events from Firestore
  Map<DateTime, List<Map<String, dynamic>>> _firestoreEvents = {};
  late final StreamSubscription<QuerySnapshot> _eventsSubscription;
  bool _isLoading = true; // For initial loading indicator

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Start listening to the database stream when the page is created
    _listenToEvents();
  }

  void _listenToEvents() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    // Set up the background listener
    _eventsSubscription = _getEventsCollection().snapshots().listen(
      (snapshot) {
        if (!mounted) return;

        // Process the data from Firestore
        final newEvents = <DateTime, List<Map<String, dynamic>>>{};
        for (var doc in snapshot.docs) {
          final data = doc.data();
          if (data['date'] != null) {
            final date = (data['date'] as Timestamp).toDate();
            final event = {
              'id': doc.id,
              'title': data['title'],
              'time': data['time'],
            };
            final dateKey = DateUtils.dateOnly(date);
            newEvents.putIfAbsent(dateKey, () => []).add(event);
          }
        }

        // Update the local state, which will trigger a UI rebuild
        setState(() {
          _firestoreEvents = newEvents;
          _isLoading =
              false; // Turn off loading indicator after first data load
        });
      },
      onError: (error) {
        print("Error listening to events: $error");
        setState(() => _isLoading = false);
      },
    );
  }

  @override
  void dispose() {
    _eventsSubscription
        .cancel(); // CRUCIAL: Stop listening to prevent memory leaks
    _titleController.dispose();
    _timeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // --- (The rest of your code for adding, editing, deleting, dialogs, and UI widgets is UNCHANGED) ---

  CollectionReference<Map<String, dynamic>> _getEventsCollection() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null)
      throw Exception("User not found for calendar operations.");
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('events');
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _firestoreEvents[DateUtils.dateOnly(day)] ?? [];
  }

  void _addEvent() {
    _titleController.clear();
    _timeController.clear();
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) {
        return _eventDialog(
          title: "Add Event",
          onSave: () async {
            if (_titleController.text.isNotEmpty &&
                _timeController.text.isNotEmpty) {
              await _getEventsCollection().add({
                'title': _titleController.text,
                'time': _timeController.text,
                'date': Timestamp.fromDate(_selectedDay),
              });
              if (mounted) Navigator.pop(context);
            }
          },
        );
      },
    );
  }

  void _editEvent(Map<String, dynamic> eventToEdit) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) {
        return _eventDialog(
          title: "Edit Event",
          initialTitle: eventToEdit['title'],
          initialTime: eventToEdit['time'],
          onSave: () async {
            if (_titleController.text.isNotEmpty &&
                _timeController.text.isNotEmpty) {
              await _getEventsCollection().doc(eventToEdit['id']).update({
                'title': _titleController.text,
                'time': _timeController.text,
              });
              if (mounted) Navigator.pop(context);
            }
          },
        );
      },
    );
  }

  void _deleteEvent(String eventId) {
    _getEventsCollection().doc(eventId).delete();
  }

  void _showEventOptions(Map<String, dynamic> event) {
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  event["title"] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  event["time"] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: ListTile(
                    leading: Icon(
                      Icons.edit,
                      color: Colors.white.withOpacity(0.9),
                      size: 24,
                    ),
                    title: Text(
                      "Edit Event",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _editEvent(event);
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: ListTile(
                    leading: Icon(
                      Icons.delete,
                      color: Colors.red.withOpacity(0.9),
                      size: 24,
                    ),
                    title: Text(
                      "Delete Event",
                      style: TextStyle(
                        color: Colors.red.withOpacity(0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _deleteEvent(event['id']);
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _eventDialog({
    required String title,
    required VoidCallback onSave,
    String? initialTitle,
    String? initialTime,
  }) {
    _titleController.text = initialTitle ?? '';
    _timeController.text = initialTime ?? '';
    TimeOfDay? localPickedTime = _timeController.text.isNotEmpty
        ? _parseTimeOfDay(_timeController.text)
        : null;
    return StatefulBuilder(
      builder: (context, setStateDialog) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: BorderSide(color: Colors.white.withOpacity(0.2)),
          ),
          title: Center(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 20,
              ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: TextField(
                  controller: _titleController,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    labelText: "Event Title",
                    labelStyle: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    border: InputBorder.none,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Text(
                      "Time:",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: ElevatedButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: localPickedTime ?? TimeOfDay.now(),
                            );
                            if (picked != null) {
                              localPickedTime = picked;
                              _timeController.text = picked.format(context);
                              setStateDialog(() {});
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            elevation: 0,
                          ),
                          child: Text(
                            localPickedTime != null
                                ? localPickedTime!.format(context)
                                : (_timeController.text.isNotEmpty
                                      ? _timeController.text
                                      : "Pick time"),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            SizedBox(
              width: 120,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.15),
                  foregroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                    side: BorderSide(color: Colors.red.withOpacity(0.3)),
                  ),
                ),
                child: const Text(
                  "Cancel",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 120,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  side: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                onPressed: onSave,
                child: const Text(
                  "Save",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  TimeOfDay _parseTimeOfDay(String formatted) {
    try {
      final regex = RegExp(
        r'(\d{1,2}):(\d{2})\s*(AM|PM)',
        caseSensitive: false,
      );
      final match = regex.firstMatch(formatted);
      if (match != null) {
        int hour = int.parse(match.group(1)!);
        final minute = int.parse(match.group(2)!);
        final ampm = match.group(3)!.toUpperCase();
        if (ampm == 'PM' && hour != 12) hour += 12;
        if (ampm == 'AM' && hour == 12) hour = 0;
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (_) {}
    return TimeOfDay.now();
  }

  Widget _eventCard({
    required String title,
    required String time,
    required VoidCallback onEdit,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.schedule,
              color: Colors.white.withOpacity(0.9),
              size: 24,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  time,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: IconButton(
              onPressed: onEdit,
              icon: Icon(
                Icons.edit,
                color: Colors.white.withOpacity(0.9),
                size: 20,
              ),
              tooltip: 'Edit event',
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Please log in to use the calendar.")),
      );
    }

    final todayEvents = _getEventsForDay(_selectedDay);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Events",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        shape: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.2))),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _addEvent,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black, Color(0xFF111111), Colors.black],
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: TableCalendar(
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) =>
                            isSameDay(_selectedDay, day),
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                        },
                        daysOfWeekHeight: 40,

                        eventLoader: _getEventsForDay,
                        headerStyle: HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          headerPadding: const EdgeInsets.only(
                            top: 12.0,
                            bottom: 15.0,
                          ),
                          decoration: BoxDecoration(color: Colors.transparent),
                          titleTextStyle: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          leftChevronPadding: const EdgeInsets.all(8),
                          rightChevronPadding: const EdgeInsets.all(8),
                          leftChevronIcon: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.25),
                              ),
                            ),
                            child: Icon(
                              Icons.chevron_left,
                              color: Colors.white.withOpacity(0.9),
                              size: 20,
                            ),
                          ),
                          rightChevronIcon: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.25),
                              ),
                            ),
                            child: Icon(
                              Icons.chevron_right,
                              color: Colors.white.withOpacity(0.9),
                              size: 20,
                            ),
                          ),
                        ),
                        daysOfWeekStyle: DaysOfWeekStyle(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          weekdayStyle: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          weekendStyle: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        calendarStyle: CalendarStyle(
                          cellMargin: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 8,
                          ),
                          defaultTextStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                          weekendTextStyle: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                          outsideTextStyle: TextStyle(
                            color: Colors.white.withOpacity(0.3),
                            fontSize: 16,
                          ),
                          todayDecoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.4),
                              width: 2,
                            ),
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                          selectedTextStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          markersMaxCount: 1,
                          markerDecoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            shape: BoxShape.circle,
                          ),
                          markerSize: 8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.event_note,
                                  color: Colors.white.withOpacity(0.9),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  "Events for ${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}",
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Expanded(
                            child: todayEvents.isEmpty
                                // --- THIS IS THE MODIFIED SECTION ---
                                ? Container(
                                    // The outer Center widget is removed.
                                    // This container will now expand to fill the available width.
                                    padding: const EdgeInsets.all(32),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.1),
                                      ),
                                    ),
                                    // A Center widget is added INSIDE to center the content.
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.event_busy,
                                            color: Colors.white.withOpacity(
                                              0.4,
                                            ),
                                            size: 56,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            "No Events",
                                            style: GoogleFonts.inter(
                                              fontSize: 18,
                                              color: Colors.white.withOpacity(
                                                0.6,
                                              ),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                // The rest of the code remains the same
                                : Scrollbar(
                                    controller: _scrollController,
                                    thumbVisibility: true,
                                    thickness: 8,
                                    radius: const Radius.circular(10),
                                    trackVisibility: true,
                                    child: ListView.builder(
                                      controller: _scrollController,
                                      physics: const BouncingScrollPhysics(),
                                      padding: const EdgeInsets.only(
                                        bottom: 120,
                                      ),
                                      itemCount: todayEvents.length,
                                      itemBuilder: (context, index) {
                                        final event = todayEvents[index];
                                        return GestureDetector(
                                          onTap: () => _showEventOptions(event),
                                          child: _eventCard(
                                            title: event["title"] ?? '',
                                            time: event["time"] ?? '',
                                            onEdit: () => _editEvent(event),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                          ),
                          SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
