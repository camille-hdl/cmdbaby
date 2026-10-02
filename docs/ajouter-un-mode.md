# Ajouter un mode de jeu

Un mode neuf ne touche que ces endroits.

1. Ajouter un cas à `KioskPlayModeID` (`Sources/BabyWorkDiagnosticsKit/KioskPlayMode.swift`), puis `displayName` et `tagline` dans `KioskPlayModeCatalog`. L’ordre des cas est l’ordre d’affichage : `available` vaut `allCases`.
2. Créer `Sources/BabyWorks/XxxPlayMode.swift` : une classe `@MainActor` qui conforme `PlayMode` (`windowBackground`, `makeStage`, `reset`).
3. Ajouter le cas dans le `switch` de `PlayModeRegistry.make` (`Sources/BabyWorks/PlayMode.swift`). C’est le seul `switch` de l’app sur les modes.
4. Aperçu statique pour la carte de Réglages : à côté de l’implémentation du mode, après le ticket Réglages.
5. Ressources éventuelles : les déclarer dans `Package.swift`, cible `BabyWorks`, tableau `resources` (comme `.process("Resources/Ocean")`).

Un mode ne gère pas les sorties adultes, le confinement, le carré de secours ni le minuteur. Tout cela passe par `KioskInputBridge` et les couvertures. La scène renvoyée par `makeStage` ne contient pas le carré de secours.
