# Step 186 — Duplicate Detection Independent of Optional Metadata

Date: 2026-10-18
Branch: `step-119-boundary-geometry`

## Change
Added a regression test that gives two rows the same State/District/City/Area names but different optional source codes. It asserts the second row is still flagged as a duplicate while both source-code strings remain available in read-only preview.

This prevents optional metadata from accidentally becoming part of the location identity or bypassing duplicate protection. The test fixture uses Dart newline escapes between records.

## Related verification
The prior Step 185 fix has Geometry Unit Tests passed; Admin Web Build had completed analysis and the full test suite successfully and was still building Flutter Web at last poll.
New test commit: `397bbb70e56de78853cc1161e7e43e1963357402`.
Current-head CI is required before calling this new test passed.

## Safety
No parser behavior/schema changes, Firebase writes, production imports, activation/deactivation, deployment, or Partner/Customer migration. Admin PR #7 remains Draft.
