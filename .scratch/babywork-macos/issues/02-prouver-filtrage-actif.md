# 02: Prouver le filtrage actif des entrées

**What to build:** Le prototype permet d’activer un filtre d’événements de session, d’observer son état et de démontrer factuellement que les principaux raccourcis clavier n’atteignent plus macOS ou les autres applications.

**Blocked by:** 01 — Inventorier le Mac cible dans une application signée.

**Status:** ready-for-agent

- [ ] Le prototype crée un `CGEventTap` actif au niveau de la session sans exécution en `root`.
- [ ] Le tap s’exécute sur un thread dédié avec une boucle Core Foundation et un callback borné qui ne réalise ni rendu ni accès disque.
- [ ] L’utilisateur peut activer puis désactiver le filtre depuis l’interface diagnostique et voir son état réel.
- [ ] Le prototype reconnaît les notifications de désactivation par dépassement de délai ou intervention de l’utilisateur.
- [ ] La suppression de `Commande-Espace`, `Commande-Tab`, `Commande-Q`, `Commande-H`, `Commande-M`, `Option-Commande-Échap`, `Contrôle-↑`, `Contrôle-↓` et `Contrôle-Commande-Q` est testée et consignée.
- [ ] Le comportement de Spotlight, Alfred et des raccourcis tiers configurés est consigné sur le Mac cible.
- [ ] Les essais sont reproduits avec App Sandbox activé puis, seulement si nécessaire, désactivé.
- [ ] Les frappes et séquences saisies ne sont jamais persistées ni écrites dans les journaux.
