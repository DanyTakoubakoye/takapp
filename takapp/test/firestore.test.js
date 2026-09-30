import { readFileSync } from 'node:fs';
import { test, before, after, beforeEach } from 'node:test';
import assert from 'node:assert';
import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} from '@firebase/rules-unit-testing';
import {
  doc, getDoc, setDoc, updateDoc, deleteDoc, writeBatch,
  collection, query, where, orderBy, getDocs, serverTimestamp,
  increment, runTransaction,
} from 'firebase/firestore';

let testEnv;

// Identifiants des deux tenants
const ESTAB_A = 'estabA';
const ESTAB_B = 'estabB';

// UIDs
const SERVEUR_A = 'serveurA';
const SERVEUR_B = 'serveurB';
const GERANTE_A = 'geranteA';
const COMPTABLE_A = 'comptableA';
const PROPRIETAIRE_A = 'proprietaireA';
const GLOBAL_ADMIN = 'globalAdmin';

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'takapp-rules-test',
    firestore: {
      rules: readFileSync('firestore.rules', 'utf8'),
      host: '127.0.0.1',
      port: 8080,
    },
  });
});

after(async () => {
  await testEnv.cleanup();
});

// Avant chaque test : on repart propre et on sème les docs users (pivot sécurité)
// + un doc de commande dans chaque établissement.
beforeEach(async () => {
  await testEnv.clearFirestore();

  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();

    // Docs users à la RACINE (ce que lisent les règles)
    await setDoc(doc(db, 'users', SERVEUR_A), { role: 'serveur', establishmentId: ESTAB_A });
    await setDoc(doc(db, 'users', SERVEUR_B), { role: 'serveur', establishmentId: ESTAB_B });
    await setDoc(doc(db, 'users', GERANTE_A), { role: 'gerante', establishmentId: ESTAB_A });
    await setDoc(doc(db, 'users', COMPTABLE_A), { role: 'comptable', establishmentId: ESTAB_A });
    await setDoc(doc(db, 'users', PROPRIETAIRE_A), { role: 'proprietaire', establishmentId: ESTAB_A });
    await setDoc(doc(db, 'users', GLOBAL_ADMIN), { role: 'global_admin', establishmentId: '' });

    // Une commande dans chaque établissement
    await setDoc(doc(db, 'establishments', ESTAB_A, 'orders', 'order1'), { total: 1000 });
    await setDoc(doc(db, 'establishments', ESTAB_B, 'orders', 'order1'), { total: 2000 });

    // Une clôture de caisse dans A (pour tester le raffinement par rôle)
    await setDoc(doc(db, 'establishments', ESTAB_A, 'accountClosures', 'clo1'), { validated: true });
    await setDoc(doc(db, 'establishments', ESTAB_A, 'payments', 'payment1'), {
      amount: 1000, handoverStatus: 'declared', handoverId: 'handover1',
      receivedBy: SERVEUR_A,
    });
    await setDoc(doc(db, 'establishments', ESTAB_A, 'serverHandovers', 'handover1'), {
      serveurId: SERVEUR_A,
      paymentIds: ['payment1'],
      validatedPaymentIds: [],
      rejectedPaymentIds: [],
      accountingTransferStatus: 'pending',
    });

    // Une notification pour SERVEUR_A
    await setDoc(doc(db, 'establishments', ESTAB_A, 'serverNotifications', 'notif1'), {
      serveurId: SERVEUR_A, isRead: false, title: 't', body: 'b',
    });
  });
});

// Helpers pour obtenir un contexte authentifié
function asUser(uid) {
  return testEnv.authenticatedContext(uid).firestore();
}
function asAnon() {
  return testEnv.unauthenticatedContext().firestore();
}

// ─────────── ISOLATION TENANT ───────────

test('✅ serveur A lit une commande de A', async () => {
  const db = asUser(SERVEUR_A);
  await assertSucceeds(getDoc(doc(db, 'establishments', ESTAB_A, 'orders', 'order1')));
});

test('🔒 serveur A ne peut PAS lire une commande de B', async () => {
  const db = asUser(SERVEUR_A);
  await assertFails(getDoc(doc(db, 'establishments', ESTAB_B, 'orders', 'order1')));
});

test('🔒 serveur A ne peut PAS écrire dans B', async () => {
  const db = asUser(SERVEUR_A);
  await assertFails(
    setDoc(doc(db, 'establishments', ESTAB_B, 'orders', 'hack'), { total: 999, createdBy: SERVEUR_A })
  );
});

test('✅ global_admin lit A ET B', async () => {
  const db = asUser(GLOBAL_ADMIN);
  await assertSucceeds(getDoc(doc(db, 'establishments', ESTAB_A, 'orders', 'order1')));
  await assertSucceeds(getDoc(doc(db, 'establishments', ESTAB_B, 'orders', 'order1')));
});

// ─────────── RAFFINEMENT PAR RÔLE ───────────

test('🔒 serveur A ne peut PAS supprimer une clôture de caisse', async () => {
  const db = asUser(SERVEUR_A);
  await assertFails(deleteDoc(doc(db, 'establishments', ESTAB_A, 'accountClosures', 'clo1')));
});

test('✅ gerante A crée une commande dans A', async () => {
  const db = asUser(GERANTE_A);
  await assertSucceeds(
    setDoc(doc(db, 'establishments', ESTAB_A, 'orders', 'order2'), { total: 500, createdBy: GERANTE_A })
  );
});

// ─────────── NON AUTHENTIFIÉ ───────────

test('🔒 un anonyme ne lit rien', async () => {
  const db = asAnon();
  await assertFails(getDoc(doc(db, 'establishments', ESTAB_A, 'orders', 'order1')));
});

// ─────────── LEGACY RACINE BLOQUÉ ───────────

test('🔒 personne ne lit la collection orders à la RACINE (legacy bloqué)', async () => {
  const db = asUser(GERANTE_A);
  await assertFails(getDoc(doc(db, 'orders', 'order1')));
});

test('serveur A cree un roomExtra dans A', async () => {
  await assertSucceeds(setDoc(doc(asUser(SERVEUR_A), 'establishments', ESTAB_A, 'roomExtras', 'ex1'), { amount: 500 }));
});

test('serveur A ne peut PAS creer un roomExtra dans B', async () => {
  await assertFails(setDoc(doc(asUser(SERVEUR_A), 'establishments', ESTAB_B, 'roomExtras', 'ex1'), { amount: 500 }));
});

// ─────────── CATALOGUE modules RACINE (lecture) ───────────

test('✅ un utilisateur connecté lit le catalogue modules racine', async () => {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'modules', 'restaurant'), { label: 'Restaurant' });
  });
  const db = asUser(SERVEUR_A);
  await assertSucceeds(getDoc(doc(db, 'modules', 'restaurant')));
});

test('🔒 serveur A ne peut PAS lire le profil du serveur B', async () => {
  await assertFails(getDoc(doc(asUser(SERVEUR_A), 'users', SERVEUR_B)));
});

test('🔒 serveur A ne peut PAS modifier son rôle', async () => {
  await assertFails(updateDoc(doc(asUser(SERVEUR_A), 'users', SERVEUR_A), { role: 'proprietaire' }));
});

test('🔒 serveur A ne peut PAS changer son établissement', async () => {
  await assertFails(updateDoc(doc(asUser(SERVEUR_A), 'users', SERVEUR_A), { establishmentId: ESTAB_B }));
});

test('🔒 serveur A ne peut PAS s’attribuer des modules ou permissions', async () => {
  const userRef = doc(asUser(SERVEUR_A), 'users', SERVEUR_A);
  await assertFails(updateDoc(userRef, { modules: { hotel: true } }));
  await assertFails(updateDoc(userRef, { permissions: { manageUsers: true } }));
});

test('🔒 serveur A ne peut PAS réactiver ou désactiver son profil', async () => {
  await assertFails(updateDoc(doc(asUser(SERVEUR_A), 'users', SERVEUR_A), { isActive: false }));
});

test('✅ serveur A peut actualiser uniquement son token FCM', async () => {
  await assertSucceeds(updateDoc(doc(asUser(SERVEUR_A), 'users', SERVEUR_A), {
    fcmToken: 'new-token', lastTokenUpdate: new Date(),
  }));
});

test('🔒 une gérante ne peut pas créer directement un profil utilisateur racine', async () => {
  await assertFails(setDoc(doc(asUser(GERANTE_A), 'users', 'newUser'), {
    uid: 'newUser', role: 'serveur', establishmentId: ESTAB_A,
  }));
});

test('✅ une gérante peut modifier le rôle d’un membre de son établissement', async () => {
  await assertSucceeds(updateDoc(doc(asUser(GERANTE_A), 'users', SERVEUR_A), { role: 'comptable' }));
});

test('🔒 une gérante ne peut pas attribuer un rôle propriétaire', async () => {
  await assertFails(updateDoc(doc(asUser(GERANTE_A), 'users', SERVEUR_A), { role: 'proprietaire' }));
});

test('🔒 une gérante ne peut pas modifier son propre rôle', async () => {
  await assertFails(updateDoc(doc(asUser(GERANTE_A), 'users', GERANTE_A), { role: 'serveur' }));
});

test('🔒 un administrateur global ne peut pas modifier son propre rôle', async () => {
  await assertFails(updateDoc(doc(asUser(GLOBAL_ADMIN), 'users', GLOBAL_ADMIN), { role: 'super_admin' }));
});

test('🔒 une gérante ne peut pas modifier un rôle et des champs hors périmètre', async () => {
  await assertFails(updateDoc(doc(asUser(GERANTE_A), 'users', SERVEUR_A), {
    role: 'comptable', email: 'changed@example.com',
  }));
});

test('✅ le comptable valide la réception liée à une remise reçue', async () => {
  const db = asUser(COMPTABLE_A);
  const batch = writeBatch(db);
  batch.update(doc(db, 'establishments', ESTAB_A, 'serverHandovers', 'handover1'), {
    accountingTransferStatus: 'received', updatedAt: new Date(),
  });
  batch.update(doc(db, 'establishments', ESTAB_A, 'payments', 'payment1'), {
    handoverStatus: 'validated', updatedAt: new Date(),
  });
  await assertSucceeds(batch.commit());
});

test('🔒 le comptable ne peut pas valider un paiement hors réception comptable', async () => {
  await assertFails(updateDoc(
    doc(asUser(COMPTABLE_A), 'establishments', ESTAB_A, 'payments', 'payment1'),
    { handoverStatus: 'validated', updatedAt: new Date() },
  ));
});

test('🔒 le comptable ne peut PAS modifier le montant d’un paiement', async () => {
  await assertFails(updateDoc(
    doc(asUser(COMPTABLE_A), 'establishments', ESTAB_A, 'payments', 'payment1'),
    { amount: 1 },
  ));
});

test('🔒 propriétaire A ne peut PAS créer un établissement B', async () => {
  await assertFails(setDoc(
    doc(asUser(PROPRIETAIRE_A), 'establishments', ESTAB_B),
    { name: 'Tenant B', establishmentId: ESTAB_B },
  ));
});

test('✅ global_admin peut créer un établissement', async () => {
  await assertSucceeds(setDoc(
    doc(asUser(GLOBAL_ADMIN), 'establishments', 'estabC'),
    { name: 'Tenant C', establishmentId: 'estabC' },
  ));
});

test('✅ un serveur peut déclarer uniquement la remise de son paiement', async () => {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await updateDoc(doc(ctx.firestore(), 'establishments', ESTAB_A, 'payments', 'payment1'), {
      handoverStatus: 'pending', handoverId: null,
    });
  });
  const db = asUser(SERVEUR_A);
  const batch = writeBatch(db);
  batch.set(doc(db, 'establishments', ESTAB_A, 'serverHandovers', 'handover2'), {
    serveurId: SERVEUR_A, paymentIds: ['payment1'],
  });
  batch.update(doc(db, 'establishments', ESTAB_A, 'payments', 'payment1'), {
    handoverStatus: 'declared', handoverId: 'handover2',
    updatedAt: new Date(), pendingSync: false, syncError: false,
  });
  await assertSucceeds(batch.commit());
});

test('✅ une gérante peut valider la remise d’un paiement', async () => {
  const db = asUser(GERANTE_A);
  const batch = writeBatch(db);
  batch.update(doc(db, 'establishments', ESTAB_A, 'serverHandovers', 'handover1'), {
    status: 'validated', validatedPaymentIds: ['payment1'],
  });
  batch.update(doc(db, 'establishments', ESTAB_A, 'payments', 'payment1'), {
    handoverStatus: 'validated', updatedAt: new Date(),
    pendingSync: false, syncError: false,
  });
  await assertSucceeds(batch.commit());
});

test('✅ un propriétaire conserve la validation liée d’une remise', async () => {
  const db = asUser(PROPRIETAIRE_A);
  const batch = writeBatch(db);
  batch.update(doc(db, 'establishments', ESTAB_A, 'serverHandovers', 'handover1'), {
    status: 'validated', validatedPaymentIds: ['payment1'],
  });
  batch.update(doc(db, 'establishments', ESTAB_A, 'payments', 'payment1'), {
    handoverStatus: 'validated', updatedAt: new Date(),
    pendingSync: false, syncError: false,
  });
  await assertSucceeds(batch.commit());
});

test('✅ une gérante peut rejeter un paiement de remise', async () => {
  const db = asUser(GERANTE_A);
  const batch = writeBatch(db);
  batch.update(doc(db, 'establishments', ESTAB_A, 'serverHandovers', 'handover1'), {
    status: 'validated', rejectedPaymentIds: ['payment1'],
  });
  batch.update(doc(db, 'establishments', ESTAB_A, 'payments', 'payment1'), {
    handoverStatus: 'pending', handoverId: null, updatedAt: new Date(),
    pendingSync: false, syncError: false,
  });
  await assertSucceeds(batch.commit());
});

test('🔒 un serveur ne peut pas modifier arbitrairement un paiement', async () => {
  const paymentRef = doc(asUser(SERVEUR_A), 'establishments', ESTAB_A, 'payments', 'payment1');
  await assertFails(updateDoc(paymentRef, { amount: 1 }));
  await assertFails(updateDoc(paymentRef, { status: 'cancelled' }));
});
// ─────────── STOCK MODE (contrôle du stock des commandes) ───────────

async function seedEstablishmentWithStockMode(stockMode) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'establishments', ESTAB_A), {
      name: 'Estab A', stockMode, plan: 'standard',
    });
    await setDoc(doc(db, 'users', 'barmanA'), { role: 'barman', establishmentId: ESTAB_A });
  });
}

test('✅ global_admin peut modifier stockMode', async () => {
  await seedEstablishmentWithStockMode('strict');
  const ref = doc(asUser(GLOBAL_ADMIN), 'establishments', ESTAB_A);
  await assertSucceeds(updateDoc(ref, { stockMode: 'warningOnly' }));
});

test('🔒 serveur et barman ne peuvent PAS modifier stockMode', async () => {
  await seedEstablishmentWithStockMode('strict');
  for (const uid of [SERVEUR_A, 'barmanA']) {
    const ref = doc(asUser(uid), 'establishments', ESTAB_A);
    await assertFails(updateDoc(ref, { stockMode: 'disabled' }));
  }
});

test('🔒 propriétaire et gérante ne peuvent PAS modifier stockMode', async () => {
  await seedEstablishmentWithStockMode('strict');
  for (const uid of [PROPRIETAIRE_A, GERANTE_A]) {
    const ref = doc(asUser(uid), 'establishments', ESTAB_A);
    await assertFails(updateDoc(ref, { stockMode: 'disabled' }));
    // Ajouter le champ sur un établissement ancien est aussi un changement.
    await assertFails(setDoc(ref, { stockMode: 'disabled' }, { merge: true }));
  }
});

test('✅ propriétaire et gérante gardent la mise à jour des autres champs', async () => {
  await seedEstablishmentWithStockMode('strict');
  for (const uid of [PROPRIETAIRE_A, GERANTE_A]) {
    const ref = doc(asUser(uid), 'establishments', ESTAB_A);
    await assertSucceeds(updateDoc(ref, { name: `Renamed by ${uid}` }));
  }
});

// ─────────── PARAMÈTRES D'ÉTABLISSEMENT (4C) ───────────

const PLATFORM_FIELDS = {
  stockMode: 'disabled',
  modules: { restaurant: true, bar: true, hotel: true, stock: true, fiscalization: true },
  plan: 'enterprise',
  status: 'active',
  type: 'hotel',
  ownerUid: 'intrus',
  ifu: '9999999999999',
  createdAt: new Date(0),
};

async function seedFullEstablishments() {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    const base = {
      name: 'Estab', city: 'Cotonou', country: 'Benin', ifu: '1234567890123',
      ownerUid: PROPRIETAIRE_A, type: 'restaurant', plan: 'starter',
      status: 'suspended', stockMode: 'strict',
      modules: { restaurant: true, bar: false, hotel: false, stock: false },
      createdAt: new Date(1000),
    };
    await setDoc(doc(db, 'establishments', ESTAB_A), base);
    await setDoc(doc(db, 'establishments', ESTAB_B), base);
    await setDoc(doc(db, 'users', 'barmanA'), { role: 'barman', establishmentId: ESTAB_A });
    await setDoc(doc(db, 'users', 'superAdmin'), { role: 'super_admin', establishmentId: ESTAB_A });
  });
}

