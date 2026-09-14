# Carte — mode Océan

Ordre d’exécution : le plus petit numéro **non bloqué** et `ready-for-agent`. Ne pas commencer 05 avant 01, 03 et 04. Ne pas commencer 06 avant 02 et 05.

## Ordre

1. **01** importer sprites — aucun blocage
2. **02** catalogue défaut — aucun blocage, parallèle à 01
3. **03** simulation banc — aucun blocage, parallèle à 01/02
4. **04** génération décor — aucun blocage, parallèle à 01/02/03
5. **05** rendu océan — bloqué par 01, 03, 04
6. **06** brancher couvertures — bloqué par 02, 05

01–04 peuvent partir en parallèle. 05 a besoin des PNG dans le bundle, du banc et du décor. 06 est le seul qui touche `CoverWindowCoordinator`.

## Décisions

- **Océan est le défaut.** `KioskPlayModeCatalog.default == .ocean`. Galaxie reste dans `available`. Pas d’UI de sélection (plus tard).
- **Pile Galaxie, pas SpriteKit.** `NSView` + `CALayer` + timer 60 Hz. La spec produit historique mentionne SpriteKit ; Galaxie ne l’utilise pas. Copier `GalaxyPlayMode.swift` plutôt qu’introduire une seconde pile de rendu.
- **Sprites Kenney CC0, zéro emoji** dans Océan. `PlayGlyphResolver` et les catalogues d’emojis restent pour Galaxie uniquement.
- **Clavier = 1 poisson**, pas de lettre. Clic = 1–3 bulles. Pas de traînée `mouseMoved`.
- **Cap 100 global** (tous écrans). Les plus vieux (`birthIndex` minimal) passent à `exitSpeed` et sortent à droite. Pas de wrap des poissons.
- **1 poisson par écran au départ.** Pas de respawn automatique ; un écran peut se vider.
- **Nage en espace écran, gauche → droite.** Les PNG Kenney regardent à gauche : `transform.scale.x = -1`.
- **Parallaxe indépendante.** Décor vers la gauche (POV qui avance). Poissons non soumis à la caméra. La frappe n’accélère pas le courant.
- **Sol = terre bas + sable dessus**, comme `Sample.png` du pack.
- **Sorties adultes inchangées.** `KioskInputBridge` + `FailsafeClickView` réutilisés tels quels.
- **Kit sans images.** `OceanSchool` et `OceanScenery` dans `BabyWorkDiagnosticsKit`. PNG uniquement dans l’exécutable via `Bundle.module`.
- **Pas d’ADR.** Décision locale, réversible, déjà tranchée par Galaxie pour la pile de rendu.
- **Pas de `CONTEXT.md`.** Glossaire dans `spec.md` seulement.

## Incertitudes tranchées (ne pas rouvrir pendant l’implémentation)

- Écran du spawn clavier : **aléatoire parmi les painters**, comme Galaxie, pas l’écran du pointeur.
- Poissons déjà boostés par surpopulation : **restent à `exitSpeed` jusqu’à la sortie**, même si le compte redescend sous 100.
- `fish_grey_long_*` : **exclus** (anguille en deux morceaux, trop ambiguë).
- Bulles : **rendu only** (painter), pas dans `OceanSchool`.
- `CoverWindowCoordinator` : enum interne `{ galaxy, ocean }` + `reset()`, pas un protocole public `PlayDirector`.
- Couleur d’eau : constante `#7EC8E3`, pas un dégradé.
- Seed décor : dérivé de l’identifiant d’écran + sel de session ; reproductible en test via RNG injecté.

## Pointeurs

- Spec : [`spec.md`](spec.md)
- Galaxie à copier : `Sources/BabyWorkDiagnostics/GalaxyPlayMode.swift`
- Catalogue : `Sources/BabyWorkDiagnosticsKit/KioskPlayMode.swift`
- Pack : `/Volumes/WD_BLACK/2D/kenney_fish-pack_2` (volume externe ; 01 échoue s’il est absent)

## Commentaires

- Les tickets 01–06 portent `Status: ready-for-agent` et `Type: task`. Passer à `claimed` puis `resolved` selon `docs/agents/issue-tracker.md`.
- Ticket 01 résolu : les 60 sprites Kenney autorisés et `License.txt` sont disponibles dans `Sources/BabyWorkDiagnostics/Resources/Ocean/`, avec la ressource déclarée dans `Package.swift`.
- Ticket 02 résolu : le catalogue expose `[.ocean, .galaxy]` et Océan est le mode jouable par défaut.
- Ticket 03 résolu : `OceanSchool` spawne, nage, accélère les trop vieux au-delà de 100 et cull à droite, avec tests seedés sans AppKit.
- Ticket 04 résolu : `OceanScenery` génère un décor déterministe (terre, sable, far/mid/foreground) et le fait défiler avec wrap ; les facteurs de parallaxe sont des `static let` pour le renderer. Voir [04](issues/04-generation-decor.md).
- Ticket 05 résolu : `OceanDirector` / `OceanPainter` / `OceanStageView` dessinent le décor parallaxe, les poissons mirroirés et les bulles à 60 Hz, sans brancher les couvertures. Voir [05](issues/05-rendu-ocean.md).
- Ticket 06 résolu : les couvertures instancient Océan via `KioskPlayModeCatalog.default` ; Galaxie reste constructible. Voir [06](issues/06-brancher-couvertures.md).
