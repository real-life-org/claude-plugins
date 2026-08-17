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

Drei Tore, die der Nutzer öffnet, nicht du: **Plan**, **Spec**, **Veröffentlichung**. Vor dem ersten Tor wird nichts geschrieben, vor dem letzten nichts nach außen gegeben — auch kein Fork. Einzige Ausnahme vor dem Plan-Tor ist ein Clone, wenn das Repo fehlt, und auch der nur auf ausdrückliche Zustimmung (Phase 0).

## Zustand lebt in einer Datei, nicht im Gedächtnis

**Shell-Variablen überleben keinen zweiten Befehl.** Jeder Aufruf startet eine neue Shell; `RLS_REPO=…` ist im nächsten Befehl weg. Genauso wenig darfst du dich darauf verlassen, dass ein Pfad „aus dem Gespräch" noch stimmt — der Nutzer kann dazwischen etwas geändert haben.

Darum hält ein **Manifest** den Arbeitszustand, ab Phase 4 unter `~/.rls-modul/<modul>.yml`:

```yaml
modul: garden-planner
repo: /home/x/code/real-life-stack                    # verifizierter Haupt-Checkout
worktree: /home/x/code/real-life-stack-garden-planner # hier wird gearbeitet
branch: modul/garden-planner
upstreamRemote: upstream        # Remote, der auf real-life-org zeigt (Basis + PR-Ziel)
pushPlan: fork                  # direkt | fork — aus viewerPermission, Phase 4
pushRemote:                     # leer bis Phase 8; bei pushPlan=direkt = upstreamRemote
prHead:                         # leer bis Phase 8; bei Fork mit owner:-Praefix
devServerPid:                   # nur waehrend Phase 7 gesetzt, danach beendet + entfernt
devServerLog:                   # Pfad der Logdatei, gleiche Lebensdauer
phase: spec-freigegeben
scope: Beete anlegen, Pflanzungen eintragen, Gießplan sehen
nonGoals: keine Ertragsstatistik, keine Erinnerungen, kein Wetterdienst
```

Regeln:

1. **Jeden Pfad aus dem Manifest lesen**, nicht aus dem Gedächtnis, und in jedem Befehl **ausschreiben** (`git -C /voller/pfad …`, `pnpm -C /voller/pfad …`).
2. Nie auf ein Arbeitsverzeichnis verlassen. Auf Entwicklungsmaschinen liegen mehrere Checkouts und Worktrees desselben Projekts nebeneinander.
3. `phase:` nach jedem erreichten Tor fortschreiben — **direkt danach**, nicht am Ende der Sitzung.

`phase:` kennt genau diese Werte, in dieser Reihenfolge:

| Wert | Bedeutet | Nächster Schritt |
|---|---|---|
| `plan-freigegeben` | Datenmodell abgenommen, Worktree steht | Phase 5 (Spec) |
| `spec-freigegeben` | Spec abgenommen | Phase 6 (Implementierung) |
| `implementiert` | Checks grün | Phase 7 (Test durch den Nutzer) |
| `getestet` | Nutzer zufrieden | Phase 8, aber erst nach Veröffentlichungs-Freigabe |
| `veroeffentlicht` | PR steht | nichts — Link zeigen, ggf. Worktree aufräumen |

## Wiedereinstieg

**Prüf beim Start immer zuerst, ob es schon einen Arbeitsstand gibt:**

```bash
ls ~/.rls-modul/ 2>/dev/null && cat ~/.rls-modul/*.yml 2>/dev/null
```

Findest du ein Manifest zum Thema des Nutzers, steig dort ein statt von vorn anzufangen — und prüf vorher, ob es noch stimmt:

