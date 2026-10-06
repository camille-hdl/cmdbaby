# Sécurité

Le modèle de menace complet viendra avec #125. Cette page note, dès maintenant, les limites connues du kiosque.

## Limites connues

### Fil principal bloqué pendant une session

Une sortie adulte reconnue par le tap clavier engage tout de suite le kill switch de ce filtre : les frappes ne sont plus filtrées. La suite passe par le fil principal (`Task { @MainActor }`) : restaurer les options de présentation, fermer les couvertures, arrêter le tap.

Si le fil principal ne répond plus, cette suite n’arrive jamais :

- les couvertures restent au niveau économiseur d’écran, sur tous les écrans ;
- les options de présentation restent actives : pas de Dock ni de barre des menus, pas de Cmd-Tab, pas de « Forcer à quitter » (Cmd-Option-Échap) ;
- le clavier n’est plus filtré, mais les frappes vont à CmdBaby, qui ne répond pas.

Le thread du tap ne peut pas restaurer lui-même la présentation : `NSApplication.presentationOptions` ne se modifie que sur le fil principal.

Pour en sortir, il faut terminer le processus de l’extérieur : `ssh` depuis une autre machine puis `killall CmdBaby`, ou un appui long sur le bouton d’alimentation. À la mort du processus, macOS retire ses fenêtres et rétablit ses options de présentation.

Piste non retenue pour l’instant : depuis le thread du tap, terminer le processus (`exit`) si une sortie reconnue n’est pas traitée sous 3 s. Cela rendrait la main à coup sûr, au prix d’une fermeture brutale si le fil principal est seulement lent.

### Secure Event Input

Quand une autre app active Secure Event Input (champ de mot de passe, Terminal avec « Secure Keyboard Entry »), le tap ne voit plus aucune frappe. CmdBaby refuse de lancer une session dans cet état. Si cela arrive en cours de session, le chien de garde affiche un bandeau pour l’adulte. Il ne peut pas rétablir le filtre : il faut utiliser une sortie adulte, à la souris (cinq clics sur le carré de secours) si le clavier ne répond plus.
