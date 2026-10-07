# Assemblage du .app, partagé par build-app.sh (développement) et release.sh (publication).
# À sourcer. Ne signe rien.

# assemble_app <dossier des produits swift build> <racine du projet> <chemin du .app>
# Copie l’exécutable, l’Info.plist, le manifeste de confidentialité et les bundles de ressources
# de l’app et du kit dans Contents/Resources (codesign interdit les bundles à la racine du .app).
assemble_app() {
    local binary_dir="$1" project_dir="$2" app_path="$3"
    local contents="$app_path/Contents"

    mkdir -p "$contents/MacOS" "$contents/Resources"
    install -m 755 "$binary_dir/CmdBaby" "$contents/MacOS/CmdBaby"
    install -m 644 "$project_dir/Resources/CmdBaby-Info.plist" "$contents/Info.plist"
    install -m 644 "$project_dir/Resources/PrivacyInfo.xcprivacy" "$contents/Resources/PrivacyInfo.xcprivacy"

    local name
    for name in CmdBaby_CmdBaby.bundle CmdBaby_CmdBabyKit.bundle; do
        if [[ ! -d "$binary_dir/$name" ]]; then
            print -u2 "Bundle de ressources introuvable : $binary_dir/$name"
            return 1
        fi
        rm -rf "$app_path/$name" "$contents/Resources/$name"
        cp -R "$binary_dir/$name" "$contents/Resources/$name"
    done
}
