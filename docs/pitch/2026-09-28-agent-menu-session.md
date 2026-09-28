# Pitch — Agent barre de menus + session à la demande

**Date :** 2026-09-28  
**Repo :** camille-hdl/babywork  
**Appétit :** petit+ (revue en une séance ; hors tranche : combo de sortie configurable, polish Galaxie, sandbox/notarization publication)

## Problème

Aujourd’hui BabyWorks lance le kiosque dès l’ouverture et toute sortie adulte (passphrase, Maj+Échap, 5 clics, timer) démonte puis **termine le process**. Il n’y a ni contrôle parent idle, ni préférences persistées, ni façon propre de relancer une session sans relancer l’app. Pour un usage quotidien (et une publication), l’app doit pouvoir vivre discrètement et n’entrer en kiosque que sur action adulte.

## Solution (éléments)

**Places**
- Barre de menus (agent) : status item template SF Symbol
- Menu status (fixe) : Lancer session · Réglages… · Quitter
- Fenêtre Réglages : choix du mode · démarrage automatique (Login Item)
- Session kiosque : couverture multi-écrans + filtre (inchangé fonctionnellement)
- Alerte d’échec : message clair + ouvrir Réglages / Accessibilité

**Affordance → flèches**
- Lancer session → active le kiosque (mode lu dans la config)
- Réglages… → fenêtre Réglages
- Sortie adulte / timer → fin de session, retour idle (🐠/symbol), **process reste**
- Quitter (hors session) → terminate
- Démarrage auto → Login Item `SMAppService` : au login Mac, app idle seulement (pas de session auto)

**Esquisse :** [variante B](2026-09-28-agent-menu-session-sketch.png) (menu + Réglages ; pas de menu « selon l’état » — le kiosque masque la barre).

## Must-haves

1. Lancement = agent `.accessory` (pas d’icône Dock hors session) + status item template.
2. Config JSON : `~/Library/Application Support/BabyWorks/config.json` ; défauts si absent ; champs au minimum `mode`, `launchAtLogin` (noms exacts laissés au builder dans un schéma versionné simple).
3. Réglages : mode (Océan défaut, Galaxie sélectionnable) + Login Item idle.
4. Lancer session depuis le menu ; lazy : scène/filtre/couvertures seulement à ce moment, détruits à la sortie.
5. Sortie adulte = teardown **sans** `terminate:` ; process idle.
6. Échec activation = alerte + chemin vers Réglages/Accessibilité ; **pas** de fenêtre diagnostics prototype sur le chemin nominal.
7. Registre de modes (id → usine) pour en ajouter/retirer plus tard sans toucher confinement/sorties.

## Nice-to-haves (hors tranche)

- Personnaliser la combinaison / passphrase de sortie
- Polish Galaxie
- Sandbox + entitlements Login Items + notarization
- Remplacer le SF Symbol par un asset custom

## No-gos

- Session automatique au login
- Menu status utilisable / « Arrêter session » pendant le kiosque
- Garder la fenêtre diagnostics + injection de panne comme UI parent nominale
- Forcer le sandbox pour cette tranche

## Laissé au builder

- Quel SF Symbol template (poisson / equivalente)
- Noms exacts des clés JSON et migration si fichier invalide (revenir aux défauts + log)
- Découpage modules / packages tant que les frontières user-facing ci-dessus tiennent
- Détail de l’alerte (NSAlert vs feuille) tant qu’elle ouvre Réglages/Accessibilité

## Rabbit holes (décidés)

| # | Risque | Décision |
|---|--------|----------|
| R1 | Teardown ObjC appelle `terminate:` | Séparer fin de session et quit |
| R2 | Emoji status item fragile | SF Symbol **template** (pas emoji) |
| R3 | Mode hardcodé Océan | Registre + clé JSON |
| R4 | Login Item × sandbox | Nosandbox seulement cette tranche |
| R5 | Diagnostics prototype | Hors chemin user |
| R6 | Mémoire idle | Lazy load / unload session |

## Vérification (par phase, intention)

- Idle : app en barre seulement, peu de travail CPU/mémoire, pas de couvertures
- Réglages : changer mode + Login Item ; relire le JSON sur disque
- Session : démarrage rapide depuis le menu ; sorties adultes existantes → idle, app toujours là
- Échec Accessibilité : alerte utile, pas de diagnostics
- Quitter hors session : process meurt

## Glossaire (à figer dans CONTEXT.md au moment des tickets)

- **Agent** : process idle, status item, pas de session
- **Session** : période où le kiosque (confinement + mode de jeu) est actif
- **Mode** : contenu jouable (Océan, Galaxie, …) indépendant du confinement
- **Config** : fichier JSON Application Support
