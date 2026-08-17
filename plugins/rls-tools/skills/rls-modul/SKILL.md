---
name: rls-modul
argument-hint: [kurze Beschreibung des gewünschten Moduls]
description: >
  Baut ein neues Space Module (bzw. eine Linse) im Real Life Stack — von der
  Anforderung über Datenmodell und Modul-Spec bis zu Toolkit-Komponenten,
  Dev-Server-Test und PR. Nutze diesen Skill, wenn jemand sagt "ich hätte
  gern ein Modul für X", "neue Linse", "eigene Ansicht im RLS", "neuer
  Item-Typ", "neues Vokabular" oder ähnlich.
allowed-tools: [Read, Grep, Glob]
---

# RLS-Modul bauen

Du baust mit dem Nutzer zusammen ein **Space Module** (oder eine **Linse**) für den Real Life Stack. Das Ergebnis ist ein PR im Repo `real-life-org/real-life-stack`, den Anton reviewt.

Der Nutzer ist meistens **nicht** der Architekt des Stacks. Deine Aufgabe ist es, seine Anforderung in die bestehende Architektur zu übersetzen und sie dabei **auf das zu begrenzen, was der Stack heute trägt** — nicht, neben ihm her eine zweite Welt zu bauen.

**Sprache:** Deutsch, im Dialog wie in Spec, Code-Kommentaren und PR.

## Die zwei Leitplanken

Alles in diesem Skill hängt an zwei Sätzen:

1. **Bestand vor Neubau.** Was es gibt, wird benutzt. Neues entsteht nur gegen eine konkret geprüfte und benannte Lücke — nie mit „es gibt nichts Passendes".
2. **Zuschnitt vor Ehrgeiz.** Ein Modul, das die heutigen Kapazitäten des Stacks übersteigt, wird nicht dadurch machbar, dass man es sorgfältiger baut. Dann wird der Wunsch kleiner geschnitten, nicht der Stack umgebaut.

Du bist an diesen beiden Stellen **nicht dienstleistend**. Sag früh und freundlich, was nicht geht, und biete den Schnitt an, der geht.

Mitgeliefertes Material in diesem Skill-Verzeichnis (unter `${CLAUDE_PLUGIN_ROOT}/skills/rls-modul/`):

- `scripts/inventur.sh` — gibt aus, was **heute** im Repo vorhanden ist
- `reference/bestand.md` — Landkarte Bedarf → vorhandener Baustein
- `reference/grenzen.md` — was der Stack nicht trägt, plus Verkleinerungs-Muster

## Zwei Dinge, die der Skill nicht vorab freigibt

**Shell-Befehle laufen durch die normale Rückfrage.** Das Frontmatter gibt bewusst nur `Read`, `Grep` und `Glob` frei. Alles, was schreibt oder ausführt — `Bash`, `Write`, `Edit` — geht durch den regulären Genehmigungsweg. Das ist Absicht: dieser Skill baut fremden Code und erzeugt am Ende einen PR.

**Push und PR-Erstellung fragst du zusätzlich ausdrücklich.** Sie wirken nach außen und sind nicht ohne Weiteres zurückzunehmen. Auch wenn der Nutzer mit dem Modul zufrieden ist, ist das noch **keine** Freigabe zum Veröffentlichen — hol sie als eigene Frage ein (Phase 7).

## Der Repo-Pfad wird einmal bestimmt und dann festgehalten

Sobald `inventur.sh` einen Pfad verifiziert hat, gibt es genau **einen** gültigen Arbeitsort. Merk ihn dir als `RLS_REPO` (das Skript gibt ihn am Ende als `RLS_REPO=…` aus) und benutz ihn in **jedem** weiteren Befehl explizit:

```bash
RLS_REPO=/verifizierter/pfad/aus/der/inventur     # einmal setzen

git -C "$RLS_REPO" status                          # git immer mit -C
pnpm -C "$RLS_REPO" test                           # pnpm immer mit -C
sed -n '1,80p' "$RLS_REPO/docs/spec/06-schema-composition.md"
```

