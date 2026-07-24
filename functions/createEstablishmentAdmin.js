const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp();
}

exports.createEstablishmentAdmin = onCall(
  { region: "us-central1" },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Utilisateur non connecté.");
    }

    const callerDoc = await admin
      .firestore()
      .collection("users")
      .doc(request.auth.uid)
      .get();

    const caller = callerDoc.data();

    if (!caller || caller.role !== "global_admin") {
      throw new HttpsError(
        "permission-denied",
        "Seul un global_admin peut créer un administrateur d’établissement."
      );
    }

    const {
      email,
      password,
      name,
      phone,
      establishmentId,
      establishmentName,
      modules,
    } = request.data;

    if (!email || !password || !name || !establishmentId) {
      throw new HttpsError(
        "invalid-argument",
        "email, password, name et establishmentId sont obligatoires."
      );
    }

    const userRecord = await admin.auth().createUser({
      email: String(email).trim(),
      password: String(password).trim(),
      displayName: String(name).trim(),
      disabled: false,
    });

    await admin.firestore().collection("users").doc(userRecord.uid).set({
      uid: userRecord.uid,
      email: String(email).trim(),
      name: String(name).trim(),
      phone: String(phone || "").trim(),
      role: "proprietaire",
      establishmentId,
      establishmentName: String(establishmentName || "").trim(),
      isActive: true,
      modules: modules || {
        restaurant: true,
        bar: true,
        hotel: true,
        stock: true,
        fiscalization: true,
      },
      mustChangePassword: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await admin
      .firestore()
      .collection("establishments")
      .doc(establishmentId)
      .set(
        {
          ownerUid: userRecord.uid,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

    return {
      success: true,
      uid: userRecord.uid,
      email,
    };
  }
);