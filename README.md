# V-COMM - Campus Communication Platform

> **PROTOTYPE PHASE**  
> This application is currently in active development and prototype testing. Features may change, and stability is not guaranteed for production use.

##  About V-COMM

V-COMM is an all-in-one campus communication and management platform built with Flutter. It provides faculty with tools for messaging, event management, timetable sharing, and presence tracking - all in one unified application.

### Key Features

- **Secure Authentication** - Firebase-powered login system
- **Real-time Messaging** - Personal and group chats with rich media support
- **Event Calendar** - Create, manage, and track campus events
- **Timetable Sharing** - Upload and view class schedules via Google Drive
- **User Search** - Find and connect with other campus members
- **Presence Tracking** - Mark yourself as present/absent
- **Push Notifications** - Stay updated with important messages
- **Cross-Platform** - Works on Android, iOS, Web, Windows, macOS, and Linux

---

## Firebase Configuration

**Important:** This codebase is currently linked to the Firebase project:
- **Account**: mrupesh2005@gmail.com
- **Project ID**: v-comm-25582

If you're setting up your own instance, you'll need to:
1. Create your own Firebase project
2. Replace the configuration files (see Setup Instructions below)

---

## Getting Started - Step by Step

### Step 1: Install Required Software

Before you begin, you need to install these programs on your computer:

#### 1.1 Install Flutter SDK

