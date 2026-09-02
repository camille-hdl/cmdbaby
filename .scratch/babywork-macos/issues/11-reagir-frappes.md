# 11: Réagir visuellement aux frappes

**What to build:** Lorsqu’un enfant appuie sur une touche, une lettre ou un emoji lisible apparaît rapidement sur l’écran pertinent tout en empêchant la frappe d’atteindre les autres applications.

**Blocked by:** 09 — Afficher le fond sur tous les écrans.

**Status:** ready-for-agent

- [ ] Les pressions, relâchements et changements de modificateurs utiles traversent une représentation légère entre le tap et la session.
- [ ] La lettre affichée respecte la disposition clavier active, notamment AZERTY, sans table QWERTY codée en dur.
- [ ] La frappe est routée vers l’écran contenant le pointeur au moment pertinent.
- [ ] L’écran principal sert de repli lorsqu’aucun écran ne peut être déterminé.
- [ ] La réaction utilise les polices système ou Apple Color Emoji et reste lisible sur les différentes tailles d’écran.
- [ ] Les nœuds visuels expirent après une durée bornée et ne s’accumulent pas pendant une longue séquence de frappes.
- [ ] Les tests couvrent plusieurs dispositions, les modificateurs, les événements sans localisation et le routage multi-écrans par comportement observable.
