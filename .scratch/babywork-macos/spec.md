Status: ready-for-agent

# BabyWork — application macOS ludique et confinée pour jeune enfant

## Problem Statement

Le propriétaire d’un Mac veut pouvoir confier momentanément le clavier et la souris à un enfant d’environ deux ans sans que ses frappes déclenchent Spotlight, Alfred, un changement d’application, une fermeture ou une action dans un autre logiciel. Les solutions plein écran ordinaires ne couvrent pas suffisamment les interactions système et peuvent donner un faux sentiment de sécurité.

Pendant cette session protégée, l’enfant doit recevoir une réponse visuelle immédiate et amusante sur tous les écrans connectés. Le parent doit pouvoir préparer la session simplement, comprendre les permissions nécessaires, choisir son fond visuel et récupérer le contrôle avec des sorties fiables.

Le produit doit être présenté honnêtement comme un confinement anti-bêtises très robuste pour un jeune enfant, et non comme une frontière de sécurité inviolable. macOS, les boutons matériels, certains gestes système, une révocation d’autorisation ou une panne peuvent toujours offrir des voies de sortie qui échappent à une application ordinaire.

## Solution

Créer une application macOS native, personnelle et hors ligne qui combine :

- une interface parent accessible pour les permissions, le choix du dossier d’images, la galerie et le démarrage ;
- une fenêtre de couverture indépendante sur chaque écran ;
- un mode de présentation AppKit adapté à un usage de type kiosque ;
- un filtre actif des événements clavier et souris au niveau de la session macOS ;
- un rendu SpriteKit réactif affichant de grandes lettres, des emojis et des animations de clic ;
- deux sorties adultes reconnues indépendamment du rendu ;
- une activation transactionnelle, un rollback systématique et une récupération explicite en cas de perte du filtre d’entrée.

La construction commence par un prototype de faisabilité signé et mesurable. Ce prototype doit démontrer sur le Mac cible que le filtre actif, les permissions, le sandbox envisagé, la suppression des raccourcis, la présentation et les fenêtres multi-écrans sont réellement viables avant toute construction du produit complet.

## User Stories

