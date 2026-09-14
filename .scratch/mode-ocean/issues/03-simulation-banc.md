# 03: Simulation du banc

Type: task

**What to build:** Un module kit pur `OceanSchool` qui spawne des poissons, les fait nager gauche → droite, accélère les plus vieux au-delà de 100, et les retire quand ils sortent à droite.

**Blocked by:** —

**Status:** resolved

Lire [`.scratch/mode-ocean/spec.md`](../spec.md) sections **Glossaire**, **Poissons**, **Constantes**, **Interfaces kit attendues**. Copier les signatures. Le RNG est injecté ; aucun `Int.random` global.

## Checklist

- [x] `OceanFish`, `OceanFishKind`, `OceanSchool`, `OceanTick` existent dans le kit, `Sendable` + `Equatable`.
- [x] `spawnFish` place `x` dans `[padding, width/2]`, `y` dans la colonne d’eau au-dessus de `groundTop`, `speed` dans `[swimMin, swimMax]`, `kind` dans `OceanFishKind.allCases`, `displaySize` dans le range fourni.
- [x] Chaque spawn incrémente un `birthIndex` (`id`) monotone à partir de 1.
- [x] `tick` avance `x += speed * dt` pour chaque poisson. `y` inchangé.
- [x] Si `count > maxFish` (100), les `count - 100` poissons au plus petit `id` ont `speed == exitSpeed` (240). Ils **gardent** cette vitesse ensuite.
- [x] Un poisson avec `x > screenWidths[screenIndex] + displaySize/2` est retiré ; son `id` apparaît dans `OceanTick.removedIDs`.
- [x] Les tests seedés passent sans AppKit.
- [x] Aucune image, aucun `CALayer`.

## Fichiers cibles

- Créer `Sources/BabyWorkDiagnosticsKit/OceanSchool.swift`
- Créer `Tests/BabyWorkDiagnosticsKitTests/OceanSchoolTests.swift`

Ne pas modifier `KioskPlayMode.swift` (ticket 02) ni l’exécutable.

## Contrat

Reprendre les types de la spec. Détails d’implémentation imposés :

- `screenIndex` est l’indice du painter / de l’écran, 0-based. `tick(screenWidths:)` utilise `screenWidths[fish.screenIndex]` ; si l’indice est hors bornes, cull immédiatement.
- `groundTop` est en coordonnées AppKit (y vers le haut) : le sol occupe `[0, groundTop]`, l’eau `[groundTop, height]`. Le `y` du poisson est le centre du sprite.
- Colonne d’eau : `y ∈ [groundTop + displaySize/2, height - padding]`. Intervalle invalide → `y = height / 2`, `x = width / 4`.
- `displaySizeRange` vient du renderer (spec : `96...150`). Le kit ne hardcode pas cette range, il la reçoit.
- Après `spawnFish`, si `count > maxFish`, appliquer tout de suite le boost `exitSpeed` aux trop vieux (pas attendre le prochain `tick`).
- `tick` renvoie l’état **après** mouvement et cull. `OceanTick.fish` est égal à `school.fish`.

RNG : toutes les tirages (`kind`, `x`, `y`, `speed`, `displaySize`) passent par `rng`. Ordre de tirage à respecter pour des tests stables :

1. `kind` (index dans `OceanFishKind.allCases`)
2. `displaySize`
3. `x`
4. `y`
5. `speed`

## Tests (Swift Testing, seed fixe)

Couvrir au minimum :

1. Un spawn a `x <= width/2`, `x >= padding`, `y > groundTop`, `id == 1` puis `id == 2`.
2. `tick(dt: 1, screenWidths: [800])` d’un poisson à `x=100, speed=40` donne `x == 140`.
3. Un poisson à `x = width + displaySize` est retiré ; `removedIDs` le contient ; `count == 0`.
4. 100 poissons : aucun n’est à `exitSpeed` s’ils ont été spawnés avec `speed < exitSpeed`.
5. Le 101ᵉ spawn : le poisson d’`id` le plus petit a `speed == OceanSchool.exitSpeed` ; le nouveau-né garde une vitesse de nage dans `[swimMin, swimMax]`.
6. Après cull du plus vieux, `count == 100` ; les poissons encore boostés restent à `exitSpeed`.
7. Même séquence + même seed ⇒ mêmes `kind` / positions.

Ne pas inspecter d’autres champs privés que ceux du contrat public.

Exemple d’amorce :

```swift
var rng = SplitMix64(seed: 1) // ou un générateur seedé déjà dans le projet ; sinon un petit struct local de test
var school = OceanSchool()
let spawned = school.spawnFish(
  screenIndex: 0,
  screenSize: CGSize(width: 800, height: 600),
  groundTop: 0.22 * 600,
  displaySizeRange: 96...150,
  rng: &rng
)
```

Si le kit n’a pas de `SplitMix64`, un `struct` de test dans le fichier de tests (conforme à `RandomNumberGenerator`) suffit. Ne pas ajouter de dépendance.

`CGSize` : `import CoreGraphics` dans le kit est acceptable. Alternative : un `OceanSize(width:height:)` dans le même fichier. Les tests restent sans AppKit.

## Ne pas faire

- Simuler les bulles dans le kit (rendu, ticket 05).
- Wrap des poissons, nage vers la gauche, bobbing obligatoire.
- `Int.random(in:)` / `Double.random(in:)` sans `rng`.
- Importer AppKit, QuartzCore, ou charger un PNG.
- Plafond par écran au lieu du cap global 100.
- Respawn automatique quand un écran se vide.

## Commentaires

- Le director (ticket 05) appellera `spawnFish` au layout (1× par écran) et à chaque frappe (écran aléatoire — l’aléa écran est **hors** de ce module, côté director).

## Réponse

`OceanSchool` vit dans le kit : spawn injecté par RNG (ordre kind → displaySize → x → y → speed), nage `x += speed * dt`, boost immédiat des plus vieux dès `count > 100`, cull à droite (et si `screenIndex` est hors bornes). Les 9 tests seedés passent, sans AppKit ni images.
