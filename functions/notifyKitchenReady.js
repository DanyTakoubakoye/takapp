const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

if (admin.apps.length === 0) {
  admin.initializeApp();
}

exports.notifyKitchenReady = onCall(
  { region: "us-central1" },
  async (request) => {
    try {
      const orderId = request.data.orderId;

      if (!orderId) {
        throw new HttpsError("invalid-argument", "orderId manquant.");
      }

      const orderDoc = await admin
        .firestore()
        .collection("orders")
        .doc(orderId)
        .get();

      if (!orderDoc.exists) {
        throw new HttpsError("not-found", "Commande introuvable.");
      }

      const orderData = orderDoc.data() || {};
      const serveurId = orderData.createdBy;
      const orderNumber = orderData.orderNumber || "";
      const clientType = orderData.clientType || "";
      const tableNumber = orderData.tableNumber || "";
      const roomNumber = orderData.roomNumber || "";

      let destinationLabel = `la commande ${orderNumber}`;

      if (clientType === "hotel" && roomNumber) {
        destinationLabel = `la chambre ${roomNumber}`;
      } else if (tableNumber) {
        destinationLabel = `la table ${tableNumber}`;
      }

      if (!serveurId) {
        throw new HttpsError(
          "failed-precondition",
          "createdBy manquant sur la commande."
        );
      }

      const userDoc = await admin
        .firestore()
        .collection("users")
        .doc(serveurId)
        .get();

      if (!userDoc.exists) {
        throw new HttpsError("not-found", "Serveur introuvable.");
      }

      const userData = userDoc.data() || {};
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
          title: "Commande prête",
          body: `La commande de ${destinationLabel} est prête à la cuisine.`,
        },
        data: {
          type: "kitchen_ready",
          orderId: orderId,
          orderNumber: orderNumber,
          source: "kitchen",
        },
        webpush: {
          notification: {
            title: "Commande prête",
            body: `La commande de ${destinationLabel} est prête à la cuisine.`,
          },
        },
        android: {
          priority: "high",
          notification: {
            channelId: "kitchen_ready_channel_v6",
            sound: "kitchen_ready",
          },
        },
      };

      const response = await admin.messaging().send(message);

      await admin.firestore().collection("serverNotifications").add({
        serveurId: serveurId,
        orderId: orderId,
        orderNumber: orderNumber,
        title: "Commande prête",
        body: `La commande de ${destinationLabel} est prête à la cuisine.`,
        isRead: false,
        source: "kitchen",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log("Notification envoyée avec succès:", response);

      return {
        success: true,
        message: "Notification envoyée.",
      };
    } catch (error) {
      console.error("notifyKitchenReady error:", error);

      if (error instanceof HttpsError) {
        throw error;
      }

      throw new HttpsError(
        "internal",
        error.message || "Erreur envoi notification."
      );
    }
  }
);