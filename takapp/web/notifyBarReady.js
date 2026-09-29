const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

exports.notifyBarReady = onCall(
  { region: "us-central1" },
  async (request) => {
    try {
      if (!request.auth) {
        throw new HttpsError("unauthenticated", "Connexion requise.");
      }

      const { orderId, establishmentId } = request.data || {};

      if (!orderId || !establishmentId) {
        throw new HttpsError(
          "invalid-argument",
          "orderId et establishmentId sont requis."
        );
      }

      const db = admin.firestore();
      const callerDoc = await db
        .collection("users")
        .doc(request.auth.uid)
        .get();

      if (!callerDoc.exists) {
        throw new HttpsError("permission-denied", "Profil utilisateur introuvable.");
      }

      const caller = callerDoc.data() || {};
      const role = String(caller.role || "").trim();
      const isPlatformAdmin = ["super_admin", "global_admin"].includes(role);
      const canNotify = [
        "barman",
        "gerante",
        "proprietaire",
        "super_admin",
        "global_admin",
      ].includes(role);

      if (!canNotify || caller.isActive === false) {
        throw new HttpsError("permission-denied", "Action non autorisée.");
      }

      if (!isPlatformAdmin && caller.establishmentId !== establishmentId) {
        throw new HttpsError("permission-denied", "Établissement non autorisé.");
      }

      const orderDoc = await db
        .collection("establishments")
        .doc(establishmentId)
        .collection("orders")
        .doc(orderId)
        .get();

      if (!orderDoc.exists) {
        throw new HttpsError("not-found", "Commande introuvable.");
      }

      const orderData = orderDoc.data() || {};
      const serveurId = orderData.createdBy;
      const orderNumber = orderData.orderNumber || "";

      if (!serveurId) {
        throw new HttpsError(
          "failed-precondition",
          "createdBy manquant sur la commande."
        );
      }

      const userDoc = await db
        .collection("users")
        .doc(serveurId)
        .get();

      if (!userDoc.exists) {
        throw new HttpsError("not-found", "Serveur introuvable.");
      }

      const userData = userDoc.data() || {};
      if (userData.establishmentId !== establishmentId) {
        throw new HttpsError("permission-denied", "Serveur d’un autre établissement.");
      }
      const token = userData.fcmToken;

      if (!token) {
        throw new HttpsError(
          "failed-precondition",
          "fcmToken introuvable pour ce serveur."
        );
      }

      const message = {
        token: token,
        notification: {
          title: "Commande bar prête",
          body: `La commande ${orderNumber} est prête au bar.`,
        },
        data: {
          type: "bar_ready",
          orderId: orderId,
          orderNumber: orderNumber,
          soundType: "bar",
        },
        webpush: {
          notification: {
            title: "Commande bar prête",
            body: `La commande ${orderNumber} est prête au bar.`,
          },
        },
        android: {
          priority: "high",
        },
      };

      const response = await admin.messaging().send(message);

      await db
        .collection("establishments")
        .doc(establishmentId)
        .collection("serverNotifications")
        .add({
          serveurId: serveurId,
          orderId: orderId,
          orderNumber: orderNumber,
          title: "Commande bar prête",
          body: `La commande ${orderNumber} est prête au bar.`,
          isRead: false,
          source: "bar",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

      console.log("Notification bar envoyée avec succès:", response);

      return {
        success: true,
        message: "Notification bar envoyée.",
      };
    } catch (error) {
      console.error("notifyBarReady error:", error);

      if (error instanceof HttpsError) {
        throw error;
      }

      throw new HttpsError(
        "internal",
        error.message || "Erreur envoi notification bar."
      );
    }
  }
);