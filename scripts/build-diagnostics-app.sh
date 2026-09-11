#!/bin/zsh

set -euo pipefail

script_dir=${0:A:h}
project_dir=${script_dir:h}
configuration=${CONFIGURATION:-release}
output_dir=${BABYWORK_APP_OUTPUT_DIR:-"$project_dir/.build/app"}
app_path="$output_dir/BabyWorkDiagnostics.app"
contents_path="$app_path/Contents"
executable_path="$contents_path/MacOS/BabyWorkDiagnostics"
info_path="$contents_path/Info.plist"
signing_identity=${BABYWORK_CODE_SIGN_IDENTITY:--}
sandbox_mode=${BABYWORK_APP_SANDBOX:-0}

if [[ "$signing_identity" == "-" ]]; then
    signing_label="Signature ad hoc — impropre à une identité TCC stable"
else
    signing_label="$signing_identity"
fi

case "$sandbox_mode" in
    1|true|TRUE|yes|YES)
        entitlements_path="$project_dir/Resources/DiagnosticApp.sandbox.entitlements"
        sandbox_label="App Sandbox activé"
        ;;
    *)
        entitlements_path="$project_dir/Resources/DiagnosticApp.nosandbox.entitlements"
        sandbox_label="App Sandbox désactivé"
        ;;
esac

swift build --configuration "$configuration" --product BabyWorkDiagnostics
binary_dir=$(swift build --configuration "$configuration" --show-bin-path)

mkdir -p "$contents_path/MacOS"
install -m 755 "$binary_dir/BabyWorkDiagnostics" "$executable_path"
install -m 644 "$project_dir/Resources/DiagnosticApp-Info.plist" "$info_path"
/usr/bin/plutil -replace BabyWorkSigningIdentity -string "$signing_label" "$info_path"
/usr/bin/plutil -replace BabyWorkSandboxMode -string "$sandbox_label" "$info_path"

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
