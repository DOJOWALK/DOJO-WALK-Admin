# DOJO WALK Location Master — Step 45 Report

Date: 2026-10-17  
Branch: `restore/india-location-reference-data`

## Result: CROSS-REPOSITORY SECURITY AUDIT — FINDINGS RECORDED

Correction: the Firestore rules file is **not missing from the DOJO WALK project**. It lives in the separate central repository, `dojoplatform2026/dojo-firebase`. The earlier statement applied only to the `dojo-admin` repository tree and was too broad. No rules were created or deployed by this audit.

Reviewed:
- [Central Firestore rules](https://github.com/dojoplatform2026/dojo-firebase/blob/main/firestore.rules)
- [Central rules deployment workflow](https://github.com/dojoplatform2026/dojo-firebase/blob/main/.github/workflows/deploy-firestore-rules.yml)
- [Admin AuthGate](https://github.com/dojoplatform2026/dojo-admin/blob/restore/india-location-reference-data/lib/screens/auth/auth_gate.dart)
- [Admin AuthService](https://github.com/dojoplatform2026/dojo-admin/blob/restore/india-location-reference-data/lib/services/auth_service.dart)

## Findings

1. The central `dojo-firebase` repository has `firestore.rules`, a `firebase.json` rules mapping, and a GitHub Actions workflow configured to deploy Firestore rules to Firebase project `dojo-platform-b68a3` when relevant files change on `main`, or by manual workflow dispatch. This confirms the repository workflow is configured; it does **not** independently prove which rules are currently deployed in production.
2. The rules define service-location collections including `service_location_boundaries`, `service_location_name_indexes`, `service_countries`, `service_states`, `service_cities`, `service_areas`, `service_localities`, and `service_location_imports`.
3. Rules require an active `super_admin` for `isAdmin()`-guarded operations. However, Admin `AuthGate` and `AuthService` only check `admin_users/{uid}.isActive == true`; they do not enforce the `super_admin` role in the UI. An active non-super-admin may therefore enter the AdminShell but have privileged Firestore operations denied by the rules. Align the UI role policy with the central rules before rollout.
4. The rules protect boundary status transitions and require a correctly linked, verified boundary before activating a City or Area. The reviewed rules validate the boundary's location ID/type/status and required provenance fields, but do not perform polygon parent-containment geometry checks. The service-layer containment check remains important; a privileged direct client write would need server-enforced rules or trusted backend validation if this invariant must be enforced against hostile clients.
5. The repository workflow file alone does not prove the current deployed rules version. Confirm deployment history/current rules before production changes.

## Required follow-up

- Reconcile Admin UI authorization with the central `super_admin` rule policy, without weakening server rules by assumption.
- Add Firestore Emulator authorization tests for unauthenticated users, active/inactive admins, role differences, boundary lifecycle, and City/Area activation requirements.
- Decide how to enforce parent-polygon containment server-side for all writes; Firestore Rules are not suitable for arbitrary polygon geometry.
- Confirm the current deployed rules version through approved Firebase deployment records before production activation.

No production Firebase rules/data were changed; no imports, activations, or deployments were performed. Keep PR #6 open.
