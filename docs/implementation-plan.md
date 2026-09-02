# BabyWork — plan d’implémentation validé et document de reprise

## Statut du document

- **Date de validation :** 2 septembre 2026
- **État :** plan validé par l’utilisateur ; implémentation non commencée
- **Prochaine action autorisée :** commencer exclusivement par la phase 0 de faisabilité décrite ci-dessous
- **État du dépôt au passage de relais :** aucun projet Xcode, aucun fichier source et aucun test applicatif n’ont été créés ; seuls les documents d’étude et de planification existent
- **Étude technique associée :** [Application macOS « clavier pour bébé » : faisabilité et options](research/macos-toddler-app-options.md)

Ce document doit permettre à une nouvelle session d’agent de reprendre le projet sans dépendre de l’historique de conversation. Avant d’agir, cette nouvelle session doit lire intégralement ce document et l’étude technique associée.

## 1. Contexte produit

L’application est destinée en premier lieu à l’usage personnel du propriétaire d’un Mac. Elle doit permettre à un enfant de deux ans de taper sur le clavier et de manipuler la souris sans déclencher accidentellement Spotlight, Alfred, un changement d’application ou une action dans un autre logiciel.

Pendant une session enfant, l’ordinateur doit réagir de manière ludique :

- affichage de grandes lettres ou d’emojis lors des frappes ;
- animation à l’endroit d’un clic ;
- fond visuel choisi par un adulte parmi les images d’un dossier ;
- occupation de tous les écrans connectés au Mac.

Le produit cible macOS uniquement. La distribution publique ou le Mac App Store ne sont pas des objectifs initiaux. Cela ne dispense pas le projet d’une intégration macOS propre, d’une signature stable, d’une gestion stricte des permissions et d’un niveau de qualité proche d’un logiciel distribuable.

## 2. Limite de sécurité à communiquer honnêtement

Le produit est un **confinement anti-bêtises très robuste pour un jeune enfant**, et non une frontière de sécurité inviolable contre un utilisateur déterminé.

Une application macOS ordinaire peut masquer l’interface système, couvrir tous les écrans et supprimer la plupart des événements clavier et souris ordinaires. Elle ne peut toutefois pas promettre de neutraliser :

- le bouton d’alimentation ou Touch ID ;
- toutes les voies matérielles ou de sécurité futures de macOS ;
- tous les gestes système du trackpad ;
- une révocation de permission, un crash ou une défaillance du système d’exploitation.

Un compte macOS standard dédié à l’enfant est recommandé comme protection complémentaire, mais ne fait pas partie du périmètre applicatif initial. Le véritable mode mono-application administré par MDM est jugé disproportionné pour cet usage personnel.

## 3. Décisions validées

Les choix suivants ont été explicitement validés par l’utilisateur :

1. **Architecture native Swift/AppKit.**
2. **AppKit** pilote le cycle de vie, les fenêtres, les écrans, le mode de présentation et l’interception système.
3. **SwiftUI** sert à l’interface normale destinée aux parents.
4. **SpriteKit** assure le rendu animé du mode enfant.
5. **ImageIO** charge, valide et sous-échantillonne les fonds d’écran.
6. Le parent sélectionne explicitement une image dans une galerie alimentée par un dossier.
7. La même image est utilisée sur tous les écrans, avec un rendu proportionnel de type *aspect fill* sans déformation.
8. Une frappe apparaît sur l’écran qui contient le pointeur ; l’écran principal sert de repli si cette information n’est pas disponible.
9. Un clic produit une animation à sa position sur l’écran concerné.
10. La sortie adulte principale est la saisie de `parent`, suivie d’Entrée, dans une fenêtre temporelle limitée.
11. La sortie de secours consiste à maintenir simultanément les deux touches Majuscule pendant trois secondes.
12. `Commande-Q` est absorbé et n’est pas une sortie activée par défaut.
13. La première étape d’implémentation doit être une phase de faisabilité courte et mesurable, avant toute construction du produit complet.

Les sons, une sélection aléatoire du fond et des thèmes graphiques avancés sont des extensions possibles, mais ne font pas partie du premier périmètre validé.

## 4. Principes d’ingénierie

Le projet a une double vocation : produire un outil réellement utilisable et servir de démonstration pédagogique de Swift et des API macOS. Le code doit donc privilégier la clarté sans sacrifier la solidité.

Principes obligatoires :

