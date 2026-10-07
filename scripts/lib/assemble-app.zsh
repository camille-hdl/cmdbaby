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

    # Sparkle (#102). L’app n’est pas sandboxée : ses services XPC sont inutiles et retirés,
    # comme le permet la documentation Sparkle (« Sandboxing »).
    if [[ ! -d "$binary_dir/Sparkle.framework" ]]; then
        print -u2 "Sparkle.framework introuvable dans $binary_dir"
        return 1
    fi
    mkdir -p "$contents/Frameworks"
    rm -rf "$contents/Frameworks/Sparkle.framework"
    ditto "$binary_dir/Sparkle.framework" "$contents/Frameworks/Sparkle.framework"
    rm -rf "$contents/Frameworks/Sparkle.framework/Versions/B/XPCServices" \
        "$contents/Frameworks/Sparkle.framework/XPCServices"
    if ! otool -l "$contents/MacOS/CmdBaby" | grep -q "@executable_path/../Frameworks"; then
        install_name_tool -add_rpath "@executable_path/../Frameworks" "$contents/MacOS/CmdBaby"
    fi
}

# sign_sparkle <identité> <chemin du .app> [options de codesign…]
# Signe Sparkle de l’intérieur vers l’extérieur, sans --deep, avant l’app,
# avec les mêmes options que l’app (hardened runtime, horodatage).
sign_sparkle() {
    local identity="$1" app_path="$2"
    shift 2
    local framework="$app_path/Contents/Frameworks/Sparkle.framework"
    local item
    for item in "$framework/Versions/B/Autoupdate" "$framework/Versions/B/Updater.app" "$framework"; do
        codesign --force --sign "$identity" "$@" "$item"
    done
}

# compile_app_icon <racine du projet> <chemin du .app> <required|optional>
# Compile Resources/AppIcon.icon (Icon Composer) avec actool : Assets.car pour macOS 26
# (Jour, Nuit, Transparent, Teinté) et AppIcon.icns statique (Jour) pour macOS 13 à 15.
compile_app_icon() {
    local project_dir="$1" app_path="$2" mode="$3"
    if ! xcrun --find actool >/dev/null 2>&1; then
        if [[ "$mode" == required ]]; then
            print -u2 "actool introuvable : installer Xcode 26 ou plus récent (icône de l’app requise pour publier)."
            return 1
        fi
        print -u2 "Avertissement : actool introuvable (Xcode absent), l’app n’aura pas d’icône."
        return 0
    fi
    local partial
    partial=$(mktemp "${TMPDIR:-/tmp}/cmdbaby-icon.XXXXXX")
    xcrun actool "$project_dir/Resources/AppIcon.icon" \
        --compile "$app_path/Contents/Resources" \
        --platform macosx --minimum-deployment-target 13.0 \
        --app-icon AppIcon --output-partial-info-plist "$partial" >/dev/null
    rm -f "$partial"
    if [[ ! -f "$app_path/Contents/Resources/Assets.car" || ! -f "$app_path/Contents/Resources/AppIcon.icns" ]]; then
        print -u2 "actool n’a pas produit Assets.car et AppIcon.icns."
        return 1
    fi
}
