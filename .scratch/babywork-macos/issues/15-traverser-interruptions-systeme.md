# 15: Traverser les interruptions système

**What to build:** Veille, réveil et révocation d’autorisation conduisent la session vers un état cohérent et récupérable, sans bureau révélé ni protection partielle silencieuse.

**Blocked by:** 06 — Guider le parent dans les permissions; 10 — Réconcilier la topologie des écrans à chaud; 14 — Récupérer après la désactivation du bouclier.

**Status:** ready-for-agent

- [ ] La mise en veille suspend ou prépare les composants sensibles sans perdre l’état nécessaire à une récupération sûre.
- [ ] Au réveil, la configuration des écrans, les fenêtres, les permissions et le tap sont revalidés avant de déclarer la session active.
- [ ] Une permission révoquée pendant la session déclenche un état dégradé explicite et une action corrective parent.
- [ ] Une reconfiguration survenue pendant la veille est correctement réconciliée au réveil.
- [ ] Une impossibilité de reprendre conduit à un arrêt transactionnel ou à une couverture maintenue selon la voie la plus sûre documentée.
- [ ] Les événements système répétés ne créent ni tâches orphelines ni transitions concurrentes invalides.
- [ ] Des tests déterministes couvrent les principaux ordonnancements veille, réveil, changement d’écran, perte de permission et demande d’arrêt.