1. Existiert `worktree:` noch als Verzeichnis? Wenn nicht: Manifest ist verwaist — dem Nutzer sagen, Phase 4 neu machen oder Manifest löschen.
2. Steht dort noch `branch:`? (`git -C /worktree branch --show-current`) Weicht es ab, hat jemand von Hand eingegriffen: **fragen**, nicht korrigieren.
3. Ist `phase:` einer der Werte oben? Fehlt er oder ist er unbekannt, ist das Manifest kaputt — nicht raten, sondern den Stand mit dem Nutzer klären.
4. Passt die Phase zum tatsächlichen Zustand? Steht `implementiert`, liegen aber keine Änderungen im Worktree (`git -C /worktree status --short`), stimmt etwas nicht — ansprechen.
5. Steht ein `devServerPid` drin, läuft der Prozess noch (`kill -0` mit der PID)? Wenn nicht, ist es eine Leiche aus einer früheren Sitzung: Feld entfernen. Wenn doch, den laufenden Server benutzen statt einen zweiten zu starten.

Erst wenn alle fünf stimmen, arbeite bei „nächster Schritt" der Tabelle weiter. **Ein Tor gilt nur als durchschritten, wenn das Manifest es sagt** — nicht, weil es im Gespräch mal vorkam. Bereits erteilte Freigaben werden nicht erneut eingeholt, aber auch nicht angenommen.

## Phase 0 — Repo finden und Inventur ableiten

**Pflicht, bevor du irgendetwas vorschlägst.** Handlisten driften lautlos; leite den Bestand jedes Mal frisch ab.

```bash
# Haupt-Checkout finden (Default-Branch: master)
find ~ -maxdepth 4 -type d -name real-life-stack 2>/dev/null | head

# Inventur — prueft den Pfad und bricht mit Exit 2 ab, wenn dort nicht
# wirklich der Stack liegt. Pfad ausschreiben, keine Variable.
"$CLAUDE_PLUGIN_ROOT/skills/rls-modul/scripts/inventur.sh" /gefundener/pfad
```

Mehrere Treffer — Worktrees, Fix-Checkouts — sind normal: **frag, welcher gemeint ist**, statt den ersten zu nehmen.

Ist gar keine Kopie da, **klon nicht von dir aus**. Ein Clone legt einige hundert Megabyte an, und wohin, entscheidet der Nutzer. Frag, ob geklont werden soll und in welches Verzeichnis, und nenn den Befehl (`git clone https://github.com/real-life-org/real-life-stack.git`). Das ist die einzige Schreibhandlung vor dem Plan-Tor — sie ist die Voraussetzung dafür, überhaupt etwas beurteilen zu können, und deshalb an die ausdrückliche Zustimmung des Nutzers gebunden.

Der Exit-Code sagt, wie belastbar die Ausgabe ist:

| Code | Bedeutung | Was du tust |
|---|---|---|
| 0 | vollständige Inventur | normal weiterarbeiten |
| 1 | Repo nicht gefunden | Pfad klären, nicht weiterarbeiten |
| 2 | Pfad ist nicht der Stack | Pfad klären, nicht weiterarbeiten |
| 3 | **degradiert** — das Repo bringt eine maschinenlesbare Inventur mit, die aber nicht läuft (kaputt oder `node` fehlt) | **dem Nutzer melden**, bevor du irgendetwas vorschlägst |

Bei Exit 3 stammt die Ausgabe aus der abgeleiteten Ersatz-Inventur. Die liest per `grep` und kann Neueres übersehen: **ein leerer Abschnitt heißt dort nicht „gibt es nicht".** Auf dieser Grundlage darfst du nicht entscheiden, dass etwas neu gebaut werden muss.

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

**Frag nicht, in welchem Space das Modul laufen soll.** Die Frage hat beim Bauen keinen Nutzen: Ein Modul entsteht **für den Stack**, nicht für einen Space. Welche Spaces es später einschalten, ist Laufzeitkonfiguration (`Group.data.modules`) und wird von den Menschen im jeweiligen Space entschieden — lange nach diesem PR. Wer beim Entwurf einen bestimmten Space vor Augen hat, baut Annahmen ein, die in jedem anderen Space falsch sind.

Ebenso wenig gehören Space-Name, Mitgliederzahl oder Gruppenstruktur zur Anforderung. Was zählt, ist die wiederkehrende Nutzung — die ist überall dieselbe, sonst ist das Modul falsch geschnitten.

**Ist es überhaupt ein Modul?**

