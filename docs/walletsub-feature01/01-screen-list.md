# Wallet Sub-Feature 01 — Screen List

The first release has no Home screen. First-time activation follows
`rewards-first-time-activation-spec-v2.md`. Every screen uses the Wallet SDK through
a controller; no screen handles activation internals.

Implementation notes (2026-09-20): runtime truth is `context/current-state.md`.
Mismatch analysis: `analysis-report.md`.

## Builder Rewards

| ID | Screen | Purpose | Main actions | Status |
| --- | --- | --- | --- | --- |
| B-01 | Rewards — Not Activated | Collect Builder name and phone | Start activation | SDK-backed |
| B-02 | Activation Request | Display the SDK-provided request QR | Copy request, scan response, import QR image | SDK-backed |
| B-03 | Review Activation | Display the SDK-provided review | Approve, cancel | SDK-backed; progress/outcome shown here |
| B-04 | Activation Progress | Show safe progress and outcome | Wait, retry when offered | No dedicated route; folded into B-03 |
| B-05 | Rewards | Show Builder card, balance, and actions | Refresh, Receive, Send, history, latest transfer status, remove access | Reads/testnet send SDK-backed; general security pending |
| B-06 | Receive Rewards | Display SDK-provided public account and receive QR | Exact copy, retry, return | SDK-backed; validated legacy migration when required |
| B-07 | Scan Recipient | Inspect public address and activated-asset receiving capacity | Camera, gallery, manual address, retry, enter amount | SDK-backed read observation |
| B-08 | Send Amount | Collect exact Rewards amount | Prepare review, cancel | SDK-backed validation of funds/capacity/fee |
| B-09 | Review Send | Display immutable SDK-prepared review | Confirm and send, cancel | SDK-backed native authorization and single testnet submission |
| B-10 | Confirm Action | Unlock local access | Native authenticate, cancel | SDK-backed legacy unlock route; cannot approve send/removal |
| B-11 | Send Outcome | Display SDK-provided outcome | Return, check saved transfer | SDK-backed confirmed/failed/cancelled/uncertain; checks never resubmit |
| B-12 | Rewards History | Display confirmed direct Rewards payments | Refresh, load more, retry | SDK-backed; other operation types/local attempts excluded |
| B-13 | Rewards Locked | Explain local protection/disabled access | Native unlock or restore | SDK-backed; each send still authenticates separately |
| B-14 | Remove Rewards Access | Disable access on this device; retain recovery material | Authenticate and disable, cancel | SDK-backed durable marker; pending transfer blocks removal; no seed erasure |

## App Master

| ID | Screen | Purpose | Main actions | Status |
| --- | --- | --- | --- | --- |
| M-01 | App Master Overview | Show activation capacity and Builder access | Scan/import request, open Advanced/My Rewards | Capacity/Rewards from SDK; Builder list mock |
| M-02 | Activate Builder | Display the SDK-provided Builder review | Create activation QR, cancel | SDK-backed |
| M-03 | Activation QR | Display the SDK-provided response QR | Save image, finish | SDK-backed real QR |
| M-04 | Advanced | Configure NOWNodes and show safe service/support status | Save endpoint/API key, import distributor secret, rotate configuration, refresh status | NOWNodes, distributor import, and configuration rotation UI wired; physical-device rotation gate open |
| M-05 | My Rewards | Reuse the Builder Rewards screens | Standard Rewards actions | Role switch exists; Rewards ops still mock |

## UI rule

Screens render safe SDK view models and return user intent. They never decode QR
content, make activation decisions, manipulate protected values, or translate raw
provider failures.
## Latest roster status — 2026-10-03

App Master Dashboard and Advanced Builder-access lists now render SDK provider records with refresh, pagination, loading, empty and error states. Sample records were removed. Real operation requires a host-injected, backend-authorized provider. This slice is implemented but unverified; earlier mock-roster descriptions are historical.
## Recovery implementation update — 2026-10-03

User-held encrypted BRB1 backup creation, same-key backup confirmation/import, authenticated permanent device removal with durable disabled markers, and ledger-proof pending-send resolution are now implemented in SDK and app UI. Recovery fields live in an SDK-owned page and no plaintext signing key enters feature state. Fresh restores can request App Master settings with initial version zero; service/API credentials are not exported. Native authentication and current-backup verification protect removal; public account/evidence remain for restoration. Unavailable/unsupported ledger proof keeps sends pending. The earlier vault dependency is obsolete.

Verification is deferred. The user explicitly authorized a user-triggered Copy encrypted backup button; it now copies only encrypted BRB1 text, never the plaintext signing key or password. The earlier clipboard approval blocker is resolved for this exact action. The implemented scope and remaining checks are maintained in `docs/walletsub-feature01/remaining-features-implementation-3oct.md`. Earlier planned/unimplemented recovery descriptions are superseded. GitHub push remains paused.
