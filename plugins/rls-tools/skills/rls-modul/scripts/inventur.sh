#!/usr/bin/env bash
# Inventur des Real Life Stack — was ist HEUTE im Repo vorhanden.
#
# Dieses Skript ist die Wahrheit ueber den Bestand. Die Landkarte in
# reference/bestand.md ordnet nur ein; Namen kommen von hier.
#
# Aufruf:  ./inventur.sh [pfad-zum-real-life-stack]
# Ohne Argument wird der Pfad gesucht (RLS_REPO, cwd, uebliche Orte).

set -uo pipefail

find_repo() {
  if [ $# -ge 1 ] && [ -n "${1:-}" ]; then echo "$1"; return; fi
  if [ -n "${RLS_REPO:-}" ]; then echo "$RLS_REPO"; return; fi
  # von cwd aufwaerts
  d=$(pwd)
  while [ "$d" != "/" ]; do
    if [ -f "$d/packages/data-interface/src/vocab.ts" ]; then echo "$d"; return; fi
    d=$(dirname "$d")
  done
  for c in ~/workspace/workspace/real-life-stack ~/workspace/real-life-stack ~/real-life-stack ./real-life-stack; do
    if [ -f "$c/packages/data-interface/src/vocab.ts" ]; then echo "$c"; return; fi
  done
  echo ""
}

REPO=$(find_repo "${1:-}")
if [ -z "$REPO" ]; then
  echo "FEHLER: real-life-stack nicht gefunden." >&2
  echo "Aufruf: inventur.sh /pfad/zum/real-life-stack   (oder RLS_REPO setzen)" >&2
  exit 1
fi
cd "$REPO" || exit 1

h() { printf '\n== %s ==\n' "$1"; }

printf 'Real Life Stack — Inventur\nRepo: %s\nBranch: %s\nStand: %s\n' \
  "$REPO" "$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')" "$(git log -1 --format=%cs 2>/dev/null || echo '?')"

h "Vokabulare (Schema-Library)"
ls docs/spec/schemas/vocab/ 2>/dev/null | tr '\n' ' '; echo
grep -h '^export const VOCAB_' packages/data-interface/src/vocab.ts 2>/dev/null | sed 's/export const /  /'

h "Aktivierungsregeln (welches Feld zieht welches Vokabular)"
sed -n '/^ \* Activation rules:/,/^ \*\//p' packages/data-interface/src/vocab.ts 2>/dev/null | sed 's/^ \* \?//' | sed '/^\/$/d'

h "Item-Typen (Typ-Manifest — einzige Quelle fuer Typ-Identitaet)"
grep -n 'id: "' packages/data-interface/src/type-manifest.ts 2>/dev/null | sed 's/^/  /'

h "Relations-Affordances im Manifest"
grep -n 'predicate: "' packages/data-interface/src/type-manifest.ts 2>/dev/null | sed 's/^/  /' | head -40

h "Darstellungs-Register (wer registriert was)"
grep -rn 'registerTypePresentation' packages/toolkit/src apps/*/src 2>/dev/null | sed 's/^/  /'

h "Composer-Widgets (WidgetType)"
sed -n '/^export type WidgetType/,/^$/p' packages/toolkit/src/components/composer/content-composer.tsx 2>/dev/null | sed 's/^/  /'

h "Toolkit-Komponenten (nach Ordner)"
for d in packages/toolkit/src/components/*/; do
  n=$(basename "$d")
  f=$(ls "$d" 2>/dev/null | grep -v -e '\.stories\.' -e '^index.ts$' | tr '\n' ' ')
  printf '  %-16s %s\n' "$n" "$f"
done

h "Toolkit-Hooks"
ls packages/toolkit/src/hooks/ 2>/dev/null | sed 's/\.tsx\?$//' | grep -v '^index$' | tr '\n' ' '; echo

h "Toolkit-Helfer (lib)"
ls packages/toolkit/src/lib/ 2>/dev/null | tr '\n' ' '; echo

h "Data-Interface (Datei-Ebene)"
ls packages/data-interface/src/ 2>/dev/null | tr '\n' ' '; echo

h "Connector-Capabilities"
grep -n '^| `' docs/spec/03-capabilities.md 2>/dev/null | sed 's/^/  /'

h "ItemFilter (was abgefragt werden KANN — alles andere ist clientseitig)"
sed -n '/^interface ItemFilter/,/^}/p' docs/spec/02-data-interface.md 2>/dev/null | sed 's/^/  /'

h "Bestehende Modul-Specs"
ls docs/spec/modules/ 2>/dev/null | tr '\n' ' '; echo

h "Module in der Reference-App"
grep -n 'VALID_MODULES' apps/reference/src/hooks/use-workspace-routing.ts 2>/dev/null | sed 's/^/  /'
ls apps/reference/src/views/ 2>/dev/null | grep -v test | tr '\n' ' '; echo

h "Linsen (read-only Darstellungen)"
ls packages/toolkit/src/components/lens/ 2>/dev/null | grep -v '\.stories\.' | tr '\n' ' '; echo

h "Connectoren"
ls packages/ 2>/dev/null | grep connector | tr '\n' ' '; echo

printf '\nLies vor jedem Vorschlag mindestens: docs/spec/06-schema-composition.md,\ndocs/spec/01-app-composition.md, docs/spec/modules/template.md,\ndocs/spec/modules/shared-components.md\n'
