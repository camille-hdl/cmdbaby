#!/bin/zsh
# Téléchargements du DMG par version, d’après les compteurs des GitHub Releases.
# Ils comptent tout : site, liens directs, Homebrew et mises à jour Sparkle.
# Les clics sur le bouton du site sont aussi comptés à part dans GoatCounter (événement « download »).

set -euo pipefail

gh api --paginate repos/camille-hdl/cmdbaby/releases --jq '
  .[] | [.tag_name, (if .prerelease then "pre-release" else "" end),
         ([.assets[] | select(.name | endswith(".dmg")) | .download_count] | add // 0)]
  | @tsv' \
  | awk -F'\t' 'BEGIN { printf "%-10s %-12s %s\n", "Version", "", "DMG" }
                { printf "%-10s %-12s %d\n", $1, $2, $3; total += $3 }
                END { printf "%-10s %-12s %d\n", "Total", "", total }'
