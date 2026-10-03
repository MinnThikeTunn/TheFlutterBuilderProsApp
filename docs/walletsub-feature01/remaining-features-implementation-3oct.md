# Remaining implementation status — 2026-10-03

The agreed lightweight, non-custodial recovery features now have SDK and UI implementations, with verification deferred at the user's request. No online vault or App Master custody of Builder keys is required.

## Recovery implementation

- Back up Rewards: native authentication creates a BRB1 password-encrypted portable backup. AES-256-GCM protects the existing Builder signing key, public Rewards identity and saved transfer evidence. PBKDF2-HMAC-SHA256 uses a random 32-byte salt and 210,000 iterations. The user retains the password; the SDK does not store it. SDK-owned recovery fields clear when the page backgrounds or closes. No plaintext signing key enters feature controllers, network calls or logs.
- Verify saved backup: import the independently saved encrypted copy and its password. The SDK derives the same public account, compares current identity/key and transfer evidence, and persists a confirmation bound to identity and transfer state. A later transfer requires fresh backup confirmation before permanent removal.
- Restore Rewards: native authentication imports the same key into protected storage, checks account binding, retains newer local evidence, rejects conflicting accounts/pending evidence, restores previous activation metadata and leaves access locked. No activation funding is repeated. On a fresh installation request service settings from App Master through the existing protected QR flow; initial configuration version zero is now supported. Service API keys and App Master secrets are excluded from the backup. Imported historical activation metadata is not a new independent ledger verification.
- Remove from this device: native authentication and explicit UI confirmation require a verified current backup and no pending send. Durable erasing/erased markers precede signing-key deletion and readback verification. Interrupted cleanup stays disabled and requires backup restoration. Public identity/transfer evidence and independent App Master/service configuration remain. The account, points and other devices are unaffected. Reversible Disable access remains separate.

Recovery is reachable from Overview, initial activation, and locked/removed screens. Backups preserve existing random-key identities; standard mnemonic generation is outside this scope.

## Pending-transfer resolution

Transfer Status now offers expiry resolution and verification of an optional support transaction reference. No blind resubmission occurs.

Expiry resolution requires an account snapshot with a Latest-Ledger consistency header, the exact still-unused source sequence, and that same ledger's close time strictly beyond the original maximum transaction time. Missing headers, malformed/unavailable data or consumed sequences keep uncertainty. Conflicting-transaction resolution requires a different included transaction using the same source account/sequence, matching envelope hash and a source signature for the configured network. Resolution proof references are persisted before releasing the pending-send guard.

These are proofs from the configured provider, not independent consensus verification. Unsupported transaction envelopes or missing proof remain uncertain for support review.

## Remaining verification

The user explicitly authorized the user-triggered Copy encrypted backup button after the initial automatic rejection. That button now copies only password-encrypted BRB1 text, never the plaintext signing key or password. The clipboard approval blocker is resolved for this exact action. Builders can save the copied encrypted backup outside the device and verify the saved copy before removal. The agreed recovery and transfer-resolution features are implemented; their runtime correctness remains unverified.

Tests, analysis, builds and device checks remain deferred. Earlier verification results do not cover this slice. GitHub push remains paused. No remaining vault/product-policy decision is required.

## Sources

- [Stellar custody guidance](https://developers.stellar.org/docs/build/apps/application-design-considerations)
- [Horizon snapshot consistency](https://developers.stellar.org/docs/data/apis/horizon/api-reference/structure/consistency)
- [Transaction timeout guidance](https://developers.stellar.org/docs/data/apis/horizon/api-reference/errors/error-handling)