Verlass dich **nie** auf ein Arbeitsverzeichnis: Jede Shell-Zelle kann woanders starten, und auf dieser Maschine liegen oft mehrere Checkouts und Worktrees desselben Projekts nebeneinander. Ein `pnpm test` oder `git checkout` im falschen Checkout trifft fremde Arbeit. Auch Datei-Lesen und -Schreiben laufen über den vollen Pfad unter `$RLS_REPO`.

## Phase 0 — Repo finden und Inventur ableiten

**Pflicht, bevor du irgendetwas vorschlägst.** Handlisten driften lautlos; leite den Bestand jedes Mal frisch aus dem Repo ab.

```bash
# 1. Repo finden (Default-Branch: master). Falls es nicht lokal liegt:
#    git clone https://github.com/real-life-org/real-life-stack.git
find ~ -maxdepth 4 -type d -name real-life-stack 2>/dev/null | head

# 2. Inventur. Das Skript prueft den Pfad und bricht mit Exit 2 ab,
#    wenn dort nicht wirklich der Stack liegt.
"$CLAUDE_PLUGIN_ROOT/skills/rls-modul/scripts/inventur.sh" "$RLS_REPO"
```

Setz `RLS_REPO` vorher auf den gefundenen Pfad. Findet `find` mehrere Treffer — auf Entwicklungsmaschinen liegen oft Worktrees und Fix-Checkouts nebeneinander — dann **frag den Nutzer, welcher gemeint ist**, statt den ersten zu nehmen. Läuft das Skript mit Exit 2, ist der Pfad falsch: nicht weiterarbeiten, sondern klären.

Lies danach `reference/bestand.md` und `reference/grenzen.md` aus diesem Skill — sie ordnen die Skript-Ausgabe ein. Bei Widerspruch gilt das Skript.

Und lies im Repo — nicht überfliegen, wirklich lesen:

- `docs/spec/06-schema-composition.md` (Vokabulare, `type`, Typ-Register) — das wichtigste Dokument für diesen Skill
- `docs/spec/01-app-composition.md` (App Shell vs. Space Module vs. Module Component, Overlay-Ebenen)
- `docs/spec/modules/README.md` + `docs/spec/modules/template.md`
- `docs/spec/modules/shared-components.md` (die geteilten Bausteine im Detail)
- `docs/spec/code-and-storybook-mapping.md` (wo Code hingehört, wie Stories heißen)
- die Spec des ähnlichsten bestehenden Moduls (Feed / Kanban / Calendar / Map / Resonance)

## Phase 1 — Anforderung aufnehmen

Frag im Gespräch, in eigenen Worten, kurz und einladend. Kein Fragebogen, keine Auswahl-Dialoge — normaler Chat.

Was du am Ende wissen musst:

- **Welche wiederkehrende Nutzung** soll das Modul tragen? (Nicht „was soll es können", sondern „was macht jemand damit immer wieder")
- **Welche Dinge** kommen darin vor, und **welche Angaben** hängen an jedem Ding?
- **Wie hängen die Dinge zusammen?** (gehört zu, ist zugewiesen an, blockiert …)
- **Wie soll man sie sehen?** Liste / Grid / Karte / Kalender / Board / etwas Eigenes?
- **Was soll man tun können?** (Erstellen, Bearbeiten, Zuweisen, Bestätigen …)
- **Wie viele Dinge** werden das realistisch, und **wie viele Menschen** nutzen es?

**Ist es überhaupt ein Modul?** Prüf das explizit:

