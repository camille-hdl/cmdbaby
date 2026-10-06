#!/bin/zsh
# Captures des Réglages pour le site : construit l’app en debug dans un dossier temporaire,
# la fait se dessiner hors écran (configuration de démonstration, jamais la vraie),
# puis écrit site/public/img/screenshots/<section>-<light|dark>-<en|fr>.webp.
# À lancer depuis la racine du dépôt.

set -euo pipefail

if ! command -v magick >/dev/null 2>&1; then
    print -u2 "magick introuvable. Installer ImageMagick : brew install imagemagick"
    exit 1
fi

work=$(mktemp -d "${TMPDIR:-/tmp}/cmdbaby-screenshots.XXXXXX")
trap 'rm -rf "$work"' EXIT
out=site/public/img/screenshots
mkdir -p "$out"

print "Construction de l’app en debug…"
CONFIGURATION=debug CMDBABY_APP_OUTPUT_DIR="$work" ./scripts/build-app.sh >/dev/null 2>&1
binary="$work/CmdBaby.app/Contents/MacOS/CmdBaby"

for lang in en fr; do
    for section in mode exits; do
        for look in light dark; do
            png="$work/$section-$look-$lang.png"
            "$binary" -AppleLanguages "($lang)" --snapshot-settings "$section" "$look" "$png" >/dev/null 2>&1
            if [[ ! -s "$png" ]]; then
                print -u2 "Capture manquante : $section $look $lang"
                exit 1
            fi
            magick "$png" -strip -quality 88 "$out/$section-$look-$lang.webp"
            print "  $out/$section-$look-$lang.webp"
        done
    done
done

# Scène Océan seule, découpée dans la carte du mode (capture 2x), pour l’illustration multi-écran.
magick "$work/mode-light-en.png" -crop 336x236+502+190 +repage -strip -quality 88 site/public/img/ocean-scene.webp
print "  site/public/img/ocean-scene.webp"
