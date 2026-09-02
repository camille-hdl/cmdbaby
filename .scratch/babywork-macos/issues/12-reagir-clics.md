# 12: Réagir visuellement aux clics

**What to build:** Les clics de l’enfant produisent une animation à leur position sur le bon écran, tandis que les mouvements intensifs restent fluides grâce à un transport borné.

**Blocked by:** 09 — Afficher le fond sur tous les écrans.

**Status:** ready-for-agent

- [ ] Les boutons principaux et supplémentaires, mouvements, glissements et événements de molette sont reconnus par le bouclier.
- [ ] Un clic produit une animation aux coordonnées visuelles attendues dans la scène de l’écran concerné.
- [ ] Les coordonnées restent correctes avec origines négatives et facteurs d’échelle différents.
- [ ] Les mouvements fréquents sont regroupés ou remplacés selon une politique explicite avant le rendu.
- [ ] La file ne croît jamais proportionnellement au nombre total d’événements reçus.
- [ ] Le traitement des mouvements ne retarde ni ne perd un événement nécessaire à une sortie adulte.
- [ ] Des tests vérifient le routage, la conversion des coordonnées, la saturation de la file et la durée de vie bornée des animations.
