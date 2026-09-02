# Documentation métier

Ce document indique comment les skills d’ingénierie doivent consulter la documentation métier du dépôt avant d’explorer le code.

## À lire avant toute exploration

- **`CONTEXT.md`** à la racine du dépôt ; ou
- **`CONTEXT-MAP.md`** à la racine, s’il existe : il renvoie vers un fichier `CONTEXT.md` par contexte. Lire chaque fichier pertinent pour le sujet traité.
- **`docs/adr/`** : lire les ADR qui concernent la zone sur laquelle le travail va porter. Dans un dépôt multi-contexte, consulter également `src/<context>/docs/adr/` pour les décisions propres au contexte.

Si certains de ces fichiers n’existent pas, **poursuivre silencieusement**. Ne pas signaler leur absence et ne pas proposer de les créer à l’avance. Le skill `/domain-modeling` — appelé via `/grill-with-docs` et `/improve-codebase-architecture` — les crée progressivement lorsque des termes ou des décisions sont effectivement établis.

## Organisation des fichiers

Dépôt à contexte unique, comme la plupart des dépôts :

```text
/
├── CONTEXT.md
├── docs/adr/
│   ├── 0001-event-sourced-orders.md
│   └── 0002-postgres-for-write-model.md
└── src/
```

Dépôt multi-contexte, signalé par la présence de `CONTEXT-MAP.md` à la racine :

```text
/
├── CONTEXT-MAP.md
├── docs/adr/                          ← décisions concernant tout le système
└── src/
    ├── ordering/
    │   ├── CONTEXT.md
    │   └── docs/adr/                  ← décisions propres au contexte
    └── billing/
        ├── CONTEXT.md
        └── docs/adr/
```

## Employer le vocabulaire du glossaire

Lorsqu’un résultat nomme un concept métier — dans le titre d’un ticket, une proposition de refactorisation, une hypothèse ou le nom d’un test — employer le terme défini dans `CONTEXT.md`. Ne pas dériver vers des synonymes que le glossaire écarte explicitement.

Si le concept nécessaire ne figure pas encore dans le glossaire, cela constitue un signal : soit le terme ne correspond pas au langage du projet et doit être reconsidéré, soit il existe une véritable lacune à noter pour `/domain-modeling`.

## Signaler les conflits avec les ADR

Lorsqu’un résultat contredit un ADR existant, le signaler explicitement au lieu de le remplacer silencieusement :

> _Contredit l’ADR-0007 (commandes basées sur des événements), mais mérite d’être réexaminé parce que…_
