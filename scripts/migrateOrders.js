const admin = require('firebase-admin');

const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function migrateOrders() {
  const snapshot = await db.collection('orders').get();

  console.log(`Documents trouvés : ${snapshot.size}`);

  let batch = db.batch();
  let opCount = 0;
  let updatedCount = 0;

  for (const doc of snapshot.docs) {
    const data = doc.data();
    const items = Array.isArray(data.items) ? data.items : [];

    const activeItems = items.filter(item => item.isCancelled !== true);
    const activeKitchenItems = activeItems.filter(
      item => item.targetDepartment === 'kitchen'
    );
    const activeBarItems = activeItems.filter(
      item => item.targetDepartment === 'bar'
    );

    const hasCancelledItems = items.some(item => item.isCancelled === true);

    const updateData = {
      hasCancelledItems,
      activeItemsCount: activeItems.length,
      activeKitchenItemsCount: activeKitchenItems.length,
      activeBarItemsCount: activeBarItems.length,
      cancelledAt: data.cancelledAt ?? null,
      cancelledBy: data.cancelledBy ?? null,
      cancelledByName: data.cancelledByName ?? null,
    };

    batch.update(doc.ref, updateData);
    opCount++;
    updatedCount++;

    if (opCount === 400) {
      await batch.commit();
      console.log(`${updatedCount} documents mis à jour...`);
      batch = db.batch();
      opCount = 0;
    }
  }

  if (opCount > 0) {
    await batch.commit();
  }

  console.log(`Migration terminée. ${updatedCount} documents mis à jour.`);
}

migrateOrders()
  .then(() => {
    console.log('Succès');
    process.exit(0);
  })
  .catch((error) => {
    console.error('Erreur migration :', error);
    process.exit(1);
  });