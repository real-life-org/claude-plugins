---
name: rls-instanz
argument-hint: [was für ein Netzwerk ist das?]
description: >
  Richtet eine eigene Real-Life-Stack-Instanz ein und gestaltet Landingpage
  und Erscheinungsbild — mit laufender Vorschau im Browser. Nutze diesen
  Skill, wenn jemand sagt "eigene Instanz", "unsere eigene Domain", "eigene
  Landingpage", "Farben anpassen", "Logo einbauen" oder "Self-Hosting".
disable-model-invocation: true
# Nur Lesendes ist vorab freigegeben. `allowed-tools` schraenkt nicht ein,
# sondern erlaubt OHNE Rueckfrage — Docker-Aufrufe, Dateiaenderungen und
# alles Veroeffentlichende laufen darum bewusst durch den normalen
# Genehmigungsweg. Das ist Absicht, kein fehlender Eintrag.
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

Sonst leg eins an. **Der Stack wird dafür nicht gebraucht** — es werden nur Konfigurationsdateien geschrieben, die App kommt als Image. Frag, wohin die Instanz soll; ein neues Verzeichnis auf fremder Platte ist keine Selbstverständlichkeit.

**Vorlagen und Image müssen aus derselben Version stammen.** Sie gehören zusammen: Die compose beschreibt, welche Umgebungsvariablen das Image erwartet und auf welchem Port es lauscht. Vom beweglichen `master` geholte Vorlagen mit einem gepinnten Image zu kombinieren, ergibt eine Instanz, die scheinbar konfiguriert ist und trotzdem nicht läuft.

Bestimm die Version darum **einmal** und benutz sie für beides:

```bash
# Neueste veroeffentlichte App-Version — Release-Tags heissen app-vX.Y.Z
gh release list --repo real-life-org/real-life-stack --limit 20 \
  | grep -o 'app-v[0-9.]*' | head -n1
```

Dann alles von genau diesem Tag holen (Beispiel: `app-v0.2.4`, Instanz nach `/home/x/code/unser-netzwerk`):

**Erst vollständig holen, dann an Ort und Stelle bringen.** Direkt ins Zielverzeichnis zu laden ist nicht wiederholbar: Bricht der dritte Download ab, liegen dort schon `docker-compose.preview.yml` und `branding/` — und der nächste Lauf hält das für eine bestehende Instanz und arbeitet auf einer Ruine weiter.

```bash
ZIEL=/home/x/code/unser-netzwerk
[ -e "$ZIEL" ] && { echo "FEHLER: $ZIEL existiert schon."; exit 1; }

# Das Zwischenverzeichnis liegt NEBEN dem Ziel — auf demselben Dateisystem.
# Nur dann ist das abschliessende mv ein einziger, unteilbarer rename.
TMP=$(mktemp -d "$(dirname "$ZIEL")/.rls-bootstrap-XXXXXX") || exit 1
trap 'rm -rf "$TMP"' EXIT      # raeumt auch bei Abbruch auf
set -e                          # jeder Fehler beendet hier, nichts laeuft weiter

BASE=https://raw.githubusercontent.com/real-life-org/real-life-stack/app-v0.2.4/deploy/app
mkdir -p "$TMP/landing" "$TMP/branding"
cd "$TMP"
curl -fsSLO "$BASE/docker-compose.yml"
curl -fsSLO "$BASE/docker-compose.preview.yml"
curl -fsSL "$BASE/.env.example" -o .env.example
curl -fsSL "$BASE/branding/theme.json" -o branding/theme.json
curl -fsSL "$BASE/landing-default/index.html" -o landing/index.html
cp .env.example .env
printf '\nRLS_IMAGE_TAG=0.2.4\n' >> .env

cd /                            # nicht im Verzeichnis stehen, das gleich wandert
mv "$TMP" "$ZIEL"               # ein rename: entweder ganz da oder gar nicht
trap - EXIT                     # nichts mehr aufzuraeumen
echo "Instanz angelegt aus app-v0.2.4"
```

Drei Dinge tragen hier, und alle drei sind nötig:

- **`set -e`** beendet beim ersten Fehler. Eine `&&`-Kette mit anschließendem `rm` reicht nicht: Der Rückgabewert wäre dann der des Aufräumens, und ein abgebrochener Download meldete Erfolg.
- **`trap … EXIT`** räumt auf, egal wie der Block endet — auch bei Abbruch durch den Nutzer.
- **`mv` statt `cp -r`**: Ein `cp` kann mittendrin scheitern und einen Teilzustand hinterlassen. `mv` innerhalb desselben Dateisystems ist ein einziger `rename` — entweder das Verzeichnis ist vollständig da oder gar nicht. Dafür liegt `$TMP` neben dem Ziel und nicht in `/tmp`, das oft ein anderes Dateisystem ist.

**Prüf danach, dass der Befehl mit Status 0 geendet hat**, bevor du weitermachst. Ist das Zielverzeichnis nicht entstanden, ist nichts angelegt worden — das ist der gewollte Zustand, kein halber.

Die **Version steht damit auch in der `.env`** — dieselbe, aus der die Vorlagen kommen. Gibt es noch gar kein Release, gibt es auch kein Image; dann ist die Instanz noch nicht dran, und du sagst das, statt etwas zusammenzustückeln.

Liegt der Stack lokal, geht `cp` aus dessen `deploy/app/` **nur, wenn er wirklich auf genau diesem Release-Tag steht und dort nichts geändert ist**:

```bash
git -C /pfad/zum/stack describe --tags --exact-match          # muss app-v0.2.4 sein
git -C /pfad/zum/stack status --porcelain -- deploy/app        # muss leer sein
```