for (const [label, uid] of [['gérante', GERANTE_A], ['propriétaire', PROPRIETAIRE_A]]) {
  for (const [field, value] of Object.entries(PLATFORM_FIELDS)) {
    test(`🔒 ${label} ne peut PAS modifier ${field}`, async () => {
      await seedFullEstablishments();
      const ref = doc(asUser(uid), 'establishments', ESTAB_A);
      await assertFails(updateDoc(ref, { [field]: value }));
    });
  }

  test(`🔒 ${label} ne peut PAS s'activer un seul module (chemin imbriqué)`, async () => {
    await seedFullEstablishments();
    const ref = doc(asUser(uid), 'establishments', ESTAB_A);
    await assertFails(updateDoc(ref, { 'modules.stock': true }));
  });

  test(`🔒 ${label} ne peut PAS supprimer un champ plateforme par remplacement complet`, async () => {
    await seedFullEstablishments();
    const ref = doc(asUser(uid), 'establishments', ESTAB_A);
    // set() sans merge : modules, plan, status… disparaîtraient.
    await assertFails(setDoc(ref, { name: 'X', city: 'Y', country: 'Z' }));
  });

  test(`🔒 ${label} ne peut PAS ajouter un champ inconnu`, async () => {
    await seedFullEstablishments();
    const ref = doc(asUser(uid), 'establishments', ESTAB_A);
    await assertFails(updateDoc(ref, { billingOverride: true }));
  });

  test(`🔒 ${label} ne peut PAS glisser un champ interdit avec un champ autorisé`, async () => {
    await seedFullEstablishments();
    const ref = doc(asUser(uid), 'establishments', ESTAB_A);
    await assertFails(updateDoc(ref, { name: 'Nouveau nom', status: 'active' }));
  });

  test(`✅ ${label} peut modifier la fiche (name, city, country, updatedAt)`, async () => {
    await seedFullEstablishments();
    const ref = doc(asUser(uid), 'establishments', ESTAB_A);
    await assertSucceeds(updateDoc(ref, {
      name: 'Nouveau nom', city: 'Porto-Novo', country: 'Bénin', updatedAt: new Date(),
    }));
  });

  test(`🔒 ${label} ne peut PAS modifier la fiche d'un autre établissement`, async () => {
    await seedFullEstablishments();
    const ref = doc(asUser(uid), 'establishments', ESTAB_B);
    await assertFails(updateDoc(ref, { name: 'Piraté' }));
  });
}

test('🔒 serveur et barman ne peuvent modifier AUCUN champ de l’établissement', async () => {
  await seedFullEstablishments();
  for (const uid of [SERVEUR_A, 'barmanA']) {
    const ref = doc(asUser(uid), 'establishments', ESTAB_A);
    await assertFails(updateDoc(ref, { name: 'X' }));
    await assertFails(updateDoc(ref, { status: 'active' }));
    await assertFails(updateDoc(ref, { 'modules.stock': true }));
  }
});

test('✅ global_admin peut modifier tous les paramètres plateforme', async () => {
  await seedFullEstablishments();
  const ref = doc(asUser(GLOBAL_ADMIN), 'establishments', ESTAB_A);
  await assertSucceeds(updateDoc(ref, { ...PLATFORM_FIELDS, updatedAt: new Date() }));
  await assertSucceeds(updateDoc(ref, { 'modules.hotel': false }));
});

test('✅ global_admin peut enregistrer le formulaire complet (set merge)', async () => {
  await seedFullEstablishments();
  const ref = doc(asUser(GLOBAL_ADMIN), 'establishments', ESTAB_A);
  await assertSucceeds(setDoc(ref, {
    name: 'Estab', city: 'Cotonou', country: 'Benin', ifu: '1234567890123',
    ownerUid: PROPRIETAIRE_A, type: 'hotel_bar_restaurant', status: 'active',
    plan: 'premium', stockMode: 'warningOnly',
    modules: { restaurant: true, bar: true, hotel: true, stock: true },
    updatedAt: new Date(),
  }, { merge: true }));
});

test('ℹ️ super_admin (comportement actuel conservé) garde les droits plateforme', async () => {
  await seedFullEstablishments();
  const ref = doc(asUser('superAdmin'), 'establishments', ESTAB_B);
  await assertSucceeds(updateDoc(ref, { plan: 'premium' }));
});

// ─────────── FLOOR_MANAGER (5B) : moindre privilège ───────────

const FLOOR_MANAGER_A = 'floorManagerA';

async function seedFloorManager() {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'users', FLOOR_MANAGER_A), {
      uid: FLOOR_MANAGER_A, role: 'floor_manager', establishmentId: ESTAB_A,
      name: 'Floor', email: 'floor@example.com', isActive: true,
      modules: { restaurant: false, bar: false, hotel: false, stock: false, fiscalization: false },
    });
    await setDoc(doc(db, 'establishments', ESTAB_A), {
      name: 'Estab A', stockMode: 'strict', plan: 'standard', status: 'active',
      type: 'restaurant', modules: { restaurant: true },
    });
    await setDoc(doc(db, 'establishments', ESTAB_B), { name: 'Estab B' });
    await setDoc(doc(db, 'establishments', ESTAB_A, 'expenses', 'exp1'), { amount: 10 });
    await setDoc(doc(db, 'establishments', ESTAB_A, 'managerToAccountingTransfers', 't1'), { amount: 10 });
    await setDoc(doc(db, 'establishments', ESTAB_A, 'menuItems', 'm1'), { name: 'Riz' });
  });
}

test('✅ floor_manager lit son propre profil et met à jour son jeton FCM', async () => {
  await seedFloorManager();
  const ref = doc(asUser(FLOOR_MANAGER_A), 'users', FLOOR_MANAGER_A);
  await assertSucceeds(getDoc(ref));
  await assertSucceeds(updateDoc(ref, { fcmToken: 'tok', lastTokenUpdate: new Date() }));
});

test('✅ floor_manager lit le document de SON établissement (connexion, stockMode)', async () => {
  await seedFloorManager();
  await assertSucceeds(getDoc(doc(asUser(FLOOR_MANAGER_A), 'establishments', ESTAB_A)));
});

test('🔒 floor_manager ne peut PAS modifier son rôle, son établissement ni ses modules', async () => {
  await seedFloorManager();
  const ref = doc(asUser(FLOOR_MANAGER_A), 'users', FLOOR_MANAGER_A);
  await assertFails(updateDoc(ref, { role: 'gerante' }));
  await assertFails(updateDoc(ref, { establishmentId: ESTAB_B }));
  await assertFails(updateDoc(ref, { 'modules.restaurant': true }));
  await assertFails(updateDoc(ref, { isActive: true, name: 'X' }));
});

test('🔒 floor_manager ne peut PAS gérer les autres utilisateurs', async () => {
  await seedFloorManager();
  const db = asUser(FLOOR_MANAGER_A);
  await assertFails(getDoc(doc(db, 'users', SERVEUR_A)));
  await assertFails(updateDoc(doc(db, 'users', SERVEUR_A), { role: 'barman' }));
  await assertFails(setDoc(doc(db, 'users', 'nouveau'), { role: 'serveur', establishmentId: ESTAB_A }));
  await assertFails(deleteDoc(doc(db, 'users', SERVEUR_A)));
});

test('🔒 floor_manager ne peut PAS modifier les paramètres de l’établissement', async () => {
  await seedFloorManager();
  const ref = doc(asUser(FLOOR_MANAGER_A), 'establishments', ESTAB_A);
  for (const [field, value] of Object.entries({
    stockMode: 'disabled', modules: { stock: true }, plan: 'premium',
    status: 'suspended', type: 'hotel', name: 'X',
  })) {
    await assertFails(updateDoc(ref, { [field]: value }));
  }
});

test('🔒 floor_manager ne peut RIEN lire ni écrire dans un autre établissement', async () => {
  await seedFloorManager();
  const db = asUser(FLOOR_MANAGER_A);
  await assertFails(getDoc(doc(db, 'establishments', ESTAB_B)));
  await assertFails(getDoc(doc(db, 'establishments', ESTAB_B, 'orders', 'order1')));
  await assertFails(setDoc(doc(db, 'establishments', ESTAB_B, 'orders', 'x'), { total: 1, createdBy: FLOOR_MANAGER_A }));
  await assertFails(updateDoc(doc(db, 'establishments', ESTAB_B), { name: 'X' }));
});

test('🔒 floor_manager n’a aucun accès comptable ni financier', async () => {
  await seedFloorManager();
  const db = asUser(FLOOR_MANAGER_A);
  for (const path of [
    ['payments', 'payment1'],
    ['serverHandovers', 'handover1'],
    ['managerToAccountingTransfers', 't1'],
    ['accountClosures', 'clo1'],
    ['expenses', 'exp1'],
  ]) {
    await assertFails(getDoc(doc(db, 'establishments', ESTAB_A, ...path)));
  }
});

test('🔒 floor_manager n’agit pas au nom d’un serveur (commandes, paiements, remises)', async () => {
  await seedFloorManager();
  const db = asUser(FLOOR_MANAGER_A);
  await assertFails(getDoc(doc(db, 'establishments', ESTAB_A, 'orders', 'order1')));
  await assertFails(setDoc(doc(db, 'establishments', ESTAB_A, 'orders', 'o2'), { total: 1 }));
  await assertFails(setDoc(doc(db, 'establishments', ESTAB_A, 'payments', 'p2'), { amount: 1 }));
  await assertFails(updateDoc(doc(db, 'establishments', ESTAB_A, 'payments', 'payment1'), {
    handoverStatus: 'validated',
  }));
  await assertFails(setDoc(doc(db, 'establishments', ESTAB_A, 'serverHandovers', 'h2'), {
    serveurId: SERVEUR_A, paymentIds: [],
  }));
  await assertFails(getDoc(doc(db, 'establishments', ESTAB_A, 'serverNotifications', 'notif1')));
});

test('🔒 floor_manager n’hérite pas du filet de lecture du tenant', async () => {
  await seedFloorManager();
  const db = asUser(FLOOR_MANAGER_A);
  await assertFails(getDoc(doc(db, 'establishments', ESTAB_A, 'menuItems', 'm1')));
  await assertFails(getDoc(doc(db, 'establishments', ESTAB_A, 'sousCollectionInconnue', 'x')));
});

test('✅ non-régression : serveur et gérante gardent leurs lectures du tenant', async () => {
  await seedFloorManager();
  await assertSucceeds(getDoc(doc(asUser(SERVEUR_A), 'establishments', ESTAB_A, 'orders', 'order1')));
  await assertSucceeds(getDoc(doc(asUser(SERVEUR_A), 'establishments', ESTAB_A, 'menuItems', 'm1')));
  await assertSucceeds(setDoc(doc(asUser(SERVEUR_A), 'establishments', ESTAB_A, 'orders', 'o3'), { total: 5, createdBy: SERVEUR_A }));
  await assertSucceeds(getDoc(doc(asUser(GERANTE_A), 'establishments', ESTAB_A, 'expenses', 'exp1')));
  await assertSucceeds(getDoc(doc(asUser(GERANTE_A), 'establishments', ESTAB_A, 'payments', 'payment1')));
  await assertSucceeds(updateDoc(doc(asUser(GERANTE_A), 'establishments', ESTAB_A), { name: 'Renommé' }));
});

// ─────────── 5C : plus de filet de lecture « tout le tenant » ───────────

const ROLE_USERS = {
  serveur: SERVEUR_A,
  barman: 'barmanA',
  chef_cuisine: 'chefA',
  floor_manager: 'floorManagerA',
  receptionniste: 'receptionA',
  service_hygiene: 'hygieneA',
  hygiene: 'legacyHygieneA',
  majordhomme: 'majordomeA',
  comptable: COMPTABLE_A,
  gerante: GERANTE_A,
  proprietaire: PROPRIETAIRE_A,
};

const ACCOUNTING = [
  'accountClosures', 'expenses', 'accountOpeningBalances', 'managerToAccountingTransfers',
];

async function seedSensitive() {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    for (const [role, uid] of Object.entries(ROLE_USERS)) {
      await setDoc(doc(db, 'users', uid), { role, establishmentId: ESTAB_A });
    }
    await setDoc(doc(db, 'users', 'comptableB'), { role: 'comptable', establishmentId: ESTAB_B });
    await setDoc(doc(db, 'users', 'geranteB'), { role: 'gerante', establishmentId: ESTAB_B });
    await setDoc(doc(db, 'users', 'hygieneB'), { role: 'service_hygiene', establishmentId: ESTAB_B });
    for (const estab of [ESTAB_A, ESTAB_B]) {
      for (const col of ACCOUNTING) {
        await setDoc(doc(db, 'establishments', estab, col, 'x'), {
          amount: 1, status: 'pending', createdAt: new Date(),
        });
      }
      await setDoc(doc(db, 'establishments', estab, 'hygiene_daily_entries', 'h1'), { preparedAt: new Date() });
      await setDoc(doc(db, 'establishments', estab, 'hygiene_daily_entries', 'h1', 'items', 'i1'), { qty: 1 });
    }
    await setDoc(doc(db, 'establishments', ESTAB_A, 'menuItems', 'm1'), { name: 'Riz' });
    await setDoc(doc(db, 'establishments', ESTAB_A, 'orders', 'order1', 'items', 'it1'), { name: 'Riz' });
    await setDoc(doc(db, 'establishments', ESTAB_A, 'clients', 'c1'), { name: 'Client' });
    await setDoc(doc(db, 'establishments', ESTAB_A, 'rooms', 'r1'), { number: '101' });
    await setDoc(doc(db, 'establishments', ESTAB_A, 'stock_items', 's1'), { store: 'restaurant' });
    await setDoc(doc(db, 'establishments', ESTAB_A, 'certilink_config', 'config'), { enabled: true });
    for (const store of ['restaurant', 'bar', 'hotel']) {
      await setDoc(doc(db, 'establishments', ESTAB_A, 'store_stocks', `st_${store}`), { store, itemId: 'i', quantity: 1 });
      await setDoc(doc(db, 'establishments', ESTAB_A, 'stock_movements', `mv_${store}`), { store });
      await setDoc(doc(db, 'establishments', ESTAB_A, 'stock_requests', `rq_${store}`), { store, status: 'delivered' });
    }
    await setDoc(doc(db, 'establishments', ESTAB_A, 'roomInvoices', 'inv1'), { status: 'paid' });
    await setDoc(doc(db, 'establishments', ESTAB_A, 'serverNotifications', 'notifCompta'), {
      serveurId: COMPTABLE_A, isRead: false, createdAt: new Date(),
    });
    await setDoc(doc(db, 'establishments', ESTAB_A, 'departmentNotifications', 'd1'), { v: 1 });
  });
}

const read = (uid, ...path) => getDoc(doc(asUser(uid), 'establishments', ...path));

// ── Refus comptables ──
for (const role of ['serveur', 'barman', 'chef_cuisine', 'floor_manager', 'receptionniste', 'service_hygiene', 'majordhomme']) {
  test(`🔒 ${role} ne lit PAS la comptabilité (${ACCOUNTING.join(', ')})`, async () => {
    await seedSensitive();
    for (const col of ACCOUNTING) {
      await assertFails(read(ROLE_USERS[role], ESTAB_A, col, 'x'));
    }
  });
}

// ── Accès comptables légitimes ──
for (const role of ['comptable', 'gerante', 'proprietaire']) {
  test(`✅ ${role} lit la comptabilité de SON établissement`, async () => {
    await seedSensitive();
    for (const col of ACCOUNTING) {
      await assertSucceeds(read(ROLE_USERS[role], ESTAB_A, col, 'x'));
    }
  });
}

test('✅ comptable : requêtes réelles de l’app (dépenses, soldes, versements, factures, paiements)', async () => {
  await seedSensitive();
  const db = asUser(COMPTABLE_A);
  const col = (name) => collection(db, 'establishments', ESTAB_A, name);
  await assertSucceeds(getDocs(query(col('expenses'), orderBy('createdAt', 'desc'))));
  await assertSucceeds(getDocs(query(col('accountOpeningBalances'))));
  await assertSucceeds(getDocs(query(col('managerToAccountingTransfers'), where('status', '==', 'pending'))));
  await assertSucceeds(getDocs(query(col('roomInvoices'), where('status', '==', 'paid'))));
  await assertSucceeds(getDocs(query(col('payments'), where('handoverStatus', '==', 'pending'))));
  await assertSucceeds(read(COMPTABLE_A, ESTAB_A, 'serverHandovers', 'handover1'));
});

test('✅ global_admin conserve l’accès comptable (administration plateforme)', async () => {
  await seedSensitive();
  for (const col of ACCOUNTING) {
    await assertSucceeds(read(GLOBAL_ADMIN, ESTAB_A, col, 'x'));
  }
});

// ── Isolation ──
test('🔒 isolation : aucun rôle ne lit les données sensibles d’un autre établissement', async () => {
  await seedSensitive();
  for (const uid of [COMPTABLE_A, GERANTE_A, PROPRIETAIRE_A, 'hygieneA']) {
    for (const col of ACCOUNTING) await assertFails(read(uid, ESTAB_B, col, 'x'));
    await assertFails(read(uid, ESTAB_B, 'hygiene_daily_entries', 'h1'));
  }
  for (const uid of ['comptableB', 'geranteB', 'hygieneB']) {
    for (const col of ACCOUNTING) await assertFails(read(uid, ESTAB_A, col, 'x'));
    await assertFails(read(uid, ESTAB_A, 'hygiene_daily_entries', 'h1'));
  }
});

// ── Hygiène ──
for (const role of ['service_hygiene', 'hygiene', 'majordhomme', 'gerante', 'proprietaire']) {
  test(`✅ ${role} lit hygiene_daily_entries (et ses items)`, async () => {
    await seedSensitive();
    await assertSucceeds(read(ROLE_USERS[role], ESTAB_A, 'hygiene_daily_entries', 'h1'));
    await assertSucceeds(read(ROLE_USERS[role], ESTAB_A, 'hygiene_daily_entries', 'h1', 'items', 'i1'));
  });
}
for (const role of ['serveur', 'barman', 'chef_cuisine', 'comptable', 'receptionniste', 'floor_manager']) {
  test(`🔒 ${role} ne lit PAS hygiene_daily_entries`, async () => {
    await seedSensitive();
    await assertFails(read(ROLE_USERS[role], ESTAB_A, 'hygiene_daily_entries', 'h1'));
    await assertFails(read(ROLE_USERS[role], ESTAB_A, 'hygiene_daily_entries', 'h1', 'items', 'i1'));
  });
}

// ── Collections sans règle propre : plus lisibles par le client ──
test('🔒 une sous-collection sans règle propre n’est plus lisible (departmentNotifications)', async () => {
  await seedSensitive();
  for (const uid of [SERVEUR_A, GERANTE_A, COMPTABLE_A]) {
    await assertFails(read(uid, ESTAB_A, 'departmentNotifications', 'd1'));
  }
});

