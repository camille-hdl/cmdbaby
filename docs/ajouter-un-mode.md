# Ajouter un mode de jeu

Un mode neuf ne touche que ces endroits.

1. Ajouter un cas à `KioskPlayModeID` (`Sources/CmdBabyKit/KioskPlayMode.swift`), puis `displayName` et `tagline` dans `KioskPlayModeCatalog`. L’ordre des cas est l’ordre d’affichage : `available` vaut `allCases`.
2. Créer `Sources/CmdBaby/XxxPlayMode.swift` : une classe `@MainActor` qui conforme `PlayMode` (`windowBackground`, `makeStage`, `reset`).
3. Ajouter le cas dans les deux `switch` de `PlayModeRegistry` (`Sources/CmdBaby/PlayMode.swift`) : `make` et `preview`. Ce sont les seuls `switch` de l’app sur les modes. La fenêtre Réglages n’en a pas : elle liste `KioskPlayModeCatalog.available`.
4. Aperçu statique, obligatoire : une vue SwiftUI à côté de l’implémentation du mode, dessinée sans aléa, sans timer et sans animation, branchée dans `PlayModeRegistry.preview`. L’aperçu se redimensionne avec `.aspectRatio(16/10, contentMode: .fit)`.
5. Ressources éventuelles : les déclarer dans `Package.swift`, cible `CmdBaby`, tableau `resources` (comme `.process("Resources/Ocean")`).

Un mode ne gère pas les sorties adultes, le confinement, le carré de secours ni le minuteur. Tout cela passe par `KioskInputBridge` et les couvertures. La scène renvoyée par `makeStage` ne contient pas le carré de secours.
