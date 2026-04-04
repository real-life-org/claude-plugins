---
description: Angenommene RFC-Entscheidungen der Real Life Organisation. Lade diesen Kontext bevor du Architektur-, Prozess- oder Organisationsentscheidungen triffst, Rollen zuweist, oder Vorschläge machst die bestehende Entscheidungen betreffen könnten.
user-invocable: false
allowed-tools: Bash(gh *)
---

# Angenommene Entscheidungen (RFCs)

Die folgenden RFCs wurden von der Real Life Organisation per Konsent angenommen. Berücksichtige sie bei deiner Arbeit.

## Gemergte RFCs

!`gh pr list --repo real-life-org/rfcs --state merged --json number,title,body --jq '.[] | "### RFC #\(.number): \(.title)\n\(.body)\n\n---"' 2>/dev/null || echo "(noch keine gemergten RFCs)"`

## Offene RFCs (in Review)

Diese sind noch nicht entschieden — erwähne sie wenn relevant, aber behandle sie nicht als beschlossen:

!`gh pr list --repo real-life-org/rfcs --state open --json number,title --jq '.[] | "- #\(.number): \(.title)"' 2>/dev/null || echo "(keine)"`

## Hinweis

Wenn du etwas vorschlägst das im Widerspruch zu einer angenommenen RFC steht, weise explizit darauf hin. Änderungen an bestehenden Entscheidungen erfordern einen neuen RFC.
