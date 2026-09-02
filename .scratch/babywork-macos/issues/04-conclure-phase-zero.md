# 04: Conclure la phase 0 et décider de poursuivre

**What to build:** Un dossier de décision permet au propriétaire de déterminer si le socle macOS est viable, sous quelles permissions et avec quelles limites, avant d’autoriser la construction du produit.

**Blocked by:** 02 — Prouver le filtrage actif des entrées; 03 — Prouver le confinement multi-écrans et les sorties adultes.

**Status:** ready-for-agent

- [ ] Le rapport décrit l’environnement exact, les manipulations reproductibles et les résultats observés sans transformer une hypothèse en fait.
- [ ] Les résultats distinguent App Sandbox activé et désactivé, ainsi que les différentes permissions effectivement demandées par macOS.
- [ ] Le rapport indique pour chaque raccourci ou fonction système testée si elle est absorbée, partiellement couverte ou hors de portée.
- [ ] Les limites concernant les boutons matériels, Touch ID, Secure Event Input et les gestes système sont rappelées honnêtement.
- [ ] Une ADR consigne la décision relative au sandbox, aux permissions, à la signature et au niveau de tap retenu.
- [ ] Toute incompatibilité bloquante est accompagnée d’au moins une alternative précise et de ses compromis.
- [ ] Le propriétaire donne une décision explicite de poursuivre, de modifier le plan ou d’arrêter; aucun ticket produit dépendant ne commence avant cette décision.
