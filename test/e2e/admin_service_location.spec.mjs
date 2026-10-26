import { chromium } from 'playwright';
import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

const baseUrl = 'http://127.0.0.1:4173';
const projectId = process.env.DOJO_E2E_PROJECT_ID;
if (projectId !== 'demo-dojo-platform-b68a3') {
  throw new Error('Refusing to run browser tests unless using demo-dojo-platform-b68a3.');
}

if (!process.env.FIRESTORE_EMULATOR_HOST) {
  throw new Error('Refusing duplicate-record verification without Firestore emulator host.');
}
const adminApp = initializeApp({ projectId }, 'dojo-e2e-record-verification');
const firestore = getFirestore(adminApp);

const browser = await chromium.launch({ headless: true });
const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
page.setDefaultTimeout(15000);
const browserDiagnostics = [];
page.on('pageerror', (error) => browserDiagnostics.push(`PAGEERROR: ${error.message}`));
page.on('console', (message) => { if (message.type() === 'error') browserDiagnostics.push(`CONSOLE: ${message.text()}`); });
page.on('requestfailed', (request) => browserDiagnostics.push(`REQUESTFAILED: ${request.method()} ${request.url()} ${request.failure()?.errorText ?? ''}`));

async function enableFlutterSemantics() {
  // Flutter Web's accessibility opt-in placeholder may be positioned outside
  // the viewport in headless Chromium. Invoke its own DOM click handler rather
  // than asking Playwright to scroll/click an off-screen control.
  const placeholder = page.locator('flt-semantics-placeholder').first();
  if (await placeholder.count()) {
    await placeholder.evaluate((element) => element.click());
    await page.waitForTimeout(500);
    return;
  }
  const enable = page.getByText(/enable accessibility/i).first();
  if (await enable.count()) {
    await enable.evaluate((element) => element.click());
    await page.waitForTimeout(500);
  }
}

async function enterFieldValue(field, value, label) {
  // Flutter Web's semantics input can report a DOM value before the rendered
  // TextField has accepted it. Try fill (which dispatches input events), then
  // keyboard entry; require both the DOM value and a short settle before submit.
  for (const attempt of ['fill', 'keyboard-40', 'keyboard-100']) {
    if (attempt === 'fill') {
      await field.click();
      await field.fill(value);
    } else {
      await field.click();
      await page.keyboard.press('Control+A');
      await field.pressSequentially(value, { delay: attempt === 'keyboard-40' ? 40 : 100 });
    }
    await page.waitForTimeout(300);
    const actual = await field.inputValue();
    if (actual === value) {
      // Let Flutter process the text-editing event before Save is clicked.
      await page.waitForTimeout(300);
      return;
    }
  }
  const actual = await field.inputValue();
  throw new Error(`${label} input mismatch before submit (expected ${value.length} chars, got ${actual.length}).`);
}

async function signIn(email, password) {
  const emailField = page.getByLabel('Admin email');
  const passwordField = page.getByLabel('Password');
  await enterFieldValue(emailField, email, 'Email');
  await enterFieldValue(passwordField, password, 'Password');
  await passwordField.press('Enter');
}

async function chooseDropdown(label, option) {
  await page.getByText(label, { exact: true }).first().click();
  await page.getByText(option, { exact: true }).last().click();
}

