# 05: Livrer une première session enfant transactionnelle

**What to build:** Depuis l’interface parent, une première session de production couvre l’écran principal, active réellement le bouclier d’entrée, offre la sortie adulte principale et restaure toujours l’environnement après arrêt ou échec.

**Blocked by:** 04 — Conclure la phase 0 et décider de poursuivre.

**Status:** ready-for-agent

- [ ] Une action parent démarre une session minimale avec un fond uni sur l’écran principal.
- [ ] La session traverse des états explicites de vérification, préparation, activation, activité, arrêt et échec.
- [ ] L’état actif n’est atteint qu’après confirmation de la fenêtre, du bouclier d’entrée, de la sortie adulte et de la restauration possible.
- [ ] `parent` suivi d’Entrée dans la durée retenue arrête la session; erreur, expiration et succès réinitialisent le tampon.
- [ ] Toute défaillance de préparation effectue un rollback en ordre inverse et rend à nouveau l’interface parent utilisable.
- [ ] La façade de session accepte des dépendances injectées et se teste par comportements observables, sans inspection de ses détails privés.
- [ ] Le projet compile en concurrence stricte Swift 6, applique un formatage reproductible et dispose d’une première vérification continue du build et des tests.
- [ ] Les erreurs sont typées et les journaux ne contiennent ni frappes, ni séquence adulte, ni donnée privée.
