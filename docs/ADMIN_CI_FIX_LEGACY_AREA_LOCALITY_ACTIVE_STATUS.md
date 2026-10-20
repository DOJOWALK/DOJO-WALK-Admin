# Admin CI Fix — Legacy Service Activation Status

## Finding
The full Admin test suite had 106 passing tests and one failure. The compatibility test showed that legacy Area and Locality records with `isActive: true` but no `isServiceActive` were being read as inactive.

## Fix
Updated the `ServiceArea.fromMap` and `ServiceLocality.fromMap` readers to use the same compatibility helper as City and District:
- `isServiceActive` remains authoritative when present.
- Legacy `isActive` is used only when the canonical field is absent.

## Safety
This is a model-read compatibility fix; it does not write or migrate Firestore data. No merge or deployment was performed. CI must pass before this fix is considered validated.
