# 01: Inventorier le Mac cible dans une application signée

**What to build:** Une application diagnostique macOS minimale et signée qui présente au développeur les caractéristiques du Mac cible et l’état initial des capacités système nécessaires à BabyWork.

**Blocked by:** None (can start immediately).

**Status:** ready-for-agent

- [ ] L’application se compile et s’exécute sur le Mac cible avec le mode de concurrence stricte Swift 6.
- [ ] L’identité de bundle et la signature utilisées pour les essais TCC sont stables et leur procédure de reproduction est documentée.
- [ ] L’interface affiche la version de macOS, l’architecture, la version de Xcode et la liste actuelle des écrans.
- [ ] L’interface affiche séparément l’état des permissions susceptibles d’être nécessaires au filtrage des entrées.
- [ ] Aucune élévation de privilège, télémétrie ou communication réseau n’est introduite.
- [ ] Un test automatisé vérifie la présentation du diagnostic à partir de valeurs système injectées.
- [ ] Les commandes permettant de reproduire le build signé et le relevé d’environnement sont documentées sans exposer de donnée privée.
