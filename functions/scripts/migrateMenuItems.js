const admin = require("firebase-admin");

if (!admin.apps.length) {
  const serviceAccount = require("./serviceAccountKey.json");

  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

const db = admin.firestore();

async function migrateMenuItems() {
  console.log("🚀 Début migration menuItems...");

  const snapshot = await db.collection("menuItems").get();

  console.log(`📦 ${snapshot.size} menuItems trouvés`);

  let batch = db.batch();
  let opCount = 0;
  let updatedCount = 0;

  for (const doc of snapshot.docs) {
    const data = doc.data();

    const updateData = {
      // 🔥 Ajout du champ sans écraser s’il existe déjà
      store: data.store ?? "",

  ingredients: [
    {
      "ingredientId": " ",
      "quantity": 0,
      "unit": ""
    }
  ]
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

  console.log(`🎯 Migration terminée : ${updatedCount} menuItems mis à jour`);
}

migrateMenuItems()
  .then(() => {
    console.log("✅ Succès");
    process.exit(0);
  })
  .catch((error) => {
    console.error("❌ Erreur :", error);
    process.exit(1);
  });