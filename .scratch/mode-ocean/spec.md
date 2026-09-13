Status: ready-for-agent

# Mode Océan

## Problem Statement

Le kiosk n’a aujourd’hui qu’un mode jouable, Galaxie, câblé en dur sur chaque couverture. On veut un second mode, Océan, qui devient le défaut. L’enfant voit un fond marin parallaxe (eau, algues, rochers, sable et terre), des poissons qui nagent lentement de gauche à droite, et des bulles. Taper au clavier ajoute des poissons ; cliquer ajoute des bulles. Au-delà de 100 poissons, les plus vieux accélèrent pour quitter l’écran.

Galaxie reste compilé et listé dans le catalogue. Le changement de mode en session ou depuis l’UI parent n’est pas dans cette demande.

## Solution

Ajouter `KioskPlayModeID.ocean` comme valeur par défaut du catalogue. Extraire la logique de banc et de décor dans `BabyWorkDiagnosticsKit` (testable, sans AppKit ni images). Rendre le mode dans l’exécutable avec la même pile que Galaxie : `NSView` + `CALayer` + timer 60 Hz, sprites PNG Kenney Fish Pack 2.0 (CC0). Brancher `CoverWindowCoordinator` sur `KioskPlayModeCatalog.default` pour instancier Océan ou Galaxie.

Les sorties adultes, le filtre d’entrée, le HUD et `FailsafeClickView` restent inchangés.

## Glossaire

Employer ces termes. Ne pas les remplacer par des synonymes dans le code, les tests ou les tickets.

- **Mode jouable** : identifiant du catalogue (`KioskPlayModeID`) qui décide le rendu enfant d’une session. N’affecte ni le confinement ni les sorties adultes.
- **Océan** : mode jouable par défaut. Sprites Kenney, pas d’emojis.
- **Galaxie** : mode jouable existant, conservé, plus sélectionné par défaut.
- **Écran** : un `NSScreen` vivant, une `CoverWindow`, un painter. Pas une fenêtre géante ni un cache de la liste d’écrans.
- **Banc** (`OceanSchool`) : état pur des poissons de toute la session (tous écrans). Spawn, nage, surpopulation, cull.
- **Poisson** : entité du banc, identifiée par un `birthIndex` croissant. Nage en espace écran, gauche → droite. Ne wrap pas. Disparaît en sortant à droite.
- **Surpopulation** : dès que le banc dépasse `maxFish` (100) poissons au total, les plus vieux (plus petit `birthIndex`) nagent à la vitesse de sortie jusqu’à être cullés.
- **Décor** (`OceanScenery`) : placement déterministe des couches parallaxes, du sol et des props d’un écran, à partir de `(bounds, seed)`.
- **Parallaxe** : défilement horizontal du décor vers la gauche (POV qui avance), à un facteur par couche. Indépendant de la nage des poissons.
- **Sol** : bande basse de l’écran, terre en dessous, sable au-dessus, comme le `Sample.png` du pack Kenney.
- **Prop** : algue ou rocher planté sur la crête de sable.
- **Bulle de poisson** : 1–2 sprites `bubble_*` émis périodiquement par un poisson vivant, qui montent et disparaissent.
- **Bulle de clic** : 1–3 sprites `bubble_*` créés à l’endroit du `mouseDown`.
- **Painter** : un par écran. Dessine le décor, les poissons de cet écran, et les bulles. Analogie : `GalaxyPainter`.
- **Director** : un par session. Timer 60 Hz, banc partagé, liste des painters. Analogie : `GalaxyDirector`.

## Comportement

### Démarrage d’une session

1. `CoverWindowCoordinator.createCoverWindows` lit `KioskPlayModeCatalog.default` (Océan).
2. Un `OceanDirector` unique est créé, avec un `OceanSchool` vide.
3. Pour chaque écran vivant : une `CoverWindow` dont le `contentView` est un `OceanStageView` (painter + `FailsafeClickView`).
4. Chaque painter génère son `OceanScenery` (seed dérivé de l’identifiant d’écran + un sel de session) et s’enregistre auprès du director.
5. Le director spawn **1 poisson par écran**, dans la moitié gauche, dans la colonne d’eau.

