// Checks firestore.rules against the Firestore emulator.
// Run from this folder: npm install, then npm test
import { after, before, beforeEach, describe, test } from 'node:test';
import { readFileSync } from 'node:fs';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
  writeBatch,
} from 'firebase/firestore';

const ADMIN_EMAIL = 'arafat.mahmud.2001@gmail.com';

let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-expensetracker',
    firestore: {
      host: '127.0.0.1',
      port: 8181,
      rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8'),
    },
  });
});

after(() => env.cleanup());
beforeEach(() => env.clearFirestore());

// Firestore as a signed-in user
const as = (uid, email, emailVerified = true) =>
  env.authenticatedContext(uid, { email, email_verified: emailVerified }).firestore();

const alice = () => as('alice', 'alice@example.com');
const bob = () => as('bob', 'bob@example.com');
const admin = () => as('admin', ADMIN_EMAIL);

// Writes that bypass the rules, to set up each case
const seed = (fn) => env.withSecurityRulesDisabled((ctx) => fn(ctx.firestore()));
const seedAccount = (uid, status) =>
  seed((db) =>
    setDoc(doc(db, `accounts/${uid}`), {
      email: `${uid}@example.com`,
      displayName: uid,
      photoUrl: null,
      status,
      createdAt: new Date(),
    }),
  );
const seedConfig = (data) => seed((db) => setDoc(doc(db, 'config/app'), data));

const registration = (email, status = 'pending', extra = {}) => ({
  email,
  displayName: 'Alice',
  photoUrl: null,
  status,
  createdAt: serverTimestamp(),
  ...extra,
});

const expense = { id: 'e1', title: 'Tea', amount: 20, updatedAt: serverTimestamp() };

describe('signed-out visitors', () => {
  test('cannot read anything', async () => {
    const db = env.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(db, 'config/app')));
    await assertFails(getDoc(doc(db, 'accounts/alice')));
    await assertFails(getDoc(doc(db, 'users/alice/expenses/e1')));
  });
});

describe('registration', () => {
  test('a new user registers as pending', async () => {
    await assertSucceeds(
      setDoc(doc(alice(), 'accounts/alice'), registration('alice@example.com')),
    );
  });

  test('cannot approve themselves while approval is required', async () => {
    await assertFails(
      setDoc(doc(alice(), 'accounts/alice'), registration('alice@example.com', 'approved')),
    );
    await seedConfig({ requireApproval: true });
    await assertFails(
      setDoc(doc(alice(), 'accounts/alice'), registration('alice@example.com', 'approved')),
    );
  });

  test('is approved at once while the admin has switched approval off', async () => {
    await seedConfig({ requireApproval: false });
    await assertSucceeds(
      setDoc(doc(alice(), 'accounts/alice'), registration('alice@example.com', 'approved')),
    );
  });

  test('cannot register as blocked-proof or forged accounts', async () => {
    // someone else's account
    await assertFails(
      setDoc(doc(alice(), 'accounts/bob'), registration('alice@example.com')),
    );
    // an email that is not theirs
    await assertFails(
      setDoc(doc(alice(), 'accounts/alice'), registration('boss@example.com')),
    );
    // extra fields such as per-user feature overrides
    await assertFails(
      setDoc(
        doc(alice(), 'accounts/alice'),
        registration('alice@example.com', 'pending', { features: { savings: true } }),
      ),
    );
    // a back-dated creation time
    await assertFails(
      setDoc(
        doc(alice(), 'accounts/alice'),
        registration('alice@example.com', 'pending', { createdAt: new Date(2020, 0, 1) }),
      ),
    );
  });

  test('cannot register again over an existing account', async () => {
    await seedAccount('alice', 'blocked');
    await assertFails(
      setDoc(doc(alice(), 'accounts/alice'), registration('alice@example.com')),
    );
  });

  test('users read their own account but cannot change it', async () => {
    await seedAccount('alice', 'pending');
    await assertSucceeds(getDoc(doc(alice(), 'accounts/alice')));
    await assertFails(updateDoc(doc(alice(), 'accounts/alice'), { status: 'approved' }));
    await assertFails(updateDoc(doc(alice(), 'accounts/alice'), { displayName: 'A' }));
    await assertFails(deleteDoc(doc(alice(), 'accounts/alice')));
  });
});

