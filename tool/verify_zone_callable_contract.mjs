#!/usr/bin/env node
import { readFileSync } from 'node:fs';

const adminPath = process.argv[2];
const firebasePath = process.argv[3];
if (!adminPath || !firebasePath) {
  console.error('Usage: node tool/verify_zone_callable_contract.mjs <admin-service.ts-or-dart> <firebase-index.ts>');
  process.exit(2);
}
const admin = readFileSync(adminPath, 'utf8');
const firebase = readFileSync(firebasePath, 'utf8');

const contracts = [
  { name: 'saveServiceLocationWithNameIndex', keys: ['locationType', 'locationId', 'payload'] },
  { name: 'submitServiceZoneForFounderReview', keys: ['zoneId'] },
  { name: 'decideServiceZoneFounderApproval', keys: ['zoneId', 'decision', 'notes'] },
  { name: 'activateServiceZone', keys: ['zoneId'] },
  { name: 'requestServiceZoneDeactivation', keys: ['zoneId', 'notes'] },
  { name: 'setServiceLocationStatus', keys: ['locationType', 'locationId', 'isActive'] },
  { name: 'requestServiceZoneReactivation', keys: ['zoneId', 'reason'] },
  { name: 'suspendServiceZoneForEmergency', keys: ['zoneId', 'reason', 'severity'] },
];

const failures = [];
for (const contract of contracts) {
  const invocation = `httpsCallable('${contract.name}')`;
  const callAt = admin.indexOf(invocation);
  if (callAt < 0) {
    failures.push(`Admin does not call ${contract.name}`);
    continue;
  }
  const end = admin.indexOf('});', callAt);
  const block = admin.slice(callAt, end < 0 ? callAt + 1600 : end + 3);
  for (const key of contract.keys) {
    if (!block.includes(`'${key}'`)) {
      failures.push(`Admin payload for ${contract.name} is missing key '${key}'`);
    }
  }
  const exportPattern = new RegExp(`export\\s+const\\s+${contract.name}\\s*=\\s*onCall\\b`);
  if (!exportPattern.test(firebase)) {
    failures.push(`Firebase baseline does not export callable ${contract.name}`);
  }
}
if (failures.length) {
  console.error('Zone callable contract FAILED:');
  for (const failure of failures) console.error(` - ${failure}`);
  process.exit(1);
}
console.log(`Zone callable contract PASS: ${contracts.length} callable names and required Admin payload keys match Firebase baseline.`);
console.log('Scope: static cross-repository contract check only; not browser/Auth/Firestore/Functions E2E.');
