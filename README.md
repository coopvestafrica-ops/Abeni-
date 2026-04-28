# 🛒 Abeni Mart

**Your Neighbourhood Foodstuff Market** — a Flutter mobile app (Android &
iOS) for Abeni Mart, a Nigerian foodstuff retail and delivery business.

Customers can browse rice, beans, garri, sugar, grains, pasta, beverages and
more — pick the measurement unit they want (Congo, Half Congo, Paint Bucket,
Bag, Pack, Carton…), add items to cart, and check out with either **Delivery**
or **Pickup**.

---

## ✨ Features

### Customer app

- Splash + branded auth flow (email + password, Firebase Authentication)
- Profile with full name, phone and delivery address
- Home screen with:
  - Search bar
  - 13 product categories
  - Featured products carousel
  - Product grid
- Product details with **multi-unit selection** (Congo units, pack units,
  carton, bottle, sachet)
- Quantity selector + live subtotal
- Cart with line-item editing and quantity updates
- Checkout with:
  - Delivery / Pickup toggle
  - Delivery address & phone
  - Payment: Pay on Delivery or Bank Transfer
  - Order summary (subtotal, delivery, total)
- Order confirmation (Order ID, status, totals)
- Order history (status badges: Pending, Processing, Delivered, Cancelled)
- Edit profile + logout

### Nigerian Congo measurement system

Every staple product supports the traditional Congo unit system:

| Unit          | Used for                              |
| ------------- | ------------------------------------- |
| Congo         | Rice, Beans, Garri, Sugar, Semovita…  |
| Half Congo    | Smaller purchases                     |
| Paint Bucket  | Bulk household quantities             |
| Half Paint    | Mid-size quantities                   |
| Bag           | Wholesale                             |

Packaged goods (noodles, spaghetti, vegetable oil, seasonings, beverages)
use: **Piece / Pack / Carton / Bottle / Sachet**.

---

## 🏗️ Architecture

**Clean Architecture** with three clearly separated layers under `lib/`:

```
lib/
├── core/                  # cross-cutting concerns
│   ├── constants/         # app-wide constants (categories, units, currency)
│   ├── router/            # go_router setup
│   ├── theme/             # colors + ThemeData
│   └── utils/             # formatters (Naira, dates)
├── data/                  # data layer
│   ├── models/            # Product, ProductUnit, CartItem, AbeniOrder, AppUser, OrderLine
│   ├── repositories/      # Auth / Product / Order
│   └── services/          # Firebase bootstrap + sample catalog
├── presentation/          # presentation layer
│   ├── providers/         # Riverpod providers
│   ├── screens/           # one folder per feature
│   │   ├── splash/
│   │   ├── auth/          # login + register
│   │   ├── home/          # main shell (bottom nav) + home screen
│   │   ├── products/      # category + product details
│   │   ├── cart/
│   │   ├── checkout/      # checkout + order confirmation
│   │   ├── orders/        # order history
│   │   └── profile/
│   └── widgets/           # reusable widgets
├── firebase_options.dart  # REPLACE with `flutterfire configure` output
└── main.dart
```

State management: [Riverpod](https://riverpod.dev/) (`flutter_riverpod`).
Navigation: [go_router](https://pub.dev/packages/go_router).

---

## 🚀 Getting started

### Prerequisites

- **Flutter** 3.24+ / Dart 3.5+  (`flutter --version`)
- **Android Studio** or **Xcode** for device builds
- A **Firebase project** (free tier is fine)

### 1. Install dependencies

```bash
flutter pub get
```

### 2. (Demo mode) Run without Firebase

The app will compile and run immediately out of the box using:
- a local in-memory sample catalog (12 products)
- a mock authentication — any email + password logs you in as "Demo Customer"
- in-memory order history

```bash
flutter run -d chrome            # web
flutter run -d <android-device>  # Android
flutter run -d <ios-device>      # iOS
```

> In demo mode you'll see a console log:
> `[Abeni Mart] Firebase config is placeholder — running in demo mode.`

### 3. Connect Firebase (production mode)

#### a. Create a Firebase project

Go to <https://console.firebase.google.com/> and create a new project called
"Abeni Mart". Enable:

- **Authentication → Sign-in method → Email / Password**
- **Firestore Database** (Production mode; choose a region close to Nigeria,
  e.g. `europe-west1`)
- **Storage**
- **Cloud Messaging**

#### b. Run `flutterfire configure`

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=<your-firebase-project-id>
```

This **replaces** `lib/firebase_options.dart` and generates the right
`google-services.json` / `GoogleService-Info.plist` for Android and iOS.

#### c. Seed Firestore with sample products

Open the app, sign in, go to **Profile → (future step)**, or temporarily call
`ProductRepository().seedSampleProducts()` once from your code. This uploads
the 12 starter products into the `products` collection.

#### d. Deploy Firestore security rules

The repo includes a `firestore.rules` file with production-ready rules that
support both the **customer app** and the **admin app**. Deploy them with:

```bash
npm install -g firebase-tools   # if you haven't already
firebase login
firebase deploy --only firestore:rules --project=abeni-mart
```

> **Important:** The admin app requires these rules to be deployed. Without
> them Firestore uses the default deny-all policy and every screen will show
> `[cloud_firestore/permission-denied]` errors. See `firestore.rules` for the
> full rule set and `ADMIN_APP.md` for details on the admin role system.

---

## 📦 Firestore schema

### `products/{productId}`

```json
{
  "productId": "rice_001",
  "productName": "Premium Long Grain Rice",
  "categoryId": "rice",
  "description": "…",
  "imageUrl": "https://…",
  "featured": true,
  "units": [
    { "unitName": "Congo",        "price": 2500,  "stock": 120 },
    { "unitName": "Half Congo",   "price": 1300,  "stock": 80  },
    { "unitName": "Paint Bucket", "price": 5200,  "stock": 40  },
    { "unitName": "Bag",          "price": 78000, "stock": 25  }
  ]
}
```

### `users/{uid}`

```json
{
  "id": "…",
  "email": "…",
  "fullName": "…",
  "phone": "…",
  "deliveryAddress": "…"
}
```

### `orders/{orderId}`

```json
{
  "userId": "…",
  "items": [
    {
      "productId": "rice_001",
      "productName": "Premium Long Grain Rice",
      "imageUrl": "…",
      "unitName": "Congo",
      "unitPrice": 2500,
      "quantity": 2,
      "lineTotal": 5000
    }
  ],
  "subtotal": 5000,
  "deliveryFee": 1500,
  "total": 6500,
  "fulfillmentType": "delivery",
  "paymentMethod": "payOnDelivery",
  "deliveryAddress": "…",
  "phone": "…",
  "status": "pending",
  "createdAt": "2025-01-15T10:30:00.000Z"
}
```

---

## 🧪 Testing

```bash
flutter analyze
flutter test
flutter build web --release
flutter build apk --release
flutter build ios --release       # on macOS
```

---

## 🗺️ Roadmap

Phase 2 (not in this PR):

- **Admin dashboard** (Flutter Web) for store owner: add products, edit units &
  stock, manage orders, view sales. Connected to the same Firestore backend.
- Online payments: **Paystack** and **Flutterwave** integration.
- Push notifications for order status updates (Firebase Cloud Messaging).
- Product image uploads via Firebase Storage from the admin dashboard.
- Order status workflow (admin can mark Pending → Processing → Delivered).

---

Built with ❤️ for Abeni Mart.
