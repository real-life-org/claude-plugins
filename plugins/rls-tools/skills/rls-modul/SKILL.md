---
name: rls-modul
argument-hint: [kurze Beschreibung des gewünschten Moduls]
description: >
  Baut ein neues Space Module (bzw. eine Linse) im Real Life Stack — von der
  Anforderung über Datenmodell und Modul-Spec bis zu Toolkit-Komponenten,
  Dev-Server-Test und PR. Nutze diesen Skill, wenn jemand sagt "ich hätte
  gern ein Modul für X", "neue Linse", "eigene Ansicht im RLS", "neuer
  Item-Typ", "neues Vokabular" oder ähnlich.
disable-model-invocation: true
allowed-tools: [Read, Grep, Glob]
---

# RLS-Modul bauen

Du baust mit dem Nutzer zusammen ein **Space Module** (oder eine **Linse**) für den Real Life Stack. Das Ergebnis ist ein PR im Repo `real-life-org/real-life-stack`, den Anton reviewt.

Der Nutzer ist meistens **nicht** der Architekt des Stacks. Deine Aufgabe ist es, seine Anforderung in die bestehende Architektur zu übersetzen und sie dabei **auf das zu begrenzen, was der Stack heute trägt** — nicht, neben ihm her eine zweite Welt zu bauen.

**Sprache:** Deutsch, im Dialog wie in Spec, Code-Kommentaren und PR.

## Die zwei Leitplanken

1. **Bestand vor Neubau.** Was es gibt, wird benutzt. Neues entsteht nur gegen eine konkret geprüfte und benannte Lücke — nie mit „es gibt nichts Passendes".
2. **Zuschnitt vor Ehrgeiz.** Ein Modul, das die heutigen Kapazitäten übersteigt, wird nicht dadurch machbar, dass man es sorgfältiger baut. Dann wird der Wunsch kleiner geschnitten, nicht der Stack umgebaut.

Du bist an diesen beiden Stellen **nicht dienstleistend**. Sag früh und freundlich, was nicht geht, und biete den Schnitt an, der geht.

## Ablauf

```text
0 Inventur  →  1 Anforderung  →  2 Zuschnitt  →  3 Datenmodell
   → PLAN-FREIGABE → 4 Arbeitsplatz (Worktree + Manifest)
   → 5 Spec → SPEC-FREIGABE → 6 Implementierung → 7 Test durch den Nutzer
   → VERÖFFENTLICHUNGS-FREIGABE → 8 PR
```

Drei Tore, die der Nutzer öffnet, nicht du: **Plan**, **Spec**, **Veröffentlichung**. Vor dem ersten Tor wird nichts geschrieben, vor dem letzten nichts nach außen gegeben.

## Zustand lebt in einer Datei, nicht im Gedächtnis

**Shell-Variablen überleben keinen zweiten Befehl.** Jeder Aufruf startet eine neue Shell; `RLS_REPO=…` ist im nächsten Befehl weg. Genauso wenig darfst du dich darauf verlassen, dass ein Pfad „aus dem Gespräch" noch stimmt — der Nutzer kann dazwischen etwas geändert haben.

Darum hält ein **Manifest** den Arbeitszustand, ab Phase 4 unter `~/.rls-modul/<modul>.yml`:

```yaml
modul: garden-planner
repo: /home/x/code/real-life-stack                    # verifizierter Haupt-Checkout
worktree: /home/x/code/real-life-stack-garden-planner # hier wird gearbeitet
branch: modul/garden-planner
phase: spec-freigegeben
scope: Beete anlegen, Pflanzungen eintragen, Gießplan sehen
nonGoals: keine Ertragsstatistik, keine Erinnerungen, kein Wetterdienst
```

Regeln:

1. **Jeden Pfad aus dem Manifest lesen**, nicht aus dem Gedächtnis, und in jedem Befehl **ausschreiben** (`git -C /voller/pfad …`, `pnpm -C /voller/pfad …`).
2. Nie auf ein Arbeitsverzeichnis verlassen. Auf Entwicklungsmaschinen liegen mehrere Checkouts und Worktrees desselben Projekts nebeneinander.
3. `phase:` nach jedem erreichten Tor fortschreiben, damit ein späterer Aufruf weiß, wo er steht.

## Phase 0 — Repo finden und Inventur ableiten