Le fond de fenêtre n’utilise plus `CoverPalette` pour Océan : le `layer.backgroundColor` du stage est une eau unie bleu clair (voir constantes). Galaxie conserve sa palette.

### Parallaxe et décor

Chaque écran empile, de l’arrière vers l’avant :

1. Eau unie (couleur de layer, pas d’image plein cadre — le pack n’en a pas).
2. Couche loin : silhouettes `background_seaweed_*`, `background_rock_*`, éventuellement `background_terrain`.
3. Couche milieu : quelques algues / rochers plus lisibles, plus bas que la couche loin.
4. Sol : tuiles `terrain_dirt_*` tout en bas, puis `terrain_sand_*` au-dessus, crête `terrain_sand_top_*` (et `terrain_dirt_top_*` à la jonction terre/sable si besoin).
5. Premier plan : `seaweed_*` et `rock_*` plantés sur la crête de sable.
6. Poissons et bulles.

Le décor défile vers la gauche à `cameraSpeed` × facteur de couche. Les tuiles et props qui sortent entièrement à gauche réapparaissent à droite (wrap). Les poissons **ne** participent **pas** à ce défilement : leur `x` n’est pas soustrait de la caméra.

La frappe n’accélère pas le courant.

### Poissons

- Orientation Kenney : les PNG regardent vers la **gauche**. Affichage : miroir horizontal (`transform.scale.x = -1`) pour nager vers la droite.
- Nage en espace écran, `x` croissant, vitesses individuelles tirées une fois au spawn dans `[swimMin, swimMax]`.
- `y` constant après spawn (pas de bobbing obligatoire).
- Spawn (initial et clavier) : `x ∈ [padding, width/2]`, `y` dans la colonne d’eau, au-dessus du sol, avec une marge sous le haut de l’écran.
- Frappe : **un** poisson, écran **aléatoire** parmi les painters (même règle que Galaxie pour les glyphes). Aucune lettre, aucun emoji.
- Sortie : dès que `x > width + halfDisplaySize`, le poisson est retiré du banc et son layer détruit.
- Surpopulation : si `school.count > maxFish` après un spawn, tous les poissons dont `birthIndex` est parmi les `count - maxFish` plus petits passent à `exitSpeed` (les autres gardent leur vitesse de nage). Quand le compte redescend à `maxFish` ou moins, plus aucun poisson n’est forcé à `exitSpeed` (ceux déjà boostés peuvent rester boostés jusqu’à la sortie — plus simple, et c’est la règle retenue).

Un écran peut se vider de poissons. On ne respawn pas automatiquement.

### Bulles

- Chaque poisson vivant émet 1–2 bulles toutes les 2,0–4,0 s, près de sa tête (côté droit du sprite une fois mirroiré).
- Un clic (`mouseDown`) sur un stage crée 1, 2 ou 3 bulles au `locationInWindow` de cet écran. Pas d’effet au `mouseMoved` / `mouseDragged`.
- Les bulles montent (`y` croissant en coordonnées AppKit) à 50–80 pt/s, opacités qui tombent, durée de vie 1,4–2,2 s, puis destruction. Pas de cap global autre que la durée de vie (une rafale de clics ne doit pas faire croître la mémoire sans borne : détruire à la fin de vie, comme les glyphes Galaxie).

Les bulles sont un détail de rendu (painter), pas du banc. Le kit n’a pas à les simuler.

### Entrées et sorties adultes

`OceanStageView.keyDown` :

1. Appelle `inputBridge.noteKeyDown(...)` exactement comme `GalaxyStageView` (lettre, return, escape, shift) pour que `parent`+Entrée et Maj+Échap restent reconnus.
2. Demande au director de spawner un poisson. Ne passe pas par `PlayGlyphResolver`.

`mouseDown` : bulles de clic sur le painter de cet écran, puis le `FailsafeClickView` continue de compter les 5 clics de secours (sous-vue existante, coin bas-droit).

`flagsChanged` / `performKeyEquivalent` restent sur `CoverWindow`, inchangés.

