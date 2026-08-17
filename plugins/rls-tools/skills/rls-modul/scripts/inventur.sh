#!/usr/bin/env bash
# Inventur des Real Life Stack — was ist HEUTE im Repo vorhanden.
#
# Dieses Skript ist die Wahrheit ueber den Bestand. Die Landkarte in
# reference/bestand.md ordnet nur ein; Namen kommen von hier.
#
# Aufruf:  ./inventur.sh [pfad-zum-real-life-stack]
# Ohne Argument wird der Pfad gesucht (cwd aufwaerts, uebliche Orte).

set -uo pipefail

# Ein Pfad ist nur dann DER Stack, wenn alle Marker stimmen. Die Namenspruefung
# unterscheidet ihn von einem beliebigen anderen pnpm-Monorepo.
is_repo() {
  [ -d "$1" ] || return 1
  [ -f "$1/packages/data-interface/src/vocab.ts" ] || return 1
  [ -d "$1/packages/toolkit/src" ] || return 1
  [ -d "$1/docs/spec" ] || return 1
  [ -f "$1/package.json" ] || return 1
  grep -q '"name": *"real-life-stack"' "$1/package.json" 2>/dev/null || return 1
  return 0
}

find_repo() {
  if [ $# -ge 1 ] && [ -n "${1:-}" ]; then echo "$1"; return; fi
  # von cwd aufwaerts
  d=$(pwd)
  while [ "$d" != "/" ]; do
    if is_repo "$d"; then echo "$d"; return; fi
    d=$(dirname "$d")
  done
  for c in ~/workspace/workspace/real-life-stack ~/workspace/real-life-stack ~/real-life-stack ./real-life-stack; do
    if is_repo "$c"; then echo "$c"; return; fi
  done
  echo ""
}

REPO=$(find_repo "${1:-}")
if [ -z "$REPO" ]; then
  echo "FEHLER: real-life-stack nicht gefunden." >&2
  echo "Aufruf: inventur.sh /pfad/zum/real-life-stack" >&2
  exit 1
fi
# Auch ein ausdruecklich uebergebener Pfad wird geprueft — sonst laeuft die
# Inventur auf einem beliebigen Verzeichnis durch und meldet leere Abschnitte
# als "nichts vorhanden".
if ! is_repo "$REPO"; then
  echo "FEHLER: '$REPO' ist kein real-life-stack." >&2
  echo "Erwartet: package.json mit name real-life-stack, packages/data-interface/src/vocab.ts," >&2
  echo "          packages/toolkit/src/ und docs/spec/" >&2
  echo "Falls das Repo fehlt: git clone https://github.com/real-life-org/real-life-stack.git" >&2
  exit 2
fi
cd "$REPO" || exit 1
# Absoluter, aufgeloester Pfad — den merkt sich der Skill fuer ALLE weiteren
# Befehle, damit spaetere Reads, Edits, pnpm- und git-Aufrufe nicht in einem
# anderen Checkout landen.
REPO=$(pwd -P)

# Exit-Codes: 0 = vollstaendig · 1 = Repo nicht gefunden · 2 = falscher Pfad
#             3 = Inventur DEGRADIERT (repo-eigene Quelle da, aber kaputt)

# Wenn das Repo selbst eine maschinenlesbare Inventur mitbringt, hat sie
# Vorrang: sie ist versioniert, kennt mehrzeilige Deklarationen und wandert
# mit Umbauten mit. Das Ableiten per grep unten ist der Fallback fuer aeltere
# Staende — aber NICHT der stille Ersatz fuer eine kaputte Quelle.
# Remote-Lage. Wird von BEIDEN Inventur-Pfaden gebraucht (Phase 4 entscheidet
# daran ueber Branch-Basis und PR-Ziel), darum als Funktion.
remotes_block() {
  printf '\n== Remotes (entscheidet ueber Fork- vs. Direkt-Workflow) ==\n'
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "  (kein git-Repo)"
    return
  fi
  git remote -v 2>/dev/null | sed 's/^/  /'
  # Der Remote, der auf real-life-org zeigt, ist die Quelle der Wahrheit —
  # egal ob er origin oder upstream heisst. Er liefert die Branch-Basis und
  # ist das PR-Ziel.
  up=$(git remote -v 2>/dev/null | awk '/real-life-org\/real-life-stack.*fetch/ {print $1; exit}')
  printf '  Remote auf real-life-org: %s\n' "${up:-(keiner — Upstream fehlt oder anderes Projekt)}"
  printf '  Branch-Basis: %s\n' "${up:-?}/master"
  printf '  ACHTUNG: Eine Remote-URL sagt NICHTS ueber Schreibrechte.\n'
  printf '           Push-Ziel erst pruefen (siehe SKILL.md Phase 4), nicht annehmen.\n'
}

DEGRADIERT=0
if [ -f "scripts/inventory.mjs" ] && ! command -v node >/dev/null 2>&1; then
  DEGRADIERT=1
  cat <<'WARN'
!! WARNUNG — INVENTUR DEGRADIERT !!
Das Repo bringt scripts/inventory.mjs mit, aber `node` ist in dieser Shell
nicht im PATH. Setz den PATH und ruf die Inventur erneut auf, statt der
Ersatz-Inventur unten zu vertrauen.
WARN
elif [ -f "scripts/inventory.mjs" ]; then
  # Nicht nur "ist JSON": {} und [] sind gueltiges JSON und waeren eine LEERE
  # Inventur — der Skill wuerde daraus "es gibt nichts" lesen und alles neu
  # bauen. Verlangt wird ein Objekt mit mehreren Abschnitten, von denen
  # mindestens einer wirklich etwas enthaelt.
  #
  # OFFEN: Das ist die Untergrenze, nicht der Vertrag. Wenn
  # scripts/inventory.mjs im Repo eingefuehrt wird, gehoert dort ein
  # versioniertes Schema dazu (`version` plus benannte Pflichtabschnitte),
  # und diese Pruefung wird dagegen geschaerft. Bis dahin bleibt sie
  # bewusst strukturell, damit sie keine Feldnamen erfindet.
  if out=$(node scripts/inventory.mjs --json 2>/dev/null) \
     && printf '%s' "$out" | node -e '
let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{
  let o; try { o = JSON.parse(s) } catch { process.exit(1) }
  if (!o || typeof o !== "object" || Array.isArray(o)) process.exit(1)
  const keys = Object.keys(o)
  if (keys.length < 3) process.exit(1)
  const gefuellt = keys.some(k => {
    const v = o[k]
    if (Array.isArray(v)) return v.length > 0
    if (v && typeof v === "object") return Object.keys(v).length > 0
    return typeof v === "string" && v.length > 0
  })
  process.exit(gefuellt ? 0 : 1)
})'; then
    echo "Inventur aus dem Repo (scripts/inventory.mjs) — verifizierter Pfad: $REPO"
    printf '%s\n' "$out"
    # Auch hier noetig: das Repo-Skript kennt den Bestand, aber nicht die
    # lokale Remote-Lage dieses Checkouts.
    remotes_block
    printf '\n== Verifizierter Repo-Pfad (ins Manifest uebernehmen) ==\nrepo: %s\n' "$REPO"
    exit 0
  fi
  DEGRADIERT=1
  # Bewusst nach stdout, nicht nur stderr: der Fallback darf nicht wie eine
  # normale, vollstaendige Inventur aussehen.
  cat <<'WARN'