describe("a user's own data", () => {
  for (const status of ['pending', 'blocked']) {
    test(`is closed while the account is ${status}`, async () => {
      await seedAccount('alice', status);
      await assertFails(setDoc(doc(alice(), 'users/alice/expenses/e1'), expense));
      await assertFails(getDoc(doc(alice(), 'users/alice/expenses/e1')));
      await assertFails(getDocs(collection(alice(), 'users/alice/expenses')));
      await assertFails(setDoc(doc(alice(), 'users/alice'), { monthlyBudget: 1000 }));
    });
  }

  test('is closed without any account', async () => {
    await assertFails(setDoc(doc(alice(), 'users/alice/expenses/e1'), expense));
  });

  test('is open once approved: every collection, reads, queries and batches', async () => {
    await seedAccount('alice', 'approved');
    const db = alice();
    await assertSucceeds(setDoc(doc(db, 'users/alice/expenses/e1'), expense));
    await assertSucceeds(getDoc(doc(db, 'users/alice/expenses/e1')));
    await assertSucceeds(getDocs(collection(db, 'users/alice/expenses')));
    await assertSucceeds(setDoc(doc(db, 'users/alice'), { monthlyBudget: 1000 }));
    await assertSucceeds(setDoc(doc(db, 'users/alice/deposit_profiles/p1'), { name: 'Goal' }));
    await assertSucceeds(setDoc(doc(db, 'users/alice/deposit_transactions/t1'), { amount: 5 }));

    // A sync batch: several writes, one approval check
    const batch = writeBatch(db);
    batch.set(doc(db, 'users/alice/expenses/e2'), expense);
    batch.set(doc(db, 'users/alice/expenses/e3'), expense);
    batch.set(doc(db, 'users/alice/expenses/e1'), { id: 'e1', deleted: true });
    await assertSucceeds(batch.commit());
  });

  test('covers every path the console rules allowed before approval was added', async () => {
    const paths = [
      'users/alice',
      'users/alice/expenses/e1',
      'users/alice/expenses_by_date/2026-10-28',
      'users/alice/expenses_by_date/2026-10-28/items/e1',
      'users/alice/deposit_profiles/p1',
      'users/alice/deposit_transactions/t1',
    ];
    await seedAccount('alice', 'approved');
    for (const path of paths) {
      await assertSucceeds(setDoc(doc(alice(), path), { a: 1 }));
      await assertSucceeds(getDoc(doc(alice(), path)));
      await assertSucceeds(deleteDoc(doc(alice(), path)));
    }
    await seedAccount('alice', 'pending');
    for (const path of paths) {
      await assertFails(setDoc(doc(alice(), path), { a: 1 }));
      await assertFails(getDoc(doc(alice(), path)));
    }
  });

  // Rules allow 20 document lookups per batch. A 450-write sync batch only
  // passes because every write looks up the same account document, which
  // is counted (and billed) once.
  test('full 450-write sync batches pass the approval check', async () => {
    await seedAccount('alice', 'approved');
    const db = alice();
    const writes = writeBatch(db);
    for (let i = 0; i < 450; i++) writes.set(doc(db, `users/alice/expenses/e${i}`), expense);
    await assertSucceeds(writes.commit());

    const deletes = writeBatch(db);
    for (let i = 0; i < 450; i++) deletes.delete(doc(db, `users/alice/expenses/e${i}`));
    await assertSucceeds(deletes.commit());
  });

  test("never includes someone else's data", async () => {
    await seedAccount('alice', 'approved');
    await seedAccount('bob', 'approved');
    await seed((db) => setDoc(doc(db, 'users/bob/expenses/e1'), expense));
    await assertFails(getDoc(doc(alice(), 'users/bob/expenses/e1')));
    await assertFails(setDoc(doc(alice(), 'users/bob/expenses/e2'), expense));
    await assertFails(getDoc(doc(alice(), 'accounts/bob')));
  });
});

describe('admins', () => {
  test('list, approve and block accounts, and change the app config', async () => {
    await seedAccount('alice', 'pending');
    const db = admin();
    await assertSucceeds(
      getDocs(query(collection(db, 'accounts'), where('status', '==', 'pending'))),
    );
    await assertSucceeds(updateDoc(doc(db, 'accounts/alice'), { status: 'approved' }));
    await assertSucceeds(
      updateDoc(doc(db, 'accounts/alice'), {
        status: 'blocked',
        blockedReason: 'spam',
        'features.cloudSync': false,
      }),
    );
    await assertSucceeds(
      setDoc(doc(db, 'config/app'), { maintenance: true, features: { savings: false } }, { merge: true }),
    );
  });

  test("cannot read other users' expenses", async () => {
    await seedAccount('alice', 'approved');
    await seed((db) => setDoc(doc(db, 'users/alice/expenses/e1'), expense));
    await assertFails(getDoc(doc(admin(), 'users/alice/expenses/e1')));
  });

  test('use their own data without waiting for approval', async () => {
    await assertSucceeds(setDoc(doc(admin(), 'users/admin/expenses/e1'), expense));
    await assertSucceeds(
      setDoc(doc(admin(), 'accounts/admin'), registration(ADMIN_EMAIL, 'approved')),
    );
  });

  test('are only recognised with a verified email', async () => {
    const impostor = as('mallory', ADMIN_EMAIL, false);
    await assertFails(setDoc(doc(impostor, 'config/app'), { maintenance: true }));
    await assertFails(getDocs(collection(impostor, 'accounts')));
  });
});

describe('everyone else', () => {
  test('cannot manage accounts or the app config', async () => {
    await seedAccount('alice', 'approved');
    await seedAccount('bob', 'pending');
    const db = alice();
    await assertSucceeds(getDoc(doc(db, 'config/app')));
    await assertFails(setDoc(doc(db, 'config/app'), { maintenance: true }));
    await assertFails(getDocs(collection(db, 'accounts')));
    await assertFails(updateDoc(doc(db, 'accounts/bob'), { status: 'approved' }));
  });

  test('cannot touch unknown collections', async () => {
    await seedAccount('alice', 'approved');
    await assertFails(setDoc(doc(alice(), 'other/x'), { a: 1 }));
    await assertFails(setDoc(doc(admin(), 'other/x'), { a: 1 }));
  });
});
