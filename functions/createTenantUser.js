const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp();
}

exports.createTenantUser = onCall(
  { region: "us-central1" },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Utilisateur non connecté.");
    }

    const callerSnap = await admin
      .firestore()
      .collection("users")
      .doc(request.auth.uid)
      .get();

    if (!callerSnap.exists) {
      throw new HttpsError("permission-denied", "Profil appelant introuvable.");
    }

    const caller = callerSnap.data();

    if (!["proprietaire", "gerante"].includes(caller.role)) {
      throw new HttpsError(
        "permission-denied",
        "Seul un propriétaire ou une gérante peut créer un utilisateur."
      );
    }

    const establishmentId = caller.establishmentId || "";

    if (!establishmentId) {
      throw new HttpsError(
        "failed-precondition",
        "L'appelant n'est rattaché à aucun établissement."
      );
    }

    const {
      name,
      email,
      password,
      phone,
      role,
    } = request.data;

    const allowedRoles = [
      "gerante",
      "comptable",
      "serveur",
      "barman",
      "chef_cuisine",
      "service_hygiene",
      "majordhomme",
      "receptionniste",
    ];

    if (!name || !email || !password || !role) {
      throw new HttpsError(
        "invalid-argument",
        "Nom, email, mot de passe et rôle sont obligatoires."
      );
    }

    if (!allowedRoles.includes(role)) {
      throw new HttpsError("invalid-argument", "Rôle non autorisé.");
    }

    const roleModules = {
      gerante: {
        restaurant: true,
        bar: true,
        hotel: true,
        stock: true,
        fiscalization: true,
      },
      comptable: {
        restaurant: true,
        bar: true,
        hotel: true,
        stock: false,
        fiscalization: true,
      },
      serveur: {
        restaurant: true,
        bar: true,
        hotel: true,
        stock: false,
        fiscalization: true,
      },
      barman: {
        restaurant: false,
        bar: true,
        hotel: false,
        stock: true,
        fiscalization: false,
      },
      chef_cuisine: {
        restaurant: true,
        bar: false,
        hotel: false,
        stock: true,
        fiscalization: false,
      },
      service_hygiene: {
        restaurant: false,
        bar: false,
        hotel: true,
        stock: true,
        fiscalization: false,
      },
      majordhomme: {
        restaurant: false,
        bar: false,
        hotel: true,
        stock: true,
        fiscalization: false,
      },
      receptionniste: {
        restaurant: false,
        bar: false,
        hotel: true,
        stock: false,
        fiscalization: true,
      },
    };

    const establishmentSnap = await admin
      .firestore()
      .collection("establishments")
      .doc(establishmentId)
      .get();

    const establishment = establishmentSnap.data() || {};
    const establishmentName = establishment.name || caller.establishmentName || "";

    const userRecord = await admin.auth().createUser({
      email: String(email).trim(),
      password: String(password).trim(),
      displayName: String(name).trim(),
      disabled: false,
    });

    await admin.firestore().collection("users").doc(userRecord.uid).set({
      uid: userRecord.uid,
      establishmentId,
      establishmentName,
      name: String(name).trim(),
      email: String(email).trim(),
      phone: String(phone || "").trim(),
      role,
      isActive: true,
      modules: roleModules[role],
      mustChangePassword: true,
      createdBy: request.auth.uid,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      success: true,
      uid: userRecord.uid,
      email,
    };
  }
);