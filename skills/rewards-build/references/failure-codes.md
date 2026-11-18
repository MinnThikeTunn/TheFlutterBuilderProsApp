# WalletSdkFailureCode Reference

All SDK errors surface as typed `WalletSdkException` instances with a machine-readable `WalletSdkFailureCode`, a localized `safeMessage` suitable for display, and a boolean `canRetry`.

| Failure Code | Description | User Recovery Action |
|:---|:---|:---|
| `unavailable` | General service unavailable | Retry the operation |
| `invalidBuilder` | Invalid builder name or phone number | Correct inputs and restart activation |
| `invalidActivationRequest` | Activation QR could not be parsed or validated | Generate a fresh activation QR |
| `activationRequestExpired` | QR lifetime exceeded | Re-scan a freshly generated QR |
| `activationApprovalFailed` | App Master failed to approve request | Verify App Master configuration |
| `invalidActivationResponse` | Activation response payload malformed | Request approval again |
| `activationSubmissionFailed` | Transaction submission to Horizon failed | Check connection and retry |
| `rewardsIdentityUnavailable` | Device has no active verified Rewards identity | Complete device activation first |
| `rewardsBalanceUnavailable` | Balance query failed | Check connection and refresh |
| `invalidRewardsRecipient` | Recipient address invalid or equal to self | Enter a valid public Stellar address |
| `rewardsRecipientUnavailable` | Recipient account missing or has no trustline | Ensure recipient is activated |
| `insufficientRewardsFunds` | Available token balance less than transfer amount | Reduce send amount |
| `insufficientRewardsFeeFunds` | Spendable XLM balance less than transaction fee | Fund account with native XLM |
| `invalidRewardsAmount` | Transfer amount exceeds recipient limit | Lower transfer amount |
| `rewardsTransferPreparationUnavailable` | Ledger state changed during preparation | Prepare transfer again |
| `invalidRewardsTransferReview` | Transfer review expired or mismatched | Re-authorize the transaction |
| `rewardsTransferPending` | Previous transfer is still settling | Await confirmation before sending again |
| `rewardsSendUnavailable` | Transaction broadcast failure | Check connectivity and retry |
| `rewardsAccessUnavailable` | Protected operation locked or busy | Authenticate via biometrics |
| `rewardsAccessRemoved` | Device credentials erased | Restore from backup |
| `providerConfigurationRequired` | App Master missing Horizon endpoint/API key | Configure App Master settings |
| `providerServiceUnavailable` | Horizon gateway 502/503/504 | Wait for node recovery |
| `providerTimeout` | Horizon HTTP timeout | Retry query |
