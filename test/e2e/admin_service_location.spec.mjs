import { chromium } from 'playwright';

const baseUrl = 'http://127.0.0.1:4173';
const projectId = process.env.DOJO_E2E_PROJECT_ID;
if (projectId !== 'demo-dojo-platform-b68a3') {
  throw new Error('Refusing to run browser tests unless using demo-dojo-platform-b68a3.');
}

const browser = await chromium.launch({ headless: true });
const page = await browser.newPage();
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

async function signIn(email, password) {
  // Flutter Web's semantic label can resolve to the surrounding semantics
  // node rather than the editable DOM input in headless Chromium. Target the
  // actual input elements and verify both values before submitting.
  const emailInput = page.locator('input:not([type="password"])').first();
  const passwordInput = page.locator('input[type="password"]').first();
  await emailInput.fill(email);
  await passwordInput.fill(password);
  const values = await page.evaluate(() => ({
    emailLength: document.querySelector('input:not([type="password"])')?.value?.length ?? 0,
    passwordLength: document.querySelector('input[type="password"]')?.value?.length ?? 0,
  }));
  if (values.emailLength === 0 || values.passwordLength === 0) {
    throw new Error(`Login form fields were not populated: ${JSON.stringify(values)}`);
  }
  await page.getByRole('button', { name: 'Sign in securely' }).click();
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

  // Use the actual Flutter Add Location screen and its callable-backed save.
  await page.getByText('Add Location', { exact: true }).last().click();
  await page.getByText('Add Service Location', { exact: true }).waitFor();
  await chooseDropdown('Country', 'India');
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
