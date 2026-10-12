#!/bin/zsh
# build-app.sh signe par défaut avec l’identité Apple Development, sinon ad hoc.
set -euo pipefail

script_dir=${0:A:h}
source "$script_dir/lib/assemble-app.zsh"

expect_exact() {
    local label="$1" expected="$2" actual="$3"
    if [[ "$actual" != "$expected" ]]; then
        print -u2 "Échec : $label"
        print -u2 "attendu : ${expected:-<vide>}"
        print -u2 "obtenu  : ${actual:-<vide>}"
        exit 1
    fi
}

both='  1) 1111111111111111111111111111111111111111 "Developer ID Application: Jane Doe (TEAMID1234)"
  2) 2222222222222222222222222222222222222222 "Apple Development: jane@example.com (ABCDE12345)"
     2 valid identities found'

expect_exact \
    "Apple Development est préférée à Developer ID" \
    "Apple Development: jane@example.com (ABCDE12345)" \
    "$(development_signing_identity <<<"$both")"

expect_exact \
    "sans Apple Development, signature ad hoc" \
    "-" \
    "$(development_signing_identity <<<'  1) 1111111111111111111111111111111111111111 "Developer ID Application: Jane Doe (TEAMID1234)"
     1 valid identities found')"

expect_exact \
    "sans aucune identité, signature ad hoc" \
    "-" \
    "$(development_signing_identity <<<'     0 valid identities found')"

print "OK"