- mode de concurrence stricte de Swift 6 ;
- séparation nette entre domaine, intégration système et rendu ;
- injection des dépendances par les initialiseurs ;
- aucun singleton métier ;
- aucune exécution en `root` ;
- principe du moindre privilège ;
- aucun `try!` ;
- aucun *force unwrap* hors invariant démontré et documenté ;
- erreurs Swift typées et messages récupérables destinés au parent ;
- aucune frappe ni séquence adulte écrite dans les journaux ;
- aucune télémétrie et aucun accès réseau ;
- nombre de tâches, d’événements, d’images en mémoire et de nœuds SpriteKit borné ;
- dépendances tierces évitées tant qu’un framework Apple convient ;
- tests conçus en même temps que les composants, pas ajoutés après coup ;
- décisions sensibles documentées dans de courtes ADR (*Architecture Decision Records*).

## 5. Architecture cible

### 5.1 Flux principal

```text
Clavier / souris
       │
       ▼
CGEventTap actif ────────► événement supprimé du flux macOS
       │
       ▼
File d’entrée bornée
       ├──► AdultExitRecognizer
       └──► ChildSessionController (@MainActor)
                    │
                    ▼
                SceneRouter
          ┌─────────┼─────────┐
          ▼         ▼         ▼
      Écran 1   Écran 2   Écran 3
      SKScene   SKScene   SKScene

Dossier choisi par le parent
       │
       ▼
WallpaperRepository ──► ImageIO ──► images adaptées aux écrans
```

### 5.2 Composants envisagés

- `AppCoordinator` : composition des services et cycle de vie global.
- `ChildSessionController` : machine à états transactionnelle du mode enfant.
- `PermissionController` : pré-vérification et présentation guidée des permissions macOS.
- `InputShield` : création, activation, surveillance et retrait du `CGEventTap`.
- `InputPump` : transfert borné et regroupement des événements fréquents.
- `AdultExitRecognizer` : sorties normale et de secours, sans dépendance au rendu.
- `KioskPresentationController` : application et restauration des `NSApplication.PresentationOptions`.
- `DisplayCoordinator` : inventaire des écrans et gestion d’une fenêtre par écran.
- `WallpaperRepository` : bookmark, catalogue, validation, miniatures et images finales.
- `SceneRouter` : routage des interactions vers la scène de l’écran pertinent.
- `SettingsStore` : préférences `Codable` versionnées et migrations.
- `DiagnosticsController` : état lisible des permissions et composants critiques, sans données sensibles.

Les noms sont indicatifs ; ils peuvent évoluer si la phase 0 démontre une meilleure séparation. Les responsabilités, elles, doivent rester explicites.

## 6. Machine à états et activation transactionnelle

États de session proposés :

```text
configuration
     │
     ▼
checkingPermissions
     │
     ▼
preparing ───────────► failed + rollback
     │
     ▼
activating
     │
     ▼
active ──────────────► recoveringInputShield
     │
     ▼
stopping
     │
     ▼
configuration
```

Le mode enfant ne doit jamais être lancé partiellement. Avant `active`, le contrôleur doit confirmer :

1. la disponibilité d’un fond valide ;
2. la création d’une fenêtre préparée pour chaque écran ;
3. l’obtention des permissions nécessaires ;
4. la création effective du filtre système ;
5. le fonctionnement des sorties adultes ;
6. la possibilité de restaurer l’état AppKit antérieur.

Toute erreur déclenche un rollback ordonné. Les options de présentation initiales doivent être mémorisées puis restaurées, jamais remplacées par une valeur supposée par défaut.

## 7. Entrées et confinement

Le mécanisme public approprié est un `CGEventTap` actif au niveau de la session. Le point d’entrée HID exigeant les droits `root` est exclu.

Le tap doit fonctionner sur un thread dédié avec sa propre boucle Core Foundation. Son callback doit uniquement :

1. reconnaître les événements de désactivation du tap ;
2. extraire une représentation légère de l’entrée ;
3. la déposer dans une structure bornée ;
4. décider si l’événement est supprimé ou transmis ;
5. rendre immédiatement la main.

Sont interdits dans le callback : chargement d’image, accès disque, attente de verrou longue, rendu, journalisation détaillée et création d’une tâche Swift par mouvement de souris.

À prendre en charge au minimum :

- `keyDown` et `keyUp` ;
- changements de modificateurs ;
- boutons principaux et supplémentaires de la souris ;
- mouvements et glissements ;
- molette ;
- notifications `tapDisabledByTimeout` et `tapDisabledByUserInput`.

