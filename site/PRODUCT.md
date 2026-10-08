# Product

<!-- impeccable:product-schema 1 -->

Écrit le 8 octobre 2026 à partir du dépôt et du brief de Camille, sans entretien. Les lignes marquées *(déduit)* viennent du dépôt, pas de Camille : à confirmer ou corriger. Les titres de section restent en anglais, car Impeccable les lit.

## Platform

web

## Users

- Des parents qui travaillent à la maison sur un Mac, et dont le tout-petit vient sur leurs genoux pour taper sur le clavier. Ils arrivent sur cmdbaby.app depuis un lien ou une recherche, lisent la page d'accueil, puis téléchargent l'app ou passent leur chemin. *(déduit du texte du site et du README)*
- Les mêmes parents, plus tard, sur `/support/` ou `/privacy/` : une session qui ne se termine pas, un raccourci qui marche encore, une question sur les données.

## Product Purpose

cmdbaby.app présente CmdBaby, une app macOS gratuite. CmdBaby protège le travail ouvert sur le Mac en se faisant passer pour un jeu : elle couvre l'écran, coupe les raccourcis, et chaque touche fait apparaître quelque chose. Le site réussit quand un parent comprend en une lecture ce que fait l'app, qu'elle ne garde rien de ce qui est tapé, et comment reprendre la main, puis télécharge le DMG ou la cask Homebrew.

## Positioning

Ce n'est pas d'abord un jeu pour enfant, c'est une protection du travail déguisée en jeu, le temps que le tout-petit passe à autre chose. Le site ne met pas le jeu en avant.

## Capabilities and Constraints

- Site statique en HTML écrit à la main dans `site/public/`, en anglais (`/`) et en français (`/fr/`). Les deux langues ont les mêmes pages : accueil, `privacy/`, `support/`, plus une page 404 bilingue.
- Tailwind 4 compile `site/src/style.css` vers `site/public/style.css` (`npm run --prefix site build`). Cloudflare Workers sert `site/public/` en « assets only » (`site/wrangler.jsonc`).
- La CSP de `site/public/_headers` n'autorise que les fichiers du site : `style-src 'self'` interdit les attributs `style` et les balises `<style>`, `script-src 'self'` les scripts en ligne. Aucune police, image ou feuille externe.
- Le seul script est le compteur GoatCounter (`/js/count.js`), avec des attributs `data-goatcounter-click` sur les boutons de téléchargement.
- `/download` redirige vers le DMG de la dernière version sur GitHub (`_redirects`).
- Les captures de l'app (`img/screenshots/`) sortent de `scripts/site-screenshots.sh` : on ne les retouche pas à la main.
- Le thème suit le système (`prefers-color-scheme`), sans sélecteur sur la page.
- Le déploiement passe par `scripts/deploy-site.sh`, lancé par Camille.

## Brand Commitments

- Nom « CmdBaby », icône et logo propres au projet (`docs/assets/brand/`, générés par `gen-icons.py`). Les forks doivent prendre les leurs.
- Palettes ft-paper de jour et ft-paper-night de nuit, publiées sur camillehdl.dev/palette et /palette-night. Le travail de design peut proposer des changements de palette, il ne les applique pas.
- Ton factuel et neutre, à la deuxième personne, sans formule marketing ni histoire personnelle de Camille. Les scènes ne sont pas détaillées une à une, et aucune nouvelle scène n'est promise.
- Le texte du site (promesses, mentions, liens de téléchargement, compteur) ne change pas sans l'accord de Camille.

## Evidence on Hand

- Captures des Réglages de l'app, jour et nuit, en anglais et en français : `site/public/img/screenshots/`.
- Illustrations de Kenney (CC0) dans l'app.
- Aucun témoignage, chiffre d'usage ou avis : ne pas en inventer.

## Product Principles

1. Le travail du parent d'abord : chaque section répond à « mon travail est-il à l'abri, et comment je reviens ? ».
2. Rien de caché : pas de compte, pas de statistiques d'usage dans l'app, et le site le dit simplement.
3. Une page qui se lit vite, sur un Mac comme sur un téléphone, de jour comme de nuit.

## Accessibility & Inclusion

- Textes à 4.5:1 au moins sur leur fond, de jour et de nuit.
- Navigation complète au clavier, focus visible, lien d'évitement vers le contenu.
- Les deux langues sont déclarées (`lang`, `hreflang`) pour les lecteurs d'écran et les moteurs de recherche.
