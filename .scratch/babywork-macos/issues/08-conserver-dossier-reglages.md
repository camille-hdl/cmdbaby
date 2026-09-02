# 08: Conserver le dossier et les réglages

**What to build:** Après avoir quitté puis relancé BabyWork, le parent retrouve sa source d’images et ses préférences lorsque l’accès reste valable, avec une récupération claire lorsqu’il ne l’est plus.

**Blocked by:** 07 — Choisir et afficher un premier fond.

**Status:** ready-for-agent

- [ ] L’accès au dossier est conservé par le mécanisme compatible avec la décision sandbox de la phase 0.
- [ ] L’application équilibre chaque début d’accès à portée de sécurité par une fin d’accès, y compris après erreur ou annulation.
- [ ] La sélection du fond et les préférences nécessaires sont stockées dans une structure versionnée.
- [ ] Une relance restaure le dossier et la sélection sans enregistrer seulement un chemin devenu fragile.
- [ ] Un bookmark périmé déclenche sa résolution ou une invitation explicite à sélectionner de nouveau le dossier.
- [ ] Une migration automatisée démontre qu’une ancienne version de réglages reste lisible après évolution du schéma.
- [ ] Les réglages invalides ou partiellement corrompus produisent des valeurs de repli sûres et un diagnostic récupérable.
