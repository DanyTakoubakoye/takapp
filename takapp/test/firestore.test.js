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