# Cricket Coaching Platform

A comprehensive multi-sport coaching platform mobile application developed with Flutter.

## Overview

The Cricket Coaching Platform is designed to bridge the gap between coaches, players, and guardians. It facilitates seamless session management, player performance tracking, and effective communication.

## Key Features

### 👥 For Guardians & Players
- **Guardian Dashboard**: Redesigned home screen with profile tabs, calendar view, and performance metrics.
- **Player Management**: Add and edit player profiles, view detailed player statistics.
- **Session Tracking**: View upcoming and past coaching sessions.

### 📋 For Coaches
- **Session Management**: Create and schedule sessions with support for single or multi-day recurring schedules.
- **Performance Reporting**: Track and report on player progress (Batting, Bowling, etc.).
- **Coach Dashboard**: Centralized view for managing assigned players and schedules.

### 🔐 Authentication & Onboarding
- **Secure Authentication**: Robust Login and Registration flows.
- **Onboarding Experience**: tailored onboarding with a dynamic welcome screen featuring an auto-playing image carousel.

## Recent Updates

- **UI/UX Redesign**: Major overhaul of Guardian Home and Create Session screens for better usability.
- **Code Quality**: Addressed Flutter deprecation warnings and standardized code with lint fixes (e.g., modern `withValues` opacity).
- **Localization**: Standardized currency display to 'Rs.' across the application.
- **Performance**: Optimized rendering and improved layout responsiveness.

## Technology Stack

- **Frontend**: Flutter (Dart)
- **State Management**: Provider / Riverpod (Inferred - standardizing on modern practices)
- **Architecture**: Modular folder structure (`screens`, `widgets`, `services`)

## Getting Started

1.  **Prerequisites**: Ensure you have Flutter SDK installed.
2.  **Installation**:
    ```bash
    git clone https://github.com/Tekly-Solutions/Cricket-Coaching-App.git
    cd cricketcoachflutter
    flutter pub get
    ```
3.  **Run**:
    ```bash
    flutter run
    ```

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/).
