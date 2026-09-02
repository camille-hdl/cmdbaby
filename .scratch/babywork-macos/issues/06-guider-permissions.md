# 06: Guider le parent dans les permissions

**What to build:** Le parent comprend l’état de chaque permission indispensable, sait comment la corriger et ne peut pas lancer une session présentée comme protégée lorsqu’une autorisation manque.

**Blocked by:** 05 — Livrer une première session enfant transactionnelle.

**Status:** ready-for-agent

- [ ] L’interface distingue chaque permission pertinente et son état actuel sans déduire un état global trompeur.
- [ ] Une permission manquante produit une explication compréhensible et une action corrective adaptée.
- [ ] Une nouvelle vérification reflète un changement effectué dans Réglages Système sans nécessiter de réinstallation.
- [ ] Le démarrage est refusé avant toute couverture si une permission critique empêche la création réelle du bouclier.
- [ ] Une erreur système inattendue est présentée au parent avec sa cause contextualisée et une possibilité de récupération.
- [ ] Des tests déterministes couvrent autorisations accordées, refusées, indéterminées et modifiées pendant le parcours parent.
- [ ] Aucun chemin privé, identifiant sensible ou contenu d’entrée n’est ajouté aux diagnostics ou aux journaux.
