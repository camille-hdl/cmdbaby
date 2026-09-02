# Inventaire initial du Mac cible

Relevé le 2 septembre 2026 avant les essais de filtrage d’entrée.

## Environnement observé

- macOS 15.7.7, build 24G720 ;
- architecture `arm64` ;
- GPU Apple M3 Pro, 14 cœurs ;
- Swift 6.1.2 fourni par les Command Line Tools ;
- répertoire développeur actif : `/Library/Developer/CommandLineTools` ;
- `xcodebuild` indisponible, car le répertoire actif n’est pas une installation Xcode complète ;
- aucune identité de signature de code valide trouvée dans le trousseau ;
- l’inventaire non graphique de System Profiler n’a retourné que le GPU ; la liste des écrans doit être relevée dans l’application diagnostique lancée au sein de la session graphique.

## Conséquences

L’application diagnostique peut être compilée avec SwiftPM et signée ad hoc pour vérifier son bundle et son interface. Cette signature ne doit pas être utilisée pour conclure à la stabilité des autorisations TCC entre deux builds.

Avant le ticket de filtrage actif, installer et sélectionner une version complète de Xcode, puis rendre disponible une identité Apple Development ou Developer ID Application stable. L’identité doit être fournie au script de build sans être inscrite en dur dans les sources.

## Confidentialité

Le diagnostic lit uniquement des métadonnées système locales et les états booléens de pré-vérification des permissions. Il n’active aucun tap, ne demande aucune autorisation, ne capture aucune frappe et n’effectue aucun accès réseau.
