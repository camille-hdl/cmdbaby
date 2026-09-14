# 04: Génération du décor parallaxe

Type: task

**What to build:** Un module kit pur `OceanScenery` qui place terre, sable, silhouettes et props sur un écran, puis les fait défiler avec wrap.

**Blocked by:** —

**Status:** resolved

Lire [`.scratch/mode-ocean/spec.md`](../spec.md) sections **Parallaxe et décor**, **Constantes**, **Interfaces kit attendues**. Aucune image dans ce ticket : le décor est une liste de props nommés (`assetName` = nom de fichier sans `.png`).

## Checklist

- [x] `OceanScenery.generate(bounds:rng:)` produit un sol terre (bande basse `0.10 * height`) + sable (`0.12 * height` au-dessus). `groundTop == dirtHeight + sandHeight` (≈ `0.22 * height`).
- [x] Des props `terrain_dirt_*` / `terrain_dirt_top_*` couvrent la bande terre ; `terrain_sand_*` / `terrain_sand_top_*` couvrent la bande sable. La crête (`*_top_*`) est alignée sur le haut de chaque bande.
- [x] Couche `far` : au moins 4 silhouettes parmi `background_seaweed_*` / `background_rock_*` (et optionnellement `background_terrain`), y dans la moitié haute de l’eau.
- [x] Couche `mid` : au moins 3 props (algues ou rochers de fond), y entre `groundTop` et ~`0.55 * height`.
- [x] Couche `foreground` : au moins 3 props `seaweed_*` ou `rock_*` plantés sur la crête de sable (`y` proche de `groundTop`).
- [x] `scroll(cameraDelta:bounds:)` déplace `x` de `-cameraDelta * factor` selon la couche (far 0,18, mid 0,40, ground 0,72, foreground 1,0) puis wrap dans `[0, width)` (ou équivalent qui empêche les props de disparaître définitivement).
- [x] Même `bounds` + même seed ⇒ mêmes props (noms et positions).
- [x] Tests sans AppKit. Aucun PNG chargé.

## Fichiers cibles

- Créer `Sources/BabyWorkDiagnosticsKit/OceanScenery.swift`
- Créer `Tests/BabyWorkDiagnosticsKitTests/OceanSceneryTests.swift`

Les facteurs de parallaxe et proportions de sol sont des `static let` nommés sur `OceanScenery` ou un enum voisin, pour que le renderer (ticket 05) les relise au lieu de les dupliquer.

## Contrat

S’aligner sur la spec. Si `OceanPropKind.sprite(String)` est gênant :

```swift
public struct OceanPropKind: Equatable, Sendable {
  public let assetName: String
}
```

`assetName` est exactement le nom Kenney sans extension, ex. `terrain_sand_top_c`, `seaweed_green_a`, `background_rock_b`.

Densités minimales (pour un écran ≥ 800×600 ; proportionnelles à `width` si plus large) :

- Sol : tuiles assez nombreuses pour **couvrir** la largeur sans trou (pas 2 tuiles isolées). Répéter les variantes `a–d` (fill) et `a–h` (top) via le rng.
- Far : 4–8 props.
- Mid : 3–6 props.
- Foreground : 3–8 props.

Écran minuscule (`width < 8` ou `height < 8`) : décor vide, `groundTop` calculé quand même.

`scroll` : `cameraDelta` est en points de caméra (déjà `cameraSpeed * dt` côté renderer). Ne pas clamp `cameraDelta`. Wrap : après décalage, tant que `x < -margin` ajouter `width + 2*margin`, tant que `x > width + margin` soustraire ; `margin` ≈ 80 pt pour que le sprite ne clignote pas. Le **nombre** de props ne change pas.

## Tests

1. `groundTop` égal à `0.22 * height` à `0.5` pt près ; `dirtHeight + sandHeight == groundTop`.
2. Au moins un prop dont `assetName` a le préfixe `terrain_dirt` et un `terrain_sand`.
3. Au moins un prop `layer == .far` et un `layer == .foreground`.
4. `scroll` de `cameraDelta = width / 0.18` (un tour de couche loin) conserve `props.count` et ramène les x dans une bande finie autour de `[0, width]`.
5. Deux `generate` avec le même rng recréé (même seed) sont égaux.
6. Deux seeds différents ne sont pas égaux (sur un écran 800×600).

## Ne pas faire

- Charger des PNG, importer AppKit, dessiner.
- Animer les algues (ondulation, sway).
- Faire défiler les poissons ici (c’est `OceanSchool`).
- Utiliser les sprites HUD / outline / skeleton / `fish_*`.
- Introduire SpriteKit (`SKTileMapNode`, etc.).

## Commentaires

- Le renderer posera un `CALayer` par prop, `contents` = image du `assetName`. Ce ticket ne fait que des nombres et des noms.

## Réponse

`OceanScenery` vit dans le kit : `generate` pose terre + sable (tuiles `a–d` / crêtes `a–h`), silhouettes loin, props milieu, algues et rochers sur la crête. `scroll` applique le facteur de couche puis wrap avec marge 80 pt. `OceanPropKind` est un struct `assetName` (l’enum associé de la spec n’est pas `RawRepresentable`). Neuf tests seedés passent, sans AppKit ni PNG.
