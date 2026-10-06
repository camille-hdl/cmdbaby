## Langue de travail

Utiliser le français par défaut pour les échanges, la documentation, les spécifications, les tickets, les plans et tout autre contenu destiné à être lu par une personne.

Conserver dans leur langue d’origine les identifiants de code, commandes, chemins, noms d’API, valeurs de protocole et citations. Employer une autre langue lorsque l’utilisateur le demande explicitement ou lorsque le format externe l’impose.

## Skills obligatoires

- **Changement d’architecture** (nouveau module, déplacement d’une frontière entre modules, refonte d’une interface) : appliquer `/codebase-design` avant d’écrire le code.
- **Modification de code ponctuelle** : suivre `/tactical-programming`.
- **Travail découpé en tickets** : implémenter chaque ticket avec `/implement` (qui passe par `/tdd`), en suivant aussi `/tactical-programming`.
- **Description de pull request** : la rédiger avec `/pull-request-description`.

## Agent skills

### Issue tracker

Les demandes sont suivies dans les issues GitHub de `camille-hdl/cmdbaby`, via la CLI `gh`. Voir `docs/agents/issue-tracker.md`.

### Triage labels

Les cinq labels canoniques sont utilisés tels quels : `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. Voir `docs/agents/triage-labels.md`.

### Domain docs

Ce dépôt utilise une organisation « single-context » pour sa documentation métier. Voir `docs/agents/domain.md`.
