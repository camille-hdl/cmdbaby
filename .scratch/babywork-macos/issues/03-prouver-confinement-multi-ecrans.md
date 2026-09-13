# 03: Prouver le confinement multi-écrans et les sorties adultes

**What to build:** Le prototype entre dans un mode de présentation couvrant tous les écrans disponibles, permet au parent d’en sortir par deux gestes indépendants et restaure l’état antérieur même après une activation incomplète.

**Blocked by:** 02 — Prouver le filtrage actif des entrées.

**Status:** claimed

- [ ] Une fenêtre sans bordure est créée et ajustée pour chaque écran disponible au moment de l’activation.
- [ ] Les options de présentation masquent et neutralisent les surfaces système compatibles avec les API publiques retenues.
- [ ] La combinaison initiale des options de présentation est mémorisée puis restaurée exactement à l’arrêt.
- [ ] La saisie de `parent` suivie d’Entrée dans la fenêtre temporelle proposée arrête le prototype.
- [ ] Le maintien de Majuscule-Échap arrête le prototype indépendamment du rendu (les deux Majuscules ne sont pas utilisables sur le Mac cible : Karabiner mappe Majuscule gauche sur Majuscule droite).
- [ ] `Commande-Q` est absorbé et ne constitue pas une sortie active.
- [ ] Une défaillance injectée à chaque étape de préparation déclenche un rollback et ne laisse ni fenêtre de couverture ni option de présentation résiduelle.
- [ ] Le comportement est démontré sur deux écrans lorsque le matériel est disponible, sinon la limitation du matériel de test est explicitement consignée.

## Commentaires

### 13 septembre 2026 — Comportement produit : kiosque à l’ouverture, quit à la sortie

Le retour à SwiftUI après le kiosque crashait (MainActor). Alignement sur le comportement visé : le kiosque démarre à l’ouverture ; une sortie adulte restaure `presentationOptions` puis quitte le processus. Commande-Q reste absorbé. La fenêtre diagnostic ne s’affiche que si l’activation échoue.

### 12 septembre 2026 — Prototype kiosque prêt pour les essais manuels

Ajouts :

- `KioskSessionController` transactionnel dans le kit, avec défaillance injectable à chaque étape de préparation ; rollback sans fenêtre ni présentation résiduelle (tests Swift Testing, y compris trois écrans dont une origine négative) ;
- `KioskPresentationPolicy` : combinaison kiosque validée par construction (Dock / barre de menus masqués, bascule et Force Quit désactivés), restauration de la valeur mémorisée et non d’un défaut ;
- une fenêtre AppKit sans bordure par `NSScreen` vivant (`CoverWindowCoordinator`), niveau `screenSaver` ;
- panneau « Confinement multi-écrans » et journal `docs/phase-0/kiosk-trials.md`.

Les cases du ticket restent ouvertes jusqu’à la démonstration sur les trois écrans du Mac cible (sorties adultes, Commande-Q, rollbacks injectés).

### 12 septembre 2026 — Premier essai kiosque : couverture ok, filtre inerte

Hors sandbox. Les 3 écrans sont couverts. Les injections « Mémoriser » et « Préparer les fenêtres » affichent l’échec. « Appliquer la présentation » et « Démarrer le filtre » ont lancé le kiosque. Sorties clavier inopérantes (bips) ; Commande-Q quittait. Cause probable : `NSCondition.wait` sur le thread principal à la création du tap. Correctifs en cours (attente async, filtre avant couverture, sortie 5 clics, refus de Commande-Q).

### 13 septembre 2026 — Les sorties ne démontent pas et ne quittent pas non plus

Les sorties adultes ne doivent pas appeler `terminate`. Elles doivent arrêter le kiosque. Constat : HUD « sortie demandée », couvertures et tap restent, ordinateur inutilisable. Correctif en cours : coupure immédiate du filtre + restauration des `presentationOptions`, masquage des fenêtres par IMP `NSWindow`.

### 12 septembre 2026 — Sortie détectée mais kiosque non démonté

Les compteurs HUD bougent ; « sortie demandée » s’affiche pour parent+Entrée et 5 clics. Le kiosque reste affiché : le rappel `Task`/`assumeIsolated` MainActor ne démonte pas. Correctif : démontage AppKit hors isolation Swift (`performSelector` / IMP). Les deux Majuscules sont irréalistes sur cette machine (Karabiner mappe Majuscule gauche → droite) : remplacé par Majuscule-Échap, sans modifier Karabiner.

### 12 septembre 2026 — Crash à l’application de la présentation

Trois crashs `EXC_BAD_ACCESS` (`swift_task_isCurrentExecutor` dans `DiagnosticView.body`) au moment d’appliquer les options de présentation / de couvrir. L’appli disparaissait sans message. Correctif : état SwiftUI hors `@MainActor`, masquage de la fenêtre de diagnostic avant la présentation, `applicationShouldTerminateAfterLastWindowClosed` = false.