Les mouvements très fréquents doivent être regroupés avant le rendu. Les événements clavier doivent être résolus selon la disposition active, notamment AZERTY, sans table QWERTY codée en dur.

Si le tap devient indisponible pendant une session, l’application conserve ses fenêtres et sa présentation, tente une réactivation immédiate et passe dans un état explicite de récupération. Elle ne doit ni prétendre que la protection est toujours complète, ni révéler automatiquement le bureau à l’enfant.

## 8. Sorties adultes

### 8.1 Sortie normale

- Reconnaître `parent` puis Entrée.
- Utiliser une fenêtre temporelle à déterminer précisément pendant la phase 0 ; cinq secondes constituent la valeur initiale proposée.
- Réinitialiser le tampon après expiration, erreur ou succès.
- Ne jamais journaliser ni persister ce tampon.

### 8.2 Sortie de secours

- Reconnaître les deux touches Majuscule maintenues simultanément pendant trois secondes.
- Effectuer la reconnaissance hors de SpriteKit et indépendamment du thread principal autant que possible.
- Tester les faux positifs, les relâchements intermittents et la répétition matérielle.

### 8.3 Ordre de désactivation

Après une sortie valide :

1. entrer dans l’état `stopping` afin d’empêcher toute réactivation concurrente ;
2. retirer ou neutraliser proprement le filtre ;
3. restaurer les options de présentation et le curseur ;
4. fermer les fenêtres de couverture ;
5. revenir à l’interface adulte ou quitter selon l’action demandée.

## 9. Multi-écrans

Créer une fenêtre sans bordure par `NSScreen`, jamais une seule fenêtre géante.

Le `DisplayCoordinator` doit gérer :

- coordonnées négatives ;
- facteurs d’échelle Retina différents ;
- écrans en miroir ;
- branchement et retrait à chaud ;
- changement de résolution ou d’orientation ;
- Spaces séparés ou communs ;
- Stage Manager ;
- veille et réveil.

La liste `NSScreen.screens` ne doit pas être mise en cache. Les fenêtres doivent être réconciliées après `NSApplication.didChangeScreenParametersNotification`.

Un écran doit être identifié par un identifiant stable lorsque macOS en expose un, et non par son indice dans le tableau. Les transformations entre coordonnées globales AppKit, coordonnées de fenêtre et coordonnées SpriteKit doivent être isolées et testées.

L’utilisation de `CGCaptureAllDisplays` n’est pas prévue au départ. Elle introduirait un rendu et un nettoyage plus contraignants. Elle ne pourra être reconsidérée qu’après mesure d’un besoin réel et rédaction d’une ADR.

## 10. Rendu enfant

Chaque écran reçoit un `SKView` et une `SKScene` indépendants. Le `SceneRouter` envoie :

- les frappes vers l’écran contenant le pointeur ;
- les clics vers l’écran et la position correspondants ;
- les événements sans localisation exploitable vers l’écran principal.

Contraintes de performance :

- nombre maximal de nœuds actifs ;
- durée de vie maximale de chaque animation ;
- réutilisation ou regroupement des effets lorsque pertinent ;
- aucun décodage d’image pendant le rendu ;
- pas d’allocation proportionnelle au nombre total d’événements depuis le début de la session ;
- comportement fluide à 60 Hz et compatible avec les écrans à taux de rafraîchissement supérieur.

Les polices système et Apple Color Emoji doivent être privilégiées. Les animations doivent rester agréables, lisibles et non agressives.

## 11. Dossier d’images et préférences

Le parent choisit un dossier via `NSOpenPanel`. Si le sandbox est retenu, l’accès persistant utilise un bookmark à portée de sécurité.

`WallpaperRepository` doit tolérer :

- bookmark périmé ;
- dossier déplacé ou supprimé ;
- disque externe absent ;
- fichier caché ou non lisible ;
- image corrompue ;
- dimensions ou volume mémoire déraisonnables ;
- modification du fichier pendant sa lecture.

ImageIO doit produire des miniatures pour la galerie et des images finales sous-échantillonnées selon la taille en pixels de chaque écran. L’affichage est de type *aspect fill* avec recadrage centré par défaut.

Les réglages utilisent une structure `Codable` versionnée. Toute évolution de schéma doit posséder une migration testée.

## 12. Concurrence et performance