// ── Non-régression opérationnelle (requêtes réelles de l’app) ──
test('✅ serveur : commandes, menu, clients, stock, paiements et notifications restent accessibles', async () => {
  await seedSensitive();
  const db = asUser(SERVEUR_A);
  const col = (name) => collection(db, 'establishments', ESTAB_A, name);
  await assertSucceeds(read(SERVEUR_A, ESTAB_A, 'orders', 'order1'));
  await assertSucceeds(read(SERVEUR_A, ESTAB_A, 'orders', 'order1', 'items', 'it1'));
  await assertSucceeds(getDocs(col('menuItems')));
  await assertSucceeds(getDocs(col('clients')));
  await assertSucceeds(read(SERVEUR_A, ESTAB_A, 'certilink_config', 'config'));
  await assertSucceeds(getDocs(query(col('store_stocks'), where('store', '==', 'restaurant'), where('itemId', '==', 'i'))));
  await assertSucceeds(getDocs(query(col('payments'), where('receivedBy', '==', SERVEUR_A))));
  await assertSucceeds(getDocs(query(col('serverHandovers'), where('serveurId', '==', SERVEUR_A))));
  await assertSucceeds(getDocs(query(col('serverNotifications'), where('serveurId', '==', SERVEUR_A))));
  await assertSucceeds(setDoc(doc(db, 'establishments', ESTAB_A, 'orders', 'o5c'), { total: 1, createdBy: SERVEUR_A }));
});

test('✅ chef, barman, majordhomme, hygiène : stocks de leur magasin et historiques', async () => {
  await seedSensitive();
  const cases = [
    ['chefA', 'restaurant'], ['barmanA', 'bar'], ['majordomeA', 'hotel'], ['hygieneA', 'hotel'],
  ];
  for (const [uid, store] of cases) {
    const col = (name) => collection(asUser(uid), 'establishments', ESTAB_A, name);
    await assertSucceeds(getDocs(query(col('store_stocks'), where('store', '==', store))));
    await assertSucceeds(getDocs(query(col('stock_movements'), where('store', '==', store))));
    await assertSucceeds(getDocs(query(col('stock_requests'), where('store', '==', store), where('status', '==', 'delivered'))));
  }
  await assertSucceeds(getDocs(collection(asUser('hygieneA'), 'establishments', ESTAB_A, 'rooms')));
  await assertSucceeds(getDocs(collection(asUser('chefA'), 'establishments', ESTAB_A, 'stock_items')));
});

test('✅ gérante : stocks tous magasins, demandes, factures chambres', async () => {
  await seedSensitive();
  const col = (name) => collection(asUser(GERANTE_A), 'establishments', ESTAB_A, name);
  await assertSucceeds(getDocs(query(col('store_stocks'), where('store', 'in', ['restaurant', 'bar', 'hotel']))));
  await assertSucceeds(getDocs(query(col('store_stocks'), where('itemId', '==', 'i'))));
  await assertSucceeds(getDocs(col('stock_requests')));
  await assertSucceeds(getDocs(query(col('roomInvoices'), where('status', '==', 'paid'))));
});

test('✅ tout rôle écoute SES notifications à la connexion (écoute AuthService)', async () => {
  await seedSensitive();
  for (const role of ['comptable', 'receptionniste', 'service_hygiene', 'majordhomme', 'barman', 'chef_cuisine', 'gerante']) {
    const uid = ROLE_USERS[role];
    const col = collection(asUser(uid), 'establishments', ESTAB_A, 'serverNotifications');
    await assertSucceeds(getDocs(query(col, where('serveurId', '==', uid), where('isRead', '==', false))));
  }
});

test('🔒 un rôle non opérationnel ne lit pas les notifications des autres', async () => {
  await seedSensitive();
  for (const role of ['comptable', 'receptionniste', 'service_hygiene', 'majordhomme', 'floor_manager']) {
    await assertFails(read(ROLE_USERS[role], ESTAB_A, 'serverNotifications', 'notif1'));
  }
  await assertSucceeds(read(COMPTABLE_A, ESTAB_A, 'serverNotifications', 'notifCompta'));
});

// ─────────── 6B : SERVICES (SHIFTS) ───────────

const FM_A = 'fmA';
const FM_A2 = 'fmA2';
const FM_B = 'fmB';
const FM_OFF = 'fmOff';
const SRV_A1 = 'srvA1';
const SRV_A2 = 'srvA2';
const SRV_A3 = 'srvA3';
const SRV_B = 'srvB';
const T_START = new Date('2026-09-30T18:00:00Z');
const T_END = new Date('2026-09-30T23:00:00Z');

async function seedShiftWorld() {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    const users = [
      [FM_A, 'floor_manager', ESTAB_A, true],
      [FM_A2, 'floor_manager', ESTAB_A, true],
      [FM_B, 'floor_manager', ESTAB_B, true],
      [FM_OFF, 'floor_manager', ESTAB_A, false],
      [SRV_A1, 'serveur', ESTAB_A, true],
      [SRV_A2, 'serveur', ESTAB_A, true],
      [SRV_A3, 'serveur', ESTAB_A, true],
      [SRV_B, 'serveur', ESTAB_B, true],
      ['barmanA', 'barman', ESTAB_A, true],
      ['chefA', 'chef_cuisine', ESTAB_A, true],
      ['receptionA', 'receptionniste', ESTAB_A, true],
      ['geranteB', 'gerante', ESTAB_B, true],
    ];
    for (const [uid, role, establishmentId, isActive] of users) {
      await setDoc(doc(db, 'users', uid), {
        role, establishmentId, isActive, name: uid, email: `${uid}@x.test`,
      });
    }
  });
}

const shiftRef = (db, e, id) => doc(db, 'establishments', e, 'shifts', id);
const participantRef = (db, e, id, s) => doc(db, 'establishments', e, 'shifts', id, 'participants', s);
const fmPointerRef = (db, e, fm) => doc(db, 'establishments', e, 'floorManagerCurrentShift', fm);
const serverPointerRef = (db, e, s) => doc(db, 'establishments', e, 'serverCurrentShift', s);

function shiftData(e, fm, servers, createdBy, extra = {}) {
  return {
    establishmentId: e, floorManagerId: fm, floorManagerName: fm,
    startsAt: T_START, endsAt: T_END, status: 'planned', serverIds: servers,
    createdAt: serverTimestamp(), createdBy, updatedAt: serverTimestamp(),
    ...extra,
  };
}

function participantData(e, id, s, by, active = true) {
  return {
    shiftId: id, establishmentId: e, serverId: s, serverName: s,
    assignedAt: serverTimestamp(), assignedBy: by, activeInShift: active,
    removedAt: null, removedBy: null,
  };
}

// Même lot que ShiftService.createShift.
function createShiftBatch(uid, e, id, fm, servers, extra = {}) {
  const db = asUser(uid);
  const batch = writeBatch(db);
  batch.set(shiftRef(db, e, id), shiftData(e, fm, servers, uid, extra));
  for (const s of servers) batch.set(participantRef(db, e, id, s), participantData(e, id, s, uid));
  return batch.commit();
}

// Même lot que ShiftService.openShift.
function openShiftBatch(uid, e, id, fm, servers, { withFmPointer = true, serverPointers = servers } = {}) {
  const db = asUser(uid);
  const batch = writeBatch(db);
  batch.update(shiftRef(db, e, id), {
    status: 'open', openedAt: serverTimestamp(), openedBy: uid, updatedAt: serverTimestamp(),
  });
  if (withFmPointer) {
    batch.set(fmPointerRef(db, e, fm), {
      floorManagerId: fm, openShiftId: id, updatedAt: serverTimestamp(), updatedBy: uid,
    });
  }
  for (const s of serverPointers) {
    batch.set(serverPointerRef(db, e, s), {
      serverId: s, openShiftId: id, floorManagerId: fm, updatedAt: serverTimestamp(), updatedBy: uid,
    });
  }
  return batch.commit();
}

function closeShift(uid, e, id) {
  return updateDoc(shiftRef(asUser(uid), e, id), {
    status: 'closed', closedAt: serverTimestamp(), closedBy: uid, updatedAt: serverTimestamp(),
  });
}

async function openShiftAsAdmin(id, fm, servers, e = ESTAB_A) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(shiftRef(db, e, id), { ...shiftData(e, fm, servers, GERANTE_A), status: 'open', createdAt: new Date(), updatedAt: new Date() });
    for (const s of servers) {
      await setDoc(participantRef(db, e, id, s), { ...participantData(e, id, s, GERANTE_A), assignedAt: new Date() });
      await setDoc(serverPointerRef(db, e, s), { serverId: s, openShiftId: id, floorManagerId: fm, updatedAt: new Date(), updatedBy: GERANTE_A });
    }
    await setDoc(fmPointerRef(db, e, fm), { floorManagerId: fm, openShiftId: id, updatedAt: new Date(), updatedBy: GERANTE_A });
  });
}

// ── Création ──
test('✅ gérante crée un service valide (service + participations)', async () => {
  await seedShiftWorld();
  await assertSucceeds(createShiftBatch(GERANTE_A, ESTAB_A, 'sh1', FM_A, [SRV_A1, SRV_A2]));
});

test('✅ propriétaire crée un service valide', async () => {
  await seedShiftWorld();
  await assertSucceeds(createShiftBatch(PROPRIETAIRE_A, ESTAB_A, 'sh1', FM_A, [SRV_A1]));
});

test('🔒 refus d’un Floor Manager d’un autre établissement, d’un autre rôle ou inactif', async () => {
  await seedShiftWorld();
  await assertFails(createShiftBatch(GERANTE_A, ESTAB_A, 'sh1', FM_B, [SRV_A1]));
  await assertFails(createShiftBatch(GERANTE_A, ESTAB_A, 'sh2', SRV_A2, [SRV_A1]));
  await assertFails(createShiftBatch(GERANTE_A, ESTAB_A, 'sh3', FM_OFF, [SRV_A1]));
});

test('🔒 refus d’un serveur d’un autre établissement ou d’un autre rôle', async () => {
  await seedShiftWorld();
  await assertFails(createShiftBatch(GERANTE_A, ESTAB_A, 'sh1', FM_A, [SRV_B]));
  await assertFails(createShiftBatch(GERANTE_A, ESTAB_A, 'sh2', FM_A, ['barmanA']));
});

test('🔒 dates incohérentes, ouverture directe, trop de serveurs, FM parmi ses serveurs', async () => {
  await seedShiftWorld();
  await assertFails(createShiftBatch(GERANTE_A, ESTAB_A, 'sh1', FM_A, [SRV_A1], { endsAt: T_START }));
  await assertFails(createShiftBatch(GERANTE_A, ESTAB_A, 'sh2', FM_A, [SRV_A1], { endsAt: new Date('2026-09-30T17:00:00Z') }));
  await assertFails(createShiftBatch(GERANTE_A, ESTAB_A, 'sh3', FM_A, [SRV_A1], { status: 'open' }));
  const thirteen = Array.from({ length: 13 }, (_, i) => `x${i}`);
  await assertFails(setDoc(shiftRef(asUser(GERANTE_A), ESTAB_A, 'sh4'), shiftData(ESTAB_A, FM_A, thirteen, GERANTE_A)));
  await assertFails(createShiftBatch(GERANTE_A, ESTAB_A, 'sh5', FM_A, [FM_A]));
});

// ── Ouverture / un seul service ouvert par Floor Manager ──
test('✅ ouverture avec pointeurs ; 🔒 ouverture sans pointeur du Floor Manager', async () => {
  await seedShiftWorld();
  await createShiftBatch(GERANTE_A, ESTAB_A, 'sh1', FM_A, [SRV_A1]);
  await assertFails(openShiftBatch(GERANTE_A, ESTAB_A, 'sh1', FM_A, [SRV_A1], { withFmPointer: false }));
  await assertSucceeds(openShiftBatch(GERANTE_A, ESTAB_A, 'sh1', FM_A, [SRV_A1]));
});

test('🔒 un Floor Manager ne peut pas avoir deux services ouverts simultanément', async () => {
  await seedShiftWorld();
  await createShiftBatch(GERANTE_A, ESTAB_A, 'sh1', FM_A, [SRV_A1]);
  await openShiftBatch(GERANTE_A, ESTAB_A, 'sh1', FM_A, [SRV_A1]);
  await createShiftBatch(GERANTE_A, ESTAB_A, 'sh2', FM_A, [SRV_A2]);
  await assertFails(openShiftBatch(GERANTE_A, ESTAB_A, 'sh2', FM_A, [SRV_A2]));
  // Après clôture du premier, le second peut ouvrir.
  await assertSucceeds(closeShift(GERANTE_A, ESTAB_A, 'sh1'));
  await assertSucceeds(openShiftBatch(GERANTE_A, ESTAB_A, 'sh2', FM_A, [SRV_A2]));
});

test('🔒 un serveur ne peut pas être présent dans deux services ouverts', async () => {
  await seedShiftWorld();
  await createShiftBatch(GERANTE_A, ESTAB_A, 'sh1', FM_A, [SRV_A1]);
  await openShiftBatch(GERANTE_A, ESTAB_A, 'sh1', FM_A, [SRV_A1]);
  await createShiftBatch(GERANTE_A, ESTAB_A, 'sh2', FM_A2, [SRV_A1]);
  await assertFails(openShiftBatch(GERANTE_A, ESTAB_A, 'sh2', FM_A2, [SRV_A1]));
  // Contournement du service (pointeur du serveur non posé) : le second
  // Floor Manager n'obtient AUCUN accès au serveur.
  await assertSucceeds(openShiftBatch(GERANTE_A, ESTAB_A, 'sh2', FM_A2, [SRV_A1], { serverPointers: [] }));
  await assertFails(getDoc(doc(asUser(FM_A2), 'users', SRV_A1)));
  await assertSucceeds(getDoc(doc(asUser(FM_A), 'users', SRV_A1)));
});

// ── Service clôturé ──
test('🔒 un service clôturé refuse les nouvelles affectations ; ✅ après réouverture explicite', async () => {
  await seedShiftWorld();
  await createShiftBatch(GERANTE_A, ESTAB_A, 'sh1', FM_A, [SRV_A1]);
  await openShiftBatch(GERANTE_A, ESTAB_A, 'sh1', FM_A, [SRV_A1]);
  await closeShift(GERANTE_A, ESTAB_A, 'sh1');

  const addServer = (uid) => {
    const db = asUser(uid);
    const batch = writeBatch(db);
    batch.update(shiftRef(db, ESTAB_A, 'sh1'), { serverIds: [SRV_A1, SRV_A2], updatedAt: serverTimestamp() });
    batch.set(participantRef(db, ESTAB_A, 'sh1', SRV_A2), participantData(ESTAB_A, 'sh1', SRV_A2, uid));
    return batch.commit();
  };
  await assertFails(addServer(GERANTE_A));
  await assertSucceeds(openShiftBatch(GERANTE_A, ESTAB_A, 'sh1', FM_A, [SRV_A1]));
  await assertSucceeds(addServer(GERANTE_A));
});

test('✅ clôture possible même si le compte du Floor Manager a été désactivé', async () => {
  await seedShiftWorld();
  await createShiftBatch(GERANTE_A, ESTAB_A, 'sh1', FM_A, [SRV_A1]);
  await openShiftBatch(GERANTE_A, ESTAB_A, 'sh1', FM_A, [SRV_A1]);
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await updateDoc(doc(ctx.firestore(), 'users', FM_A), { isActive: false });
  });
  await assertSucceeds(closeShift(GERANTE_A, ESTAB_A, 'sh1'));
});

test('✅ 12 serveurs ouverts d’un coup restent sous la limite d’accès des règles', async () => {
  await seedShiftWorld();
  const servers = Array.from({ length: 12 }, (_, i) => `bulk${i}`);
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    for (const [i, s] of servers.entries()) {
      await setDoc(doc(db, 'users', s), { role: 'serveur', establishmentId: ESTAB_A, isActive: true });
      // Chaque serveur pointe vers un ancien service clôturé DIFFÉRENT :
      // cas le plus coûteux en lectures pour les règles.
      await setDoc(shiftRef(db, ESTAB_A, `old${i}`), { ...shiftData(ESTAB_A, FM_A2, [s], GERANTE_A), status: 'closed', createdAt: new Date(), updatedAt: new Date() });
      await setDoc(serverPointerRef(db, ESTAB_A, s), { serverId: s, openShiftId: `old${i}`, floorManagerId: FM_A2, updatedAt: new Date(), updatedBy: GERANTE_A });
    }
  });
  await assertSucceeds(createShiftBatch(GERANTE_A, ESTAB_A, 'big', FM_A, servers));
  await assertSucceeds(openShiftBatch(GERANTE_A, ESTAB_A, 'big', FM_A, servers));
});

// ── Lectures du Floor Manager ──
test('✅ Floor Manager : son service, ses participations, ses serveurs présents', async () => {
  await seedShiftWorld();
  await openShiftAsAdmin('sh1', FM_A, [SRV_A1, SRV_A2]);
  const db = asUser(FM_A);
  await assertSucceeds(getDoc(fmPointerRef(db, ESTAB_A, FM_A)));
  await assertSucceeds(getDoc(shiftRef(db, ESTAB_A, 'sh1')));
  await assertSucceeds(getDocs(query(
    collection(db, 'establishments', ESTAB_A, 'shifts', 'sh1', 'participants'),
    where('activeInShift', '==', true),
  )));
  await assertSucceeds(getDoc(serverPointerRef(db, ESTAB_A, SRV_A1)));
  await assertSucceeds(getDoc(doc(db, 'users', SRV_A1)));
  await assertSucceeds(getDoc(doc(db, 'users', SRV_A2)));
});

test('🔒 Floor Manager : pas de profil d’un serveur actif mais hors de son service', async () => {
  await seedShiftWorld();
  await openShiftAsAdmin('sh1', FM_A, [SRV_A1]);
  const db = asUser(FM_A);
  await assertFails(getDoc(doc(db, 'users', SRV_A3)));
  await assertFails(getDoc(doc(db, 'users', GERANTE_A)));
  await assertFails(getDocs(query(collection(db, 'users'), where('establishmentId', '==', ESTAB_A))));
});

