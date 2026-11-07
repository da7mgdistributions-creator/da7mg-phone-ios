# DA7MG Phone (iOS)

**DA7MG Phone** is DA7MG Distributions' own iPhone calling app — a rebrand
of [Linphone for iOS](https://github.com/BelledonneCommunications/linphone-iphone)
by Belledonne Communications, released under the **GNU General Public
License v3** (see `LICENSE`). The source is published here because the GPL
requires it — and because the value is the house server, numbers and brand,
not secret app code.

What is different from upstream Linphone:

- App name **DA7MG Phone**, bundle ID `com.da7mg.phone` (app + extensions)
- House server pre-filled: `da7mgdistributions.com:5060`, UDP — the user
  only types an extension number (e.g. `100`) and a password
- "Create Linphone account" removed — login is "Use a SIP account" only
- Colours: house gold `#D4AF37` on black `#0A0A0A`
- DA7MG globe app icon + in-app logo
- Version `1.0.0-da7mg`

## Build (unsigned .ipa, no Apple ID needed)

Every push to `master` — or a manual run from the Actions tab — builds an
unsigned `.ipa` on a free GitHub-hosted macOS runner
(`.github/workflows/build-ipa.yml`, Xcode 16, signing disabled) and uploads
it as the `da7mg-phone-ios-ipa` workflow artifact. Download it from the
run's Artifacts section.

## Install on an iPhone (Alex's phone, free Apple ID)

The `.ipa` is **unsigned** — Apple will not install it as-is. Re-sign it on
a computer with a free Apple ID using AltStore (recommended: it re-signs
automatically every 7 days on the same Wi-Fi) or Sideloadly, then trust the
certificate on the iPhone under Settings → General → VPN & Device
Management. Full step-by-step instructions are in the build report
(`DA7MG-PHONE-IOS-BUILD-REPORT-2026-11-07.md` in the workspace; the
canonical copy ships with each release).

Honest limits of this v1: a free Apple ID signature **expires after
7 days** (re-sign weekly; AltStore automates it) and allows **3 apps**;
incoming calls will not ring with the app fully closed (no APNs push
without the $99/yr Apple membership — Phase 2); no outside calls and no
911 yet (no SIP trunk on the house server — keep the Boost line for 911).

## Rebrand locally

```sh
cd linphone-iphone
../linphone-ios-apply-da7mg-rebrand.sh   # re-runnable, commits nothing
```

The script mirrors `linphone-android-apply-da7mg-rebrand.sh` (Android fork).

## Licence

Linphone / liblinphone are © Belledonne Communications, licensed GPLv3
(app) / AGPLv3 (SDK). This fork stays GPLv3. See `LICENSE` and
`GPL-LICENCE-NOTE.md` in the workspace. No passwords, tokens or secrets
are in this repo — ever.
