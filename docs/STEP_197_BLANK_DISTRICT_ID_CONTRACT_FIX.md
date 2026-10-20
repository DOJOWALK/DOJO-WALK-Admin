# Step 197 — Blank District ID Callable Contract Fix

## Issue found
Admin treated a whitespace-only City `districtId` as a legacy City when calculating the index parent fields, but the payload still contained `districtId: ""`. Firebase treats a present District ID as supplied ancestry and rejects an empty parent ID. That mismatch could make saving a legacy City fail.

## Fix
- Added `normalizeServiceLocationIndexPayload` to omit a blank optional City `districtId` and trim a nonblank value.
- Applied this normalization before building the callable's parent tuple.
- Added tests for blank, padded nonblank, and non-string District IDs.

## Safety and validation
- This is an Admin source/test change only; no Firestore data was changed.
- CI is pending for the latest branch commit.
- PR #7 remains Draft/open; no merge or deployment.
- Partner and Customer work remains deferred until Admin is finished and merged.
