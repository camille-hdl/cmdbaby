#!/bin/zsh
# La recherche des .swiftconstvalues reste dans la configuration et l’architecture compilées.
set -euo pipefail

script_dir=${0:A:h}
source "$script_dir/lib/assemble-app.zsh"

root=$(mktemp -d "${TMPDIR:-/tmp}/cmdbaby-const-values.XXXXXX")
trap 'rm -rf "$root"' EXIT

mkdir -p \
    "$root/.build/arm64-apple-macosx/debug/Old.build" \
    "$root/.build/arm64-apple-macosx/release/CmdBaby.build" \
    "$root/.build/x86_64-apple-macosx/release/CmdBaby.build" \
    "$root/.build/apple/Products/Release"

print -n old > "$root/.build/arm64-apple-macosx/debug/Old.build/Old.swiftconstvalues"
print -n rel > "$root/.build/arm64-apple-macosx/release/CmdBaby.build/CmdBaby.swiftconstvalues"
print -n x86 > "$root/.build/x86_64-apple-macosx/release/CmdBaby.build/CmdBaby.swiftconstvalues"

arm64_release="$root/.build/arm64-apple-macosx/release/CmdBaby.build/CmdBaby.swiftconstvalues"
arm64_debug="$root/.build/arm64-apple-macosx/debug/Old.build/Old.swiftconstvalues"

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
    "$arm64_release" \
    "$(_app_intents_const_values "$root" "$root/.build/apple/Products/Release" arm64)"

expect_exact \
    "binaire debug arm64" \
    "$arm64_debug" \
    "$(_app_intents_const_values "$root" "$root/.build/arm64-apple-macosx/debug" arm64)"

only_debug=$(mktemp -d "${TMPDIR:-/tmp}/cmdbaby-const-values.XXXXXX")
trap 'rm -rf "$root" "$only_debug"' EXIT
mkdir -p "$only_debug/.build/arm64-apple-macosx/debug/Old.build"
print -n old > "$only_debug/.build/arm64-apple-macosx/debug/Old.build/Old.swiftconstvalues"
expect_exact \
    "release sans const values ne reprend pas le debug" \
    "" \
    "$(_app_intents_const_values "$only_debug" "$only_debug/.build/apple/Products/Release" arm64)"