!! WARNUNG — INVENTUR DEGRADIERT !!
scripts/inventory.mjs ist vorhanden, liefert aber keine brauchbare Inventur
(kein gueltiges JSON, oder ein leeres bzw. inhaltsloses Objekt).
Was unten folgt, ist die abgeleitete Ersatz-Inventur: sie liest per grep und
kann mehrzeilige Deklarationen und neuere Strukturen uebersehen. Fehlende
Abschnitte bedeuten hier NICHT "nichts vorhanden".
Melde das dem Nutzer, bevor du auf dieser Grundlage etwas vorschlaegst.
WARN
fi

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

h "Modul-Listen — ALLE Stellen, an denen ein Modul angemeldet sein muss"
# Ein Modul, das nur in einer davon steht, funktioniert nur halb: fehlt es in
# AVAILABLE_MODULES, laesst es sich in KEINEM Space aktivieren und erscheint
# nur in der Uebersicht.
printf '  -- Toolkit, Space-Dialog (entscheidet ueber Aktivierbarkeit) --\n'
sed -n '/^const AVAILABLE_MODULES/,/as const/p' packages/toolkit/src/components/layout/group-dialog.tsx 2>/dev/null | sed 's/^/    /'
printf '  -- App, Routing --\n'
grep -n 'VALID_MODULES = ' apps/reference/src/hooks/use-workspace-routing.ts 2>/dev/null | sed 's/^/    /'
printf '  -- App, Labels --\n'
sed -n '/^const MODULE_LABELS/,/^}/p' apps/reference/src/hooks/use-workspace-routing.ts 2>/dev/null | sed 's/^/    /'
printf '  -- App, Dispatch --\n'
grep -c 'activeModule ===' apps/reference/src/views/module-outlet.tsx 2>/dev/null | sed 's/^/    Zweige: /'
printf '  -- App, Notification-Fallback --\n'
grep -n 'group.data.modules as string\[\]' apps/reference/src/notification-navigation.ts 2>/dev/null | sed 's/^/    /'

h "Views in der Reference-App"
ls apps/reference/src/views/ 2>/dev/null | grep -v test | tr '\n' ' '; echo

h "Linsen (read-only Darstellungen)"
ls packages/toolkit/src/components/lens/ 2>/dev/null | grep -v '\.stories\.' | tr '\n' ' '; echo

h "Connectoren"
ls packages/ 2>/dev/null | grep connector | tr '\n' ' '; echo

remotes_block

printf '\nLies vor jedem Vorschlag mindestens: docs/spec/06-schema-composition.md,\ndocs/spec/01-app-composition.md, docs/spec/modules/template.md,\ndocs/spec/modules/shared-components.md\n'

# Der Pfad gehoert ins Manifest, NICHT in eine Shell-Variable — die ueberlebt
# den naechsten Befehl nicht.
printf '\n== Verifizierter Repo-Pfad (ins Manifest uebernehmen) ==\nrepo: %s\n' "$REPO"

if [ "$DEGRADIERT" = "1" ]; then
  printf '\n!! Diese Inventur war DEGRADIERT (Exit 3) — siehe Warnung oben. !!\n'
  exit 3
fi
