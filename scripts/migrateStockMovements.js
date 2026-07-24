const admin = require("firebase-admin");

if (!admin.apps.length) {
  const serviceAccount = require("./serviceAccountKey.json");

  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

const db = admin.firestore();

async function migrateStockMovements() {
  console.log("🚀 Début migration stock_movements...");

  const snapshot = await db.collection("stock_movements").get();

  console.log(`📦 ${snapshot.size} mouvements trouvés`);

  let batch = db.batch();
  let opCount = 0;
  let updatedCount = 0;

  for (const doc of snapshot.docs) {
    const data = doc.data();

    // 🔥 LOGIQUE INTELLIGENTE (adaptée TAKAPP)
    let type = data.type;
    let orderId = data.orderId;

    if (!type) {
      if (data.orderNumber) {
        type = "order";
      } else if (data.source === "manual") {
        type = "manual_adjustment";
      } else if (data.source === "restock") {
        type = "restock";
      } else {
        type = "unknown";
      }
    }

    if (!orderId) {
      orderId = data.orderId ?? data.orderNumber ?? "";
    }

    const updateData = {
      type,
      orderId,
    };

    batch.update(doc.ref, updateData);

    opCount++;
    updatedCount++;

    if (opCount === 400) {
      await batch.commit();
      console.log(`✅ ${updatedCount} documents mis à jour...`);
      batch = db.batch();
      opCount = 0;
    }
  }

  if (opCount > 0) {
    await batch.commit();
  }

  console.log(
    `🎯 Migration terminée : ${updatedCount} stock_movements mis à jour`
  );
}

migrateStockMovements()
  .then(() => {
    console.log("✅ Succès");
    process.exit(0);
  })
  .catch((error) => {
    console.error("❌ Erreur :", error);
    process.exit(1);
  });