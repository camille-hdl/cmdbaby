# Vérification du kiosque

Rempli à la main, sur une session lancée depuis `/Applications/CmdBaby.app` signée. macOS 26 : vérifié le 2026-10-07. macOS 13 : non testé. « Absorbé » : rien ne se passe derrière les couvertures et la scène garde le focus. Colonnes de résultat : ✅ conforme, ❌ passe encore, — non testé.

Depuis #120, le filtre raisonne par catégories : toute combinaison avec Commande ou Contrôle, les touches de fonction F1 à F20, la touche fn/Globe et les touches système (`NX_SYSDEFINED`, sous-type 8) sont absorbées. Les lettres, Maj et Option seuls passent, pour la scène et les sorties adulte.

## Raccourcis absorbés par le filtre

| Raccourci ou touche | Effet sans filtre | Attendu | macOS 26 | macOS 13 |
|---|---|---|---|---|
| Cmd-Espace, Option-Espace, Ctrl-Espace, Ctrl-Option-Espace | Spotlight, sources de saisie | Absorbé | ✅ | — |
| Ctrl-Cmd-Espace | sélecteur d’emojis | Absorbé | ✅ | — |
| Cmd-Option-Espace | recherche du Finder | Absorbé | ✅ | — |
| Ctrl-← / Ctrl-→ | change d’Espace | Absorbé | ✅ | — |
| Ctrl-1 à Ctrl-9 | va à l’Espace n | Absorbé | ✅ | — |
| Ctrl-↑ / Ctrl-↓ | Mission Control, fenêtres de l’app | Absorbé | ✅ | — |
| Cmd-Maj-3, Cmd-Maj-4 | capture d’écran | Absorbé | ✅ | — |
| Cmd-Maj-5 | barre de capture, au-dessus des couvertures | Absorbé | ✅ | — |
| Cmd-F5, Cmd-Option-F5 | VoiceOver, raccourcis d’Accessibilité | Absorbé | ✅ | — |
| Cmd-Option-8 | zoom | Absorbé | ✅ | — |
| Ctrl-Option-Cmd-8 | inversion des couleurs | Absorbé | ✅ | — |
| Cmd-Q, Cmd-H, Cmd-M, Ctrl-Cmd-Q | quitter, masquer, réduire, verrouiller | Absorbé | ✅ | — |
| F11 | afficher le bureau | Absorbé | ✅ | — |
| fn/Globe seule | emojis, dictée ou sources de saisie | Absorbé | ✅ | — |
| Touches média, luminosité, volume | lecture, réglages | Absorbé | ✅ | — |
| Touches Spotlight, Dictée, Ne pas déranger (rangée du haut) | Spotlight, dictée, concentration | Absorbé | ✅ | — |
| Touches Mission Control, Launchpad (rangée du haut) | Mission Control, Launchpad | Absorbé | ✅ | — |

## Couverts par les options de présentation

| Raccourci | Option | Attendu | macOS 26 | macOS 13 |
|---|---|---|---|---|
| Cmd-Tab | `disableProcessSwitching` (et filtre) | Absorbé | ✅ | — |
| Cmd-Option-Échap (Forcer à quitter) | `disableForceQuit` (et filtre) | Absorbé | ✅ | — |
| Cmd-Option-Maj-Q (fermer la session) | `disableSessionTermination` (et filtre) | Absorbé | ✅ | — |
| Mission Control par geste ou touche | `disableProcessSwitching` | Absorbé | ✅ | — |

## Doivent rester possibles

| Action | Attendu | macOS 26 | macOS 13 |
|---|---|---|---|
| Phrase de sortie puis Entrée | Fin de session | ✅ | — |
| Maj-Échap maintenu 1,5 s, Maj seul (si activé) | Fin de session | ✅ | — |
| Maj-Échap bref, ou avec Cmd, Ctrl ou Option | Rien | ✅ | — |
| Cinq clics sur le carré de secours (si activés) | Fin de session | ✅ | — |
| Lettres, chiffres, Espace, Entrée | Réaction de la scène | ✅ | — |

## Hors de portée

Voir `docs/securite.md`, section « Impossible à bloquer depuis une app ».
