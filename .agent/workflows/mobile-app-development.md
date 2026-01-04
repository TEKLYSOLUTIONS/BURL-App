---
description: Complete workflow for developing the Multi-Sport Coaching Platform mobile app with Flutter
---

# Multi-Sport Coaching Platform - Development Workflow (Flutter)

This workflow guides the complete development process from setup to deployment using Flutter.

## Phase 1: Project Setup & Infrastructure

### 1.1 Initialize Project Structure
```bash
# Navigate to project directory
cd "d:\My work\Cricket Coacing Platform"

# Create Flutter project
flutter create coaching_platform
cd coaching_platform
```

### 1.2 Configure pubspec.yaml Dependencies
Edit `pubspec.yaml` to add:
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Firebase
  firebase_core: ^2.24.0
  firebase_auth: ^4.15.0
  cloud_firestore: ^4.13.0
  firebase_storage: ^11.5.0
  firebase_messaging: ^14.7.0
  
  # State Management (choose one)
  flutter_riverpod: ^2.4.9
  # Or: provider: ^6.1.1
  # Or: flutter_bloc: ^8.1.3
  
  # Navigation
  go_router: ^12.1.3
  
  # UI & Widgets
  flutter_svg: ^2.0.9
  table_calendar: ^3.0.9
  fl_chart: ^0.65.0
  image_picker: ^1.0.5
  flutter_image_compress: ^2.1.0
  cached_network_image: ^3.3.0
  
  # Forms & Validation
  flutter_form_builder: ^9.1.1
  form_builder_validators: ^9.1.0
  
  # Utilities
  intl: ^0.18.1
  google_maps_flutter: ^2.5.0
  url_launcher: ^6.2.1
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
  build_runner: ^2.4.6
  json_serializable: ^6.7.1
  integration_test:
    sdk: flutter
```

### 1.3 Install Dependencies
```bash
# Get dependencies
flutter pub get

# Run code generation for models
flutter pub run build_runner build --delete-conflicting-outputs
```

### 1.4 Setup Development Environment
```bash
# Check Flutter installation
fletcher doctor -v

# Ensure toolchains are ready
# iOS (macOS only): Xcode, CocoaPods
# Android: Android Studio, Android SDK
```

## Phase 2: Backend Setup

### 2.1 Firebase Configuration
1. Create Firebase project at console.firebase.google.com
2. Enable Authentication (Phone & Email)
3. Create Firestore database
4. Enable Firebase Storage
5. Download configuration files:
   - `google-services.json` → Place in `android/app/`
   - `GoogleService-Info.plist` → Place in `ios/Runner/`
6. Configure FlutterFire:
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase for your Flutter app
flutterfire configure
```

### 2.2 Database Schema Design
Create Firestore collections:
- `users` - User profiles with roles
- `players` - Player profiles
- `coaches` - Coach profiles
- `sessions` - Session definitions
- `bookings` - Booking records
- `feedback` - Session feedback
- `earnings` - Coach earnings tracking

### 2.3 Firestore Security Rules
Configure security rules in Firebase Console

## Phase 3: Core Feature Development

### 3.1 Authentication & Onboarding
- [ ] Create `lib/models/` directory with Dart models
- [ ] Implement Firebase Auth service in `lib/services/auth_service.dart`
- [ ] Create role selection screen
- [ ] Build Guardian onboarding flow
- [ ] Build Self-managed Player onboarding flow
- [ ] Build Coach onboarding flow
- [ ] Implement player creation wizard

### 3.2 Navigation System
- [ ] Setup go_router in `lib/navigation/app_router.dart`
- [ ] Create Guardian bottom navigation bar
- [ ] Create Player bottom navigation bar
- [ ] Create Coach bottom navigation bar
- [ ] Implement role-based navigation logic

### 3.3 Guardian/Player Features
- [ ] Home screen with upcoming sessions
- [ ] Coach discovery/search screen
- [ ] Coach profile view
- [ ] Booking flow (1:1 sessions)
- [ ] Booking flow (Group sessions)
- [ ] Players management screen (Guardian only)
- [ ] Player context switching
- [ ] Sessions list screen
- [ ] Session detail view
- [ ] Feedback view

