#!/bin/zsh
# Met à jour la version et le SHA-256 d'un cask Homebrew existant.

set -euo pipefail

fail() {
    print -u2 "Échec : $1"
    exit 1
}

[[ $# == 3 ]] || fail "Usage : scripts/update-cask.zsh CASK VERSION SHA256"
cask=$1
version=$2
sha=$3

[[ -f "$cask" ]] || fail "Cask absent : $cask."
[[ "$version" =~ '^[0-9]+\.[0-9]+\.[0-9]+$' ]] || fail "Version invalide : $version."
[[ "$sha" =~ '^[a-f0-9]{64}$' ]] || fail "SHA-256 invalide."

version_count=$(grep -cE '^  version "[^"[:cntrl:]]+"$' "$cask" || true)
sha_count=$(grep -cE '^  sha256 "[a-f0-9]{64}"$' "$cask" || true)
[[ "$version_count" == 1 && "$sha_count" == 1 ]] || fail "Le cask doit contenir exactement une version et un SHA-256 au format attendu."

if grep -Fxq "  version \"$version\"" "$cask" && grep -Fxq "  sha256 \"$sha\"" "$cask"; then
    print "Cask déjà à jour."
    exit 0
fi

CASK_VERSION="$version" CASK_SHA="$sha" perl -0pi -e '
    s/^  version "[^"\n]+"$/  version "$ENV{CASK_VERSION}"/m;
    s/^  sha256 "[a-f0-9]{64}"$/  sha256 "$ENV{CASK_SHA}"/m;
' "$cask"

grep -Fxq "  version \"$version\"" "$cask" || fail "La version du cask n’a pas été mise à jour."
grep -Fxq "  sha256 \"$sha\"" "$cask" || fail "Le SHA-256 du cask n’a pas été mis à jour."
print "Cask mis à jour : $version ($sha)."
