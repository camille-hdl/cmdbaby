---
name: cmdbaby.app
description: Une page de produit sur papier ft-paper, avec une édition de nuit.
typography:
  display:
    fontFamily: "ui-serif, New York, Georgia, Times New Roman, serif"
    fontSize: "3rem → 4.5rem (text-5xl, sm:text-7xl)"
    fontWeight: 700
    lineHeight: 1.1
  headline:
    fontFamily: "ui-serif, New York, Georgia, Times New Roman, serif"
    fontSize: "1.875rem → 2.25rem (text-3xl, sm:text-4xl)"
    fontWeight: 700
    lineHeight: 1.25
  title:
    fontFamily: "ui-serif, New York, Georgia, Times New Roman, serif"
    fontSize: "1.5rem (text-2xl)"
    fontWeight: 700
  body:
    fontFamily: "-apple-system, BlinkMacSystemFont, Segoe UI, Roboto, sans-serif"
    fontSize: "1.125rem → 1.25rem (text-lg, sm:text-xl)"
    fontWeight: 400
    lineHeight: 1.625
  label:
    fontFamily: "-apple-system, BlinkMacSystemFont, Segoe UI, Roboto, sans-serif"
    fontSize: "0.875rem (text-sm)"
    fontWeight: 400
  code:
    fontFamily: "ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace"
    fontSize: "0.9em"
rounded:
  focus: "0.25rem"
  code: "6px"
  screenshot: "16px"
  key: "12px"
  panel: "2.5rem"
  pill: "9999px"
spacing:
  gutter-phone: "1rem"
  gutter: "2rem"
  section: "4rem → 6rem"
---

# Design System: cmdbaby.app

Les couleurs ne sont pas recopiées ici : elles vivent dans le bloc `@theme` de `site/src/style.css` (jour) et dans son bloc `prefers-color-scheme: dark` (nuit). Ce fichier décrit leurs rôles. Les titres restent en anglais, car Impeccable les lit.

## Overview

**Étoile du nord : « Le papier saumon »**

Une page de produit posée sur le papier ft-paper : fond saumon, encre ardoise, titres en serif, texte en sans-serif système. Une seule couleur d'action, le bordeaux (`claret`). Les autres teintes de la palette n'apparaissent qu'en version douce (`*-soft`), comme fonds de panneaux et comme coups de surligneur sous un mot par titre.

La nuit, c'est le même papier dans le noir : fond brun chaud, encre blé, les mêmes accents éclaircis jusqu'à 4.5:1. Le site suit le thème du système.

**Caractéristiques :**

- un seul bouton plein, bordeaux, en pilule ;
- un surligneur à la main (`.marker`) sous un mot de chaque titre, d'une teinte douce propre à la section ;
- des captures de l'app en grand, arrondies, avec une ombre douce ;
- aucune police, image ou feuille externe : la CSP ne l'autorise pas.

## Colors

Palette ft-paper (jour) et ft-paper-night (nuit), de camillehdl.dev/palette. Toute proposition de changement de palette va à Camille, elle ne s'applique pas directement.

### Primary

- **Claret** (`--color-claret`) : bouton de téléchargement, liens, survol de la navigation. Texte du bouton en `on-claret`.

### Neutral

- **Paper** (`--color-paper`) : fond de page.
- **Raised** (`--color-raised`) : touches du clavier dessinées, lien d'évitement.
- **Surface** et **Surface 2** (`--color-surface`, `--color-surface-2`) : encadré de téléchargement final, fond du `code` en ligne.
- **Rule** (`--color-rule`) : bordures, filet du pied de page, anneau des captures.
- **Ink**, **Ink 2**, **Muted** : titres, texte courant, mentions. Tous trois passent 4.5:1 sur `paper`, `raised`, `surface` et les fonds doux, de jour et de nuit.

### Tertiary

- **Teintes douces** (`claret-soft`, `teal-soft`, `velvet-soft`, `jade-soft`, `mandarin-soft`) : fonds de panneaux et surligneurs. Leurs teintes pleines (`teal`, `velvet`, `jade`, `mandarin`, `oxford`) existent dans la palette ; seul `velvet` sert, pour barrer les raccourcis.

### Named Rules

**La règle du bordeaux seul.** Un seul accent d'action, `claret`. Les autres teintes ne portent jamais de texte ni de bouton.

