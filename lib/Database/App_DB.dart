import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:flutter/material.dart';

class User {
  final int? id;
  final String username;
  final String password;

  User({this.id, required this.username, required this.password});

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      password: map['password'],
    );
  }
}

class Event {
  final int id;
  final String title;
  final String description;
  final String date; // Format: DD-MMM-YYYY
  final String location;
  final int capacity;
  final int? bookingCount;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.location,
    required this.capacity,
    this.bookingCount, // Optional
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date,
      'location': location,
      'capacity': capacity,
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      date: map['date'],
      location: map['location'],
      capacity: map['capacity'],
      bookingCount: map['bookingCount'] as int?,
    );
  }
}

class Booking {
  final int id;
  final String bookingId;
  final int userId;
  final int eventId;
  final String eventTitle;
  final String eventDate;

  Booking({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.eventId,
    required this.eventTitle,
    required this.eventDate,
  });

  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
      id: map['id'],
      bookingId: map['bookingId'],
      userId: map['userId'],
      eventId: map['eventId'],
      eventTitle: map['eventTitle'],
      eventDate: map['eventDate'],
    );
  }
}

class DataBase {
  static final DataBase instance = DataBase._init();
  static Database? _database;
  DataBase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('EventEase.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, filePath);
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        date TEXT NOT NULL, 
        location TEXT NOT NULL,
        capacity INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE bookings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bookingId TEXT UNIQUE NOT NULL,
        userId INTEGER NOT NULL,
        eventId INTEGER NOT NULL,
        eventTitle TEXT NOT NULL,
        eventDate TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (eventId) REFERENCES events (id) ON DELETE CASCADE
      )
    ''');

    await _insertDummyEvents(db);
  }

  Future _insertDummyEvents(Database db) {
    final List<Map<String, dynamic>> dummyEvents = [
      {
        'title': 'Flutter Developer Conf',
        'description':
        'A grand conference for Flutter developers from all over the world. Join us for 2 days of learning and networking.',
        'date': '24-Nov-2025',
        'location': 'Mumbai, India',
        'capacity': 100,
      },
      {
        'title': 'Tech Meetup 2025',
        'description': 'Annual tech meetup. This time, we focus on AI and ML.',
        'date': '24-Dec-2025',
        'location': 'Bangalore, India',
        'capacity': 50,
      },
      {
        'title': 'Past Music Concert',
        'description': 'A concert that already happened.',
        'date': '15-Oct-2025', // Purani date
        'location': 'Pune, India',
        'capacity': 200,
      },
      {
        'title': 'Ongoing Art Exhibition',
        'description': 'Art exhibition happening today.',
        'date': DateFormat('dd-MMM-yyyy')
            .format(DateTime.now()), // Aaj ki date
        'location': 'Delhi, India',
        'capacity': 30,
      },
      {
        'title': 'The Grammy Awards',
        'description': 'The biggest night in music.',
        'date': '24-Nov-2025',
        'location': 'Bangalore, India',
        'capacity': 5,
      },
    ];

    Batch batch = db.batch();
    for (var event in dummyEvents) {
      batch.insert('events', event);
    }
    return batch.commit();
  }

  Future<User?> login(String username, String password) async {
    final db = await instance.database;
    final res = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
      limit: 1,
    );

    if (res.isNotEmpty) {
      return User.fromMap(res.first);
    }
    return null;
  }

  Future<bool> register(String username, String password) async {
    final db = await instance.database;
    try {
      await db.insert(
        'users',
        {'username': username, 'password': password},
        conflictAlgorithm: ConflictAlgorithm.fail,
      );
      return true; // Success
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return false; // Failure
    }
  }

  Future<List<Event>> getEvents() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> res = await db.rawQuery('''
      SELECT 
        E.*, 
        COUNT(B.id) as bookingCount
      FROM events E
      LEFT JOIN bookings B ON E.id = B.eventId
      GROUP BY E.id
    ''');

    return res.isNotEmpty ? res.map((e) => Event.fromMap(e)).toList() : [];
  }

  Future<Event> getEvent(int id) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> res = await db.rawQuery('''
      SELECT 
        E.*, 
        COUNT(B.id) as bookingCount
      FROM events E
      LEFT JOIN bookings B ON E.id = B.eventId
      WHERE E.id = ?
      GROUP BY E.id
    ''', [id]);

    return Event.fromMap(res.first);
  }

  Future<List<Booking>> getUserBookings(int userId) async {
    final db = await instance.database;
    final res =
    await db.query('bookings', where: 'userId = ?', whereArgs: [userId]);
    return res.isNotEmpty ? res.map((b) => Booking.fromMap(b)).toList() : [];
  }

  Future<int> getBookingCountForEvent(int eventId) async {
    final db = await instance.database;
    final res = await db.rawQuery(
        'SELECT COUNT(*) as count FROM bookings WHERE eventId = ?', [eventId]);
    return res.isNotEmpty ? (res.first['count'] as int) : 0;
  }

  Future<bool> checkUserBookingExists(int userId, int eventId) async {
    final db = await instance.database;
    final res = await db.query('bookings',
        where: 'userId = ? AND eventId = ?', whereArgs: [userId, eventId]);
    return res.isNotEmpty;
  }

  Future<String> createBooking(int userId, Event event) async {
    final db = await instance.database;

    bool alreadyBooked = await checkUserBookingExists(userId, event.id);
    if (alreadyBooked) {
      return 'Error: Aap is event ke liye pehle hi book kar chuke hain.';
    }

    int currentBookings = await getBookingCountForEvent(event.id);
    if (currentBookings >= event.capacity) {
      return 'Error: Sorry, yeh event full ho chuka hai.';
    }

    String bookingId = _generateBookingId();
    Map<String, dynamic> bookingMap = {
      'bookingId': bookingId,
      'userId': userId,
      'eventId': event.id,
      'eventTitle': event.title,
      'eventDate': event.date,
    };

    await db.insert('bookings', bookingMap);
    return 'Success: Booking confirmed! Aapki Booking ID hai: $bookingId';
  }

  Future<int> cancelBooking(int bookingId) async {
    final db = await instance.database;
    return await db
        .delete('bookings', where: 'id = ?', whereArgs: [bookingId]);
  }

  String _generateBookingId() {
    final String month =
    DateFormat('MMM').format(DateTime.now()).toUpperCase();
    final String year = DateFormat('yyyy').format(DateTime.now());
    const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final Random rnd = Random();
    final String random3 = String.fromCharCodes(Iterable.generate(
        3, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));

    return 'BKG-$month$year-$random3';
  }
}

String getEventStatus(String dateString) {
  try {
    final eventDate = DateFormat('dd-MMM-yyyy').parse(dateString);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final normalizedEventDate =
    DateTime(eventDate.year, eventDate.month, eventDate.day);

    if (normalizedEventDate.isAtSameMomentAs(today)) {
      return 'Ongoing';
    } else if (normalizedEventDate.isBefore(today)) {
      return 'Completed';
    } else {
      return 'Upcoming';
    }
  } catch (e) {
    return 'Unknown';
  }
}

Color getStatusColor(String status) {
  switch (status) {
    case 'Upcoming':
      return Colors.green.shade800;
    case 'Ongoing':
      return Colors.blue.shade800;
    case 'Completed':
      return Colors.grey.shade600;
    default:
      return Colors.black;
  }
}

Color getChipBackgroundColor(String status) {
  switch (status) {
    case 'Upcoming':
      return Colors.green.withOpacity(0.25);
    case 'Ongoing':
      return Colors.blue.withOpacity(0.25);
    case 'Completed':
      return Colors.grey.withOpacity(0.25);
    default:
      return Colors.grey.shade200;
  }
}

void showSnackBar(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : Colors.green,
    ),
  );
}
