/**
 * Abeni Mart — Cloud Functions for FCM push notifications + Auth custom claims.
 *
 * Triggers:
 *   1. customer_messages/{id}  → push to that single customer's devices.
 *   2. broadcasts/{id}         → push to the "customers" topic.
 *   3. orders/{id} (written)   → direct push when order status changes.
 *   4. orders/{id} (created)   → push to "admins" topic on new order.
 *   5. users/{uid}             → set Firebase Auth custom claims when the
 *                                user's `role` field changes (admin/staff).
 *   6. products/{productId}    → push to "admins" topic when any unit's
 *                                stock drops to ≤3 (low stock alert).
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

setGlobalOptions({ region: "europe-west1", maxInstances: 10 });

const db = admin.firestore();
const fcm = admin.messaging();

const LOW_STOCK_THRESHOLD = 3;

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
          defaultSound: true,
          vibrateTimingsMillis: [0, 250, 250, 250],
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
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
          defaultSound: true,
        },
      },
      apns: { payload: { aps: { sound: "default", badge: 1 } } },
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
// 3. Direct order status push: triggered when an order document is updated.   //
//    This is a direct trigger so push fires even if the customer_messages     //
//    approach is delayed or the function above is temporarily unavailable.    //
// --------------------------------------------------------------------------- //
exports.onOrderStatusChanged = onDocumentWritten(
  "orders/{orderId}",
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();

    if (!after) return; // document deleted
    if (!before) return; // document created — handled by onNewOrderCreated below

    const oldStatus = before.status;
    const newStatus = after.status;

    // Only act on actual status changes.
    if (!newStatus || oldStatus === newStatus) return;

    const userId = after.userId;
    if (!userId) return;

    const orderId = event.params.orderId;
    const note = after.lastNote || "";

    const statusTitles = {
      pending: "Order received",
      processing: "Order is being prepared",
      out_for_delivery: "Out for delivery 🚚",
      delivered: "Order delivered ✅",
      cancelled: "Order cancelled",
    };

    const statusBodies = {
      pending: `Order #${orderId} is now pending.`,
      processing: `We are preparing order #${orderId} for you.`,
      out_for_delivery: `Order #${orderId} is on its way to you!`,
      delivered: `Order #${orderId} has been delivered. Enjoy!`,
      cancelled: `Order #${orderId} was cancelled.`,
    };

    const title = statusTitles[newStatus] || "Order update";
    let body = statusBodies[newStatus] || `Your order status changed to ${newStatus}.`;
    if (note) body += `\nNote: ${note}`;

    const tokens = await loadUserTokens(userId);
    if (tokens.length === 0) {
      logger.info(`No FCM tokens for user ${userId} on order ${orderId} status change.`);
      return;
    }

    const payload = {
      notification: { title, body },
      data: stringifyData({
        type: "order_status",
        orderId,
        status: newStatus,
      }),
      android: {
        priority: "high",
        notification: {
          channelId: "abeni_order_updates",
          sound: "default",
          defaultSound: true,
          vibrateTimingsMillis: [0, 250, 250, 250],
        },
      },
      apns: {
        payload: { aps: { sound: "default", badge: 1 } },
      },
    };

    await sendToTokens(userId, tokens, payload);
    logger.info(`Order status push sent: order=${orderId} ${oldStatus}→${newStatus}`);
  }
);

// --------------------------------------------------------------------------- //
// 4. New order → notify ALL admins via the "admins" FCM topic.                //
//    Fires every time a new order document is created.                        //
// --------------------------------------------------------------------------- //
exports.onNewOrderCreated = onDocumentCreated(
  "orders/{orderId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const order = snap.data();
    const orderId = event.params.orderId;

    const itemCount = Array.isArray(order.items) ? order.items.length : 0;
    const totalRaw = typeof order.total === "number" ? order.total : 0;
    const total = totalRaw.toLocaleString("en-NG", {
      style: "currency",
      currency: "NGN",
      minimumFractionDigits: 0,
    });
    const fulfillment = order.fulfillmentType === "pickup" ? "pickup" : "delivery";

    const message = {
      topic: "admins",
      notification: {
        title: "New order received! 🛒",
        body: `Order #${orderId} — ${itemCount} item${itemCount !== 1 ? "s" : ""} · ${total} (${fulfillment})`,
      },
      data: stringifyData({
        type: "new_order",
        orderId,
        total: String(totalRaw),
        fulfillmentType: order.fulfillmentType || "delivery",
      }),
      android: {
        priority: "high",
        notification: {
          channelId: "abeni_admin_orders",
          sound: "default",
          defaultSound: true,
          vibrateTimingsMillis: [0, 300, 200, 300],
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
            "content-available": 1,
          },
        },
      },
    };

    try {
      const id = await fcm.send(message);
      logger.info("Admin new-order push sent", { id, orderId });
    } catch (e) {
      logger.error("Admin new-order push failed", { orderId, error: e });
    }
  }
);

// --------------------------------------------------------------------------- //
// 5. Sync user role → Firebase Auth custom claims.                            //
// --------------------------------------------------------------------------- //
exports.onUserRoleChanged = onDocumentWritten(
  "users/{uid}",
  async (event) => {
    const uid = event.params.uid;
    const afterData = event.data?.after?.data();
    const newRole = afterData?.role ?? null;

    try {
      const userRecord = await admin.auth().getUser(uid);
      const existingClaims = userRecord.customClaims || {};

      if (existingClaims.role === newRole) return;

      await admin.auth().setCustomUserClaims(uid, {
        ...existingClaims,
        role: newRole,
      });

      logger.info(`Custom claim role=${newRole} set for uid=${uid}`);

      await db.collection("users").doc(uid).update({
        claimsRefreshedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (e) {
      logger.error(`Failed to set custom claims for uid=${uid}`, e);
    }
  }
);

// --------------------------------------------------------------------------- //
// 6. Low-stock alert → notify admins when a product unit stock drops to ≤3.  //
//    Only fires when stock crosses the threshold (not on every save).         //
// --------------------------------------------------------------------------- //
exports.onProductStockChanged = onDocumentWritten(
  "products/{productId}",
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();

    // Ignore deletions and new products (no "before" stock to compare).
    if (!before || !after) return;

    const productName = after.productName || after.name || "Unknown product";
    const beforeUnits = Array.isArray(before.units) ? before.units : [];
    const afterUnits = Array.isArray(after.units) ? after.units : [];

    // Build a map of unitName → stock for the "before" snapshot.
    const beforeStockMap = {};
    for (const u of beforeUnits) {
      if (u.unitName) beforeStockMap[u.unitName] = typeof u.stock === "number" ? u.stock : 0;
    }

    // Find units that just crossed the low-stock threshold.
    const alerts = [];
    for (const u of afterUnits) {
      if (!u.unitName) continue;
      const newStock = typeof u.stock === "number" ? u.stock : 0;
      const oldStock = typeof beforeStockMap[u.unitName] === "number"
        ? beforeStockMap[u.unitName]
        : newStock + 1; // treat missing-before as above threshold

      const wasAbove = oldStock > LOW_STOCK_THRESHOLD;
      const isNowAtOrBelow = newStock <= LOW_STOCK_THRESHOLD;

      if (wasAbove && isNowAtOrBelow) {
        alerts.push({ unitName: u.unitName, stock: newStock });
      }
    }

    if (alerts.length === 0) return;

    // Build one notification covering all newly low/out-of-stock units.
    const outOfStock = alerts.filter((a) => a.stock === 0);
    const lowStock = alerts.filter((a) => a.stock > 0);

    let title;
    let body;

    if (outOfStock.length > 0 && lowStock.length === 0) {
      const units = outOfStock.map((a) => a.unitName).join(", ");
      title = `⚠️ Out of stock: ${productName}`;
      body = `${units} — completely out of stock. Restock soon!`;
    } else if (outOfStock.length === 0) {
      const units = lowStock.map((a) => `${a.unitName} (${a.stock} left)`).join(", ");
      title = `📦 Low stock: ${productName}`;
      body = `${units} — running low. Consider restocking.`;
    } else {
      const outStr = outOfStock.map((a) => a.unitName).join(", ");
      const lowStr = lowStock.map((a) => `${a.unitName} (${a.stock} left)`).join(", ");
      title = `⚠️ Stock alert: ${productName}`;
      body = `Out of stock: ${outStr}. Low stock: ${lowStr}.`;
    }

    const message = {
      topic: "admins",
      notification: { title, body },
      data: stringifyData({
        type: "low_stock",
        productId: event.params.productId,
        productName,
      }),
      android: {
        priority: "high",
        notification: {
          channelId: "abeni_admin_orders",
          sound: "default",
          defaultSound: true,
          vibrateTimingsMillis: [0, 400, 200, 400],
        },
      },
      apns: {
        payload: { aps: { sound: "default", badge: 1 } },
      },
    };

    try {
      const id = await fcm.send(message);
      logger.info("Low-stock alert sent", {
        id,
        productId: event.params.productId,
        alerts,
      });
    } catch (e) {
      logger.error("Low-stock alert failed", { productId: event.params.productId, error: e });
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
