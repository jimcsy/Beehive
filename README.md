# 🐝 Beehive

A comprehensive, Flutter-based Learning Management Tool designed specifically for student programmers. Beehive bridges the gap between theoretical learning and practical application by combining standard LMS features with a built-in IDE for real-time coding practice.

## 📱 About The Project

Beehive provides educators and students with a streamlined, interactive environment. Teachers can easily manage classrooms and course materials, while students can access reading content, video lessons, game-based activities, and practice their coding skills directly within the app.

### Built With

* **Frontend:** [Flutter](https://flutter.dev/) 
* **Backend & Database:** [Firebase Authentication](https://firebase.google.com/docs/auth) & [Cloud Firestore](https://firebase.google.com/docs/firestore)
* **Code Execution Environment:** Dedicated secure sandbox (e.g., Railway / Cloud Run)

## ✨ Core Features

* **Secure User Authentication:** Role-based access for teachers and students.
* **Room Management:** Teachers can easily create and manage virtual classrooms, while students can join using a unique room code. Notifications keep students updated on room activities.
* **Rich Content Management:** A robust system allowing educators to upload, manage, and archive learning units and materials.
* **Interactive Learning Modules:** * Reading materials and video lessons
    * Interactive, game-based activities
    * Quizzes to test knowledge retention
* **Integrated IDE:** A built-in coding sandbox allowing students to practice programming concepts directly within their learning modules.

## 🏗️ Architecture Overview


Beehive utilizes a hybrid architecture approach to ensure both rapid content delivery and secure code execution. The core LMS features (user data, room management, content metadata) are handled by Firebase for real-time synchronization. Meanwhile, the built-in IDE connects to an isolated, dedicated execution platform to safely run student code without compromising the main application database.

## 🚀 Getting Started

### Prerequisites

* Flutter SDK (latest stable version)
* Dart SDK
* A Firebase project configured for Android/iOS

### Installation

1. Clone the repo
   ```sh
   git clone [https://github.com/your-username/beehive.git](https://github.com/your-username/beehive.git)

2. Install Flutter packages
    ```sh
    flutter pub get

3. Add your Firebase configuration files (`google-services.json` for Android, `GoogleService-Info.plist` for iOS) to the respective directories.

4. Run the app
    ```sh
    flutter run
    

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.
