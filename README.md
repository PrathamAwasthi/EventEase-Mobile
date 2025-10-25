# eventease

A new Flutter project.

## Getting Started

EventEase Mobile - Flutter Event Booking App

EventEase Mobile is a cross-platform event booking application built with Flutter & Dart, as part of the Koders Flutter Developer Assignment. The app allows users to browse events, book tickets, and manage their bookings.

This project implements all core assignment requirements and several bonus features, using SQLite as a local database instead of the specified backend (per clarification) to create a self-contained mobile application.

Features Implemented

Core Features

User Authentication:

Secure user registration and login.

User sessions are managed locally using shared_preferences.

Event Browsing:

Dynamic list of all available events fetched from the local SQLite database.

Events automatically display their status: Upcoming, Ongoing, or Completed.

Event Details:

A detailed screen for each event showing its full description, date, location, and booking status.

Booking System:

Logged-in users can book one seat per event.

The app prevents booking if the user has already booked or if the event is at full capacity.

Booking Management:

A "My Bookings" screen where users can view all their booked tickets.

Users can cancel a booking only if the event is still Upcoming.

Unique Booking IDs:

Generates a unique booking ID for every new booking (e.g., BKG-OCT2025-A9Z).

Bonus Features

Search Functionality:

Users can search for events by their title from the home screen.

Advanced Filtering:

Users can filter the event list by Location and Status (Upcoming, Ongoing, Completed).

Display Seat Availability:

The event list and detail pages clearly show the number of booked seats vs. total capacity (e.g., Booked: 5 / 50).

Polished & Responsive UI:

A clean, intuitive, and responsive user interface that works on various screen sizes.

Tech Stack & Libraries

Core: Flutter & Dart

Database: sqflite (For all app data: users, events, bookings)

State Management: provider (For managing authentication UI state)

Local Session: shared_preferences (For persisting user login state)

Date Formatting: intl (For consistent date formatting: DD-MMM-YYYY)

Path Management: path_provider & path (For locating the SQLite database)

Getting Started

Prerequisites

Flutter SDK (v3.x.x or newer)

A code editor (VS Code, Android Studio)

An emulator or physical device

Setup Instructions

Clone the Repository:

git clone [YOUR_GITHUB_REPO_LINK]
cd eventease_mobile

Add Dependencies:
Add the following dependencies to your pubspec.yaml file:

dependencies:
flutter:
sdk: flutter

# Database
sqflite: ^2.3.3+1
path_provider: ^2.1.3
path: ^1.9.0

# State Management
provider: ^6.1.2

# Local Session
shared_preferences: ^2.2.3

# Date/Time format
intl: ^0.19.0

cupertino_icons: ^1.0.6

Add Assets:

Create an assets folder in the root of your project.

Add your logo image to this folder (e.g., assets/logo_image.png).

Declare the asset in your pubspec.yaml:

flutter:
uses-material-design: true
assets:
- assets/logo_image.png

Install Packages:
Run the following command in your terminal:

flutter pub get

Run the App:

flutter run

The app will launch. The database and dummy events will be created automatically on the first run.

Application Structure

lib/
├── Database/
│   └── App_DB.dart         # Main SQLite database helper (models, queries, utils)
├── main.dart               # App entry point, Splash Screen, Auth Check
│
├── Provider/
│   └── AuthButtonState.dart  # Provider for Auth screen (Login/Register tab)
│
└── UI/
├── AuthenticationPage.dart # Login and Registration screen
├── HomePage.dart           # Main screen (Event List, Search, Filter)
├── BookingPage.dart        # Event Details and Booking screen
└── MyBookingsPage.dart     # User's booking list screen

