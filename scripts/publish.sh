#!/bin/zsh
# Met en ligne une version produite par scripts/release.sh : Release GitHub immuable avec le DMG,
# puis appcast et lien /download sur https://cmdbaby.app. Dans cet ordre, pour que Sparkle
# ne pointe jamais vers un fichier absent.
#
# Usage : scripts/publish.sh X.Y.Z [--prerelease]
# Relancer la même commande après un échec reprend là où elle s’était arrêtée.

set -euo pipefail

script_dir=${0:A:h}
project_dir=${script_dir:h}
cd "$project_dir"

repo=camille-hdl/cmdbaby

fail() {
    print -u2 "\nÉchec : $1"
    exit 1
}

step() {
    print "\n▸ $1"
}

# curl_site [options…] URL : curl vers cmdbaby.app en résolvant par 1.1.1.1. Le cache DNS du Mac
# (ou d’un VPN) peut garder un « nom inconnu » longtemps après la création du domaine.
curl_site() {
    local ip
    ip=$(dig +short A cmdbaby.app @1.1.1.1 2>/dev/null | grep -E '^[0-9.]+$' | head -n1)
    if [[ -n "$ip" ]]; then
        curl --resolve "cmdbaby.app:443:$ip" "$@"
    else
        curl "$@"
    fi
}

# ── Pré-vols ────────────────────────────────────────────────────────────────

version=${1:-}
[[ "$version" =~ '^[0-9]+\.[0-9]+\.[0-9]+$' ]] || fail "Usage : scripts/publish.sh X.Y.Z [--prerelease]"
prerelease=()
[[ "${2:-}" == "--prerelease" ]] && prerelease=(--prerelease)

tag="v$version"
dmg="dist/CmdBaby-$version.dmg"
dmg_url="https://github.com/$repo/releases/download/$tag/CmdBaby-$version.dmg"

[[ -f "$dmg" && -f "$dmg.sha256" ]] || fail "$dmg absent : lancer scripts/release.sh $version."
[[ -f dist/appcast.xml ]] || fail "dist/appcast.xml absent : lancer scripts/release.sh $version."

[[ -z "$(git status --porcelain)" ]] || fail "L’arbre git n’est pas propre : committer ou ranger les changements."
[[ "$(git rev-parse --abbrev-ref HEAD)" == "main" ]] || fail "Publier depuis la branche main."
git fetch --quiet origin main
[[ "$(git rev-parse HEAD)" == "$(git rev-parse origin/main)" ]] || fail "main n’est pas à jour avec origin/main : pousser ou tirer d’abord."

gh auth status >/dev/null 2>&1 || fail "gh n’est pas connecté : gh auth login."
[[ "$(gh repo view $repo --json visibility --jq .visibility)" == "PUBLIC" ]] \
    || fail "Le dépôt n’est pas public : Sparkle et Homebrew doivent télécharger le DMG sans compte (#109)."
[[ "$(gh api repos/$repo/immutable-releases --jq .enabled 2>/dev/null)" == "true" ]] \
    || fail "Les Releases immuables ne sont pas activées (Settings › General › Immutable releases)."

source scripts/release.env

step "Contrôle du DMG"
xcrun stapler validate "$dmg" >/dev/null || fail "Le DMG n’est pas agrafé : relancer scripts/release.sh $version."
spctl -a -t open --context context:primary-signature "$dmg" 2>/dev/null || fail "Gatekeeper refuse le DMG."
mount=$(mktemp -d /tmp/cmdbaby-publish.XXXXXX)
hdiutil attach -quiet -nobrowse -readonly -mountpoint "$mount" "$dmg"
team=$(codesign -dv --verbose=4 "$mount/CmdBaby.app" 2>&1 | sed -nE 's/^TeamIdentifier=(.*)$/\1/p')
dmg_version=$(/usr/bin/plutil -extract CFBundleShortVersionString raw "$mount/CmdBaby.app/Contents/Info.plist")
hdiutil detach -quiet "$mount"
rmdir "$mount"
[[ "$team" == "$RELEASE_TEAM_ID" ]] || fail "Team ID de l’app du DMG ($team) différent de RELEASE_TEAM_ID ($RELEASE_TEAM_ID)."
[[ "$dmg_version" == "$version" ]] || fail "L’app du DMG est en version $dmg_version, pas $version."

grep -qF "$dmg_url" dist/appcast.xml || fail "dist/appcast.xml ne contient pas $dmg_url : relancer scripts/release.sh $version."
grep -q "sparkle-signatures" dist/appcast.xml || fail "dist/appcast.xml n’est pas signé : relancer scripts/release.sh $version."

local_sha=$(cut -d' ' -f1 "$dmg.sha256")
[[ "$(shasum -a 256 "$dmg" | cut -d' ' -f1)" == "$local_sha" ]] || fail "$dmg ne correspond plus à son .sha256."

# ── Tag et Release ──────────────────────────────────────────────────────────

step "Release GitHub $tag"
if gh release view "$tag" --repo $repo --json assets --jq '.assets[].name' 2>/dev/null | grep -qx "CmdBaby-$version.dmg"; then
    print "La Release $tag existe déjà avec son DMG : étape sautée."
