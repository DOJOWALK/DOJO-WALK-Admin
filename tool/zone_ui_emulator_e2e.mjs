import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { spawn } from 'node:child_process';
import { setTimeout as delay } from 'node:timers/promises';

const require = createRequire(import.meta.url);
const { chromium } = require('playwright');
const adminRequire = createRequire(new URL('../firebase-backend/functions/package.json', import.meta.url));
const { initializeApp, getApps } = adminRequire('firebase-admin/app');
const { getAuth } = adminRequire('firebase-admin/auth');
const { getFirestore } = adminRequire('firebase-admin/firestore');

const projectId = 'demo-dojo-zone-e2e';
const email = 'central-admin-e2e@dojo.invalid';
const password = 'TestOnly-Dojo-Walk-2026!';
const zoneName = `E2E Zone ${Date.now()}`;

for (const [key, expected] of Object.entries({
  FIREBASE_AUTH_EMULATOR_HOST: '127.0.0.1:9099',
  FIRESTORE_EMULATOR_HOST: '127.0.0.1:8080',
})) {
  if (process.env[key] !== expected) {
    throw new Error(`Refusing E2E run: ${key} must equal ${expected}`);
  }
}
if (process.env.GCLOUD_PROJECT && process.env.GCLOUD_PROJECT !== projectId) {
  throw new Error('Refusing E2E run: GCLOUD_PROJECT is not the isolated demo project.');
}
if (process.env.FIREBASE_PROJECT_ID === 'dojo-platform-b68a3') {
  throw new Error('Refusing to run browser E2E against the production project ID.');
}

if (getApps().length === 0) initializeApp({ projectId });
const auth = getAuth();
const db = getFirestore();
let server;
let browser;

try {
  const user = await auth.createUser({ email, password, displayName: 'E2E Central Admin' });
  await db.doc(`admin_users/${user.uid}`).set({
    role: 'central_admin',
    isActive: true,
    name: 'E2E Central Admin',
    email,
  });
  await db.doc('service_countries/e2e-india').set({
    name: 'E2E India',
    code: 'IN-E2E',
    isActive: true,
  });
  await db.doc('service_states/e2e-up').set({
    name: 'E2E Uttar Pradesh',
    countryId: 'e2e-india',
    isActive: true,
  });
  await db.doc('service_districts/e2e-gbn').set({
    name: 'E2E Gautam Buddha Nagar',
    countryId: 'e2e-india',
    stateId: 'e2e-up',
    isServiceActive: true,
  });
  await db.doc('service_cities/e2e-noida-west').set({
    name: 'E2E Greater Noida West',
    countryId: 'e2e-india',
    stateId: 'e2e-up',
    districtId: 'e2e-gbn',
    isServiceActive: true,
  });

  server = spawn('python3', ['-m', 'http.server', '4173', '--directory', 'build/web'], {
    stdio: 'ignore',
    env: process.env,
  });
  let ready = false;
  for (let i = 0; i < 40; i++) {
    try {
      const response = await fetch('http://127.0.0.1:4173');
      if (response.ok) { ready = true; break; }
    } catch {}
    await delay(500);
  }
  assert.equal(ready, true, 'Flutter web server did not become ready.');

  browser = await chromium.launch({ headless: true, args: ['--no-sandbox'] });
  const page = await browser.newPage({ viewport: { width: 1440, height: 1000 }, locale: 'en-US', timezoneId: 'Asia/Kolkata' });
  page.setDefaultTimeout(15000);
  page.on('pageerror', error => console.error('BROWSER_PAGE_ERROR:', error.stack || error.message));
  page.on('console', message => { if (message.type() === 'error') console.error('BROWSER_CONSOLE_ERROR:', message.text()); });
  page.on('requestfailed', request => console.error('BROWSER_REQUEST_FAILED:', request.url(), request.failure()?.errorText));
  // The UI test does not depend on Google Maps network/API availability.
  await page.route('https://maps.googleapis.com/**', route => route.abort());
  await page.goto('http://127.0.0.1:4173', { waitUntil: 'domcontentloaded' });
  await page.waitForTimeout(2500);
  console.log('BROWSER_DOM_DIAGNOSTIC:', JSON.stringify(await page.evaluate(() => ({
    url: location.href,
    locale: navigator.language,
    bodyText: document.body.innerText.slice(0, 500),
    bodyHtml: document.body.innerHTML.slice(0, 1800),
    glassPaneCount: document.querySelectorAll('flt-glass-pane').length,
    canvasCount: document.querySelectorAll('canvas').length,
    inputCount: document.querySelectorAll('input').length,
  }))));

  const enableAccessibility = page.getByRole('button', { name: /enable accessibility/i });
  const placeholder = page.locator('flt-semantics-placeholder');
  console.log('Flutter accessibility controls:', {
    namedButtonCount: await enableAccessibility.count().catch(() => 0),
    placeholderCount: await placeholder.count().catch(() => 0),
    title: await page.title(),
  });
  if (await enableAccessibility.count().catch(() => 0)) {
    await enableAccessibility.first().click({ force: true });
  } else if (await placeholder.count().catch(() => 0)) {
    await placeholder.click({ force: true });
  } else {
    // Some Flutter web builds expose the accessibility prompt only on first
    // keyboard focus; Tab/Enter enables the semantic DOM for browser tests.
    await page.keyboard.press('Tab');
    await page.keyboard.press('Enter');
  }
  await page.waitForTimeout(500);
  await page.getByPlaceholder('Enter admin email').fill(email);
  await page.getByPlaceholder('Enter password').fill(password);
  await page.getByRole('button', { name: /sign in/i }).click();

  await page.getByText('DOJO WALK Admin', { exact: false }).first().waitFor();
  await page.getByText('Service Locations', { exact: true }).first().click();
  await page.getByText('Service Locations', { exact: true }).first().waitFor();
  await page.getByText('Zones', { exact: true }).click();
  await page.getByRole('button', { name: /create zone draft/i }).click();

  await page.getByText('State / UT', { exact: true }).click();
  await page.getByText('E2E Uttar Pradesh', { exact: true }).last().click();
  await page.getByText('District', { exact: true }).click();
  await page.getByText('E2E Gautam Buddha Nagar', { exact: true }).last().click();
  await page.getByText('City', { exact: true }).click();
  await page.getByText('E2E Greater Noida West', { exact: true }).last().click();
  await page.getByLabel('Zone name').fill(zoneName);
  await page.getByRole('button', { name: /^save draft$/i }).click();

  await page.getByText(/Zone draft saved/i).waitFor();
  const saved = await db.collection('service_zones').where('name', '==', zoneName).limit(1).get();
  assert.equal(saved.size, 1, 'Zone Draft callable did not create exactly one matching emulator document.');
  const data = saved.docs[0].data();
  assert.equal(data.stateId, 'e2e-up');
  assert.equal(data.districtId, 'e2e-gbn');
  assert.equal(data.cityId, 'e2e-noida-west');
  assert.equal(data.isServiceActive, false, 'New Zone must not be activated by draft creation.');
  console.log(JSON.stringify({
    result: 'PASS',
    projectId,
    browserFlow: 'Central Admin login → Service Locations → Zones → Create Zone Draft → Save Draft',
    savedZoneId: saved.docs[0].id,
    zoneName,
    isServiceActive: data.isServiceActive,
  }, null, 2));
} finally {
  if (browser) await browser.close().catch(() => {});
  if (server && !server.killed) server.kill('SIGTERM');
}