test('🔒 Floor Manager A ne voit pas le service ni les serveurs du Floor Manager B', async () => {
  await seedShiftWorld();
  await openShiftAsAdmin('shA', FM_A, [SRV_A1]);
  await openShiftAsAdmin('shA2', FM_A2, [SRV_A2]);
  const db = asUser(FM_A);
  await assertFails(getDoc(shiftRef(db, ESTAB_A, 'shA2')));
  await assertFails(getDocs(collection(db, 'establishments', ESTAB_A, 'shifts', 'shA2', 'participants')));
  await assertFails(getDoc(fmPointerRef(db, ESTAB_A, FM_A2)));
  await assertFails(getDoc(serverPointerRef(db, ESTAB_A, SRV_A2)));
  await assertFails(getDoc(doc(db, 'users', SRV_A2)));
  await assertFails(getDocs(collection(db, 'establishments', ESTAB_A, 'shifts')));
});

test('🔒 service clôturé : le Floor Manager ne lit plus les profils de ses anciens serveurs', async () => {
  await seedShiftWorld();
  await openShiftAsAdmin('sh1', FM_A, [SRV_A1]);
  await assertSucceeds(getDoc(doc(asUser(FM_A), 'users', SRV_A1)));
  await closeShift(GERANTE_A, ESTAB_A, 'sh1');
  await assertFails(getDoc(doc(asUser(FM_A), 'users', SRV_A1)));
});

test('🔒 Floor Manager incapable de créer son service ou de s’ajouter un serveur', async () => {
  await seedShiftWorld();
  await openShiftAsAdmin('sh1', FM_A, [SRV_A1]);
  const db = asUser(FM_A);
  await assertFails(createShiftBatch(FM_A, ESTAB_A, 'mine', FM_A, [SRV_A3]));
  await assertFails(updateDoc(shiftRef(db, ESTAB_A, 'sh1'), { serverIds: [SRV_A1, SRV_A3] }));
  await assertFails(setDoc(participantRef(db, ESTAB_A, 'sh1', SRV_A3), participantData(ESTAB_A, 'sh1', SRV_A3, FM_A)));
  await assertFails(setDoc(serverPointerRef(db, ESTAB_A, SRV_A3), {
    serverId: SRV_A3, openShiftId: 'sh1', floorManagerId: FM_A, updatedAt: serverTimestamp(), updatedBy: FM_A,
  }));
  await assertFails(closeShift(FM_A, ESTAB_A, 'sh1'));
});

// ── Serveur ──
test('🔒 un serveur ne peut pas créer ni modifier un service ; ✅ il lit sa propre affectation', async () => {
  await seedShiftWorld();
  await openShiftAsAdmin('sh1', FM_A, [SRV_A1]);
  const db = asUser(SRV_A1);
  await assertFails(createShiftBatch(SRV_A1, ESTAB_A, 'x', FM_A, [SRV_A1]));
  await assertFails(updateDoc(shiftRef(db, ESTAB_A, 'sh1'), { endsAt: new Date('2026-10-01T02:00:00Z') }));
  await assertFails(closeShift(SRV_A1, ESTAB_A, 'sh1'));
  await assertFails(updateDoc(participantRef(db, ESTAB_A, 'sh1', SRV_A1), { activeInShift: false }));
  await assertSucceeds(getDoc(participantRef(db, ESTAB_A, 'sh1', SRV_A1)));
  await assertSucceeds(getDoc(serverPointerRef(db, ESTAB_A, SRV_A1)));
  await assertSucceeds(getDocs(query(
    collection(db, 'establishments', ESTAB_A, 'shifts'),
    where('serverIds', 'array-contains', SRV_A1),
  )));
});

test('🔒 un serveur ne lit pas l’affectation des autres', async () => {
  await seedShiftWorld();
  await openShiftAsAdmin('sh1', FM_A, [SRV_A1, SRV_A2]);
  const db = asUser(SRV_A3);
  await assertFails(getDoc(participantRef(db, ESTAB_A, 'sh1', SRV_A1)));
  await assertFails(getDoc(shiftRef(db, ESTAB_A, 'sh1')));
  await assertFails(getDoc(serverPointerRef(db, ESTAB_A, SRV_A1)));
});

// ── Isolation et autres rôles ──
test('🔒 isolation multi-tenant des services', async () => {
  await seedShiftWorld();
  await openShiftAsAdmin('sh1', FM_A, [SRV_A1]);
  for (const uid of ['geranteB', FM_B, SRV_B]) {
    const db = asUser(uid);
    await assertFails(getDoc(shiftRef(db, ESTAB_A, 'sh1')));
    await assertFails(getDoc(participantRef(db, ESTAB_A, 'sh1', SRV_A1)));
    await assertFails(getDoc(fmPointerRef(db, ESTAB_A, FM_A)));
    await assertFails(getDoc(doc(db, 'users', SRV_A1)));
  }
  await assertFails(createShiftBatch('geranteB', ESTAB_A, 'sh9', FM_A, [SRV_A1]));
  await assertFails(closeShift('geranteB', ESTAB_A, 'sh1'));
  // Une gérante B ne peut pas non plus affecter du personnel de A chez elle.
  await assertFails(createShiftBatch('geranteB', ESTAB_B, 'shB', FM_A, [SRV_B]));
  await assertFails(createShiftBatch('geranteB', ESTAB_B, 'shB2', FM_B, [SRV_A1]));
  await assertSucceeds(createShiftBatch('geranteB', ESTAB_B, 'shB3', FM_B, [SRV_B]));
});

test('🔒 barman, chef, réceptionniste, comptable ne voient pas les services', async () => {
  await seedShiftWorld();
  await openShiftAsAdmin('sh1', FM_A, [SRV_A1]);
  for (const uid of ['barmanA', 'chefA', 'receptionA', COMPTABLE_A]) {
    const db = asUser(uid);
    await assertFails(getDoc(shiftRef(db, ESTAB_A, 'sh1')));
    await assertFails(getDocs(collection(db, 'establishments', ESTAB_A, 'shifts')));
    await assertFails(createShiftBatch(uid, ESTAB_A, 'x', FM_A, [SRV_A2]));
  }
});

test('✅ gérante : liste des services et du personnel (requêtes réelles de l’app)', async () => {
  await seedShiftWorld();
  await openShiftAsAdmin('sh1', FM_A, [SRV_A1]);
  const db = asUser(GERANTE_A);
  await assertSucceeds(getDocs(query(collection(db, 'establishments', ESTAB_A, 'shifts'), orderBy('startsAt', 'desc'))));
  await assertSucceeds(getDocs(query(collection(db, 'users'), where('establishmentId', '==', ESTAB_A))));
});

test('🔒 service clôturé : même une participation seule ne peut plus être réécrite', async () => {
  await seedShiftWorld();
  await createShiftBatch(GERANTE_A, ESTAB_A, 'sh1', FM_A, [SRV_A1]);
  await openShiftBatch(GERANTE_A, ESTAB_A, 'sh1', FM_A, [SRV_A1]);
  await closeShift(GERANTE_A, ESTAB_A, 'sh1');
  const db = asUser(GERANTE_A);
  await assertFails(setDoc(participantRef(db, ESTAB_A, 'sh1', SRV_A1), participantData(ESTAB_A, 'sh1', SRV_A1, GERANTE_A)));
});

// ─────────── 8B : AUTEUR RÉEL VS SERVEUR RESPONSABLE ───────────

// Champs d'acteur, comme OrderActorContext.toOrderFields().
function actorFields({ performer, assigned, shiftId = null }) {
  return {
    createdBy: assigned, createdByName: assigned,
    performedByUserId: performer, performedByUserName: performer,
    assignedServerId: assigned, assignedServerName: assigned,
    shiftId,
  };
}

function createOrderAs(uid, e, id, fields) {
  return setDoc(doc(asUser(uid), 'establishments', e, 'orders', id), {
    establishmentId: e, total: 1000, status: 'sent', paymentStatus: 'unpaid', ...fields,
  });
}

// Cas 1
test('✅ cas 1 : serveur Jean crée sa propre commande (performedBy = assigned = Jean)', async () => {
  await seedShiftWorld();
  await assertSucceeds(createOrderAs(SRV_A1, ESTAB_A, 'c1', actorFields({ performer: SRV_A1, assigned: SRV_A1 })));
});

test('✅ ancien client (sans nouveaux champs) : accepté si createdBy = soi', async () => {
  await seedShiftWorld();
  await assertSucceeds(createOrderAs(SRV_A1, ESTAB_A, 'old', { createdBy: SRV_A1, createdByName: 'Jean' }));
  await assertFails(createOrderAs(SRV_A1, ESTAB_A, 'old2', { createdBy: SRV_A2, createdByName: 'Autre' }));
  await assertFails(createOrderAs(SRV_A1, ESTAB_A, 'old3', { total: 1 }));
});

test('🔒 serveur : ni autre serveur responsable, ni faux auteur, ni shift', async () => {
  await seedShiftWorld();
  // Attribuer à un autre serveur.
  await assertFails(createOrderAs(SRV_A1, ESTAB_A, 'x1', actorFields({ performer: SRV_A1, assigned: SRV_A2 })));
  // Falsifier l'auteur réel.
  await assertFails(createOrderAs(SRV_A1, ESTAB_A, 'x2', actorFields({ performer: SRV_A2, assigned: SRV_A1 })));
  // createdBy incohérent avec assignedServerId.
  await assertFails(createOrderAs(SRV_A1, ESTAB_A, 'x3', {
    ...actorFields({ performer: SRV_A1, assigned: SRV_A1 }), createdBy: SRV_A2,
  }));
  // Un serveur ne rattache pas sa commande à un shift.
  await assertFails(createOrderAs(SRV_A1, ESTAB_A, 'x4', actorFields({ performer: SRV_A1, assigned: SRV_A1, shiftId: 'sh1' })));
});

test('✅ gérante : pour elle-même ; 🔒 pas pour un serveur', async () => {
  await seedShiftWorld();
  await assertSucceeds(createOrderAs(GERANTE_A, ESTAB_A, 'g1', actorFields({ performer: GERANTE_A, assigned: GERANTE_A })));
  await assertFails(createOrderAs(GERANTE_A, ESTAB_A, 'g2', actorFields({ performer: GERANTE_A, assigned: SRV_A1 })));
});

// Cas 2
test('✅ cas 2 : Floor Manager en direct dans son service ouvert (performedBy = assigned = FM)', async () => {
  await seedShiftWorld();
  await openShiftAsAdmin('sh1', FM_A, [SRV_A1]);
  await assertSucceeds(createOrderAs(FM_A, ESTAB_A, 'fm1', actorFields({ performer: FM_A, assigned: FM_A, shiftId: 'sh1' })));
});

test('🔒 Floor Manager direct : sans service, service clôturé ou service d’un autre', async () => {
  await seedShiftWorld();
  await openShiftAsAdmin('shA2', FM_A2, [SRV_A2]);
  await assertFails(createOrderAs(FM_A, ESTAB_A, 'f1', actorFields({ performer: FM_A, assigned: FM_A })));
  await assertFails(createOrderAs(FM_A, ESTAB_A, 'f2', actorFields({ performer: FM_A, assigned: FM_A, shiftId: 'shA2' })));
  await openShiftAsAdmin('sh1', FM_A, [SRV_A1]);
  await closeShift(GERANTE_A, ESTAB_A, 'sh1');
  await assertFails(createOrderAs(FM_A, ESTAB_A, 'f3', actorFields({ performer: FM_A, assigned: FM_A, shiftId: 'sh1' })));
});

// Cas 3
test('✅ cas 3 : Floor Manager Paul pour Jean (performedBy = Paul, assigned = Jean)', async () => {
  await seedShiftWorld();
  await openShiftAsAdmin('sh1', FM_A, [SRV_A1]);
  await assertSucceeds(createOrderAs(FM_A, ESTAB_A, 'd1', actorFields({ performer: FM_A, assigned: SRV_A1, shiftId: 'sh1' })));
});

test('🔒 Floor Manager : pas pour un serveur hors de son service', async () => {
  await seedShiftWorld();
  await openShiftAsAdmin('sh1', FM_A, [SRV_A1]);
  await openShiftAsAdmin('shA2', FM_A2, [SRV_A2]);
  // Serveur actif mais non affecté.
  await assertFails(createOrderAs(FM_A, ESTAB_A, 'h1', actorFields({ performer: FM_A, assigned: SRV_A3, shiftId: 'sh1' })));
  // Serveur du service d'un autre Floor Manager.
  await assertFails(createOrderAs(FM_A, ESTAB_A, 'h2', actorFields({ performer: FM_A, assigned: SRV_A2, shiftId: 'sh1' })));
  await assertFails(createOrderAs(FM_A, ESTAB_A, 'h3', actorFields({ performer: FM_A, assigned: SRV_A2, shiftId: 'shA2' })));
  // Serveur d'un autre établissement.
  await assertFails(createOrderAs(FM_A, ESTAB_A, 'h4', actorFields({ performer: FM_A, assigned: SRV_B, shiftId: 'sh1' })));
  // Rôle non serveur.
  await assertFails(createOrderAs(FM_A, ESTAB_A, 'h5', actorFields({ performer: FM_A, assigned: GERANTE_A, shiftId: 'sh1' })));
});

test('🔒 Floor Manager : serveur retiré ou dont le pointeur désigne un autre service', async () => {
  await seedShiftWorld();
  await openShiftAsAdmin('sh1', FM_A, [SRV_A1]);
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await updateDoc(serverPointerRef(ctx.firestore(), ESTAB_A, SRV_A1), { openShiftId: 'autre' });
  });
  await assertFails(createOrderAs(FM_A, ESTAB_A, 'r1', actorFields({ performer: FM_A, assigned: SRV_A1, shiftId: 'sh1' })));
});

test('🔒 Floor Manager : serveur désactivé', async () => {
  await seedShiftWorld();
  await openShiftAsAdmin('sh1', FM_A, [SRV_A1]);
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await updateDoc(doc(ctx.firestore(), 'users', SRV_A1), { isActive: false });
  });
  await assertFails(createOrderAs(FM_A, ESTAB_A, 'r2', actorFields({ performer: FM_A, assigned: SRV_A1, shiftId: 'sh1' })));
});

test('🔒 Floor Manager : faux auteur ou createdBy incohérent', async () => {
  await seedShiftWorld();
  await openShiftAsAdmin('sh1', FM_A, [SRV_A1]);
  await assertFails(createOrderAs(FM_A, ESTAB_A, 's1', actorFields({ performer: SRV_A1, assigned: SRV_A1, shiftId: 'sh1' })));
  await assertFails(createOrderAs(FM_A, ESTAB_A, 's2', {
    ...actorFields({ performer: FM_A, assigned: SRV_A1, shiftId: 'sh1' }), createdBy: FM_A,
  }));
});

// Isolation
test('🔒 isolation multi-tenant des commandes et de leurs acteurs', async () => {
  await seedShiftWorld();
  await openShiftAsAdmin('sh1', FM_A, [SRV_A1]);
  await openShiftAsAdmin('shB', FM_B, [SRV_B], ESTAB_B);
  // FM B ne commande pas dans A, même avec un service de A.
  await assertFails(createOrderAs(FM_B, ESTAB_A, 'i1', actorFields({ performer: FM_B, assigned: FM_B, shiftId: 'sh1' })));
  // Serveur B ne commande pas dans A.
  await assertFails(createOrderAs(SRV_B, ESTAB_A, 'i2', actorFields({ performer: SRV_B, assigned: SRV_B })));
  // FM A ne commande pas dans B pour un serveur de B.
  await assertFails(createOrderAs(FM_A, ESTAB_B, 'i3', actorFields({ performer: FM_A, assigned: SRV_B, shiftId: 'shB' })));
  // Chacun chez soi : accepté.
  await assertSucceeds(createOrderAs(FM_B, ESTAB_B, 'i4', actorFields({ performer: FM_B, assigned: SRV_B, shiftId: 'shB' })));
});

// Immuabilité
test('🔒 les acteurs d’une commande ne sont plus modifiables ; ✅ le suivi cuisine si', async () => {
  await seedShiftWorld();
  await createOrderAs(SRV_A1, ESTAB_A, 'u1', actorFields({ performer: SRV_A1, assigned: SRV_A1 }));
  const ref = doc(asUser(SRV_A1), 'establishments', ESTAB_A, 'orders', 'u1');
  await assertFails(updateDoc(ref, { createdBy: SRV_A2 }));
  await assertFails(updateDoc(ref, { assignedServerId: SRV_A2 }));
  await assertFails(updateDoc(ref, { performedByUserId: SRV_A2 }));
  await assertFails(updateDoc(ref, { shiftId: 'sh1' }));
  await assertFails(updateDoc(doc(asUser(GERANTE_A), 'establishments', ESTAB_A, 'orders', 'u1'), { createdByName: 'X' }));
  await assertSucceeds(updateDoc(doc(asUser('chefA'), 'establishments', ESTAB_A, 'orders', 'u1'), { kitchenStatus: 'ready' }));
});

// Lignes de commande
test('✅ Floor Manager crée les lignes de SA commande ; 🔒 pas celles d’une autre', async () => {
  await seedShiftWorld();
  await openShiftAsAdmin('sh1', FM_A, [SRV_A1]);
  const db = asUser(FM_A);
  const batch = writeBatch(db);
  batch.set(doc(db, 'establishments', ESTAB_A, 'orders', 'l1'), {
    establishmentId: ESTAB_A, total: 1, ...actorFields({ performer: FM_A, assigned: SRV_A1, shiftId: 'sh1' }),
  });
  batch.set(doc(db, 'establishments', ESTAB_A, 'orders', 'l1', 'items', 'it1'), { name: 'Riz', quantity: 1 });
  await assertSucceeds(batch.commit());

  await createOrderAs(SRV_A1, ESTAB_A, 'l2', actorFields({ performer: SRV_A1, assigned: SRV_A1 }));
  await assertFails(setDoc(doc(db, 'establishments', ESTAB_A, 'orders', 'l2', 'items', 'it9'), { name: 'X' }));
});

// ─────────── 9B : COMMANDES FLOOR MANAGER (moteur réutilisé) ───────────

