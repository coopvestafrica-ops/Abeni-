# Abeni Mart — Backend deployment

The Flutter customer + admin apps are pure clients. They cannot work until you
deploy the backend pieces in this folder to your `abeni-mart` Firebase project.

## What's included

| File / folder            | What it does                                                                 |
| ------------------------ | ---------------------------------------------------------------------------- |
| `firestore.rules`        | Security rules — gives admin/staff read+write on every collection. Without these, the admin app shows `permission-denied` everywhere. |
| `firestore.indexes.json` | Composite indexes for the queries the apps run.                              |
| `functions/index.js`     | Cloud Functions that turn Firestore writes into FCM pushes.                  |
| `firebase.json`          | Wires the above together for `firebase deploy`.                              |

## One-time setup (your laptop, ~5 min)

```bash
# 1. Install the Firebase CLI (skip if you already have it)
npm install -g firebase-tools

# 2. Sign in with the Google account that owns the abeni-mart project
firebase login

# 3. Tell the CLI which project to deploy to
cd abeni                             # the repo root
firebase use abeni-mart

# 4. Install Cloud Function dependencies (one-time)
cd functions && npm install && cd ..
```

## Deploy

### Fix the permission-denied errors (security rules) — DO THIS FIRST
```bash
firebase deploy --only firestore:rules,firestore:indexes
```
After this, your admin account (whose `users/{uid}.role == "admin"`) will be
able to load the dashboard, orders, customers, sales, etc.

### Enable real-time push notifications (Cloud Functions)
```bash
firebase deploy --only functions
```
Requires the **Blaze** (pay-as-you-go) plan on Firebase — free tier is plenty for
the volumes a single store generates. After this:
- Status change in admin app → customer's phone gets a push within seconds.
- Broadcast from admin app → every customer who has logged in gets a push.

### Deploy everything in one go
```bash
firebase deploy
```

## Bootstrap your first admin

The admin app intentionally has no public sign-up. Create your account in the
**customer** app, then promote it once:

1. Sign up in the customer app with the email you want as admin.
2. Open the [Firebase Console → Firestore](https://console.firebase.google.com/project/abeni-mart/firestore/data/~2Fusers).
3. Open the doc under `users` that matches your account.
4. Click **Add field** → name `role` → type `string` → value `admin` → Save.
5. Open the admin app and sign in.
6. From there, **More → Staff & admins** lets you promote anyone else.

## How push notifications flow

```
Admin taps "Out for delivery"
       │
       ▼
admin_repository.updateOrderStatus()
       │  writes to /customer_messages/{auto}
       ▼
Cloud Function `onCustomerMessageCreated`
       │  reads /users/{uid}/fcm_tokens
       ▼
FCM multicast → customer's phone(s)
       │
       ▼
NotificationService displays "Order is out for delivery"
```

Broadcast follows the same pattern but publishes to the `customers` topic
that every customer device subscribes to on login.
