# Grenzen — was der Stack heute nicht trägt

Dieser Text ist dazu da, den Nutzer zu **begrenzen**. Ein Modul, das eine dieser Grenzen überschreitet, wird nicht dadurch machbar, dass man es sorgfältiger baut — es wird zu einer Baustelle, die den Stack umbaut. Das ist eine Entscheidung für Anton, nicht für dich und nicht für den Nutzer.

Wenn ein Wunsch hier anschlägt: **sag es früh, sag es freundlich, und biete den kleineren Schnitt an**, der heute funktioniert.

## 1. Abfragen sind einfach

Der Connector kann nur nach `type`, `hasField`, `hasTag`, `createdBy`, `source`, `bbox` und `limit`/`offset` filtern. Alles andere passiert clientseitig auf der bereits geladenen Menge.

Nicht vorhanden: Volltextsuche, serverseitige Sortierung, Bereichsabfragen („alle Termine zwischen X und Y"), Joins über Relationen, Aggregationen (Summen, Durchschnitte, Gruppierungen), serverseitiges Clustering.

Heißt praktisch: Ein Modul, dessen Nutzen an einer Auswertung über zehntausend Items hängt, geht heute nicht. Eines, das ein paar hundert Items im Space sortiert und gruppiert darstellt, geht gut.

## 2. Kein Server, der rechnet

Die Daten sind Ende-zu-Ende verschlüsselt und syncen als CRDT zwischen Geräten. Es gibt keine Serverseite, die den Inhalt sieht.

Nicht vorhanden: serverseitige Berechnungen, zeitgesteuerte Jobs, E-Mail- oder Push-Versand aus einem Modul heraus, Webhooks, Auswertung über alle Spaces hinweg, „der Server erinnert dich".

Heißt praktisch: Alles, was ein Modul tut, tut es im Client eines Menschen, der gerade hinschaut.

## 3. Offline-first

Ein Modul muss ohne Netz sinnvoll bleiben. Es darf keinen externen Dienst als Voraussetzung haben. Externe Daten sind Anreicherung, nie Fundament.

## 4. Autorisierung ist grob

Berechtigungen gibt es pro Ressource für Erstellen, Bearbeiten und Löschen. Nicht vorhanden: Rechte pro Feld, Rollen-Matrizen, Freigabe-Workflows, „nur der Kassenwart darf den Betrag sehen".

Sichtbarkeit wird über **Spaces** geschnitten, nicht über Feldrechte. Wenn etwas nur eine Teilgruppe sehen soll, ist das ein eigener Space.

## 5. Beziehungen sind Kanten, keine Fremdschlüssel

Relations tragen keine referentielle Integrität: kein Cascade-Delete, keine erzwungene Kardinalität, keine Garantie, dass das Gegenstück existiert oder sichtbar ist. Ein Modul muss mit einer Kante ins Leere umgehen können.

## 6. Typen sind additiv

Das Typ-Register kennt in v0.1 kein Override. Ein neuer Beitrag kann Typen **einführen** oder vorhandene **ergänzen** — aber nichts ersetzen oder entfernen. Wer ein bestehendes Verhalten „nur für sein Modul" anders haben will, stößt hier an.

## 7. Eine Overlay-Fläche pro Ebene

App-weit gibt es ein Content-Panel, einen Dialog und Benachrichtigungen. Kein Panel im Panel, keine zweite Sidebar, kein mehrstufiger Wizard über gestapelte Flächen. Verschachtelte Flows laufen über einen Back-Stack in derselben Fläche.

## 8. Kein Workflow-Motor

Es gibt keine Statusmaschine mit Regeln, keine Genehmigungsketten, keine Automatisierung („wenn X, dann tue Y"). `status` ist ein Feld, kein Prozess. Ein Modul zeigt Zustände und lässt Menschen sie ändern.

## 9. Keine eigene Backend-Struktur

Ein Modul bekommt keine eigene Tabelle, keine Schema-Migration, keinen eigenen Endpunkt. Alles ist ein Item mit `@context` und `data`.

## 10. Ein Modul zeigt Bedeutung, es definiert sie nicht

Soziale Semantik gehört ins RLNP, Spielregeln ins Real Life Game, kryptografische Wahrheit ins WoT. Ein Modul, das anfängt, Vertrauen zu berechnen oder Punkte zu vergeben, baut in fremdem Gebiet.

## Verkleinern statt ablehnen

Wenn ein Wunsch zu groß ist, führ das Gespräch entlang dieser Fragen:

1. **Was ist die eine Sache, die jemand damit immer wieder tut?** Das ist V1. Der Rest ist später.
2. **Geht es auch mit einem vorhandenen Typ plus einem Feld mehr?** Fast immer ja.
3. **Braucht es eine eigene Ansicht, oder reicht eine Linse über vorhandene Items?** Eine Linse ist ein Bruchteil des Aufwands und bricht nichts.
4. **Was passiert, wenn man es weglässt?** Wenn die Antwort „dann macht man es weiter von Hand" ist, ist es V2.
5. **Wäre das ein eigener Space statt eines Moduls?** Trennung von Sichtbarkeit und Kontext löst überraschend viele vermeintliche Modul-Wünsche.

Ein gutes Ergebnis dieser Phase ist oft: **ein kleineres Modul als gewünscht, plus eine notierte Liste dessen, was bewusst nicht drin ist.** Diese Liste gehört in die Spec unter „Nicht-Ziele" und in den PR.