- `@MainActor` pour AppKit, SwiftUI, SpriteKit et la coordination de session.
- Thread et boucle Core Foundation dédiés au tap.
- Travail disque et ImageIO hors du thread principal.
- Types traversant les frontières conformes à `Sendable`.
- Tâches structurées, annulées à la fin d’une session.
- Pas de `Task.detached` sans justification documentée.
- File d’entrée bornée avec politique explicite de regroupement ou de perte pour les mouvements, jamais pour la sortie adulte.

Les objectifs doivent être mesurés avec Instruments et `OSLog` signposts : latence du callback, temps de rendu, allocations, mémoire stabilisée et absence de fuite après plusieurs sessions.

## 13. Erreurs, journaux et confidentialité

- Définir des erreurs métier et système explicites conformes à `Error` et, lorsque pertinent, `LocalizedError`.
- Convertir les valeurs `nil` et codes Core Graphics en erreurs contextualisées.
- Présenter au parent une cause et une action corrective.
- Utiliser `Logger` avec catégories et confidentialité appropriées.
- Ne jamais enregistrer les caractères saisis, la séquence `parent`, les chemins privés complets ou le contenu des images.
- Employer `defer` et des opérations idempotentes pour le nettoyage.
- Prévenir les exceptions Objective-C par construction, notamment en validant les combinaisons de `presentationOptions` au lieu d’essayer de les intercepter en Swift.

## 14. Signature, sandbox et permissions

Principes :

- signature stable dès la phase 0 afin d’éviter des autorisations TCC attachées à une identité changeante ;
- Hardened Runtime activé ;
- aucune élévation de privilège ;
- droits limités à ceux réellement nécessaires ;
- préférence pour App Sandbox si l’interception active fonctionne correctement dans cette configuration.

La compatibilité réelle entre sandbox, signature, version de macOS et tap actif est un objectif central de la phase 0. Si le sandbox doit être désactivé, cette décision doit être justifiée par une reproduction, documentée dans une ADR et compensée par une surface fonctionnelle minimale.

## 15. Stratégie de tests

### 15.1 Tests unitaires avec Swift Testing

- transitions valides et invalides de la machine à états ;
- rollback pour chaque étape d’activation ;
- reconnaissance des deux sorties adultes ;
- délais, répétitions et faux positifs ;
- traduction d’entrées selon plusieurs dispositions clavier ;
- coordonnées multi-écrans, y compris origines négatives et échelles différentes ;
- catalogue et sélection de fonds ;
- limites d’images et fichiers corrompus ;
- migrations de réglages.

L’horloge, le générateur aléatoire, les écrans et les services système doivent être injectables pour rendre les tests déterministes.

### 15.2 Tests d’intégration

- création et destruction de fenêtres ;
- application puis restauration de la présentation ;
- activation et désactivation répétée du tap ;
- comportement lors de sa désactivation forcée ;
- ajout et retrait d’écrans via abstractions testables ;
- bookmarks valides, périmés et absents ;
- décodage d’images de fixtures.

### 15.3 Tests d’interface avec XCTest/XCUITest

- parcours adulte ;
- état des permissions ;
- sélection d’un fond de fixture ;
- démarrage et sortie contrôlée ;
- accessibilité et navigation clavier de l’interface adulte.

### 15.4 Matrice manuelle macOS

Tester au minimum :

- `Commande-Espace`, `Commande-Tab`, `Commande-Q`, `Commande-H`, `Commande-M` ;
- `Option-Commande-Échap` ;
- `Contrôle-↑`, `Contrôle-↓`, `Contrôle-Commande-Q` ;
- Spotlight, Alfred et raccourcis tiers configurés ;
- touches Fn/Globe et multimédias ;
- gestes du trackpad et coins actifs ;
- Stage Manager et Spaces ;
- écran branché ou retiré pendant la session ;
- veille et réveil ;
- permission révoquée ;
- dossier ou disque retiré ;
- tap ralenti ou désactivé ;
- crash simulé.

Les limites observées doivent être consignées, pas masquées.

## 16. Qualité continue et documentation

Prévoir dès la fondation :

- formatage reproductible avec `swift-format` ;
- compilation avec concurrence stricte ;
- CI sur un runner macOS ;
- builds Debug et Release ;
- tests unitaires, intégration et UI ;
- exécutions périodiques avec Address Sanitizer et Thread Sanitizer ;
- sessions Instruments avant une version utilisable ;
- documentation DocC des composants pédagogiques ;
- ADR pour les décisions sensibles ;
- modèle de menace, procédure d’autorisation et procédure de récupération.

