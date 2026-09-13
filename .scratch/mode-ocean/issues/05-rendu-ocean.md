# 05: Rendu Océan

Type: task

**What to build:** Director, painter et stage AppKit/Core Animation qui dessinent le décor parallaxe, les poissons (sprites mirroirés) et les bulles, à 60 Hz. Pas encore branché sur les couvertures.

**Blocked by:** 01, 03, 04

**Status:** ready-for-agent

Lire [`.scratch/mode-ocean/spec.md`](../spec.md) en entier et copier la structure de [`GalaxyPlayMode.swift`](../../../Sources/BabyWorkDiagnostics/GalaxyPlayMode.swift) (`Director` / `Painter` / `StageView`, `NSLock`, `runOnMain`, `MainHop`, timer `1/60` sur `RunLoop.main` en `.common`, `dt` clampé).

Prérequis : PNG dans `Bundle.module`, `OceanSchool` et `OceanScenery` compilés.

## Checklist

- [ ] `OceanDirector`, `OceanPainter`, `OceanStageView` existent dans `Sources/BabyWorkDiagnostics/OceanPlayMode.swift`.
- [ ] Un director, un banc partagé ; un painter par stage ; timer 60 Hz dès le premier `register`.
- [ ] Au premier `setBounds` valide, le painter génère le décor (`OceanScenery.generate`) et le director spawn 1 poisson pour cet écran.
- [ ] Fond = eau `#7EC8E3`. Couches CA : décor (far/mid/ground/foreground), poissons, bulles. Z-order = spec.
- [ ] Props : `CALayer.contents` = `CGImage` du PNG `assetName`. Sol et silhouettes défilent via `scenery.scroll` puis positions layer.
- [ ] Poissons : sprite `fish_<kind>`, `transform.scale.x = -1`, taille `displaySize`, position = `(fish.x, fish.y)`. Cull = retrait du layer quand l’id est dans `removedIDs`.
- [ ] Chaque poisson émet 1–2 bulles toutes les 2–4 s. Clic : 1–3 bulles au point (API painter, branchée au ticket 06).
- [ ] `reset()` du director invalide le timer, vide painters et banc (comme `GalaxyDirector.reset`).
- [ ] `FailsafeClickView` est déjà posé sur le stage (même contraintes que Galaxie) pour que 06 n’ait pas à le rajouter.
- [ ] `swift build` passe. Pas d’emoji, pas de `PlayGlyphResolver` dans ce fichier.
- [ ] `CoverWindowCoordinator` n’est **pas** modifié (ticket 06).

## Fichiers cibles

- Créer `Sources/BabyWorkDiagnostics/OceanPlayMode.swift`
- Lire seulement, ne pas éditer : `GalaxyPlayMode.swift`, `CoverWindowCoordinator.swift`

Le `keyDown` / `mouseDown` du stage peuvent déjà appeler director/painter (comme Galaxie le fait). Tant que le stage n’est pas le `contentView` d’une couverture, c’est inerte. 06 se contente alors de l’instancier.

## Chargement des sprites

```swift
enum OceanSprite {
  static func image(named name: String) -> NSImage? {
    Bundle.module.image(forResource: name)
      ?? Bundle.module.image(forResource: "\(name).png")
  }
}
```

Si `Bundle.module` n’est pas généré, vérifier le ticket 01 (`resources` sur la target exécutable). Pas de fallback emoji. Un nom inconnu : layer vide, pas de crash (`try!` interdit).

Taille d’affichage : `fish.displaySize` (kit). Anchor : centre du layer = `(x, y)` AppKit.

Miroir : appliquer le scale **après** avoir cadré le layer, ou group wrapper + contents, pour ne pas inverser la position. Vérifier visuellement qu’un `fish_orange` nage tête à **droite**.

## Director

Responsabilités :

- `register(painter)` + index d’écran (ordre d’enregistrement = `screenIndex`).
- `spawnKeyFish()` : tire un `screenIndex` aléatoire parmi les painters enregistrés, appelle `school.spawnFish` avec `screenSize` / `groundTop` du painter, `displaySizeRange: 96...150`.
- `ensureInitialFish(for:)` : 1 spawn si cet écran n’a pas encore son poisson de départ.
- `tick` : `school.tick` puis `scenery.scroll(cameraDelta: 22 * dt)` sur chaque painter, sync layers, émission de bulles de poisson.

L’aléa **d’écran** au clavier peut utiliser `Int.random` côté exécutable (comme Galaxie). L’aléa **du poisson** passe par un `RandomNumberGenerator` détenu par le director (pas besoin d’être seedé en prod).

`OceanSchool.tick(screenWidths:)` : passer la largeur de chaque painter dans l’ordre des indices.

## Bulles (painter only)

- Layer `bubble_a` / `_b` / `_c` au hasard, taille ~24–48 pt.
- Poisson : origine près du bord droit du sprite (tête après miroir), léger jitter.
- Clic : `spawnClickBubbles(at: CGPoint, count: Int)` avec `count ∈ 1...3`.
- Animation : `y += riseSpeed * dt` ou `CABasicAnimation` position + fade. Détruire après `1.4...2.2` s. Ne pas laisser les layers s’accumuler (même schéma `asyncAfter` + remove que Galaxie).

Pas d’effet `mouseMoved`.

## Concurrence

Reprendre `GalaxyPainter` : AppKit peut appeler `keyDown` hors MainActor isolé Swift. `nonisolated` sur les overrides NSView, hop vers le main pour CA. Pas de `Task.detached`. Swift 6 strict.

## Ne pas faire

- Modifier `CoverWindowCoordinator` (06).
- Importer SpriteKit.
- Afficher des lettres / emojis / `CATextLayer` de glyphes.
- Accélérer `cameraSpeed` à la frappe.
- Traînée de souris.
- Changer `OceanSchool` / `OceanScenery` sauf bug bloquant découvert ici — alors corriger avec test kit.
- Toucher le filtre d’entrée, le HUD, `KioskInputBridge` (l’injecter seulement, comme Galaxie).

## Commentaires

- Référence visuelle : dune de sable sur terre, eau claire, poissons gauche → droite, algues plantées. Le `Sample.png` du pack (hors dépôt) donne l’ambiance, sans le score HUD.
- Vérif manuelle complète au ticket 06.