async function seedOrderingWorld() {
  await seedShiftWorld();
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'establishments', ESTAB_A), { name: 'A', stockMode: 'strict' });
    await setDoc(doc(db, 'establishments', ESTAB_B), { name: 'B', stockMode: 'strict' });
    for (const e of [ESTAB_A, ESTAB_B]) {
      await setDoc(doc(db, 'establishments', e, 'menuItems', 'riz'), { name: 'Riz', price: 1000 });
      await setDoc(doc(db, 'establishments', e, 'store_stocks', 'st_riz'), {
        store: 'restaurant', itemId: 'riz', unit: 'kg', quantity: 10, minimumQuantity: 1,
      });
    }
    // Ancienne commande non encaissée sans addition (table 7) : le moteur la
    // rattache à l'addition de la nouvelle commande.
    await setDoc(doc(db, 'establishments', ESTAB_A, 'orders', 'legacy7'), {
      createdBy: SRV_A2, createdByName: 'Ancien', paymentStatus: 'unpaid',
      clientType: 'restaurant', tableNumber: '7', total: 500,
    });
    await setDoc(doc(db, 'establishments', ESTAB_A, 'orders', 'paid1'), {
      createdBy: SRV_A2, paymentStatus: 'paid', total: 900,
    });
  });
}

// Même lot que OrderService.createOrder (transaction) + StoreStockService.
function orderBatch(uid, e, orderId, actor, {
  newQuantity = 9.6, movement = {}, stockUpdate = {}, orphans = ['legacy7'],
} = {}) {
  const db = asUser(uid);
  const batch = writeBatch(db);
  batch.set(doc(db, 'establishments', e, 'orders', orderId), {
    establishmentId: e, orderNumber: `CMD-${orderId}`, ticketId: `TCK-7-${orderId}`,
    clientType: 'restaurant', tableNumber: '7', status: 'sent',
    paymentStatus: 'unpaid', total: 1000, stockMode: 'strict', ...actor,
  });
  batch.set(doc(db, 'establishments', e, 'orders', orderId, 'items', 'l1'), {
    menuItemId: 'riz', name: 'Riz', quantity: 1,
  });
  for (const orphan of orphans) {
    batch.update(doc(db, 'establishments', e, 'orders', orphan), { ticketId: `TCK-7-${orderId}` });
  }
  batch.update(doc(db, 'establishments', e, 'store_stocks', 'st_riz'), {
    quantity: newQuantity, isLowStock: false, lastOrderId: orderId, updatedAt: serverTimestamp(),
    pendingSync: false, syncError: false, ...stockUpdate,
  });
  batch.set(doc(db, 'establishments', e, 'stock_movements', `mv_${orderId}`), {
    establishmentId: e, store: 'restaurant', itemId: 'riz', itemName: 'Riz', unit: 'kg',
    quantity: 0.4, movementType: 'out', performedBy: actor.performedByUserId,
    orderId, orderNumber: `CMD-${orderId}`, createdAt: serverTimestamp(), ...movement,
  });
  return batch.commit();
}

const fmDirect = () => actorFields({ performer: FM_A, assigned: FM_A, shiftId: 'sh1' });
const fmForJean = () => actorFields({ performer: FM_A, assigned: SRV_A1, shiftId: 'sh1' });

test('✅ Floor Manager en service : menu, additions ouvertes, stock (lectures du moteur)', async () => {
  await seedOrderingWorld();
  await openShiftAsAdmin('sh1', FM_A, [SRV_A1]);
  const db = asUser(FM_A);
  await assertSucceeds(getDocs(collection(db, 'establishments', ESTAB_A, 'menuItems')));
  await assertSucceeds(getDoc(doc(db, 'establishments', ESTAB_A)));
  await assertSucceeds(getDocs(query(
    collection(db, 'establishments', ESTAB_A, 'orders'), where('paymentStatus', '==', 'unpaid'),
  )));
  await assertSucceeds(getDocs(query(
    collection(db, 'establishments', ESTAB_A, 'store_stocks'),
    where('store', '==', 'restaurant'), where('itemId', '==', 'riz'),
  )));
});

test('🔒 Floor Manager en service : pas l’historique encaissé ni toutes les commandes', async () => {
  await seedOrderingWorld();
  await openShiftAsAdmin('sh1', FM_A, [SRV_A1]);
  const db = asUser(FM_A);
  await assertFails(getDoc(doc(db, 'establishments', ESTAB_A, 'orders', 'paid1')));
  await assertFails(getDocs(collection(db, 'establishments', ESTAB_A, 'orders')));
  await assertFails(getDocs(collection(db, 'establishments', ESTAB_A, 'clients')));
});

test('✅ commande directe Floor Manager (lot complet du moteur)', async () => {
  await seedOrderingWorld();
  await openShiftAsAdmin('sh1', FM_A, [SRV_A1]);
  await assertSucceeds(orderBatch(FM_A, ESTAB_A, 'direct1', fmDirect()));
});

test('✅ commande Floor Manager → Jean (lot complet du moteur)', async () => {
  await seedOrderingWorld();
  await openShiftAsAdmin('sh1', FM_A, [SRV_A1]);
  await assertSucceeds(orderBatch(FM_A, ESTAB_A, 'jean1', fmForJean()));
  // La commande appartient bien à Jean (lecture par un rôle d'établissement).
  const snap = await getDoc(doc(asUser(GERANTE_A), 'establishments', ESTAB_A, 'orders', 'jean1'));
  assert.strictEqual(snap.data().createdBy, SRV_A1);
  assert.strictEqual(snap.data().assignedServerId, SRV_A1);
  assert.strictEqual(snap.data().performedByUserId, FM_A);
  assert.strictEqual(snap.data().shiftId, 'sh1');
});

test('🔒 service clôturé avant validation : commande refusée (et plus de menu)', async () => {
  await seedOrderingWorld();
  await openShiftAsAdmin('sh1', FM_A, [SRV_A1]);
  await closeShift(GERANTE_A, ESTAB_A, 'sh1');
  await assertFails(orderBatch(FM_A, ESTAB_A, 'c1', fmDirect()));
  await assertFails(orderBatch(FM_A, ESTAB_A, 'c2', fmForJean()));
  await assertFails(getDocs(collection(asUser(FM_A), 'establishments', ESTAB_A, 'menuItems')));
});

test('🔒 Jean retiré du service avant validation : commande pour Jean refusée', async () => {
  await seedOrderingWorld();
  await openShiftAsAdmin('sh1', FM_A, [SRV_A1, SRV_A2]);
  // La gérante retire Jean (même lot que ShiftService.updateServers).
  const g = asUser(GERANTE_A);
  const batch = writeBatch(g);
  batch.update(shiftRef(g, ESTAB_A, 'sh1'), { serverIds: [SRV_A2], updatedAt: serverTimestamp() });
  batch.set(participantRef(g, ESTAB_A, 'sh1', SRV_A1), {
    ...participantData(ESTAB_A, 'sh1', SRV_A1, GERANTE_A, false), removedBy: GERANTE_A,
  });
  await assertSucceeds(batch.commit());

  await assertFails(orderBatch(FM_A, ESTAB_A, 'r1', fmForJean()));
  // Le Floor Manager peut toujours commander en direct.
  await assertSucceeds(orderBatch(FM_A, ESTAB_A, 'r2', fmDirect()));
});

test('🔒 serveur hors service et autre établissement refusés', async () => {
  await seedOrderingWorld();
  await openShiftAsAdmin('sh1', FM_A, [SRV_A1]);
  await assertFails(orderBatch(FM_A, ESTAB_A, 'h1', actorFields({ performer: FM_A, assigned: SRV_A3, shiftId: 'sh1' })));
  await assertFails(orderBatch(FM_A, ESTAB_B, 'b1', fmDirect(), { orphans: [] }));
  await assertFails(getDocs(collection(asUser(FM_A), 'establishments', ESTAB_B, 'menuItems')));
  await assertFails(getDocs(query(
    collection(asUser(FM_A), 'establishments', ESTAB_B, 'store_stocks'), where('store', '==', 'restaurant'),
  )));
});

test('🔒 stock : le Floor Manager ne fait que DÉDUIRE pour SA commande', async () => {
  await seedOrderingWorld();
  await openShiftAsAdmin('sh1', FM_A, [SRV_A1]);
  // Hausse de stock.
  await assertFails(orderBatch(FM_A, ESTAB_A, 's1', fmDirect(), { newQuantity: 11 }));
  // Stock négatif.
  await assertFails(orderBatch(FM_A, ESTAB_A, 's2', fmDirect(), { newQuantity: -1 }));
  // Autre champ du stock.
  await assertFails(orderBatch(FM_A, ESTAB_A, 's3', fmDirect(), { stockUpdate: { minimumQuantity: 0 } }));
  // Mouvement d'entrée.
  await assertFails(orderBatch(FM_A, ESTAB_A, 's4', fmDirect(), { movement: { movementType: 'in' } }));
  // Mouvement signé par quelqu'un d'autre.
  await assertFails(orderBatch(FM_A, ESTAB_A, 's5', fmDirect(), { movement: { performedBy: SRV_A1 } }));
  // Déduction isolée, sans commande.
  await assertFails(updateDoc(doc(asUser(FM_A), 'establishments', ESTAB_A, 'store_stocks', 'st_riz'), { quantity: 5 }));
  // Déduction citant une commande jamais créée.
  await assertFails(updateDoc(doc(asUser(FM_A), 'establishments', ESTAB_A, 'store_stocks', 'st_riz'), {
    quantity: 5, lastOrderId: 'fantome',
  }));
  // Rejeu : déduction citant SA commande déjà existante.
  await assertSucceeds(orderBatch(FM_A, ESTAB_A, 'mine', fmDirect()));
  await assertFails(updateDoc(doc(asUser(FM_A), 'establishments', ESTAB_A, 'store_stocks', 'st_riz'), {
    quantity: 5, lastOrderId: 'mine',
  }));
  // Mouvement pour la commande d'un autre.
  await assertFails(setDoc(doc(asUser(FM_A), 'establishments', ESTAB_A, 'stock_movements', 'mvx'), {
    store: 'restaurant', movementType: 'out', performedBy: FM_A, orderId: 'legacy7', quantity: 1,
  }));
});

test('🔒 commandes existantes : le Floor Manager ne fait que rattacher une addition', async () => {
  await seedOrderingWorld();
  await openShiftAsAdmin('sh1', FM_A, [SRV_A1]);
  const db = asUser(FM_A);
  await assertFails(updateDoc(doc(db, 'establishments', ESTAB_A, 'orders', 'legacy7'), { status: 'cancelled' }));
  await assertFails(updateDoc(doc(db, 'establishments', ESTAB_A, 'orders', 'legacy7'), { ticketId: 'T', total: 0 }));
  await assertFails(updateDoc(doc(db, 'establishments', ESTAB_A, 'orders', 'paid1'), { ticketId: 'T' }));
  await assertSucceeds(updateDoc(doc(db, 'establishments', ESTAB_A, 'orders', 'legacy7'), { ticketId: 'T' }));
  // Addition déjà posée : plus modifiable.
  await assertFails(updateDoc(doc(db, 'establishments', ESTAB_A, 'orders', 'legacy7'), { ticketId: 'T2' }));
});

test('🔒 Floor Manager hors service : aucune lecture ni écriture de commande', async () => {
  await seedOrderingWorld();
  const db = asUser(FM_A);
  await assertFails(getDocs(collection(db, 'establishments', ESTAB_A, 'menuItems')));
  await assertFails(getDocs(query(collection(db, 'establishments', ESTAB_A, 'orders'), where('paymentStatus', '==', 'unpaid'))));
  await assertFails(getDocs(query(collection(db, 'establishments', ESTAB_A, 'store_stocks'), where('store', '==', 'restaurant'))));
  await assertFails(orderBatch(FM_A, ESTAB_A, 'x1', fmDirect()));
});

test('✅ non-régression : serveur classique (lot complet) et anciennes commandes lisibles', async () => {
  await seedOrderingWorld();
  await assertSucceeds(orderBatch(SRV_A1, ESTAB_A, 'srv1', actorFields({ performer: SRV_A1, assigned: SRV_A1 })));
  const legacy = await getDoc(doc(asUser(SRV_A1), 'establishments', ESTAB_A, 'orders', 'legacy7'));
  assert.strictEqual(legacy.data().createdBy, SRV_A2);
  assert.strictEqual(legacy.data().assignedServerId, undefined);
});

test('✅ Floor Manager lit SES notifications « prêt » (commandes directes), pas celles des autres', async () => {
  await seedOrderingWorld();
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'establishments', ESTAB_A, 'serverNotifications', 'kitchen_direct_ready'), {
      serveurId: FM_A, isRead: false, createdAt: new Date(),
    });
    await setDoc(doc(db, 'establishments', ESTAB_A, 'serverNotifications', 'kitchen_jean_ready'), {
      serveurId: SRV_A1, isRead: false, createdAt: new Date(),
    });
  });
  const db = asUser(FM_A);
  await assertSucceeds(getDocs(query(
    collection(db, 'establishments', ESTAB_A, 'serverNotifications'),
    where('serveurId', '==', FM_A), where('isRead', '==', false),
  )));
  await assertSucceeds(getDoc(doc(db, 'establishments', ESTAB_A, 'serverNotifications', 'kitchen_direct_ready')));
  await assertFails(getDoc(doc(db, 'establishments', ESTAB_A, 'serverNotifications', 'kitchen_jean_ready')));
});

// ─────────── 10B : ENCAISSEMENTS FLOOR MANAGER ───────────

function unpaidOrder(e, owner, extra = {}) {
  return {
    establishmentId: e, createdBy: owner, createdByName: owner,
    assignedServerId: owner, assignedServerName: owner,
    performedByUserId: owner, performedByUserName: owner,
    paymentStatus: 'unpaid', status: 'ready', total: 3000,
    isForKitchen: true, kitchenStatus: 'ready', isForBar: false,
    clientType: 'restaurant', tableNumber: '8',
    ...extra,
  };
}

async function seedPaymentWorld() {
  await seedOrderingWorld();
  await openShiftAsAdmin('sh1', FM_A, [SRV_A1]);
  await openShiftAsAdmin('shA2', FM_A2, [SRV_A3]);
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    const put = (e, id, data) => setDoc(doc(db, 'establishments', e, 'orders', id), data);
    await put(ESTAB_A, 'jean1', unpaidOrder(ESTAB_A, SRV_A1));
    await put(ESTAB_A, 'jean2', unpaidOrder(ESTAB_A, SRV_A1));
    await put(ESTAB_A, 'paul1', unpaidOrder(ESTAB_A, FM_A, { tableNumber: '7' }));
    await put(ESTAB_A, 'other1', unpaidOrder(ESTAB_A, SRV_A2, { tableNumber: '9' }));
    await put(ESTAB_A, 'fm2direct', unpaidOrder(ESTAB_A, FM_A2, { tableNumber: '10' }));
    await put(ESTAB_A, 'notReady', unpaidOrder(ESTAB_A, SRV_A1, { kitchenStatus: 'preparing' }));
    await put(ESTAB_A, 'cancelled', unpaidOrder(ESTAB_A, SRV_A1, { status: 'cancelled' }));
    await put(ESTAB_B, 'jeanB', unpaidOrder(ESTAB_B, SRV_B));
  });
}

// Même lot que PaymentService.registerTicketPayment (transaction).
function payBatch(uid, e, paymentId, orderIds, payment = {}) {
  const db = asUser(uid);
  const batch = writeBatch(db);
  batch.set(doc(db, 'establishments', e, 'payments', paymentId), {
    establishmentId: e, ticketId: 'TCK-8', orderId: orderIds[0],
    orderNumber: 'CMD', orderIds, orderNumbers: orderIds, orderCount: orderIds.length,
    clientType: 'restaurant', type: 'restaurant',
    receivedBy: uid, receivedByName: uid,
    responsibleServerId: SRV_A1, responsibleServerName: 'Jean',
    shiftId: 'sh1', method: 'cash', amount: 3000 * orderIds.length,
    status: 'confirmed', handoverStatus: 'pending', handoverId: null,
    isFiscalized: false, fiscalUid: '', pendingSync: false, syncError: false,
    createdAt: serverTimestamp(), updatedAt: serverTimestamp(),
    ...payment,
  });
  for (const id of orderIds) {
    batch.update(doc(db, 'establishments', e, 'orders', id), {
      paymentStatus: 'paid', status: 'paid', paymentId, paidAt: serverTimestamp(),
      updatedAt: serverTimestamp(), pendingSync: false, syncError: false,
    });
  }
  return batch.commit();
}

test('✅ vente de Jean encaissée par le Floor Manager (responsable = Jean, encaisseur = FM)', async () => {
  await seedPaymentWorld();
  await assertSucceeds(payBatch(FM_A, ESTAB_A, 'p1', ['jean1', 'jean2']));
  const snap = await getDoc(doc(asUser(GERANTE_A), 'establishments', ESTAB_A, 'payments', 'p1'));
  assert.strictEqual(snap.data().responsibleServerId, SRV_A1);
  assert.strictEqual(snap.data().receivedBy, FM_A);
  assert.strictEqual(snap.data().shiftId, 'sh1');
});

test('✅ encaissement direct du Floor Manager (responsable = encaisseur = FM)', async () => {
  await seedPaymentWorld();
  await assertSucceeds(payBatch(FM_A, ESTAB_A, 'p2', ['paul1'], {
    responsibleServerId: FM_A, responsibleServerName: 'Paul',
  }));
});

test('🔒 pas la table d’un serveur hors service ni d’un autre Floor Manager', async () => {
  await seedPaymentWorld();
  // Serveur hors de son service (déclaré tel quel, ou maquillé en Jean).
  await assertFails(payBatch(FM_A, ESTAB_A, 'x1', ['other1'], { responsibleServerId: SRV_A2 }));
  await assertFails(payBatch(FM_A, ESTAB_A, 'x2', ['other1']));
  // Commande directe d'un autre Floor Manager.
  await assertFails(payBatch(FM_A, ESTAB_A, 'x3', ['fm2direct'], { responsibleServerId: FM_A2 }));
  await assertFails(payBatch(FM_A, ESTAB_A, 'x4', ['fm2direct'], { responsibleServerId: FM_A }));
  // Serveur d'un autre Floor Manager.
  await assertFails(payBatch(FM_A, ESTAB_A, 'x5', ['jean1'], { responsibleServerId: SRV_A3 }));
});

