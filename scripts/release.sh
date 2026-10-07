#!/bin/zsh
# Publication : construit dist/CmdBaby-<version>.dmg, signé Developer ID, notarisé et agrafé.
# Construit depuis une copie propre du commit courant (git worktree), jamais depuis le clone de travail.
# Ne publie rien : la mise en ligne est le travail de scripts/publish.sh (#113).
#
# Usage : scripts/release.sh X.Y.Z
# Prérequis (une fois) : scripts/setup-release.sh

set -euo pipefail

script_dir=${0:A:h}
project_dir=${script_dir:h}
cd "$project_dir"

fail() {
    print -u2 "\nÉchec : $1"
    exit 1
}

step() {
    print "\n▸ $1"
}

# ── Pré-vols ────────────────────────────────────────────────────────────────

version=${1:-}
[[ "$version" =~ '^[0-9]+\.[0-9]+\.[0-9]+$' ]] || fail "Usage : scripts/release.sh X.Y.Z (par exemple 1.0.0)."

[[ -z "$(git status --porcelain)" ]] || fail "L’arbre git n’est pas propre : committer ou ranger les changements, puis relancer."

[[ -f scripts/release.env ]] || fail "scripts/release.env manquant : lancer scripts/setup-release.sh."
source scripts/release.env
[[ -n "${RELEASE_TEAM_ID:-}" ]] || fail "RELEASE_TEAM_ID absent de scripts/release.env : lancer scripts/setup-release.sh."
notary_profile=${RELEASE_NOTARY_PROFILE:-cmdbaby-notary}

identity=${RELEASE_SIGN_IDENTITY:-$(security find-identity -v -p codesigning \
    | sed -nE "s/.*\"(Developer ID Application: .*\\($RELEASE_TEAM_ID\\))\".*/\\1/p" | head -n1)}
[[ -n "$identity" ]] || fail "Aucune identité « Developer ID Application » pour l’équipe $RELEASE_TEAM_ID : lancer scripts/setup-release.sh."

xcrun notarytool history --keychain-profile "$notary_profile" >/dev/null 2>&1 \
    || fail "Le profil notarytool « $notary_profile » ne répond pas : lancer scripts/setup-release.sh (étape 5)."

xcode_major=$(xcodebuild -version | sed -nE 's/^Xcode ([0-9]+).*/\1/p')
(( xcode_major >= 26 )) || fail "Xcode 26 ou plus récent est requis (trouvé : $(xcodebuild -version | head -n1))."

build_number=$(git rev-list --count HEAD)
commit=$(git rev-parse --short HEAD)
print "CmdBaby $version (build $build_number, commit $commit)"
print "Identité : $identity"

# ── Copie propre ────────────────────────────────────────────────────────────

work=$(mktemp -d /tmp/cmdbaby-release.XXXXXX)
cleanup() {
    git -C "$project_dir" worktree remove --force "$work/src" >/dev/null 2>&1 || true
    rm -rf "$work"
}
trap cleanup EXIT

step "Copie propre du commit $commit"
git worktree add --quiet --detach "$work/src" HEAD
src="$work/src"

# ── Build universel ─────────────────────────────────────────────────────────

step "Build universel (arm64 + x86_64)"
build_flags=(-c release --arch arm64 --arch x86_64 --only-use-versions-from-resolved-file)
resolved_before=$(shasum -a 256 "$src/Package.resolved" 2>/dev/null || echo "absent")
(cd "$src" && swift build "${build_flags[@]}" --product CmdBaby)
resolved_after=$(shasum -a 256 "$src/Package.resolved" 2>/dev/null || echo "absent")
[[ "$resolved_before" == "$resolved_after" ]] || fail "Package.resolved a changé pendant le build : figer les dépendances et committer."
binary_dir=$(cd "$src" && swift build "${build_flags[@]}" --show-bin-path)

architectures=$(lipo -archs "$binary_dir/CmdBaby")
[[ " $architectures " == *" arm64 "* && " $architectures " == *" x86_64 "* ]] \
    || fail "Le binaire n’est pas universel (architectures : $architectures)."

# ── Assemblage ──────────────────────────────────────────────────────────────

step "Assemblage d’un .app neuf"
source "$src/scripts/lib/assemble-app.zsh"
app="$work/CmdBaby.app"
assemble_app "$binary_dir" "$src" "$app"
/usr/bin/plutil -replace CFBundleShortVersionString -string "$version" "$app/Contents/Info.plist"
/usr/bin/plutil -replace CFBundleVersion -string "$build_number" "$app/Contents/Info.plist"
/usr/bin/plutil -lint "$app/Contents/Info.plist" >/dev/null