**Pflicht, bevor du irgendetwas vorschlägst.** Handlisten driften lautlos; leite den Bestand jedes Mal frisch ab.

```bash
# Haupt-Checkout finden (Default-Branch: master). Fehlt er:
#   git clone https://github.com/real-life-org/real-life-stack.git
find ~ -maxdepth 4 -type d -name real-life-stack 2>/dev/null | head

# Inventur — prueft den Pfad und bricht mit Exit 2 ab, wenn dort nicht
# wirklich der Stack liegt. Pfad ausschreiben, keine Variable.
"$CLAUDE_PLUGIN_ROOT/skills/rls-modul/scripts/inventur.sh" /gefundener/pfad
```

Mehrere Treffer — Worktrees, Fix-Checkouts — sind normal: **frag, welcher gemeint ist**, statt den ersten zu nehmen. Exit 2 heißt falscher Pfad: klären, nicht weiterarbeiten.

Lies danach `reference/bestand.md` und `reference/grenzen.md` aus diesem Skill; sie ordnen die Ausgabe ein. Bei Widerspruch gilt die Skript-Ausgabe.

Und lies im Repo — nicht überfliegen, wirklich lesen:

- `docs/spec/06-schema-composition.md` (Vokabulare, `type`, Typ-Register) — das wichtigste Dokument
- `docs/spec/01-app-composition.md` (App Shell vs. Space Module vs. Module Component, Overlay-Ebenen)
- `docs/spec/modules/README.md` + `docs/spec/modules/template.md`
- `docs/spec/modules/shared-components.md`
- `docs/spec/code-and-storybook-mapping.md`
- die Spec des ähnlichsten bestehenden Moduls (Feed / Kanban / Calendar / Map / Resonance)

## Phase 1 — Anforderung aufnehmen

Im Gespräch, in eigenen Worten, kurz und einladend. Kein Fragebogen, keine Auswahl-Dialoge.

- **Welche wiederkehrende Nutzung** soll das Modul tragen? (Nicht „was soll es können", sondern „was macht jemand damit immer wieder")
- **Welche Dinge** kommen vor, und **welche Angaben** hängen an jedem?
- **Wie hängen sie zusammen?** (gehört zu, ist zugewiesen an, blockiert …)
- **Wie soll man sie sehen?** Liste / Grid / Karte / Kalender / Board / etwas Eigenes?
- **Was soll man tun können?**
- **Wie viele Dinge** werden das realistisch, und **wie viele Menschen** nutzen es?

**Ist es überhaupt ein Modul?**

| Wunsch | Das ist … |
|---|---|
| Profile, Kontakte, Verifikation, Auth, Benachrichtigungen, Debug | eine **App-Shell-Fläche**, kein Space Module |
| Eine andere Darstellung vorhandener Items | eine **Linse** (`components/lens/`) — Bruchteil des Aufwands |
| Ein Baustein, der in mehreren Modulen vorkommt | eine **Module Component** im Toolkit |
| Abgetrennte Sichtbarkeit für eine Teilgruppe | ein eigener **Space** |

Spiegele die Anforderung einmal in eigenen Worten zurück.

## Phase 2 — Zuschnitt begrenzen

**Nie überspringen**, auch wenn der Wunsch harmlos klingt. Prüf ihn gegen `reference/grenzen.md`. Häufige Anschläge:

- Auswertung, Summen, Ranglisten über große Mengen → keine Aggregation im Vertrag
- Suche über alles → keine Volltextsuche im Vertrag
- Erinnerungen, E-Mails, zeitgesteuerte Automatik → kein rechnender Server vorauszusetzen
- Genehmigungsketten, Rollen, Feldrechte → Autorisierung ist grob und optional
- Mehrstufige Wizards in gestapelten Panels → eine Overlay-Fläche pro Ebene

Merksatz: Ein Modul läuft gegen **jeden** Connector (`local`, `mock`, `supabase`, `graphql`, `wot`). Was ein einzelnes Backend zusätzlich kann, darf nie Voraussetzung werden.

Wenn etwas anschlägt, führ das Gespräch über die fünf Verkleinerungs-Fragen aus `reference/grenzen.md`. Ergebnis ist ein **ausdrücklich vereinbarter Schnitt** — was drin ist, was bewusst draußen bleibt. Ein kleineres Modul als gewünscht ist hier ein **gutes** Ergebnis.

