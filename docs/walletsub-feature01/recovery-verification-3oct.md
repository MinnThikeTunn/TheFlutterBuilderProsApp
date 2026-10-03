# Recovery testing checklist — not executed

Use a disposable account and points for the initial checks. No results are claimed here.

1. Open Rewards → Back up or restore Rewards. Enter matching backup passwords, authenticate and create a backup. Copy encrypted backup and save it outside the app with its password.
2. Paste the independently saved copy, enter the password, confirm that it is saved outside the device and select Verify saved backup. Try a wrong password and a modified backup; both should fail without altering the account.
3. Send points, then try permanent removal using the old backup confirmation. It should require a new backup verification. Pending transfers should block permanent removal.
4. Create/verify a current backup. Confirm permanent removal and authenticate. Restart: access should remain removed, and ordinary native unlock should direct you to restore the backup.
5. Restore the same backup and password. The public account must be identical and no activation funding should be repeated. Unlock and check current balance/history.
6. Restore on a clean second installation. Open Update Rewards service, request settings from App Master, scan the protected response and apply it. Then compare the same public account, balance and history. Do not use two restored devices to send concurrently during these checks.
7. Interrupt backup creation, restoration and removal by backgrounding. Recovery fields should clear; interrupted removal/restoration must remain disabled until completed/retried with the backup.
8. Exercise an uncertain submission. Check saved transfer; then Resolve expired transfer. Missing data or a consumed sequence must not clear uncertainty. A consistent account snapshot showing the exact unused sequence at a ledger closed after expiry may resolve it without sending another payment. A support reference must match an included competing transaction using the exact account/sequence; unrelated/malformed references must not clear the guard.

SDK checks to run when verification resumes: dependency resolution, Flutter analysis, full unit/widget suite and device integration checks. The latest source includes unexecuted recovery encryption/binding fixtures. Device installation approval may still be required.
