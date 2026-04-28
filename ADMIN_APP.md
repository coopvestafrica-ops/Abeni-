# Abeni Admin app

A separate Android/iOS package that lets the store owner and staff manage
the Abeni Mart business from their phones. Installs side-by-side with the
customer app.

## Features

- **Sign in** with admin/staff accounts only. Customer accounts are rejected.
- **Dashboard** — today / 7-day / 30-day revenue, pending and processing
  order counts, recent orders, top-selling products, low-stock warnings.
- **Orders** — list of every order with filter by status, search by ID
  / phone / address / item. Tap an order to see line items, customer info,
  totals, payment method.
- **Order actions** — change status (Pending → Processing → Out for
  delivery → Delivered) with optional note. Each change writes a notification
  record so the customer is informed. Mark bank-transfer payments as
  received. Add internal staff-only notes.
- **Products** — list, search, filter by category, create / edit / delete.
  Each product supports multiple unit/price/stock combos
  (e.g. Congo / Half Congo / Bag).
- **Inventory** — low-stock highlights surfaced on the dashboard.
- **Customers** — list of every customer with search, profile detail,
  full order history per customer, one-tap call / email, and a “send
  notification” button to message a single customer.
- **Broadcast** — send a push notification to every customer
  (e.g. "New stock arrived").
- **Sales** — revenue summary cards + top-products leaderboard.
- **Staff** — admin-only screen to grant / revoke admin or staff access on
  any account.

## Architecture

- Same Flutter codebase as the customer app, gated by an Android
  `productFlavors` block that produces two side-by-side APKs:
  - `customer` → `com.abenimart.abeni_mart` → "Abeni Mart"
  - `admin`    → `com.abenimart.abeni_admin` → "Abeni Admin"
- Separate entry points: `lib/main.dart` (customer) and
  `lib/main_admin.dart` (admin).
- Both apps share Firebase / Firestore. Collections used:
  - `users` (with `role` ∈ {customer, staff, admin})
  - `orders`
  - `products`
  - `customer_messages` (per-user notifications)
  - `broadcasts` (store-wide)

## Building

```bash
# Customer
flutter build apk --release --flavor customer -t lib/main.dart
# Admin
flutter build apk --release --flavor admin -t lib/main_admin.dart
```

Both APKs land in `build/app/outputs/flutter-apk/`.

## Granting admin access

When you sign up your first account through the customer app, it has the
default role `customer`. To bootstrap the first admin:

1. Open the Firebase console → Firestore → `users`.
2. Locate your user document.
3. Add a field `role` of type **string** with value `admin`.
4. Open the Admin app and sign in — you now have full access.

After that, you can promote / demote others from **More → Staff & admins**
inside the Admin app.

## Deploying real push notifications

Status updates and broadcasts already write to Firestore. To turn those
into real-time pushes that reach customers even when their app is closed,
deploy a Cloud Function on each of these collections:

- `customer_messages` — fan-out to the customer's `fcm_tokens` subcollection.
- `broadcasts` — publish to a topic that every customer is subscribed to.

Cloud Function snippets are not committed to this repo; ask Devin to add
them once you've enabled Cloud Functions on the Firebase project.

## Firestore security rules

The production rules live in `firestore.rules` at the repo root. Deploy them
with:

```bash
firebase deploy --only firestore:rules --project=abeni-mart
```

The rules use an `isAdmin()` helper that reads the caller's `users` document
and checks `role in ['admin', 'staff']`. Without these rules deployed,
**every admin screen will show `permission-denied` errors**.