Besteht der Nutzer auf etwas jenseits einer Grenze: nicht still einbauen. Festhalten, dass es eine Entscheidung für Anton ist, die tragfähige Version bauen, den offenen Punkt in den PR schreiben.

## Phase 3 — Datenmodell ableiten

Reihenfolge — jede Stufe erst, wenn die darüber wirklich nicht passt:

1. **Vorhandenes Vokabular** (`event`, `place`, `task`, `person`, `project`, `resource`, `statement`) — gleiche Semantik, gleicher Name.
2. **Vorhandener Typ** — ein neuer `type` nur, wenn die *Intention beim Erstellen* wirklich neu ist.
3. **Tags statt Vokabular**, wenn es in Wahrheit um Kategorisierung geht.
4. Erst dann: neues Vokabular.

Nicht verhandelbar (Spec 06 / 04):

1. Struktur kommt aus `@context`-Vokabularen, nicht aus einer Typ-Hierarchie. Ein Item kann mehrere tragen.
2. `data` hält die fachlichen Felder. Top-Level bleibt RLS-Core.
3. **Property-Namen sind global eindeutig.** Gleiche Semantik → gleicher Name (`start`, `position`, `status`, `title`). Kollision = Vokabular-Bug.
4. `type` = Intention beim Erstellen. `type` steuert **nie** die Modul-Aktivierung — das tut **Feld-Präsenz**.
5. Beziehungen in `item.relations[]` bzw. als RelationRecords, nie als Fremdschlüssel-Feld.
6. Vertrauens- und Abschluss-Aussagen sind **Confirmations**.

**Plan vorlegen** — das erste Tor:

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
| Bewusst draußen (aus Phase 2) | … |

Die letzten drei Zeilen sind Pflicht. Ist die Liste neuer Komponenten länger als die der wiederverwendeten, hast du den Bestand vermutlich nicht ausgeschöpft — nochmal durch `reference/bestand.md`.

## Phase 4 — Arbeitsplatz einrichten

**Erst hier wird zum ersten Mal geschrieben, und zwar nie im Haupt-Checkout.** Der kann einen laufenden Dev-Server, fremde Änderungen oder einen anderen Branch haben. Ein eigener Worktree macht all das gegenstandslos:

```bash
git -C /pfad/zum/haupt-checkout fetch origin
git -C /pfad/zum/haupt-checkout worktree add \
    -b modul/garden-planner \
    /pfad/zum/haupt-checkout-garden-planner \
    origin/master

pnpm -C /pfad/zum/haupt-checkout-garden-planner install
```

Der Haupt-Checkout wird dabei **nicht angefasst**: kein Branch-Wechsel, kein Stash, kein `install`. Das `install` im frischen Worktree dauert einen Moment — sag dem Nutzer, dass das normal ist.

Danach das Manifest unter `~/.rls-modul/<modul>.yml` anlegen (Felder siehe oben) mit `phase: plan-freigegeben`. **Ab jetzt kommt jeder Pfad aus dieser Datei.**

Ist `git worktree` nicht nutzbar (kein Git-Repo, alte Version), sag es und arbeite ersatzweise auf einem frischen Branch aus `origin/master` — dann aber erst nach `git status` und ausdrücklicher Zustimmung, weil das den Checkout des Nutzers verändert.

## Phase 5 — Modul-Spec schreiben

**Spec vor Code. Immer.** `docs/spec/` ist Source of Truth; Regeln, die nur im Code stehen, gelten als Bug.

- `docs/spec/modules/template.md` nach `docs/spec/modules/<modul>.md` kopieren und **jeden** Abschnitt füllen: Zweck, Einordnung, Datenmodell, Capabilities, Aktionen, Komponenten, Cross-Module-Verhalten, Nicht-Ziele, Implementierungsreferenzen, offene Punkte.
- Unter „Nicht-Ziele" steht der in Phase 2 vereinbarte Schnitt.
- Stil: normativ und knapp. MUSS / DARF NICHT / SOLLTE. Keine Prosa-Schleifen, keine ADRs.
- Modul in die Tabelle in `docs/spec/modules/README.md` eintragen.
- Neue Vokabulare: `docs/spec/schemas/vocab/<name>/v1/` mit `schema.json`, `context.jsonld`, `examples/`.

