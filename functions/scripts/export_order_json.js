const admin = require('firebase-admin');
const fs = require('fs');

// 🔥 Remplace par ton fichier de clé Firebase
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// 🔥 CONFIGURATION
const COLLECTION_NAME = 'store_stocks';
const DOCUMENT_ID = '0TVbeSeRwjkd9CToehyo';
const OUTPUT_FILE = 'store_stock_export.json';

// 🔧 Conversion propre Firestore → JSON
function normalizeFirestoreData(data) {
  if (data === null || data === undefined) return data;

  if (data instanceof admin.firestore.Timestamp) {
    return data.toDate().toISOString();
  }

  if (data instanceof Date) {
    return data.toISOString();
  }

  if (Array.isArray(data)) {
    return data.map((item) => normalizeFirestoreData(item));
  }

  if (typeof data === 'object') {
    const result = {};
    for (const key in data) {
      result[key] = normalizeFirestoreData(data[key]);
    }
    return result;
  }

  return data;
}

async function exportDocument() {
  try {
    const docRef = db.collection(COLLECTION_NAME).doc(DOCUMENT_ID);
    const docSnap = await docRef.get();

    if (!docSnap.exists) {
      console.log('❌ Document introuvable.');
      return;
    }

    const rawData = docSnap.data();

    const normalizedData = {
      id: docSnap.id,
      ...normalizeFirestoreData(rawData),
    };

    fs.writeFileSync(
      OUTPUT_FILE,
      JSON.stringify(normalizedData, null, 2),
      'utf-8'
    );

    console.log(`✅ Document exporté dans ${OUTPUT_FILE}`);

  } catch (error) {
    console.error('❌ Erreur:', error);
  }
}

exportDocument();