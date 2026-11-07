#!/bin/bash
# DA7MG Phone — rebrand patch for a linphone-iphone checkout (SwiftUI, SPM).
# Run from inside the linphone-iphone repo root:
#   cd ~/workspace/da7mg-phone/linphone-iphone && ../linphone-ios-apply-da7mg-rebrand.sh
# Safe to re-run. Does NOT commit anything. Review with `git diff --stat`.
# Verified against linphone-iphone master @ 7d506a3 (Xcode 16, SDK 5.5.18).
#
# What it changes (mirrors linphone-android-apply-da7mg-rebrand.sh):
#   bundle IDs org.linphone.phone* -> com.da7mg.phone* (app + all extensions)
#   app groups + keychain groups -> com.da7mg.phone.*
#   display name -> "DA7MG Phone" (INFOPLIST_KEY_CFBundleDisplayName + CFBundleName)
#   version 6.3.0 -> 1.0.0-da7mg
#   default SIP domain sip.linphone.org -> da7mgdistributions.com, transport UDP
#   "Create Linphone account" button removed from the login screen
#   theme accent orange #FF5E00 -> house gold #D4AF37 (default "orange" theme)
#   app icon + in-app logo replaced from the DA7MG globe
#   Belledonne's DEVELOPMENT_TEAM removed (unsigned / free-ID sideload build)
set -e
BRAND="$HOME/workspace/da7mg-phone/branding"
[ -d Linphone ] || { echo "ERROR: run from the linphone-iphone repo root"; exit 1; }
[ -f "$BRAND/ios/AppIcon-1024.png" ] || { echo "ERROR: branding icon not found at $BRAND/ios/AppIcon-1024.png"; exit 1; }

echo "== 1. Bundle IDs: org.linphone.phone* -> com.da7mg.phone* =="
# project.pbxproj: main app, msgNotificationService, linphoneExtension,
# intentsExtension, and both test targets. Info.plist: URL types + scheme.
sed -i 's/org\.linphone\.phone/com.da7mg.phone/g' LinphoneApp.xcodeproj/project.pbxproj
sed -i 's/org\.linphone\.LinphoneApp/com.da7mg.phone.LinphoneApp/g' LinphoneApp.xcodeproj/project.pbxproj
sed -i 's/org\.linphone\.phone/com.da7mg.phone/g' Linphone/Info.plist
sed -i 's|<string>org.linphone</string>|<string>com.da7mg.phone</string>|' Linphone/Info.plist
grep -n 'PRODUCT_BUNDLE_IDENTIFIER' LinphoneApp.xcodeproj/project.pbxproj | sort -u

echo "== 2. App groups + keychain groups -> com.da7mg.phone.* =="
sed -i 's/group\.org\.linphone\.phone/group.com.da7mg.phone/g' Shared.xcconfig \
  Linphone/Linphone.entitlements \
  linphoneExtension/linphoneExtension.entitlements \
  msgNotificationService/msgNotificationService.entitlements
sed -i 's/\$(AppIdentifierPrefix)org\.linphone\.phone/$(AppIdentifierPrefix)com.da7mg.phone/g' \
  Linphone/Linphone.entitlements msgNotificationService/msgNotificationService.entitlements
# NOTE: group.belledonne-communications.linphone in Linphone.entitlements is
# Belledonne's own group and is left alone (inert in an unsigned build).
grep -rn 'group.com.da7mg.phone' Shared.xcconfig Linphone/Linphone.entitlements \
  linphoneExtension/linphoneExtension.entitlements \
  msgNotificationService/msgNotificationService.entitlements | head -8

