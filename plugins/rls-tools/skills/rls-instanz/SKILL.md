---
name: rls-instanz
argument-hint: [was für ein Netzwerk ist das?]
description: >
  Richtet eine eigene Real-Life-Stack-Instanz ein und gestaltet Landingpage
  und Erscheinungsbild — mit laufender Vorschau im Browser. Nutze diesen
  Skill, wenn jemand sagt "eigene Instanz", "unsere eigene Domain", "eigene
  Landingpage", "Farben anpassen", "Logo einbauen" oder "Self-Hosting".
disable-model-invocation: true
allowed-tools: [Read, Grep, Glob]
---

# Eine eigene RLS-Instanz gestalten

Du richtest mit dem Nutzer eine **eigene Instanz** des Real Life Stack ein: eigene Domain, eigener Name, eigene Landingpage, eigene Farben. Am Ende liegt das alles in **seinem** Repo — nicht in unserem.

**Sprache:** Deutsch.

## Was hier läuft und was nicht

Das Instanz-Verzeichnis enthält **keinen Stack-Code**. Die App kommt als fertiges Container-Image; das Verzeichnis sagt nur, wie sie heißt, wo sie hinzeigt und wie sie aussieht. Darum gibt es hier nichts zu bauen und nichts zu mergen — Updates kommen über ein neues Image, ohne dass die Dateien des Nutzers angefasst werden.

Daraus folgt die Grenze, die du **durchsetzt**, auch wenn jemand mehr will:

| Fläche | Wie weit darf Gestaltung gehen |
|---|---|
| **Landingpage** (`landing/`) | frei. Eigene Seite, eigenes HTML und CSS, keine Vorgaben |
| **Erscheinungsbild der App** | Farbtokens, Name, Favicon — sonst nichts |
| **Layout oder Verhalten der App** | gar nicht. Das hieße, den Stack zu forken |

Wer die App selbst umbauen will, braucht kein Branding, sondern ein **Modul** — dafür gibt es `/rls-tools:rls-modul`. Sag das, statt einen Weg zu suchen.

**Ehrlich bleiben, was heute wirkt:** `appName` setzt den Titel, `faviconUrl` das Tab-Icon, `colors` die Farben. Für ein **Logo in der App gibt es kein Konfigurationsfeld** — die App-Shell hat keine Fläche dafür. Auf der Landingpage ist ein Logo dagegen einfach eine Datei in `branding/`, die du im HTML einbindest. Versprich nichts darüber hinaus.

## Der Zustand liegt im Verzeichnis

Kein Gedächtnis, keine Shell-Variablen: Der Stand steht in den Dateien.

```
instanz/
├── .env                        Domain, Name, Relay
├── docker-compose.yml          Betrieb hinter Traefik
├── docker-compose.preview.yml  lokale Vorschau
├── landing/index.html          die Landingpage
└── branding/
    ├── theme.json              Farben, hell und dunkel
    ├── logo.svg                nur für die Landingpage
    └── favicon.svg
```

Schreib in jedem Befehl den vollen Pfad aus (`docker compose -f /voller/pfad/...`). Eine Shell-Variable überlebt den nächsten Aufruf nicht, und auf der Maschine liegen womöglich mehrere Instanzen nebeneinander.

## Phase 0 — Instanz-Verzeichnis

Gibt es schon eins (erkennbar an `docker-compose.preview.yml` und `branding/`), arbeite dort weiter.

Sonst leg eins an. **Der Stack wird dafür nicht gebraucht** — es werden nur Konfigurationsdateien geschrieben, die App kommt als Image. Frag, wohin die Instanz soll; ein neues Verzeichnis auf fremder Platte ist keine Selbstverständlichkeit. Dann hol die Vorlagen einzeln aus dem veröffentlichten Stand:

```bash
# Beispiel: Instanz nach /home/x/code/unser-netzwerk
mkdir -p /home/x/code/unser-netzwerk/landing /home/x/code/unser-netzwerk/branding
cd /home/x/code/unser-netzwerk
BASE=https://raw.githubusercontent.com/real-life-org/real-life-stack/master/deploy/app
curl -fsSLO "$BASE/docker-compose.yml"
curl -fsSLO "$BASE/docker-compose.preview.yml"
curl -fsSL "$BASE/.env.example" -o .env
curl -fsSL "$BASE/branding/theme.json" -o branding/theme.json
curl -fsSL "$BASE/landing-default/index.html" -o landing/index.html
```

Liegt der Stack ohnehin lokal, geht auch `cp` aus dessen `deploy/app/` — aber **kopiere `docker-compose.build.yml` nicht mit**: Die Datei baut aus dem Monorepo und ergibt außerhalb davon keinen Sinn.

Prüf danach, dass die Instanz wirklich eigenständig ist:

```bash
grep -rn "build:" /home/x/code/unser-netzwerk/docker-compose*.yml || echo "gut — kein Build-Kontext"
```

Findet sich dort ein `build:`, ist etwas Falsches mitgekommen. Entfernen, nicht ausprobieren.

Trag in `.env` Domain und Name ein. **Beide sind Pflicht**: Eine Instanz tritt unter ihrer eigenen Adresse auf, eine geerbte wäre jemandes andere.

## Phase 1 — Wofür ist das Netzwerk?

Kurz, im Gespräch. Du brauchst nur, was die Seite trägt:

