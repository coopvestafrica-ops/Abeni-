# 🛒 Abeni Mart Enterprise

> **Your Neighbourhood Foodstuff Market** — A premium Flutter mobile app (Android & iOS) for Abeni Mart, a Nigerian foodstuff retail and delivery business.

![Flutter](https://img.shields.io/badge/Flutter-3.24+-02569B?style=flat-square&logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.5+-0175C2?style=flat-square&logo=dart)
![Firebase](https://img.shields.io/badge/Firebase-10.x-FFCA28?style=flat-square&logo=firebase)
![License](https://img.shields.io/badge/License-Proprietary-E53935?style=flat-square)

---

## ✨ Enterprise Features

### 🎨 Premium UI/UX
- **Enterprise Design System**: Sophisticated color palette with emerald green (#0A6847) primary and gold (#FFB800) accents
- **Glassmorphism Effects**: Modern frosted glass elements throughout the app
- **Smooth Animations**: Staggered reveals, particle effects, micro-interactions
- **Custom Typography**: Plus Jakarta Sans + Outfit fonts for professional appearance
- **Advanced Shadows**: Multi-layered elevation system with colored shadows

### 📱 Customer App
- **Animated Splash Screen**: Particle effects, glow animations, brand reveal
- **Smart Home Screen**: Pull-to-refresh, animated headers, featured carousel
- **Product Cards**: 3D press effects, dynamic badges, hover states
- **Category Navigation**: Animated cards with glow effects
- **Premium Cart**: Swipe-to-delete, elegant summaries, delivery breakdown
- **Checkout Flow**: Step indicators, animated transitions
- **Profile Management**: Quick actions, contact options, settings

### 🏗️ Architecture
- **Clean Architecture**: Three-layer separation (core/data/presentation)
- **State Management**: Riverpod with providers
- **Navigation**: go_router with typed routes
- **Firebase Backend**: Authentication, Firestore, Storage, Cloud Messaging

---

## 🚀 Getting Started

### Prerequisites
- Flutter 3.24+ / Dart 3.5+
- Android Studio or Xcode
- Firebase project (free tier)

### Installation

```bash
# Clone the repository
git clone <repository-url>
cd Abeni-Mart

# Install dependencies
flutter pub get

# Run in demo mode (no Firebase)
flutter run -d chrome

# Or connect Firebase
flutterfire configure --project=<your-project-id>
```

### Demo Mode
The app runs out-of-the-box with:
- 12 in-memory sample products
- Mock authentication
- In-memory order history

---

## 📁 Project Structure

```
lib/
├── core/
│   ├── constants/        # App constants, categories, store info
│   ├── router/           # go_router configuration
│   ├── services/        # Biometric, notification, session services
│   ├── theme/            # Enterprise theme & colors
│   └── utils/           # Formatters, helpers
├── data/
│   ├── models/           # Product, Cart, Order, User models
│   ├── repositories/     # Auth, Product, Order repositories
│   └── services/        # Firebase services
├── presentation/
│   ├── providers/        # Riverpod state providers
│   ├── screens/         # Feature screens
│   │   ├── auth/        # Login, Register
│   │   ├── cart/        # Shopping cart
│   │   ├── checkout/    # Checkout, confirmation
│   │   ├── home/        # Home, main shell
│   │   ├── notifications/
│   │   ├── orders/      # Order history
│   │   ├── products/    # Category, details
│   │   ├── profile/     # User profile
│   │   └── splash/      # Animated splash
│   └── widgets/         # Reusable components
├── firebase_options.dart
└── main.dart
```

---

## 🎨 Design System

### Colors
```dart
// Primary - Deep Emerald
primary: #0A6847
primaryLight: #12A869
primaryDark: #054832

// Accent - Warm Gold
accent: #FFB800
accentLight: #FFD54F

// Semantic
success: #10B981
warning: #F59E0B
error: #DC3545
info: #3B82F6
```

### Shadows
```dart
// Shadow elevation levels
cardShadow(0) // Subtle
cardShadow(1) // Default card
cardShadow(2) // Elevated card
cardShadow(3) // Modal
cardShadow(4) // Floating

// Colored shadows
primaryShadow()
accentShadow()
glassDecoration()
```

### Typography
- **Display**: Outfit (headings)
- **Body**: Plus Jakarta Sans (content)

---

## 🔥 Firebase Setup

### Enable Services
1. **Authentication** → Email/Password
2. **Firestore** → Production mode (europe-west1)
3. **Storage** → Default
4. **Cloud Messaging** → Enabled

### Deploy Rules
```bash
firebase deploy --only firestore:rules --project=<project-id>
```

---

## 🧪 Testing

```bash
# Analyze code
flutter analyze

# Run tests
flutter test

# Build releases
flutter build apk --release
flutter build ios --release
flutter build web --release
```

---

## 🗺️ Roadmap

### Phase 2
- [ ] Admin Dashboard (Flutter Web)
- [ ] Paystack / Flutterwave Integration
- [ ] Advanced Push Notifications
- [ ] Product Image Uploads
- [ ] Order Status Workflow

### Future
- [ ] Multi-language Support
- [ ] Loyalty/Rewards System
- [ ] Analytics Dashboard
- [ ] A/B Testing

---

## 📄 License

Proprietary - © 2024 Abeni Mart. All rights reserved.

---

Built with ❤️ using Flutter & Firebase
