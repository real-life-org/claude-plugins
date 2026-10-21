# Windows

Der Skill ist in Unix-Schreibweise geschrieben. Auf Windows funktioniert das
meiste sinngemäß, drei Dinge aber nicht wörtlich. Aus der ersten echten
Nutzung auf einem Rechner ganz ohne Toolchain.

## Werkzeuge fehlen oft ganz

`git`, `gh` und `node` sind auf einem frischen Windows nicht da. Installieren
über winget, dann **neue Shell öffnen** (der `PATH` wird sonst nicht neu
gelesen):

```powershell
winget install --id Git.Git -e
winget install --id GitHub.cli -e
winget install --id OpenJS.NodeJS.LTS -e
```

## `pnpm` gibt es nicht global — `corepack pnpm` benutzen

`corepack enable` will nach `C:\Program Files\nodejs\` schreiben und braucht
Administratorrechte. Das ist unnötig: `corepack pnpm` funktioniert ohne
Aktivierung und liest die Version aus `packageManager` in der `package.json`.

```powershell
corepack pnpm --filter @real-life-stack/toolkit build
corepack pnpm --filter reference test
```

**Achtung bei npm-Skripten, die intern `pnpm` aufrufen** — `pnpm build:toolkit`
scheitert dann trotzdem, weil das innere `pnpm` nicht im `PATH` ist. In dem
Fall den Filter direkt aufrufen statt das Skript.

## Bash-Skripte über Git Bash

`inventur.sh` ist ein Shell-Skript. PowerShell führt es nicht aus:

```powershell
& "C:\Program Files\Git\bin\bash.exe" `
  "$env:CLAUDE_PLUGIN_ROOT/skills/rls-modul/scripts/inventur.sh" `
  /d/Workspace/20-repos/real-life-stack
```

Der Pfad zum Repo in Git-Bash-Schreibweise (`/d/...`), nicht `D:\...`.

## Kein `nohup` für den Dev-Server

Statt `nohup … &` den Hintergrund-Modus deines Werkzeugs für Shell-Aufrufe
benutzen. Ins Manifest kommt dann keine Betriebssystem-PID, sondern die
Kennung, die dein Werkzeug vergibt — dafür ist das Feld `devServerHandle` da.
Beenden entsprechend über dasselbe Werkzeug, nicht über `kill`.

Auch `ss -ltnp` gibt es nicht. Belegte Ports findest du mit:

```powershell
Get-NetTCPConnection -State Listen | Where-Object LocalPort -in 5173,5174,6006
```

## Pfade im Manifest

Windows-Pfade mit Rückwärtsschrägstrichen gehören in Anführungszeichen, und in
YAML besser als einfacher String:

```yaml
repo: 'D:\Workspace\20-repos\real-life-stack'
worktree: 'D:\Workspace\20-repos\real-life-stack-garten'
```