echo "== 3. Display name -> DA7MG Phone; version 6.3.0 -> 1.0.0-da7mg =="
python3 - <<'PYEOF'
p = "LinphoneApp.xcodeproj/project.pbxproj"
s = open(p).read()
# Main app target only: the two "Linphone" display-name lines (msgNotificationService
# and the extensions keep their own names). Add CFBundleName so the app shows
# "DA7MG Phone" under its icon AND in Settings (CFBundleName falls back to
# PRODUCT_NAME = LinphoneApp otherwise). Idempotent: skip if already applied.
old = "\t\t\t\tINFOPLIST_KEY_CFBundleDisplayName = Linphone;\n"
new = '\t\t\t\tINFOPLIST_KEY_CFBundleDisplayName = "DA7MG Phone";\n\t\t\t\tINFOPLIST_KEY_CFBundleName = "DA7MG Phone";\n'
if old in s:
    assert s.count(old) == 2, f"expected 2 Linphone display-name lines, found {s.count(old)}"
    s = s.replace(old, new)
    print("display name applied")
else:
    print("display name already applied, skipping")
# Marketing version for the app + notification service + both extensions
# (all eight were 6.3.0: 2 configs x 4 targets).
if "MARKETING_VERSION = 6.3.0;" in s:
    assert s.count("MARKETING_VERSION = 6.3.0;") == 8, "expected 8 MARKETING_VERSION 6.3.0 lines"
    s = s.replace("MARKETING_VERSION = 6.3.0;", "MARKETING_VERSION = 1.0.0-da7mg;")
    print("version applied")
else:
    print("version already applied, skipping")
open(p, "w").write(s)
PYEOF
grep -n 'INFOPLIST_KEY_CFBundleDisplayName = "DA7MG Phone"\|INFOPLIST_KEY_CFBundleName = "DA7MG Phone"\|MARKETING_VERSION = 1.0.0-da7mg' \
  LinphoneApp.xcodeproj/project.pbxproj | head -10

echo "== 4. Remove Belledonne's DEVELOPMENT_TEAM (unsigned build) =="
# The fork ships with Belledonne's team ID (Z2V957B3D6) in every target.
# An unsigned build (CODE_SIGNING_ALLOWED=NO) needs no team; shipping
# someone else's team ID would be wrong. Alex re-signs with his own
# free Apple ID on his own machine.
sed -i '/DEVELOPMENT_TEAM = Z2V957B3D6;/d' LinphoneApp.xcodeproj/project.pbxproj
grep -c 'DEVELOPMENT_TEAM' LinphoneApp.xcodeproj/project.pbxproj || echo "no DEVELOPMENT_TEAM lines left"

echo "== 5. House server as the default domain (UDP 5060) =="
# CorePreferences: the compiled-in default domain (2 spots).
sed -i 's/defaultString: "sip.linphone.org"/defaultString: "da7mgdistributions.com"/g' \
  Linphone/Core/CorePreferences.swift
# AccountLoginViewModel: default domain + the reset-after-login value.
# The `if domain != "sip.linphone.org"` branch check is INTENTIONALLY left
# alone: with the house domain as default, a house login now takes the
# third-party-defaults branch (assistant_third_party_default_values),
# which is the correct config for a non-Linphone server.
sed -i 's/@Published var domain: String = "sip.linphone.org"/@Published var domain: String = "da7mgdistributions.com"/' \
  Linphone/UI/Assistant/Viewmodel/AccountLoginViewModel.swift
sed -i 's/self.domain = "sip.linphone.org"/self.domain = "da7mgdistributions.com"/' \
  Linphone/UI/Assistant/Viewmodel/AccountLoginViewModel.swift
# Default transport TLS -> UDP: the house Asterisk listens on UDP 5060
# (no TLS listener). The SIP login screen still lets the user pick.
sed -i 's/@Published var transportType: String = "TLS"/@Published var transportType: String = "UDP"/' \
  Linphone/UI/Assistant/Viewmodel/AccountLoginViewModel.swift
# RegisterViewModel (Linphone-account creation, hidden by step 7): domain
# default kept consistent so no sip.linphone.org default survives.
sed -i 's/@Published var domain: String = "sip.linphone.org"/@Published var domain: String = "da7mgdistributions.com"/' \
  Linphone/UI/Assistant/Viewmodel/RegisterViewModel.swift
# Third-party SIP login screen: placeholder + back-button reset values.
sed -i 's/TextField("sip.linphone.org"/TextField("da7mgdistributions.com"/' \
  Linphone/UI/Assistant/Fragments/ThirdPartySipAccountLoginFragment.swift
