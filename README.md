# AU Connect

**AU Connect** is a comprehensive campus social networking and productivity application built with Flutter. It provides students with tools to connect, share, study, and manage campus life.

## Features

### Social Features
- **Home Feed**: Share posts, images, and thoughts with the campus community
- **Comments & Likes**: Engage with posts from fellow students
- **Friends**: Add friends and manage your campus network
- **Chat**: Real-time messaging with friends and groups
- **Profile Management**: Customize your profile and view your activity

### Campus Tools
- **Shop & Lost Found**: Buy/sell items and report lost/found items
- **AU Polls**: Create and participate in campus-wide polls
- **Upcoming Events**: Stay updated on campus events
- **Idea Cloud**: Share and collaborate on ideas

### Productivity Tools
- **Pomodoro Timer**: Focus sessions with built-in timer
- **Study Sessions**: Join or create study groups
- **Calculator**: Quick calculations on the go

## Technology Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Node.js REST API
- **Authentication**: JWT Token-based
- **State Management**: StatefulWidget with setState

## Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio / Xcode (for mobile development)
- Chrome (for web development)
- Node.js backend server running on `localhost:8383`

## Installation

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd au_connect
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure backend URL**:
   - Ensure your backend server is running on `localhost:8383`
   - Update service files if using a different URL

4. **Run the application**:
   ```bash
   # For web
   flutter run -d chrome
   
   # For Android
   flutter run -d android
   
   # For iOS
   flutter run -d ios
   ```

## Project Structure

```
lib/
├── main.dart                 # Application entry point
├── models/                   # Data models
├── screens/                  # UI screens/pages
│   ├── signin_page.dart
│   ├── signup_page.dart
│   ├── home_page.dart
│   ├── profile_page.dart
│   ├── campus_corner_page.dart
│   ├── shop_and_lost_found_page.dart
│   └── ...
├── services/                 # API service layer
│   ├── auth_service.dart
│   ├── user_service.dart
│   ├── post_service.dart
│   └── ...
└── widgets/                  # Reusable widgets
```

## API Endpoints

The app connects to the following backend endpoints:

- **Authentication**: `/auth/login`, `/auth/register`
- **Users**: `/users/me`, `/users/:userId`
- **Posts**: `/posts`, `/posts/:id`
- **Comments**: `/comments`
- **Friends**: `/friends/requests`, `/friends/accept`, `/friends/reject`
- **Shop Items**: `/sell-items`
- **Lost & Found**: `/lost-items`

## User Manual

For detailed usage instructions with screenshots, please refer to [user_manual.html](user_manual.html).

## Configuration

- Backend API URL is configured in service files
- Authentication tokens are stored using SharedPreferences
- Default theme uses Material Design with custom blue color scheme

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License.

## Support

For issues, questions, or contributions, please open an issue on the repository.

## Screenshots

See the [User Manual](user_manual.html) for detailed screenshots and usage guide.
