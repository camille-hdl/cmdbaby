# 02: Prouver le filtrage actif des entrées

**What to build:** Le prototype permet d’activer un filtre d’événements de session, d’observer son état et de démontrer factuellement que les principaux raccourcis clavier n’atteignent plus macOS ou les autres applications.

**Blocked by:** 01 — Inventorier le Mac cible dans une application signée.

**Status:** resolved

- [x] Le prototype crée un `CGEventTap` actif au niveau de la session sans exécution en `root`.
- [x] Le tap s’exécute sur un thread dédié avec une boucle Core Foundation et un callback borné qui ne réalise ni rendu ni accès disque.
- [x] L’utilisateur peut activer puis désactiver le filtre depuis l’interface diagnostique et voir son état réel.
- [x] Le prototype reconnaît les notifications de désactivation par dépassement de délai ou intervention de l’utilisateur.
- [x] La suppression de `Commande-Espace`, `Commande-Tab`, `Commande-Q`, `Commande-H`, `Commande-M`, `Option-Commande-Échap`, `Contrôle-↑`, `Contrôle-↓` et `Contrôle-Commande-Q` est testée et consignée.
- [x] Le comportement de Spotlight, Alfred et des raccourcis tiers configurés est consigné sur le Mac cible.
- [x] Les essais sont reproduits avec App Sandbox activé puis, seulement si nécessaire, désactivé.
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

### 11 septembre 2026 — Premier essai manuel sans sandbox

Filtre **Actif** après Accessibilité accordée et relance. Compteurs : Espace 3, Tab 2, Q 0, H 4, M 0, Option-Commande-Échap 1, Contrôle-↑ 2, Contrôle-↓ 0, Contrôle-Commande-Q 0.

Causes des zéros, distinctes d’un tap inactif :

- Contrôle-↓ : `kVK_DownArrow` était `0x7F` au lieu de `0x7D` ;
- Commande-Q / Commande-M / Contrôle-Commande-Q : comparaison sur les positions ANSI QWERTY, inadaptée à l’AZERTY du Mac cible.

Correction : lettre selon la disposition active pour Q/H/M, code flèche bas corrigé. Retest manuel et essai sandbox encore dus. Spotlight/Alfred non distingués au-delà du compteur Commande-Espace.

### 11 septembre 2026 — Second essai sans sandbox : matrice complète absorbée

Après le crash TIS-sur-thread-tap (corrigé par cache de disposition sur le thread principal), retest : tous les raccourcis ont un compteur ≥ 1 (Espace 3, Tab 2, les autres 1). **Spotlight ne s’est pas affiché** sur Commande-Espace. Filtre ensuite désactivé proprement.

### 11 septembre 2026 — Sandbox : tap actif viable ; Alfred en Option-Espace passe

Variante `BabyWorkDiagnostics-sandbox.app` (App Sandbox, autre bundle ID). Filtre **Actif**. Commande-Espace : Spotlight ne s’affiche pas. **Option-Espace ouvre encore Alfred** : la politique n’absorbait que Commande-Espace.

### 11 septembre 2026 — Option-Espace absorbe Alfred ; ticket clos

Après ajout de la règle Option-Espace : compteur en hausse, Alfred ne s’ouvre pas (essai sandbox). Spotlight reste absorbé. Le tap actif est viable avec App Sandbox sur le Mac cible. Ticket 02 résolu.

## Réponse

Prototype de `CGEventTap` de session démontré sans `root`, avec et sans App Sandbox. Matrice des raccourcis absorbée sur AZERTY, y compris Spotlight (Commande-Espace) et Alfred (Option-Espace). Les frappes ne sont pas journalisées. Suite : ticket 03.