test('🔒 Jean retiré du service avant le paiement : refusé', async () => {
  await seedPaymentWorld();
  const g = asUser(GERANTE_A);
  const batch = writeBatch(g);
  batch.update(shiftRef(g, ESTAB_A, 'sh1'), { serverIds: [], updatedAt: serverTimestamp() });
  batch.set(participantRef(g, ESTAB_A, 'sh1', SRV_A1), participantData(ESTAB_A, 'sh1', SRV_A1, GERANTE_A, false));
  await assertSucceeds(batch.commit());
  await assertFails(payBatch(FM_A, ESTAB_A, 'r1', ['jean1']));
});

test('🔒 service clôturé avant le paiement : encaissement délégué et direct refusés', async () => {
  await seedPaymentWorld();
  await closeShift(GERANTE_A, ESTAB_A, 'sh1');
  await assertFails(payBatch(FM_A, ESTAB_A, 'c1', ['jean1']));
  await assertFails(payBatch(FM_A, ESTAB_A, 'c2', ['paul1'], { responsibleServerId: FM_A }));
});

test('🔒 autre établissement refusé', async () => {
  await seedPaymentWorld();
  await assertFails(payBatch(FM_A, ESTAB_B, 'b1', ['jeanB'], { responsibleServerId: SRV_B }));
});

test('🔒 encaisseur falsifié, note chambre, commande non prête ou annulée', async () => {
  await seedPaymentWorld();
  await assertFails(payBatch(FM_A, ESTAB_A, 'f1', ['jean1'], { receivedBy: SRV_A1 }));
  await assertFails(payBatch(FM_A, ESTAB_A, 'f2', ['jean1'], { method: 'room', handoverStatus: 'none' }));
  await assertFails(payBatch(FM_A, ESTAB_A, 'f3', ['notReady']));
  await assertFails(payBatch(FM_A, ESTAB_A, 'f4', ['cancelled']));
  await assertFails(payBatch(FM_A, ESTAB_A, 'f5', ['jean1'], { shiftId: 'shA2' }));
});

test('🔒 double encaissement : la seconde validation échoue (Floor Manager)', async () => {
  await seedPaymentWorld();
  await assertSucceeds(payBatch(FM_A, ESTAB_A, 'd1', ['jean1']));
  await assertFails(payBatch(FM_A, ESTAB_A, 'd2', ['jean1']));
});

test('🔒 double encaissement : la seconde validation échoue aussi pour un serveur', async () => {
  await seedPaymentWorld();
  const serveurPay = (id) => payBatch(SRV_A1, ESTAB_A, id, ['jean2'], { shiftId: null });
  await assertSucceeds(serveurPay('s1'));
  await assertFails(serveurPay('s2'));
  // Une commande payée ne peut pas non plus être « dé-payée » ni rattachée
  // à un autre paiement.
  const ref = doc(asUser(GERANTE_A), 'establishments', ESTAB_A, 'orders', 'jean2');
  await assertFails(updateDoc(ref, { paymentStatus: 'unpaid' }));
  await assertFails(updateDoc(ref, { paymentId: 'autre' }));
  // Les autres champs restent modifiables (ex. fiscalisation).
  await assertSucceeds(updateDoc(ref, { isFiscalized: true }));
});

test('🔒 pas de paiement « fantôme » ni d’accès général aux paiements', async () => {
  await seedPaymentWorld();
  const db = asUser(FM_A);
  // Paiement sans solder la commande dans le même lot.
  await assertFails(setDoc(doc(db, 'establishments', ESTAB_A, 'payments', 'g1'), {
    orderId: 'jean1', orderIds: ['jean1'], receivedBy: FM_A, responsibleServerId: SRV_A1,
    shiftId: 'sh1', method: 'cash', status: 'confirmed', handoverStatus: 'pending', amount: 1,
  }));
  // Commande soldée avec le paiement d'un autre.
  await assertFails(updateDoc(doc(db, 'establishments', ESTAB_A, 'orders', 'jean1'), {
    paymentStatus: 'paid', status: 'paid', paymentId: 'payment1',
  }));
  // Lecture des paiements : fermée.
  await assertFails(getDoc(doc(db, 'establishments', ESTAB_A, 'payments', 'payment1')));
  await assertFails(getDocs(collection(db, 'establishments', ESTAB_A, 'payments')));
});

test('✅ Floor Manager : liste des additions ouvertes (lecture des non encaissées)', async () => {
  await seedPaymentWorld();
  await assertSucceeds(getDocs(query(
    collection(asUser(FM_A), 'establishments', ESTAB_A, 'orders'),
    where('paymentStatus', '==', 'unpaid'),
  )));
});

test('✅ non-régression : encaissement classique d’un serveur', async () => {
  await seedPaymentWorld();
  await assertSucceeds(payBatch(SRV_A1, ESTAB_A, 'srvp', ['jean1'], { shiftId: null }));
});

// ─────────── 11B : REMISES SERVEUR -> FLOOR MANAGER ───────────

const payRef = (db, e, id) => doc(db, 'establishments', e, 'payments', id);
const hoRef = (db, e, id) => doc(db, 'establishments', e, 'serverHandovers', id);

function shiftPayment(receivedBy, amount, extra = {}) {
  return {
    establishmentId: ESTAB_A, receivedBy, receivedByName: receivedBy,
    responsibleServerId: receivedBy, amount, method: 'cash', type: 'restaurant',
    status: 'confirmed', handoverStatus: 'pending', handoverId: null,
    shiftId: 'sh1', pendingSync: false, syncError: false, createdAt: new Date(),
    ...extra,
  };
}

// sh1 : Floor Manager FM_A, serveur SRV_A1 (Jean). shA2 : FM_A2, SRV_A3.
async function seedHandoverWorld() {
  await seedPaymentWorld();
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    const put = (id, data, e = ESTAB_A) => setDoc(payRef(db, e, id), data);
    await put('jp1', shiftPayment(SRV_A1, 30000));
    await put('jp2', shiftPayment(SRV_A1, 20000, { method: 'mobile_money' }));
    await put('jold', shiftPayment(SRV_A1, 5000, { shiftId: null }));
    // Vente de Jean encaissée par le Floor Manager : Paul détient l'argent.
    await put('fmp', shiftPayment(FM_A, 12000, { responsibleServerId: SRV_A1 }));
    await put('a3p', shiftPayment(SRV_A3, 7000, { shiftId: 'shA2' }));
    // Donnée incohérente (service dont Jean n'a jamais fait partie).
    await put('jx', shiftPayment(SRV_A1, 4000, { shiftId: 'shA2' }));
  });
}

// Même lot que ShiftHandoverService.handOverToFloorManager.
function fmHandoverBatch(uid, e, id, paymentIds, over = {}, declare = paymentIds, bump = true) {
  const db = asUser(uid);
  const batch = writeBatch(db);
  batch.set(hoRef(db, e, id), {
    establishmentId: e, serveurId: uid, serveurName: uid,
    declaredAmount: 1000 * paymentIds.length, validatedAmount: null, status: 'pending',
    receivedByManagerId: null, receivedByManagerName: null,
    paymentIds, validatedPaymentIds: [], rejectedPaymentIds: [],
    shiftId: 'sh1', senderUserId: uid, senderUserName: uid, senderRole: 'serveur',
    receiverUserId: FM_A, receiverUserName: FM_A, receiverRole: 'floor_manager',
    paymentBreakdown: { cash: 1000 }, comment: '', createdBy: uid,
    createdAt: serverTimestamp(), updatedAt: serverTimestamp(), validatedAt: null,
    pendingSync: false, syncError: false,
    ...over,
  });
  for (const p of declare) {
    batch.update(payRef(db, e, p), {
      handoverStatus: 'declared', handoverId: id, updatedAt: serverTimestamp(),
      pendingSync: false, syncError: false,
    });
  }
  // 13B : remise Floor Manager = événement financier du service.
  if ((over.receiverRole === undefined ? 'floor_manager' : over.receiverRole) === 'floor_manager' && bump) {
    batch.update(shiftRef(db, e, over.shiftId ?? 'sh1'), { financialRevision: increment(1) });
  }
  return batch.commit();
}

// Même lot que GeranteHandoverService.validateSelectedPayments /
// rejectSelectedPayments (réutilisés par le Floor Manager).
function processBatch(uid, e, id, paymentIds, reject = false, over = {}, bumpShift = 'sh1') {
  const db = asUser(uid);
  const batch = writeBatch(db);
  batch.update(hoRef(db, e, id), {
    [reject ? 'rejectedPaymentIds' : 'validatedPaymentIds']: paymentIds,
    validatedAmount: reject ? 0 : 50000, status: 'validated',
    receivedByManagerId: uid, receivedByManagerName: uid,
    validatedAt: serverTimestamp(), updatedAt: serverTimestamp(),
    pendingSync: false, syncError: false,
    ...over,
  });
  for (const p of paymentIds) {
    batch.update(payRef(db, e, p), reject
      ? { handoverStatus: 'pending', handoverId: null, updatedAt: serverTimestamp(), pendingSync: false, syncError: false }
      : { handoverStatus: 'validated', updatedAt: serverTimestamp(), pendingSync: false, syncError: false });
  }
  if (bumpShift) batch.update(shiftRef(db, e, bumpShift), { financialRevision: increment(1) });
  return batch.commit();
}

async function readPayment(id) {
  let data;
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    data = (await getDoc(payRef(ctx.firestore(), ESTAB_A, id))).data();
  });
  return data;
}

// ── Rattachement d'un encaissement serveur à son service ──
test('✅ serveur présent dans un service ouvert : son encaissement porte le shiftId', async () => {
  await seedPaymentWorld();
  await assertSucceeds(payBatch(SRV_A1, ESTAB_A, 'sp1', ['jean1'], { responsibleServerId: SRV_A1 }));
});

test('🔒 shiftId d’un autre service, service clôturé ou non-serveur : refusé', async () => {
  await seedPaymentWorld();
  await assertFails(payBatch(SRV_A1, ESTAB_A, 'sx1', ['jean1'], { shiftId: 'shA2' }));
  await assertFails(payBatch(SRV_A2, ESTAB_A, 'sx2', ['other1'], { responsibleServerId: SRV_A2 }));
  await assertFails(payBatch(GERANTE_A, ESTAB_A, 'sx3', ['jean1']));
  await closeShift(GERANTE_A, ESTAB_A, 'sh1');
  await assertFails(payBatch(SRV_A1, ESTAB_A, 'sx4', ['jean1']));
  // Service clôturé : l'encaissement hors service reste possible (historique).
  await assertSucceeds(payBatch(SRV_A1, ESTAB_A, 'sx5', ['jean1'], { shiftId: null }));
});

// ── Création d'une remise ──
test('✅ Jean remet ses encaissements du service à SON Floor Manager', async () => {
  await seedHandoverWorld();
  await assertSucceeds(fmHandoverBatch(SRV_A1, ESTAB_A, 'h1', ['jp1', 'jp2']));
  const p = await readPayment('jp1');
  assert.strictEqual(p.handoverStatus, 'declared');
  assert.strictEqual(p.handoverId, 'h1');
  // Le paiement client n'est pas réécrit (montant, encaisseur, service).
  assert.strictEqual(p.amount, 30000);
  assert.strictEqual(p.receivedBy, SRV_A1);
});

test('🔒 destinataire libre, autre service, autre établissement, émetteur falsifié', async () => {
  await seedHandoverWorld();
  await assertFails(fmHandoverBatch(SRV_A1, ESTAB_A, 'x1', ['jp1'], { receiverUserId: FM_A2 }));
  await assertFails(fmHandoverBatch(SRV_A1, ESTAB_A, 'x2', ['jp1'], { receiverUserId: GERANTE_A }));
  await assertFails(fmHandoverBatch(SRV_A1, ESTAB_A, 'x3', ['jp1'], { shiftId: 'shA2', receiverUserId: FM_A2 }));
  await assertFails(fmHandoverBatch(SRV_A1, ESTAB_A, 'x4', ['jp1'], { serveurId: SRV_A3, senderUserId: SRV_A3 }));
  await assertFails(fmHandoverBatch(SRV_A1, ESTAB_A, 'x5', ['jp1'], { senderRole: 'gerante' }));
  await assertFails(fmHandoverBatch(SRV_A1, ESTAB_A, 'x6', ['jp1'], { status: 'validated' }));
  await assertFails(fmHandoverBatch(SRV_A1, ESTAB_A, 'x7', ['jp1'], { validatedPaymentIds: ['jp1'] }));
  await assertFails(fmHandoverBatch(SRV_A1, ESTAB_A, 'x8', ['jp1'], { declaredAmount: 0 }));
  await assertFails(fmHandoverBatch(SRV_B, ESTAB_B, 'x9', ['jp1'], {}, []));
  await assertFails(fmHandoverBatch('barmanA', ESTAB_A, 'x10', ['jp1']));
  await assertFails(fmHandoverBatch(FM_A, ESTAB_A, 'x11', ['fmp']));
});

test('🔒 pas de paiement historique, d’un autre encaisseur ou d’un autre service', async () => {
  await seedHandoverWorld();
  // Paiement historique sans shiftId : jamais rattaché à un service.
  await assertFails(fmHandoverBatch(SRV_A1, ESTAB_A, 'y1', ['jp1', 'jold']));
  // Encaissé par Paul : Jean ne remet pas ce que Paul détient déjà.
  await assertFails(fmHandoverBatch(SRV_A1, ESTAB_A, 'y2', ['jp1', 'fmp']));
  // Paiement d'un autre serveur, d'un autre service.
  await assertFails(fmHandoverBatch(SRV_A1, ESTAB_A, 'y3', ['jp1', 'a3p']));
  // Service dont il n'est pas participant, même avec un paiement qui le porte.
  await assertFails(fmHandoverBatch(SRV_A1, ESTAB_A, 'y4', ['jx'], { shiftId: 'shA2', receiverUserId: FM_A2 }));
});

test('🔒 remise « fantôme » : le document sans bascule des paiements est refusé', async () => {
  await seedHandoverWorld();
  await assertFails(fmHandoverBatch(SRV_A1, ESTAB_A, 'g1', ['jp1', 'jp2'], {}, []));
});

test('🔒 double remise : le même encaissement ne peut être remis deux fois', async () => {
  await seedHandoverWorld();
  await assertSucceeds(fmHandoverBatch(SRV_A1, ESTAB_A, 'd1', ['jp1']));
  await assertFails(fmHandoverBatch(SRV_A1, ESTAB_A, 'd2', ['jp1']));
  await assertFails(fmHandoverBatch(SRV_A1, ESTAB_A, 'd3', ['jp2', 'jp1']));
  // Ni vers la gérante par le circuit historique.
  await assertFails(fmHandoverBatch(SRV_A1, ESTAB_A, 'd4', ['jp1'], {
    receiverRole: null, receiverUserId: null, shiftId: null,
  }));
});

test('🔒 circuit gérante : les encaissements d’un service passent par le Floor Manager', async () => {
  await seedHandoverWorld();
  const legacy = { receiverRole: null, receiverUserId: null, shiftId: null };
  await assertFails(fmHandoverBatch(SRV_A1, ESTAB_A, 'l1', ['jp1'], legacy));
  await assertFails(fmHandoverBatch(SRV_A1, ESTAB_A, 'l2', ['jp1'], { ...legacy, shiftId: 'sh1' }));
  // Non-régression : paiement hors service -> gérante, validé par elle.
  await assertSucceeds(fmHandoverBatch(SRV_A1, ESTAB_A, 'l3', ['jold'], legacy));
  await assertSucceeds(processBatch(GERANTE_A, ESTAB_A, 'l3', ['jold'], false, {}, null));
});

// ── Lecture côté Floor Manager ──
test('✅🔒 le Floor Manager lit ses remises et les encaissements de SES services seulement', async () => {
  await seedHandoverWorld();
  await fmHandoverBatch(SRV_A1, ESTAB_A, 'h1', ['jp1']);
  const fm = asUser(FM_A);
  const fm2 = asUser(FM_A2);
  await assertSucceeds(getDoc(hoRef(fm, ESTAB_A, 'h1')));
  await assertSucceeds(getDocs(query(
    collection(fm, 'establishments', ESTAB_A, 'serverHandovers'),
    where('receiverUserId', '==', FM_A),
  )));
  await assertSucceeds(getDoc(payRef(fm, ESTAB_A, 'jp1')));
  await assertSucceeds(getDocs(query(
    collection(fm, 'establishments', ESTAB_A, 'payments'),
    where('shiftId', '==', 'sh1'),
  )));
  // Pas les remises / paiements d'un autre service, ni l'historique.
  await assertFails(getDoc(hoRef(fm2, ESTAB_A, 'h1')));
  await assertFails(getDocs(collection(fm2, 'establishments', ESTAB_A, 'serverHandovers')));
  await assertFails(getDoc(payRef(fm2, ESTAB_A, 'jp1')));
  await assertFails(getDocs(query(
    collection(fm2, 'establishments', ESTAB_A, 'payments'),
    where('shiftId', '==', 'sh1'),
  )));
  await assertFails(getDoc(payRef(fm, ESTAB_A, 'jold')));
  await assertFails(getDoc(payRef(fm, ESTAB_A, 'a3p')));
  await assertFails(getDoc(hoRef(fm, ESTAB_A, 'handover1')));
});

// ── Validation / rejet ──
test('✅ le Floor Manager destinataire valide la remise', async () => {
  await seedHandoverWorld();
  await fmHandoverBatch(SRV_A1, ESTAB_A, 'h1', ['jp1', 'jp2']);
  await assertSucceeds(processBatch(FM_A, ESTAB_A, 'h1', ['jp1', 'jp2']));
  assert.strictEqual((await readPayment('jp2')).handoverStatus, 'validated');
});

test('🔒 autre Floor Manager, gérante ou serveur ne valident pas une remise Floor Manager', async () => {
  await seedHandoverWorld();
  await fmHandoverBatch(SRV_A1, ESTAB_A, 'h1', ['jp1']);
  await assertFails(processBatch(FM_A2, ESTAB_A, 'h1', ['jp1']));
  await assertFails(processBatch(GERANTE_A, ESTAB_A, 'h1', ['jp1']));
  await assertFails(processBatch(SRV_A1, ESTAB_A, 'h1', ['jp1']));
  await assertFails(processBatch(FM_A, ESTAB_A, 'h1', ['jp1'], false, { receivedByManagerId: GERANTE_A }));
  // Le Floor Manager ne valide pas une remise du circuit gérante.
  await assertFails(processBatch(FM_A, ESTAB_A, 'handover1', ['payment1']));
});

