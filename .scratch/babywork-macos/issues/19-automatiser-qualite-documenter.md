# 19: Automatiser la qualité et documenter les décisions

**What to build:** Chaque changement de BabyWork peut être compilé, formaté, testé et compris de manière reproductible, avec une documentation des composants pédagogiques et des compromis sensibles.

**Blocked by:** 17 — Finaliser le parcours parent accessible; 18 — Durcir l’expérience sous charge.

**Status:** ready-for-agent

- [ ] L’intégration continue s’exécute sur macOS et construit les configurations Debug et Release en concurrence stricte Swift 6.
- [ ] Le formatage est vérifié par une commande reproductible avec une version d’outil maîtrisée.
- [ ] Les suites Swift Testing, XCTest et XCUITest applicables s’exécutent automatiquement et distinguent clairement les essais nécessitant un environnement physique.
- [ ] Des exécutions périodiques avec Address Sanitizer et Thread Sanitizer sont définies et leurs résultats restent consultables.
- [ ] Les composants pédagogiques et leurs contrats publics disposent d’une documentation DocC utile.
- [ ] Les décisions de sandbox, permissions, présentation, récupération et confidentialité sont couvertes par des ADR courtes et cohérentes.
- [ ] Un modèle de menace décrit le jeune enfant visé, les limites hors contrôle de l’application et les mesures complémentaires recommandées.
- [ ] La stratégie de journaux garantit qu’aucune frappe, séquence adulte, image ou chemin privé complet n’est collecté.