| Wunsch | Das ist … |
|---|---|
| Profile, Kontakte, Verifikation, Auth, Benachrichtigungen, Debug | eine **App-Shell-Fläche**, kein Space Module |
| Eine andere Darstellung vorhandener Items | eine **Linse** (`components/lens/`) — Bruchteil des Aufwands |
| Ein Baustein, der in mehreren Modulen vorkommt | eine **Module Component** im Toolkit |
| „Nur diese Leute sollen das sehen" | keine Modul-Eigenschaft — Sichtbarkeit schneidet der **Space**, das Modul kennt sie nicht |

Die letzte Zeile ist eine Struktur-Feststellung, kein Anlass zur Rückfrage nach Spaces: Wenn ein Wunsch in Wahrheit Sichtbarkeit meint, benenn das — und bau kein Sichtbarkeitsfeature ins Modul.

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

**Erst hier wird zum ersten Mal geschrieben, und zwar nie im Haupt-Checkout.** Der kann einen laufenden Dev-Server, fremde Änderungen oder einen anderen Branch haben. Ein eigener Worktree macht all das gegenstandslos.

**Zuerst klären, wie das Repo angebunden ist** — die Inventur hat es unter „Remotes" ausgegeben. `origin` ist **nicht** automatisch das zentrale Repo.

Und: **eine Remote-URL sagt nichts über Schreibrechte.** Dass `origin` auf `real-life-org/real-life-stack` zeigt, heißt nicht, dass der Nutzer dorthin pushen darf — die meisten Beitragenden dürfen das nicht. Frag die Berechtigung ab, statt sie anzunehmen:

```bash
gh repo view real-life-org/real-life-stack --json viewerPermission --jq .viewerPermission
```

`ADMIN`, `MAINTAIN` oder `WRITE` heißt: direkt auf einen Branch im Zielrepo. `READ` oder `TRIAGE` heißt: es wird ein **Fork** gebraucht. Das jetzt zu wissen ist wichtig, weil der Push sonst erst ganz am Ende scheitert — nach der gesamten Arbeit.

**Schlägt der Aufruf fehl oder kommt leer zurück, ist das kein `fork`.** Ein `gh`-Fehler (nicht angemeldet, kein Netz, API-Störung) sagt nichts über die Rechte des Nutzers; daraus einen Fork abzuleiten, würde einem Maintainer ungefragt ein Repo anlegen. Nenn das Ergebnis, frag nach — „darfst du direkt in `real-life-org/real-life-stack` pushen, oder arbeitest du über einen Fork?" — und trag die Antwort ein. Bei `gh: command not found` oder fehlender Anmeldung gilt dasselbe.

**Den Fork jetzt aber nicht anlegen.** Ein Fork ist ein öffentlich sichtbares Repo unter dem Namen des Nutzers; ihn hier zu erzeugen wäre eine Außenwirkung vor dem Veröffentlichungstor. Es wird nur **festgehalten**, was in Phase 8 zu tun ist:

| `viewerPermission` | `pushPlan` im Manifest | Basis für den Branch | In Phase 8 |
|---|---|---|---|
| `ADMIN` / `MAINTAIN` / `WRITE` | `direkt` | `<upstream>/master` | Push nach `<upstream>`, `--head modul/garden-planner` |
| `READ` / `TRIAGE` | `fork` | `<upstream>/master` | Fork anlegen, Remote setzen, Push dorthin, `--head owner:modul/garden-planner` |
| Abfrage schlägt fehl oder ist leer | **erst fragen** | — | nichts, bis der Nutzer geantwortet hat |

Zeigt **kein** Remote auf `real-life-org/real-life-stack`, frag nach — dann fehlt entweder der Upstream oder es ist ein anderes Projekt. Nicht raten.

Die Befehle unten sind für ein **Beispiel-Manifest** ausgeschrieben. Setz überall die Werte deines eigenen Manifests ein — die Namen sind nicht fix, `upstream` kann `origin` heißen und umgekehrt:

