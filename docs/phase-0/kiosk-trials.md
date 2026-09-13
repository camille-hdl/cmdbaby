# Essais de confinement multi-écrans — phase 0

Journal factuel pour le ticket 03. Ne consigner **aucun** caractère saisi, ni séquence adulte, ni chemin privé.

## Environnement

- Date : 12 septembre 2026
- macOS : 26.6.2 (25G83), clavier AZERTY
- Trois écrans AppKit (origine négative sur le MSI) :
  - Built-in Retina Display — (0, 0)
  - ROG PG279Q — (2259, 881)
  - MSI MAG323UPF — (−749, 982)
- Build diagnostique : `/Applications/BabyWorkDiagnostics.app` et variante sandbox
- Accessibilité : déjà accordée pour les deux bundles (ticket 02)

## Procédure

1. Quitter toute instance déjà ouverte, puis relancer le bundle signé (sans `open` sur un processus existant).
2. Vérifier Accessibilité, relancer si besoin.
3. **Rollback** (optionnel mais demandé par le ticket) : pour chaque étape du menu « Simuler une défaillance », activer le kiosque. Attendu : message d’échec, Dock/barre de menus inchangés, aucune fenêtre de couverture.
4. Remettre la simulation sur **Aucune**, activer le kiosque.
5. Vérifier une fenêtre distincte (couleur/nom/origine) sur **chaque** écran, y compris le MSI à origine négative.
6. Vérifier Dock et barre de menus masqués.
7. Tenter Commande-Q : l’app ne quitte pas.
8. Sortie `parent` + Entrée (dans les 5 s) : le kiosque s’arrête, présentation restaurée.
9. Relancer le kiosque, sortie des deux Majuscules 3 s : même restauration.
10. Reproduire le chemin nominal avec la variante sandbox si le temps le permet.

## Essai du 12 septembre 2026 — BabyWorkDiagnostics (hors sandbox)

Couverture des 3 écrans **ok** (origines visibles, y compris négative).

Échecs observés :

- injections « Appliquer la présentation » et « Démarrer le filtre » : le kiosque s’est lancé au lieu du message d’échec (picker Optional probablement non lié) ;
- sorties `parent`+Entrée et deux Majuscules inopérantes ; bips à chaque touche (les événements arrivaient aux fenêtres de couverture) ;
- Commande-Q **quittait** — le `CGEventTap` n’interceptait pas, probablement parce que l’attente de création du tap **bloquait le thread principal**.

Correctifs prévus pour le passage suivant : attente async du filtre (boucle principale libre), filtre armé avant les fenêtres, picker sans Optional, Commande-Q refusé pendant le kiosque, 5 clics sur le point pâle en bas à droite comme issue de secours indépendante du tap.

## Essai du 12 septembre 2026 — crash au clic (cycle AppKit)

Kiosque affiché sur les 3 écrans (défaillance « Appliquer la présentation » et « Aucune »). Les sorties clavier n’ont pas arrêté la session. Un clic (y compris 1 clic sur le point pâle) fermait l’app.

Cause : `EXC_BAD_ACCESS` dans `@objc CoverWindow.canBecomeKey.getter` (`swift_task_isCurrentExecutor`) au `mouseDown` AppKit. `NSWindow` est isolé MainActor ; la runloop appelle l’accesseur hors de cet exécuteur. Ce n’était pas la sortie de secours (5 clics).

Correctif prévu : accesseurs `nonisolated`, cible de clic hors MainActor, défaillance armée par bouton plutôt que par Picker.

### 13 septembre 2026 — Sortie détectée, kiosque non arrêté

Les sorties prévues (parent+Entrée, 5 clics, Majuscule-Échap) ne doivent **pas** quitter le processus : elles doivent retirer les couvertures, restaurer la présentation et laisser passer le clavier. Constat : HUD « sortie demandée », couvertures restantes, tap encore actif, Mac inutilisable (`disableProcessSwitching`).

Correctif : couper le tap et restaurer `presentationOptions` **immédiatement** (n’importe quel thread), masquer les couvertures via l’IMP ObjC de `NSWindow` (pas le thunk Swift MainActor), report du masquage hors du callback souris/tap.

### 13 septembre 2026 — Correctif ObjC (hors isolation Swift)

Les appels AppKit depuis Swift (même via IMP / `DispatchQueue.main`) no-op ou deadlock hors de l’exécuteur MainActor ; `CGEventTapEnable` depuis le callback Quartz peut aussi bloquer. Le démontage est désormais un helper Objective-C (`BabyWorkAppKitBridge`) : tap coupé sur une file parallèle, fenêtres / `presentationOptions` sur la runloop principale (`kCFRunLoopCommonModes`). Le processus n’est pas terminé.

## Grille

| Critère | Sans sandbox | Avec sandbox | Notes |
|---|---|---|---|
| Fenêtre par écran (3) | | | Noter si un écran reste visible |
| Origine négative couverte | | | MSI MAG323UPF |
| Dock / barre de menus masqués | | | |
| Commande-Q n’est pas une sortie | | | |
| Sortie parent + Entrée | | | Ne pas noter la saisie |
| Sortie deux Majuscules 3 s | | | |
| Rollback étape « Mémoriser la présentation » | | | |
| Rollback étape « Préparer les fenêtres » | | | |
| Rollback étape « Appliquer la présentation » | | | |
| Rollback étape « Démarrer le filtre » | | | |

Légende : `ok` / `échec` / `partiel` / `non testé`.
