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

# true si swiftc documente l’option (driver ou frontend). On ne la passe jamais
# à `swift build` directement : un argument qui commence par « - » n’est pas
# une option de SwiftPM, seulement une valeur de -Xswiftc.
_swiftc_documents() {
    local flag="$1" out
    out=$(swiftc -help 2>&1 || true)
    out+=$'\n'"$(swiftc -help-hidden 2>&1 || true)"
    out+=$'\n'"$(swiftc -frontend -help 2>&1 || true)"
    out+=$'\n'"$(swiftc -frontend -help-hidden 2>&1 || true)"
    [[ "$out" == *"$flag"* ]]
}

# Remplit le tableau global app_intents_swift_flags.
# Sans -const-gather-protocols-file, aucun .swiftconstvalues n’est émis et
# l’installation des métadonnées s’arrête.
# Noms courts de protocoles : ConstExtract les compare à getName().
# AppEnum est requis dès qu’un paramètre a ce type : sinon l’extracteur ne
# connaît pas Optional<StartSessionMode>.
prepare_app_intents_swift_flags() {
    local project_dir="$1"
    typeset -g -a app_intents_swift_flags
    app_intents_swift_flags=()
    if ! _swiftc_documents "-const-gather-protocols-file"; then
        print -u2 "Ce swiftc ignore -const-gather-protocols-file : pas de .swiftconstvalues."
        return 0
    fi
    # Chaque -Xswiftc ne transmet qu’un argument, y compris ceux qui commencent par « - ».
    app_intents_swift_flags=(
        -Xswiftc -emit-const-values
        -Xswiftc -Xfrontend
        -Xswiftc -const-gather-protocols-file
        -Xswiftc -Xfrontend
        -Xswiftc "$project_dir/Resources/app-intents-protocols.json"
    )
}

# install_app_intents_metadata <dossier des produits swift build> <racine du projet> <chemin du .app>
# Produit Contents/Resources/Metadata.appintents sans projet Xcode.
#
# Commande retenue (une architecture, les const values sont identiques) :
#   xcrun appintentsmetadataprocessor \
#     --toolchain-dir "$TOOLCHAIN" \
#     --module-name CmdBaby \
#     --sdk-root "$SDK" \
#     --xcode-version "$XCODE_BUILD" \
#     --platform-family macOS \
#     --deployment-target 13.0 \
#     --bundle-identifier "$BUNDLE_ID" \
#     --output "$OUT" \
#     --target-triple "${ARCH}-apple-macos13.0" \
#     --binary-file "$BINARY" \
#     --source-file-list "$SOURCES" \
#     --swift-const-vals-list "$CONSTS" \
#     --compile-time-extraction \
#     --deployment-aware-processing \
#     --force
# L’outil écrit $OUT/Metadata.appintents. --force évite le court-circuit
# « pas de dépendance AppIntents » quand aucun fichier de dépendances n’est fourni.
install_app_intents_metadata() {
    local binary_dir="$1" project_dir="$2" app_path="$3"
    local work

    if ! xcrun --find appintentsmetadataprocessor >/dev/null 2>&1; then
        print -u2 "appintentsmetadataprocessor introuvable : installer Xcode (métadonnées Raccourcis requises)."
        return 1
    fi

    work=$(mktemp -d "${TMPDIR:-/tmp}/cmdbaby-appintents.XXXXXX")
    # Pas de trap ici : release.sh en a déjà un, et un trap de fonction le remplacerait.
    if ! _install_app_intents_metadata "$binary_dir" "$project_dir" "$app_path" "$work"; then
        rm -rf "$work"
        return 1
    fi
    rm -rf "$work"
}

