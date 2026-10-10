#!/bin/zsh
# La recherche des .swiftconstvalues reste dans la configuration et l’architecture compilées.
set -euo pipefail

script_dir=${0:A:h}
source "$script_dir/lib/assemble-app.zsh"

root=$(mktemp -d "${TMPDIR:-/tmp}/cmdbaby-const-values.XXXXXX")
only_release=$(mktemp -d "${TMPDIR:-/tmp}/cmdbaby-const-values.XXXXXX")
trap 'rm -rf "$root" "$only_release"' EXIT

mkdir -p \
    "$root/.build/arm64-apple-macosx/debug/Old.build" \
    "$root/.build/arm64-apple-macosx/release/CmdBaby.build" \
    "$root/.build/x86_64-apple-macosx/release/CmdBaby.build" \
    "$root/.build/apple/Products/Release" \
    "$root/.build/apple/Products/Debug" \
    "$root/.build/apple/Intermediates.noindex/CmdBaby.build/Release/CmdBaby.build/Objects-normal/arm64" \
    "$root/.build/apple/Intermediates.noindex/CmdBaby.build/Release/CmdBaby.build/Objects-normal/x86_64" \
    "$root/.build/apple/Intermediates.noindex/CmdBaby.build/Debug/CmdBaby.build/Objects-normal/arm64"

print -n old > "$root/.build/arm64-apple-macosx/debug/Old.build/Old.swiftconstvalues"
print -n rel > "$root/.build/arm64-apple-macosx/release/CmdBaby.build/CmdBaby.swiftconstvalues"
print -n x86 > "$root/.build/x86_64-apple-macosx/release/CmdBaby.build/CmdBaby.swiftconstvalues"
print -n uni > "$root/.build/apple/Intermediates.noindex/CmdBaby.build/Release/CmdBaby.build/Objects-normal/arm64/CmdBaby-primary.swiftconstvalues"
print -n x86uni > "$root/.build/apple/Intermediates.noindex/CmdBaby.build/Release/CmdBaby.build/Objects-normal/x86_64/CmdBaby-primary.swiftconstvalues"
print -n dbg > "$root/.build/apple/Intermediates.noindex/CmdBaby.build/Debug/CmdBaby.build/Objects-normal/arm64/CmdBaby-primary.swiftconstvalues"

arm64_release="$root/.build/arm64-apple-macosx/release/CmdBaby.build/CmdBaby.swiftconstvalues"
arm64_debug="$root/.build/arm64-apple-macosx/debug/Old.build/Old.swiftconstvalues"
universal_arm64="$root/.build/apple/Intermediates.noindex/CmdBaby.build/Release/CmdBaby.build/Objects-normal/arm64/CmdBaby-primary.swiftconstvalues"
universal_debug="$root/.build/apple/Intermediates.noindex/CmdBaby.build/Debug/CmdBaby.build/Objects-normal/arm64/CmdBaby-primary.swiftconstvalues"

expect_exact() {
    local label="$1" expected="$2" actual="$3"
    if [[ "$actual" != "$expected" ]]; then
        print -u2 "Échec : $label"
        print -u2 "attendu : ${expected:-<vide>}"
        print -u2 "obtenu  : ${actual:-<vide>}"
        exit 1
    fi
}

expect_exact \
    "binaire release arm64" \
    "$arm64_release" \
    "$(_app_intents_const_values "$root" "$root/.build/arm64-apple-macosx/release" arm64)"

expect_exact \
    "binaire universel, architecture arm64" \
    "$universal_arm64" \
    "$(_app_intents_const_values "$root" "$root/.build/apple/Products/Release" arm64)"

expect_exact \
    "binaire universel, la casse Debug est conservée" \
    "$universal_debug" \
    "$(_app_intents_const_values "$root" "$root/.build/apple/Products/Debug" arm64)"

expect_exact \
    "binaire debug arm64" \
    "$arm64_debug" \
    "$(_app_intents_const_values "$root" "$root/.build/arm64-apple-macosx/debug" arm64)"

mkdir -p "$only_release/.build/apple/Products/Release" \
    "$only_release/.build/arm64-apple-macosx/debug/Old.build"
print -n old > "$only_release/.build/arm64-apple-macosx/debug/Old.build/Old.swiftconstvalues"
set +e
missing=$( _app_intents_const_values "$only_release" "$only_release/.build/apple/Products/Release" arm64 2>&1 )
missing_status=$?
set -e
if [[ "$missing_status" -eq 0 ]]; then
    print -u2 "Échec : une liste vide doit arrêter la recherche"
    print -u2 "obtenu : ${missing:-<vide>}"
    exit 1
fi
if [[ "$missing" != *"arm64"* || "$missing" != *"Release"* ]]; then
    print -u2 "Échec : le message doit nommer l’architecture et la configuration"
    print -u2 "obtenu : ${missing:-<vide>}"
    exit 1
fi
