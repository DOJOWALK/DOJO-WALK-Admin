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
  // Flutter Web initially exposes a small accessibility opt-in control in
  // Chromium. Enable it when present so Playwright uses the real semantics tree.
  const placeholder = page.locator('flt-semantics-placeholder').first();
  if (await placeholder.isVisible().catch(() => false)) {
    await placeholder.click();
    await page.waitForTimeout(500);
    return;
  }
  const enable = page.getByText(/enable accessibility/i).first();
  if (await enable.isVisible().catch(() => false)) {
    await enable.click();
    await page.waitForTimeout(500);
  }
}

async function signIn(email, password) {
  await page.getByLabel('Admin email').fill(email);
  await page.getByLabel('Password').fill(password);
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
  await page.getByText('Dashboard', { exact: true }).first().waitFor();

  // Use the actual Flutter Add Location screen and its callable-backed save.
  await page.getByText('Add Location', { exact: true }).last().click();
  await page.getByText('Add Service Location', { exact: true }).waitFor();
  await chooseDropdown('Country', 'India');
  const stateName = `E2E State ${Date.now()}`;
  await page.getByLabel('State / Union Territory name').fill(stateName);
  await page.getByRole('button', { name: 'Save location' }).click();
  await page.getByText(/Saved successfully\. Record ID:/).waitFor();

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
