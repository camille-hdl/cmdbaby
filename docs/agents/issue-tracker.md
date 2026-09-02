# Suivi des demandes : fichiers Markdown locaux

Les demandes et les spécifications de ce dépôt sont enregistrées dans des fichiers Markdown sous `.scratch/`.

## Conventions

- Un répertoire par fonctionnalité : `.scratch/<feature-slug>/`
- La spécification se trouve dans `.scratch/<feature-slug>/spec.md`.
- Chaque ticket d’implémentation possède son propre fichier dans `.scratch/<feature-slug>/issues/<NN>-<slug>.md`. La numérotation commence à `01` ; ne jamais regrouper tous les tickets dans un seul fichier.
- Les commentaires et l’historique des échanges sont ajoutés à la fin du fichier, sous un titre `## Commentaires`.

## Lorsqu’un skill demande de publier dans le suivi des demandes

Créer un fichier sous `.scratch/<feature-slug>/`, ainsi que le répertoire si nécessaire.

## Lorsqu’un skill demande de récupérer le ticket concerné

Lire le fichier au chemin indiqué. L’utilisateur fournira normalement directement le chemin ou le numéro du ticket.

## Opérations de navigation

Utilisées par `/wayfinder`. La **carte** est un fichier associé à un fichier **enfant** par ticket.

- **Carte** : `.scratch/<effort>/map.md` (corps contenant les notes, les décisions prises et les zones d’incertitude).
- **Ticket enfant** : `.scratch/<effort>/issues/NN-<slug>.md`, numéroté à partir de `01`, avec la question dans le corps. Une ligne `Type:` indique le type du ticket (`research`/`prototype`/`grilling`/`task`) ; une ligne `Status:` indique `claimed` ou `resolved`.
- **Blocage** : une ligne `Blocked by: NN, NN` placée près du début. Un ticket est débloqué lorsque tous les fichiers indiqués ont le statut `resolved`.
- **Frontière** : parcourir `.scratch/<effort>/issues/` à la recherche des fichiers ouverts, non bloqués et non attribués ; le premier numéro l’emporte.
- **Attribution** : définir `Status: claimed` et enregistrer avant de commencer le travail.
- **Résolution** : ajouter la réponse sous un titre `## Réponse`, définir `Status: resolved`, puis ajouter dans la partie consacrée aux décisions de `map.md` un pointeur vers le contexte (résumé et lien).
