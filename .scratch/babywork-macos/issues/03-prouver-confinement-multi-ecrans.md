# 03: Prouver le confinement multi-écrans et les sorties adultes

**What to build:** Le prototype entre dans un mode de présentation couvrant tous les écrans disponibles, permet au parent d’en sortir par deux gestes indépendants et restaure l’état antérieur même après une activation incomplète.

**Blocked by:** 02 — Prouver le filtrage actif des entrées.

**Status:** ready-for-agent

- [ ] Une fenêtre sans bordure est créée et ajustée pour chaque écran disponible au moment de l’activation.
- [ ] Les options de présentation masquent et neutralisent les surfaces système compatibles avec les API publiques retenues.
- [ ] La combinaison initiale des options de présentation est mémorisée puis restaurée exactement à l’arrêt.
- [ ] La saisie de `parent` suivie d’Entrée dans la fenêtre temporelle proposée arrête le prototype.
- [ ] Le maintien simultané des deux touches Majuscule pendant trois secondes arrête le prototype indépendamment du rendu.
- [ ] `Commande-Q` est absorbé et ne constitue pas une sortie active.
- [ ] Une défaillance injectée à chaque étape de préparation déclenche un rollback et ne laisse ni fenêtre de couverture ni option de présentation résiduelle.
- [ ] Le comportement est démontré sur deux écrans lorsque le matériel est disponible, sinon la limitation du matériel de test est explicitement consignée.