| Wunsch | Das ist … |
|---|---|
| Profile, Kontakte, Verifikation, Auth, Benachrichtigungen, Debug | eine **App-Shell-Fläche**, kein Space Module |
| Eine andere Darstellung vorhandener Items | eine **Linse** (`components/lens/`) — Bruchteil des Aufwands |
| Ein Baustein, der in mehreren Modulen vorkommt | eine **Module Component** im Toolkit |
| Eine abgetrennte Sichtbarkeit für eine Teilgruppe | ein eigener **Space**, kein Modul |

Spiegele die Anforderung einmal in deinen Worten zurück, bevor du weitermachst.

## Phase 2 — Zuschnitt begrenzen

**Diese Phase überspringst du nie**, auch wenn der Wunsch harmlos klingt. Geh `reference/grenzen.md` durch und prüf den Wunsch dagegen. Die häufigsten Anschläge:

- Auswertung, Summen, Ranglisten über große Mengen → keine Aggregation im Vertrag, nur clientseitige Arbeit auf geladenen Items
- Suche über alles → keine Volltextsuche im Vertrag
- Erinnerungen, E-Mails, zeitgesteuerte Automatik → ein Modul darf keinen rechnenden Server voraussetzen
- Genehmigungsketten, Rollen, Feldrechte → Autorisierung ist grob und optional, Sichtbarkeit läuft über Spaces
- Mehrstufige Wizards in gestapelten Panels → eine Overlay-Fläche pro Ebene

Merksatz: Ein Modul läuft gegen **jeden** Connector (`local`, `mock`, `supabase`, `graphql`, `wot`). Was ein einzelnes Backend zusätzlich kann, darf nie Voraussetzung werden.

Wenn etwas anschlägt, führ das Gespräch über die fünf Verkleinerungs-Fragen aus `reference/grenzen.md`:

1. Was ist die **eine** Sache, die jemand damit immer wieder tut? Das ist V1.
2. Geht es auch mit einem vorhandenen Typ plus einem Feld mehr?
3. Reicht eine Linse statt einer eigenen Ansicht?
4. Was passiert, wenn man es weglässt?
5. Wäre das ein eigener Space statt eines Moduls?

Ergebnis dieser Phase ist ein **ausdrücklich vereinbarter Schnitt**: was drin ist, und was bewusst draußen bleibt. Die Draußen-Liste geht später in die Spec unter „Nicht-Ziele" und in den PR. Ein kleineres Modul als gewünscht ist hier ein **gutes** Ergebnis.

Wenn der Nutzer auf etwas besteht, das eine Grenze überschreitet: bau es nicht still ein. Halt fest, dass es eine Entscheidung für Anton ist, bau die Version, die heute trägt, und benenn den offenen Punkt im PR.

## Phase 3 — Datenmodell ableiten

Übersetze die Anforderung in RLS-Begriffe und **zeig sie dem Nutzer, bevor du Code schreibst**.

Reihenfolge — jede Stufe erst, wenn die darüber wirklich nicht passt:

1. **Vorhandenes Vokabular** benutzen (`event`, `place`, `task`, `person`, `project`, `resource`, `statement`) — ein Feld mit gleicher Semantik heißt gleich wie im Bestand.
2. **Vorhandener Typ** — ein neuer `type` nur, wenn die *Intention beim Erstellen* wirklich neu ist.
3. **Tags statt Vokabular**, wenn es in Wahrheit um Kategorisierung geht.
4. Erst dann: neues Vokabular — und dann vollständig in die Schema-Library.

Regeln, die nicht verhandelbar sind (Spec 06 / 04):

1. Struktur kommt aus `@context`-Vokabularen, **nicht** aus einer Typ-Hierarchie. Ein Item kann mehrere tragen.
2. `data` hält die fachlichen Felder. Top-Level-Felder bleiben RLS-Core.
3. **Property-Namen sind global eindeutig.** Gleiche Semantik → gleicher Name (`start`, `position`, `status`, `title`, `description`). Andere Semantik → anderer Name. Eine Kollision ist ein Vokabular-Bug.
4. `type` = Intention beim Erstellen (Composer-Template, Karte, User-Filter). `type` steuert **nie** die Modul-Aktivierung. Ob ein Item in deinem Modul auftaucht, entscheidet **Feld-Präsenz**.
5. Beziehungen liegen in `item.relations[]` bzw. als RelationRecords — nicht als Fremdschlüssel-Feld in `data`.
6. Vertrauens- und Abschluss-Aussagen sind **Confirmations**, keine erfundenen Item-Felder.

