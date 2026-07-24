const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

const db = admin.firestore();

exports.createOrderAndDeductStock = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Utilisateur non authentifié.");
  }

  const data = request.data || {};
  const items = Array.isArray(data.items) ? data.items : [];

  if (items.length === 0) {
    throw new HttpsError("invalid-argument", "Commande vide.");
  }

  // Ici tu refais exactement la logique de calcul des ingrédients
  // puis transaction Firestore : création commande + décrément stock + mouvements

  return { success: true };
});