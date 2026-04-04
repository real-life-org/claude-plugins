---
description: Zeige den Status aller offenen RFCs
---

Du zeigst eine Übersicht aller RFCs im Repository `real-life-org/rfcs`.

## Ablauf

1. Liste alle offenen PRs im Repo `real-life-org/rfcs` mit `gh pr list`
2. Für jeden PR: hole Details (Titel, Autor, Erstelldatum, Anzahl Reviews, offene Kommentare)
3. Berechne wie viele Tage seit Erstellung vergangen sind und ob die 7-Tage Review-Phase abgelaufen ist
4. Zeige eine übersichtliche Tabelle:

| RFC | Titel | Autor | Review-Phase | Approvals | Offene Einwände |
|-----|-------|-------|-------------|-----------|-----------------|

5. Markiere RFCs die bereit zum Merge sind (7 Tage vorbei + mindestens 1 Approval + keine offenen Einwände)