test('🔒 remise validée : champs financiers figés, plus de rejet ni de retour arrière', async () => {
  await seedHandoverWorld();
  await fmHandoverBatch(SRV_A1, ESTAB_A, 'h1', ['jp1']);
  await processBatch(FM_A, ESTAB_A, 'h1', ['jp1']);
  const fm = asUser(FM_A);
  await assertFails(updateDoc(hoRef(fm, ESTAB_A, 'h1'), { validatedAmount: 1, updatedAt: serverTimestamp() }));
  await assertFails(processBatch(FM_A, ESTAB_A, 'h1', ['jp1'], true));
  await assertFails(updateDoc(payRef(fm, ESTAB_A, 'jp1'), { handoverStatus: 'pending', handoverId: null }));
  await assertFails(updateDoc(hoRef(asUser(GERANTE_A), ESTAB_A, 'h1'), { status: 'pending' }));
  await assertFails(deleteDoc(hoRef(asUser(GERANTE_A), ESTAB_A, 'h1')));
});

test('🔒 remise ouverte : paiements, montant déclaré, émetteur et service figés', async () => {
  await seedHandoverWorld();
  await fmHandoverBatch(SRV_A1, ESTAB_A, 'h1', ['jp1']);
  const fm = asUser(FM_A);
  const base = { status: 'partially_validated', receivedByManagerId: FM_A };
  // Contrôle : la même écriture sans champ interdit passe.
  for (const change of [
    { declaredAmount: 1 }, { paymentIds: ['jp1', 'jp2'] }, { serveurId: SRV_A3 },
    { senderUserId: SRV_A3 }, { shiftId: 'shA2' }, { receiverUserId: FM_A2 },
  ]) {
    const bad = writeBatch(fm);
    bad.update(hoRef(fm, ESTAB_A, 'h1'), { ...base, ...change });
    bad.update(shiftRef(fm, ESTAB_A, 'sh1'), { financialRevision: increment(1) });
    await assertFails(bad.commit());
  }
  await assertFails(updateDoc(hoRef(asUser(SRV_A1), ESTAB_A, 'h1'), { declaredAmount: 1 }));
  // 13B : la même écriture passe avec l'incrément du compteur du service.
  const ok = writeBatch(fm);
  ok.update(hoRef(fm, ESTAB_A, 'h1'), base);
  ok.update(shiftRef(fm, ESTAB_A, 'sh1'), { financialRevision: increment(1) });
  await assertSucceeds(ok.commit());
});

test('✅ remise rejetée : les paiements redeviennent à remettre, puis remise à nouveau', async () => {
  await seedHandoverWorld();
  await fmHandoverBatch(SRV_A1, ESTAB_A, 'h1', ['jp1']);
  await assertSucceeds(processBatch(FM_A, ESTAB_A, 'h1', ['jp1'], true));
  const p = await readPayment('jp1');
  assert.strictEqual(p.handoverStatus, 'pending');
  assert.strictEqual(p.handoverId, null);
  await assertSucceeds(fmHandoverBatch(SRV_A1, ESTAB_A, 'h2', ['jp1']));
});

// ── Service clôturé / serveur retiré ──
test('✅ service clôturé : la remise et sa validation restent possibles', async () => {
  await seedHandoverWorld();
  await closeShift(GERANTE_A, ESTAB_A, 'sh1');
  await assertSucceeds(getDoc(shiftRef(asUser(SRV_A1), ESTAB_A, 'sh1')));
  await assertSucceeds(fmHandoverBatch(SRV_A1, ESTAB_A, 'c1', ['jp1', 'jp2']));
  await assertSucceeds(processBatch(FM_A, ESTAB_A, 'c1', ['jp1', 'jp2']));
});

test('✅ serveur retiré du service : il remet quand même ce qu’il a encaissé', async () => {
  await seedHandoverWorld();
  const g = asUser(GERANTE_A);
  const batch = writeBatch(g);
  batch.update(shiftRef(g, ESTAB_A, 'sh1'), { serverIds: [], updatedAt: serverTimestamp() });
  batch.set(participantRef(g, ESTAB_A, 'sh1', SRV_A1), participantData(ESTAB_A, 'sh1', SRV_A1, GERANTE_A, false));
  await assertSucceeds(batch.commit());
  await assertSucceeds(getDoc(shiftRef(asUser(SRV_A1), ESTAB_A, 'sh1')));
  await assertSucceeds(fmHandoverBatch(SRV_A1, ESTAB_A, 'r1', ['jp1']));
  // Un serveur jamais affecté à ce service : ni lecture, ni remise.
  await assertFails(getDoc(shiftRef(asUser(SRV_A2), ESTAB_A, 'sh1')));
});

// ─────────── 12B : REMISES FLOOR MANAGER -> GÉRANTE ───────────

const GERANTE_A2 = 'geranteA2';
const fmtId = (shiftId, fm, seq) => `fmt_${shiftId}_${fm}_${seq}`;

// sh1 : Floor Manager FM_A, créé par GERANTE_A. Paul détient 12 000
// (encaissement direct) + 20 000 (remise de Jean validée).
async function seedTransferWorld() {
  await seedHandoverWorld();
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'users', GERANTE_A2), { role: 'gerante', establishmentId: ESTAB_A });
    await setDoc(payRef(db, ESTAB_A, 'jv'), shiftPayment(SRV_A1, 20000, { handoverStatus: 'validated', handoverId: 'hx' }));
    // Service clôturé créé par le propriétaire (caisse centrale).
    await setDoc(shiftRef(db, ESTAB_A, 'shOwner'), {
      ...shiftData(ESTAB_A, FM_A, [], PROPRIETAIRE_A), status: 'closed',
      createdAt: new Date(), updatedAt: new Date(),
    });
    // Service (incohérent) créé par la comptable : pas un destinataire.
    await setDoc(shiftRef(db, ESTAB_A, 'shCompta'), {
      ...shiftData(ESTAB_A, FM_A, [], COMPTABLE_A), status: 'closed',
      createdAt: new Date(), updatedAt: new Date(),
    });
  });
}

function transferData(uid, seq, over = {}) {
  const shiftId = over.shiftId ?? 'sh1';
  return {
    establishmentId: ESTAB_A, serveurId: uid, serveurName: uid,
    declaredAmount: 10000, amount: 10000, validatedAmount: null, status: 'pending',
    receivedByManagerId: null, receivedByManagerName: null,
    paymentIds: [], validatedPaymentIds: [], rejectedPaymentIds: [],
    shiftId, senderUserId: uid, senderUserName: uid, senderRole: 'floor_manager',
    receiverUserId: GERANTE_A, receiverUserName: 'Awa', receiverRole: 'gerante',
    paymentBreakdown: { cash: 7000, mobile_money: 3000 }, transferSequence: seq,
    comment: '', createdBy: uid, createdAt: serverTimestamp(), updatedAt: serverTimestamp(),
    validatedAt: null, validatedBy: null, physicalAmount: null, difference: null,
    rejectedAt: null, rejectedBy: null, rejectedByName: null, decisionComment: null,
    pendingSync: false, syncError: false,
    ...over,
  };
}

// Même écriture que ShiftHandoverService.transferToReceiver.
function sendTransfer(uid, seq, over = {}, { e = ESTAB_A, id, bump = true } = {}) {
  const data = transferData(uid, seq, over);
  const db = asUser(uid);
  const batch = writeBatch(db);
  batch.set(hoRef(db, e, id ?? fmtId(data.shiftId, uid, seq)), data);
  if (bump) batch.update(shiftRef(db, e, data.shiftId), { financialRevision: increment(1) });
  return batch.commit();
}

// Même écriture que ShiftHandoverService.validateTransfer.
function validateTransfer(uid, id, physical = 10000, over = {}, bump = true) {
  const db = asUser(uid);
  const batch = writeBatch(db);
  if (bump) batch.update(shiftRef(db, ESTAB_A, 'sh1'), { financialRevision: increment(1) });
  batch.update(hoRef(db, ESTAB_A, id), {
    status: 'validated', validatedAmount: 10000, physicalAmount: physical,
    difference: physical - 10000, validatedBy: uid, receivedByManagerId: uid,
    receivedByManagerName: uid, validatedAt: serverTimestamp(), decisionComment: '',
    updatedAt: serverTimestamp(),
    ...over,
  });
  return batch.commit();
}

function rejectTransfer(uid, id, over = {}, bump = true) {
  const db = asUser(uid);
  const batch = writeBatch(db);
  if (bump) batch.update(shiftRef(db, ESTAB_A, 'sh1'), { financialRevision: increment(1) });
  batch.update(hoRef(db, ESTAB_A, id), {
    status: 'rejected', rejectedBy: uid, rejectedByName: uid,
    rejectedAt: serverTimestamp(), decisionComment: 'manque', updatedAt: serverTimestamp(),
    ...over,
  });
  return batch.commit();
}

// ── Création ──
test('✅ Floor Manager : remises partielles successives à la gérante du service', async () => {
  await seedTransferWorld();
  await assertSucceeds(sendTransfer(FM_A, 0));
  await assertSucceeds(sendTransfer(FM_A, 1, { declaredAmount: 5000, amount: 5000, paymentBreakdown: { cash: 5000 } }));
  // Ni le paiement client ni la remise serveur ne sont modifiés.
  assert.strictEqual((await readPayment('fmp')).handoverStatus, 'pending');
});

test('✅ service créé par le propriétaire : remise à la caisse centrale (propriétaire)', async () => {
  await seedTransferWorld();
  await assertSucceeds(sendTransfer(FM_A, 0, {
    shiftId: 'shOwner', receiverUserId: PROPRIETAIRE_A, receiverRole: 'proprietaire',
  }));
});

test('🔒 double remise : même rang refusé, rang sauté ou identifiant libre refusés', async () => {
  await seedTransferWorld();
  await assertSucceeds(sendTransfer(FM_A, 0));
  await assertFails(sendTransfer(FM_A, 0));
  await assertFails(sendTransfer(FM_A, 2));
  await assertFails(sendTransfer(FM_A, 1, {}, { id: 'libre' }));
  await assertFails(sendTransfer(FM_A, 1, {}, { id: fmtId('sh1', FM_A, 5) }));
});

test('🔒 destinataire imposé : ni autre gérante, ni autre établissement, ni autre rôle', async () => {
  await seedTransferWorld();
  await assertFails(sendTransfer(FM_A, 0, { receiverUserId: GERANTE_A2 }));
  await assertFails(sendTransfer(FM_A, 0, { receiverUserId: 'geranteB' }));
  await assertFails(sendTransfer(FM_A, 0, { receiverUserId: COMPTABLE_A, receiverRole: 'comptable' }));
  await assertFails(sendTransfer(FM_A, 0, { receiverRole: 'proprietaire' }));
  await assertFails(sendTransfer(FM_A, 0, { receiverUserId: SRV_A1, receiverRole: 'serveur' }));
  // Même le créateur du service, s'il n'est ni gérante ni propriétaire.
  await assertFails(sendTransfer(FM_A, 0, {
    shiftId: 'shCompta', receiverUserId: COMPTABLE_A, receiverRole: 'comptable',
  }));
});

test('🔒 émetteur : autre Floor Manager, autre établissement, serveur ou gérante', async () => {
  await seedTransferWorld();
  // FM_A2 n'est pas le Floor Manager de sh1.
  await assertFails(sendTransfer(FM_A2, 0));
  await assertFails(sendTransfer(FM_A2, 0, { senderUserId: FM_A, serveurId: FM_A, createdBy: FM_A }, { id: fmtId('sh1', FM_A, 0) }));
  await assertFails(sendTransfer(FM_B, 0, { establishmentId: ESTAB_B }, { e: ESTAB_B }));
  await assertFails(sendTransfer(FM_A, 0, { establishmentId: ESTAB_B }, { e: ESTAB_B }));
  await assertFails(sendTransfer(SRV_A1, 0));
  // La gérante ne fabrique pas une remise de Floor Manager (circuit historique).
  await assertFails(setDoc(hoRef(asUser(GERANTE_A), ESTAB_A, fmtId('sh1', FM_A, 0)), transferData(FM_A, 0)));
});

test('🔒 montant incohérent ou champs de décision pré-remplis', async () => {
  await seedTransferWorld();
  for (const over of [
    { paymentBreakdown: { cash: 9000 } },
    { amount: 9000 },
    { paymentBreakdown: { cash: 11000, mobile_money: -1000 } },
    { paymentBreakdown: { cash: 7000, bitcoin: 3000 } },
    { paymentBreakdown: { cash: 10000, bitcoin: 3000 } },
    { declaredAmount: 0, amount: 0, paymentBreakdown: {} },
    { status: 'validated' },
    { physicalAmount: 10000 },
    { validatedAmount: 10000 },
    { paymentIds: ['fmp'] },
    { transferSequence: -1 },
    { extra: true },
  ]) {
    await assertFails(sendTransfer(FM_A, 0, over));
  }
});

// ── Lecture ──
test('✅🔒 lecture : émetteur, gérante, comptabilité ; ni autres rôles ni autre tenant', async () => {
  await seedTransferWorld();
  await sendTransfer(FM_A, 0);
  const id = fmtId('sh1', FM_A, 0);
  await assertSucceeds(getDoc(hoRef(asUser(FM_A), ESTAB_A, id)));
  await assertSucceeds(getDocs(query(
    collection(asUser(FM_A), 'establishments', ESTAB_A, 'serverHandovers'),
    where('senderUserId', '==', FM_A),
  )));
  await assertSucceeds(getDoc(hoRef(asUser(GERANTE_A), ESTAB_A, id)));
  await assertSucceeds(getDoc(hoRef(asUser(COMPTABLE_A), ESTAB_A, id)));
  await assertFails(getDoc(hoRef(asUser(FM_A2), ESTAB_A, id)));
  await assertFails(getDoc(hoRef(asUser(SRV_A1), ESTAB_A, id)));
  await assertFails(getDoc(hoRef(asUser('barmanA'), ESTAB_A, id)));
  await assertFails(getDoc(hoRef(asUser('geranteB'), ESTAB_A, id)));
  // Non-régression : un serveur lit toujours ses remises, un barman une
  // remise historique.
  await assertSucceeds(getDocs(query(
    collection(asUser(SERVEUR_A), 'establishments', ESTAB_A, 'serverHandovers'),
    where('serveurId', '==', SERVEUR_A),
  )));
  await assertSucceeds(getDoc(hoRef(asUser('barmanA'), ESTAB_A, 'handover1')));
});

// ── Validation / rejet ──
test('✅ la gérante destinataire valide avec le montant compté et l’écart', async () => {
  await seedTransferWorld();
  await sendTransfer(FM_A, 0);
  await assertSucceeds(validateTransfer(GERANTE_A, fmtId('sh1', FM_A, 0), 9500));
});

test('🔒 validation : autre gérante, autre tenant, Floor Manager, montant ou écart falsifié', async () => {
  await seedTransferWorld();
  await sendTransfer(FM_A, 0);
  const id = fmtId('sh1', FM_A, 0);
  await assertFails(validateTransfer(GERANTE_A2, id));
  await assertFails(validateTransfer('geranteB', id));
  await assertFails(validateTransfer(FM_A, id));
  await assertFails(validateTransfer(COMPTABLE_A, id));
  await assertFails(validateTransfer(GERANTE_A, id, 9500, { difference: 0 }));
  await assertFails(validateTransfer(GERANTE_A, id, 9500, { validatedAmount: 9500 }));
  await assertFails(validateTransfer(GERANTE_A, id, 10000, { declaredAmount: 9000 }));
  await assertFails(validateTransfer(GERANTE_A, id, 10000, { paymentBreakdown: { cash: 10000 } }));
  await assertFails(validateTransfer(GERANTE_A, id, -1));
  await assertFails(validateTransfer(GERANTE_A, id, 10000, { validatedBy: GERANTE_A2 }));
  await assertFails(rejectTransfer(GERANTE_A2, id));
  // Pas par le circuit historique de validation non plus.
  await assertFails(updateDoc(hoRef(asUser(GERANTE_A), ESTAB_A, id), { declaredAmount: 1 }));
});

test('🔒 remise validée : immuable, ni rejet ni suppression', async () => {
  await seedTransferWorld();
  await sendTransfer(FM_A, 0);
  const id = fmtId('sh1', FM_A, 0);
  await validateTransfer(GERANTE_A, id);
  const g = asUser(GERANTE_A);
  await assertFails(rejectTransfer(GERANTE_A, id));
  await assertFails(validateTransfer(GERANTE_A, id, 9000));
  for (const change of [
    { declaredAmount: 1 }, { amount: 1 }, { paymentBreakdown: { cash: 10000 } },
    { senderUserId: FM_A2 }, { receiverUserId: GERANTE_A2 }, { shiftId: 'shA2' },
    { establishmentId: ESTAB_B }, { status: 'pending' }, { physicalAmount: 1 },
  ]) {
    await assertFails(updateDoc(hoRef(g, ESTAB_A, id), change));
  }
  await assertFails(deleteDoc(hoRef(g, ESTAB_A, id)));
  await assertFails(deleteDoc(hoRef(asUser(PROPRIETAIRE_A), ESTAB_A, id)));
  // Suivi du versement en comptabilité (circuit existant) : autorisé.
  await assertSucceeds(updateDoc(hoRef(g, ESTAB_A, id), {
    accountingTransferStatus: 'declared', accountingTransferId: 't1',
  }));
  await assertSucceeds(updateDoc(hoRef(asUser(COMPTABLE_A), ESTAB_A, id), {
    accountingTransferStatus: 'received', updatedAt: serverTimestamp(),
  }));
});

test('✅ remise rejetée : figée, puis nouvelle remise au rang suivant', async () => {
  await seedTransferWorld();
  await sendTransfer(FM_A, 0);
  const id = fmtId('sh1', FM_A, 0);
  await assertSucceeds(rejectTransfer(GERANTE_A, id));
  await assertFails(validateTransfer(GERANTE_A, id));
  await assertFails(rejectTransfer(GERANTE_A, id, { decisionComment: 'autre' }));
  await assertSucceeds(sendTransfer(FM_A, 1));
});

