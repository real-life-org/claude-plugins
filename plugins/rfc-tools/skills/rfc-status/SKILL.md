---
description: Status aller RFCs anzeigen. Nutze diesen Skill wenn jemand nach dem Stand der Entscheidungen, offenen RFCs oder Review-Status fragt.
allowed-tools: Bash(gh *)
---

# RFC Status

Zeige eine Übersicht aller RFCs im Repository `real-life-org/rfcs`.

## Daten

Offene PRs:
!`gh api repos/real-life-org/rfcs/pulls?state=open --jq '.[] | {number: .number, title: .title, user: .user.login, created_at: .created_at}' 2>/dev/null || echo "Fehler beim Laden"`

Reviews zu offenen PRs:
!`for pr in $(gh api repos/real-life-org/rfcs/pulls?state=open --jq '.[].number' 2>/dev/null); do echo "PR #$pr:"; gh api "repos/real-life-org/rfcs/pulls/$pr/reviews" --jq '.[] | "  \(.user.login): \(.state)"' 2>/dev/null || echo "  keine Reviews"; done`

## Anzeige

Erstelle aus den Daten oben eine übersichtliche Tabelle:

| # | Titel | Autor | Review-Phase | Approvals | Offene Einwände | Status |
|---|-------|-------|-------------|-----------|-----------------|--------|

Für jede Zeile:
- **Review-Phase:** Berechne Tage seit Erstellung. Format: `X/7 Tage` oder `abgeschlossen` wenn >= 7
- **Approvals:** Anzahl Reviews mit State `APPROVED`
- **Offene Einwände:** Anzahl Reviews mit State `CHANGES_REQUESTED`
- **Status:** Kurze Zusammenfassung (z.B. "Bereit zum Merge", "Wartet auf Reviews", "Einwand offen")

Markiere am Ende klar, welche RFCs **bereit zum Merge** sind:
- 7 Tage vergangen
- Mindestens 1 Approval
- Keine offenen Einwände (CHANGES_REQUESTED)
