# Stage 04: Production Readiness & Hardening

This stage outlines the non-negotiable security requirements, cryptographic boundaries, and custody models required before mainnet deployment.

## Production Security Gates

1. **Strict Key Custody**:
   - The Issuer account secret MUST NEVER be stored on any mobile or client device.
   - The Issuer key should be stored in cold storage (hardware security module or offline multi-sig).
   - Only the Distributor account secret is imported into App Master devices.

2. **Network Configuration**:
   - Mainnet Horizon Endpoint: Dedicated high-availability Horizon provider (e.g. SDF or private cluster).
   - Mainnet Passphrase: `Public Global Stellar Network ; September 2015`.
   - API Keys: Secured via runtime config injection, never hardcoded.

3. **Multi-Signature Policies**:
   - Medium and high thresholds on the Distributor account should require at least 2 distinct signers for administrative changes.
   - Builder activation transactions must only fund legitimate devices with the required minimum reserve (2.1 XLM) and 1 initial token.

4. **Biometric & KeyStore Protection**:
   - Android: Hardware-backed KeyStore (`AndroidKeyStore`) with user authentication gates.
   - iOS: Secure Enclave Keychain (`kSecAccessControlBiometryAny` or device passcode).

5. **Disaster Recovery**:
   - Builders MUST create and confirm their `BRB1....` encrypted backup before device erasure.
   - Backups use AES-256-GCM with PBKDF2 (210,000 iterations of HMAC-SHA256).

6. **Verification Gate**:
   - Run `.\skills\rewards-build\scripts\verify.ps1 -Act 3` to verify zero `sandbox.dart` imports in production app code.
