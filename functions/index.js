/**
 * Abeni Mart — Cloud Functions for FCM push notifications.
 *
 * Triggers:
 *   1. customer_messages/{id}  → push to that single customer's devices.
 *      Used for order-status updates, payment confirmations, and direct
 *      admin → customer messages.
 *
 *   2. broadcasts/{id}         → push to the "customers" topic so every
 *      customer device receives the announcement.
 *
 *   3. (helper) onUserCreate   → seed new users with role=customer.
 *
 * Deploy:
 *     cd functions && npm install
 *     firebase deploy --only functions
 */

const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { setGlobalOptions } = require("firebase-functions/v2");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
setGlobalOptions({ region: "us-central1", maxInstances: 10 });

const db = admin.firestore();
const fcm = admin.messaging();

// --------------------------------------------------------------------------- //
// 1. Per-customer push: triggered by writes to /customer_messages.            //
// --------------------------------------------------------------------------- //
exports.onCustomerMessageCreated = onDocumentCreated(
  "customer_messages/{messageId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const msg = snap.data();
    const userId = msg.userId;
    if (!userId) {
      logger.warn("customer_messages doc missing userId", { id: snap.id });
      return;
    }

    const tokens = await loadUserTokens(userId);
    if (tokens.length === 0) {
      logger.info(`No FCM tokens for user ${userId} — skipping push.`);
      return;
    }

    const payload = {
      notification: {
        title: msg.title || "Abeni Mart",
        body: msg.body || "",
      },
      data: stringifyData({
        type: msg.type || "direct",
        orderId: msg.orderId || "",
        status: msg.status || "",
        messageId: snap.id,
      }),
      android: {
        priority: "high",
        notification: {
          channelId: "abeni_order_updates",
          sound: "default",
        },
      },
      apns: {
        payload: {
          aps: { sound: "default" },
        },
      },
    };

    await sendToTokens(userId, tokens, payload);
  }
);

// --------------------------------------------------------------------------- //
// 2. Broadcast push: triggered by writes to /broadcasts.                       //
//    Sent to the "customers" topic so all customer devices receive it.         //
// --------------------------------------------------------------------------- //
exports.onBroadcastCreated = onDocumentCreated(
  "broadcasts/{broadcastId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const b = snap.data();

    const message = {
      topic: "customers",
      notification: {
        title: b.title || "Abeni Mart",
        body: b.body || "",
      },
      data: stringifyData({
        type: "broadcast",
        broadcastId: snap.id,
      }),
      android: {
        priority: "high",
        notification: {
          channelId: "abeni_order_updates",
          sound: "default",
        },
      },
      apns: { payload: { aps: { sound: "default" } } },
    };

    try {
      const id = await fcm.send(message);
      logger.info("Broadcast sent", { id, broadcastId: snap.id });
    } catch (e) {
      logger.error("Broadcast send failed", e);
    }
  }
);

// --------------------------------------------------------------------------- //
// Helpers                                                                      //
// --------------------------------------------------------------------------- //

async function loadUserTokens(userId) {
  const ref = db.collection("users").doc(userId).collection("fcm_tokens");
  const snap = await ref.get();
  return snap.docs
    .map((d) => d.data().token || d.id)
    .filter((t) => typeof t === "string" && t.length > 0);
}

async function sendToTokens(userId, tokens, payload) {
  const message = { ...payload, tokens };
  try {
    const res = await fcm.sendEachForMulticast(message);
    logger.info(`FCM → user=${userId} success=${res.successCount} failure=${res.failureCount}`);

    // Clean up dead tokens so we don't keep retrying them.
    const deadTokens = [];
    res.responses.forEach((r, i) => {
      if (!r.success) {
        const code = r.error && r.error.code;
        if (
          code === "messaging/invalid-registration-token" ||
          code === "messaging/registration-token-not-registered"
        ) {
          deadTokens.push(tokens[i]);
        } else {
          logger.warn(`FCM error for token[${i}]`, r.error);
        }
      }
    });
    if (deadTokens.length) {
      const batch = db.batch();
      const tokRef = db.collection("users").doc(userId).collection("fcm_tokens");
      deadTokens.forEach((t) => batch.delete(tokRef.doc(t)));
      await batch.commit();
      logger.info(`Pruned ${deadTokens.length} dead token(s) for user ${userId}`);
    }
  } catch (e) {
    logger.error(`FCM multicast failed for user ${userId}`, e);
  }
}

function stringifyData(obj) {
  // FCM data values must all be strings.
  const out = {};
  for (const [k, v] of Object.entries(obj)) {
    if (v === null || v === undefined) continue;
    out[k] = String(v);
  }
  return out;
}
