# Step 128 — Partner and Customer Location Compatibility Audit

Date: 2026-10-18  
Status: **Read-only cross-app audit; no app code, Firestore data, Rules deployment or migration changed**

## Sources inspected

- Partner `lib/features/onboarding/screens/work_location_screen.dart` at `9c5d5e12a3fd29785d2001fb20937a7bbb374df5`
- Partner `lib/features/onboarding/screens/personal_details_screen.dart` at `ae8a929e9ec724e9536acd2c8ffcc9b7c06c0f82`
- Partner `firestore.rules` at `7b02a8bfb4fe80ab04d72f59966e2e09c848ffd0`
- Customer `lib/features/addresses/services/address_service.dart` at `a80281b7b6ee02b5c3c3fac4275881ee60190898`
- Customer `lib/features/addresses/models/saved_address.dart` at `03c2f642141abcaae297bfd3b0b7f6ed51c045e8`
- Customer `lib/features/booking/screens/booking_confirmation_screen.dart` at `94d45b12c7873fc2d289e164df965c735c0c63cb`

The refs are repository source snapshots, not proof of production deployment.

## Findings

### Partner: operational onboarding is tied to legacy `zones`

- Work Location queries `zones` where `isActive == true`.
- It builds city and area dropdown values from the `city` and `area` text fields in those zone documents.
- On selection, it finds matching zone documents by city + area text, reads the `state` text, and derives `zoneName`/`zoneNames`.
- It writes the selected display strings and the matched zone document IDs into `walkers/{uid}` fields including `city`, `state`, `area`, `zoneName`, `zoneNames`, `zones`, and `travelMode`.
- Personal Details also persists the legacy zone names/IDs on the walker profile when creating the application.
- The inspected Partner Rules allowlist for ordinary owner updates includes `city`, `area`, and `zones`, but does not include every field the Work Location screen attempts to update on an existing draft (notably `state`, `zoneName`, `zoneNames`, `travelMode`). This is a **source-level compatibility risk requiring a targeted test**; it is not proof of current production failure because deployed Rules/version and exact existing-draft flow have not been verified.
- New Service City/Area IDs must not be substituted into `zones` until an explicit adapter or versioned migration preserves the meaning of existing zone IDs.

### Customer: saved address and booking snapshot are free-text based

- `SavedAddress` stores text fields including `area`, `city`, `pincode`, `flatHouse`, and `buildingSociety`, plus optional latitude/longitude. It has no service `cityId`, `areaId`, `districtId`, or LGD code.
- Address persistence writes the existing text/address fields under `users/{uid}/addresses`.
- Booking confirmation composes a display address from the text fields and creates a booking document. The inspected screen does not establish an authoritative Service Area ID as part of the address model.
- Customer free-text address data should remain intact. New optional IDs, if approved, must not make existing saved addresses unreadable or invalidate existing booking snapshots.
- Customer booking creation is also gated by the shared Firestore Rules source; do not infer the deployed booking-create policy from this audit alone.

## Compatibility matrix

| Data/use | Current representation | Safe next step | Do not do |
|---|---|---|---|
| Partner work area selection | Active `zones`, matched by city/area text | Build explicit reviewed `zoneId → serviceAreaId` mapping report | Match by name and rewrite IDs automatically |
| Walker's assigned zones | `walkers/{uid}.zones` contains zone document IDs | Preserve legacy IDs; add adapter only after contract approval | Replace existing zone IDs with area IDs |
| Partner location labels | Text `state`, `city`, `area`, `zoneName(s)` | Keep readable during transition; test Rules allowlists | Assume all label writes currently pass Rules |
| Customer saved address | Free-text area/city and address details | Preserve; optionally add IDs only after compatibility approval | Rewrite historical addresses from normalized names |
| Booking pickup snapshot | Address text copied into booking | Keep historical snapshot immutable; new IDs are additive and versioned if approved | Retroactively recalculate old bookings |
| LGD District reference | Not present in these app address models | Introduce only through approved cross-app contract | Treat customer area text as LGD Sub-District |

## Required safe migration sequence

1. Approve the shared schema and define stable IDs/parent fields first.
2. Export/report active legacy zones with IDs and fields `state`, `city`, `area`, `zoneName`, `isActive`; report ambiguous duplicates separately.
3. Create a human-reviewed explicit mapping for each legacy zone to a service city/area. Unmapped or ambiguous entries stay on legacy behavior.
4. Add an adapter/read compatibility layer without deleting or rewriting legacy `zones`.
5. Update Partner's Rules and onboarding writes together; test both new application creation and editing an existing `in_progress` draft.
6. Keep Customer's free-text address and historical booking snapshot behavior. Test old address documents and old bookings before introducing optional service-location IDs.
7. Run Firebase Emulator tests and app tests against both legacy and new-shaped fixtures.
8. Only after separate approval, plan a reversible migration and staged rollout. No production write is implied by this report.

## Step 128 status

- [x] Located Partner's legacy zone selection and walker ID writes.
- [x] Compared Partner source allowlists with fields updated by Work Location.
- [x] Confirmed Customer saved address and booking confirmation are text/snapshot oriented in inspected files.
- [x] Recorded no-name-only-mapping and historical-data-preservation rules.
- [ ] Verify deployed Rules and reproduce the existing-draft Partner update with Emulator tests.
- [ ] Approve cross-app schema and explicit legacy zone mapping.
- [ ] Implement adapter and tests.
- [ ] Complete integrated CI/release review.

**Safety:** No production records were read or changed by this audit; no imports, migrations, activations, deployments or merges were performed.