`describe --tags` allein reicht nicht — es liefert auch bei Commits *nach* dem Tag einen Treffer (`app-v0.2.4-7-gabc1234`). Und ein sauberer Tag nützt nichts, wenn im Arbeitsverzeichnis lokale Änderungen an `deploy/app/` liegen: Die Instanz bekäme Vorlagen, die es nirgends veröffentlicht gibt. Stimmt eines von beidem nicht, hol über das Netz. Und **kopiere `docker-compose.build.yml` nicht mit**: Die Datei baut aus dem Monorepo und ergibt außerhalb davon keinen Sinn.

Muss der Stack geklont werden, dann **neben** das Instanz-Verzeichnis, nie hinein — sonst landet ein ganzes Monorepo im Repo der Instanz.

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

Es wird **nichts gebaut** — das Image wird gezogen. Der erste Lauf lädt es herunter und dauert je nach Leitung einen Moment.

**Den Port nimmst du aus der laufenden Instanz, nicht aus dem Beispiel.** `RLS_PORT` ist konfigurierbar, und Docker meldet, was tatsächlich vergeben wurde:

```bash
docker compose -f /home/x/code/unser-netzwerk/docker-compose.preview.yml port app 8080
```

Diese Adresse benutzt du danach überall — beim Öffnen im Browser, in jedem Screenshot-Aufruf und wenn du dem Nutzer sagst, wo er hinschauen soll. `8080` in den Beispielen unten ist genau das: ein Beispiel.

Scheitert das Ziehen, liegt es fast immer an einem Tag, den es nicht gibt, oder an fehlender Anmeldung bei einem privaten Paket — nicht am Verzeichnis des Nutzers. Nenn die Fehlermeldung, statt einen Build zu versuchen.

Zwei Dinge, die man auseinanderhalten muss:

- Änderungen an `landing/` und `branding/theme.json` wirken **sofort** — Datei speichern, Seite neu laden. Die Verzeichnisse sind gemountet, und die Farben werden getrennt geladen.
- Änderungen an `.env` brauchen ein erneutes `up -d`, weil daraus beim Start die `config.json` entsteht.

Läuft kein Docker auf der Maschine, sag es klar und hör hier auf: Ohne Vorschau ist der Rest Raterei.

## Phase 3 — Gestalten

Der Kern dieses Skills: **ändern, ansehen, weitermachen.** Du schaust dir dein Ergebnis selbst an, statt es zu behaupten.

Mit den Chrome-DevTools-Werkzeugen: Seite öffnen (die Adresse aus Phase 2 für die Landingpage, `/app` darunter für die App), Screenshot machen, beurteilen, nachbessern. Zeig dem Nutzer, was du siehst, statt es zu beschreiben.

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

**Zuerst: Gibt es hier überhaupt ein Repository?** Eine frisch angelegte Instanz ist erst einmal nur ein Verzeichnis — jeder `git`-Befehl darin scheitert, und im schlimmsten Fall greift er auf ein Repository weiter oben im Baum zu und committet dort hinein.

```bash
git -C /home/x/code/unser-netzwerk rev-parse --show-toplevel 2>/dev/null
```

Kommt nichts zurück oder ein **anderer** Pfad als das Instanz-Verzeichnis, gibt es hier kein eigenes Repository. Dann **frag**, ob eines angelegt werden soll — und leg es erst nach der Zusage an:

```bash
git -C /home/x/code/unser-netzwerk init
printf '.env\n' >> /home/x/code/unser-netzwerk/.gitignore
```

Ein bestehendes Repository weiter oben im Baum ist ein Grund zum Nachfragen, nicht zum Weitermachen: Die Instanz gehört dann vermutlich woandershin.

**Dann schau, was schon im Index liegt.** Ein `git commit` nimmt alles Vorgestagte mit — auch was jemand vor dieser Sitzung dort abgelegt hat und was der Nutzer gerade gar nicht freigegeben hat:

```bash
git -C /home/x/code/unser-netzwerk status --short
git -C /home/x/code/unser-netzwerk diff --cached --name-only
```

Ist dort Fremdes, **fass es nicht an**. `git restore --staged .` würde die vorbereitete Arbeit eines Menschen verwerfen, ohne dass er es merkt — und sie ist nirgends gesichert. Sag stattdessen, was du gefunden hast, und frag, ob es mit in den Commit soll oder ob der Nutzer es vorher selbst aus dem Index nimmt.

Dann alles stagen, was die Instanz ausmacht. **Nicht nur Landingpage und Farben:** Ohne die compose-Dateien und `.env.example` kann niemand — auch der Nutzer selbst nicht auf einem anderen Rechner — die Instanz aus dem Repo wieder aufbauen. Genau das ist der Zweck des Repos.

```bash
git -C /home/x/code/unser-netzwerk add \
  docker-compose.yml docker-compose.preview.yml .env.example .gitignore \
  landing branding
git -C /home/x/code/unser-netzwerk diff --cached --name-only   # zeigen, bevor committet wird
git -C /home/x/code/unser-netzwerk commit
```

`landing` und `branding` sind die Verzeichnisse des Nutzers — dort liegt nur, was zur Instanz gehört. Trotzdem gilt: **nie `git add -A`**, und die Liste vorher zeigen.

**Die `.env` selbst gehört nicht in den Commit**, solange nicht geklärt ist, was darin steht: Heute sind es Domain, Name und Image-Tag, morgen ein Schlüssel. `.env.example` dagegen schon — sie dokumentiert, was gesetzt werden muss, ohne die Werte dieser Instanz preiszugeben. Die `.gitignore` mit dem `.env`-Eintrag wird **mitcommittet**: Sonst schützt sie nur diesen einen Rechner, und der nächste Klon committet die `.env` beim ersten `git add`.

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
