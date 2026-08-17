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

## d) `apps/reference` — nur Komposition

- `src/views/<modul>-view.tsx`
- Dispatch in `src/views/module-outlet.tsx` (inkl. Füllmodus: full-bleed oder zentrierter Container)
- `VALID_MODULES` + Modul-Label in `src/hooks/use-workspace-routing.ts`
- app-spezifische Register-Ergänzungen in `src/type-register.tsx`

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
