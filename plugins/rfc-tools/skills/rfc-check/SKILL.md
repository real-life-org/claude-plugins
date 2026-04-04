---
description: Prüfe ob es RFC-Entscheidungen zu einem Thema gibt. Nutze diesen Skill wenn du wissen willst ob zu einem bestimmten Thema bereits eine Entscheidung getroffen wurde.
argument-hint: [thema]
allowed-tools: Bash(gh *)
---

# RFC-Check

Prüfe ob es im Repository `real-life-org/rfcs` bereits Entscheidungen zu einem Thema gibt.

## Thema

$ARGUMENTS

## Gemergte RFCs (angenommen)

!`gh pr list --repo real-life-org/rfcs --state merged --json number,title,body --jq '.[] | "### #\(.number): \(.title)\n\(.body)\n\n---"' 2>/dev/null || echo "(noch keine)"`

## Offene RFCs (in Review)

!`gh pr list --repo real-life-org/rfcs --state open --json number,title,body --jq '.[] | "### #\(.number): \(.title)\n\(.body)\n\n---"' 2>/dev/null || echo "(keine)"`

## Aufgabe

1. Durchsuche alle RFCs oben nach Relevanz zum Thema **$ARGUMENTS**
2. Zeige dem Nutzer:
   - **Relevante angenommene Entscheidungen** — diese gelten und müssen berücksichtigt werden
   - **Relevante offene RFCs** — diese sind noch in der Diskussion
   - **Keine Treffer** — es gibt noch keine Entscheidung zu diesem Thema
3. Falls keine Entscheidung existiert und das Thema eine braucht: schlage vor, einen neuen RFC mit `/rfc` zu erstellen
