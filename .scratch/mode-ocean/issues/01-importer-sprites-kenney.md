# 01: Importer les sprites Kenney

Type: task

**What to build:** Copier le sous-ensemble utile du Kenney Fish Pack 2.0 dans le bundle de l’exécutable, déclarer les resources SPM, conserver la licence CC0. Aucune logique de jeu.

**Blocked by:** —

**Status:** ready-for-agent

Lire d’abord [`.scratch/mode-ocean/spec.md`](../spec.md) section **Assets**. Source : `/Volumes/WD_BLACK/2D/kenney_fish-pack_2`. Si le volume est absent, s’arrêter avec un message clair. Ne pas substituer d’autres packs.

## Checklist

- [ ] Les PNG listés ci-dessous existent sous `Sources/BabyWorkDiagnostics/Resources/Ocean/`, copiés depuis `PNG/Double/` (128×128), mêmes noms de fichiers.
- [ ] `License.txt` du pack est copié à côté des PNG (depuis la racine du pack, pas depuis `PNG/Double/`).
- [ ] Aucun `hud_*`, `*_outline*`, `*_skeleton*`, `fish_grey_long_*`, Default, Vector, Spritesheet, Preview ou Sample n’est dans le dépôt.
- [ ] `Package.swift` : la target `BabyWorkDiagnostics` déclare `resources: [.process("Resources/Ocean")]`.
- [ ] Le projet compile (`swift build`). Un test kit existant continue de passer. Pas de code de rendu dans ce ticket.

## Fichiers cibles

- Créer `Sources/BabyWorkDiagnostics/Resources/Ocean/` (tous les PNG + `License.txt`)
- Modifier [`Package.swift`](../../../Package.swift) uniquement pour ajouter `resources` à `.executableTarget(name: "BabyWorkDiagnostics", ...)`

## Liste exacte à copier

Depuis `/Volumes/WD_BLACK/2D/kenney_fish-pack_2/PNG/Double/` :

```
bubble_a.png
bubble_b.png
bubble_c.png
fish_blue.png
fish_green.png
fish_orange.png
fish_pink.png
fish_red.png
fish_brown.png
fish_grey.png
seaweed_green_a.png
seaweed_green_b.png
seaweed_green_c.png
seaweed_green_d.png
seaweed_grass_a.png
seaweed_grass_b.png
seaweed_orange_a.png
seaweed_orange_b.png
seaweed_pink_a.png
seaweed_pink_b.png
seaweed_pink_c.png
seaweed_pink_d.png
rock_a.png
rock_b.png
terrain_sand_a.png
terrain_sand_b.png
terrain_sand_c.png
terrain_sand_d.png
terrain_sand_top_a.png
terrain_sand_top_b.png
terrain_sand_top_c.png
terrain_sand_top_d.png
terrain_sand_top_e.png
terrain_sand_top_f.png
terrain_sand_top_g.png
terrain_sand_top_h.png
terrain_dirt_a.png
terrain_dirt_b.png
terrain_dirt_c.png
terrain_dirt_d.png
terrain_dirt_top_a.png
terrain_dirt_top_b.png
terrain_dirt_top_c.png
terrain_dirt_top_d.png
terrain_dirt_top_e.png
terrain_dirt_top_f.png
terrain_dirt_top_g.png
terrain_dirt_top_h.png
background_seaweed_a.png
background_seaweed_b.png
background_seaweed_c.png
background_seaweed_d.png
background_seaweed_e.png
background_seaweed_f.png
background_seaweed_g.png
background_seaweed_h.png
background_rock_a.png
background_rock_b.png
background_terrain.png
background_terrain_top.png
```

Depuis `/Volumes/WD_BLACK/2D/kenney_fish-pack_2/License.txt` → `Sources/BabyWorkDiagnostics/Resources/Ocean/License.txt`.

## `Package.swift`

Sur `.executableTarget(name: "BabyWorkDiagnostics", ...)` ajouter, en plus des `dependencies` et `linkerSettings` existants :

```swift
resources: [
  .process("Resources/Ocean"),
],
```

Ne pas ajouter SpriteKit aux `linkerSettings`.

## Vérification

```
find Sources/BabyWorkDiagnostics/Resources/Ocean -name 'hud_*' | wc -l
# attendu : 0
ls Sources/BabyWorkDiagnostics/Resources/Ocean/*.png | wc -l
# attendu : 60
swift build
```

## Ne pas faire

- Écrire `OceanPlayMode`, toucher le catalogue, ou charger une image en Swift.
- Copier `PNG/Default/`, SVG, spritesheet, outlines, skeletons, HUD, `fish_grey_long_*`.
- Inventer des assets de remplacement si le volume WD_BLACK est démonté.
- Créer un `.xcassets` ou un `.atlas` SpriteKit.
- Committer des fichiers hors de `Resources/Ocean/` et `Package.swift`.

## Commentaires

- Licence CC0 : crédit Kenney encouragé, non obligatoire. Garder `License.txt` dans le bundle suffit.
