# 01: Inventorier le Mac cible dans une application signée

**What to build:** Une application diagnostique macOS minimale et signée qui présente au développeur les caractéristiques du Mac cible et l’état initial des capacités système nécessaires à BabyWork.

**Blocked by:** None (can start immediately).

**Status:** ready-for-agent

- [x] L’application se compile et s’exécute sur le Mac cible avec le mode de concurrence stricte Swift 6.
- [ ] L’identité de bundle et la signature utilisées pour les essais TCC sont stables et leur procédure de reproduction est documentée.
- [x] L’interface affiche la version de macOS, l’architecture, la version de Xcode et la liste actuelle des écrans.
- [x] L’interface affiche séparément l’état des permissions susceptibles d’être nécessaires au filtrage des entrées.
- [x] Aucune élévation de privilège, télémétrie ou communication réseau n’est introduite.
- [x] Un test automatisé vérifie la présentation du diagnostic à partir de valeurs système injectées.
- [x] Les commandes permettant de reproduire le build signé et le relevé d’environnement sont documentées sans exposer de donnée privée.

## Commentaires

### 2 septembre 2026 — Première implémentation

L’application SwiftUI, le rapport injectable, les tests Swift 6 et le script de création du bundle ont été ajoutés. Le bundle `arm64` utilise un identifiant stable, le Hardened Runtime et une signature ad hoc vérifiée ; son lancement dans la session graphique a été confirmé.

Le critère de signature TCC stable reste ouvert : le Mac utilise uniquement les Command Line Tools et ne possède actuellement aucune identité de signature valide. Installer Xcode complet et une identité Apple Development ou Developer ID Application, reconstruire avec cette identité, puis consigner la vérification `codesign` avant de résoudre ce ticket ou de commencer le ticket 02.
