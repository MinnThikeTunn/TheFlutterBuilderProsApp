# WalletSdkFailureCode Reference

All SDK errors surface as typed `WalletSdkException` instances with a machine-readable `WalletSdkFailureCode` (`49` total codes), a localized `safeMessage` suitable for display, and a boolean `canRetry`.

| Failure Code | Description | User Recovery Action |
|:---|:---|:---|
| `unavailable` | General service unavailable | Retry the operation |
| `invalidBuilder` | Invalid builder name or phone number | Correct inputs and restart activation |
| `secureSetupFailed` | Local device secure key generation or storage failed | Check device lock/keystore and retry |
| `requestCreationFailed` | Failed to create activation or configuration request | Retry request creation |
| `cancellationFailed` | Failed to cancel an in-progress activation | Retry cancellation |
| `invalidActivationRequest` | Activation QR could not be parsed or validated | Generate a fresh activation QR |
| `activationRequestExpired` | QR lifetime exceeded | Re-scan a freshly generated QR |
| `activationRequestAlreadyUsed` | Activation request QR was already consumed | Start a new activation request |
| `invalidDistributorSecret` | Distributor secret seed is malformed or invalid | Enter a valid Stellar secret seed (`S...`) |
| `distributorAccountUnavailable` | Distributor account not found or unfunded on Horizon | Verify account funding and trustline |
| `distributorAuthoritySaveFailed` | Failed to persist distributor secret securely | Retry saving distributor authority |
| `activationApprovalFailed` | App Master failed to approve request | Verify App Master configuration |
| `activationPolicyUnavailable` | Activation funding/initial rewards policy unavailable | Reconfigure App Master provider settings |
| `invalidActivationResponse` | Activation response payload malformed | Request approval again |
| `activationResponseExpired` | Activation response QR lifetime exceeded | Request a fresh approval QR from App Master |
| `activationSubmissionFailed` | Transaction submission to Horizon failed | Check connection and retry |
| `invalidProviderConfiguration` | Provider endpoint, API key, or policy values invalid | Correct App Master provider settings |
| `providerConfigurationSaveFailed` | Failed to persist provider configuration | Retry saving configuration |
| `providerConfigurationRequired` | App Master missing Horizon endpoint/API key | Configure App Master settings |
| `providerUnauthorized` | Horizon provider rejected API key | Verify Horizon API key in App Master |
| `providerRateLimited` | Horizon rate limit (HTTP 429) reached | Wait briefly and retry |
| `providerServiceUnavailable` | Horizon gateway 502/503/504 | Wait for node recovery |
| `providerNetworkMismatch` | Horizon passphrase does not match selected environment | Check Testnet vs. Production endpoint |
| `providerInvalidResponse` | Unexpected or malformed Horizon JSON response | Retry or inspect provider endpoint |
| `providerTimeout` | Horizon HTTP timeout | Retry query |
| `invalidConfigurationRequest` | Configuration request QR malformed or invalid | Generate a fresh configuration request QR |
| `invalidConfigurationUpdate` | Configuration update QR malformed or invalid | Re-scan configuration update QR |
| `configurationUpdateExpired` | Configuration update QR lifetime exceeded | Request a new configuration update QR |
| `configurationUpdateAlreadyUsed` | Configuration update QR already applied | Generate a new update if needed |
| `rosterNotConfigured` | App Master roster lacks provider/distributor setup | Configure provider and distributor authority |
| `rosterAccessDenied` | Unauthorized to query App Master roster | Verify App Master role/authority |
| `rosterUnavailable` | Roster query to Horizon failed | Check connectivity and retry |
| `rewardsIdentityUnavailable` | Device has no active verified Rewards identity | Complete device activation first |
| `rewardsBalanceUnavailable` | Balance query failed | Check connection and refresh |
| `rewardsHistoryUnavailable` | Payment history query failed | Check connection and refresh |
| `invalidRewardsHistoryCursor` | Pagination cursor invalid or expired | Reload history from the first page |
| `invalidRewardsRecipient` | Recipient address invalid or equal to self | Enter a valid public Stellar address |
| `rewardsRecipientUnavailable` | Recipient account missing or has no trustline | Ensure recipient is activated |
| `insufficientRewardsFunds` | Available token balance less than transfer amount | Reduce send amount |
| `insufficientRewardsFeeFunds` | Spendable XLM balance less than transaction fee | Fund account with native XLM |
| `invalidRewardsAmount` | Transfer amount invalid or exceeds recipient limit | Enter a valid amount within limit |
| `rewardsTransferPreparationUnavailable` | Ledger state changed during preparation | Prepare transfer again |
| `invalidRewardsTransferReview` | Transfer review expired or mismatched | Re-authorize the transaction |
| `rewardsAuthorizationUnavailable` | Biometric/passcode prompt unavailable on device | Enable device lock screen and retry |
| `rewardsAuthorizationDenied` | User cancelled or failed biometric authorization | Re-authenticate to authorize transfer |
| `rewardsTransferPending` | Previous transfer is still settling | Await confirmation before sending again |
| `rewardsSendUnavailable` | Transaction broadcast failure | Check connectivity and retry |
| `rewardsAccessUnavailable` | Protected operation locked or busy | Authenticate via biometrics |
| `rewardsAccessRemoved` | Device credentials erased | Restore from backup |