La couverture de tests sert de signal, pas d’objectif artificiel. Les composants purs et de sécurité doivent cependant être couverts de manière exhaustive par comportements et cas limites.

## 17. Phases d’implémentation validées

### Phase 0 — Prototype de faisabilité

Objectif : lever les risques macOS avant de construire le produit.

Travaux :

1. relever la version macOS, l’architecture du Mac, la version stable de Xcode et les écrans cibles ;
2. créer l’identité minimale et stable nécessaire aux essais TCC ;
3. vérifier la création d’un tap de session actif ;
4. vérifier la suppression réelle des principaux raccourcis ;
5. tester la réaction aux événements de désactivation du tap ;
6. vérifier App Sandbox activé, puis documenter le résultat ;
7. créer deux fenêtres de démonstration sur deux écrans si disponibles ;
8. tester entrée, rollback et sortie du mode de présentation ;
9. produire un compte rendu factuel et une ADR de décision sandbox/permissions.

Critère de sortie : démonstration reproductible que le socle est viable sur le Mac cible, ou rapport de blocage précis avec alternative proposée.

La phase 0 doit rester limitée. Elle ne doit pas commencer le moteur d’animations, la galerie complète ou la finition visuelle.

### Phase 1 — Fondations

- projet Xcode et organisation des sources ;
- concurrence stricte ;
- machine à états ;
- injection des dépendances ;
- erreurs et journalisation ;
- Swift Testing, XCTest et CI ;
- premiers documents DocC/ADR.

### Phase 2 — Configuration adulte

- état des permissions ;
- choix du dossier ;
- bookmarks ;
- galerie de miniatures ;
- préférences versionnées ;
- accessibilité de l’interface.

### Phase 3 — Multi-écrans et fonds

- une fenêtre par écran ;
- suivi dynamique de la configuration ;
- rendu *aspect fill* ;
- transformations de coordonnées testées ;
- cycle veille/réveil minimal.

### Phase 4 — Bouclier d’entrée

- tap sur thread dédié ;
- file bornée et regroupement ;
- résolution clavier ;
- sorties adultes ;
- watchdog et récupération ;
- activation et désactivation transactionnelles.

### Phase 5 — Expérience enfant

- affichage de lettres et emojis ;
- animations de clic ;
- routage vers le bon écran ;
- bornes de ressources ;
- déterminisme injectable pour les tests.

### Phase 6 — Intégration système

- branchement d’écrans à chaud ;
- Spaces et Stage Manager ;
- veille et réveil ;
- révocation de permissions ;
- dossier ou disque absent ;
- comportement du curseur.

### Phase 7 — Durcissement

- matrice complète de raccourcis ;
- tests de charge d’entrée ;
- fuzzing des traducteurs et machines à états ;
- sanitizers ;
- Instruments ;
- revue du modèle de menace et des journaux.

### Phase 8 — Livraison locale

- build Release signé ;
- installation reproductible ;
- procédure de première autorisation ;
- guide d’utilisation et de récupération ;
- versionnement et changelog.

## 18. Consignes pour la prochaine session

1. Lire ce document et l’étude associée avant toute action.
2. Ne pas sauter directement à l’interface ou aux animations.
3. Commencer par inventorier l’environnement local avec des commandes en lecture seule.
4. Présenter brièvement au propriétaire le périmètre exact de la phase 0 avant les premières modifications.
5. Ne demander une clarification que si une décision manquante modifie réellement l’architecture ou le niveau de protection.
6. Préserver les limites de sécurité documentées ; ne jamais promettre un kiosque inviolable.
7. Après la phase 0, remettre un rapport de faisabilité et attendre la décision de poursuivre vers la phase 1 si un résultat remet en cause le plan.

## 19. Définition globale de « terminé »

Le premier produit utilisable sera considéré terminé lorsque :

- tous les écrans sont couverts et suivis dynamiquement ;
- l’image choisie est chargée de manière sûre et performante ;
- les frappes et clics produisent les réactions prévues ;
- les principaux raccourcis système sont absorbés dans la matrice validée ;
- les deux sorties adultes fonctionnent indépendamment du rendu ;
- chaque échec d’activation restaure proprement l’état précédent ;
- les permissions manquantes ou révoquées sont expliquées au parent ;
- les tests automatiques et la matrice manuelle sont à jour ;
- aucune fuite ou croissance mémoire non bornée n’est observée ;
- un build Release signé et une procédure de récupération existent ;
- les limites restantes sont écrites et visibles dans la documentation utilisateur.

