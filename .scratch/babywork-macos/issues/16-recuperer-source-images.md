# 16: Récupérer après la perte du dossier d’images

**What to build:** Si la source d’images disparaît ou devient invalide, BabyWork conserve un état visuel sûr, explique le problème au parent et permet de choisir une nouvelle source.

**Blocked by:** 08 — Conserver le dossier et les réglages; 09 — Afficher le fond sur tous les écrans.

**Status:** ready-for-agent

- [ ] Un dossier déplacé, supprimé ou situé sur un disque retiré est détecté sans accès non borné ni blocage du thread principal.
- [ ] Une image supprimée, corrompue, excessivement grande ou modifiée pendant sa lecture ne remplace pas un fond valide par un contenu partiel.
- [ ] Pendant une session active, la perte de la source conserve l’image déjà préparée ou utilise un repli sûr documenté.
- [ ] Dans l’interface parent, une source invalide affiche une cause et permet une nouvelle sélection.
- [ ] La nouvelle sélection remplace proprement l’ancien bookmark et équilibre les accès à portée de sécurité.
- [ ] Les journaux ne contiennent pas le chemin privé complet du dossier ou des images.
- [ ] Des tests à base de fixtures couvrent les sources absentes, périmées, illisibles, corrompues et modifiées en cours de lecture.