## Constantes

Toutes ces valeurs sont des constantes nommées côté kit quand elles concernent le banc, côté rendu sinon. Ne pas les « améliorer » sans changer la spec.

| Nom | Valeur | Où |
|-----|--------|-----|
| `maxFish` | `100` | kit, total session |
| Poissons initiaux | `1` par écran | director au premier layout |
| Spawn clavier | `1` poisson | director |
| Demi-écran de spawn | `x ∈ [padding, width / 2]` | kit |
| `padding` | `90` pt | kit |
| `swimMin` | `28` pt/s | kit |
| `swimMax` | `52` pt/s | kit |
| `exitSpeed` | `240` pt/s | kit |
| Cull | `x > width + halfDisplaySize` | kit (le renderer fournit `halfDisplaySize`) |
| Bulles par clic | `1...3` | painter |
| Période bulles poisson | `2.0...4.0` s | painter |
| Bulles par émission poisson | `1...2` | painter |
| Vitesse montée bulle | `50...80` pt/s | painter |
| Durée de vie bulle | `1.4...2.2` s | painter |
| Taille d’affichage poisson | `96...150` pt | painter, tirée au spawn |
| Timer | `1.0 / 60.0` s | director, comme Galaxie |
| `dt` clamp | `[1/120, 0.05]` | director, comme Galaxie |
| `cameraSpeed` | `22` pt/s | painter, constant |
| Facteur loin | `0.18` | painter |
| Facteur milieu | `0.40` | painter |
| Facteur sol | `0.72` | painter |
| Facteur premier plan | `1.0` | painter |
| Hauteur de sol totale | `0.22 * height` | décor |
| dont terre | `0.10 * height` (bande basse) | décor |
| dont sable | `0.12 * height` (au-dessus de la terre) | décor |
| Couleur d’eau | `#7EC8E3` (sRGB, opaque) | stage layer |
| Miroir poisson | `scale.x = -1` | painter |

Colonne d’eau pour le `y` d’un poisson : `[groundTop + halfDisplaySize, height - padding]`. Si l’intervalle est invalide (écran minuscule), spawn au centre.

## Architecture

Même découpage que Galaxie.

### Kit — `BabyWorkDiagnosticsKit`

- `KioskPlayModeID.ocean`, catalogue : `available == [.ocean, .galaxy]`, `default == .ocean`, `displayName(.ocean) == "Océan"`.
- `OceanSchool` : état des poissons, RNG injecté.
- `OceanScenery` : génération du décor d’un écran, seed injecté.

Le kit ne charge aucune image et n’importe pas AppKit.

### Exécutable — `BabyWorkDiagnostics`

- `OceanPlayMode.swift` : `OceanDirector`, `OceanPainter`, `OceanStageView`. Copier les habitudes de concurrence de Galaxie (`@unchecked Sendable`, `NSLock`, `runOnMain`, `MainHop`, timer sur `RunLoop.main` en mode `.common`).
- `CoverWindowCoordinator` : switch sur `KioskPlayModeCatalog.default`. Stocker le director dans un enum interne `{ galaxy(GalaxyDirector), ocean(OceanDirector) }` qui expose `reset()`.
- Ressources : `Sources/BabyWorkDiagnostics/Resources/Ocean/` déclarées sur la target exécutable via `resources: [.process("Resources/Ocean")]`. Chargement par `Bundle.module`.

### Interfaces kit attendues

Ces signatures sont le contrat. Un agent peut renommer un paramètre interne, pas le comportement.

