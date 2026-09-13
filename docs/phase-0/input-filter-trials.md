# Essais de filtrage actif — phase 0

Journal factuel pour le ticket 02. Ne consigner **aucun** caractère saisi, ni séquence adulte, ni chemin privé.

## Environnement

- Date : 11 septembre 2026
- macOS : 26.6.2 (25G83), clavier AZERTY
- Build diagnostique : Bundle ID `fr.camille.babywork.diagnostics`, emplacement `/Applications/BabyWorkDiagnostics.app`
- Identité de signature : Apple Development (Personal Team)
- Variante sandbox : [x] désactivée [x] activée — tap **Actif**, même code, bundle `fr.camille.babywork.diagnostics.sandbox`
- Surveillance de l’entrée : [x] accordée
- Accessibilité : [x] accordée
- Alfred installé : [x] oui — Alfred 5 (`/Applications/Alfred 5.app`) ; raccourci principal non lu automatiquement

## Procédure

1. Construire et ouvrir le bundle signé :

```sh
BABYWORK_CODE_SIGN_IDENTITY="$(security find-identity -v -p codesigning | sed -n 's/.*"\(Apple Development:.*\)".*/\1/p' | head -1)" \
  BABYWORK_APP_SANDBOX=0 \
  ./scripts/build-diagnostics-app.sh
open /Applications/BabyWorkDiagnostics.app
```

2. Accorder Accessibilité (le tap actif n’a pas besoin du panneau Surveillance de l’entrée), puis **Quitter et relancer**.
3. Activer le filtre. L’état doit passer à **Actif**.
4. Pour chaque raccourci, tenter la combinaison et noter le compteur UI + l’effet système observé.
5. Reproduire avec `BABYWORK_APP_SANDBOX=1` (bundle `/Applications/BabyWorkDiagnostics-sandbox.app`).

## Matrice des raccourcis

### Premier essai (politique QWERTY)

Compteurs à 0 pour Commande-Q, Commande-M, Contrôle-↓, Contrôle-Commande-Q (AZERTY + code flèche bas erroné). Les autres raccourcis étaient déjà absorbés.

### Second essai — 11 septembre 2026, sans sandbox

Après correction AZERTY (cache de disposition hors du callback) et `kVK_DownArrow = 0x7D`. Filtre activé puis désactivé. Tous les raccourcis de la matrice ont un compteur ≥ 1.

| Raccourci | Compteur UI | Effet système (sans sandbox) | Effet système (sandbox) |
|---|---|---|---|
| Commande-Espace | 3 | absorbé | absorbé — Spotlight ne s’est pas affiché |
| Commande-Tab | 2 | absorbé | non testé |
| Commande-Q | 1 | absorbé | non testé |
| Commande-H | 1 | absorbé | non testé |
| Commande-M | 1 | absorbé | non testé |
| Option-Commande-Échap | 1 | absorbé | non testé |
| Contrôle-↑ | 1 | absorbé | non testé |
| Contrôle-↓ | 1 | absorbé | non testé |
| Contrôle-Commande-Q | 1 | absorbé | non testé |

Légende effet système : `absorbé` / `partiel` / `passe` / `non classé` / `non testé`.

Un crash `EXC_BREAKPOINT` (`dispatch_assert_queue`) s’est produit au premier Cmd-Espace après l’ajout de `TISCopyCurrentKeyboardLayoutInputSource` dans le callback. Corrigé en précalculant la table de lettres sur le thread principal.

## Spotlight, Alfred, raccourcis tiers

| Source | Sans sandbox | Avec sandbox | Notes |
|---|---|---|---|
| Spotlight (Cmd-Espace) | absorbé — Spotlight ne s’est pas affiché | absorbé — Spotlight ne s’est pas affiché | |
| Alfred (Option-Espace) | — | absorbé — Alfred ne s’ouvre pas | compteur Option-Espace après ajout de la règle |
| Autre raccourci tiers | non testé | non testé | |

## Désactivation du tap

| Événement | Observé | Réactivation OK |
|---|---|---|
| `tapDisabledByTimeout` | non testé | |
| `tapDisabledByUserInput` | non testé | |

## Confidentialité

Les compteurs n’exposent que le nom du raccourci classé. Aucune frappe n’est persistée.

## Conclusion provisoire

- Tap de session actif sans `root` : [x] oui
- Thread dédié + callback borné : [x] oui (revu dans le code)
- App Sandbox viable pour le tap actif : [x] oui (macOS 26.6.2, Personal Team, Hardened Runtime)
- Suite proposée : ticket 03 (confinement multi-écrans et sorties adultes)
