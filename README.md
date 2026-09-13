# BabyWork

BabyWork est un projet d’application macOS ludique permettant à un jeune enfant de manipuler le clavier et la souris dans un environnement visuel confiné. Le produit reste un confinement anti-bêtises robuste, pas une frontière de sécurité inviolable.

Le développement se trouve dans la phase 0 de faisabilité. L’inventaire du Mac cible et la signature TCC stable sont en place ; la prochaine tranche autorisée est le prototype de filtrage actif des entrées (ticket 02).

## Prérequis actuels

- macOS 13 ou ultérieur ;
- Swift 6.1 ou ultérieur ;
- Xcode complet pour le développement normal et les essais d’identité Apple ; les Command Line Tools suffisent pour compiler le diagnostic actuel ;
- une identité Apple Development ou Developer ID Application **valide** dans le trousseau pour les essais TCC ;
- l’intermédiaire Apple WWDR G3 si `security find-identity -v` ne liste aucune identité alors qu’un certificat Apple Development est déjà présent.

Afficher les identités disponibles :

```sh
security find-identity -v -p codesigning
```

Si une identité apparaît sans `-v` mais qu’aucune n’est « valid », et que `codesign` signale `unable to build chain to self-signed root`, importer l’intermédiaire public :

```sh
curl -fsSL -o AppleWWDRCAG3.cer \
  https://www.apple.com/certificateauthority/AppleWWDRCAG3.cer
security import AppleWWDRCAG3.cer \
  -k ~/Library/Keychains/login.keychain-db -t cert
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
open /Applications/BabyWorkDiagnostics.app
```

Cette voie utilise une signature ad hoc. Elle permet de vérifier le bundle et l’interface, mais **elle n’offre pas une identité suffisamment stable pour les essais TCC**.

Pour une signature stable, fournir exactement le nom d’une identité **valide** retournée par `security find-identity -v` :

```sh
BABYWORK_CODE_SIGN_IDENTITY="Apple Development: Exemple (TEAMID)" \
  ./scripts/build-diagnostics-app.sh
```

Le Bundle ID reste `fr.camille.babywork.diagnostics`. Vérifier le bundle produit et l’exigence désignée :

```sh
codesign --verify --deep --strict --verbose=2 /Applications/BabyWorkDiagnostics.app
codesign --display --verbose=4 /Applications/BabyWorkDiagnostics.app
codesign -d -r- /Applications/BabyWorkDiagnostics.app
```

L’exigence désignée d’une signature Apple Development doit mentionner l’identifiant de bundle et le certificat feuille, et non seulement un `CDHash`. Elle doit rester identique d’un build à l’autre. L’inventaire factuel du Mac cible est dans `docs/phase-0/environment-inventory.md`.

Pour comparer App Sandbox activé / désactivé :

```sh
BABYWORK_CODE_SIGN_IDENTITY="Apple Development: Exemple (TEAMID)" \
  BABYWORK_APP_SANDBOX=0 \
  ./scripts/build-diagnostics-app.sh

BABYWORK_CODE_SIGN_IDENTITY="Apple Development: Exemple (TEAMID)" \
  BABYWORK_APP_SANDBOX=1 \
  ./scripts/build-diagnostics-app.sh
open /Applications/BabyWorkDiagnostics-sandbox.app
```

Le panneau **Filtrage actif** de l’application permet d’activer le `CGEventTap` de session, de demander les permissions et de compter les raccourcis absorbés sans journaliser les frappes. La grille manuelle est dans `docs/phase-0/input-filter-trials.md`.
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