Ergebnis, dem Nutzer als kurze Tabelle vorgelegt:

| Frage | Antwort |
|---|---|
| Genutzte bestehende Vokabulare | … |
| Neue Vokabulare (mit benannter Lücke) | … |
| Genutzte bestehende Typen | … |
| Neue Typen (mit Begründung) | … |
| Relationen | `predicate`, Rolle, Gegenstück |
| Modul-Aktivierung (welches Feld) | … |
| Wiederverwendete Toolkit-Komponenten | … |
| Neue Komponenten (mit benannter Lücke) | … |

Die letzten beiden Zeilen sind Pflicht. Wenn die Liste der neuen Komponenten länger ist als die der wiederverwendeten, hast du wahrscheinlich den Bestand nicht ausgeschöpft — geh nochmal durch `reference/bestand.md`.

## Phase 4 — Modul-Spec schreiben

**Spec vor Code. Immer.** `docs/spec/` ist Source of Truth des Repos; Regeln, die nur im Code stehen, gelten als Bug.

- Kopiere `docs/spec/modules/template.md` nach `docs/spec/modules/<modul>.md` und fülle **jeden** Abschnitt: Zweck, Einordnung, Datenmodell, Capabilities, Aktionen, Komponenten, Cross-Module-Verhalten, Nicht-Ziele, Implementierungsreferenzen, offene Punkte.
- Unter „Nicht-Ziele" steht der in Phase 2 vereinbarte Schnitt.
- Stil: normativ und knapp. MUSS / DARF NICHT / SOLLTE. Keine Prosa-Schleifen, keine ADRs.
- Trag das Modul in die Tabelle in `docs/spec/modules/README.md` ein.
- Neue Vokabulare bekommen `docs/spec/schemas/vocab/<name>/v1/` mit `schema.json`, `context.jsonld` und `examples/` — Aufbau exakt wie bei einem bestehenden Vokabular (`event/v1` ist die beste Vorlage).

**Leg die Spec dem Nutzer vor und hol Zustimmung, bevor du implementierst.** Wenn die Spec eine bestehende normative Aussage ändern würde, ist das eine Entscheidung für Anton — benenne sie explizit.

## Phase 5 — Implementieren (TDD)

**Zuerst der Branch, dann die erste Datei.** Bevor du irgendetwas schreibst, sorg dafür, dass die Arbeit auf einem eigenen Branch landet — nicht auf `master` und nicht auf dem, was gerade zufällig ausgecheckt ist:

```bash
git -C "$RLS_REPO" status                # liegt schon fremde Arbeit im Worktree?
git -C "$RLS_REPO" branch --show-current

MODUL=mein-modul                         # kurzer kebab-case Name des Moduls
git -C "$RLS_REPO" fetch origin
git -C "$RLS_REPO" checkout -b "modul/$MODUL" origin/master
```

Liegen bereits uncommittete fremde Änderungen im Worktree: **nicht überschreiben und nicht mitnehmen** — ansprechen und klären. Der Wechsel könnte auch einen laufenden Dev-Server unter den Füßen wegziehen (siehe Phase 6).

**Test zuerst, dann Implementierung.** Kein Quick Fix, keine Workarounds an der Infrastruktur vorbei.

**a) Schema-Library** (`docs/spec/schemas/vocab/<name>/v1/`)
`schema.json` (JSON Schema 2020-12, `$id` = Vokabular-URL + `/schema.json`), `context.jsonld`, mindestens ein Beispiel unter `examples/`.

