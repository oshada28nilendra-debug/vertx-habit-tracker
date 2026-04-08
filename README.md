# ⚡ Vertx — AI-Powered Habit Tracker

<p align="center">
  <img src="assets/images/app_icon.png" width="120" alt="Vertx Logo"/>
</p>

<p align="center">
  <strong>Build habits. Build yourself.</strong>
</p>

<p align="center">
  A smart daily habit tracker mobile application built with Flutter and Firebase, featuring AI-powered habit suggestions.
</p>

---

## 📱 About

Vertx is a feature-rich habit tracking mobile application developed as part of the PUSL2023 Mobile Application Development module at NSBM Green University (affiliated with University of Plymouth). The app helps users build and maintain daily habits through intelligent tracking, streak monitoring, and AI-powered suggestions.

---

## ✨ Features

### 🔐 Authentication
- Email & Password Sign Up / Login
- Password Reset via Email
- Google Sign-In
- Auto-login with persistent sessions
- Secure Firebase Authentication

### 📋 Habit Management
- Add custom habits with icons, colors, and categories
- Mark habits as complete with one tap
- Swipe to delete habits
- Long press to edit habit name and category
- 6 categories: Health, Fitness, Learning, Mindfulness, Finance, Social

### 🤖 AI Features
- AI-powered habit suggestions based on user goals
- Smart keyword analysis for personalized recommendations
- Powered by Claude AI (Anthropic)

### 📊 Analytics
- Weekly overview bar chart
- Daily completion progress tracking
- Best streak counter
- Total habits summary
- Real-time data from Firebase

### 🔥 Streak System
- Automatic daily streak tracking
- Streak milestone notifications (7, 30, 100 days)
- Streak resets if habit is missed for a day

### 🌙 User Experience
- Dark mode toggle
- Personalized greeting (morning/afternoon/evening)
- Profile photo (Camera & Gallery)
- Push notifications
- Daily habit reset at midnight
- Smooth animations throughout

### ⚙️ Settings
- Notifications management (Daily Reminder, Streak Alerts, Weekly Summary)
- Privacy policy
- Help & Support guide
- Dark mode

---

## 🛠️ Tech Stack

| Technology | Usage |
|------------|-------|
| **Flutter** | Mobile app framework |
| **Dart** | Programming language |
| **Firebase Auth** | User authentication |
| **Cloud Firestore** | Real-time database |
| **Firebase Core** | Firebase initialization |
| **Google Sign-In** | OAuth authentication |
| **Claude AI (Anthropic)** | AI habit suggestions |
| **flutter_local_notifications** | Push notifications |
| **image_picker** | Camera & gallery access |
| **permission_handler** | Runtime permissions |
| **shared_preferences** | Local storage |
| **go_router** | Navigation |
| **google_fonts** | Typography |

---

## 📁 Project Structure

```
vertx/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── screens/
│   │   ├── auth/
│   │   │   ├── splash_screen.dart   # Splash + auto-login
│   │   │   ├── login_screen.dart    # Login + Google Sign-In
│   │   │   └── signup_screen.dart   # User registration
│   │   ├── habits/
│   │   │   └── add_habit_screen.dart # Add habit + AI suggestions
│   │   └── home/
│   │       └── home_screen.dart     # Main app screens
│   ├── services/
│   │   └── auth_service.dart        # Firebase Auth service
│   └── utils/
│       └── app_router.dart          # GoRouter navigation
├── android/                         # Android configuration
├── assets/                          # Images and animations
└── pubspec.yaml                     # Dependencies
```

---

## 🗄️ Database Structure

```
Firestore:
└── users/
    └── {userId}/
        └── habits/
            └── {habitId}/
                ├── name: String
                ├── category: String
                ├── colorValue: int
                ├── iconCode: int
                ├── done: bool
                ├── streak: int
                ├── lastCompleted: Timestamp
                └── createdAt: Timestamp
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.38.9+)
- Android Studio
- Firebase account

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/oshada28nilendra-debug/vertx-habit-tracker.git
cd vertx-habit-tracker
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Add Firebase configuration**
   - Add your `google-services.json` to `android/app/`
   - Configure Firebase project with your SHA-1 fingerprint

4. **Build and run**
```bash
cd android
./gradlew assembleDebug
adb install app/build/outputs/apk/debug/app-debug.apk
```

---

## 👥 Team Members

| Name | GitHub | Role |
|------|--------|------|
| Oshada Nilendra | [@oshada28nilendra-debug](https://github.com/oshada28nilendra-debug) | Project Lead & Full Stack Developer |
| Member 2 | @username | Role |
| Member 3 | @username | Role |
| Member 4 | @username | Role |
| Member 5 | @username | Role |
| Member 6 | @username | Role |
| Member 7 | @username | Role |

---

---

## 🏫 Academic Information

- **Module:** PUSL2023 — Mobile Application Development
- **University:** NSBM Green University (Affiliated with University of Plymouth)
- **Academic Year:** 2025/2026

---

## 📄 License

This project is developed for academic purposes as part of PUSL2023 coursework.
