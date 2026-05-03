/**
 * Abeni Mart — Cloud Functions for FCM push notifications + Auth custom claims.
 *
 * Triggers:
 *   1. customer_messages/{id}  → push to that single customer's devices.
 *   2. broadcasts/{id}         → push to the "customers" topic.
 *   3. users/{uid}             → set Firebase Auth custom claims when the
 *                                user's `role` field changes (admin/staff).
 *                                This avoids a Firestore read in every
 *                                security rule evaluation.
 *
 * Deploy:
 *     cd functions && npm install
 *     firebase deploy --only functions
 */

const { onDocumentCreated, onDocumentWritten } = require("firebase-functions/v2/firestore");
const { setGlobalOptions } = require("firebase-functions/v2");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

// Match the Firestore region recommended in the README (europe-west1).
setGlobalOptions({ region: "europe-west1", maxInstances: 10 });

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
        payload: { aps: { sound: "default" } },
      },
    };

    await sendToTokens(userId, tokens, payload);
  }
);

// --------------------------------------------------------------------------- //
// 2. Broadcast push: triggered by writes to /broadcasts.                      //
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
// 3. Sync user role → Firebase Auth custom claims.                            //
//    When an admin sets/changes users/{uid}.role in Firestore, this function  //
//    mirrors it as a custom claim so Firestore rules can check                //
//    request.auth.token.role without an extra document read per request.       //
// --------------------------------------------------------------------------- //
exports.onUserRoleChanged = onDocumentWritten(
  "users/{uid}",
  async (event) => {
    const uid = event.params.uid;
    const afterData = event.data?.after?.data();
    const newRole = afterData?.role ?? null;

    try {
      // Read existing claims so we don't overwrite unrelated ones.
      const userRecord = await admin.auth().getUser(uid);
      const existingClaims = userRecord.customClaims || {};

      if (existingClaims.role === newRole) return; // no change

      await admin.auth().setCustomUserClaims(uid, {
        ...existingClaims,
        role: newRole,
      });

      logger.info(`Custom claim role=${newRole} set for uid=${uid}`);

      // Write a flag so the client knows to refresh its ID token.
      await db.collection("users").doc(uid).update({
        claimsRefreshedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (e) {
      logger.error(`Failed to set custom claims for uid=${uid}`, e);
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
    logger.info(
      `FCM → user=${userId} success=${res.successCount} failure=${res.failureCount}`
    );

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
      const tokRef = db
        .collection("users")
        .doc(userId)
        .collection("fcm_tokens");
      deadTokens.forEach((t) => batch.delete(tokRef.doc(t)));
      await batch.commit();
      logger.info(
        `Pruned ${deadTokens.length} dead token(s) for user ${userId}`
      );
    }
  } catch (e) {
    logger.error(`FCM multicast failed for user ${userId}`, e);
  }
}

function stringifyData(obj) {
  const out = {};
  for (const [k, v] of Object.entries(obj)) {
    if (v === null || v === undefined) continue;
    out[k] = String(v);
  }
  return out;
}
