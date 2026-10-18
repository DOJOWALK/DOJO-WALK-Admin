# Step 134 — District Status Transaction Read-Order Fix

Date: 2026-10-19

Firebase repository: `DOJO-WALK-Firebase`
Branch: `fix/location-index-import-rules`
Code commit: `5f69cbcafb1c05333131449165c88f602f2921f6`
Regression-test commit: `ffbdac545d943215a72f226cad57a5b7ac6227ea`

## Finding and fix
A review of `setServiceLocationStatus` found that District activation read the Country document with `tx.get()` after the transaction had already started writing the target District. Firestore requires transaction reads to occur before writes, so this path could fail at runtime.

The District Country is now read and checked for active status before the first transaction write. The later write section only guard-writes the already validated State and Country references.

## Regression guard
Added `functions/test/status_transaction_order.test.cjs`. It checks that the District Country read appears before the first transaction write and is not performed again after writes begin.

## Verification status
- Firestore Security Rules workflow run 244: **in progress** at report creation.
- This test is a source-order regression guard, not a callable-emulator integration test.
- The dedicated emulator tests for District save/activate/deactivate authorization, ancestry, duplicate index handling, and active-descendant blocking remain outstanding.

## Safety
No production data was written. No deployment or merge was performed. Customer and Partner repositories were not changed.
