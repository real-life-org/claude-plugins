---
description: Erstelle einen neuen RFC (Branch, Datei nach Template, PR)
---

Du erstellst einen neuen RFC im Repository `real-life-org/rfcs`.

## Ablauf

1. Frage den Nutzer nach dem Thema des RFCs, falls nicht angegeben
2. Bestimme die nächste RFC-Nummer: liste die Dateien in `rfcs/` im Repo und nimm die nächste freie Nummer
3. Erstelle einen Branch: `rfc/XXXX-kurzer-name`
4. Erstelle die RFC-Datei `rfcs/XXXX-kurzer-name.md` nach diesem Template:

```markdown
# RFC-XXXX: Titel

- **Autor:** {Name des Nutzers}
- **Datum:** {Heutiges Datum, YYYY-MM-DD}
- **Status:** In Review

## Zusammenfassung

{Ein Absatz, der den Vorschlag auf den Punkt bringt.}

## Motivation

{Warum brauchen wir das? Welches Problem wird gelöst?}

## Vorschlag

{Was genau wird vorgeschlagen? So konkret wie möglich.}

## Alternativen

{Welche anderen Ansätze wurden erwogen? Warum wurden sie verworfen?}

## Offene Fragen

{Was ist noch unklar oder muss noch diskutiert werden?}
```

5. Schreibe den RFC gemeinsam mit dem Nutzer — frage nach Inhalt für jeden Abschnitt
6. Committe und pushe den Branch
7. Erstelle einen PR mit dem vollen RFC-Text als Body
8. Gib dem Nutzer den PR-Link