else
    if git ls-remote --exit-code --tags origin "refs/tags/$tag" >/dev/null 2>&1; then
        fail "Le tag $tag existe sans Release complète. Les Releases sont immuables : publier une nouvelle version."
    fi
    git tag -s "$tag" -m "CmdBaby $version"
    git tag -v "$tag" >/dev/null 2>&1 || fail "La signature du tag $tag ne se vérifie pas (git tag -v)."
    git push --quiet origin "$tag"
    gh release create "$tag" "$dmg" --repo $repo --title "CmdBaby $version" \
        --generate-notes --verify-tag "${prerelease[@]}"
fi
print "La Release existe désormais. En cas d’échec plus loin, relancer la même commande."

# ── Intégrité du téléchargement ─────────────────────────────────────────────

step "Retéléchargement du DMG publié"
curl -fsIL "$dmg_url" >/dev/null || fail "$dmg_url ne répond pas."
download=$(mktemp -d /tmp/cmdbaby-download.XXXXXX)
curl -fsSL -o "$download/dmg" "$dmg_url"
remote_sha=$(shasum -a 256 "$download/dmg" | cut -d' ' -f1)
rm -rf "$download"
[[ "$remote_sha" == "$local_sha" ]] || fail "Le DMG publié ($remote_sha) diffère du DMG local ($local_sha)."
print "SHA-256 identique."

# ── Site : appcast et /download ─────────────────────────────────────────────

step "Appcast et lien de téléchargement"
cp dist/appcast.xml site/public/appcast.xml
redirects=site/public/_redirects
grep -q '^/download ' "$redirects" || fail "$redirects n’a pas de ligne /download."
sed -i '' -E "s#^/download .*#/download $dmg_url 302#" "$redirects"

step "Déploiement du site"
scripts/deploy-site.sh

step "Contrôle du site en ligne"
served=""
for _ in $(seq 1 24); do
    served=$(curl_site -fsS "https://cmdbaby.app/appcast.xml" 2>/dev/null || true)
    [[ "$served" == "$(cat site/public/appcast.xml)" ]] && break
    sleep 5
done
[[ "$served" == "$(cat site/public/appcast.xml)" ]] || fail "L’appcast servi par https://cmdbaby.app diffère du fichier local."
location=""
for _ in $(seq 1 24); do
    location=$(curl_site -sI "https://cmdbaby.app/download" | sed -nE 's/^[Ll]ocation: ([^[:space:]]+).*/\1/p')
    [[ "$location" == "$dmg_url" ]] && break
    sleep 5
done
[[ "$location" == "$dmg_url" ]] || fail "https://cmdbaby.app/download redirige vers « $location », pas vers $dmg_url."

# ── Enregistrement ──────────────────────────────────────────────────────────

step "Commit de l’appcast et du lien"
git add site/public/_redirects site/public/appcast.xml
if ! git diff --cached --quiet; then
    git commit --quiet -m "Publier CmdBaby $version."
    git push --quiet origin main
fi

# ── Cask Homebrew ────────────────────────────────────────────────────────────

step "Cask Homebrew"
tap_dir=$(mktemp -d /tmp/cmdbaby-tap.XXXXXX)
trap 'rm -rf "$tap_dir"' EXIT
git clone --quiet --depth 1 --branch main https://github.com/camille-hdl/homebrew-tap.git "$tap_dir" \
    || fail "Impossible de cloner camille-hdl/homebrew-tap dans une copie temporaire."
cask="$tap_dir/Casks/cmdbaby.rb"
[[ -f "$cask" ]] || fail "Casks/cmdbaby.rb absent du dépôt homebrew-tap."

update_result=$(scripts/update-cask.zsh "$cask" "$version" "$remote_sha") \
    || fail "Impossible de mettre à jour Casks/cmdbaby.rb."
if [[ "$update_result" == "Cask déjà à jour." ]]; then
    print "Le cask est déjà à $version avec ce SHA-256 : aucune action nécessaire."
else
    if command -v brew >/dev/null 2>&1; then
        brew style "$cask" || fail "brew style refuse Casks/cmdbaby.rb."
    fi
    git -C "$tap_dir" remote set-url origin git@github.com:camille-hdl/homebrew-tap.git
    git -C "$tap_dir" add Casks/cmdbaby.rb
    git -C "$tap_dir" -c commit.gpgsign=true commit --quiet -m "cmdbaby $version" \
        || fail "Impossible de créer le commit signé cmdbaby $version dans le tap."
    [[ "$(git -C "$tap_dir" log -1 --format=%G?)" == G ]] \
        || fail "La signature du commit cmdbaby $version ne se vérifie pas."
    git -C "$tap_dir" push --quiet origin main \
        || fail "Impossible de pousser le cask sur main de camille-hdl/homebrew-tap."
    print "Cask Homebrew mis à jour et poussé sur main."
fi

print "\n✓ CmdBaby $version en ligne"
print "Release : https://github.com/$repo/releases/tag/$tag"
print "DMG : $dmg_url"
print "SHA-256 : $local_sha"
print "Cask Homebrew : version $version et SHA-256 $remote_sha."