### 3.4 Coach Features
- [ ] Coach home dashboard
- [ ] Profile management screen
- [ ] Session type definition
- [ ] Availability calendar (using table_calendar)
- [ ] Session management
- [ ] Participant list view
- [ ] Feedback submission
- [ ] Earnings dashboard (using fl_chart)
- [ ] Earnings detail view
- [ ] Players list

### 3.5 Shared Widgets
- [ ] Custom button widgets
- [ ] CustomTextField widgets
- [ ] Card widgets
- [ ] Modal/Dialog widgets
- [ ] Loading indicators
- [ ] Error state widgets
- [ ] Empty state widgets
- [ ] Notification system

## Phase 4: Design Implementation

### 4.1 Create Design System
Create `lib/config/theme.dart`:
- [ ] Define color palette using ColorScheme
- [ ] Typography using TextTheme
- [ ] Spacing constants
- [ ] Custom ThemeData
- [ ] Icon set (Material Icons + custom)

### 4.2 Screen Designs
Implement all 30+ screens listed in PRD Section 10 using Material Design 3

## Phase 5: Testing

### 5.1 Unit Testing
```bash
# Run unit tests
flutter test

# Run with coverage
flutter test --coverage

# View coverage report
genhtml coverage/lcov.info -o coverage/html
```

### 5.2 Widget Testing
- [ ] Test individual widgets
- [ ] Test authentication screens
- [ ] Test booking flow widgets
- [ ] Test role switching

### 5.3 Integration Testing
```bash
# Run integration tests
flutter test integration_test

# Run on specific device
flutter test integration_test --device-id=<device_id>
```

### 5.4 Manual Testing
- [ ] Test on iOS simulator (iPhone SE, iPhone 14, iPhone 14 Pro Max)
- [ ] Test on Android emulator (Pixel 5, Samsung Galaxy S21)
- [ ] Test on physical iOS device
- [ ] Test on physical Android device
- [ ] Test offline scenarios
- [ ] Test edge cases (booking conflicts, capacity limits)

## Phase 6: Optimization

### 6.1 Performance
- [ ] Optimize build size
- [ ] Implement lazy loading for screens
- [ ] Add image caching with cached_network_image
- [ ] Implement efficient list rendering with ListView.builder
- [ ] Reduce app load time to < 3s
- [ ] Profile app performance with DevTools

### 6.2 Accessibility
- [ ] Add Semantics widgets for screen readers
- [ ] Test with TalkBack (Android) and VoiceOver (iOS)
- [ ] Ensure color contrast compliance (WCAG AA)
- [ ] Implement proper touch target sizes (48x48dp minimum)
- [ ] Support text scaling

## Phase 7: Deployment Preparation

### 7.1 Build Configuration

#### iOS Build
```bash
# Build iOS release
flutter build ios --release

# Or build IPA
flutter build ipa
```

#### Android Build
```bash
# Build APK
flutter build apk --release

# Build App Bundle (recommended for Play Store)
flutter build appbundle --release
```