```bash
# Beispiel-Manifest: repo=/home/x/code/real-life-stack · upstreamRemote=upstream
#                    modul=garden-planner · worktree=/home/x/code/rls-garden-planner
git -C /home/x/code/real-life-stack fetch upstream
git -C /home/x/code/real-life-stack worktree add \
    -b modul/garden-planner \
    /home/x/code/rls-garden-planner \
    upstream/master

pnpm -C /home/x/code/rls-garden-planner install
```

Zuordnung: `git -C` ← `repo` · `fetch`/Basis ← `upstreamRemote` · `-b` ← `branch` · Zielverzeichnis ← `worktree`.

Der Haupt-Checkout wird dabei **nicht angefasst**: kein Branch-Wechsel, kein Stash, kein `install`. Das `install` im frischen Worktree dauert einen Moment — sag dem Nutzer, dass das normal ist.

Danach das Manifest unter `~/.rls-modul/<modul>.yml` anlegen (Felder siehe oben) mit `upstreamRemote`, `pushPlan` und `phase: plan-freigegeben`. `pushRemote` und `prHead` bleiben leer — sie werden in Phase 8 gefüllt, wenn feststeht, wohin tatsächlich gepusht wird. **Ab jetzt kommt jeder Pfad und jeder Remote aus dieser Datei.**

Ist `git worktree` nicht nutzbar (kein Git-Repo, alte Version), sag es und arbeite ersatzweise auf einem frischen Branch — die Basis ist auch dann `<upstreamRemote>/master` aus dem Manifest, nicht `origin/master`. Dieser Weg verändert den Checkout des Nutzers, also erst nach `git status` und ausdrücklicher Zustimmung.

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

Sobald die Check-Kette grün durchläuft: `phase: implementiert` ins Manifest.

## Phase 7 — Testen lassen

Erst die Checks aus `reference/implementierung.md`, dann der Mensch:

Beide Server laufen, bis man sie abbricht. Starte nur den, den der Nutzer gerade braucht, und **wirklich im Hintergrund** — sonst blockiert der Aufruf und du kommst nicht weiter. Hat dein Werkzeug einen Hintergrund-Modus für Shell-Aufrufe, nimm ihn; sonst hängt der Prozess selbst ab und die PID wird festgehalten:

```bash
# Beispiel-Manifest: worktree=/home/x/code/rls-garden-planner
cd /home/x/code/rls-garden-planner && \
  nohup pnpm dev:reference > /tmp/rls-garden-planner-dev.log 2>&1 &
echo "devServerPid: $!"        # ins Manifest eintragen
sleep 5 && grep -m1 "Local:" /tmp/rls-garden-planner-dev.log   # tatsaechlicher Port
```

Storybook nur, wenn es zusätzlich wirklich gebraucht wird, als **eigener** Aufruf nach demselben Muster (`pnpm storybook`, eigene Logdatei, eigene PID).

Ins Manifest gehören `devServerPid` und der Pfad der Logdatei. Ohne das weiß ein späterer Aufruf nicht, was er gestartet hat, und der Prozess bleibt nach Sitzungsende hängen.

Läuft schon ein Dev-Server (`ss -ltnp | grep -E '517[0-9]|6006'`), stör den fremden Prozess nicht — Vite nimmt selbst den nächsten freien Port, der Worktree ist ein eigenes Verzeichnis. **Nenn dem Nutzer den Port aus der Logdatei**, nicht den erwarteten.

Wenn der Nutzer fertig ist, den Server mit `kill` und der PID aus dem Manifest beenden, beide Felder entfernen und die Logdatei aufräumen — spätestens bevor du in Phase 8 gehst.

Sag konkret, **was der Nutzer anklicken soll** und **was er sehen müsste**: Modul öffnen, Item anlegen, Item bearbeiten, Filter, Detail-Panel, leerer Zustand, Space ohne das Modul, unbekannter Item-Typ. Feedback einarbeiten und erneut vorlegen. Die Schleife läuft, bis **der Nutzer** zufrieden ist — nicht bis du es bist.