# Rien de personnel dans le binaire : chemin du build, e-mail, identité de signature.
leaks=$(strings -a "$app/Contents/MacOS/CmdBaby" | grep -E '/Users/|SigningIdentity|[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[a-z]{2,}' || true)
[[ -z "$leaks" ]] || fail "Le binaire contient un chemin, une adresse ou une identité :\n$leaks"

xattr -cr "$app"

# ── Signature ───────────────────────────────────────────────────────────────

step "Signature Developer ID (de l’intérieur vers l’extérieur, sans --deep)"
for bundle in "$app"/Contents/Resources/*.bundle; do
    codesign --force --sign "$identity" --timestamp "$bundle"
done
codesign --force --sign "$identity" --options runtime --timestamp \
    --entitlements "$src/Resources/CmdBaby.nosandbox.entitlements" "$app"

codesign --verify --strict --verbose=2 "$app"
details=$(codesign -dv --verbose=4 "$app" 2>&1)
team=$(sed -nE 's/^TeamIdentifier=(.*)$/\1/p' <<<"$details")
[[ "$team" == "$RELEASE_TEAM_ID" ]] || fail "Team ID de la signature ($team) différent de RELEASE_TEAM_ID ($RELEASE_TEAM_ID)."
grep -qE '^CodeDirectory .*flags=.*runtime' <<<"$details" || fail "Le hardened runtime n’est pas actif."
grep -q '^Timestamp=' <<<"$details" || fail "La signature n’a pas d’horodatage sécurisé."
entitlement_keys=$(codesign -d --entitlements - --xml "$app" 2>/dev/null | grep -c '<key>' || true)
(( entitlement_keys == 0 )) || fail "La signature porte des entitlements ; ils doivent être vides."

# ── Notarisation ────────────────────────────────────────────────────────────

# notarize <fichier> : soumet, attend, lit le journal et échoue au moindre refus ou problème signalé.
notarize() {
    local file="$1" result id notary_status log
    result=$(xcrun notarytool submit "$file" --keychain-profile "$notary_profile" --wait --output-format json)
    id=$(python3 -c 'import json,sys; print(json.load(sys.stdin)["id"])' <<<"$result")
    notary_status=$(python3 -c 'import json,sys; print(json.load(sys.stdin)["status"])' <<<"$result")
    log=$(xcrun notarytool log "$id" --keychain-profile "$notary_profile")
    if [[ "$notary_status" != "Accepted" ]]; then
        print -u2 "$log"
        fail "Notarisation refusée ($notary_status, soumission $id)."
    fi
    if ! python3 -c 'import json,sys; sys.exit(1 if json.load(sys.stdin).get("issues") else 0)' <<<"$log"; then
        print -u2 "$log"
        fail "La notarisation a accepté $file mais signale des problèmes (soumission $id)."
    fi
    print "Notarisé (soumission $id)."
}

step "Notarisation de l’app"
ditto -c -k --keepParent "$app" "$work/CmdBaby.zip"
notarize "$work/CmdBaby.zip"
xcrun stapler staple "$app"

# ── DMG ─────────────────────────────────────────────────────────────────────

step "DMG"
mkdir -p "$work/dmg"
ditto "$app" "$work/dmg/CmdBaby.app"
ln -s /Applications "$work/dmg/Applications"
dmg="$work/CmdBaby-$version.dmg"
hdiutil create -quiet -volname CmdBaby -srcfolder "$work/dmg" -ov -format UDZO "$dmg"
codesign --force --sign "$identity" --timestamp "$dmg"
notarize "$dmg"
xcrun stapler staple "$dmg"

# ── Contrôles finaux ────────────────────────────────────────────────────────

step "Contrôles Gatekeeper"
spctl --assess --type execute -vv "$app"
spctl -a -t open --context context:primary-signature -vv "$dmg"
xcrun stapler validate "$app"
xcrun stapler validate "$dmg"

# ── Sortie ──────────────────────────────────────────────────────────────────

mkdir -p dist
cp "$dmg" "dist/CmdBaby-$version.dmg"
(cd dist && shasum -a 256 "CmdBaby-$version.dmg" > "CmdBaby-$version.dmg.sha256")

print "\n✓ dist/CmdBaby-$version.dmg"
print "SHA-256 : $(cut -d' ' -f1 "dist/CmdBaby-$version.dmg.sha256")"