1. En tant que parent, je veux lancer une session enfant depuis une interface dédiée, afin de confier le clavier et la souris sans exposer mes autres applications.
2. En tant que parent, je veux que le démarrage soit refusé si une condition critique manque, afin de ne jamais croire qu’une session partiellement protégée est sûre.
3. En tant que parent, je veux voir quelles permissions macOS sont requises, afin de comprendre pourquoi l’application en a besoin.
4. En tant que parent, je veux être guidé vers l’action corrective lorsqu’une permission manque ou a été révoquée, afin de pouvoir rétablir le fonctionnement.
5. En tant que parent, je veux connaître l’état des composants critiques avant le démarrage, afin de détecter un filtre d’entrée ou un écran indisponible.
6. En tant que parent, je veux choisir explicitement un dossier d’images, afin de maîtriser les visuels proposés à l’enfant.
7. En tant que parent, je veux parcourir une galerie de miniatures, afin de sélectionner facilement le fond de la session.
8. En tant que parent, je veux retrouver mon dossier et mes réglages après un redémarrage, afin de ne pas reconfigurer l’application à chaque usage.
9. En tant que parent, je veux être averti si le dossier a été déplacé, supprimé ou se trouve sur un disque absent, afin de choisir une autre source sans échec opaque.
10. En tant que parent, je veux que les images corrompues, illisibles ou démesurées soient ignorées proprement, afin qu’un fichier défectueux ne bloque pas la session.
11. En tant que parent, je veux que l’image sélectionnée s’affiche sur tous les écrans sans déformation, afin d’obtenir un environnement visuel cohérent.
12. En tant que parent, je veux que le cadrage remplisse chaque écran en conservant les proportions, afin d’éviter les bandes et les images étirées.
13. En tant que parent, je veux que tous les écrans connectés soient couverts, afin qu’aucun bureau ni logiciel ne reste directement accessible à l’enfant.
14. En tant que parent, je veux que l’ajout, le retrait ou la reconfiguration d’un écran soit pris en charge pendant une session, afin que la couverture reste cohérente.
15. En tant que parent, je veux que les configurations avec coordonnées négatives, écrans Retina différents ou écrans en miroir fonctionnent correctement, afin d’utiliser mon installation réelle.
16. En tant qu’enfant, je veux voir une grande lettre ou un emoji lorsque j’appuie sur une touche, afin que chaque frappe produise une réaction amusante.
17. En tant qu’enfant, je veux que la lettre corresponde à la disposition active du clavier, notamment AZERTY, afin que l’affichage représente ce que j’ai réellement saisi.
18. En tant qu’enfant, je veux que ma frappe apparaisse sur l’écran où se trouve le pointeur, afin que la réaction soit située là où je regarde et interagis.
19. En tant qu’enfant, je veux que les frappes sans écran identifiable apparaissent sur l’écran principal, afin qu’elles produisent toujours une réponse visible.
20. En tant qu’enfant, je veux voir une animation à l’endroit exact de mon clic, afin de comprendre immédiatement le lien entre mon geste et l’écran.
21. En tant qu’enfant, je veux que les boutons supplémentaires, déplacements, glissements et défilements soient traités sans rendre l’expérience instable, afin de pouvoir manipuler librement la souris.
22. En tant qu’enfant, je veux des animations fluides, lisibles et non agressives, afin que la session reste agréable.
23. En tant qu’enfant, je veux que l’expérience reste fluide lorsque je produis de très nombreux mouvements ou frappes, afin que mon jeu spontané ne sature pas l’application.
24. En tant que parent, je veux que les principaux raccourcis macOS et ceux d’outils comme Alfred soient absorbés, afin qu’ils ne fassent pas apparaître une autre interface.
25. En tant que parent, je veux que `Commande-Q` soit absorbé par défaut, afin qu’une combinaison accidentelle ne ferme pas l’application.
26. En tant que parent, je veux quitter normalement en saisissant `parent` puis Entrée dans une durée limitée, afin de récupérer le Mac par une action difficile à produire au hasard.
27. En tant que parent, je veux que la séquence de sortie expire et se réinitialise après une erreur, afin qu’une accumulation de frappes anciennes ne provoque pas une sortie inattendue.
28. En tant que parent, je veux disposer d’une sortie de secours en maintenant les deux touches Majuscule pendant trois secondes, afin de reprendre le contrôle si la sortie textuelle est inutilisable.
29. En tant que parent, je veux que les deux sorties fonctionnent sans dépendre des animations ni de la disponibilité du rendu, afin qu’un problème visuel ne m’enferme pas dans la session.
30. En tant que parent, je veux que la sortie restaure la présentation, le curseur et les fenêtres dans un ordre sûr, afin de retrouver mon environnement normal.
31. En tant que parent, je veux qu’une erreur pendant l’activation annule toutes les étapes déjà appliquées, afin de ne pas laisser le Mac dans un état intermédiaire.
32. En tant que parent, je veux que la perte temporaire du filtre d’entrée déclenche une récupération visible et immédiate, afin de connaître le niveau réel de protection.
33. En tant que parent, je veux que les fenêtres restent en place pendant une tentative de récupération du filtre, afin que le bureau ne soit pas soudainement révélé à l’enfant.
34. En tant que parent, je veux que plusieurs sessions successives démarrent et s’arrêtent proprement, afin d’utiliser l’application quotidiennement sans redémarrer le Mac.
35. En tant que parent, je veux que la veille et le réveil soient gérés proprement, afin de ne pas retrouver une session incohérente.
36. En tant que parent, je veux que les limites connues concernant Touch ID, le bouton d’alimentation et certains gestes soient documentées, afin de choisir des protections complémentaires en connaissance de cause.
37. En tant que parent, je veux recevoir la recommandation d’utiliser un compte macOS standard dédié à l’enfant, afin de réduire les conséquences d’une sortie imprévue.
38. En tant que parent, je veux que l’application n’envoie aucune télémétrie et n’accède pas au réseau, afin de préserver la confidentialité familiale.
39. En tant que parent, je veux que les frappes, la séquence adulte, les chemins privés et les images ne soient jamais écrits dans les journaux, afin que les diagnostics ne divulguent aucune donnée sensible.
40. En tant que parent, je veux des messages d’erreur compréhensibles avec une action corrective, afin de résoudre les problèmes sans expertise de développement.
41. En tant qu’utilisateur de l’interface parent, je veux une navigation accessible au clavier et aux technologies d’assistance, afin que la configuration reste utilisable par tous.
42. En tant que propriétaire du Mac, je veux une application exécutée sans privilèges administrateur permanents, afin de respecter le principe du moindre privilège.
43. En tant que propriétaire du Mac, je veux un binaire signé de manière stable, afin que les autorisations macOS restent associées à une identité prévisible.
44. En tant que propriétaire du Mac, je veux une procédure d’installation, de première autorisation et de récupération reproductible, afin de remettre l’application en service sans improvisation.
45. En tant que développeur, je veux valider le filtre d’événements et les permissions sur le vrai Mac cible avant de développer les animations, afin de lever le risque principal le plus tôt possible.
46. En tant que développeur, je veux comparer factuellement le fonctionnement avec et sans App Sandbox, afin que la décision de sécurité repose sur une reproduction documentée.
47. En tant que développeur, je veux mesurer la latence du filtre, le temps de rendu, les allocations et la mémoire, afin de vérifier que les ressources restent bornées.
48. En tant que développeur, je veux isoler le domaine, l’intégration système et le rendu, afin de tester les comportements sans dépendre partout des API macOS.
49. En tant que développeur, je veux injecter l’horloge, les écrans, les services système et les sources de données, afin d’obtenir des tests déterministes.
50. En tant que développeur, je veux compiler en mode de concurrence stricte Swift 6, afin de détecter tôt les traversées d’acteurs dangereuses.
51. En tant que développeur, je veux que les tâches, événements en attente, images et nœuds de rendu soient bornés, afin d’éviter une croissance mémoire provoquée par une longue session.
52. En tant que développeur, je veux que le callback du filtre reste minimal et non bloquant, afin que macOS ne désactive pas le tap pour dépassement de délai.
53. En tant que développeur, je veux regrouper ou perdre explicitement les mouvements fréquents sans jamais perdre une sortie adulte, afin de concilier fluidité et récupération sûre.
54. En tant que développeur, je veux des réglages versionnés avec migrations testées, afin de faire évoluer l’application sans casser les configurations existantes.
55. En tant que mainteneur, je veux des erreurs typées, des journaux privés et des nettoyages idempotents, afin de diagnostiquer les échecs sans créer de nouvel état dangereux.
56. En tant que mainteneur, je veux que les décisions sensibles soient consignées dans des ADR courtes, afin de conserver la justification des compromis macOS.
57. En tant que mainteneur, je veux une intégration continue macOS avec builds Debug et Release, tests et formatage reproductible, afin de détecter rapidement les régressions.
58. En tant que responsable qualité, je veux une matrice manuelle couvrant raccourcis, gestes, Spaces, Stage Manager, écrans, veille, permissions et pannes, afin de rendre visibles les limites réelles.
59. En tant que responsable qualité, je veux simuler la désactivation du filtre, le retrait du dossier et les erreurs d’activation, afin de vérifier les chemins de récupération aussi soigneusement que le chemin nominal.
60. En tant que responsable qualité, je veux répéter les sessions sous sanitizers et Instruments, afin de détecter les fuites, courses et croissances non bornées avant une livraison locale.

