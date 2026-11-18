# Stage 02: Stellar Testnet Live Integration

This stage transitions from local sandbox emulation to the public Stellar Testnet.

## Testnet Architecture

- **Horizon Node**: `https://horizon-testnet.stellar.org`
- **Network Passphrase**: `Test SDF Network ; September 2015`
- **Friendbot Faucet**: `https://friendbot.stellar.org`
- **Asset Code**: `REWARD`
- **Initial Supply**: 100,000 tokens minted to Distributor account.

## Automated Seeding

Run the automated testnet seeding script:

```powershell
.\skills\rewards-build\scripts\seed-testnet.ps1
```

### What this script automates:
1. Generates cryptographic Ed25519 keypairs for **Issuer** and **Distributor**.
2. Requests 10,000 test XLM for both accounts from Friendbot with exponential backoff on HTTP 429.
3. Submits a `change_trust` operation from the Distributor to trust the Issuer's `REWARD` asset up to maximum integer limit.
4. Submits a payment operation from the Issuer to fund the Distributor with 100,000 `REWARD` units.
5. Saves all authority secrets to `.secrets/testnet-authority.json` (strictly gitignored).

## Configuring App Master

1. Open the host application or reference harness.
2. Navigate to App Master setup.
3. Import the Distributor Secret from `.secrets/testnet-authority.json`.
4. Set Provider Endpoint to `https://horizon-testnet.stellar.org`.
5. Approve Builder requests live on the Testnet ledger.
