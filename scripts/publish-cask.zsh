#!/bin/zsh
# Met à jour le cask Homebrew après une publication stable.

set -euo pipefail

fail() {
    print -u2 "Échec : $1"
    exit 1
}

[[ $# == 2 || ( $# == 3 && "$3" == "--prerelease" ) ]] \
    || fail "Usage : scripts/publish-cask.zsh VERSION SHA256 [--prerelease]"
version=$1
sha=$2

if [[ "${3:-}" == "--prerelease" ]]; then
    print "Prépublication : mise à jour du cask Homebrew ignorée."
    exit 0
fi

step() {
    print "\n▸ $1"
}

step "Cask Homebrew"
tap_dir=$(mktemp -d /tmp/cmdbaby-tap.XXXXXX)
trap 'rm -rf "$tap_dir"' EXIT
git clone --quiet --depth 1 --branch main https://github.com/camille-hdl/homebrew-tap.git "$tap_dir" \
    || fail "Impossible de cloner camille-hdl/homebrew-tap dans une copie temporaire."
cask="$tap_dir/Casks/cmdbaby.rb"
[[ -f "$cask" ]] || fail "Casks/cmdbaby.rb absent du dépôt homebrew-tap."

update_result=$(scripts/update-cask.zsh "$cask" "$version" "$sha") \
    || fail "Impossible de mettre à jour Casks/cmdbaby.rb."
if [[ "$update_result" == "Cask déjà à jour." ]]; then
    print "Le cask est déjà à $version avec ce SHA-256 : aucune action nécessaire."
else
    if command -v brew >/dev/null 2>&1; then
        brew style "$cask" || fail "brew style refuse Casks/cmdbaby.rb."
    fi
    git -C "$tap_dir" remote set-url origin git@github.com:camille-hdl/homebrew-tap.git \
        || fail "Impossible de configurer le dépôt distant du tap."
    git -C "$tap_dir" add Casks/cmdbaby.rb \
        || fail "Impossible de préparer Casks/cmdbaby.rb pour le commit."
    git -C "$tap_dir" -c commit.gpgsign=true commit --quiet -m "cmdbaby $version" \
        || fail "Impossible de créer le commit signé cmdbaby $version dans le tap."
    [[ "$(git -C "$tap_dir" log -1 --format=%G?)" == G ]] \
        || fail "La signature du commit cmdbaby $version ne se vérifie pas."
    git -C "$tap_dir" push --quiet origin main \
        || fail "Impossible de pousser le cask sur main de camille-hdl/homebrew-tap."
    print "Cask Homebrew mis à jour et poussé sur main."
fi
