# Ajouter un mode de jeu

Un mode neuf ne touche que ces endroits.

1. Ajouter un cas à `KioskPlayModeID` (`Sources/CmdBabyKit/KioskPlayMode.swift`), puis `displayName` et `tagline` dans `KioskPlayModeCatalog`. L’ordre des cas est l’ordre d’affichage : `available` vaut `allCases`.
2. Créer `Sources/CmdBaby/XxxPlayMode.swift` : une classe `@MainActor` qui conforme `PlayMode` (`windowBackground`, `makeStage`, `reset`).
3. Ajouter le cas dans les deux `switch` de `PlayModeRegistry` (`Sources/CmdBaby/PlayMode.swift`) : `make` et `preview`. La fenêtre Réglages n’en a pas : elle liste `KioskPlayModeCatalog.available`.
4. Ajouter le cas, dans le même ordre, à `SessionLaunchMode.playModes` et aux deux `switch` de `StartSessionMode` (`init` et `playMode`). Le test `shortcutModesMatchThePlayModeCatalog` échoue si la liste du kit oublie le mode. La compilation de l’app échoue si l’`AppEnum` l’oublie. Le nom affiché reprend le libellé du catalogue (`Ocean`, `Terminal`, `Starship` dans `Localizable.strings` de l’app).
5. Aperçu statique, obligatoire : une vue SwiftUI à côté de l’implémentation du mode, dessinée sans aléa, sans timer et sans animation, branchée dans `PlayModeRegistry.preview`. L’aperçu se redimensionne avec `.aspectRatio(16/10, contentMode: .fit)`.
6. Ressources éventuelles : les déclarer dans `Package.swift`, cible `CmdBaby`, tableau `resources` (comme `.process("Resources/Ocean")`).

Un mode ne gère pas les sorties adultes, le confinement, le carré de secours ni le minuteur. Tout cela passe par `KioskInputBridge` et les couvertures. La scène renvoyée par `makeStage` ne contient pas le carré de secours.
