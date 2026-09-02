# 10: Réconcilier la topologie des écrans à chaud

**What to build:** La couverture enfant reste cohérente quand la configuration des écrans change, sans dépendre de leur position dans une liste mise en cache.

**Blocked by:** 09 — Afficher le fond sur tous les écrans.

**Status:** ready-for-agent

- [ ] L’ajout d’un écran pendant la session crée une fenêtre préparée avec le fond actif.
- [ ] Le retrait d’un écran libère sa fenêtre et reroute les futures interactions vers un écran encore disponible.
- [ ] Un changement de résolution, d’orientation ou de facteur d’échelle recalcule le rendu et les transformations.
- [ ] Les écrans en miroir sont traités sans créer d’état contradictoire ni de fenêtre orpheline.
- [ ] Les écrans sont corrélés au moyen d’un identifiant stable lorsque macOS en fournit un.
- [ ] Le comportement est vérifié avec Spaces séparés ou communs et avec Stage Manager.
- [ ] Les transformations entre coordonnées globales, coordonnées de fenêtre et coordonnées de scène sont couvertes par des tests déterministes.
