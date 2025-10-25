import 'package:eventease/UI/BookingPage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Database/App_DB.dart';
import 'AuthenticationPage.dart';
import 'MyBookingsPage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() {
    return HomePageState();
  }
}

class HomePageState extends State<HomePage> {
  late Future<bool> _dataLoadFuture;
  final TextEditingController _searchController = TextEditingController();
  String? _selectedLocation;
  String? _selectedStatus;
  List<String> _locations = [];

  List<Event> _allEvents = [];
  List<Event> _filteredEvents = [];
  String _username = "User";

  @override
  void initState() {
    super.initState();
    _dataLoadFuture = _loadData();

    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilters);
    _searchController.dispose();
    super.dispose();
  }

  Future<bool> _loadData() async {
    _allEvents = await DataBase.instance.getEvents();
    _filteredEvents = List.from(_allEvents);

    _locations = _allEvents.map((e) => e.location).toSet().toList();

    await _loadUsername();
    _applyFilters();
    return true;
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _username = prefs.getString('username') ?? "User";
      });
    }
  }

  void _applyFilters() {
    List<Event> tempEvents = List.from(_allEvents);

    final String query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      tempEvents = tempEvents
          .where((event) => event.title.toLowerCase().contains(query))
          .toList();
    }

    if (_selectedLocation != null) {
      tempEvents = tempEvents
          .where((event) => event.location == _selectedLocation)
          .toList();
    }

    if (_selectedStatus != null) {
      tempEvents = tempEvents
          .where((event) => getEventStatus(event.date) == _selectedStatus)
          .toList();
    }

    if (mounted) {
      setState(() {
        _filteredEvents = tempEvents;
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const AuthenticationPage()),
            (route) => false,
      );
    }
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _selectedLocation = null;
      _selectedStatus = null;
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Welcome, $_username",
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const Text(
                "Available Events",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: _logout,
            ),
          ],
        ),
        body: FutureBuilder<bool>(
          future: _dataLoadFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            else {
              return Column(
                children: [
                  _buildFilterSection(),
                  Expanded(
                    child: _filteredEvents.isEmpty
                        ? const Center(
                      child: Text(
                        'No events found matching your criteria.',
                        textAlign: TextAlign.center,
                      ),
                    )
                        : RefreshIndicator(
                      onRefresh: () async {
                        setState(() {
                          _dataLoadFuture = _loadData();
                        });
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12.0),
                        itemCount: _filteredEvents.length,
                        itemBuilder: (context, index) {
                          final event = _filteredEvents[index];
                          return EventCard(
                            event: event,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      BookingPage(event: event),
                                ),
                              );
                              setState(() {
                                _dataLoadFuture = _loadData();
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            }
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MyBookingsPage()),
            );
            setState(() {
              _dataLoadFuture = _loadData();
            });
          },
          label: const Text('My Bookings'),
          icon: const Icon(Icons.confirmation_number_outlined),
          backgroundColor: Colors.indigo.shade50,
          foregroundColor: Colors.indigo.shade700,
          elevation: 1,
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by event title...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                },
              )
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedLocation,
                  hint: const Text('Location'),
                  isExpanded: true,
                  decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.location_on_outlined)
                  ),
                  items: _locations.map((String location) {
                    return DropdownMenuItem<String>(
                      value: location,
                      child: Text(location, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedLocation = newValue;
                    });
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  hint: const Text('Status'),
                  decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.flag_outlined)
                  ),
                  items: ['Upcoming', 'Ongoing', 'Completed']
                      .map((String status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(status),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedStatus = newValue;
                    });
                    _applyFilters();
                  },
                ),
              ),
            ],
          ),
          // Reset Button
          if (_searchController.text.isNotEmpty ||
              _selectedLocation != null ||
              _selectedStatus != null)
            TextButton(
              onPressed: _resetFilters,
              child: const Text('Clear All Filters'),
            )
        ],
      ),
    );
  }
}

class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
  });

  final Event event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = getEventStatus(event.date);
    final statusColor = getStatusColor(status);
    final chipBgColor = getChipBackgroundColor(status);

    final int bookedSeats = event.bookingCount ?? 0;
    final int remainingSeats = event.capacity - bookedSeats;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      event.title,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(status),
                    backgroundColor: chipBgColor,
                    labelStyle: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    padding: EdgeInsets.zero,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 16, color: Colors.grey[700]),
                  const SizedBox(width: 8),
                  Text(
                    event.date,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 16, color: Colors.grey[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    // Taaki location wrap ho sake
                    child: Text(
                      event.location,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.people_outline,
                      size: 16, color: Colors.grey[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Seats Left: $remainingSeats / ${event.capacity}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: remainingSeats < 10 && remainingSeats > 0
                          ? Colors.orange.shade800
                          : (remainingSeats == 0 ? Colors.red.shade700 : Colors.black87),
                      fontWeight: remainingSeats < 10
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