**b) `packages/data-interface`** (UI-frei, keine React-Abhängigkeit)

- `src/vocab.ts`: `VOCAB_<NAME>` + Aktivierungsregel in `deriveContext` (feldbasiert!) + Doc-Kommentar
- `src/item-types.ts`: `…Data`-Interface, `…Item`, `…Relations`, Typ-Guard
- `src/type-manifest.ts`: Manifest-Eintrag (`id`, `vocabularies`, `relations`) — die **einzige** Quelle für Typ-Identität
- `src/index.ts`: exportieren

**c) `packages/toolkit`** (alles Wiederverwendbare)

- Komponenten unter `src/components/<modul>/` (Space Module) bzw. `src/components/lens/` (Linse), modulgebundene Helfer daneben
- Darstellungs-Register via `registerTypePresentation` (Label, Icon, `composerWidgets`, `preview`/`detail`/`footer`-Slots) — es darf **keine** Typen einführen, nur an Manifest-Ids anhängen
- Export in `src/components/index.ts` bzw. `src/index.ts`
- **Storybook-Story pro Komponente**, Titel nach `code-and-storybook-mapping.md`
- Vitest-Tests für die Logik-Helfer

**d) `apps/reference`** (nur Komposition, keine wiederverwendbare Logik)

- `src/views/<modul>-view.tsx`
- Dispatch in `src/views/module-outlet.tsx` (inkl. Füllmodus: full-bleed oder zentrierter Container)
- `VALID_MODULES` + Modul-Label in `src/hooks/use-workspace-routing.ts`
- app-spezifische Register-Ergänzungen in `src/type-register.tsx`

Laufend gegen diese Regeln prüfen:

- **Kein `if (type === …)` in Modul-Code.** Typabhängiges kommt aus dem Register; Modul-Mechanik verzweigt über Felder und Capabilities.
- **Karten werden nie neu gebaut** — `ItemPreview` plus Slots.
- **Unbekannte Typen brechen nie.** Fehlt ein Registereintrag, greift der generische Fallback — sichtbar generisch, nie kaputt.
- **Fehlende Capabilities** werden sichtbar degradiert oder ausgeblendet, nie angenommen.
- **Wiederverwendbares gehört ins Toolkit**, nicht in die App. Querschnitts-UX gehört zusätzlich in die Spec.
- Package-Grenzen: `toolkit` → `data-interface`, nie umgekehrt. Connectoren importieren keine anderen Connectoren.

## Phase 6 — Testen lassen

Erst die Checks, dann der Mensch.

```bash
pnpm -C "$RLS_REPO" build:toolkit    # zuerst: Tests lesen dist, nicht src
pnpm -C "$RLS_REPO" test
pnpm -C "$RLS_REPO" build
git -C "$RLS_REPO" diff --check
```

Fallstrick: die Vite-Apps lösen `@real-life-stack/toolkit` auf **src** auf, Node und Vitest auf **dist**. Grüner Dev-Server bei roten Tests heißt meistens: `dist` ist stale → `pnpm build:toolkit`.

Dann den Nutzer klicken lassen:

```bash
pnpm -C "$RLS_REPO" dev:reference    # Reference-App, Vite
pnpm -C "$RLS_REPO" storybook        # Komponenten isoliert, Port 6006
```

- **Vorher prüfen, ob schon ein Dev-Server auf dem Repo läuft** (`ss -ltnp | grep -E '517[0-9]|6006'`). Wenn ja: keinen Branch-Wechsel und kein `pnpm install` unter dem laufenden Server durchziehen — erst abstimmen.
- Sag konkret, **was der Nutzer anklicken soll** und **was er sehen müsste**: Modul öffnen, Item anlegen, Item bearbeiten, Filter, Detail-Panel, leerer Zustand, Space ohne das Modul, unbekannter Item-Typ.
- Feedback einarbeiten und erneut vorlegen. Diese Schleife läuft, bis der Nutzer zufrieden ist — **nicht** bis du zufrieden bist.

