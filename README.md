# Claude Plugins — Real Life Org

Claude Code Skills und Tools für das Real Life Team.

## Installation

```shell
claude plugin marketplace add real-life-org/claude-plugins
claude plugin install rfc-tools@real-life-tools
claude plugin install rls-tools@real-life-tools
```

## Verfügbare Skills

### rfc-tools

| Skill | Beschreibung |
|-------|-------------|
| `/rfc [thema]` | Neuen RFC erstellen (prüft automatisch ob es schon eine Entscheidung gibt) |
| `/rfc-status` | Übersicht aller offenen RFCs und deren Status |
| `/rfc-review [nummer]` | RFC reviewen nach dem Konsent-Prinzip |
| `/rfc-suggest [nummer]` | Änderungsvorschlag für einen RFC formulieren |
| `/rfc-check [thema]` | Prüfen ob es zu einem Thema bereits eine Entscheidung gibt |

### rls-tools

| Skill | Beschreibung |
|-------|-------------|
| `/rls-modul [beschreibung]` | Eigenes Space Module oder eine Linse für den Real Life Stack bauen — Anforderung aufnehmen, Datenmodell ableiten, Spec schreiben, Oberfläche aus dem Toolkit bauen, auf dem Dev-Server testen, PR erstellen |

Der Skill kennt den Bestand des Stacks (Vokabulare, Item-Typen, Toolkit-Komponenten, Hooks) und leitet ihn bei jedem Lauf frisch aus dem Repo ab, statt eine Liste zu pflegen, die veraltet. Er benutzt konsequent, was schon da ist, und begrenzt Wünsche, die die heutigen Kapazitäten des Stacks übersteigen. Voraussetzung: eine lokale Kopie von [`real-life-stack`](https://github.com/real-life-org/real-life-stack).

### Automatischer Kontext

Claude berücksichtigt angenommene RFC-Entscheidungen automatisch bei Architektur-, Prozess- und Organisationsfragen — ohne dass man einen Skill manuell aufrufen muss.