## Implementation Decisions

- Le produit cible uniquement macOS et utilise une architecture native Swift/AppKit.
- AppKit pilote le cycle de vie, les fenêtres, les écrans, le mode de présentation et l’interception système.
- SwiftUI porte l’interface normale destinée aux parents ; SpriteKit porte le rendu animé du mode enfant ; ImageIO charge, valide et sous-échantillonne les fonds.
- `AppCoordinator` compose les services et pilote le cycle de vie global sans devenir un singleton métier.
- `ChildSessionController` expose la façade unique de session et applique une machine à états explicite : configuration, vérification des permissions, préparation, activation, activité, récupération du filtre, arrêt, échec et rollback.
- L’activation est transactionnelle. Une session n’atteint l’état actif qu’après validation du fond, préparation d’une fenêtre par écran, confirmation des permissions, création effective du filtre, disponibilité des sorties adultes et capacité à restaurer l’état AppKit antérieur.
- Toute activation interrompue déclenche un rollback ordonné. Les options AppKit initiales sont capturées puis restaurées, jamais remplacées par une valeur supposée par défaut.
- `PermissionController` pré-vérifie les autorisations et fournit à l’interface parent un diagnostic et une action corrective.
- `InputShield` utilise un `CGEventTap` actif au niveau de la session utilisateur. Le point d’entrée HID nécessitant les droits `root` est exclu.
- Le tap fonctionne sur un thread dédié avec sa propre boucle Core Foundation. Son callback reconnaît les désactivations, extrait un événement léger, le dépose dans une file bornée, décide de le supprimer ou de le transmettre, puis rend immédiatement la main.
- Le callback n’effectue ni accès disque, ni décodage d’image, ni rendu, ni attente longue, ni journalisation détaillée, ni création d’une tâche Swift par mouvement.
- `InputPump` transporte les événements par une file bornée. Les mouvements peuvent être regroupés ou perdus selon une politique explicite ; les événements nécessaires aux sorties adultes ne le sont jamais.
- Les événements pris en charge comprennent les pressions et relâchements de touches, les changements de modificateurs, les boutons principaux et supplémentaires, les mouvements, les glissements, la molette et les notifications de désactivation du tap.
- La traduction clavier respecte la disposition active et ne repose pas sur une table QWERTY codée en dur.
- `AdultExitRecognizer` reconnaît `parent` suivi d’Entrée dans une fenêtre temporelle initialement fixée à cinq secondes, à préciser par mesure pendant la phase 0. Le tampon est réinitialisé après expiration, erreur ou succès et n’est ni journalisé ni persisté.
- La sortie de secours exige le maintien simultané des deux touches Majuscule pendant trois secondes. Elle est reconnue hors du rendu et reste indépendante du thread principal autant que possible.
- `Commande-Q` est absorbé et n’est pas une sortie activée par défaut.
- Après une sortie valide, la session empêche toute réactivation concurrente, neutralise le filtre, restaure la présentation et le curseur, ferme les fenêtres, puis revient à l’interface parent ou quitte selon l’action demandée.
- Si le tap devient indisponible pendant une session, les fenêtres restent affichées, une réactivation immédiate est tentée et la session passe dans un état explicite de récupération sans prétendre que la protection reste complète.
- `KioskPresentationController` applique une combinaison valide d’options de présentation et restaure exactement la combinaison précédente. Les combinaisons invalides sont empêchées par construction.
- `DisplayCoordinator` crée une fenêtre sans bordure par écran, réconcilie les fenêtres après chaque changement de configuration et ne met jamais durablement en cache la liste des écrans.
- Les écrans utilisent un identifiant stable lorsque macOS en expose un. Les coordonnées globales AppKit, locales aux fenêtres et SpriteKit sont transformées dans une responsabilité isolée.
- `CGCaptureAllDisplays` n’est pas utilisé initialement. Une adoption ultérieure exige un besoin mesuré et une ADR.
- Chaque écran possède son propre `SKView` et sa propre `SKScene`.
- `SceneRouter` envoie les frappes à l’écran contenant le pointeur, utilise l’écran principal en repli et place les animations de clic dans la scène correspondant à leurs coordonnées.
- Le rendu impose une durée de vie et un nombre maximal de nœuds, réutilise ou regroupe les effets utiles, ne décode jamais d’image pendant une frame et vise une fluidité de 60 Hz compatible avec les écrans plus rapides.
- Les polices système et Apple Color Emoji sont privilégiées. Les animations restent lisibles, agréables et non agressives.
- `WallpaperRepository` gère la sélection du dossier, son accès persistant éventuel, le catalogue, la validation, les miniatures et les images finales adaptées aux dimensions en pixels de chaque écran.
- L’accès persistant au dossier utilise un bookmark à portée de sécurité si le sandbox est retenu. Les bookmarks périmés, dossiers déplacés, disques absents, fichiers cachés, illisibles, corrompus, excessifs ou modifiés pendant leur lecture sont traités explicitement.
- La même image est utilisée sur tous les écrans avec un remplissage proportionnel et un recadrage centré par défaut.
- `SettingsStore` persiste une structure `Codable` versionnée et applique des migrations testées.
- AppKit, SwiftUI, SpriteKit et la coordination de session restent sur `@MainActor`. Le disque et ImageIO travaillent hors du thread principal. Les valeurs traversant les frontières de concurrence sont `Sendable`.
- Les tâches sont structurées et annulées à la fin d’une session. `Task.detached` exige une justification documentée.
- Les dépendances sont injectées par les initialiseurs ; aucun singleton métier n’est introduit.
- Les erreurs métier et système sont typées et converties en messages récupérables pour le parent. Les nettoyages utilisent des opérations idempotentes et `defer` lorsque pertinent.
- Les journaux utilisent des catégories et niveaux de confidentialité adaptés sans contenir les frappes, la séquence adulte, les chemins privés complets ni le contenu des images.
- L’application n’utilise ni télémétrie ni accès réseau.
- Le projet utilise le mode de concurrence stricte Swift 6, évite `try!` et réserve les déballages forcés aux invariants démontrés et documentés.
- La signature reste stable dès la phase 0, le Hardened Runtime est activé, aucune élévation de privilège n’est utilisée et les droits sont limités au besoin réel.
- App Sandbox est préféré si le tap actif fonctionne correctement dans cette configuration. Toute désactivation doit être reproduite, justifiée dans une ADR et compensée par une surface fonctionnelle minimale.
- Le développement suit les phases validées : faisabilité, fondations, configuration parent, multi-écrans et fonds, bouclier d’entrée, expérience enfant, intégration système, durcissement, puis livraison locale.
- La phase 0 est la seule prochaine étape autorisée. Elle ne doit pas commencer le moteur d’animations, la galerie complète ni la finition visuelle.
- La phase 0 produit un prototype signé minimal, des résultats reproductibles sur les raccourcis et les permissions, une démonstration multi-écrans si le matériel est disponible, un compte rendu factuel et une ADR sur le sandbox et les autorisations.

