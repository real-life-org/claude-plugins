---
description: Änderungsvorschlag für einen RFC formulieren. Nutze diesen Skill wenn jemand eine konkrete Änderung an einem RFC vorschlagen will.
argument-hint: [pr-nummer]
allowed-tools: Bash(gh *)
---

# RFC Änderungsvorschlag

Du hilfst dabei, einen konkreten Änderungsvorschlag (Suggested Change) für einen RFC zu formulieren und als Review-Kommentar zu posten.

## Kontext

Offene RFCs:
!`gh pr list --repo real-life-org/rfcs --state open --json number,title --jq '.[] | "#\(.number) \(.title)"' 2>/dev/null || echo "(keine)"`

## PR-Nummer

$ARGUMENTS

## Ablauf

1. Falls keine PR-Nummer angegeben: zeige die offenen RFCs oben und frage welcher geändert werden soll
2. Lade den aktuellen RFC-Text und die Datei-Infos:
   ```
   gh pr view <nummer> --repo real-life-org/rfcs --json body --jq .body
   gh api repos/real-life-org/rfcs/pulls/<nummer>/files --jq '.[0] | {filename: .filename, sha: .sha}'
   ```
3. Zeige den RFC-Text dem Nutzer
4. Frage: **Was möchtest du ändern?** (z.B. "Der Punkt zu X fehlt", "Die Formulierung bei Y sollte anders sein")
5. Formuliere den Suggested Change — zeige dem Nutzer:
   - Die **aktuelle Passage** (Originaltext)
   - Den **Vorschlag** (geänderter Text)
   - Eine kurze **Begründung**
6. Nach Bestätigung: poste als Review-Kommentar mit Suggested Change

### Suggested Change posten

Nutze die GitHub API um einen Review mit Suggested Change zu erstellen:

```
gh api repos/real-life-org/rfcs/pulls/<nummer>/reviews -X POST \
  -f event=COMMENT \
  -f body="Änderungsvorschlag" \
  --jsonArray -f 'comments[][path]=<dateiname>' \
  --jsonArray -f 'comments[][body]='"'"'Begründung
```suggestion
Neuer Text hier
```'"'"'' \
  --jsonArray -f 'comments[][line]=<zeilennummer>'
```

Falls die API zu komplex wird, poste alternativ einen normalen PR-Kommentar mit dem Vorschlag im Markdown-Format:

```
gh pr comment <nummer> --repo real-life-org/rfcs --body "**Änderungsvorschlag**

Aktuell:
> Originaltext

Vorschlag:
> Neuer Text

Begründung: ..."
```

Frage IMMER den Nutzer um Bestätigung bevor du den Kommentar postest!
