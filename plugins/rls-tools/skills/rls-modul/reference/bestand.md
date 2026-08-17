# Was der Real Life Stack schon kann

Diese Landkarte ordnet **Bedarf → vorhandener Baustein** zu. Sie ist eine Orientierung, **keine Wahrheit über den aktuellen Stand** — die liefert `scripts/inventur.sh`. Wenn eine Zeile hier und das Skript sich widersprechen, gilt das Skript, und die Zeile hier gehört korrigiert.

Lies das so: **Bevor du irgendetwas baust, such deinen Bedarf in der linken Spalte.** Findest du ihn, ist die Frage nicht mehr "wie baue ich das", sondern "wie benutze ich das Vorhandene".

## Daten

| Bedarf | Vorhanden |
|---|---|
| Zeitpunkt / Zeitraum an einem Item | Vokabular `event/v1` → `start`, `end`, `duration`, `rrule`, `meetingLink` |
| Ort / Geometrie an einem Item | Vokabular `place/v1` → `position` (GeoJSON Point/LineString/Polygon), `address` |
| Zustand / Fortschritt / Sortierung in Spalten | Vokabular `task/v1` → `status`, `order` |
| Person als Item | Vokabular `person/v1` |
| Vorhaben mit Beteiligten | Vokabular `project/v1` |
| Etwas, das geteilt/angeboten/gebraucht wird | Vokabular `resource/v1` |
| Aussage, über die abgestimmt wird | Vokabular `statement/v1` + Resonance-Modul |
| Titel, Beschreibung, Autor, Zeitstempel, Bilder | Vokabular `base/v1` — **immer da, nie neu definieren** |
| Kategorisierung / Thema | **Tags** (`docs/spec/07-tags.md`), nicht ein neues Vokabular |
| Beziehung zwischen zwei Items | `item.relations[]` bzw. RelationRecords (`docs/spec/08-relation-records.md`) |
| „X bestätigt, dass Y" | **Confirmations** (`docs/spec/05-confirmations-and-trust.md`), kein eigenes Feld |
| Zugehörigkeit zu einer Gemeinschaft | **Space / Group**, nicht ein Feld in `data` |

Wenn ein Feld nur einen anderen Namen für etwas Vorhandenes wäre (`beginn` statt `start`, `koordinaten` statt `position`, `zustand` statt `status`), ist das **kein neues Vokabular**, sondern ein Namensfehler. Property-Namen sind RLS-weit eindeutig.

## Oberfläche

| Bedarf | Vorhanden |
|---|---|
| Item als Karte oder Zeile zeigen | `ItemPreview` + Slots aus dem Typ-Register — **Karten werden nie neu gebaut** |
| Zusatzangaben auf der Karte | `ItemMetaRow`, `ItemTypeBadge`, `ItemTimeRange`, `ItemAssignees`, `ItemGroupBadge`, `ItemScopeBadge`, `ItemCommentCount` |
| Detailansicht eines Items | `ItemDetailPanel` / `ItemDetailView` + `ItemDetailActions` |
| Erstellen und Bearbeiten | `ContentComposer` / `ItemComposer` mit den Widgets `title`, `text`, `media`, `date`, `location`, `people`, `tags`, `status`, `group` |
| Einstieg zum Erstellen | `CreateFab` |
| Filtern | `FilterBar` + `applyItemListFilter`, darunter `ItemFilter` im Connector |
| Liste / Grid / Dichte | Linsen: `CollectionView`, `ListView`, `GridView` |
| Karte | `MapView` + Adapter (`maplibre`, `leaflet`) + Marker, `MapLens`, `LocationPick` |
| Kalender | `CalendarView` + `calendar-layout`, `date-utils` |
| Board mit Spalten und Drag | `KanbanBoard`, `KanbanToolbar`, `KanbanCardDetail`, `reorder` |
| Strom von Beiträgen | `PostCard`, `FeedComposerTrigger`, `SimplePostWidget` |
| Beziehungen visuell | `GraphView` + `force-layout` |
| Kommentare | `CommentSection`, `CommentThread`, `CommentBubble`, `CommentInput` |
| Reaktionen | `ReactionBar`, `ReactionPicker`, `ReactionDetails` |
| Abstimmen | `VoteBar` |
| Tags anzeigen | `TagChip`, `getTagColor` |
| Seitenpanel / Drawer | `AdaptivePanel`, `ModulePanel` — **eine Instanz app-weit**, siehe Grenzen |
| Dialog / Sheet | `Dialog`, `Sheet` aus den Primitives |
| Leerer Zustand | `EmptyState` |
| Kennzahlen, Aktionskacheln | `StatCard`, `ActionCard` |
| Aktivität und Benachrichtigungen | `ActivityPanel`, `ActivityBell`, `NotificationCenter` |
| Buttons, Inputs, Tabs, Avatar, Skeleton … | Primitives — **nie selbst stylen** |

## Datenzugriff

| Bedarf | Vorhanden |
|---|---|
| Items lesen (reaktiv) | `useItems`, `useFilterableItems` |
| Items schreiben | `useMutations`, `useItemEditor`, `useDraftItem` |
| Darf der Nutzer das? | `useItemPermissions` |
| Verwandte Items | `useRelatedItems`, `useRelationRecords` |
| Wer hat das erstellt | `useItemAuthor`, `useResolvedUsers`, `useUserNames` |
| Spaces / Mitgliedschaft | `useGroups` |
| Angemeldeter Nutzer | `useAuth` |
| Kommentare, Reaktionen, Votes | `useComments`, `useCommentCount`, `useReactions`, `useVotes` |
| Bestätigungen, Verifikation | `useConfirmations`, `useVerification` |
| Aktivität, Benachrichtigungen | `useActivity`, `useNotifications` |
| Was kann der Connector? | `useFeatures` + die Capability-Prüfungen (`hasRelations()`, `isWritable()`, …) |

Ein Modul spricht **nie direkt mit einem Connector oder Backend**. Es liest über Hooks und das `DataInterface`.

## Wo Neues hingehört

| Art | Ort |
|---|---|
| Neues Vokabular | `docs/spec/schemas/vocab/<name>/v1/` + `packages/data-interface/src/vocab.ts` |
| Neuer Typ | `packages/data-interface/src/type-manifest.ts` (Identität) + `registerTypePresentation` (Darstellung) |
| Wiederverwendbare Komponente | `packages/toolkit/src/components/…` — **nie in eine App** |
| Reine Darstellungsvariante | `packages/toolkit/src/components/lens/` |
| Modulübergreifender Helfer | `packages/toolkit/src/lib/` |
| Datenhelfer ohne UI | `packages/data-interface/src/` |
| Nur die Verdrahtung einer App | `apps/reference/src/views/` + `module-outlet.tsx` |
