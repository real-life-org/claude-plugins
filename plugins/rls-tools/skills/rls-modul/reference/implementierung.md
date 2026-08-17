# Implementierung — Ablageorte und Regeln

Gilt ab der Spec-Freigabe. Alle Pfade sind **relativ zum Worktree** aus dem Manifest (`worktree:`), nie zum Haupt-Checkout.

**Test zuerst, dann Implementierung.** Kein Quick Fix, keine Workarounds an der Infrastruktur vorbei.

## a) Schema-Library

`docs/spec/schemas/vocab/<name>/v1/` mit:

- `schema.json` — JSON Schema 2020-12, `$id` = Vokabular-URL + `/schema.json`
- `context.jsonld`
- `examples/` mit mindestens einem Beispiel

Aufbau exakt wie bei einem bestehenden Vokabular; `event/v1` ist die beste Vorlage.

## b) `packages/data-interface` — UI-frei, keine React-Abhängigkeit

| Datei | Beitrag |
|---|---|
| `src/vocab.ts` | `VOCAB_<NAME>` + Aktivierungsregel in `deriveContext` (feldbasiert!) + Doc-Kommentar |
| `src/item-types.ts` | `…Data`-Interface, `…Item`, `…Relations`, Typ-Guard |
| `src/type-manifest.ts` | Manifest-Eintrag (`id`, `vocabularies`, `relations`) — die **einzige** Quelle für Typ-Identität |
| `src/index.ts` | exportieren |

## c) `packages/toolkit` — alles Wiederverwendbare

- Komponenten unter `src/components/<modul>/` (Space Module) bzw. `src/components/lens/` (Linse), modulgebundene Helfer daneben
- Darstellungs-Register via `registerTypePresentation` (Label, Icon, `composerWidgets`, `preview`/`detail`/`footer`-Slots) — es darf **keine** Typen einführen, nur an Manifest-Ids anhängen
- Export in `src/components/index.ts` bzw. `src/index.ts`
- **Storybook-Story pro Komponente**, Titel nach `docs/spec/code-and-storybook-mapping.md`
- Vitest-Tests für die Logik-Helfer

## d) Ein neues Modul anmeldbar machen

**Die häufigste Falle.** Ein Modul existiert nicht an einer Stelle, sondern an mehreren — und wer eine vergisst, bekommt ein Modul, das *fast* funktioniert. Der typische Fehlschlag: Es erscheint unter „Mein Netzwerk", aber in keinem einzelnen Space, und im Space-Dialog lässt es sich nicht einschalten.

Der Grund: Für die Übersicht gelten **alle** Module, für einen Space nur die in `Group.data.modules`. Und was dort hinein *kann*, entscheidet eine Liste im **Toolkit** — nicht die in der App.

Leite die Stellen ab, statt dieser Aufzählung zu vertrauen (`inventur.sh` gibt sie aus, Abschnitt „Modul-Listen"):

| Ort | Was passiert ohne den Eintrag |
|---|---|
| `packages/toolkit/src/components/layout/group-dialog.tsx` → `AVAILABLE_MODULES` | **Das Modul lässt sich in keinem Space aktivieren** — es fehlt im Space-Dialog, und `knownModules()` filtert es aus einer bestehenden Liste heraus |
| `apps/reference/src/hooks/use-workspace-routing.ts` → `VALID_MODULES` | Die URL `/{space}/{modul}` wird als Item-Id gelesen, das Modul ist nicht erreichbar |
| dieselbe Datei → `MODULE_LABELS` | Der Tab trägt keinen Namen |
| `apps/reference/src/views/module-outlet.tsx` | Der Tab ist da, die Fläche bleibt leer |
| `apps/reference/src/notification-navigation.ts` | Benachrichtigungen zu Items dieses Moduls landen im falschen Tab |
| `apps/reference/src/views/<modul>-view.tsx` | — die View selbst |
| `src/type-register.tsx` | app-spezifische Typ-Ergänzungen, falls das Modul einen eigenen Typ mitbringt |

**Prüfe die Anmeldung, bevor du das Modul für fertig hältst:**

```bash
# Kommt der Modulname in allen Listen vor? Beispiel: mein-modul
grep -rn "mein-modul" /pfad/aus/dem/manifest/packages/toolkit/src/components/layout/group-dialog.tsx   /pfad/aus/dem/manifest/apps/reference/src/hooks/use-workspace-routing.ts   /pfad/aus/dem/manifest/apps/reference/src/views/module-outlet.tsx   /pfad/aus/dem/manifest/apps/reference/src/notification-navigation.ts
```

Fehlt eine Zeile, fehlt der Eintrag. Das ist billiger als der Test danach — und der Test danach ist trotzdem Pflicht (Phase 7: „Modul in einem **einzelnen Space** öffnen", nicht nur in der Übersicht).

Dass dieselbe Frage an fünf Stellen beantwortet wird, ist eine bekannte Schwäche. Wenn dir beim Eintragen auffällt, dass die Listen bereits auseinanderlaufen, **melde es** — repariere nicht still die eine, die dir gerade im Weg ist.

## e) `apps/reference` — nur Komposition

Hier gehört **keine** wiederverwendbare Logik hin. Wenn etwas in einer zweiten App nützlich wäre, gehört es ins Toolkit.

## Regeln, laufend zu prüfen

1. **Kein `if (type === …)` in Modul-Code.** Typabhängiges kommt aus dem Register; Modul-Mechanik verzweigt über Felder und Capabilities.
2. **Karten werden nie neu gebaut** — `ItemPreview` plus Slots.
3. **Unbekannte Typen brechen nie.** Fehlt ein Registereintrag, greift der generische Fallback — sichtbar generisch, nie kaputt.
4. **Fehlende Capabilities** werden sichtbar degradiert oder ausgeblendet, nie angenommen. Jede Capability ist optional.
5. **Wiederverwendbares gehört ins Toolkit**, nicht in die App. Querschnitts-UX gehört zusätzlich in die Spec.
6. Package-Grenzen: `toolkit` → `data-interface`, nie umgekehrt. Connectoren importieren keine anderen Connectoren.

## Checks

Immer mit explizitem Worktree-Pfad, nie im Vertrauen auf ein Arbeitsverzeichnis — und **fail-fast verkettet**, damit ein roter Test nicht von einem grünen Build danach verdeckt wird:

```bash
pnpm -C /pfad/aus/dem/manifest install &&        # einmalig im frischen Worktree
pnpm -C /pfad/aus/dem/manifest build:toolkit &&  # zuerst: Tests lesen dist, nicht src
pnpm -C /pfad/aus/dem/manifest test &&
pnpm -C /pfad/aus/dem/manifest build &&
git -C /pfad/aus/dem/manifest diff --check &&
echo "ALLE CHECKS GRUEN"
```

Ohne die `&&`-Kette laufen alle Befehle unabhängig davon durch, ob der vorherige gescheitert ist, und die letzte Ausgabe sieht grün aus, obwohl in der Mitte etwas rot war. Erscheint `ALLE CHECKS GRUEN` nicht, ist mindestens ein Schritt gescheitert — such den ersten Fehler, nicht den letzten.

Beim Nacharbeiten reicht der jeweils betroffene Teil (`test` allein), aber vor dem Vorlegen läuft die ganze Kette.

Fallstrick: Die Vite-Apps lösen `@real-life-stack/toolkit` auf **src** auf, Node und Vitest auf **dist**. Grüner Dev-Server bei roten Tests heißt meistens: `dist` ist stale → `build:toolkit`.