Sagt er, dass es passt: `phase: getestet` ins Manifest. Das ist die Zufriedenheit mit dem Ergebnis — **nicht** die Freigabe zum Veröffentlichen, die kommt in Phase 8 getrennt.

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

**Erst nach der Freigabe** wird irgendetwas nach außen gegeben — auch der Fork. Was zu tun ist, steht als `pushPlan` im Manifest.

Bei `pushPlan: fork` zuerst den Fork anlegen und als Remote eintragen. `gh repo fork` legt ohne weiteres Zutun **keinen** Remote im Worktree an, der Remote muss also gesetzt werden. Den eigenen Kontonamen abfragen statt annehmen:

```bash
# Beispiel-Manifest: worktree=/home/x/code/rls-garden-planner · pushPlan=fork
gh repo fork real-life-org/real-life-stack --clone=false --remote=false
gh api user --jq .login          # liefert den Owner des Forks, hier: timo
git -C /home/x/code/rls-garden-planner remote add fork git@github.com:timo/real-life-stack.git
```

Dann ins Manifest: `pushRemote: fork` und `prHead: timo:modul/garden-planner`. Bei `pushPlan: direkt` stattdessen `pushRemote:` = der Wert von `upstreamRemote` und `prHead:` = der nackte Branchname.

Jetzt pushen und den PR öffnen — **jeder Wert aus dem Manifest**, nichts fest verdrahtet:

```bash
# Beispiel-Manifest: worktree=/home/x/code/rls-garden-planner · pushRemote=fork
#                    branch=modul/garden-planner · prHead=timo:modul/garden-planner
git -C /home/x/code/rls-garden-planner push -u fork modul/garden-planner

gh pr create \
  --repo real-life-org/real-life-stack \
  --base master \
  --head timo:modul/garden-planner \
  --title "…" --body "…"
```

Zuordnung: `git -C` ← `worktree` · `push -u` ← `pushRemote` · Branchname ← `branch` · `--head` ← `prHead`. Steht im Manifest `origin` statt `fork`, heißt der Remote im Befehl `origin`.

`--repo` **und** `--head` sind Pflicht: ohne `--head` rät `gh` den Branch aus dem Arbeitsverzeichnis, das hier nicht der Worktree ist. Beim Fork trägt `--head` das `owner:`-Präfix, sonst sucht `gh` den Branch im Zielrepo, wo er nicht liegt.

Danach `phase: veroeffentlicht` ins Manifest.

PR-Beschreibung auf Deutsch, mit: was das Modul tut und für wen · Datenmodell mit benannter Lücke für jedes neue Vokabular · welche Toolkit-Komponenten wiederverwendet wurden und was neu ist · der Zuschnitt aus Phase 2 (was bewusst draußen blieb) · welches Feld die Modul-Aktivierung trägt · gelaufene Checks mit Ergebnis · offene Punkte und Entscheidungen für Anton.

Danach: Link an den Nutzer, und deutlich sagen, dass Anton reviewt. Der Worktree bleibt bestehen, bis der PR durch ist; aufgeräumt wird mit `git worktree remove`, wenn der Nutzer zustimmt.

## Was du nie tust

- Den Nutzer fragen, in welchem Space das Modul laufen soll — das entscheidet später jeder Space für sich, nicht dieser PR
- Ein neues Vokabular, einen neuen Typ oder eine neue Komponente anlegen, ohne den Bestand geprüft und die Lücke benannt zu haben
- Einen Wunsch durchbauen, der eine Grenze aus `reference/grenzen.md` überschreitet
- Im Haupt-Checkout schreiben, dort den Branch wechseln oder dort `install` laufen lassen
- Einen Pfad aus dem Gedächtnis oder aus einer Shell-Variablen nehmen statt aus dem Manifest
- Schreiben, bevor der Plan freigegeben ist; implementieren, bevor die Spec freigegeben ist; veröffentlichen, bevor das ausdrücklich freigegeben ist
- `git add -A`, `--no-verify`, auf `master` pushen oder einen PR mergen
- Spec-Aussagen still ändern oder neue Regeln nur im Code einführen
- `type` für Modul-Aktivierung benutzen