## Typography

**Titres :** `ui-serif` (New York sur Mac), repli Georgia.
**Texte :** sans-serif système (San Francisco sur Mac).

Le site vise surtout des visiteurs sur Mac, où ces piles donnent New York et San Francisco sans rien télécharger.

### Hierarchy

- **Display** (700, 3rem puis 4.5rem, 1.1) : titre de l'accueil, centré.
- **Headline** (700, 1.875rem puis 2.25rem) : titres de section de l'accueil, h1 des pages secondaires (2.25rem puis 3rem).
- **Title** (700, 1.5rem) : h2 des pages secondaires ; les h3 de la FAQ sont en sans-serif 600, 1.125rem.
- **Body** (400, 1.125rem puis 1.25rem, 1.625) : paragraphes, en `ink-2`, colonnes de 42 à 48rem au plus.
- **Label** (400, 0.875rem) : mentions sous les boutons, pied de page, en `muted`.
- **Code** (monospace système, 0.9em) : commande Homebrew, phrase de sortie, adresse de l'appcast, chemins de fichiers, sur fond `surface-2`.

## Layout

Colonne centrée, conteneurs `max-w-3xl` à `max-w-6xl`, gouttière de 1rem sur téléphone et 2rem au-delà de 640px. L'accueil alterne des sections de texte seul, des panneaux arrondis colorés et des grilles à deux colonnes (texte et illustration) à partir de 768px. Toutes les sections de l'accueil partagent le conteneur `max-w-6xl` et son bord gauche ; un texte seul y garde 48rem au plus. Seuls l'accroche et l'encadré de téléchargement final sont centrés. Les pages secondaires sont une colonne de 42rem ; dans la FAQ, une question est à 12px de sa réponse et à 36px du paragraphe précédent.

Les titres équilibrent leurs lignes (`text-wrap: balance`), les paragraphes évitent le mot seul en dernière ligne (`text-wrap: pretty`). Un mot composé d'un grand titre ou une commande à copier ne se coupe pas (`whitespace-nowrap`), tant que la page ne déborde pas à 320px.

## Elevation & Depth

Le papier est plat. Deux éléments seulement ont une ombre : les captures de l'app (`shadow-2xl` teintée d'encre, anneau `rule`) et le bouton de téléchargement (`shadow-lg` teintée de bordeaux, qui grandit au survol).

## Shapes

Pilules pour le bouton et le lien de langue, panneaux à 2.5rem, captures à 16px, touches à 12px avec une bordure basse de 4px, `code` à 6px.

## Components

- **Bouton de téléchargement** : pilule `claret`, texte `on-claret` 600, 2rem sur 1rem de marge interne. Toujours suivi des deux mentions (prix et systèmes, cask Homebrew).
- **Surligneur** (`.marker`) : dégradé de 0.55em de haut sous le mot. Sa teinte vient d’une classe `marker-<teinte>` posée sur la section ; sur un panneau `teal-soft`, `marker-teal` mélange 30 % de `teal` pour rester visible.
- **Touche** (`kbd`) : fond `raised`, bordure `rule` épaissie en bas, texte `muted` barré en `velvet`.
- **Panneau** : fond doux, coins de 2.5rem, sans bordure ni ombre.

### Surfaces du navigateur

- **Focus** : anneau `claret` de 2px, décalé de 3px, sur tout élément focalisé au clavier.
- **Sélection** : fond `mandarin-soft`, encre `ink`, comme le surligneur.
- **Page courante** : `aria-current="page"` sur le lien de l'en-tête, en `claret`.
- **Mouvement** : le bouton ne se soulève au survol que hors `prefers-reduced-motion`.

## Do's and Don'ts

- **Faire** passer toute nouvelle couleur par les jetons de `site/src/style.css`, de jour et de nuit.
- **Faire** les variantes par des classes de `site/src/style.css`, jamais par un attribut `style` : la CSP les bloque.
- **Faire** suivre `paper` aux balises `theme-color` de chaque page si la palette change : elles recopient sa valeur de jour et de nuit.
- **Ne pas** charger de police ou de ressource externe.
- **Ne pas** retoucher les captures de l'app à la main : elles sortent de `scripts/site-screenshots.sh`.
- **Ne pas** changer le texte sans l'accord de Camille.
