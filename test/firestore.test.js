import { readFileSync } from 'node:fs';
import { test, before, after, beforeEach } from 'node:test';
import assert from 'node:assert';
import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} from '@firebase/rules-unit-testing';
import {
  doc, getDoc, setDoc, deleteDoc,
} from 'firebase/firestore';

let testEnv;

// Identifiants des deux tenants
const ESTAB_A = 'estabA';
const ESTAB_B = 'estabB';

// UIDs
const SERVEUR_A = 'serveurA';
const SERVEUR_B = 'serveurB';
const GERANTE_A = 'geranteA';
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
    await setDoc(doc(db, 'users', GLOBAL_ADMIN), { role: 'global_admin', establishmentId: '' });

    // Une commande dans chaque établissement
    await setDoc(doc(db, 'establishments', ESTAB_A, 'orders', 'order1'), { total: 1000 });
    await setDoc(doc(db, 'establishments', ESTAB_B, 'orders', 'order1'), { total: 2000 });

    // Une clôture de caisse dans A (pour tester le raffinement par rôle)
    await setDoc(doc(db, 'establishments', ESTAB_A, 'accountClosures', 'clo1'), { validated: true });

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