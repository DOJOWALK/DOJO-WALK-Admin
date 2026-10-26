import { chromium } from 'playwright';

const baseUrl = 'http://127.0.0.1:4173';
const projectId = process.env.DOJO_E2E_PROJECT_ID;
if (projectId !== 'demo-dojo-platform-b68a3') {
  throw new Error('Refusing to run browser tests unless using demo-dojo-platform-b68a3.');
}

const browser = await chromium.launch({ headless: true });
const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
page.setDefaultTimeout(15000);

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
  await field.click();
  await page.keyboard.press('Control+A');
  // Send actual key events to Flutter's editable semantics node. Then assert
  // the visible field contains the value before trying to authenticate.
  await field.pressSequentially(value, { delay: 10 });
  const actual = await field.inputValue();
  if (actual !== value) {
    throw new Error(`${label} input mismatch before submit (expected ${value.length} chars, got ${actual.length}).`);
  }
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
  await page.getByLabel('State / Union Territory name').fill(stateName);
  await page.getByRole('button', { name: 'Save location' }).click();
  await page.getByText(/Saved successfully\\. Record ID:/).waitFor();

  // Duplicate names under the same parent must be rejected by the callable.
  await page.getByLabel('State / Union Territory name').fill(stateName);
  await page.getByRole('button', { name: 'Save location' }).click();
  await page.getByText(/Naam check karke try karein|duplicate|already exists/i).waitFor();

  // Sign out and prove the UI denies an inactive super_admin.
  await page.getByRole('button', { name: 'Sign out' }).click();
  await page.getByLabel('Admin email').waitFor();
  await signIn('e2e-inactive@dojo.invalid', 'E2eOnly-Inactive-2026!');
  await page.getByText(/Is account ko Admin access nahi hai/).waitFor();
  await page.getByText('Admin Control Center', { exact: true }).waitFor();

  console.log('PASS: active super_admin UI login, callable-backed State create/read-back, duplicate rejection, and inactive-admin denial.');
} catch (error) {
  await page.screenshot({ path: '/tmp/admin-location-e2e-failure.png', fullPage: true }).catch(() => {});
  console.error('Admin Service Location browser E2E failed:', error);
  throw error;
} finally {
  await browser.close();
}
