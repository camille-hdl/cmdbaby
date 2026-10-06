#!/bin/zsh

set -euo pipefail

script_dir=${0:A:h}
project_dir=${script_dir:h}
configuration=${CONFIGURATION:-release}
# Les variables BABYWORK_* restent acceptées comme anciens noms.
output_dir=${CMDBABY_APP_OUTPUT_DIR:-${BABYWORK_APP_OUTPUT_DIR:-"/Applications"}}
signing_identity=${CMDBABY_CODE_SIGN_IDENTITY:-${BABYWORK_CODE_SIGN_IDENTITY:--}}
sandbox_mode=${CMDBABY_APP_SANDBOX:-${BABYWORK_APP_SANDBOX:-0}}

if [[ "$signing_identity" == "-" ]]; then
    signing_label="Signature ad hoc — impropre à une identité TCC stable"
else
    signing_label="$signing_identity"
fi

case "$sandbox_mode" in
    1|true|TRUE|yes|YES)
        entitlements_path="$project_dir/Resources/CmdBaby.sandbox.entitlements"
        sandbox_label="App Sandbox activé"
        app_name="CmdBaby-sandbox.app"
        ;;
    *)
        entitlements_path="$project_dir/Resources/CmdBaby.nosandbox.entitlements"
        sandbox_label="App Sandbox désactivé"
        app_name="CmdBaby.app"
        ;;
esac

app_path="$output_dir/$app_name"
contents_path="$app_path/Contents"
executable_path="$contents_path/MacOS/CmdBaby"
info_path="$contents_path/Info.plist"

swift build --configuration "$configuration" --product CmdBaby
binary_dir=$(swift build --configuration "$configuration" --show-bin-path)

mkdir -p "$contents_path/MacOS" "$contents_path/Resources"
install -m 755 "$binary_dir/CmdBaby" "$executable_path"
install -m 644 "$project_dir/Resources/CmdBaby-Info.plist" "$info_path"

copy_resource_bundle() {
    local name="$1"
    local source="$binary_dir/$name"
    if [[ ! -d "$source" ]]; then
        print -u2 "Bundle de ressources introuvable : $source"
        exit 1
    fi
    rm -rf "$app_path/$name"
    rm -rf "$contents_path/Resources/$name"
    cp -R "$source" "$contents_path/Resources/$name"
}

copy_resource_bundle "CmdBaby_CmdBaby.bundle"
copy_resource_bundle "CmdBaby_CmdBabyKit.bundle"

if [[ "$sandbox_mode" == 1 || "$sandbox_mode" == true || "$sandbox_mode" == TRUE || "$sandbox_mode" == yes || "$sandbox_mode" == YES ]]; then
    /usr/bin/plutil -replace CFBundleIdentifier -string "app.cmdbaby.CmdBaby.sandbox" "$info_path"
    /usr/bin/plutil -replace CFBundleDisplayName -string "CmdBaby (sandbox)" "$info_path"
    /usr/bin/plutil -replace CFBundleName -string "CmdBabySandbox" "$info_path"
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
if [[ "$signing_identity" == "-" ]]; then
    print -r -- "Rappel TCC : la signature ad hoc change l’identité Accessibilité à chaque rebuild."
    print -r -- "Pour un TCC stable, voir README (Build & run) :"
    print -r -- 'CMDBABY_CODE_SIGN_IDENTITY="$(security find-identity -v -p codesigning | sed -n '\''s/.*"\(Apple Development:.*\)".*/\1/p'\'' | head -1)" CMDBABY_APP_SANDBOX=0 ./scripts/build-app.sh'
fi
