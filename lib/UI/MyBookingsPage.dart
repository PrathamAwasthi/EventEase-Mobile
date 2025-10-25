import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Database/App_DB.dart';

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> {
  late Future<List<Booking>> _bookingsFuture;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    if (userId != null) {
      if (mounted) {
        setState(() {
          _bookingsFuture = DataBase.instance.getUserBookings(userId);
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _bookingsFuture = Future.value([]);
        });
        showSnackBar(context, 'Could not find user. Please login again.',
            isError: true);
      }
    }
  }

  Future<void> _handleCancelBooking(int bookingId) async {
    final bool? shouldCancel = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking?'),
        content:
        const Text('Kya aap sach mein yeh booking cancel karna chahte hain?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (shouldCancel == true) {
      await DataBase.instance.cancelBooking(bookingId);
      if (mounted) {
        showSnackBar(context, 'Booking cancelled successfully');
      }
      _loadBookings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
      ),
      body: FutureBuilder<List<Booking>>(
        future: _bookingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Aapne abhi tak koi event book nahi kiya hai.',
                textAlign: TextAlign.center,
              ),
            );
          } else {
            final bookings = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final booking = bookings[index];
                final status = getEventStatus(booking.eventDate);
                final canCancel = status == 'Upcoming';

                return Card(
                  child: ListTile(
                    title: Text(
                      booking.eventTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Booking ID: ${booking.bookingId}'),
                        Text('Event Date: ${booking.eventDate}'),
                        Text(
                          'Status: $status',
                          style: TextStyle(
                            color: getStatusColor(status),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    trailing: Tooltip(
                      message: canCancel
                          ? 'Cancel this booking'
                          : 'Completed/Ongoing events cannot be cancelled',
                      child: TextButton(
                        onPressed: canCancel
                            ? () => _handleCancelBooking(booking.id)
                            : null,
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: canCancel ? Colors.red : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