## Testing Decisions

- Un bon test vérifie un comportement observable et un contrat public : état de session, effet système demandé, événement routé, message présenté, ressource libérée ou configuration restaurée. Il ne fige ni l’ordre interne des appels sans portée contractuelle, ni les types privés, ni l’organisation des sources.
- Le point principal automatisé est la façade de session portée par `ChildSessionController`. Les dépendances macOS sont remplacées par des doubles déterministes afin de tester, par une seule frontière, le démarrage, l’activation transactionnelle, les entrées, les changements d’environnement, les sorties, la récupération et le rollback.
- Le second point est l’application signée exécutée dans une vraie session macOS. Il vérifie les comportements que les doubles ne peuvent pas prouver : TCC, App Sandbox, création et désactivation du `CGEventTap`, suppression effective des raccourcis, options de présentation, fenêtres réelles et écrans physiques.
- Le critère de sortie de la phase 0 est une démonstration reproductible du socle sur le Mac cible, ou un rapport de blocage précis accompagné d’une alternative. Une simulation seule ne satisfait pas ce critère.
- Les tests unitaires couvrent les transitions valides et invalides, le rollback de chaque étape, les deux sorties adultes, les délais, répétitions et faux positifs, la traduction de plusieurs dispositions clavier, les transformations multi-écrans, le catalogue de fonds, les limites d’image et les migrations de réglages.
- L’horloge, la configuration des écrans, les services système et toute source aléatoire sont injectables pour rendre les scénarios déterministes.
- Les tests d’intégration couvrent la création et la destruction de fenêtres, l’application puis la restauration de la présentation, les cycles répétés du tap, sa désactivation forcée, les changements d’écrans via abstractions testables, les bookmarks et le décodage d’images de fixture.
- Les tests d’interface couvrent le parcours parent, l’état des permissions, la sélection d’un fond de fixture, le démarrage et la sortie contrôlée ainsi que l’accessibilité et la navigation clavier.
- La matrice manuelle couvre au minimum les raccourcis système critiques, Spotlight, Alfred, les touches Fn/Globe et multimédias, les gestes et coins actifs, Stage Manager, Spaces, les écrans branchés ou retirés, les changements de résolution, la veille, le réveil, la révocation des permissions, le retrait du dossier, la désactivation du tap et un crash simulé.
- Les tests de performance mesurent avec Instruments et des signposts la latence du callback, le temps de rendu, les allocations, la stabilisation de la mémoire et l’absence de fuite après plusieurs sessions.
- Les tests de charge produisent des rafales d’entrées pour vérifier que les files, tâches et nœuds restent bornés et que les sorties adultes restent prioritaires.
- Le durcissement utilise périodiquement Address Sanitizer et Thread Sanitizer, ainsi que du fuzzing sur les traducteurs d’entrée et les machines à états.
- Il n’existe aucun projet ni test applicatif antérieur dans le dépôt ; il n’y a donc pas de précédent de test à réutiliser. Les premiers tests établiront les conventions autour de Swift Testing pour le domaine et de XCTest/XCUITest pour l’intégration système et l’interface.
- La couverture sert de signal et non d’objectif artificiel. Les composants purs et ceux qui protègent l’activation, la sortie et la restauration doivent néanmoins être couverts exhaustivement par comportement et cas limite.

