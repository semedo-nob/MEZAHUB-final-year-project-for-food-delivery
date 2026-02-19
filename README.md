# MezaHub

A modern food delivery mobile application built with Flutter. MezaHub connects hungry customers with their favorite restaurants, offering a seamless experience from browsing menus to live order tracking.

## About

MezaHub is a final-year project that delivers a full-featured food ordering platform with real-time updates, order tracking, and a polished user interface.

## Features

- **User Authentication** — Sign up and log in with email or Google Sign-In
- **Menu Browsing** — Browse dishes by category (Pizza, Burger, and more) with search
- **Shopping Cart** — Add items, adjust quantities, and manage your order
- **Checkout** — Secure checkout flow with delivery details
- **Order Management** — View order history and current order status
- **Live Order Tracking** — Real-time tracking on Google Maps with ETA
- **Favorites** — Save your favorite meals for quick reordering
- **Push Notifications** — Stay updated on order status
- **Dark & Light Themes** — Toggle between themes for comfortable viewing
- **Offline Support** — Local storage for a smoother experience

## Tech Stack

- **Framework:** Flutter (Dart)
- **State Management:** Provider
- **Backend:** Firebase (Auth, Firestore, Realtime Database, Messaging, Storage) & Supabase
- **Maps & Location:** Google Maps Flutter, Geolocator, Geocoding
- **Storage:** SQLite (local), SharedPreferences

## Project Structure

```
MEZAHUB-final-year-project-for-food-delivery/
└── swift_dine/                 # Flutter application
    ├── lib/
    │   ├── main.dart
    │   ├── data/               # Menu data
    │   ├── model/              # Data models
    │   ├── pages/              # Screens (Home, Cart, Orders, etc.)
    │   ├── provider/           # State management
    │   ├── services/           # Auth, Firebase, Sync, etc.
    │   ├── theme/              # App theming
    │   └── widgets/            # Reusable UI components
    └── pubspec.yaml
```

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (^3.9.2)
- Firebase project configured for iOS/Android
- Supabase project (optional, for backend features)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/MEZAHUB-final-year-project-for-food-delivery.git
   cd MEZAHUB-final-year-project-for-food-delivery/swift_dine
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Configure Firebase:
   - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Update `lib/firebase_options.dart` if needed

4. Run the app:
   ```bash
   flutter run
   ```

### Building for Release

- **Android:** `flutter build apk` or `flutter build appbundle`
- **iOS:** `flutter build ios`

## Author

**Nelson**  
📧 nelsonapidi75@gmail.com

## License

This project is developed as a final-year academic project.

---

*MezaHub — Order your meal with ease.*