```swift
public struct OceanFish: Equatable, Sendable {
  public let id: UInt64          // birthIndex
  public var x: Double
  public var y: Double
  public var speed: Double       // pt/s, exitSpeed si boosté
  public var kind: OceanFishKind
  public var displaySize: Double
  public let screenIndex: Int
}

public enum OceanFishKind: String, CaseIterable, Sendable {
  case blue, green, orange, pink, red, brown, grey
}

public struct OceanSchool: Equatable, Sendable {
  public static let maxFish = 100
  public static let swimMin = 28.0
  public static let swimMax = 52.0
  public static let exitSpeed = 240.0
  public static let padding = 90.0

  public private(set) var fish: [OceanFish]

  public init(fish: [OceanFish] = [])

  /// Un poisson dans la moitié gauche de `screenIndex`. `rng` décide kind, x, y, speed, displaySize.
  public mutating func spawnFish<R: RandomNumberGenerator>(
    screenIndex: Int,
    screenSize: CGSize,
    groundTop: Double,
    displaySizeRange: ClosedRange<Double>,
    rng: inout R
  ) -> OceanFish

  /// Avance tous les poissons. Applique exitSpeed aux trop vieux si count > maxFish.
  /// Retire ceux dont `x > width + displaySize/2`.
  public mutating func tick(dt: Double, screenWidths: [Double]) -> OceanTick

  public var count: Int { fish.count }
}

public struct OceanTick: Equatable, Sendable {
  public var fish: [OceanFish]
  public var removedIDs: [UInt64]
}

public enum OceanLayer: String, Sendable {
  case far, mid, ground, foreground
}

public struct OceanProp: Equatable, Sendable {
  public var kind: OceanPropKind
  public var x: Double
  public var y: Double
  public var layer: OceanLayer
}

public enum OceanPropKind: String, Sendable {
  // noms de fichiers sans extension, ex. seaweed_green_a, terrain_sand_top_c
  case sprite(String)
}

public struct OceanScenery: Equatable, Sendable {
  public var props: [OceanProp]
  public var groundTop: Double
  public var dirtHeight: Double
  public var sandHeight: Double

  public static func generate<R: RandomNumberGenerator>(
    bounds: CGSize,
    rng: inout R
  ) -> OceanScenery

  /// Décale les props de `-cameraDelta * factor(layer)` et wrap selon `bounds.width`.
  public mutating func scroll(cameraDelta: Double, bounds: CGSize)
}
```

`CGSize` / `CGPoint` viennent de `CoreGraphics` (déjà OK dans un kit sans AppKit) ou d’un `OceanSize` local si l’agent préfère éviter CoreGraphics. Les tests ne doivent pas importer AppKit.

Si `OceanPropKind.sprite(String)` pose un problème d’Equatable associé, utiliser un `struct OceanPropKind: Equatable, Sendable { public let assetName: String }` à la place.

### Câblage des couvertures

```swift
switch KioskPlayModeCatalog.default {
case .ocean:
  let director = OceanDirector()
  // CoverWindow(..., play: .ocean(director))
  // contentView = OceanStageView(...)
case .galaxy:
  let director = GalaxyDirector()
  // CoverWindow(..., play: .galaxy(director))
  // contentView = GalaxyStageView(...)
}
```

Pas d’UI. Pas de réglage persisté. Changer le défaut du catalogue change le mode de la prochaine session.

## Assets

Pack source (hors dépôt, volume externe) :

`/Volumes/WD_BLACK/2D/kenney_fish-pack_2`

Licence : Creative Commons Zero 1.0, fichier `License.txt` à copier dans le bundle.

Utiliser **uniquement** `PNG/Double/` (128×128). Destination :

`Sources/BabyWorkDiagnostics/Resources/Ocean/`

### À copier (noms exacts)

Bulles :

- `bubble_a.png`
- `bubble_b.png`
- `bubble_c.png`

Poissons vivants :

- `fish_blue.png`
- `fish_green.png`
- `fish_orange.png`
- `fish_pink.png`
- `fish_red.png`
- `fish_brown.png`
- `fish_grey.png`

Algues :

- `seaweed_green_a.png` … `seaweed_green_d.png`
- `seaweed_grass_a.png`, `seaweed_grass_b.png`
- `seaweed_orange_a.png`, `seaweed_orange_b.png`
- `seaweed_pink_a.png` … `seaweed_pink_d.png`

Rochers :

- `rock_a.png`
- `rock_b.png`

Sable :

- `terrain_sand_a.png` … `terrain_sand_d.png`
- `terrain_sand_top_a.png` … `terrain_sand_top_h.png`

Terre :

