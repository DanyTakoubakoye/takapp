const admin = require("firebase-admin");

if (!admin.apps.length) {
  const serviceAccount = require("./serviceAccountKey.json");

  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

const db = admin.firestore();

async function migrateOrderItems() {
  console.log("🚀 Début migration des items...");

  const ordersSnapshot = await db.collection("orders").get();

  console.log(`📦 ${ordersSnapshot.size} commandes trouvées`);

  let totalItemsUpdated = 0;

  for (const orderDoc of ordersSnapshot.docs) {
    const orderId = orderDoc.id;

    const itemsSnapshot = await db
      .collection("orders")
      .doc(orderId)
      .collection("items")
      .get();

    if (itemsSnapshot.empty) continue;

    let batch = db.batch();
    let opCount = 0;

    for (const itemDoc of itemsSnapshot.docs) {
      const data = itemDoc.data();

      const updateData = {
        isCancelled: data.isCancelled ?? false,
        cancelledAt: data.cancelledAt ?? null,
        cancelledBy: data.cancelledBy ?? "",
        cancelledByName: data.cancelledByName ?? "",
        cancellationReason: data.cancellationReason ?? "",
      };

      batch.update(itemDoc.ref, updateData);

      opCount++;
      totalItemsUpdated++;

      if (opCount === 400) {
        await batch.commit();
        batch = db.batch();
        opCount = 0;
      }
    }

    if (opCount > 0) {
      await batch.commit();
    }

    console.log(`✅ Order ${orderId} traité`);
  }

  console.log(`🎯 Migration terminée : ${totalItemsUpdated} items mis à jour`);
}

migrateOrderItems()
  .then(() => {
    console.log("✅ Succès");
    process.exit(0);
  })
  .catch((error) => {
    console.error("❌ Erreur :", error);
    process.exit(1);
  });