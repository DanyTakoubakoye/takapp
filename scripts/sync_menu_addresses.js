const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

// =======================
// CONFIGURATION
// =======================
const platsFilePath = 'C:/Users/danyt/Downloads/plats.txt';
const imagesDir = 'C:/src/Applications/Takhotel/takapp/assets/images/menuimages';

// Mets ici le chemin vers ta clé Firebase Admin SDK
const serviceAccount = require('./serviceAccountKey.json');

// Nom exact de la collection Firestore
const collectionName = 'menuItems';

// Si true => adresse = null si image absente
const writeNullWhenImageMissing = true;

// =======================
// INITIALISATION FIREBASE
// =======================
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// =======================
// OUTILS
// =======================
function normalizeFileName(text) {
  return text
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '') // supprime accents
    .replace(/œ/g, 'oe')
    .replace(/æ/g, 'ae')
    .replace(/[^a-z0-9]/g, ''); // supprime espaces et caractères spéciaux
}

function loadPlats(filePath) {
  const content = fs.readFileSync(filePath, 'utf8');
  return content
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter((line) => line.length > 0);
}

function imageExists(fileName) {
  const fullPath = path.join(imagesDir, fileName);
  return fs.existsSync(fullPath);
}

// =======================
// SCRIPT PRINCIPAL
// =======================
async function main() {
  try {
    const plats = loadPlats(platsFilePath);

    console.log(`Nombre de plats lus dans plats.txt : ${plats.length}`);

    let updatedCount = 0;
    let notFoundCount = 0;
    let duplicateCount = 0;
    let noImageCount = 0;

    const report = [];

    for (const plat of plats) {
      const normalized = normalizeFileName(plat);
      const fileName = `${normalized}.jpg`;

      const exists = imageExists(fileName);

      // ✅ CORRECTION ICI
      const adresseValue = exists
        ? `assets/images/menuimages/${fileName}`
        : (writeNullWhenImageMissing ? null : undefined);

      const snapshot = await db
        .collection(collectionName)
        .where('name', '==', plat)
        .get();

      if (snapshot.empty) {
        notFoundCount++;
        report.push({
          name: plat,
          status: 'NOT_FOUND_IN_FIRESTORE',
          adresse: adresseValue,
        });
        console.log(`Introuvable dans Firestore : ${plat}`);
        continue;
      }

      if (snapshot.docs.length > 1) {
        duplicateCount++;
        console.log(`Doublons détectés pour : ${plat} (${snapshot.docs.length} docs)`);
      }

      for (const doc of snapshot.docs) {
        const updateData = {};

        // ✅ CORRECTION ICI
        if (exists) {
          updateData.adresse = `assets/images/menuimages/${fileName}`;
        } else if (writeNullWhenImageMissing) {
          updateData.adresse = null;
          noImageCount++;
        }

        if (Object.keys(updateData).length > 0) {
          await doc.ref.update(updateData);
          updatedCount++;
        }

        report.push({
          name: plat,
          docId: doc.id,
          status: exists ? 'UPDATED_WITH_IMAGE' : 'UPDATED_WITH_NULL',
          adresse: adresseValue,
        });

        console.log(
          `${plat} -> ${adresseValue !== undefined ? adresseValue : 'non modifié'}`
        );
      }
    }

    const reportPath = path.join(process.cwd(), 'sync_menu_addresses_report.json');
    fs.writeFileSync(reportPath, JSON.stringify(report, null, 2), 'utf8');

    console.log('\n=== TERMINÉ ===');
    console.log(`Documents mis à jour : ${updatedCount}`);
    console.log(`Plats introuvables dans Firestore : ${notFoundCount}`);
    console.log(`Doublons détectés : ${duplicateCount}`);
    console.log(`Plats sans image : ${noImageCount}`);
    console.log(`Rapport enregistré : ${reportPath}`);
  } catch (error) {
    console.error('Erreur :', error);
  }
}

main();