try {
  await page.goto(baseUrl, { waitUntil: 'networkidle' });
  await enableFlutterSemantics();
  await page.getByLabel('Admin email').waitFor();

  // Positive authorization: the emulator-only active super_admin can sign in.
  await signIn('e2e-admin@dojo.invalid', 'E2eOnly-Admin-2026!');
  const signInOutcome = await Promise.race([
    page.getByText('Dashboard', { exact: true }).first().waitFor({ timeout: 20000 }).then(() => 'dashboard'),
    page.getByText(/Login nahi ho saka|Email ya password sahi nahi hai|Network connection check|Admin access could not be checked|Is account ko Admin access nahi hai/i).first().waitFor({ timeout: 20000 }).then(() => 'error'),
  ]).catch(() => 'timeout');
  if (signInOutcome !== 'dashboard') {
    const visibleText = await page.locator('body').innerText().catch(() => '(body text unavailable)');
    throw new Error(`Active super_admin did not reach Dashboard (outcome=${signInOutcome}). Visible page text: ${visibleText.slice(0, 2500)}`);
  }

  // Flutter paints this sidebar label in the canvas, but does not expose it as
  // a Playwright text node even after accessibility is enabled. Keep the
  // browser viewport fixed and click the visible Add Location navigation item
  // confirmed by the failure screenshot, rather than retrying a non-existent
  // DOM text locator.
  await page.mouse.click(57, 240);
  // Flutter paints the form title and dropdowns on its canvas; the title is
  // visible in screenshots but is not exposed as a DOM text node. Wait for the
  // rendered form, then open the Country dropdown at its stable viewport spot.
  await page.waitForTimeout(1000);
  await page.mouse.click(700, 335);
  await page.waitForTimeout(400);
  // India is the first country option in the emulator-seeded list. The menu is
  // anchored to the Country field in the fixed 1280x720 viewport.
  await page.mouse.click(220, 335);
  const stateName = `E2E State ${Date.now()}`;
  const stateNameField = page.getByLabel('State / Union Territory name');
  await enterFieldValue(stateNameField, stateName, 'State name');
  await page.getByRole('button', { name: 'Save location' }).click();
  await page.getByText(/Saved successfully\. Record ID:/).waitFor();

  // Duplicate names under the same parent must be rejected by the callable.
  await enterFieldValue(stateNameField, stateName, 'Duplicate State name');
  await page.getByRole('button', { name: 'Save location' }).click();
  // The service catches callable errors and renders a generic inline
  // validation message rather than an AlertDialog. Verify that surface and
  // the HTTP 409 conflict observed from the callable request.
  await page.getByText(/Location save nahi hui\. Input aur backend logs check karein\./).waitFor();
  const conflictObserved = browserDiagnostics.some((entry) => entry.includes('409 (Conflict)'));
  if (!conflictObserved) {
    throw new Error(`Duplicate save showed the generic failure message but no HTTP 409 conflict was captured. Browser diagnostics: ${browserDiagnostics.slice(-20).join(' | ')}`);
  }
  const duplicateSaveCount = (await firestore.collection('service_states').where('name', '==', stateName).get()).size;
  if (duplicateSaveCount !== 1) {
    throw new Error(`Duplicate save changed service_states record count (expected 1, found ${duplicateSaveCount}).`);
  }
  console.log('Verified duplicate-save HTTP 409 and exactly one matching Firestore State record after both attempts.');

  // Sign out and prove the UI denies an inactive super_admin.
  await page.getByRole('button', { name: 'Sign out' }).click();
  // Wait for the auth stream to settle; if Flutter Web keeps the old semantics
  // tree after sign-out, reload the local test app and re-enable semantics.
  await page.waitForTimeout(1000);
  let loginField = page.getByLabel('Admin email');
  if (!(await loginField.isVisible().catch(() => false))) {
    await page.reload({ waitUntil: 'networkidle' });
    await enableFlutterSemantics();
    loginField = page.getByLabel('Admin email');
  }
  await loginField.waitFor({ timeout: 20000 });
  await signIn('e2e-inactive@dojo.invalid', 'E2eOnly-Inactive-2026!');
  await page.getByText(/Is account ko Admin access nahi hai/).waitFor();
  // Authorization denial is the expected terminal state. Do not require the
  // authenticated shell's title: the login/denial screen intentionally has no
  // Admin Control Center heading, and Flutter canvas text is not a DOM node.
  const dashboardVisible = await page.getByText('Dashboard', { exact: true }).first().isVisible().catch(() => false);
  if (dashboardVisible) {
    throw new Error('Inactive admin was denied by message but Dashboard remained visible.');
  }

  // Sign out and verify an active account with a non-privileged role is denied.
  await page.reload({ waitUntil: 'networkidle' });
  await enableFlutterSemantics();
  await page.getByLabel('Admin email').waitFor();
  await signIn('e2e-operator@dojo.invalid', 'E2eOnly-Operator-2026!');
  await page.getByText(/Is account ko Admin access nahi hai/).waitFor();
  const operatorDashboardVisible = await page.getByText('Dashboard', { exact: true }).first().isVisible().catch(() => false);
  if (operatorDashboardVisible) throw new Error('Non-super-admin operator reached Dashboard.');

  // An authenticated user without an admin_users document must also fail closed.
  await page.reload({ waitUntil: 'networkidle' });
  await enableFlutterSemantics();
  await page.getByLabel('Admin email').waitFor();
  await signIn('e2e-missing-admin@dojo.invalid', 'E2eOnly-Missing-2026!');
  await page.getByText(/Is account ko Admin access nahi hai/).waitFor();
  const missingAdminDashboardVisible = await page.getByText('Dashboard', { exact: true }).first().isVisible().catch(() => false);
  if (missingAdminDashboardVisible) throw new Error('User without admin_users record reached Dashboard.');

  console.log('PASS: active super_admin UI login, callable-backed State create/read-back, duplicate rejection (HTTP 409), inactive-admin denial, non-super-admin role denial, and missing-admin-record denial.');
} catch (error) {
  await page.screenshot({ path: '/tmp/admin-location-e2e-failure.png', fullPage: true }).catch(() => {});
  console.error('Admin Service Location browser E2E failed:', error);
  throw error;
} finally {
  await browser.close();
}
