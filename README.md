# 🍽️ iBites - Your Healthy Recipe Companion

![iBites Logo](assets/background.png)

## 🌟 Overview

iBites is a modern, user-friendly recipe application designed to promote healthy cooking and eating habits. Whether you're a health-conscious individual or a professional chef, iBites provides a platform to discover, share, and manage healthy recipes.

## ✨ Features

### 👤 For Users
- Browse a curated collection of healthy recipes
- Save favorite recipes for quick access
- Share your own healthy recipes with the community
- Track your cooking journey
- User-friendly interface with beautiful visuals

### 👨‍🍳 For Admins
- Manage recipe submissions
- Moderate user content
- Handle user accounts
- Access detailed analytics
- Maintain platform quality

## 🛠️ Technical Stack

- **Frontend**: Flutter
- **Backend**: Firebase
- **Authentication**: Firebase Auth
- **Database**: Cloud Firestore
- **Storage**: Firebase Storage

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (latest version)
- Firebase account
- Android Studio / VS Code
- Git

### Installation

1. Clone the repository
```bash
git clone https://github.com/yourusername/ibites.git
```

2. Navigate to project directory
```bash
cd ibites
```

3. Install dependencies
```bash
flutter pub get
```

4. Configure Firebase
   - Create a new Firebase project
   - Add your Android/iOS app to the Firebase project
   - Download and add the configuration files
   - Enable Authentication and Firestore

5. Run the app
```bash
flutter run
```

## 📱 App Structure

```
lib/
├── view/
│   ├── admin/
│   │   ├── adminHomePage.dart
│   │   └── adminsignuppage.dart
│   ├── user/
│   │   ├── userHomePage.dart
│   │   └── usersignuppage.dart
│   └── login.dart
├── view_models/
│   └── login_vm.dart
├── services/
│   └── auth_service.dart
└── main.dart
```

## 🔐 Authentication

The app supports two types of users:
- **Regular Users**: Can browse and interact with recipes
- **Admin Users**: Have additional privileges for content management

## 🎨 UI/UX Features

- Modern and clean interface
- Responsive design
- Intuitive navigation
- Beautiful recipe cards
- Smooth animations
- Dark/Light mode support


## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Team

- [Your Name] - Lead Developer
- [Team Member 2] - UI/UX Designer
- [Team Member 3] - Backend Developer

Made with ❤️ by the iBites Team