**Spec vorlegen und Zustimmung holen** — das zweite Tor. Würde die Spec eine bestehende normative Aussage ändern, ist das eine Entscheidung für Anton; benenne sie ausdrücklich. Danach `phase: spec-freigegeben` ins Manifest.

## Phase 6 — Implementieren

Ablageorte, Regeln und Checks stehen in `reference/implementierung.md` — lies die Datei jetzt und arbeite danach.

Kurz: TDD, Schema-Library → `data-interface` (UI-frei) → `toolkit` (alles Wiederverwendbare, mit Storybook-Story) → `apps/reference` (nur Komposition). Kein `if (type === …)` in Modul-Code, Karten immer aus `ItemPreview`, unbekannte Typen brechen nie, jede Capability ist optional.

## Phase 7 — Testen lassen

Erst die Checks aus `reference/implementierung.md`, dann der Mensch:

```bash
pnpm -C /worktree/aus/dem/manifest dev:reference    # Reference-App, Vite
pnpm -C /worktree/aus/dem/manifest storybook        # Komponenten isoliert, Port 6006
```

Läuft schon ein Dev-Server (`ss -ltnp | grep -E '517[0-9]|6006'`), nimm einen anderen Port statt den fremden Prozess zu stören — der Worktree ist ein eigenes Verzeichnis, beide können parallel laufen.

Sag konkret, **was der Nutzer anklicken soll** und **was er sehen müsste**: Modul öffnen, Item anlegen, Item bearbeiten, Filter, Detail-Panel, leerer Zustand, Space ohne das Modul, unbekannter Item-Typ. Feedback einarbeiten und erneut vorlegen. Die Schleife läuft, bis **der Nutzer** zufrieden ist — nicht bis du es bist.

## Phase 8 — Veröffentlichen

**Push und PR brauchen eine eigene, ausdrückliche Freigabe** — das dritte Tor. „Das Modul gefällt mir" ist Zustimmung zum Ergebnis, nicht zum Veröffentlichen. Zeig vorher, was genau rausgeht.

```bash
git -C /worktree/aus/dem/manifest status
git -C /worktree/aus/dem/manifest diff --stat

# Gezielt stagen, Datei fuer Datei — nie `git add -A`:
git -C /worktree/aus/dem/manifest add docs/spec/modules/garden-planner.md
git -C /worktree/aus/dem/manifest add packages/data-interface/src/vocab.ts

git -C /worktree/aus/dem/manifest commit    # kein --no-verify
```

Nach der Freigabe:

```bash
git -C /worktree/aus/dem/manifest push -u origin modul/garden-planner

gh pr create \
  --repo real-life-org/real-life-stack \
  --base master \
  --head modul/garden-planner \
  --title "…" --body "…"
```

`--repo` **und** `--head` sind Pflicht: ohne `--head` rät `gh` den Branch aus dem Arbeitsverzeichnis, das hier nicht der Worktree ist.

PR-Beschreibung auf Deutsch, mit: was das Modul tut und für wen · Datenmodell mit benannter Lücke für jedes neue Vokabular · welche Toolkit-Komponenten wiederverwendet wurden und was neu ist · der Zuschnitt aus Phase 2 (was bewusst draußen blieb) · welches Feld die Modul-Aktivierung trägt · gelaufene Checks mit Ergebnis · offene Punkte und Entscheidungen für Anton.

Danach: Link an den Nutzer, und deutlich sagen, dass Anton reviewt. Der Worktree bleibt bestehen, bis der PR durch ist; aufgeräumt wird mit `git worktree remove`, wenn der Nutzer zustimmt.

## Was du nie tust

- Ein neues Vokabular, einen neuen Typ oder eine neue Komponente anlegen, ohne den Bestand geprüft und die Lücke benannt zu haben
- Einen Wunsch durchbauen, der eine Grenze aus `reference/grenzen.md` überschreitet
- Im Haupt-Checkout schreiben, dort den Branch wechseln oder dort `install` laufen lassen
- Einen Pfad aus dem Gedächtnis oder aus einer Shell-Variablen nehmen statt aus dem Manifest
- Schreiben, bevor der Plan freigegeben ist; implementieren, bevor die Spec freigegeben ist; veröffentlichen, bevor das ausdrücklich freigegeben ist
- `git add -A`, `--no-verify`, auf `master` pushen oder einen PR mergen
- Spec-Aussagen still ändern oder neue Regeln nur im Code einführen
- `type` für Modul-Aktivierung benutzen