sed -i 's/accountLoginViewModel.domain = "sip.linphone.org"/accountLoginViewModel.domain = "da7mgdistributions.com"/' \
  Linphone/UI/Assistant/Fragments/ThirdPartySipAccountLoginFragment.swift
sed -i 's/accountLoginViewModel.transportType = "TLS"/accountLoginViewModel.transportType = "UDP"/' \
  Linphone/UI/Assistant/Fragments/ThirdPartySipAccountLoginFragment.swift
grep -rn 'da7mgdistributions.com' Linphone/Core/CorePreferences.swift \
  Linphone/UI/Assistant/Viewmodel/AccountLoginViewModel.swift \
  Linphone/UI/Assistant/Viewmodel/RegisterViewModel.swift \
  Linphone/UI/Assistant/Fragments/ThirdPartySipAccountLoginFragment.swift | head -12

echo "== 6. House colours: gold #D4AF37 accent (default theme) =="
# iOS theme colours live in ThemeManager (main100/main500 per theme name);
# the app defaults to the "orange" theme, so re-colouring that theme
# re-colours every Color.orangeMain500 usage (buttons, highlights, logo
# tint). AccentColor asset set to gold as well.
python3 - <<'PYEOF'
p = "Linphone/Utils/ThemeManager.swift"
s = open(p).read()
if '"#FF5E00"' not in s:
    print("theme accent already gold, skipping")
else:
    old = """\tstatic let orange = Theme(
\t\tname: "orange",
\t\tmain100: Color(hex: "#FFEACB"),
\t\tmain500: Color(hex: "#FF5E00")
\t)"""
    new = """\t// DA7MG: house gold #D4AF37 on black #0A0A0A (was Linphone orange
\t// #FF5E00). The app defaults to this "orange" theme, so changing it
\t// here re-colours every Color.orangeMain500 usage in the UI.
\tstatic let orange = Theme(
\t\tname: "orange",
\t\tmain100: Color(hex: "#F7EFD2"),
\t\tmain500: Color(hex: "#D4AF37")
\t)"""
    assert old in s, "orange theme block not found"
    open(p, "w").write(s.replace(old, new, 1))
    print("theme accent -> gold")
