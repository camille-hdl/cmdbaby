#!/bin/zsh

set -euo pipefail

script_dir=${0:A:h}
project_dir=${script_dir:h:h}
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

fail() {
    print -u2 "Échec du test : $1"
    exit 1
}

cask="$tmp/cmdbaby.rb"
cp "$project_dir/Tests/fixtures/cmdbaby.rb" "$cask"
version=1.2.3
sha=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa

output=$("$project_dir/scripts/update-cask.zsh" "$cask" "$version" "$sha")
[[ "$output" == *"Cask mis à jour"* ]] || fail "la mise à jour n’est pas signalée"
grep -Fxq "  version \"$version\"" "$cask" || fail "la version n’a pas changé"
grep -Fxq "  sha256 \"$sha\"" "$cask" || fail "le SHA-256 n’a pas changé"
grep -Fq 'url "https://github.com/camille-hdl/cmdbaby/releases/download/v#{version}/CmdBaby-#{version}.dmg"' "$cask" || fail "le reste du cask a été modifié"

before=$(shasum -a 256 "$cask" | cut -d' ' -f1)
output=$("$project_dir/scripts/update-cask.zsh" "$cask" "$version" "$sha")
after=$(shasum -a 256 "$cask" | cut -d' ' -f1)
[[ "$output" == *"déjà à jour"* && "$before" == "$after" ]] || fail "la répétition n’est pas idempotente"

if "$project_dir/scripts/update-cask.zsh" "$cask" "$version" invalid >/dev/null 2>&1; then
    fail "un SHA-256 invalide a été accepté"
fi

print "Tests du cask réussis."
