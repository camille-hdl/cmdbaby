# Sécurité

Ce que CmdBaby protège, contre quoi, où sont les racines de confiance de la distribution, et quoi faire en cas d’incident. Signaler une vulnérabilité : voir `SECURITY.md`.

À relire après #102, #109, #112 et #113 : certaines mesures citées ici ne sont pas encore en place.

## 1. Ce que l’app protège, et ce qu’elle ne protège pas

CmdBaby protège le Mac contre les manipulations **accidentelles** d’un jeune enfant. Ce n’est pas un contrôle parental, ni une protection contre un utilisateur déterminé.

**Ce qui est bloqué** : la liste, à vérifier à la main, est dans `docs/verification-kiosque.md` (#120). En résumé : toute combinaison avec Commande ou Contrôle, les touches de fonction, fn/Globe et les touches système, plus les options de présentation (pas de Dock, de barre des menus, de Cmd-Tab ni de Forcer à quitter). Un chien de garde vérifie toutes les 0,5 s que le filtre tient encore (#118).

**Fail-open** : un plantage de l’app rend le bureau. C’est voulu : l’adulte ne doit jamais rester enfermé.

### Lancement par lien

`cmdbaby://session/start` est une entrée externe, pour Alfred, Raycast, le Terminal (`open`) et toute app qui ouvre une URL. Une page web peut aussi le proposer. La case Réglages › Général « Autoriser le lancement par lien (Alfred, Raycast, Terminal) » est décochée par défaut, y compris quand la clé est absente d’une configuration déjà enregistrée. Tant qu’elle est décochée, le lien est refusé et n’ouvre pas de session.

L’action Raccourcis ne dépend pas de cette case. Un lancement externe, une fois le lien autorisé, passe par les mêmes contrôles (Saisie protégée, phrase tapable), le même confinement et les mêmes sorties adultes. Le lien ne peut pas arrêter une session. Pendant une session, un lien ne montre rien : il est ignoré, et le journal note `session.link.ignored` sans l’URL.

### Impossible à bloquer depuis une app

Ces actions relèvent du matériel ou du système, hors de portée d’un tap clavier ou des options de présentation. CmdBaby ne cherche pas à les contourner :

- bouton d’alimentation et Touch ID, Ctrl-Cmd-Alimentation ;
- fermeture du capot ;
- « Dis Siri » ;
- fenêtres SecurityAgent (demandes de mot de passe du système) ;
- gestes du trackpad gérés par le Dock ;
- coins actifs.

### Fil principal bloqué pendant une session (#118)

Une sortie adulte reconnue par le tap clavier engage tout de suite le kill switch de ce filtre : les frappes ne sont plus filtrées. La suite passe par le fil principal (`Task { @MainActor }`) : restaurer les options de présentation, fermer les couvertures, arrêter le tap.

Si le fil principal ne répond plus, cette suite n’arrive jamais :

- les couvertures restent au niveau économiseur d’écran, sur tous les écrans ;
- les options de présentation restent actives : pas de Dock ni de barre des menus, pas de Cmd-Tab, pas de « Forcer à quitter » (Cmd-Option-Échap) ;
- le clavier n’est plus filtré, mais les frappes vont à CmdBaby, qui ne répond pas.

Le thread du tap ne peut pas restaurer lui-même la présentation : `NSApplication.presentationOptions` ne se modifie que sur le fil principal.

Pour en sortir, il faut terminer le processus de l’extérieur : `ssh` depuis une autre machine puis `killall CmdBaby`, ou un appui long sur le bouton d’alimentation. À la mort du processus, macOS retire ses fenêtres et rétablit ses options de présentation.

Piste non retenue pour l’instant : depuis le thread du tap, terminer le processus (`exit`) si une sortie reconnue n’est pas traitée sous 3 s. Cela rendrait la main à coup sûr, au prix d’une fermeture brutale si le fil principal est seulement lent.

### Secure Event Input (#118)

Quand une autre app active Secure Event Input (champ de mot de passe, Terminal avec « Secure Keyboard Entry »), le tap ne voit plus aucune frappe. CmdBaby refuse de lancer une session dans cet état. Si cela arrive en cours de session, le chien de garde affiche un bandeau pour l’adulte. Il ne peut pas rétablir le filtre : il faut utiliser une sortie adulte, à la souris (cinq clics sur le carré de secours) si le clavier ne répond plus.

### Sorties adulte : limites assumées (#121)

Décision du 2026-10-06. Pour qu’un enfant ne sorte pas par hasard, Maj-Échap n’est reconnu qu’après un appui maintenu de 1,5 s, Maj seul enfoncé, sans retour visuel. Le reste est assumé, sans correctif :

- à la fin du minuteur, la session se ferme et rend le bureau, sans verrou ;
- en mode Terminal, les lettres tapées s’affichent dans le prompt jusqu’à Entrée, phrase de sortie comprise : un enfant plus grand peut la lire ;
- le carré de secours reste visible ; cinq clics en trois secondes suffisent ;
- la phrase par défaut `parent` est publique ; on la change dans les Réglages.

## 2. Données

- **Frappes** : aucune n’est enregistrée, stockée ni envoyée. Aucun journal ne contient de caractère tapé, de keycode, de phrase de sortie ni de progression de phrase ; un test le vérifie sur tous les événements (#122).
- **Réseau** : seulement l’appcast et le téléchargement des mises à jour (#102). Chaque vérification envoie l’adresse IP et un `User-Agent` avec les versions de CmdBaby et de Sparkle.
- **Local**, dans `~/Library/Application Support/CmdBaby/` (dossier en `0700`, #122) :
  - `config.json` en `0600`, phrase de sortie en clair : c’est cohérent avec le modèle, qui ne protège pas contre l’utilisateur du Mac ;
  - un `config.json` illisible est conservé en `config.json.corrupt-…` avant d’être réécrit ;
  - journaux en `0600`, purgés au-delà de 14 jours et de 20 Mo, chemins personnels remplacés par `~`.

## 3. Racines de confiance de la distribution

| Racine | Si elle est compromise | Ce qui protège |
|---|---|---|
| Mac du mainteneur | build et signature d’une version piégée | FileVault, session verrouillée ; build depuis une copie propre du tag (#99) |
| Certificat Developer ID | une app signée au nom de Camille Hodoul | trousseau, sauvegarde `.p12` chiffrée hors ligne (#98). Seul, il ne suffit pas à pousser une mise à jour : il faut aussi la clé EdDSA |
| Clé EdDSA Sparkle | une mise à jour acceptée par Sparkle | trousseau, sauvegarde chiffrée hors ligne (#98). Elle suffit à faire accepter une mise à jour : Sparkle vérifie l’intégrité de la signature Apple, pas son équipe, et accepte même une signature ad hoc. Il faut encore servir l’appcast, donc contrôler Cloudflare ou GitHub (#102) |
| Compte Apple | nouveaux certificats, notarisation | 2FA |
| Compte GitHub | Release ou code modifiés | clé d’accès ou clé de sécurité, Releases immuables, règles sur `main` et les tags `v*` (#109), hook pre-commit contre les secrets (#123), CODEOWNERS et règles pour les agents (#124) |
| Compte Cloudflare | appcast, page de téléchargement, e-mail support | 2FA par clé de sécurité, verrou du registrar, DNSSEC, CAA, DMARC (#112) |
| Dépôt Homebrew | cask pointant vers un autre DMG | `sha256` du DMG dans le cask (#103) |

## 4. Chaîne de publication

```text
commit signé sur main (#109, #123)
  → scripts/release.sh : copie propre du tag, dépendances épinglées, binaire universel (#99)
  → signature Developer ID, hardened runtime, horodatage (#99)
  → notarisation (notarytool) puis agrafage du .app et du DMG (#99)
  → sign_update : signature EdDSA de la mise à jour (#102)
  → scripts/publish.sh : tag signé, Release GitHub immuable, retéléchargement et SHA-256 comparé (#113)
  → appcast signé sur Cloudflare Workers, /download vers le DMG (#111, #113)
  → chez l’utilisateur, Sparkle vérifie la signature EdDSA, l’intégrité de la signature Apple (sans contrôle d’équipe) et l’appcast signé (#102)
```

## 5. Réponse à incident

- **Clé EdDSA compromise** : générer une nouvelle clé et la publier dans une version signée par l’ancienne, selon la procédure de rotation de la documentation Sparkle de la version utilisée (https://sparkle-project.org/documentation/). Détruire ensuite l’ancienne sauvegarde.
- **Certificat Developer ID compromis** : le révoquer sur developer.apple.com, en créer un nouveau, publier une nouvelle version signée.
- **Version piégée publiée** : la retirer de l’appcast et de `/download`, publier une version corrective, prévenir sur le site et par un avis de sécurité GitHub (Security › Advisories). Les Releases étant immuables, la version fautive ne se corrige pas : on publie la suivante.
- **Compte compromis** : changer son mot de passe et ses clés d’accès, révoquer ses sessions et ses jetons, puis selon le compte :
  - GitHub : jetons `gh`, clés SSH et de signature, secrets d’Actions ;
  - Cloudflare : jeton de `wrangler login` (le révoquer, puis refaire `wrangler login`), jetons d’API ;
  - Apple : mot de passe d’app du profil `notarytool`, certificats ;
  - e-mail : règles de transfert d’Email Routing.

## 6. Vérifier un téléchargement

```sh
spctl -a -vv /Applications/CmdBaby.app
```

doit afficher `source=Notarized Developer ID` et `origin=Developer ID Application: CAMILLE PAULIN HODOUL (2B8R2FVJP6)`. Le Team ID, public, est `2B8R2FVJP6` ; les scripts le lisent dans `scripts/release.env` (`RELEASE_TEAM_ID`, #98, #99).

```sh
shasum -a 256 ~/Downloads/CmdBaby-<version>.dmg
```

doit donner la somme publiée avec la Release GitHub.
