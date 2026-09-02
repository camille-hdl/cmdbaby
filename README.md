# BabyWork

BabyWork est un projet d’application macOS ludique permettant à un jeune enfant de manipuler le clavier et la souris dans un environnement visuel confiné. Le produit reste un confinement anti-bêtises robuste, pas une frontière de sécurité inviolable.

Le développement se trouve dans la phase 0 de faisabilité. La seule tranche actuellement autorisée est l’inventaire du Mac cible au moyen de l’application diagnostique.

## Prérequis actuels

- macOS 13 ou ultérieur ;
- Swift 6.1 ou ultérieur ;
- Xcode complet pour le développement normal et les essais d’identité Apple ; les Command Line Tools suffisent pour compiler le diagnostic actuel ;
- une identité Apple Development ou Developer ID Application installée dans le trousseau pour obtenir une identité de code stable lors des essais TCC.

Afficher les identités disponibles :

```sh
security find-identity -v -p codesigning
```

## Tester

```sh
swift test
```

Les tests du diagnostic passent par son interface publique de rapport. Les valeurs macOS y sont injectées afin que les attentes restent déterministes et ne dépendent pas du poste exécutant la suite.

## Construire l’application diagnostique

Pour une exécution locale sans identité installée :

```sh
./scripts/build-diagnostics-app.sh
open .build/app/BabyWorkDiagnostics.app
```

Cette voie utilise une signature ad hoc. Elle permet de vérifier le bundle et l’interface, mais **elle n’offre pas une identité suffisamment stable pour les futurs essais TCC**.

Pour une signature stable, fournir exactement le nom d’une identité retournée par `security find-identity` :

```sh
BABYWORK_CODE_SIGN_IDENTITY="Apple Development: Exemple (TEAMID)" \
  ./scripts/build-diagnostics-app.sh
```

Le Bundle ID reste `fr.camille.babywork.diagnostics`. Vérifier le bundle produit :

```sh
codesign --verify --deep --strict --verbose=2 .build/app/BabyWorkDiagnostics.app
codesign --display --verbose=4 .build/app/BabyWorkDiagnostics.app
```

## Relever l’environnement manuellement

```sh
sw_vers
uname -m
xcodebuild -version
xcode-select -p
xcrun swift --version
system_profiler SPDisplaysDataType -json
security find-identity -v -p codesigning
```

Ces commandes sont en lecture seule. Le rapport de phase 0 ne doit contenir ni donnée saisie au clavier, ni chemin privé complet, ni contenu d’image.
