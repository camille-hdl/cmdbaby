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

if [[ "$signing_identity" == "-" ]]; then
    signing_label="Signature ad hoc — impropre à une identité TCC stable"
else
    signing_label="$signing_identity"
fi

swift build --configuration "$configuration" --product BabyWorkDiagnostics
binary_dir=$(swift build --configuration "$configuration" --show-bin-path)

mkdir -p "$contents_path/MacOS"
install -m 755 "$binary_dir/BabyWorkDiagnostics" "$executable_path"
install -m 644 "$project_dir/Resources/DiagnosticApp-Info.plist" "$info_path"
/usr/bin/plutil -replace BabyWorkSigningIdentity -string "$signing_label" "$info_path"

/usr/bin/codesign \
    --force \
    --sign "$signing_identity" \
    --options runtime \
    --timestamp=none \
    "$app_path"

/usr/bin/codesign --verify --deep --strict --verbose=2 "$app_path"

print -r -- "$app_path"
