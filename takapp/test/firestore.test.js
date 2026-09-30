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
    setDoc(doc(db, 'establishments', ESTAB_B, 'orders', 'hack'), { total: 999 })
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
    setDoc(doc(db, 'establishments', ESTAB_A, 'orders', 'order2'), { total: 500 })
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
  await assertFails(setDoc(doc(db, 'establishments', ESTAB_B, 'orders', 'x'), { total: 1 }));
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
  await assertSucceeds(setDoc(doc(asUser(SERVEUR_A), 'establishments', ESTAB_A, 'orders', 'o3'), { total: 5 }));
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
  await assertSucceeds(setDoc(doc(db, 'establishments', ESTAB_A, 'orders', 'o5c'), { total: 1 }));
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
