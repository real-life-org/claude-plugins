---
description: RFC reviewen nach dem Konsent-Prinzip. Nutze diesen Skill wenn jemand einen RFC bewerten, Einwände prüfen oder ein Review abgeben will.
argument-hint: [pr-nummer]
allowed-tools: Bash(gh *)
---

# RFC Review

Du hilfst beim Reviewen eines RFCs im Repository `real-life-org/rfcs` nach dem Konsent-Prinzip.

## Kontext

Offene RFCs:
!`gh pr list --repo real-life-org/rfcs --state open --json number,title --jq '.[] | "#\(.number) \(.title)"' 2>/dev/null || echo "(keine)"`

## PR-Nummer

$ARGUMENTS

## Ablauf

1. Falls keine PR-Nummer angegeben: zeige die offenen RFCs oben und frage welcher reviewed werden soll
2. Lade den RFC-Text: `gh pr view <nummer> --repo real-life-org/rfcs --json body --jq .body`
3. Zeige den RFC-Text dem Nutzer
4. Führe durch die **Konsent-Checkliste**:

### Konsent-Checkliste

Gehe mit dem Nutzer diese Fragen durch:

1. **Verstanden?** — Ist der Vorschlag klar? Gibt es Verständnisfragen?
2. **Reaktion** — Was ist dein erster Eindruck? Was findest du gut, was fehlt?
3. **Einwand?** — Gibt es einen **schwerwiegenden Einwand**?
   - Richtet der Vorschlag Schaden an?
   - Hindert er das Team an seinen Zielen?
   - Gibt es ein konkretes Risiko, das nicht adressiert wurde?
   
   Zur Erinnerung — das sind **KEINE** schwerwiegenden Einwände:
   - "Ich hätte es anders gemacht"
   - "Ich finde es nicht optimal"
   - Persönliche Präferenz ohne Begründung

4. **Verbesserungsvorschläge?** — Ideen die den RFC besser machen, aber keine Einwände sind?

### Review abgeben

Basierend auf den Antworten, formuliere das Review und frage den Nutzer ob es so passt:

- **Kein Einwand, keine Vorschläge** → Submit als `APPROVE` mit kurzem Kommentar
- **Kein Einwand, aber Vorschläge** → Submit als `COMMENT` mit Suggested Changes
- **Schwerwiegender Einwand** → Submit als `REQUEST_CHANGES` mit Begründung und Lösungsvorschlag

Nutze zum Submitten:
```
gh api repos/real-life-org/rfcs/pulls/<nummer>/reviews -X POST -f event=<APPROVE|COMMENT|REQUEST_CHANGES> -f body="<text>"
```

Frage IMMER den Nutzer um Bestätigung bevor du das Review submittest!