test('🔒 remise en attente : ni avant accord ni annulation par le Floor Manager', async () => {
  await seedTransferWorld();
  await sendTransfer(FM_A, 0);
  const id = fmtId('sh1', FM_A, 0);
  await assertFails(updateDoc(hoRef(asUser(FM_A), ESTAB_A, id), { declaredAmount: 20000, amount: 20000 }));
  await assertFails(deleteDoc(hoRef(asUser(FM_A), ESTAB_A, id)));
  await assertFails(updateDoc(hoRef(asUser(GERANTE_A), ESTAB_A, id), {
    accountingTransferStatus: 'declared', accountingTransferId: 't1',
  }));
});

// ── Service clôturé ──
test('✅ service clôturé : remise et validation possibles, aucune nouvelle vente', async () => {
  await seedTransferWorld();
  await closeShift(GERANTE_A, ESTAB_A, 'sh1');
  await assertFails(payBatch(FM_A, ESTAB_A, 'late', ['paul1'], { responsibleServerId: FM_A }));
  await assertSucceeds(sendTransfer(FM_A, 0));
  await assertSucceeds(validateTransfer(GERANTE_A, fmtId('sh1', FM_A, 0)));
});

// ── Rapprochement ──
test('✅🔒 rapprochement du service dans accountClosures : gérante oui, Floor Manager non', async () => {
  await seedTransferWorld();
  const closure = {
    establishmentId: ESTAB_A, scope: 'shift', accountType: 'shift', shiftId: 'sh1',
    floorManagerId: FM_A, theoreticalAmount: 62000, physicalAmount: 60000, difference: -2000,
    validatedById: GERANTE_A, validatedByName: 'Awa', comment: '', date: serverTimestamp(),
    createdAt: serverTimestamp(), pendingSync: false, syncError: false,
  };
  await assertSucceeds(setDoc(doc(asUser(GERANTE_A), 'establishments', ESTAB_A, 'accountClosures', 'r1'), closure));
  await assertFails(setDoc(doc(asUser(FM_A), 'establishments', ESTAB_A, 'accountClosures', 'r2'), closure));
  await assertFails(getDoc(doc(asUser(FM_A), 'establishments', ESTAB_A, 'accountClosures', 'r1')));
});

// ── Service : créateur ──
test('🔒 service : le rôle du créateur ne peut pas être falsifié ni modifié', async () => {
  await seedShiftWorld();
  await assertFails(createShiftBatch(GERANTE_A, ESTAB_A, 'c1', FM_A, [SRV_A1], { createdByRole: 'proprietaire' }));
  await assertSucceeds(createShiftBatch(GERANTE_A, ESTAB_A, 'c2', FM_A, [SRV_A1], { createdByRole: 'gerante', createdByName: 'Awa' }));
  await assertFails(updateDoc(shiftRef(asUser(GERANTE_A), ESTAB_A, 'c2'), { createdByRole: 'proprietaire', updatedAt: serverTimestamp() }));
});

// ─────────── 13B : CLÔTURE FINANCIÈRE DU SERVICE ───────────

const discRef = (db, e, id) => doc(db, 'establishments', e, 'shiftDiscrepancies', id);

// Même écriture que ShiftClosureService.closeFinancially (dans sa transaction).
function closeFinancially(uid, over = {}, { e = ESTAB_A, shiftId = 'sh1' } = {}) {
  return updateDoc(shiftRef(asUser(uid), e, shiftId), {
    financialStatus: 'reconciled', financialClosedAt: serverTimestamp(),
    financialClosedBy: uid, financialClosedByName: uid,
    financialSummary: { theoreticalAmount: 62000, difference: 0 },
    updatedAt: serverTimestamp(),
    ...over,
  });
}

function discrepancyData(uid, over = {}) {
  return {
    establishmentId: ESTAB_A, shiftId: 'sh1',
    subjectUserId: SRV_A1, subjectName: 'Jean', subjectRole: 'serveur',
    expectedAmount: 5000, physicalAmount: 0, difference: -5000, reason: 'billet manquant',
    recordedBy: uid, recordedByName: uid, recordedByRole: 'floor_manager',
    recordedAt: serverTimestamp(), status: 'pending',
    approvedBy: null, approvedAt: null, rejectedBy: null, rejectedAt: null,
    decidedByName: null, decisionComment: null,
    ...over,
  };
}

// Même lot que ShiftClosureService.declareDiscrepancy.
function declareDiscrepancy(uid, id, over = {}, bump = true) {
  const db = asUser(uid);
  const batch = writeBatch(db);
  const data = discrepancyData(uid, over);
  batch.set(discRef(db, ESTAB_A, id), data);
  if (bump) batch.update(shiftRef(db, ESTAB_A, data.shiftId), { financialRevision: increment(1) });
  return batch.commit();
}

// Même lot que ShiftClosureService.decideDiscrepancy.
function decideDiscrepancy(uid, id, approve = true, over = {}, bump = true) {
  const db = asUser(uid);
  const batch = writeBatch(db);
  batch.update(discRef(db, ESTAB_A, id), {
    status: approve ? 'approved' : 'rejected',
    ...(approve
      ? { approvedBy: uid, approvedAt: serverTimestamp() }
      : { rejectedBy: uid, rejectedAt: serverTimestamp() }),
    decidedByName: uid, decisionComment: '',
    ...over,
  });
  if (bump) batch.update(shiftRef(db, ESTAB_A, 'sh1'), { financialRevision: increment(1) });
  return batch.commit();
}

async function readShift(id = 'sh1') {
  let data;
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    data = (await getDoc(shiftRef(ctx.firestore(), ESTAB_A, id))).data();
  });
  return data;
}

// ── Clôture ──
test('🔒 service en cours : pas de clôture financière', async () => {
  await seedTransferWorld();
  await assertFails(closeFinancially(GERANTE_A));
});

test('✅ service terminé : la gérante clôture une seule fois, montants figés', async () => {
  await seedTransferWorld();
  await closeShift(GERANTE_A, ESTAB_A, 'sh1');
  await assertSucceeds(closeFinancially(GERANTE_A));
  const s = await readShift();
  assert.strictEqual(s.status, 'closed');
  assert.strictEqual(s.financialStatus, 'reconciled');
  // Double clôture : refusée.
  await assertFails(closeFinancially(GERANTE_A));
  await assertFails(closeFinancially(PROPRIETAIRE_A));
});

test('🔒 clôture : ni Floor Manager, ni serveur, ni comptable, ni autre établissement', async () => {
  await seedTransferWorld();
  await closeShift(GERANTE_A, ESTAB_A, 'sh1');
  for (const uid of [FM_A, SRV_A1, COMPTABLE_A, 'geranteB', 'barmanA']) {
    await assertFails(closeFinancially(uid));
  }
  // Le propriétaire (caisse centrale) peut clôturer.
  await assertSucceeds(closeFinancially(PROPRIETAIRE_A));
});

test('🔒 clôture falsifiée : auteur, date, compteur ou champs hors clôture', async () => {
  await seedTransferWorld();
  await closeShift(GERANTE_A, ESTAB_A, 'sh1');
  await assertFails(closeFinancially(GERANTE_A, { financialClosedBy: GERANTE_A2 }));
  await assertFails(closeFinancially(GERANTE_A, { financialClosedAt: new Date('2026-01-01') }));
  await assertFails(closeFinancially(GERANTE_A, { financialRevision: 99 }));
  await assertFails(closeFinancially(GERANTE_A, { status: 'open' }));
  await assertFails(closeFinancially(GERANTE_A, { financialSummary: 'ok' }));
  await assertFails(closeFinancially(GERANTE_A, { financialStatus: 'ready' }));
});

test('🔒 après clôture : rien ne bouge (montants, réouverture, remises, écarts, affectations)', async () => {
  await seedTransferWorld();
  await sendTransfer(FM_A, 0);
  await fmHandoverBatch(SRV_A1, ESTAB_A, 'h1', ['jp1']);
  await declareDiscrepancy(FM_A, 'd1');
  await closeShift(GERANTE_A, ESTAB_A, 'sh1');
  await assertSucceeds(closeFinancially(GERANTE_A));

  const g = asUser(GERANTE_A);
  await assertFails(updateDoc(shiftRef(g, ESTAB_A, 'sh1'), { financialSummary: { theoreticalAmount: 1 } }));
  await assertFails(updateDoc(shiftRef(g, ESTAB_A, 'sh1'), { financialStatus: 'pending' }));
  await assertFails(openShiftBatch(GERANTE_A, ESTAB_A, 'sh1', FM_A, [SRV_A1], { serverPointers: [] }));
  await assertFails(updateDoc(shiftRef(g, ESTAB_A, 'sh1'), { financialRevision: increment(1) }));
  // Aucun nouvel événement financier.
  await assertFails(sendTransfer(FM_A, 1));
  await assertFails(validateTransfer(GERANTE_A, fmtId('sh1', FM_A, 0)));
  await assertFails(fmHandoverBatch(SRV_A1, ESTAB_A, 'h2', ['jp2']));
  await assertFails(processBatch(FM_A, ESTAB_A, 'h1', ['jp1']));
  await assertFails(declareDiscrepancy(FM_A, 'd2'));
  await assertFails(decideDiscrepancy(GERANTE_A, 'd1'));
  // Aucune nouvelle participation.
  await assertFails(setDoc(participantRef(g, ESTAB_A, 'sh1', SRV_A2), participantData(ESTAB_A, 'sh1', SRV_A2, GERANTE_A, false)));
});

test('✅ ancien service sans champs financiers : lisible, « à rapprocher », clôturable', async () => {
  await seedTransferWorld();
  const s = await readShift();
  assert.strictEqual(s.financialStatus, undefined);
  await assertSucceeds(getDoc(shiftRef(asUser(GERANTE_A), ESTAB_A, 'sh1')));
  await closeShift(GERANTE_A, ESTAB_A, 'sh1');
  await assertSucceeds(closeFinancially(GERANTE_A));
});

test('🔒 création de service : jamais déjà clôturé financièrement', async () => {
  await seedShiftWorld();
  await assertFails(createShiftBatch(GERANTE_A, ESTAB_A, 'n1', FM_A, [SRV_A1], { financialStatus: 'reconciled' }));
  await assertFails(createShiftBatch(GERANTE_A, ESTAB_A, 'n2', FM_A, [SRV_A1], { financialRevision: 5 }));
  await assertSucceeds(createShiftBatch(GERANTE_A, ESTAB_A, 'n3', FM_A, [SRV_A1]));
});

// ── Compteur d'événements financiers ──
test('🔒 tout événement financier doit faire avancer le compteur du service', async () => {
  await seedTransferWorld();
  await assertFails(fmHandoverBatch(SRV_A1, ESTAB_A, 'h1', ['jp1'], {}, ['jp1'], false));
  await assertFails(sendTransfer(FM_A, 0, {}, { bump: false }));
  await assertSucceeds(sendTransfer(FM_A, 0));
  await assertFails(validateTransfer(GERANTE_A, fmtId('sh1', FM_A, 0), 10000, {}, false));
  await assertFails(rejectTransfer(GERANTE_A, fmtId('sh1', FM_A, 0), {}, false));
  await assertFails(declareDiscrepancy(FM_A, 'd1', {}, false));
  await assertSucceeds(fmHandoverBatch(SRV_A1, ESTAB_A, 'h1', ['jp1']));
  await assertFails(processBatch(FM_A, ESTAB_A, 'h1', ['jp1'], false, {}, null));
});

test('🔒 compteur : +1 seulement, par un acteur du service', async () => {
  await seedTransferWorld();
  const bump = (uid, by = 1) => updateDoc(shiftRef(asUser(uid), ESTAB_A, 'sh1'), { financialRevision: increment(by) });
  for (const uid of ['barmanA', SRV_A2, FM_A2, COMPTABLE_A, 'geranteB']) {
    await assertFails(bump(uid));
  }
  await assertFails(bump(GERANTE_A, 2));
  await assertFails(updateDoc(shiftRef(asUser(FM_A), ESTAB_A, 'sh1'), { financialRevision: increment(1), status: 'closed' }));
  await assertSucceeds(bump(SRV_A1));
  await assertSucceeds(bump(FM_A));
});

test('🔒 concurrence : une remise pendant la clôture fait échouer la clôture', async () => {
  await seedTransferWorld();
  await closeShift(GERANTE_A, ESTAB_A, 'sh1');
  const g = asUser(GERANTE_A);
  const ref = shiftRef(g, ESTAB_A, 'sh1');
  // 1. La gérante lit la situation (compteur r0)...
  const r0 = (await getDoc(ref)).data().financialRevision ?? 0;
  // 2. ... Jean remet ses encaissements au même moment...
  await assertSucceeds(fmHandoverBatch(SRV_A1, ESTAB_A, 'late', ['jp1']));
  // 3. ... la transaction de clôture relit le compteur : il a bougé.
  await assert.rejects(
    runTransaction(g, async (tx) => {
      const snap = await tx.get(ref);
      if ((snap.data().financialRevision ?? 0) !== r0) throw new Error('shiftFinancialChanged');
      tx.update(ref, {
        financialStatus: 'reconciled', financialClosedAt: serverTimestamp(),
        financialClosedBy: GERANTE_A, financialSummary: {}, updatedAt: serverTimestamp(),
      });
    }),
    /shiftFinancialChanged/,
  );
  assert.notStrictEqual((await readShift()).financialStatus, 'reconciled');
});

// ── Écarts ──
test('✅ Floor Manager : déclare un écart sur sa caisse ou celle d’un serveur du service', async () => {
  await seedTransferWorld();
  await assertSucceeds(declareDiscrepancy(FM_A, 'd1'));
  await assertSucceeds(declareDiscrepancy(FM_A, 'd2', {
    subjectUserId: FM_A, subjectName: 'Paul', subjectRole: 'floor_manager',
  }));
  await assertSucceeds(declareDiscrepancy(GERANTE_A, 'd3', { recordedByRole: 'gerante' }));
  // Aucun paiement ni aucune remise n'est modifié.
  assert.strictEqual((await readPayment('jp1')).handoverStatus, 'pending');
});

test('🔒 déclaration d’écart invalide ou hors périmètre', async () => {
  await seedTransferWorld();
  for (const over of [
    { subjectUserId: SRV_A2 },
    { subjectUserId: FM_A2, subjectRole: 'floor_manager' },
    { subjectRole: 'gerante', subjectUserId: GERANTE_A },
    { physicalAmount: 6000, difference: 1000 },
    { difference: 0 },
    { expectedAmount: 0, physicalAmount: 0, difference: 0 },
    { reason: '' },
    { recordedAt: new Date('2026-01-01') },
    { recordedBy: GERANTE_A },
    { recordedByRole: 'gerante' },
    { status: 'approved' },
    { approvedBy: FM_A },
    { establishmentId: ESTAB_B },
    { extra: 1 },
  ]) {
    await assertFails(declareDiscrepancy(FM_A, 'bad', over));
  }
  await assertFails(declareDiscrepancy(FM_A2, 'x1'));
  await assertFails(declareDiscrepancy(SRV_A1, 'x2', { recordedByRole: 'serveur' }));
  await assertFails(declareDiscrepancy('geranteB', 'x3', { recordedByRole: 'gerante' }));
});

test('✅🔒 décision : la gérante seulement ; jamais le Floor Manager sur son propre écart', async () => {
  await seedTransferWorld();
  await declareDiscrepancy(FM_A, 'd1', {
    subjectUserId: FM_A, subjectName: 'Paul', subjectRole: 'floor_manager',
  });
  for (const uid of [FM_A, SRV_A1, COMPTABLE_A, 'geranteB', FM_A2]) {
    await assertFails(decideDiscrepancy(uid, 'd1'));
  }
  await assertFails(decideDiscrepancy(GERANTE_A, 'd1', true, { approvedBy: FM_A }));
  await assertFails(decideDiscrepancy(GERANTE_A, 'd1', true, { expectedAmount: 1 }));
  await assertSucceeds(decideDiscrepancy(GERANTE_A, 'd1'));
  // Décidé : figé, jamais supprimé.
  await assertFails(decideDiscrepancy(GERANTE_A, 'd1', false));
  await assertFails(deleteDoc(discRef(asUser(GERANTE_A), ESTAB_A, 'd1')));
  await assertFails(deleteDoc(discRef(asUser(PROPRIETAIRE_A), ESTAB_A, 'd1')));
});

test('✅ écart rejeté par la gérante', async () => {
  await seedTransferWorld();
  await declareDiscrepancy(FM_A, 'd1');
  await assertSucceeds(decideDiscrepancy(GERANTE_A, 'd1', false));
});

test('✅🔒 lecture des écarts : gérante, Floor Manager du service, serveur concerné', async () => {
  await seedTransferWorld();
  await declareDiscrepancy(FM_A, 'd1');
  const byShift = (uid) => getDocs(query(
    collection(asUser(uid), 'establishments', ESTAB_A, 'shiftDiscrepancies'),
    where('shiftId', '==', 'sh1'),
  ));
  await assertSucceeds(byShift(FM_A));
  await assertSucceeds(byShift(GERANTE_A));
  await assertSucceeds(byShift(COMPTABLE_A));
  await assertFails(byShift(FM_A2));
  await assertFails(byShift('barmanA'));
  await assertFails(byShift('geranteB'));
  await assertSucceeds(getDocs(query(
    collection(asUser(SRV_A1), 'establishments', ESTAB_A, 'shiftDiscrepancies'),
    where('subjectUserId', '==', SRV_A1),
  )));
  await assertFails(byShift(SRV_A1));
  await assertFails(getDoc(discRef(asUser(SRV_A3), ESTAB_A, 'd1')));
});

test('🔒 la mise à jour ordinaire d’un service ne touche pas aux champs financiers', async () => {
  await seedTransferWorld();
  const ref = shiftRef(asUser(GERANTE_A), ESTAB_A, 'sh1');
  await assertFails(updateDoc(ref, { financialStatus: 'reconciled', updatedAt: serverTimestamp() }));
  await assertFails(updateDoc(ref, { financialRevision: 0, updatedAt: serverTimestamp() }));
  await assertFails(updateDoc(ref, { financialSummary: {}, updatedAt: serverTimestamp() }));
  await assertSucceeds(updateDoc(ref, { updatedAt: serverTimestamp() }));
});
