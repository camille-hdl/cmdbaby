# 07: Choisir et afficher un premier fond

**What to build:** Le parent choisit un dossier, parcourt ses images valides, sélectionne un fond et le voit dans une session enfant sur l’écran principal.

**Blocked by:** 05 — Livrer une première session enfant transactionnelle.

**Status:** ready-for-agent

- [ ] Le parent peut sélectionner explicitement un dossier au moyen de l’interface macOS prévue à cet effet.
- [ ] La galerie présente des miniatures générées hors du thread principal pour les formats d’image pris en charge.
- [ ] Les fichiers cachés, non lisibles, corrompus ou manifestement excessifs n’empêchent pas l’affichage des autres images.
- [ ] Le parent choisit une image précise et voit clairement laquelle sera utilisée.
- [ ] Le démarrage refuse une sélection devenue invalide au lieu d’ouvrir une session au fond indéfini.
- [ ] L’image choisie apparaît sur l’écran principal avec un remplissage proportionnel et un recadrage centré, sans déformation.
- [ ] Des fixtures vérifient le catalogue, les limites de décodage, la sélection et le rendu attendu sans dépendre du dossier personnel du développeur.
