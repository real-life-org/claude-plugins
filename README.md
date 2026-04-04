# Claude Plugins — Real Life Org

Claude Code Skills und Tools für das Real Life Team.

## Installation

```shell
claude plugin marketplace add real-life-org/claude-plugins
claude plugin install rfc-tools@real-life-tools
```

## Verfügbare Skills

| Skill | Beschreibung |
|-------|-------------|
| `/rfc [thema]` | Neuen RFC erstellen (prüft automatisch ob es schon eine Entscheidung gibt) |
| `/rfc-status` | Übersicht aller offenen RFCs und deren Status |
| `/rfc-review [nummer]` | RFC reviewen nach dem Konsent-Prinzip |
| `/rfc-suggest [nummer]` | Änderungsvorschlag für einen RFC formulieren |
| `/rfc-check [thema]` | Prüfen ob es zu einem Thema bereits eine Entscheidung gibt |

### Automatischer Kontext

Claude berücksichtigt angenommene RFC-Entscheidungen automatisch bei Architektur-, Prozess- und Organisationsfragen — ohne dass man einen Skill manuell aufrufen muss.
