# Identité visuelle de CmdBaby

Tout ce dossier, sauf `planche.png` et `source-openclipart-baby-bottle-cc0.svg`, sort de `gen-icons.py`. **On modifie le script, jamais les fichiers générés à la main.**

## Régénérer

```sh
brew install librsvg   # une fois, pour rsvg-convert
python3 docs/assets/brand/gen-icons.py
```

Le script écrit dans son propre dossier, quel que soit le dossier courant. Il est déterministe : le relancer ne change aucun fichier (`git diff --exit-code docs/assets/brand`). Les PDF portent une date figée (`SOURCE_DATE_EPOCH=0`).

## Fichiers

| Fichier | Contenu | Utilisé par |
|---|---|---|
| `icon-jour.svg` | icône complète 1024 × 1024, variante retenue (apparence claire) | site, README |
| `icon-nuit.svg` | même icône, apparence sombre | site, README |
| `icon-ocean.svg` | variante sur fond bleu Oxford | aperçu social |
| `layers/background-{jour,nuit}.svg` | dégradé du fond seul, carré plein, sans squircle ni ombre | Icon Composer (#100) |
| `layers/command-{jour,nuit,mono}.svg` | le ⌘ seul, fond transparent, même position que dans l’icône ; `mono` en blanc | Icon Composer (#100) |
| `layers/bottle-{jour,nuit,mono}.svg` | le biberon seul, même règle ; `mono` en blanc, lait et bulles à 60 % | Icon Composer (#100) |
| `app-icon-jour.pdf`, `app-icon-nuit.pdf` | icône sans ombre portée, PDF vectoriel, page de 1024 × 1024 pt | logo des Réglages (#116) |
| `app-icon-1024.png`, `app-icon-1024-dark.png` | PNG 1024 × 1024, Jour et Nuit, avec ombre | README (#104) |
| `social-preview.png` | 1280 × 640, dégradé Oxford et icône Océan de 440 px, sans texte | aperçu GitHub (#109), `og:image` du site (#111) |
| `menubar-bottle.svg`, `menubar-bottle.pdf` | picto modèle 18 × 18 pt, noir sur transparent ; macOS le teinte | barre de menus (#115) |
| `planche.png` | planche de référence du dessin (non générée) | — |
| `source-openclipart-baby-bottle-cc0.svg` | biberon source (non généré) | — |

## Palettes

- Jour : https://camillehdl.dev/palette
- Nuit : https://camillehdl.dev/palette-night

Les valeurs sont dans les dictionnaires `DAY` et `NIGHT` du script.

## Origine du biberon

Le biberon est un dessin original. Ses proportions s’inspirent d’un biberon OpenClipart en domaine public (CC0), trouvé sur https://freesvg.org/vector-baby-bottle-icon et conservé dans `source-openclipart-baby-bottle-cc0.svg`. Aucune attribution n’est exigée.