### 7.2 App Store Submission (iOS)
- [ ] Create App Store Connect account
- [ ] Configure app icons in `ios/Runner/Assets.xcassets`
- [ ] Create app screenshots (6.5", 5.5", 12.9" sizes)
- [ ] Write app description
- [ ] Upload build via Xcode or Transporter
- [ ] Submit for review

### 7.3 Google Play Submission (Android)
- [ ] Create Google Play Console account
- [ ] Configure app icons and feature graphics
- [ ] Create screenshots (Phone, 7" Tablet, 10" Tablet)
- [ ] Write app description
- [ ] Upload App Bundle
- [ ] Submit for review

## Phase 8: Post-Launch

### 8.1 Monitoring
- [ ] Setup Firebase Analytics
- [ ] Setup Firebase Crashlytics
```bash
flutter pub add firebase_analytics
flutter pub add firebase_crashlytics
```
- [ ] Monitor performance metrics
- [ ] Track user engagement
- [ ] Monitor crash reports

### 8.2 Iteration
- [ ] Collect user feedback via in-app feedback form
- [ ] Prioritize bug fixes based on crash reports
- [ ] Plan feature enhancements (facility booking, payments)
- [ ] Release regular updates
- [ ] A/B test UI variations with Firebase Remote Config

## Development Commands Reference

### Running the App
```bash
# List available devices
flutter devices

# Run on iOS simulator (auto-selected)
flutter run

# Run on Android emulator
flutter run

# Run on specific device
flutter run -d <device-id>

# Run in release mode
flutter run --release

# Hot reload: Press 'r' in terminal
# Hot restart: Press 'R' in terminal
```

### Debugging
```bash
# Open DevTools
flutter pub global activate devtools
flutter pub global run devtools

# View logs
flutter logs

# Attach to running app
flutter attach
```

### Code Quality
```bash
# Analyze code
flutter analyze

# Format code
flutter format lib/

# Check for outdated packages
flutter pub outdated

# Upgrade packages
flutter pub upgrade
```

### Building & Testing
```bash
# Clean build
flutter clean
flutter pub get

# Build for specific platform
flutter build ios
flutter build apk
flutter build appbundle

# Test
flutter test
flutter test --coverage
flutter drive --target=test_driver/app.dart
```

## Project Structure
```
lib/
├── main.dart                   # App entry point
├── config/
│   ├── firebase_config.dart   # Firebase initialization
│   └── theme.dart              # App theme & design system
├── models/                     # Data models
│   ├── user.dart
│   ├── player.dart
│   ├── coach.dart
│   ├── session.dart
│   └── booking.dart
├── providers/                  # Riverpod providers / BLoC
│   ├── auth_provider.dart
│   ├── user_provider.dart
│   └── booking_provider.dart
├── services/                   # Firebase & API services
│   ├── auth_service.dart
│   ├── firestore_service.dart
│   └── storage_service.dart
├── navigation/
│   └── app_router.dart         # go_router configuration
├── screens/                    # All screens organized by feature
│   ├── auth/
│   ├── onboarding/
│   ├── guardian/
│   ├── player/
│   └── coach/
├── widgets/                    # Reusable widgets
│   ├── buttons/
│   ├── inputs/
│   ├── cards/
│   └── navigation/
└── utils/                      # Helper functions
    ├── validators.dart
    ├── constants.dart
    └── date_helpers.dart
```

## Key Principles

1. **Mobile-First**: Flutter's native compilation ensures optimal mobile performance
2. **Role-Based**: Clear separation between Guardian, Player, and Coach experiences
3. **Performance**: App load < 3s, booking confirmation < 2s
4. **Simplicity**: ≤ 4 steps to book, one primary CTA per screen
5. **Sport-Agnostic**: Design works for all sports, not just cricket
6. **Material Design 3**: Leveraging Flutter's built-in Material Design components

## Debugging Tips

### Common Issues
- **Hot reload not working**: Try hot restart (R) or full restart
- **Firebase not configured**: Run `flutterfire configure` again
- **Build errors after pubspec changes**: Run `flutter clean && flutter pub get`
- **iOS build issues**: Delete `ios/Pods`, `ios/Podfile.lock`, run `pod install`
- **Android build issues**: Clean Android build: `cd android && ./gradlew clean`

### Performance Profiling
```bash
# Profile app performance
flutter run --profile

# Open DevTools performance view
# Then record performance while using the app
```

## Reference Documents
- PRD: `PRODUCT REQUIREMENTS DOCUMENT.docx`
- Task Tracker: `C:\Users\aksha\.gemini\antigravity\brain\1cfebae8-6f98-4ca5-a2f0-94c94a4aa0ab\task.md`
- Implementation Plan: `C:\Users\aksha\.gemini\antigravity\brain\1cfebae8-6f98-4ca5-a2f0-94c94a4aa0ab\implementation_plan.md`