## Phase 7 — PR

Der Branch steht seit Phase 5. Jetzt fehlen Commit, Push und PR — und **Push und PR brauchen eine eigene, ausdrückliche Freigabe.** „Das Modul gefällt mir" ist Zustimmung zum Ergebnis, nicht zum Veröffentlichen. Frag in einem Satz, zeig vorher, was genau rausgeht:

```bash
git -C "$RLS_REPO" status            # was liegt im Worktree?
git -C "$RLS_REPO" diff --stat       # was davon gehoert zum Modul?

# Gezielt stagen — Datei fuer Datei, nie `git add -A`:
git -C "$RLS_REPO" add packages/data-interface/src/vocab.ts
git -C "$RLS_REPO" add docs/spec/modules/mein-modul.md
# … usw.

git -C "$RLS_REPO" commit            # aussagekraeftige Message, kein --no-verify
```

Danach — **erst nach der Freigabe** — veröffentlichen:

```bash
git -C "$RLS_REPO" push -u origin "modul/$MODUL"
gh pr create --repo real-life-org/real-life-stack --base master
```

- **Nie auf `master` pushen.** Immer Branch + PR.
- **Nie `git add -A`.** Das veröffentlicht sonst fremde Änderungen, die zufällig im Worktree lagen — lokale Konfigurationen, halbfertige Arbeit von jemand anderem. Stage die Dateien des Moduls einzeln; wenn du unsicher bist, ob eine dazugehört, gehört sie nicht dazu.
- Lagen vorher schon fremde Änderungen im Worktree: **nicht mitnehmen**, sondern ansprechen. `git stash` ist eine Option, aber nur mit Wissen des Nutzers.
- **Ein PR pro Modul** (maximal zwei, wenn Spec und Implementierung sinnvoll trennbar sind). Nicht in fünf Häppchen zerlegen.
- Wer keine Push-Rechte auf `real-life-org/real-life-stack` hat, arbeitet über einen Fork (`gh repo fork`) und stellt den PR von dort.

PR-Beschreibung auf Deutsch, mit:

- **Was** das Modul tut und **für wen**
- **Datenmodell**: genutzte und neue Vokabulare/Typen, mit benannter Lücke für jedes neue
- **Wiederverwendung**: welche Toolkit-Komponenten benutzt wurden, was neu ist und warum
- **Zuschnitt**: was bewusst draußen blieb (aus Phase 2)
- **Modul-Aktivierung**: welches Feld entscheidet, welche Items erscheinen
- **Checks**: welche Kommandos liefen, mit Ergebnis
- **Offene Punkte und Entscheidungen für Anton** — besonders alles, was normative Spec berührt

Danach: Link zum PR an den Nutzer, und deutlich sagen, dass Anton reviewt.

## Was du nie tust

- Ein neues Vokabular, einen neuen Typ oder eine neue Komponente anlegen, ohne den Bestand konkret geprüft und die Lücke benannt zu haben
- Einen Wunsch durchbauen, der eine Grenze aus `reference/grenzen.md` überschreitet
- Spec-Aussagen still ändern oder neue Regeln nur im Code einführen
- Wiederverwendbare UI in die App statt ins Toolkit legen
- `type` für Modul-Aktivierung benutzen
- Auf `master` pushen, `--no-verify` benutzen, oder einen PR mergen
- Pushen oder einen PR erstellen, ohne dass der Nutzer genau das freigegeben hat
- Einen Befehl ohne `-C "$RLS_REPO"` bzw. ohne vollen Pfad absetzen — es gibt oft mehrere Checkouts
- Mit der Implementierung anfangen, bevor der Branch steht
- Spec-relevante Änderungen (`docs/spec/`, Schemas, Connector-Verträge) selbst durchwinken
