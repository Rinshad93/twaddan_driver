# twaddan_driver
Driver Delivery App
-------------------

Core Features
-------------
Authentication: Secure login with email/phone validation
Driver Management: Profile management with online/offline status
Order Management: Accept/decline orders, real-time status tracking
Navigation: Google Maps integration with GPS routing
Earnings Tracking: Daily/weekly earnings with detailed analytics
Real-time Updates: Live order status and location sharing

Advanced Features
-----------------
Analytics Dashboard: Performance insights and earnings trends
Goal Setting: Custom earning goals with progress tracking
Document Management: Driver document upload and verification
Background Services: Location tracking when app is backgrounded
Push Notifications: Real-time order alerts and status updates
Settings: Comprehensive app configuration

Architecture
-----------
📁 Core Layer (Shared)
├── Constants (Colors, Strings, Dimensions)
├── Utils (Validators, Extensions, Helpers)
└── Widgets (Reusable UI components)

📁 Data Layer
├── Models (Data structures)
├── Repositories (Abstract interfaces)
├── Services (Concrete implementations)
└── Mock (Development data)

📁 Presentation Layer
├── BLoC (State management)
├── Screens (UI pages)
└── Widgets (Screen-specific components)

rerequisites
------------
Flutter SDK 3.8.1 or higher
Dart 3.0+
Android Studio / VS Code
Android SDK (for Android builds)
Xcode (for iOS builds)

Configure Google Maps
---------------------
Get API key from Google Cloud Console
Add to android/app/src/main/AndroidManifest.xml:
xml<meta-data android:name="com.google.android.geo.API_KEY"
android:value="YOUR_API_KEY"/>


Demo Credentials
-----------------
Email: john.smith@driver.com
Password: 123456
Phone: +1 (555) 123-4567