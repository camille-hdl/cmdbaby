#!/bin/zsh

set -euo pipefail

script_dir=${0:A:h}
project_dir=${script_dir:h}
configuration=${CONFIGURATION:-release}
output_dir=${BABYWORK_APP_OUTPUT_DIR:-"/Applications"}
signing_identity=${BABYWORK_CODE_SIGN_IDENTITY:--}
sandbox_mode=${BABYWORK_APP_SANDBOX:-0}

if [[ "$signing_identity" == "-" ]]; then
    signing_label="Signature ad hoc — impropre à une identité TCC stable"
else
    signing_label="$signing_identity"
fi

case "$sandbox_mode" in
    1|true|TRUE|yes|YES)
        entitlements_path="$project_dir/Resources/BabyWorks.sandbox.entitlements"
        sandbox_label="App Sandbox activé"
        app_name="BabyWorks-sandbox.app"
        ;;
    *)
        entitlements_path="$project_dir/Resources/BabyWorks.nosandbox.entitlements"
        sandbox_label="App Sandbox désactivé"
        app_name="BabyWorks.app"
        ;;
esac

app_path="$output_dir/$app_name"
contents_path="$app_path/Contents"
executable_path="$contents_path/MacOS/BabyWorks"
info_path="$contents_path/Info.plist"

swift build --configuration "$configuration" --product BabyWorks
binary_dir=$(swift build --configuration "$configuration" --show-bin-path)

mkdir -p "$contents_path/MacOS" "$contents_path/Resources"
install -m 755 "$binary_dir/BabyWorks" "$executable_path"
install -m 644 "$project_dir/Resources/BabyWorks-Info.plist" "$info_path"

resource_bundle="$binary_dir/BabyWork_BabyWorks.bundle"
if [[ ! -d "$resource_bundle" ]]; then
    print -u2 "Bundle de ressources introuvable : $resource_bundle"
    exit 1
fi
rm -rf "$app_path/BabyWork_BabyWorks.bundle"
rm -rf "$contents_path/Resources/BabyWork_BabyWorks.bundle"
cp -R "$resource_bundle" "$contents_path/Resources/BabyWork_BabyWorks.bundle"
/usr/bin/plutil -replace BabyWorkSigningIdentity -string "$signing_label" "$info_path"
/usr/bin/plutil -replace BabyWorkSandboxMode -string "$sandbox_label" "$info_path"

if [[ "$sandbox_mode" == 1 || "$sandbox_mode" == true || "$sandbox_mode" == TRUE || "$sandbox_mode" == yes || "$sandbox_mode" == YES ]]; then
    /usr/bin/plutil -replace CFBundleIdentifier -string "fr.camille.babywork.sandbox" "$info_path"
    /usr/bin/plutil -replace CFBundleDisplayName -string "BabyWorks (sandbox)" "$info_path"
    /usr/bin/plutil -replace CFBundleName -string "BabyWorksSandbox" "$info_path"
fi

/usr/bin/codesign \
    --force \
    --sign "$signing_identity" \
    --entitlements "$entitlements_path" \
    --options runtime \
    --timestamp=none \
    "$app_path"

/usr/bin/codesign --verify --deep --strict --verbose=2 "$app_path"
/usr/bin/codesign --display --entitlements - "$app_path" 2>&1 | sed -n '1,40p'

print -r -- "$app_path"
print -r -- "Signature: $signing_label"
print -r -- "Sandbox: $sandbox_label"
