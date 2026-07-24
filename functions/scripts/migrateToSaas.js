const admin = require("firebase-admin");

const serviceAccount = require("../serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

const ESTABLISHMENT_ID = "UYl0zamuxqrKOTw6K5DG";

const COLLECTIONS_TO_MIGRATE = [
  "users",
  "menuItems",
  "managerToAccountingTransfers",
  "stock_items",
  "store_stocks",
  "stock_requests",
  "stock_movements",
  "orders",
  "payments",
  "roomInvoices",
  "serverHandovers",
  "serverNotifications",
  "hygiene_daily_entries",
];

async function migrateCollection(collectionName) {
  console.log(`\nMigration de la collection: ${collectionName}`);

  const snapshot = await db.collection(collectionName).get();

  if (snapshot.empty) {
    console.log(`Aucun document trouvé dans ${collectionName}`);
    return;
  }

  let batch = db.batch();
  let count = 0;
  let batchCount = 0;

  for (const doc of snapshot.docs) {
    const data = doc.data();

    const targetRef = db
      .collection("establishments")
      .doc(ESTABLISHMENT_ID)
      .collection(collectionName)
      .doc(doc.id);

    batch.set(targetRef, {
      ...data,
      establishmentId: ESTABLISHMENT_ID,
      migratedFrom: collectionName,
      migratedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    count++;
    batchCount++;

    if (batchCount === 450) {
      await batch.commit();
      console.log(`${count} documents migrés dans ${collectionName}`);
      batch = db.batch();
      batchCount = 0;
    }
  }

  if (batchCount > 0) {
    await batch.commit();
  }

  console.log(`Migration terminée pour ${collectionName}: ${count} documents`);
}

async function migrateOrderItems() {
  console.log("\nMigration des sous-collections orders/{orderId}/items");

  const ordersSnapshot = await db.collection("orders").get();

  for (const orderDoc of ordersSnapshot.docs) {
    const itemsSnapshot = await db
      .collection("orders")
      .doc(orderDoc.id)
      .collection("items")
      .get();

    if (itemsSnapshot.empty) continue;

    let batch = db.batch();
    let count = 0;

    for (const itemDoc of itemsSnapshot.docs) {
      const targetRef = db
        .collection("establishments")
        .doc(ESTABLISHMENT_ID)
        .collection("orders")
        .doc(orderDoc.id)
        .collection("items")
        .doc(itemDoc.id);

      batch.set(targetRef, {
        ...itemDoc.data(),
        establishmentId: ESTABLISHMENT_ID,
        migratedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });

      count++;
    }

    await batch.commit();
    console.log(`Commande ${orderDoc.id}: ${count} items migrés`);
  }
}

async function createEstablishmentIfMissing() {
  const ref = db.collection("establishments").doc(ESTABLISHMENT_ID);

  await ref.set({
    name: "Takhotel",
    status: "active",
    modules: {
      restaurant: true,
      bar: true,
      hotel: true,
      stock: true,
      fiscalization: true,
    },
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });

  console.log(`Établissement ${ESTABLISHMENT_ID} créé ou mis à jour`);
}

async function addEstablishmentIdToUsers() {
  console.log("\nAjout de establishmentId aux utilisateurs");

  const snapshot = await db.collection("users").get();

  if (snapshot.empty) {
    console.log("Aucun utilisateur trouvé");
    return;
  }

  let batch = db.batch();
  let count = 0;

  for (const doc of snapshot.docs) {
    batch.set(doc.ref, {
      establishmentId: ESTABLISHMENT_ID,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    count++;
  }

  await batch.commit();

  console.log(`${count} utilisateurs mis à jour`);
}

async function main() {
  try {
    console.log("Début migration SaaS Takapp");

    await createEstablishmentIfMissing();
    await addEstablishmentIdToUsers();

    for (const collectionName of COLLECTIONS_TO_MIGRATE) {
      await migrateCollection(collectionName);
    }

    await migrateOrderItems();

    console.log("\nMigration SaaS terminée avec succès");
    process.exit(0);
  } catch (error) {
    console.error("Erreur pendant la migration:", error);
    process.exit(1);
  }
}

main();