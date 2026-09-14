# 02: Catalogue — Océan par défaut

Type: task

**What to build:** Enregistrer le mode Océan dans le catalogue kit et en faire le défaut. Galaxie reste disponible. Aucun rendu, aucun sprite.

**Blocked by:** —

**Status:** resolved

Lire [`.scratch/mode-ocean/spec.md`](../spec.md) sections **Glossaire** et **Architecture** (kit, catalogue seulement).

## Checklist

- [ ] `KioskPlayModeID` a `case ocean` (et conserve `case galaxy`).
- [ ] `KioskPlayModeCatalog.available == [.ocean, .galaxy]`.
- [ ] `KioskPlayModeCatalog.default == .ocean`.
- [ ] `displayName(.ocean) == "Océan"` ; `displayName(.galaxy) == "Galaxie"` inchangé.
- [ ] Le commentaire d’en-tête du fichier mentionne Océan (plus seulement « feuille, paysage, jeux »).
- [ ] Les tests catalogue existants sont mis à jour ; ils passent.
- [ ] `PlayGlyphResolver` et `WarpDrive` ne changent pas.

## Fichiers cibles

- [`Sources/BabyWorkDiagnosticsKit/KioskPlayMode.swift`](../../../Sources/BabyWorkDiagnosticsKit/KioskPlayMode.swift)
- [`Tests/BabyWorkDiagnosticsKitTests/KioskPlayModeTests.swift`](../../../Tests/BabyWorkDiagnosticsKitTests/KioskPlayModeTests.swift)

## Implémentation

Dans `KioskPlayModeID` :

```swift
public enum KioskPlayModeID: String, Sendable, CaseIterable, Equatable {
  case ocean
  case galaxy
}
```

Mettre `ocean` en premier pour que `CaseIterable.allCases` et `available` restent alignés.

```swift
public enum KioskPlayModeCatalog: Sendable {
  public static var available: [KioskPlayModeID] { [.ocean, .galaxy] }
  public static var `default`: KioskPlayModeID { .ocean }

  public static func displayName(_ id: KioskPlayModeID) -> String {
    switch id {
    case .ocean: "Océan"
    case .galaxy: "Galaxie"
    }
  }
}
```

Le `switch` doit rester exhaustif. Ne pas ajouter de `default`.

## Tests

Remplacer le test `playModeCatalogStartsWithGalaxy` par un test du type :

```swift
@Test("Le catalogue expose le mode océan par défaut")
func playModeCatalogDefaultsToOcean() {
  #expect(KioskPlayModeCatalog.available == [.ocean, .galaxy])
  #expect(KioskPlayModeCatalog.default == .ocean)
  #expect(KioskPlayModeCatalog.displayName(.ocean) == "Océan")
  #expect(KioskPlayModeCatalog.displayName(.galaxy) == "Galaxie")
}
```

Laisser les tests glyphes / warp inchangés.

Commande : `swift test --filter playModeCatalogDefaultsToOcean` puis `swift test --filter KioskPlayModeTests` si le filtre de fichier n’existe pas ; à défaut `swift test`.

## Ne pas faire

- Brancher `CoverWindowCoordinator` (ticket 06).
- Créer `OceanSchool` ou des sprites (tickets 01, 03).
- Ajouter une UI parent, un réglage UserDefaults, ou un argument CLI de mode.
- Supprimer `galaxy` du catalogue.
- Changer `PlayGlyphResolver.emojis`.

## Commentaires

- L’exécutable continue d’ouvrir Galaxie tant que 06 n’est pas fait. C’est attendu.

## Réponse

Le catalogue kit expose désormais `[.ocean, .galaxy]`, avec Océan comme mode jouable par défaut et les noms d’affichage `Océan` et `Galaxie`. Les tests catalogue ont été mis à jour ; le test ciblé passe. `PlayGlyphResolver` et `WarpDrive` sont inchangés.
