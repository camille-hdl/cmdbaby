#!/bin/zsh
# Déploie site/ sur Cloudflare Workers. À lancer depuis la racine du dépôt.
# Les arguments sont passés à `wrangler deploy` : `--dry-run` ne demande pas de connexion.

set -euo pipefail

if ! command -v npx >/dev/null 2>&1; then
    print -u2 "npx introuvable. Installer Node.js : brew install node"
    exit 1
fi

if [[ ! -f site/wrangler.jsonc ]]; then
    print -u2 "site/wrangler.jsonc introuvable : lancer ce script depuis la racine du dépôt."
    exit 1
fi

refused=$(find site/public -type f \( -size +25M -o -name '*.dmg' -o -name '*.zip' \))
if [[ -n "$refused" ]]; then
    print -u2 "Fichiers refusés dans site/public (plus de 25 Mio, .dmg ou .zip) :"
    print -u2 -- "$refused"
    print -u2 "Les DMG vont dans les GitHub Releases, pas sur le site : voir #113."
    exit 1
fi

if [[ -f site/public/appcast.xml ]]; then
    if ! xmllint --noout site/public/appcast.xml; then
        print -u2 "site/public/appcast.xml n’est pas un XML valide : corriger l’appcast avant de déployer."
        exit 1
    fi
fi

print "Installation de Wrangler et Tailwind (versions épinglées dans site/package-lock.json)…"
npm ci --prefix site --ignore-scripts --no-audit --no-fund

print "Compilation de la feuille de style (Tailwind)…"
npm run --prefix site build

print "Déploiement…"
npm exec --prefix site -- wrangler deploy --config site/wrangler.jsonc "$@"

if (( ${@[(Ie)--dry-run]} == 0 )); then
    print "En ligne : https://cmdbaby.app"
fi
