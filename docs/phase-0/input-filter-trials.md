# Essais de filtrage actif — phase 0

Journal factuel pour le ticket 02. Ne consigner **aucun** caractère saisi, ni séquence adulte, ni chemin privé.

## Environnement

- Date :
- macOS :
- Build diagnostique : Bundle ID `fr.camille.babywork.diagnostics`
- Identité de signature : Apple Development (Personal Team)
- Variante sandbox : [ ] désactivée [ ] activée
- Surveillance de l’entrée : [ ] accordée [ ] refusée
- Accessibilité : [ ] accordée [ ] refusée
- Alfred installé : [ ] oui [ ] non

## Procédure

1. Construire et ouvrir le bundle signé :

```sh
BABYWORK_CODE_SIGN_IDENTITY="$(security find-identity -v -p codesigning | sed -n 's/.*"\(Apple Development:.*\)".*/\1/p' | head -1)" \
  BABYWORK_APP_SANDBOX=0 \
  ./scripts/build-diagnostics-app.sh
open .build/app/BabyWorkDiagnostics.app
```

2. Accorder les permissions demandées, puis actualiser l’UI.
3. Activer le filtre. L’état doit passer à **Actif**.
4. Pour chaque raccourci, tenter la combinaison hors de l’application et noter le compteur UI + l’effet système observé.
5. Reproduire avec `BABYWORK_APP_SANDBOX=1` et `BABYWORK_APP_OUTPUT_DIR=.build/app-sandbox`.

## Matrice des raccourcis

| Raccourci | Compteur UI > 0 | Effet système (sans sandbox) | Effet système (sandbox) |
|---|---|---|---|
| Commande-Espace | | | |
| Commande-Tab | | | |
| Commande-Q | | | |
| Commande-H | | | |
| Commande-M | | | |
| Option-Commande-Échap | | | |
| Contrôle-↑ | | | |
| Contrôle-↓ | | | |
| Contrôle-Commande-Q | | | |

Légende effet système : `absorbé` / `partiel` / `passe` / `non testé`.

## Spotlight, Alfred, raccourcis tiers

| Source | Sans sandbox | Avec sandbox | Notes |
|---|---|---|---|
| Spotlight (Cmd-Espace) | | | |
| Alfred (si présent) | | | |
| Autre raccourci tiers | | | |

## Désactivation du tap

| Événement | Observé | Réactivation OK |
|---|---|---|
| `tapDisabledByTimeout` | | |
| `tapDisabledByUserInput` | | |

## Confidentialité

Vérifier qu’aucun journal unifié (`log stream --predicate 'subsystem == "fr.camille.babywork.diagnostics"'`) ne contient de caractère saisi pendant les essais.

## Conclusion provisoire

- Tap de session actif sans `root` : [ ] oui [ ] non
- Thread dédié + callback borné : [ ] oui [ ] non (revu dans le code)
- App Sandbox viable pour le tap actif : [ ] oui [ ] non [ ] non testé
- Suite proposée : [ ] poursuivre ticket 03 [ ] ADR sandbox requise [ ] blocage
