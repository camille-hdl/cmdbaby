# Inventaire du Mac cible

Relevé initial le 2 septembre 2026 ; mis à jour le 11 septembre 2026 après installation de Xcode et d’une identité Apple Development.

## Environnement observé

- MacBook Pro (`Mac15,6`), puce Apple M3 Pro ;
- CPU : 11 cœurs (5 performance, 6 efficacité) ; mémoire : 18 Go ;
- GPU Apple M3 Pro, 14 cœurs ;
- macOS 26.6.2, build 25G83 ;
- architecture `arm64` ;
- Xcode 26.6 (build 17F113) ; répertoire développeur actif : `/Applications/Xcode.app/Contents/Developer` ;
- Swift 6.3.3 (`swiftlang-6.3.3.1.3`) ;
- une identité Apple Development valide est disponible dans le trousseau (Personal Team) ; `TeamIdentifier` observé sur le bundle signé : `2B8R2FVJP6` ;
- Hardened Runtime activé sur le bundle diagnostique ;
- trois écrans relevés via AppKit dans la session graphique :
  - `Built-in Retina Display` — 1512×982 points, échelle 2,0, origine (0, 0), écran principal ;
  - `ROG PG279Q` — 2560×1440 points, échelle 2,0, origine (2259, 881) ;
  - `MSI MAG323UPF` — 3008×1692 points, échelle 2,0, origine (−749, 982).

## Signature et stabilité TCC

Deux builds Release successifs signés avec l’identité Apple Development produisent la **même exigence désignée** (`codesign -d -r-`), ancrée sur :

- l’identifiant de bundle `fr.camille.babywork.diagnostics` ;
- le certificat feuille Apple Development ;
- l’intermédiaire Apple WWDR (OID `1.2.840.113635.100.6.2.1`).

Cette exigence ne dépend pas du `CDHash`. Elle est donc adaptée aux essais TCC, contrairement à une signature ad hoc.

Lors de la mise en service, le certificat feuille était présent avec sa clé privée, mais l’identité restait invalide (`unable to build chain to self-signed root`) faute de l’intermédiaire **Apple WWDR G3** dans le trousseau. Import depuis [Apple PKI](https://www.apple.com/certificateauthority/) :

```sh
curl -fsSL -o AppleWWDRCAG3.cer \
  https://www.apple.com/certificateauthority/AppleWWDRCAG3.cer
security import AppleWWDRCAG3.cer \
  -k ~/Library/Keychains/login.keychain-db -t cert
```

## Conséquences

- Le ticket 01 peut être clos : inventaire à jour et signature TCC stable démontrée.
- Le ticket 02 (filtrage actif) peut démarrer sur ce Mac, avec trois écrans dont une origine négative — configuration utile pour les essais multi-écrans ultérieurs.
- Le compte Apple Developer gratuit (Personal Team) suffit pour la phase 0 locale ; pas de Developer ID ni de notarisation à ce stade.
- L’identité doit continuer d’être fournie au script via `BABYWORK_CODE_SIGN_IDENTITY`, sans être inscrite en dur dans les sources.

## Confidentialité

Le diagnostic lit uniquement des métadonnées système locales et les états booléens de pré-vérification des permissions. Il n’active aucun tap, ne demande aucune autorisation, ne capture aucune frappe et n’effectue aucun accès réseau. Cet inventaire n’inclut ni numéro de série, ni adresse e-mail, ni chemin privé.
