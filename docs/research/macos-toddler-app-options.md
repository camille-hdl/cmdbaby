# Application macOS « clavier pour bébé » : faisabilité et options

Recherche effectuée le 2 septembre 2026 à partir de documentation Apple, Electron et de standards Web officiels. Aucun code d'application n'a été commencé.

## Conclusion courte

Le besoin est réalisable de façon robuste pour un enfant de deux ans, mais pas comme une frontière de sécurité absolue : une application macOS ordinaire peut masquer l'interface système, filtrer la plupart des événements clavier/souris et couvrir tous les écrans, mais elle ne peut pas garantir le blocage des boutons matériels, de tous les gestes système futurs ni d'une extinction forcée. Apple documente notamment que le bouton d'alimentation maintenu force l'arrêt et que Touch ID peut verrouiller l'écran ([Apple Support — raccourcis Mac](https://support.apple.com/en-au/102650)).

La meilleure option pour cet usage personnel est une petite application **Swift/AppKit native**, avec une fenêtre sans bordure par écran, les options de présentation « kiosk » d'AppKit et un `CGEventTap` actif. Une application Web seule ne répond pas à l'exigence de confinement. Electron ou WebKit restent possibles pour la partie visuelle, mais la couche de confinement doit tout de même être native.

## Socle commun nécessaire

### Couvrir tous les écrans

