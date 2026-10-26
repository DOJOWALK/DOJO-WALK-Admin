import { initializeApp, cert } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';

const projectId = process.env.DOJO_E2E_PROJECT_ID;
if (projectId !== 'demo-dojo-platform-b68a3') {
  throw new Error('Refusing to seed anything except demo-dojo-platform-b68a3');
}
if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) {
  throw new Error('Firebase Auth and Firestore emulator environment variables are required.');
}

const app = initializeApp({ projectId });
const auth = getAuth(app);
const db = getFirestore(app);
const users = [
  { email: 'e2e-admin@dojo.invalid', password: 'E2eOnly-Admin-2026!', role: 'super_admin', isActive: true },
  { email: 'e2e-inactive@dojo.invalid', password: 'E2eOnly-Inactive-2026!', role: 'super_admin', isActive: false },
  { email: 'e2e-operator@dojo.invalid', password: 'E2eOnly-Operator-2026!', role: 'operator', isActive: true },
];

for (const entry of users) {
  let user;
  try {
    user = await auth.getUserByEmail(entry.email);
  } catch (error) {
    if (error.code !== 'auth/user-not-found') throw error;
    user = await auth.createUser({ email: entry.email, password: entry.password, emailVerified: true });
  }
  await db.collection('admin_users').doc(user.uid).set({
    role: entry.role,
    isActive: entry.isActive,
    displayName: entry.email,
  });
}

await db.collection('service_countries').doc('e2e-india').set({
  name: 'India',
  code: 'IN',
  isActive: true,
});
console.log('Seeded emulator-only admin identities and India catalog record.');
