const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

if (admin.apps.length === 0) {
  admin.initializeApp();
}

function buildClientLabel(orderData) {
  const clientType = orderData.clientType || "";
  const tableNumber = orderData.tableNumber || "";
  const roomNumber = orderData.roomNumber || "";
  if (clientType === "hotel" && roomNumber) {
    return `Chambre ${roomNumber}`;
  }
  if (tableNumber) {
    return `Table ${tableNumber}`;
  }
  if (clientType === "bar") {
    return "Client Bar";
  }
  if (clientType === "restaurant") {
    return "Client Restaurant";
  }
  return "Client";
}

async function getTokensByRole(role, establishmentId) {
  const snap = await admin
    .firestore()
    .collection("users")
    .where("role", "==", role)
    .where("establishmentId", "==", establishmentId)
    .get();

  const tokens = [];
  snap.forEach((doc) => {
    const data = doc.data() || {};
    const token = data.fcmToken;
    if (typeof token === "string" && token.trim() !== "") {
      tokens.push({
        uid: doc.id,
        token: token.trim(),
      });
    }
  });
  return tokens;
}

async function sendToTokens({ tokens, messageBuilder }) {
  const results = [];
  for (const item of tokens) {
    try {
      const message = messageBuilder(item.token);
      const response = await admin.messaging().send(message);
      results.push({ uid: item.uid, success: true, response });
    } catch (error) {
      console.error("Erreur envoi FCM:", {
        uid: item.uid,
        error: error.message,
      });
      results.push({ uid: item.uid, success: false, error: error.message });
    }
  }
  return results;
}

exports.notifyDepartmentsNewOrder = onDocumentCreated(
  {
    region: "us-central1",
    document: "establishments/{establishmentId}/orders/{orderId}",
  },
  async (event) => {
    const snap = event.data;
    if (!snap) {
      console.log("Aucun snapshot recu.");
      return;
    }

    const orderId = event.params.orderId;
    const establishmentId = event.params.establishmentId;
    const orderData = snap.data() || {};
    const orderNumber = orderData.orderNumber || "";
    const isForKitchen = orderData.isForKitchen === true;
    const isForBar = orderData.isForBar === true;
    const clientLabel = buildClientLabel(orderData);

    console.log("Nouvelle commande detectee:", {
      orderId,
      establishmentId,
      orderNumber,
      isForKitchen,
      isForBar,
      clientLabel,
    });

    const promises = [];

    if (isForKitchen) {
      promises.push(
        (async () => {
          const kitchenTokens = await getTokensByRole(
            "chef_cuisine",
            establishmentId
          );
          await admin
            .firestore()
            .collection("establishments")
            .doc(establishmentId)
            .collection("departmentNotifications")
            .add({
              department: "kitchen",
              title: "Nouvelle commande cuisine",
              body: `Nouvelle commande cuisine - ${clientLabel}.`,
              orderId,
              orderNumber,
              isRead: false,
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
          return sendToTokens({
            tokens: kitchenTokens,
            messageBuilder: (token) => ({
              token,
              notification: {
                title: "Nouvelle commande cuisine",
                body: `Nouvelle commande cuisine - ${clientLabel}.`,
              },
              data: {
                type: "new_kitchen_order",
                source: "kitchen_new_order",
                orderId,
                orderNumber,
              },
              android: {
                priority: "high",
                notification: {
                  channelId: "new_kitchen_order_channel_v3",
                  sound: "kitchen_ready",
                },
              },
              webpush: {
                notification: {
                  title: "Nouvelle commande cuisine",
                  body: `Nouvelle commande cuisine - ${clientLabel}.`,
                },
              },
            }),
          });
        })()
      );
    }

    if (isForBar) {
      promises.push(
        (async () => {
          const barTokens = await getTokensByRole("barman", establishmentId);
          await admin
            .firestore()
            .collection("establishments")
            .doc(establishmentId)
            .collection("departmentNotifications")
            .add({
              department: "bar",
              title: "Nouvelle commande bar",
              body: `Nouvelle commande bar - ${clientLabel}.`,
              orderId,
              orderNumber,
              isRead: false,
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
          return sendToTokens({
            tokens: barTokens,
            messageBuilder: (token) => ({
              token,
              notification: {
                title: "Nouvelle commande bar",
                body: `Nouvelle commande bar - ${clientLabel}.`,
              },
              data: {
                type: "new_bar_order",
                source: "bar_new_order",
                orderId,
                orderNumber,
              },
              android: {
                priority: "high",
                notification: {
                  channelId: "new_bar_order_channel_v3",
                  sound: "bar_ready",
                },
              },
              webpush: {
                notification: {
                  title: "Nouvelle commande bar",
                  body: `Nouvelle commande bar - ${clientLabel}.`,
                },
              },
            }),
          });
        })()
      );
    }

    const results = await Promise.all(promises);
    console.log("Notifications departements envoyees:", results);
  }
);