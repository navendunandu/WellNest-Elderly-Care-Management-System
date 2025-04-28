# WellNest - Elderly Care Management System

WellNest is a comprehensive elderly care management system consisting of four interconnected Flutter applications designed to facilitate and streamline elderly care services.

## Project Components

1. **WellNest Admin** (`admin_wellnest`)
   - Administrative dashboard for managing the overall system
   - Built with Flutter and Supabase integration
   - Features analytics, user management, and system oversight

2. **WellNest Family** (`family_member`)
   - Mobile application for family members
   - Firebase integration for real-time notifications
   - Features payment integration (Razorpay, Cashfree)
   - Secure storage and permission handling

3. **WellNest Resident** (`resident_wellnest`)
   - Application for elderly residents
   - User-friendly interface designed for elderly users
   - Supabase integration for data management

4. **WellNest Caretaker** (`caretaker_wellnest`)
   - Application for caretakers and healthcare providers
   - Firebase integration for real-time updates
   - Task management and resident monitoring features

## Technology Stack

- **Frontend Framework**: Flutter
- **Backend Services**: 
  - Supabase (Database and Authentication)
  - Firebase (Notifications and Real-time Updates)
- **Payment Gateways**: 
  - Razorpay
  - Cashfree
- **Additional Features**:
  - Local Notifications
  - File Management
  - Secure Storage
  - Permission Handling

## Project Developer

This project was developed by **Ajith Mani Santhosh** as part of his academic curriculum. Ajith demonstrated exceptional skills in:
- Multi-platform application development
- Integration of various third-party services
- Implementation of real-time features
- Creating a cohesive ecosystem of interconnected applications

## Getting Started

Each application can be run independently. Navigate to the respective project directory and run:

```bash
flutter pub get
flutter run
```

## Prerequisites

- Flutter SDK ^3.6.1
- Dart SDK
- Android Studio / VS Code
- Firebase CLI
- Supabase Account

## Environment Setup

Each application requires specific configuration:

1. Set up Supabase credentials
2. Configure Firebase (for applicable apps)
3. Set up payment gateway credentials (for Family Member app)
4. Configure notification services

## License

This project is proprietary and all rights are reserved.

