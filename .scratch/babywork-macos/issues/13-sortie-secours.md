# 13: Ajouter la sortie adulte de secours

**What to build:** Le parent peut arrêter toute session active en maintenant simultanément les deux touches Majuscule pendant trois secondes, même si le rendu ou le thread principal est momentanément indisponible.

**Blocked by:** 05 — Livrer une première session enfant transactionnelle.

**Status:** ready-for-agent

- [ ] La durée de maintien est mesurée par une horloge monotone injectable.
- [ ] Le compteur ne démarre que lorsque les deux touches sont effectivement maintenues en même temps.
- [ ] Le relâchement d’une touche avant trois secondes annule proprement la tentative.
- [ ] Les répétitions matérielles et changements de modificateurs ne provoquent pas de sortie anticipée.
- [ ] Une reconnaissance valide emprunte exactement le même arrêt transactionnel que la sortie principale.
- [ ] La reconnaissance ne dépend ni de SpriteKit ni d’une animation et minimise sa dépendance au thread principal.
- [ ] Des tests déterministes couvrent succès, seuil temporel, relâchements intermittents, répétitions et faux positifs.