## Out of Scope

- Garantir un mode kiosque inviolable contre un utilisateur déterminé.
- Neutraliser le bouton d’alimentation, Touch ID, toutes les voies matérielles, toutes les fonctions de sécurité futures de macOS ou tous les gestes système du trackpad.
- Installer ou administrer un compte macOS dédié à l’enfant, bien que son utilisation soit recommandée.
- Déployer un véritable mode mono-application administré par MDM.
- Distribuer publiquement l’application ou la publier sur le Mac App Store dans le premier périmètre.
- Prendre en charge Windows, Linux, iOS, iPadOS ou le Web.
- Utiliser une PWA, Electron ou un rendu Web comme fondation du confinement.
- Exécuter l’application en `root` ou utiliser un tap au point d’entrée HID.
- Utiliser initialement `CGCaptureAllDisplays`.
- Ajouter des sons, une sélection aléatoire du fond ou des thèmes graphiques avancés dans le premier produit validé.
- Ajouter de la télémétrie, un compte en ligne, une synchronisation distante ou toute fonctionnalité réseau.
- Commencer la galerie complète, les animations finales ou la finition produit pendant la phase 0.

## Further Notes

- Le plan a été validé le 2 septembre 2026 alors que le dépôt ne contenait encore aucun projet Xcode, code source ou test applicatif.
- La protection promise est un confinement anti-bêtises robuste pour un enfant d’environ deux ans. Toute communication produit ou message d’interface doit préserver cette formulation et rendre visibles les limites observées.
- Secure Event Input n’est pas une technique de kiosque ; il constitue au contraire une condition susceptible d’empêcher le filtre de recevoir certaines frappes.
- Un compte macOS standard dédié à l’enfant constitue la principale protection complémentaire recommandée pour les données et sessions du parent.
- Toute limite découverte pendant la phase 0 ou la matrice manuelle doit être consignée. Elle ne doit pas être masquée derrière une interface donnant l’impression que la protection est complète.
- Si la phase 0 remet en cause le sandbox, les permissions ou la viabilité du filtre actif, le travail s’arrête après le rapport et l’ADR jusqu’à décision explicite de poursuivre avec l’alternative proposée.
- Le premier produit utilisable est terminé lorsque tous les écrans sont suivis, le fond est chargé sûrement, les entrées produisent les réactions prévues, les raccourcis validés sont absorbés, les deux sorties adultes fonctionnent, chaque échec restaure l’état antérieur, les permissions sont expliquées, les tests et la matrice manuelle sont à jour, la mémoire reste bornée et un build Release signé avec procédure de récupération existe.
