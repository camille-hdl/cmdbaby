# 02: Prouver le filtrage actif des entrées

**What to build:** Le prototype permet d’activer un filtre d’événements de session, d’observer son état et de démontrer factuellement que les principaux raccourcis clavier n’atteignent plus macOS ou les autres applications.

**Blocked by:** 01 — Inventorier le Mac cible dans une application signée.

**Status:** claimed

- [x] Le prototype crée un `CGEventTap` actif au niveau de la session sans exécution en `root`.
- [x] Le tap s’exécute sur un thread dédié avec une boucle Core Foundation et un callback borné qui ne réalise ni rendu ni accès disque.
- [x] L’utilisateur peut activer puis désactiver le filtre depuis l’interface diagnostique et voir son état réel.
- [x] Le prototype reconnaît les notifications de désactivation par dépassement de délai ou intervention de l’utilisateur.
- [ ] La suppression de `Commande-Espace`, `Commande-Tab`, `Commande-Q`, `Commande-H`, `Commande-M`, `Option-Commande-Échap`, `Contrôle-↑`, `Contrôle-↓` et `Contrôle-Commande-Q` est testée et consignée.
- [ ] Le comportement de Spotlight, Alfred et des raccourcis tiers configurés est consigné sur le Mac cible.
- [ ] Les essais sont reproduits avec App Sandbox activé puis, seulement si nécessaire, désactivé.
- [x] Les frappes et séquences saisies ne sont jamais persistées ni écrites dans les journaux.

## Commentaires

### 11 septembre 2026 — Prototype de filtre livré, essais manuels en attente

Ajouts :

- `ShortcutSuppressionPolicy` et compteurs dans `BabyWorkDiagnosticsKit`, couverts par Swift Testing ;
- `SessionInputFilter` : tap `cgSessionEventTap` / `defaultTap`, thread dédié, boucle CF, gestion `tapDisabledByTimeout` et `tapDisabledByUserInput`, aucune journalisation de frappe ;
- panneau UI pour activer/désactiver, demander les permissions et afficher l’état + compteurs par raccourci ;
- script de build avec `BABYWORK_APP_SANDBOX=0|1` et entitlements associés ;
- grille manuelle : `docs/phase-0/input-filter-trials.md`.

Les cases restantes exigent une exécution interactive sur le Mac cible (permissions TCC + matrice de raccourcis, avec et sans sandbox). L’application signée sans sandbox a été ouverte pour ces essais.
