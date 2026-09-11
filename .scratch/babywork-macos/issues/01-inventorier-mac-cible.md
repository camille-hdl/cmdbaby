# 01: Inventorier le Mac cible dans une application signée

**What to build:** Une application diagnostique macOS minimale et signée qui présente au développeur les caractéristiques du Mac cible et l’état initial des capacités système nécessaires à BabyWork.

**Blocked by:** None (can start immediately).

**Status:** resolved

- [x] L’application se compile et s’exécute sur le Mac cible avec le mode de concurrence stricte Swift 6.
- [x] L’identité de bundle et la signature utilisées pour les essais TCC sont stables et leur procédure de reproduction est documentée.
- [x] L’interface affiche la version de macOS, l’architecture, la version de Xcode et la liste actuelle des écrans.
- [x] L’interface affiche séparément l’état des permissions susceptibles d’être nécessaires au filtrage des entrées.
- [x] Aucune élévation de privilège, télémétrie ou communication réseau n’est introduite.
- [x] Un test automatisé vérifie la présentation du diagnostic à partir de valeurs système injectées.
- [x] Les commandes permettant de reproduire le build signé et le relevé d’environnement sont documentées sans exposer de donnée privée.

## Réponse

Inventaire à jour dans `docs/phase-0/environment-inventory.md`. Bundle diagnostique signé avec une identité Apple Development valide ; exigence désignée stable sur deux builds ; Hardened Runtime actif ; Bundle ID `fr.camille.babywork.diagnostics` ; `TeamIdentifier` `2B8R2FVJP6`. Trois écrans relevés, dont une origine négative.

## Commentaires

### 2 septembre 2026 — Première implémentation

L’application SwiftUI, le rapport injectable, les tests Swift 6 et le script de création du bundle ont été ajoutés. Le bundle `arm64` utilise un identifiant stable, le Hardened Runtime et une signature ad hoc vérifiée ; son lancement dans la session graphique a été confirmé.

Le critère de signature TCC stable reste ouvert : le Mac utilise uniquement les Command Line Tools et ne possède actuellement aucune identité de signature valide. Installer Xcode complet et une identité Apple Development ou Developer ID Application, reconstruire avec cette identité, puis consigner la vérification `codesign` avant de résoudre ce ticket ou de commencer le ticket 02.

### 11 septembre 2026 — Signature stable et inventaire rafraîchi

Xcode 26.6 est sélectionné. Le certificat Apple Development était présent avec sa clé privée mais l’identité restait invalide faute de l’intermédiaire Apple WWDR G3 ; import de [AppleWWDRCAG3.cer](https://www.apple.com/certificateauthority/AppleWWDRCAG3.cer) dans le trousseau login. `security find-identity -v -p codesigning` liste ensuite une identité valide.

Deux builds Release avec `BABYWORK_CODE_SIGN_IDENTITY` pointant vers cette identité produisent la même exigence désignée :

```text
identifier "fr.camille.babywork.diagnostics" and anchor apple generic and certificate leaf[subject.CN] = "Apple Development: …" and certificate 1[field.1.2.840.113635.100.6.2.1] /* exists */
```

Procédure reproduite dans le README et l’inventaire phase 0. Ticket prêt à être considéré résolu ; le ticket 02 n’est plus bloqué par la signature.
