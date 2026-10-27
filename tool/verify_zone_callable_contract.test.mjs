import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { spawnSync } from 'node:child_process';

const contracts = [
  ['saveServiceLocationWithNameIndex', ['locationType', 'locationId', 'payload']],
  ['submitServiceZoneForFounderReview', ['zoneId']],
  ['decideServiceZoneFounderApproval', ['zoneId', 'decision', 'notes']],
  ['activateServiceZone', ['zoneId']],
  ['requestServiceZoneDeactivation', ['zoneId', 'notes']],
  ['setServiceLocationStatus', ['locationType', 'locationId', 'isActive']],
  ['requestServiceZoneReactivation', ['zoneId', 'reason']],
  ['suspendServiceZoneForEmergency', ['zoneId', 'reason', 'severity']],
];

function fixtures({ omitKeyFor, omitExport } = {}) {
  const admin = contracts.map(([name, keys]) => {
    const includedKeys = name === omitKeyFor ? keys.slice(1) : keys;
    return `httpsCallable('${name}').call({ ${includedKeys.map((key) => `'${key}': null`).join(', ')} });`;
  }).join('\n');
  const firebase = contracts
    .filter(([name]) => name !== omitExport)
    .map(([name]) => `export const ${name} = onCall(async () => {});`)
    .join('\n');
  return { admin, firebase };
}

function runVerifier(options) {
  const dir = mkdtempSync(join(tmpdir(), 'dojo-zone-contract-'));
  try {
    const adminPath = join(dir, 'admin.dart');
    const firebasePath = join(dir, 'firebase.ts');
    const data = fixtures(options);
    writeFileSync(adminPath, data.admin);
    writeFileSync(firebasePath, data.firebase);
    return spawnSync(process.execPath, [
      resolve('tool/verify_zone_callable_contract.mjs'),
      adminPath,
      firebasePath,
    ], { encoding: 'utf8' });
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
}

test('Zone callable contract verifier accepts matching names and payload keys', () => {
  const result = runVerifier();
  assert.equal(result.status, 0, result.stderr || result.stdout);
  assert.match(result.stdout, /Zone callable contract PASS: 8 callable names/);
});

test('Zone callable contract verifier rejects a missing Admin payload key', () => {
  const result = runVerifier({ omitKeyFor: 'activateServiceZone' });
  assert.equal(result.status, 1);
  assert.match(result.stderr, /missing key 'zoneId'/);
});

test('Zone callable contract verifier rejects a missing Firebase callable export', () => {
  const result = runVerifier({ omitExport: 'requestServiceZoneReactivation' });
  assert.equal(result.status, 1);
  assert.match(result.stderr, /does not export callable requestServiceZoneReactivation/);
});
