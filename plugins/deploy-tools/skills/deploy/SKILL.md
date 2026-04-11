---
description: Deployt ein Projekt auf unseren NixOS-Server. Erstellt Dockerfile, GitHub Action und docker-compose.yml. Nutze diesen Skill wenn jemand ein Projekt deployen, ein neues Deployment aufsetzen oder ein Deployment debuggen will.
allowed-tools: [Bash, Read, Write, Edit, Glob, Grep, WebFetch]
---

# Deploy

Deployt Projekte auf den NixOS-Server via GitHub Actions + Watchtower.

## Stack

- **Server:** h2980589.stratoserver.net (NixOS)
- **Reverse Proxy:** Traefik (Docker-Labels, auto-SSL)
- **Auto-Deploy:** Watchtower (pollt ghcr.io alle 30 Sek)
- **Registry:** ghcr.io (GitHub Container Registry)
- **User auf Server:** `timo` (Docker-Rechte, kein sudo), `root` (nur Anton via Nitrokey)

## Was der Skill tut

Interpretiere $ARGUMENTS und den Kontext:

### Neues Deployment aufsetzen

Wenn der User ein Projekt deployen will und es noch kein Deployment gibt:

**Schritt 1: Projekt analysieren**

Schau dir das aktuelle Repo an:
- Gibt es ein `Dockerfile`? Wenn nicht, erstelle eins basierend auf der Technologie (Node, Python, Go, etc.)
- Gibt es `.github/workflows/deploy.yml`? Wenn nicht, erstelle es.
- Gibt es eine `docker-compose.yml`? Wenn nicht, erstelle sie.

**Schritt 2: Dockerfile erstellen (falls nötig)**

Erstelle ein passendes Dockerfile für das Projekt. Erkenne die Technologie automatisch:
- `package.json` → Node.js
- `requirements.txt` / `pyproject.toml` → Python
- `go.mod` → Go
- `Cargo.toml` → Rust

**Schritt 3: GitHub Action erstellen (falls nötig)**

```yaml
name: Build and Push

on:
  push:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
      - uses: actions/checkout@v4

      - uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - uses: docker/build-push-action@v6
        with:
          context: .
          push: true
          tags: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest
```

**Schritt 4: docker-compose.yml erstellen (falls nötig)**

Frage den User nach der Domain. Erstelle:

```yaml
services:
  app:
    image: ghcr.io/GITHUB-USER/REPO-NAME:latest
    network_mode: bridge
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.PROJEKT-NAME.rule=Host(`domain.de`)"
      - "traefik.http.routers.PROJEKT-NAME.entrypoints=websecure"
      - "traefik.http.routers.PROJEKT-NAME.tls.certresolver=letsencrypt"
```

Ersetze GITHUB-USER, REPO-NAME und PROJEKT-NAME mit den tatsächlichen Werten.

**Schritt 5: User informieren**

Sage dem User:
1. Pushe den Code auf `main` (GitHub Action baut das Image)
2. DNS A-Record der Domain auf Server-IP setzen: **85.214.196.122**
3. Einmalig auf dem Server den Container starten:

```
ssh timo@h2980589.stratoserver.net
mkdir -p ~/apps/PROJEKT-NAME
# docker-compose.yml dorthin kopieren
cd ~/apps/PROJEKT-NAME && docker compose up -d
```

4. Ab dann: jeder `git push` deployed automatisch

### Deployment debuggen

Wenn der User sagt dass etwas nicht funktioniert:

**Schritt 1:** Prüfe ob die GitHub Action erfolgreich war:
```bash
gh run list --repo OWNER/REPO --limit 5
```

**Schritt 2:** Frage den User ob er die Logs vom Server braucht. Gib ihm die Befehle:
```
ssh timo@h2980589.stratoserver.net
docker ps -a
docker logs CONTAINER-NAME
docker logs traefik 2>&1 | tail -30
docker logs watchtower 2>&1 | tail -30
```

**Schritt 3:** Häufige Probleme:

| Problem | Ursache | Lösung |
|---|---|---|
| 404 | Traefik findet Container nicht | `network_mode: bridge` in docker-compose.yml? |
| 502 Bad Gateway | Container läuft nicht | `docker logs CONTAINER` prüfen |
| SSL-Fehler | DNS zeigt nicht auf Server | A-Record prüfen |
| Image pull error | Registry-Auth fehlt | `docker login ghcr.io` auf dem Server |
| Watchtower updated nicht | Credentials nicht gemountet | Infra-Repo prüfen |

### Domain hinzufügen

Wenn der User eine Domain hinzufügen will:

1. DNS A-Record auf **85.214.196.122** setzen
2. Traefik-Labels in docker-compose.yml anpassen
3. Container neu starten: `docker compose up -d`
4. Traefik holt SSL-Zertifikat automatisch

## Wichtig

- Erstelle KEINE Dateien die Secrets enthalten (Passwörter, API-Keys, Tokens)
- Der Server hat nur Port 22, 80 und 443 offen
- Timo hat KEINEN sudo-Zugang, nur Docker-Rechte
- Root-Zugang nur für Anton via Nitrokey