1. Go to [Flutter's official website](https://flutter.dev/docs/get-started/install)
2. Choose your operating system (Windows, macOS, or Linux)
3. Download the Flutter SDK
4. Follow the installation instructions for your OS
5. After installation, open a terminal/command prompt and type:
   ```bash
   flutter doctor
   ```
   This will check if everything is installed correctly.

#### 1.2 Install an IDE (Code Editor)

Choose one of these:

- **Visual Studio Code** (Recommended for beginners)
  - Download from: https://code.visualstudio.com/
  - After installing, add the Flutter extension:
    1. Open VS Code
    2. Click on Extensions icon (left sidebar)
    3. Search for "Flutter"
    4. Click Install

- **Android Studio**
  - Download from: https://developer.android.com/studio
  - Includes Android emulator for testing

#### 1.3 Install Git

1. Go to https://git-scm.com/downloads
2. Download and install Git for your operating system
3. Follow the installation wizard (default settings are fine)

---

### Step 2: Download the Code

#### Option A: Using Git (Recommended)

1. Open Terminal (Mac/Linux) or Command Prompt (Windows)
2. Navigate to where you want to save the project:
   ```bash
   cd Desktop
   ```
3. Clone the repository:
   ```bash
   git clone <your-repository-url>
   cd v_comm
   ```

#### Option B: Download as ZIP

1. Go to the GitHub repository page
2. Click the green "Code" button
3. Select "Download ZIP"
4. Extract the ZIP file to your desired location
5. Open Terminal/Command Prompt and navigate to the extracted folder:
   ```bash
   cd path/to/v_comm
   ```

---

### Step 3: Install Dependencies

Once you're in the project folder:

1. Run this command to download all required packages:
   ```bash
   flutter pub get
   ```
2. Wait for it to complete (may take a few minutes)

---

### Step 4: Set Up Firebase (Choose Your Option)

#### Option A: Use Existing Firebase Project (Quick Start)

The code is already configured with the Firebase project. You can test it immediately, but:
- You won't have admin access
- Data is shared with other testers
- Not recommended for production

**Skip to Step 5 if you choose this option.**

#### Option B: Create Your Own Firebase Project (Recommended)

1. **Create Firebase Project:**
   - Go to https://console.firebase.google.com/
   - Click "Add Project"
   - Enter a project name (e.g., "my-vcomm")
   - Follow the setup wizard

2. **Enable Required Services:**
   - In Firebase Console, click on your project
   - **Authentication:**
     - Click "Authentication" in left menu
     - Click "Get Started"
     - Enable "Email/Password" sign-in method
   
   - **Firestore Database:**
     - Click "Firestore Database" in left menu
     - Click "Create Database"
     - Choose "Start in test mode"
     - Select a location close to you
   
   - **Storage:**
     - Click "Storage" in left menu
     - Click "Get Started"
     - Accept default security rules

3. **Install FlutterFire CLI:**
   ```bash
   dart pub global activate flutterfire_cli
   ```

4. **Configure Your Project:**
   ```bash
   flutterfire configure
   ```
   - Login with your Google account
   - Select your Firebase project
   - Select all platforms you want to support (use spacebar to select, enter to confirm)
   - This will automatically update `lib/firebase_options.dart`

5. **Update Package Name (Optional but Recommended):**
   - Open `android/app/build.gradle`
   - Change `applicationId` to something unique (e.g., `com.yourname.vcomm`)

---

### Step 5: Run the Application

#### On Android Emulator:

1. **Start an Emulator:**
   - Open Android Studio
   - Click "Device Manager" (phone icon on right sidebar)
   - Click "Create Device"
   - Select a phone model (e.g., Pixel 5)
   - Select a system image (latest Android version)
   - Click Finish

2. **Run the App:**
   ```bash
   flutter run
   ```

#### On Physical Device:

**Android:**
1. Enable Developer Options on your phone:
   - Go to Settings > About Phone
   - Tap "Build Number" 7 times
   - Go back to Settings > Developer Options
   - Enable "USB Debugging"
2. Connect your phone via USB
3. Run:
   ```bash
   flutter run
   ```

**iOS (Mac only):**
1. Connect your iPhone via USB
2. Trust your computer on the iPhone
3. Run:
   ```bash
   flutter run
   ```

#### On Web:

```bash
flutter run -d chrome
```

---

## 📂 Project Structure

```
v_comm/
├── lib/
│   ├── Calendar/          # Event calendar functionality
│   ├── Chat/              # Messaging system
│   ├── HomePage/          # Main dashboard
│   ├── LoginPage/         # Authentication screens
│   ├── Profile/           # User profile management
│   ├── Search/            # User search functionality
│   ├── auth_gate.dart     # Authentication handler
│   ├── firebase_options.dart  # Firebase configuration
│   └── main.dart          # App entry point
├── android/               # Android-specific code
├── ios/                   # iOS-specific code
├── web/                   # Web-specific code
├── assets/                # Images and resources
└── pubspec.yaml          # Dependencies configuration
```

---

## Creating Test Accounts

Since this is a prototype, you'll need to create user accounts through Firebase Console:

1. Go to Firebase Console > Authentication > Users
2. Click "Add User"
3. Enter email and password
4. After creating, go to Firestore Database
5. Create a document in `users` collection with the user's UID:
   ```json
   {
     "name": "John Doe",
     "email": "john@example.com",
     "dept": "Computer Science",
     "customId": "CS001",
     "isPresent": false,
     "photoUrl": "",
     "phoneNumber": ""
   }
   ```

---

## 🛠️ Troubleshooting

### "Flutter not found"
- Make sure Flutter is added to your system PATH
- Restart your terminal/command prompt
- Run `flutter doctor` to verify installation

### "Gradle build failed" (Android)
- Open `android/` folder in Android Studio
- Let it sync and download dependencies
- Try running again

### "Pod install failed" (iOS)
- Navigate to `ios/` folder
- Run: `pod install`
- If that fails: `pod repo update` then `pod install`

### "Firebase configuration error"
- Make sure you ran `flutterfire configure`
- Check that `firebase_options.dart` exists
- Verify your Firebase project is set up correctly

### App crashes on startup
- Check Firebase Console > Authentication is enabled
- Verify Firestore Database is created
- Ensure all rules are set to test mode initially

---

## 📱 Building for Release

### Android APK:
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

### iOS App (Mac only):
```bash
flutter build ios --release
```
Then open Xcode to archive and distribute.

### Web:
```bash
flutter build web
```
Output: `build/web/` folder

---

## Contributing

This is a prototype project. If you'd like to contribute:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

---

##  Important Notes

- **Prototype Status**: This app is under active development. Features may be incomplete or change without notice.
- **Firebase Limits**: The free Firebase plan has usage limits. Monitor your usage in Firebase Console.
- **Security**: Current Firestore rules are set for testing. Implement proper security rules before production use.
- **Data Privacy**: This prototype shares data across all users. Implement proper data isolation for production.

---

##  Support

For issues specific to this codebase:
- Check existing GitHub issues
- Create a new issue with detailed description
- Include error messages and screenshots

For Firebase-specific issues:
- Visit [Firebase Documentation](https://firebase.google.com/docs)
- Check [FlutterFire Documentation](https://firebase.flutter.dev/)

---
**Last Updated**: November 2025  
**Flutter Version**: 3.24+  
**Dart Version**: 3.9+

---

##  Next Steps After Installation

1. **Test Basic Features:**
   - Create a test account
   - Login to the app
   - Explore the calendar, messaging, and profile features

2. **Customize for Your Campus:**
   - Update app name in `pubspec.yaml`
   - Replace app icon in `assets/`
   - Modify color scheme in `lib/main.dart`

3. **Add Real Users:**
   - Set up a proper registration flow
   - Import existing user data
   - Configure email verification

4. **Prepare for Production:**
   - Implement proper Firestore security rules
   - Set up proper error handling
   - Add analytics and crash reporting
   - Test on multiple devices

---


````markdown
---

# Firebase Admin Panel

This is a lightweight Admin Panel for managing users in the V-COMM Firebase project.  
It allows you to create users manually or import them from a CSV file.

---

## Features

- Manual user creation (email, password, department, etc.)
- CSV bulk user import (using PapaParse)
- Displays all users in a live table
- Automatically saves users in Firebase Authentication and Firestore
- Supports Google Drive profile image links

---

## Prerequisites

You’ll need:
- A Firebase project with Authentication and Firestore enabled
- Your own Firebase Web API credentials

---

## Setup Instructions

1. Go to your Firebase Console → Project Settings → “General” tab  
2. Scroll to **Your apps → Web App**  
3. Copy your Firebase config:
   ```js
   const firebaseConfig = {
     apiKey: "YOUR_API_KEY",
     authDomain: "YOUR_PROJECT_ID.firebaseapp.com",
     projectId: "YOUR_PROJECT_ID",
     storageBucket: "YOUR_PROJECT_ID.appspot.com",
     messagingSenderId: "YOUR_SENDER_ID",
     appId: "YOUR_APP_ID"
   };
````

4. Replace the placeholder config inside `index.html`

---

## Usage

1. Open `index.html` in your browser (no server required).
2. Use the Manual Form to add users individually.
3. Or import a CSV file with the following columns:

   ```
   Name,Email,Password,Dept,ID,Phone,PhotoUrl
   ```
4. The users will appear in the table after being created.

---

## Example CSV

```
Name,Email,Password,Dept,ID,Phone,PhotoUrl
John Doe,john@example.com,pass123,IT,EMP001,9876543210,https://drive.google.com/file/d/abc123/view
```

---

## Important Notes

* Do **NOT** commit your Firebase credentials to GitHub.
* Always use test accounts when trying bulk imports.
* For production, restrict API key access in the Firebase Console.

---

## Developer

**Rupesh Malisetty**
Email: [mrupesh2005@gmail.com](mailto:mrupesh2005@gmail.com)

---

**Last Updated:** November 2025







Good luck with your V-COMM setup! 

```
