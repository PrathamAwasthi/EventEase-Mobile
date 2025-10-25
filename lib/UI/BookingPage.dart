import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Database/App_DB.dart';

class BookingPage extends StatefulWidget {
  final Event event;
  const BookingPage({super.key, required this.event});

  @override
  State<StatefulWidget> createState() {
    return BookingPageState();
  }
}

class BookingPageState extends State<BookingPage> {
  late int _currentBookingCount;
  bool _isBooking = false;
  String _eventStatus = 'Unknown';
  int _remainingSeats = 0;
  bool _userHasBooked = false;

  @override
  void initState() {
    super.initState();
    _currentBookingCount = widget.event.bookingCount ?? 0;
    _eventStatus = getEventStatus(widget.event.date);
    _updateRemainingSeats();
    _checkIfUserBooked();
  }

  void _updateRemainingSeats() {
    setState(() {
      _remainingSeats = widget.event.capacity - _currentBookingCount;
    });
  }

  Future<void> _checkIfUserBooked() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    if (userId == null) return;

    bool booked =
    await DataBase.instance.checkUserBookingExists(userId, widget.event.id);
    if (mounted) {
      setState(() {
        _userHasBooked = booked;
      });
    }
  }

  Future<void> _handleBooking() async {
    setState(() => _isBooking = true);

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');

    if (userId == null) {
      if (mounted) {
        showSnackBar(context, 'User not found, please login again.',
            isError: true);
      }
      setState(() => _isBooking = false);
      return;
    }

    final result = await DataBase.instance.createBooking(userId, widget.event);

    if (mounted) {
      if (result.startsWith('Success')) {
        showSnackBar(context, result);
        setState(() {
          _currentBookingCount++;
          _userHasBooked = true;
          _updateRemainingSeats();
        });
      } else {
        showSnackBar(context, result, isError: true);
      }
    }

    setState(() => _isBooking = false);
  }

  @override
  Widget build(BuildContext context) {

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.event.title),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Title
              Text(
                widget.event.title,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              Chip(
                label: Text(_eventStatus),
                backgroundColor: getChipBackgroundColor(_eventStatus),
                labelStyle: TextStyle(
                  color: getStatusColor(_eventStatus),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              InfoRow(icon: Icons.calendar_today, text: widget.event.date),
              const SizedBox(height: 12),
              InfoRow(icon: Icons.location_on, text: widget.event.location),
              const SizedBox(height: 24),
              Text(
                "Description",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Divider(),
              Text(
                widget.event.description,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),

              InfoRow(
                icon: Icons.people,
                text:
                "Remaining Seats: $_remainingSeats / ${widget.event.capacity}",
              ),

              const Spacer(),

              if (_isBooking)
                const Center(child: CircularProgressIndicator())
              else
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _getButtonOnPressed(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _userHasBooked ? Colors.grey : Colors.indigo,
                    ),
                    child: Text(_getButtonText(), style: TextStyle(color: Colors.white),),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getButtonText() {
    if (_userHasBooked) return 'Already Booked';
    if (_eventStatus != 'Upcoming') return 'Booking Closed';
    if (_remainingSeats <= 0) return 'Event Full';
    return 'Book Now (1 Seat)';
  }

  VoidCallback? _getButtonOnPressed() {
    if (_isBooking || _userHasBooked || _eventStatus != 'Upcoming' || _remainingSeats <= 0) {
      return null;
    }
    return _handleBooking;
  }
}

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const InfoRow({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[700]),
        const SizedBox(width: 16),
        Text(text, style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }
}
