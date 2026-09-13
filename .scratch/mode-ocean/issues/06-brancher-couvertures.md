# 06: Brancher Océan sur les couvertures

Type: task

**What to build:** `CoverWindowCoordinator` instancie le mode de `KioskPlayModeCatalog.default` (Océan). Clavier → poisson, clic → bulles. Galaxie reste constructible. Sorties adultes inchangées.

**Blocked by:** 02, 05

**Status:** ready-for-agent

Lire [`.scratch/mode-ocean/spec.md`](../spec.md) sections **Démarrage**, **Entrées et sorties adultes**, **Câblage des couvertures**. Fichier actuel : [`CoverWindowCoordinator.swift`](../../../Sources/BabyWorkDiagnostics/CoverWindowCoordinator.swift) (director et `contentView` câblés sur Galaxie).

## Checklist

- [ ] `createCoverWindows` switch sur `KioskPlayModeCatalog.default`.
- [ ] Défaut actuel = Océan → `OceanDirector` + `OceanStageView` par écran.
- [ ] `case .galaxy` construit encore `GalaxyDirector` + `GalaxyStageView` (pour plus tard). Aucune UI de choix.
- [ ] Le director n’est plus typé `GalaxyDirector?` seulement : enum interne `{ galaxy(GalaxyDirector), ocean(OceanDirector) }` avec `reset()` appelé depuis `closeCoverWindows`.
- [ ] `CoverWindow` n’importe plus `GalaxyDirector` en dur ; il reçoit le `NSView` déjà créé, ou un enum de play, sans dupliquer le reste de l’init fenêtre (level, collectionBehavior, failsafe déjà dans le stage).
- [ ] `OceanStageView.keyDown` notifie `inputBridge` **puis** `director.spawnKeyFish()` (pas `PlayGlyphResolver`).
- [ ] `mouseDown` : 1–3 bulles au `locationInWindow` ; `FailsafeClickView` toujours présent.
- [ ] `mouseMoved` / `mouseDragged` : pas de traînée en Océan.
- [ ] Une session kiosk sur Océan : 1 poisson par écran au départ, frappe ajoute un poisson (moitié gauche, écran aléatoire), clic ajoute des bulles, `parent`+Entrée et Maj+Échap et 5 clics secours fonctionnent encore.
- [ ] `swift test` et `swift build` passent. Tests kit catalogue + banc + décor verts.

## Fichiers cibles

- [`Sources/BabyWorkDiagnostics/CoverWindowCoordinator.swift`](../../../Sources/BabyWorkDiagnostics/CoverWindowCoordinator.swift)
- [`Sources/BabyWorkDiagnostics/OceanPlayMode.swift`](../../../Sources/BabyWorkDiagnostics/OceanPlayMode.swift) si `keyDown` / `mouseDown` n’ont pas été câblés au ticket 05
- Ne pas modifier le kit sauf bug de contrat.

## Câblage suggéré

Enum privé dans le coordinator (ou au-dessus de `CoverWindow`) :

```swift
private enum PlaySession {
  case ocean(OceanDirector)
  case galaxy(GalaxyDirector)

  func reset() {
    switch self {
    case .ocean(let director): director.reset()
    case .galaxy(let director): director.reset()
    }
  }
}
```

`createCoverWindows` :

```swift
let session: PlaySession
switch KioskPlayModeCatalog.default {
case .ocean:
  session = .ocean(OceanDirector())
case .galaxy:
  session = .galaxy(GalaxyDirector())
}
playSession = session
```

Pour chaque écran, construire le `contentView` correspondant et le passer à `CoverWindow`. Factoriser l’init fenêtre pour ne pas copier-coller `collectionBehavior` / `level` / etc.

Ne **pas** lire un UserDefaults, un flag compile-time, ou un argument de ligne de commande.

## Entrées (si pas déjà dans 05)

Copier `GalaxyStageView.keyDown` jusqu’à `inputBridge.noteKeyDown(...)`. Remplacer le spawn de glyphe par `director.spawnKeyFish()`. Ne pas logger le caractère.

`mouseDown` : `painter.spawnClickBubbles(at: event.locationInWindow, count: Int.random(in: 1...3))`.

Conserver `flagsChanged` et `performKeyEquivalent` sur `CoverWindow`.

## Vérification manuelle (matrice courte)

Sur le Mac cible, session kiosk :

1. Tous les écrans montrent eau + sol terre/sable + quelques algues/rochers, pas un fond Galaxie.
2. 1 poisson par écran, tête vers la droite, nage lente, vitesses un peu différentes, quelques bulles.
3. Le décor glisse lentement vers la gauche ; les poissons vont vers la droite.
4. Une touche → un poisson supplémentaire, moitié gauche d’un écran (parfois un autre écran).
5. Un clic → 1–3 bulles à l’endroit du clic, pas d’emoji.
6. Enfoncer beaucoup de touches : au-delà de 100 poissons, les plus anciens accélèrent et sortent à droite, puis disparaissent.
7. `parent` + Entrée quitte. Maj+Échap quitte. 5 clics coin secours quittent.
8. Relancer une session : Galaxie n’apparaît pas (défaut Océan).

## Ne pas faire

- Ajouter un sélecteur de mode dans l’UI parent.
- Casser Galaxie (le `case .galaxy` doit encore compiler et fonctionner si on inverse temporairement le `default` pour un smoke test).
- Modifier `SessionInputFilter`, `AdultExitRecognizer`, `KioskPresentationController`.
- Introduire SpriteKit « pour finir ».
- Remettre des lettres sur les frappes « en plus des poissons ».
- Router la frappe vers l’écran du pointeur (la spec dit aléatoire, comme Galaxie aujourd’hui).

## Commentaires

- Dernier ticket de la série. Après `resolved`, noter dans [`map.md`](../map.md) un pointeur vers le commit.