PYEOF
cat > Linphone/Assets.xcassets/AccentColor.colorset/Contents.json <<'JSONEOF'
{
  "colors" : [
    {
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "1.000",
          "blue" : "0.216",
          "green" : "0.686",
          "red" : "0.831"
        }
      },
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
JSONEOF
echo "AccentColor -> #D4AF37"

echo "== 7. Hide 'Create Linphone account' on the login screen =="
# LoginFragment's bottom row ("No account yet?" + RegisterFragment link)
# is removed, so the only account path left is the SIP login
# ("Use a SIP account" button + the username/password form above it,
# which now defaults to the house domain, see step 5). The Register
# view model + fragment stay in the tree, unreachable from the UI.
if grep -q 'assistant_account_register' Linphone/UI/Assistant/Fragments/LoginFragment.swift; then
python3 - <<'PYEOF'
p = "Linphone/UI/Assistant/Fragments/LoginFragment.swift"
lines = open(p).read().split("\n")
start = next(i for i, l in enumerate(lines) if l == "\t\t\tHStack(alignment: .center) {")
end = next(i for i, l in enumerate(lines) if l == '\t\t\tImage("mountain2")')
assert start < end, "register HStack block not found in order"
removed = lines[start:end]
assert any("assistant_account_register" in l for l in removed), "register link not in removed block"
assert any("assistant_no_account_yet" in l for l in removed), "no-account label not in removed block"
comment = '\t\t\t// DA7MG: "Create Linphone account" removed — the only account path is\n\t\t\t// "Use a SIP account" (house server pre-filled). RegisterFragment stays\n\t\t\t// in the tree but is unreachable from the UI.'
lines[start:end] = [comment, ""]
open(p, "w").write("\n".join(lines))
print(f"removed {len(removed)} lines (register row)")
PYEOF
else
  echo "register UI already removed, skipping"
fi
grep -c 'assistant_account_register\|assistant_no_account_yet' \
  Linphone/UI/Assistant/Fragments/LoginFragment.swift || echo "register UI gone from LoginFragment"

echo "== 8. App icon set from the DA7MG globe (1024px source) =="
# iOS icons must be opaque: flatten the RGBA globe onto house black.
# Generates every iPhone/iPad size + the 1024 marketing icon.
python3 - "$BRAND/ios/AppIcon-1024.png" Linphone/Assets.xcassets/AppIcon.appiconset <<'PYEOF'
import json, os, sys
from PIL import Image
src_path, outdir = sys.argv[1], sys.argv[2]
src = Image.open(src_path).convert("RGBA")
bg = Image.new("RGBA", src.size, (10, 10, 10, 255))  # house black #0A0A0A
flat = Image.alpha_composite(bg, src).convert("RGB")
sizes = [  # (idiom, size_pt, scale, filename)
    ("iphone", 20, 2, "Icon-20@2x.png"), ("iphone", 20, 3, "Icon-20@3x.png"),
    ("iphone", 29, 2, "Icon-29@2x.png"), ("iphone", 29, 3, "Icon-29@3x.png"),
    ("iphone", 40, 2, "Icon-40@2x.png"), ("iphone", 40, 3, "Icon-40@3x.png"),
    ("iphone", 60, 2, "Icon-60@2x.png"), ("iphone", 60, 3, "Icon-60@3x.png"),
    ("ipad", 20, 1, "Icon-20.png"), ("ipad", 20, 2, "Icon-20@2x-ipad.png"),
    ("ipad", 29, 1, "Icon-29.png"), ("ipad", 29, 2, "Icon-29@2x-ipad.png"),
    ("ipad", 40, 1, "Icon-40.png"), ("ipad", 40, 2, "Icon-40@2x-ipad.png"),
    ("ipad", 76, 1, "Icon-76.png"), ("ipad", 76, 2, "Icon-76@2x.png"),
    ("ipad", 83.5, 2, "Icon-83.5@2x.png"),
]
images = []
for idiom, pt, scale, fn in sizes:
    px = int(pt * scale)
    flat.resize((px, px), Image.LANCZOS).save(os.path.join(outdir, fn))
    images.append({"filename": fn, "idiom": idiom, "scale": f"{scale}x",
                   "size": f"{pt:g}x{pt:g}"})
flat.save(os.path.join(outdir, "1024x1024.png"))
images.append({"filename": "1024x1024.png", "idiom": "ios-marketing",
               "scale": "1x", "size": "1024x1024"})
contents = {"images": images, "info": {"author": "xcode", "version": 1}}
json.dump(contents, open(os.path.join(outdir, "Contents.json"), "w"), indent=2)
print(f"wrote {len(images)} icon sizes to {outdir}")
PYEOF

echo "== 9. In-app logo: Linphone wordmark SVG -> DA7MG globe PNG =="
# Every Image("linphone") usage is .resizable() + .renderingMode(.template)
# and tinted with the theme accent, so the globe renders as a gold globe
# on the splash screen, side menu, welcome page, and CallKit icon.
cp "$BRAND/ios/AppIcon-1024.png" Linphone/Assets.xcassets/linphone.imageset/linphone.png
rm -f Linphone/Assets.xcassets/linphone.imageset/linphone.svg
cat > Linphone/Assets.xcassets/linphone.imageset/Contents.json <<'JSONEOF'
{
  "images" : [
    {
      "filename" : "linphone.png",
      "idiom" : "universal",
      "scale" : "1x"
    },
    {
      "filename" : "linphone.png",
      "idiom" : "universal",
      "scale" : "2x"
    },
    {
      "filename" : "linphone.png",
      "idiom" : "universal",
      "scale" : "3x"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
JSONEOF
echo "in-app logo -> DA7MG globe"

echo "== 10. Summary =="
git diff --stat | tail -20
git status --short | head -25
echo "REBRAND APPLIED. Next: commit + push to the public repo, then the"
echo "GitHub Actions workflow builds the unsigned .ipa (see build-ipa.yml)."