- **Wer** kommt hier zusammen, und **wofür**?
- Was soll jemand tun, der die Seite zum ersten Mal sieht?
- Gibt es ein Logo, Bilder, einen Text, der schon existiert?
- Welche Anmutung? (Ein Bild oder ein Vergleich hilft mehr als Farbcodes)

**Frag nicht** nach Technik, die aus `.env` kommt, und nicht nach Dingen, die die Instanz nicht entscheidet — welcher Connector läuft oder welches Relay, steht schon fest.

## Phase 2 — Vorschau starten

Ohne laufende Vorschau gestaltest du blind.

```bash
docker compose -f /home/x/code/unser-netzwerk/docker-compose.preview.yml up -d
```

Es wird **nichts gebaut** — das Image wird gezogen. Der erste Lauf lädt es herunter und dauert je nach Leitung einen Moment; danach startet die Instanz in Sekunden auf `http://localhost:8080` (Port über `RLS_PORT` änderbar, falls belegt).

Scheitert das Ziehen, liegt es fast immer an einem Tag, den es nicht gibt, oder an fehlender Anmeldung bei einem privaten Paket — nicht am Verzeichnis des Nutzers. Nenn die Fehlermeldung, statt einen Build zu versuchen.

Zwei Dinge, die man auseinanderhalten muss:

- Änderungen an `landing/` und `branding/theme.json` wirken **sofort** — Datei speichern, Seite neu laden. Die Verzeichnisse sind gemountet, und die Farben werden getrennt geladen.
- Änderungen an `.env` brauchen ein erneutes `up -d`, weil daraus beim Start die `config.json` entsteht.

Läuft kein Docker auf der Maschine, sag es klar und hör hier auf: Ohne Vorschau ist der Rest Raterei.

## Phase 3 — Gestalten

Der Kern dieses Skills: **ändern, ansehen, weitermachen.** Du schaust dir dein Ergebnis selbst an, statt es zu behaupten.

Mit den Chrome-DevTools-Werkzeugen: Seite öffnen (`http://localhost:8080` für die Landingpage, `/app` für die App), Screenshot machen, beurteilen, nachbessern. Zeig dem Nutzer, was du siehst, statt es zu beschreiben.

**Welche Farbtokens es gibt, fragst du die laufende Instanz** — nie aus einer Liste, die veraltet:

```js
// evaluate_script auf der geöffneten Seite
const s = getComputedStyle(document.documentElement)
Array.from(document.styleSheets)
  .flatMap(sh => { try { return Array.from(sh.cssRules) } catch { return [] } })
  .flatMap(r => Array.from(r.style || []))
  .filter(n => n.startsWith('--'))
  .filter((n, i, a) => a.indexOf(n) === i)
  .sort()
  .map(n => `${n}: ${s.getPropertyValue(n).trim()}`)
```

Die wichtigsten sind `--primary` und `--primary-foreground`; `--background`, `--foreground`, `--card`, `--muted`, `--accent`, `--border` und `--radius` tragen den Rest. Setz in `branding/theme.json` **wenige** Tokens bewusst, statt alle zu überschreiben — die Vorgaben sind aufeinander abgestimmt, und jedes gesetzte Token übernimmt Verantwortung für den Kontrast.

```json
{
  "light": { "primary": "#2f6b3a", "primary-foreground": "#ffffff" },
  "dark":  { "primary": "#8fd19e", "primary-foreground": "#0b1f12" }
}
```

Prüfe **beide** Schemata: Die App schaltet auf `.dark` um, und eine Farbe, die hell trägt, kann dunkel unlesbar sein. Ein Token wird verworfen, wenn sein Name keines des Toolkits ist oder sein Wert unzulässig — steht eine Farbe nicht, sagt die Browser-Konsole warum. Farbfunktionen wie `oklch()`, `rgb()` und `hsl()` sind erlaubt.

Für die Landingpage gilt nichts von alldem: eigene Datei, freie Hand. Sie soll zur App passen, muss aber nichts von ihr erben. Verlinke die App unter `/app`.

## Phase 4 — Veröffentlichen

**Erst nach ausdrücklicher Freigabe** — dass die Seite gefällt, ist noch keine Zustimmung zum Veröffentlichen. Zeig vorher, was rausgeht.

```bash
git -C /home/x/code/unser-netzwerk status
git -C /home/x/code/unser-netzwerk add landing/index.html branding/theme.json
git -C /home/x/code/unser-netzwerk commit
```

Stage gezielt, nie `git add -A`. Und **niemals `.env` committen**, wenn dort etwas steht, das nicht öffentlich sein soll — Domain und Name sind harmlos, aber die Datei ist der Ort, an dem später Schlüssel landen würden.

Ist das Verzeichnis noch kein Repo, frag, ob eines angelegt werden soll und wohin. Ein neues öffentliches Repo ist eine Außenwirkung, die dem Nutzer gehört.

Zum Schluss die Vorschau aufräumen:

```bash
docker compose -f /home/x/code/unser-netzwerk/docker-compose.preview.yml down
```

## Was du nie tust

- Behaupten, etwas sähe gut aus, ohne es angesehen zu haben
- Die App über Tokens hinaus verändern wollen — dafür gibt es `/rls-tools:rls-modul`
- Ein Logo in der App versprechen; heute wirkt es nur auf der Landingpage
- Eine Liste von Tokens aus dem Gedächtnis benutzen statt der laufenden Instanz
- `.env` committen, ohne hineingesehen zu haben
- Ein Repo anlegen, pushen oder veröffentlichen ohne ausdrückliche Freigabe
- Den Stack forken, um einen Gestaltungswunsch zu erfüllen
