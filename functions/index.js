const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

const db = admin.firestore();

/// Triggered when any presence document changes.
/// Evaluates whether everyone has left or someone arrived,
/// then arms/disarms partitions or sends a notification prompt.
exports.evaluateGeofence = functions.firestore
  .document("presence/{siteId}")
  .onWrite(async (change, context) => {
    const siteId = context.params.siteId;
    const presenceData = change.after.data();
    if (!presenceData || !presenceData.members) return;

    // Get site config
    const siteSnap = await db.collection("sites").doc(siteId).get();
    if (!siteSnap.exists) return;
    const site = { id: siteSnap.id, ...siteSnap.data() };

    if (!site.geofence || !site.geofence.enabled) return;

    const members = presenceData.members;
    const anyoneHome = Object.values(members).some((m) => m.inside === true);

    // Get panel for this site
    const panelSnap = await db
      .collection("panels")
      .where("siteId", "==", siteId)
      .limit(1)
      .get();

    if (panelSnap.empty) return;
    const panelRef = panelSnap.docs[0].ref;
    const panel = panelSnap.docs[0].data();

    if (!anyoneHome) {
      await handleEveryoneLeft(panelRef, panel, site);
    } else {
      await handleSomeoneArrived(panelRef, panel, site);
    }
  });

async function handleEveryoneLeft(panelRef, panel, site) {
  if (site.geofence.mode === "auto") {
    // Auto-arm all partitions that are currently disarmed
    const updatedPartitions = panel.partitions.map((p) => {
      if (p.state === "disarmed") {
        return { ...p, state: "armed" };
      }
      return p;
    });

    await panelRef.update({ partitions: updatedPartitions });
    await logEvent(
      panelRef.id,
      site.id,
      "arm",
      "geofence",
      "Auto-armed: everyone left the geofence"
    );
  } else {
    // Prompt mode — send push notification (stub: just log the event)
    await logEvent(
      panelRef.id,
      site.id,
      "geofence_prompt",
      "geofence",
      "Everyone left — arm prompt sent"
    );
    // In production: send FCM notification here
    // await admin.messaging().sendToTopic(`site_${site.id}`, { ... });
  }
}

async function handleSomeoneArrived(panelRef, panel, site) {
  // Disarm is ALWAYS prompt mode for security.
  // You never silently disarm — that would be a security risk.
  const isArmed = panel.partitions.some((p) => p.state !== "disarmed");

  if (isArmed) {
    await logEvent(
      panelRef.id,
      site.id,
      "geofence_prompt",
      "geofence",
      "Someone arrived — disarm prompt sent"
    );
    // In production: send FCM notification here
  }
}

async function logEvent(panelId, siteId, type, source, details) {
  await db.collection("events").add({
    panelId,
    siteId,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    type,
    source,
    userId: null,
    details,
    partitionId: null,
  });
}