- `terrain_dirt_a.png` … `terrain_dirt_d.png`
- `terrain_dirt_top_a.png` … `terrain_dirt_top_h.png`

Parallaxe :

- `background_seaweed_a.png` … `background_seaweed_h.png`
- `background_rock_a.png`, `background_rock_b.png`
- `background_terrain.png`
- `background_terrain_top.png`

Licence :

- `License.txt` (racine du pack, pas dans `PNG/Double/`)

### À ne pas copier

- tout `hud_*` (chiffres, colon, dollar, dot, percent, plus)
- tout fichier `*_outline*`
- tout fichier `*_skeleton*`
- `fish_grey_long_a.png`, `fish_grey_long_b.png`
- tout `PNG/Default/`
- tout `Vector/`
- tout `Spritesheet/`
- `Preview.png`, `Sample.png`, fichiers `.url`

Le chargement runtime mappe `OceanFishKind.orange` → `fish_orange` dans le bundle, etc. Un asset manquant est un bug d’import, pas un fallback emoji.

## Tests

Suivre [`KioskPlayModeTests.swift`](../../Tests/BabyWorkDiagnosticsKitTests/KioskPlayModeTests.swift) : Swift Testing, `@testable import BabyWorkDiagnosticsKit`, aucun AppKit.

- Catalogue : `available`, `default`, `displayName` pour Océan et Galaxie.
- Banc : spawn dans la moitié gauche et au-dessus du sol ; vitesses dans `[swimMin, swimMax]` ; `tick` avance `x` ; cull hors écran ; au 101ᵉ poisson les plus vieux passent à `exitSpeed` ; le compte redescend après cull.
- Décor : `groundTop` ≈ `0.78 * height` ; présence de terre et de sable ; `scroll` wrap sans faire disparaître le nombre de props ; même seed ⇒ même décor.

Le rendu AppKit n’a pas de test unitaire dans ce dépôt (Galaxie non plus). La vérif visuelle est manuelle après le ticket 06.

RNG : `var rng = SplitMix64(seed:)` ou `SystemRandomNumberGenerator` en prod, seed fixe en test. Ne pas appeler `Int.random` / `Double.random` sans générateur injecté dans le kit.

## Hors scope

- UI ou raccourci pour changer de mode.
- Lettres, emojis, `PlayGlyphResolver` en mode Océan.
- SpriteKit, SwiftUI Canvas, SKCameraNode.
- Traînée souris, boost du courant à la frappe, wrap des poissons.
- Son.
- Animation d’algues autre que le défilement parallaxe.
- Hot-plug d’écrans (reste le ticket 10 de `babywork-macos`).
- Modifier le filtre d’entrée, `AdultExitRecognizer`, le HUD, ou la présentation kiosk.
- Copier Default / Vector / spritesheet / HUD Kenney « au cas où ».

## Références code

- Catalogue actuel : [`Sources/BabyWorkDiagnosticsKit/KioskPlayMode.swift`](../../Sources/BabyWorkDiagnosticsKit/KioskPlayMode.swift)
- Rendu Galaxie à copier : [`Sources/BabyWorkDiagnostics/GalaxyPlayMode.swift`](../../Sources/BabyWorkDiagnostics/GalaxyPlayMode.swift)
- Câblage dur Galaxie : [`Sources/BabyWorkDiagnostics/CoverWindowCoordinator.swift`](../../Sources/BabyWorkDiagnostics/CoverWindowCoordinator.swift)
- Tests catalogue : [`Tests/BabyWorkDiagnosticsKitTests/KioskPlayModeTests.swift`](../../Tests/BabyWorkDiagnosticsKitTests/KioskPlayModeTests.swift)
- Manifeste SPM sans resources aujourd’hui : [`Package.swift`](../../Package.swift)

## Commentaires

- Décisions d’architecture et ordre des tickets : [`map.md`](map.md).
- Le pack Kenney n’est pas dans le dépôt tant que le ticket 01 n’est pas fait. Si `/Volumes/WD_BLACK` est démonté, le ticket 01 échoue clairement ; ne pas substituer d’autres assets.
