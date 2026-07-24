const fs = require("fs");
const path = require("path");
const admin = require("firebase-admin");

const serviceAccount = require("../serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

const COLLECTIONS = [
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

async function backupCollection(collectionName) {
  console.log(`\nBackup de ${collectionName}...`);

  const snapshot = await db.collection(collectionName).get();

  const data = [];

  for (const doc of snapshot.docs) {
    data.push({
      id: doc.id,
      ...doc.data(),
    });
  }

  const backupDir = path.join(__dirname, "backups");

  if (!fs.existsSync(backupDir)) {
    fs.mkdirSync(backupDir, { recursive: true });
  }

  const filePath = path.join(backupDir, `${collectionName}.json`);

  fs.writeFileSync(filePath, JSON.stringify(data, null, 2), "utf8");

  console.log(`${collectionName}: ${data.length} documents sauvegardés`);
}

async function main() {
  try {
    console.log("Début du backup Firestore Takapp");

    for (const collectionName of COLLECTIONS) {
      await backupCollection(collectionName);
    }

    console.log("\nBackup Firestore terminé avec succès");
    process.exit(0);
  } catch (error) {
    console.error("Erreur pendant le backup Firestore:", error);
    process.exit(1);
  }
}

main();