- AppKit expose la liste dynamique de tous les écrans avec `NSScreen.screens`; Apple précise qu'elle ne doit pas être mise en cache et que la notification `NSApplication.didChangeScreenParametersNotification` est envoyée après ajout, retrait ou reconfiguration d'un écran ([`NSScreen.screens`](https://developer.apple.com/documentation/appkit/nsscreen/screens), [notification de changement](https://developer.apple.com/documentation/appkit/nsapplication/didchangescreenparametersnotification)).
- L'architecture fiable est une fenêtre sans titre, non redimensionnable et opaque par `NSScreen`, calée sur `screen.frame`, plutôt qu'une seule fenêtre géante. Chaque fenêtre peut être placée à un niveau élevé; AppKit documente notamment le niveau écran de veille et le fait qu'un niveau supérieur recouvre les niveaux inférieurs ([`NSWindow.Level`](https://developer.apple.com/documentation/appkit/nswindow/level-swift.struct)).
- Les comportements `canJoinAllSpaces`, `stationary`, `ignoresCycle` et, selon le mode plein écran choisi, `fullScreenAuxiliary`, permettent d'adapter les fenêtres à Spaces, Mission Control et Stage Manager ([`NSWindow.CollectionBehavior`](https://developer.apple.com/documentation/appkit/nswindow/collectionbehavior-swift.struct)). Il faut néanmoins tester avec « Les écrans disposent d'espaces distincts » activé et désactivé.

### Masquer et neutraliser l'interface macOS

`NSApplication.presentationOptions` est explicitement conçu pour les jeux plein écran et les kiosques. Il peut notamment :

- cacher entièrement le Dock et la barre des menus;
- désactiver le menu Apple, le masquage de l'application et le changement d'application (`Cmd-Tab`);
- désactiver la fenêtre Forcer à quitter (`Cmd-Option-Esc`);
- désactiver le panneau redémarrage/arrêt/déconnexion invoqué par la touche d'alimentation.

Apple impose certaines combinaisons : par exemple, `disableProcessSwitching` et `disableForceQuit` doivent être accompagnés de `hideDock` ou `autoHideDock` ([`NSApplication.PresentationOptions`](https://developer.apple.com/documentation/appkit/nsapplication/presentationoptions-swift.struct)). Ces options ne documentent pas le blocage de Spotlight, Alfred, `Control-Up`, du Centre de notifications ou de chaque raccourci futur : elles doivent être complétées par le filtrage d'événements.

### Capturer et supprimer les raccourcis

- Les moniteurs globaux `NSEvent` sont seulement observateurs et ne peuvent ni modifier ni empêcher la livraison; les moniteurs locaux ne voient que les événements distribués dans l'application. Ils sont donc insuffisants comme frontière de confinement ([moniteur global](https://developer.apple.com/documentation/appkit/nsevent/addglobalmonitorforevents%28matching%3Ahandler%3A%29), [moniteur local](https://developer.apple.com/documentation/appkit/nsevent/addlocalmonitorforevents%28matching%3Ahandler%3A%29)).
- Quartz Event Services permet d'installer un `CGEventTap` avant la livraison des événements à l'application au premier plan ([vue d'ensemble Quartz Event Services](https://developer.apple.com/documentation/coregraphics/quartz-event-services)).
- Un tap actif (`defaultTap`, et non `listenOnly`) peut laisser passer, modifier ou jeter un événement ([`CGEventTapOptions`](https://developer.apple.com/documentation/coregraphics/cgeventtapoptions)). Le callback supprime un événement en renvoyant `NULL` ([`CGEventTapCallBack`](https://developer.apple.com/documentation/coregraphics/cgeventtapcallback)). C'est la primitive pertinente pour consommer `Cmd-Space`, les combinaisons Alfred, les touches de fonction, les clics ou le défilement avant qu'ils n'atteignent un autre client de la session.
- Le point d'entrée HID lui-même est réservé aux processus root; une application normale doit utiliser un tap de session ou annoté ([`CGEventTapCreate`](https://developer.apple.com/documentation/coregraphics/cgevent/tapcreate%28tap%3Aplace%3Aoptions%3Aeventsofinterest%3Acallback%3Auserinfo%3A%29)). Exécuter l'application entière en root serait une mauvaise conception pour ce besoin.
- L'accès doit être explicitement autorisé dans Réglages Système > Confidentialité et sécurité > Surveillance de l'entrée. Apple fournit `CGPreflightListenEventAccess` et `CGRequestListenEventAccess`; un ingénieur DTS Apple confirme que ce mécanisme est utilisable par une application sandboxée après consentement ([Apple Developer Forums, réponse DTS](https://developer.apple.com/forums/thread/724608)). Selon la combinaison exacte de tap actif et de signature, macOS peut également présenter l'autorisation Accessibilité; `AXIsProcessTrustedWithOptions` permet d'en vérifier l'état et de demander l'affichage de l'invite ([documentation Apple](https://developer.apple.com/documentation/applicationservices/1459186-axisprocesstrustedwithoptions)). Prévoir un écran adulte de diagnostic plutôt qu'un échec silencieux.
- Un tap peut être désactivé s'il devient lent ou à la demande du système/utilisateur; Apple envoie alors un événement de désactivation et permet de le réactiver via `CGEvent.tapEnable` ([documentation Apple](https://developer.apple.com/documentation/coregraphics/cgevent/tapenable%28tap%3Aenable%3A%29)). Le callback doit donc être minuscule, sans chargement d'image ni rendu : il enfile l'action, décide rapidement si l'événement passe, puis rend la main.

Le filtre doit traiter au minimum `keyDown`, `keyUp`, `flagsChanged`, tous les boutons de souris, déplacement/drag et molette. En pratique, les clics peuvent rester livrés aux fenêtres de l'application puisqu'elles couvrent tous les écrans; le filtre sert surtout à garantir que les touches ne partent pas ailleurs et à reconnaître la sortie adulte.

### Secure Event Input n'est pas un mode kiosque

Secure Event Input est une protection réservée aux saisies sensibles : il empêche les événements clavier d'atteindre les processus d'interception, y compris les event taps. Apple dit explicitement de ne jamais l'activer pour une saisie ordinaire ni pendant toute la durée de vie d'une application ([note technique Apple TN2150](https://developer.apple.com/library/archive/technotes/tn2150/)). C'est donc une limitation possible à détecter, et non une technique de kiosque. `presentationOptions` et le tap actif sont les mécanismes adaptés.

### Choix du dossier d'images

`NSOpenPanel` sait sélectionner un dossier via `canChooseDirectories` ([documentation Apple](https://developer.apple.com/documentation/appkit/nsopenpanel)). Dans une application sandboxée, la sélection étend l'accès au dossier et à ses descendants; pour le conserver entre les lancements, Apple recommande un bookmark à portée de sécurité ([accès aux fichiers depuis l'App Sandbox](https://developer.apple.com/documentation/security/accessing-files-from-the-macos-app-sandbox)). Pour un usage personnel hors Mac App Store, le sandbox est facultatif, mais garder ce flux évite d'enregistrer un simple chemin devenu invalide après déplacement ou renommage.

### Porte de sortie adulte

La sortie doit être reconnue **dans le tap**, puisque celui-ci jette les événements avant AppKit/WebKit. Proposition sûre et simple : conserver un tampon des caractères et quitter seulement après la séquence `parent`, saisie en moins de cinq secondes, éventuellement suivie d'Entrée. Avant de terminer : désactiver le tap, restaurer les options de présentation, puis fermer les fenêtres.

`Cmd-Q` seul est une mauvaise sortie principale : un enfant peut le produire par hasard. Il peut servir de seconde sortie si on exige un maintien de trois secondes ou une confirmation par code. Il faut aussi conserver une issue d'urgence adulte connue, par exemple les deux touches Shift maintenues trois secondes puis un PIN. Un crash ne doit pas verrouiller la machine : quand le processus disparaît, ses fenêtres et son tap disparaissent également.

## Trois options d'implémentation

### Option 1 — Swift + AppKit natif, rendu SwiftUI Canvas ou SpriteKit (recommandée)

**Architecture.** AppKit gère le cycle de vie, les fenêtres multi-écrans, les options de présentation, le tap et le sélecteur de dossier. La scène visuelle peut être un `NSView`, un `Canvas` SwiftUI ou SpriteKit pour les lettres, emojis, particules et sons.

**Avantages.** Meilleure maîtrise des API macOS, binaire et consommation mémoire réduits, aucune couche native additionnelle, permissions attribuées à un seul bundle, comportement multi-écrans le plus prévisible. Le périmètre fonctionnel est assez petit pour ne pas justifier un gros runtime.

**Inconvénients.** Animations et mise en page à écrire en Swift; développement moins immédiat si l'équipe maîtrise surtout le Web. SwiftUI ne remplace pas AppKit pour le confinement : il faut assumer une petite couche AppKit explicite.

**Effort relatif.** Moyen pour le premier prototype, faible ensuite. C'est l'option qui réduit le plus le risque technique.

### Option 2 — Coquille Swift/AppKit + interface locale HTML/CSS/JavaScript dans `WKWebView`

**Architecture.** La même coquille native que l'option 1 assure toutes les fonctions sensibles. Chaque fenêtre contient un `WKWebView` chargé uniquement avec des ressources locales; le tap transmet des messages de haut niveau (« touche A », « clic à x/y ») au rendu. Apple décrit `WKWebView` comme une vue native pouvant présenter HTML, CSS et JavaScript au sein d'une hiérarchie AppKit ([documentation Apple](https://developer.apple.com/documentation/webkit/wkwebview)).

**Avantages.** Animations CSS/Canvas rapides à produire, pas de Chromium ni de Node embarqués, empreinte plus faible qu'Electron, tout en gardant le confinement natif.

**Inconvénients.** Pont Swift-JavaScript et synchronisation de plusieurs vues; il faut interdire navigation externe, menus contextuels et inspectabilité en production. La partie Web ne doit jamais décider seule du verrouillage ou de la sortie.

**Effort relatif.** Moyen. Bon compromis si le rendu Web est nettement plus familier que SwiftUI/SpriteKit.

### Option 3 — Electron pour l'interface + petit helper natif Swift/Objective-C

**Architecture.** Electron crée un `BrowserWindow` par écran à partir de `screen.getAllDisplays()` et suit les événements d'ajout/retrait d'écran ([module `screen`](https://www.electronjs.org/docs/latest/api/screen)). Les fenêtres utilisent le mode kiosk/plein écran et l'interface est locale. Un helper ou module natif macOS porte le `CGEventTap` et, si nécessaire, les options de présentation non exposées avec assez de précision par Electron.

**Pourquoi le helper est obligatoire.** `before-input-event` ne s'applique qu'aux événements arrivés au `webContents` et permet d'annuler les événements de page ou raccourcis de menu ([documentation Electron](https://www.electronjs.org/docs/latest/api/web-contents#event-before-input-event)). `globalShortcut` enregistre des accélérateurs un par un; l'enregistrement échoue silencieusement quand une combinaison est déjà prise, comportement voulu par l'OS ([documentation Electron](https://www.electronjs.org/docs/latest/api/global-shortcut/)). Ces API ne constituent donc pas un filtre exhaustif de la session.

**Avantages.** Développement de l'interface très rapide en JavaScript/TypeScript, bibliothèques d'animation nombreuses, multi-écrans directement exposé.

**Inconvénients.** Plus gros binaire et davantage de RAM; deux mondes à signer, empaqueter et diagnostiquer; le point le plus délicat reste de toute façon natif. Une application locale doit charger uniquement ses propres ressources et garder `contextIsolation` et le sandbox du renderer; Electron recommande aussi de bloquer les navigations et fenêtres inattendues ([guide de sécurité Electron](https://www.electronjs.org/docs/latest/tutorial/security)).

**Effort relatif.** Moyen à élevé à cause du helper. À choisir surtout si l'écosystème JS apporte une vraie accélération au projet.

## Options écartées ou complémentaires

### Page Web/PWA en plein écran : insuffisante

Les événements clavier Web sont ciblés sur l'élément du document ayant le focus, pas sur les autres applications ni sur l'OS ([HTML Standard](https://html.spec.whatwg.org/dev/interaction.html)). Le standard Fullscreen autorise explicitement le navigateur à mettre fin au plein écran quand il le juge nécessaire ([Fullscreen API Standard](https://fullscreen.spec.whatwg.org/)). Une page peut afficher les lettres et emojis, mais pas garantir le blocage de Spotlight, Alfred, `Cmd-Tab`, Mission Control ou la sortie du navigateur.

### MDM + Autonomous Single App Mode : confinement maximal, lourdeur maximale

macOS dispose d'un payload `com.apple.asam` qui accorde aux applications autorisées un accès système bas niveau, y compris journalisation de touches et manipulation d'interface. Il exige cependant un serveur MDM approuvé par l'utilisateur et un bundle signé identifié par Bundle ID et Team ID ([documentation Apple Device Management](https://developer.apple.com/documentation/devicemanagement/autonomoussingleappmode), [guide de déploiement Apple](https://support.apple.com/guide/deployment/autonomous-single-app-mode-payload-settings-dep8a42c4c4a/1/web/1.0)). C'est disproportionné pour un Mac personnel, mais c'est la piste appropriée si « impossible à quitter » devient une exigence de kiosque institutionnel plutôt qu'une protection contre un bambin.

Un compte macOS standard dédié à l'enfant est une mesure complémentaire beaucoup plus simple : même si un geste système échappe au filtre, le compte ne contient pas les documents ni sessions sensibles de l'adulte.

## Limites incompressibles et durcissement pratique

- Le produit doit être présenté comme **anti-bêtises pour bambin**, pas comme verrou de sécurité contre un utilisateur déterminé.
- Le type public `CGEventType` couvre clavier, boutons, déplacement et molette, mais n'expose pas de type « geste » équivalent aux gestes AppKit. On ne peut donc pas promettre que le tap Quartz supprimera chaque geste système; c'est une inférence à partir de [la liste Core Graphics](https://developer.apple.com/documentation/coregraphics/cgeventtype) et des [types d'événements AppKit](https://developer.apple.com/documentation/appkit/nsevent/eventtypemask).
- Désactiver dans Réglages Système les raccourcis Spotlight/Mission Control redondants, les coins actifs et les gestes « Mission Control », « afficher le bureau », « changer d'app plein écran » réduit les chemins non couverts. Apple confirme que ces gestes et raccourcis sont configurables ou désactivables ([Mission Control](https://support.apple.com/en-gb/guide/mac-help/mh35798/mac), [gestes du trackpad](https://support.apple.com/guide/mac-help/use-trackpad-and-mouse-gestures-mh35869/26/mac/26), [coins actifs](https://support.apple.com/en-gb/guide/mac-help/-mchlp3000/mac)).
- Tester expressément : `Cmd-Space`, `Cmd-Tab`, `Cmd-Q`, `Cmd-H`, `Cmd-M`, `Cmd-Option-Esc`, `Control-Up/Down`, `Control-Command-Q`, touches Globe/Fn, Touch ID/alimentation, gestes à trois/quatre doigts, coins actifs, Centre de notifications, changement d'écran à chaud, mise en veille/réveil et révocation des permissions.
- À l'activation, vérifier que le tap est réellement créé et que les fenêtres couvrent chaque écran; sinon refuser de lancer le « mode enfant » et afficher une procédure adulte. Un écran noir joli sans filtre actif donnerait un faux sentiment de sécurité.
- Pour l'usage quotidien, l'option 1 associée à un compte standard dédié offre le meilleur rapport simplicité/protection. L'option MDM n'est justifiée que si les limites matérielles et système ordinaires sont inacceptables.
