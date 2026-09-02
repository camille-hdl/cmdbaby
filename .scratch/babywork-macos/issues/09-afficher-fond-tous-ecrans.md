# 09: Afficher le fond sur tous les écrans

**What to build:** Une session enfant affiche le fond choisi dans une fenêtre indépendante sur chaque écran connecté, sans lacune de couverture ni déformation de l’image.

**Blocked by:** 07 — Choisir et afficher un premier fond.

**Status:** ready-for-agent

- [ ] Une fenêtre dédiée est créée pour chaque écran fourni par la configuration actuelle de macOS.
- [ ] Toutes les fenêtres sont prêtes avant que la session puisse devenir active.
- [ ] La même image est sous-échantillonnée selon les dimensions en pixels nécessaires à chaque écran avant le rendu.
- [ ] Chaque fenêtre utilise un remplissage proportionnel et un recadrage centré sans étirement.
- [ ] Les configurations avec origines négatives et facteurs d’échelle différents sont représentées correctement.
- [ ] Un échec de préparation sur un écran empêche l’activation et ferme toutes les fenêtres déjà créées.
- [ ] Les tests vérifient la couverture et les transformations à partir de configurations d’écrans injectées.
