# UI Context

## Direction

theBuilderPros uses a restrained, professional mobile visual language with the official orange and violet brand palette. The interface currently supports light mode.

## Visual Hierarchy

- Neutral light page background
- White cards, fields, and navigation surfaces
- Black primary and secondary typography
- Neutral borders and subtle shadows
- Orange for primary actions and focused emphasis
- Violet for selection, focus, supporting badges, and small accents

Avoid large orange or violet backgrounds, dim text, and decorative colored strips on cards.

## Tokens

| Role | Token | Value |
| --- | --- | --- |
| Orange | `AppColors.primary` / `accent` | `#F35A12` |
| Orange dark | `AppColors.primaryDark` | `#D94A08` |
| Orange soft | `AppColors.primarySoft` / `accentSoft` | `#FFF0E8` |
| Violet | `AppColors.violet` / `secondary` | `#5B20E5` |
| Violet soft | `AppColors.violetSoft` | `#EEE8FF` |
| Background | `AppColors.background` | `#F4F2F1` |
| Surface | `AppColors.surface` | `#FFFFFF` |
| Text | `AppColors.textPrimary` / `textSecondary` | `#000000` |
| Border | `AppColors.border` | `#DED9E8` |

The code is authoritative for token values. Update this table when shared tokens change.

## Typography

`AppTheme` declares Inter as the application font family and uses bold black headings with black body and label text. Inter font files are not currently bundled; declaring a family does not embed it. Add and configure font assets before relying on Inter in production.

## Components

### Page Header

- Official horizontal theBuilderPros wordmark on the left
- Notification control on the right
- Page title and subtitle
- Left-aligned underline at approximately 32% of the content width
- Underline is mostly orange with a small violet ending

### Cards

- White surface
- Neutral border
- Subtle shadow
- No orange, violet, or per-App decorative top strip

Wallet and Profile cards use the global Material `Card` theme with a 24 px corner radius. Specialized inner surfaces may use a smaller radius when their local component design requires it.

### Navigation

- Rewards remains the initial route and there is no bottom navigation.
- Builder Rewards and App Master surfaces link through explicit role-switch
  controls. Activation, balance, Receive, direct-payment history, and recipient
  inspection and testnet transfer preparation/review/confirmation/outcome are
  SDK-backed. Uncertain outcomes offer status checks without resubmission. General
  lock/removal flows are SDK-backed. Removal explains retained recovery material
  and native restoration; the App Master Builder list remains a presentation prototype.
- The App Master role switch is for dual-role testing and is not production
  authorization.
- Builder screens and normal App Master flows use plain Rewards language. App
  Master Advanced may show the masked NOWNodes endpoint/API-key configuration,
  rotation version, distributor masked status, and safe service status. All
  processing and persistence remain inside the Wallet SDK.

### Buttons and Inputs

- Primary filled action: orange with white text
- Outlined or supporting action: violet and neutral styling
- Input surface: white
- Focused border: violet
- Stadium treatment for primary themed buttons

### Badges

- Orange-soft for general status
- Violet-soft for selection, verification, and count support
- Compact use only

## Accessibility and Responsiveness

- Preserve strong text contrast.
- Keep touch targets appropriately sized.
- Respect `SafeArea`.
- Use scrolling layouts on compact devices.
- Add semantic labels and real validation with production interactions.
- Test overflow on narrow devices.

Screen availability and current behavior belong in `current-state.md`.
## App Master roster update — 2026-10-03

Dashboard and Advanced use shared SDK roster rendering with loading, safe error, empty, refresh and load-more states. Display public identity and application access state only. With no host provider configured, show the configuration error and no sample Builder records. This change remains unverified.
## Latest App Master controls

Advanced includes account funding and initial Rewards points in the protected service settings. Builder lists show real Rewards balances and public account references; restricted status comes from the asset authorization flag. Keep chain mechanisms inside the SDK and show product language in the UI. No fabricated names or membership states. This slice remains unverified.
## Planned lightweight recovery flow — 2026-10-03

Use Back up Rewards, Restore Rewards and Remove from this device. Explain in plain language that the user keeps the backup and removal affects this device only. Require local authentication, backup confirmation and explicit removal confirmation. Keep key presentation within a dedicated SDK-controlled flow. No banking-style approval workflow or online vault selection is required. These screens are not implemented yet.
## Recovery implementation update — 2026-10-03

User-held encrypted BRB1 backup creation, same-key backup confirmation/import, authenticated permanent device removal with durable disabled markers, and ledger-proof pending-send resolution are now implemented in SDK and app UI. Recovery fields live in an SDK-owned page and no plaintext signing key enters feature state. Fresh restores can request App Master settings with initial version zero; service/API credentials are not exported. Native authentication and current-backup verification protect removal; public account/evidence remain for restoration. Unavailable/unsupported ledger proof keeps sends pending. The earlier vault dependency is obsolete.

Verification is deferred. The user explicitly authorized a user-triggered Copy encrypted backup button; it now copies only encrypted BRB1 text, never the plaintext signing key or password. The earlier clipboard approval blocker is resolved for this exact action. The implemented scope and remaining checks are maintained in `docs/walletsub-feature01/remaining-features-implementation-3oct.md`. Earlier planned/unimplemented recovery descriptions are superseded. GitHub push remains paused.
