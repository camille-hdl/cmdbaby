# 14: Récupérer après la désactivation du bouclier

**What to build:** Si macOS désactive le filtre pendant une session, BabyWork conserve la couverture visuelle, expose un état de récupération honnête et tente de rétablir immédiatement la protection.

**Blocked by:** 05 — Livrer une première session enfant transactionnelle.

**Status:** ready-for-agent

- [ ] Les notifications de désactivation par délai et par entrée utilisateur sont distinguées et transmises à la façade de session.
- [ ] Une session active passe dans un état explicite de récupération sans fermer automatiquement les fenêtres.
- [ ] Une tentative de réactivation immédiate est effectuée sans boucle non bornée ni attente sur le callback.
- [ ] Le retour effectif du tap ramène la session à l’état actif et non la simple demande de réactivation.
- [ ] Un échec persistant est signalé au parent sans prétendre que le confinement reste complet.
- [ ] Les sorties adultes gardent une voie prioritaire pendant la récupération ou conduisent à un arrêt sûr si la reconnaissance n’est plus possible.
- [ ] Des tests injectent les deux types de désactivation, la réussite et l’échec de réactivation ainsi que les courses avec l’arrêt.
