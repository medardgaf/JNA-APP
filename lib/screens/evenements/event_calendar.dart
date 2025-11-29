import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../services/event_service.dart';

class EventCalendarScreen extends StatefulWidget {
  const EventCalendarScreen({super.key});

  @override
  State<EventCalendarScreen> createState() => _EventCalendarScreenState();
}

class _EventCalendarScreenState extends State<EventCalendarScreen> {
  Map<DateTime, List<dynamic>> eventsByDate = {};
  DateTime focused = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final res = await EventService.getAll();
    final list = res["data"] ?? [];

    Map<DateTime, List> map = {};

    for (var e in list) {
      final date = DateTime.parse(e["date_debut"]);
      final key = DateTime(date.year, date.month, date.day);

      map[key] ??= [];
      map[key]!.add(e);
    }

    setState(() => eventsByDate = map);
  }

  List _getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return eventsByDate[key] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Calendrier"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          TableCalendar(
            focusedDay: focused,
            firstDay: DateTime(2020),
            lastDay: DateTime(2090),
            eventLoader: _getEventsForDay,
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarStyle: CalendarStyle(
              markerDecoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
            onDaySelected: (selected, f) {
              setState(() => focused = selected);
            },
          ),
          Expanded(
            child: ListView(
              children: _getEventsForDay(focused)
                  .map((e) => ListTile(
                        title: Text(e["titre"]),
                        subtitle: Text(e["date_debut"]),
                        leading: CircleAvatar(
                          backgroundColor: _hexToColor(e["couleur"]),
                        ),
                      ))
                  .toList(),
            ),
          )
        ],
      ),
    );
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll("#", "");
    return Color(int.parse("FF$hex", radix: 16));
  }
}
