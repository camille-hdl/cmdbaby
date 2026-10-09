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
info_path="$contents_path/Info.plist"

source "$script_dir/lib/assemble-app.zsh"
prepare_app_intents_swift_flags "$project_dir"
swift build --configuration "$configuration" --product CmdBaby "${app_intents_swift_flags[@]}"
binary_dir=$(swift build --configuration "$configuration" --show-bin-path --product CmdBaby)

assemble_app "$binary_dir" "$project_dir" "$app_path"
compile_app_icon "$project_dir" "$app_path" optional

if [[ "$sandbox_mode" == 1 || "$sandbox_mode" == true || "$sandbox_mode" == TRUE || "$sandbox_mode" == yes || "$sandbox_mode" == YES ]]; then
    /usr/bin/plutil -replace CFBundleIdentifier -string "app.cmdbaby.CmdBaby.sandbox" "$info_path"
    /usr/bin/plutil -replace CFBundleDisplayName -string "CmdBaby (sandbox)" "$info_path"
    /usr/bin/plutil -replace CFBundleName -string "CmdBabySandbox" "$info_path"
fi

install_app_intents_metadata "$binary_dir" "$project_dir" "$app_path"

# Hardened runtime, sauf en signature ad hoc : sans Team ID, la validation des bibliothèques
# refuserait de charger Sparkle.framework. Un build ad hoc n’est jamais distribué.
runtime_options=(--options runtime)
if [[ "$signing_identity" == "-" ]]; then
    runtime_options=()
fi

sign_sparkle "$signing_identity" "$app_path" "${runtime_options[@]}" --timestamp=none

/usr/bin/codesign \
    --force \
    --sign "$signing_identity" \
    --entitlements "$entitlements_path" \
    "${runtime_options[@]}" \
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
