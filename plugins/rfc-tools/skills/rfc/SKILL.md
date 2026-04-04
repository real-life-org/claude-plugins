---
description: Neuen RFC erstellen. Nutze diesen Skill wenn jemand einen Vorschlag, eine Entscheidung oder Änderung für die Organisation einbringen will.
argument-hint: [thema]
allowed-tools: Bash(gh *) Bash(git *) Read Write Glob
---

# Neuen RFC erstellen

Du erstellst einen neuen RFC im Repository `real-life-org/rfcs`.

## Kontext

Existierende RFCs (gemergt):
!`gh pr list --repo real-life-org/rfcs --state merged --json number,title --jq '.[] | "#\(.number) \(.title)"' 2>/dev/null || echo "(noch keine)"`

Offene PRs:
!`gh pr list --repo real-life-org/rfcs --state open --json number,title --jq '.[] | "#\(.number) \(.title)"' 2>/dev/null || echo "(keine)"`

RFC-Dateien:
!`gh api repos/real-life-org/rfcs/contents/rfcs --jq '.[].name' 2>/dev/null || echo "(noch keine)"`

## Thema

$ARGUMENTS

## Ablauf

1. Falls kein Thema angegeben: frage den Nutzer kurz, worum es geht
2. **Prüfe zuerst** ob es zu dem Thema bereits eine angenommene oder offene RFC gibt (siehe Kontext oben). Falls ja: weise den Nutzer darauf hin und frage ob der neue RFC die bestehende ersetzen/ergänzen soll
3. Bestimme die nächste RFC-Nummer aus den existierenden RFCs oben
3. Wechsle ins rfcs-Repo (`/home/fritz/workspace/workspace/rfcs`) und erstelle einen Branch: `rfc/XXXX-kurzer-name`
4. Schreibe den RFC **gemeinsam mit dem Nutzer** — frage nach Inhalt, mach Vorschläge, iteriere. Nicht einfach Platzhalter stehen lassen!
5. Erstelle die RFC-Datei `rfcs/XXXX-kurzer-name.md` nach diesem Template:

```markdown
# RFC-XXXX: Titel

- **Autor:** {Name}
- **Datum:** {YYYY-MM-DD}
- **Status:** In Review

## Zusammenfassung
Ein Absatz.

## Motivation
Warum brauchen wir das?

## Vorschlag
Was genau wird vorgeschlagen?

## Alternativen
Was wurde sonst erwogen?

## Offene Fragen
Was ist noch unklar?
```

6. Committe und pushe den Branch
7. Erstelle einen PR — **der volle RFC-Text ist der PR-Body** (nicht nur ein Link auf die Datei!)
8. Gib dem Nutzer den PR-Link
