# 18: Durcir l’expérience sous charge

**What to build:** BabyWork reste réactif et stabilise sa mémoire pendant des rafales d’entrées et des sessions répétées, sans compromettre les sorties adultes ni la restauration du Mac.

**Blocked by:** 11 — Réagir visuellement aux frappes; 12 — Réagir visuellement aux clics; 15 — Traverser les interruptions système; 16 — Récupérer après la perte du dossier d’images.

**Status:** ready-for-agent

- [ ] Une charge reproductible combine frappes, mouvements, clics et changements d’environnement à une cadence supérieure à l’usage attendu.
- [ ] Le callback du tap respecte un budget mesuré et ne déclenche pas de désactivation imputable à un travail excessif.
- [ ] Les files, tâches, images décodées et nœuds SpriteKit ont des limites explicites vérifiées sous saturation.
- [ ] Les sorties adultes restent reconnues dans leur délai même lorsque les mouvements sont regroupés ou perdus.
- [ ] Le rendu vise 60 Hz sans supposer que tous les écrans ont le même taux de rafraîchissement.
- [ ] La mémoire revient à un plateau après plusieurs démarrages, arrêts et reconfigurations; toute croissance restante est expliquée.
- [ ] Instruments et les signposts mesurent latence, temps de rendu, allocations et durée des transitions critiques.
- [ ] Address Sanitizer et Thread Sanitizer ne révèlent aucune anomalie dans les scénarios applicables.