_install_app_intents_metadata() {
    local binary_dir="$1" project_dir="$2" app_path="$3" work="$4"
    local info="$app_path/Contents/Info.plist"
    local arch bundle_id developer_dir toolchain sdk xcode_version
    local processor_binary sources_list const_list out produced const_file

    arch=$(_app_intents_arch "$binary_dir/CmdBaby")
    bundle_id=$(/usr/bin/plutil -extract CFBundleIdentifier raw -o - "$info")
    developer_dir=$(xcode-select -p)
    toolchain="$developer_dir/Toolchains/XcodeDefault.xctoolchain"
    sdk=$(xcrun --sdk macosx --show-sdk-path)
    xcode_version=$(xcodebuild -version | awk '/Build version/ { print $3 }')
    [[ -n "$xcode_version" ]] || { print -u2 "Version de build Xcode introuvable."; return 1 }

    processor_binary="$work/CmdBaby"
    if [[ $(lipo -archs "$binary_dir/CmdBaby" | wc -w | tr -d ' ') -gt 1 ]]; then
        lipo "$binary_dir/CmdBaby" -thin "$arch" -output "$processor_binary" || return 1
    else
        cp "$binary_dir/CmdBaby" "$processor_binary"
    fi

    sources_list="$work/sources.txt"
    find "$project_dir/Sources/CmdBaby" -name '*.swift' -type f | sort > "$sources_list"
    [[ -s "$sources_list" ]] || { print -u2 "Aucune source Swift pour CmdBaby."; return 1 }

    const_list="$work/const-values.txt"
    if ! _app_intents_const_values "$project_dir" "$binary_dir" "$arch" > "$const_list"; then
        return 1
    fi
    out="$work/out"
    mkdir -p "$out"
    local -a processor_flags
    processor_flags=(
        --toolchain-dir "$toolchain"
        --module-name CmdBaby
        --sdk-root "$sdk"
        --xcode-version "$xcode_version"
        --platform-family macOS
        --deployment-target 13.0
        --bundle-identifier "$bundle_id"
        --output "$out"
        --target-triple "${arch}-apple-macos13.0"
        --binary-file "$processor_binary"
        --source-file-list "$sources_list"
        --deployment-aware-processing
        --swift-const-vals-list "$const_list"
        --compile-time-extraction
        --force
    )
    print -r -- "xcrun appintentsmetadataprocessor --module-name CmdBaby --target-triple ${arch}-apple-macos13.0 --compile-time-extraction --swift-const-vals-list <${arch} .swiftconstvalues> --force"
    xcrun appintentsmetadataprocessor "${processor_flags[@]}" || return 1

    produced="$out/Metadata.appintents"
    if [[ ! -d "$produced" && -f "$out/extract.actionsdata" ]]; then
        produced="$out"
    fi
    if [[ ! -s "$produced/extract.actionsdata" ]]; then
        print -u2 "appintentsmetadataprocessor n’a pas écrit Metadata.appintents/extract.actionsdata."
        return 1
    fi
    if ! grep -a -q "StartSessionIntent" "$produced/extract.actionsdata"; then
        print -u2 "Les métadonnées App Intents ne mentionnent pas StartSessionIntent."
        return 1
    fi

    rm -rf "$app_path/Contents/Resources/Metadata.appintents"
    cp -R "$produced" "$app_path/Contents/Resources/Metadata.appintents"

    # Raccourcis lit le catalogue du bundle principal, pas CmdBaby_CmdBaby.bundle.
    local lang src_lproj
    for lang in en fr; do
        src_lproj="$project_dir/Sources/CmdBaby/Resources/$lang.lproj"
        [[ -d "$src_lproj" ]] || { print -u2 "Catalogue Raccourcis manquant : $src_lproj"; return 1 }
        rm -rf "$app_path/Contents/Resources/$lang.lproj"
        cp -R "$src_lproj" "$app_path/Contents/Resources/$lang.lproj"
    done
}

# Fichiers .swiftconstvalues de la configuration et de l’architecture compilées.
# binary_dir est `swift build --show-bin-path`.
# Un binaire universel est dans `.build/apple/Products/<Config>` (casse conservée) ;
# ses const values sont sous Intermediates.noindex, pas sous un triplet.
# Une liste vide arrête l’assemblage : pas d’extraction depuis les sources.
_app_intents_const_values() {
    local project_dir="$1" binary_dir="$2" arch="$3"
    local configuration="${binary_dir:t}"
    local search_root path_filter files
    if [[ "$binary_dir" == */apple/Products/* ]]; then
        search_root="$project_dir/.build/apple/Intermediates.noindex"
        path_filter="*/${configuration}/*/Objects-normal/${arch}/*"
    else
        search_root="$project_dir/.build"
        path_filter="*${arch}-apple-macos*/${configuration}/*"
    fi
    if [[ -d "$search_root" ]]; then
        files=$(find "$search_root" -name '*.swiftconstvalues' -path "$path_filter" | sort)
    fi
    if [[ -z "${files:-}" ]]; then
        print -u2 "Aucun .swiftconstvalues pour l’architecture ${arch} et la configuration ${configuration}."
        return 1
    fi
    print -r -- "$files"
}

# Architecture préférée pour l’extraction : les const values ne dépendent pas du binaire.
_app_intents_arch() {
    local binary="$1" archs
    archs=$(lipo -archs "$binary" 2>/dev/null || true)
    if [[ "$archs" == *arm64* ]]; then
        print -r -- arm64
    elif [[ "$archs" == *x86_64* ]]; then
        print -r -- x86_64
    else
        print -r -- arm64
    fi
}
