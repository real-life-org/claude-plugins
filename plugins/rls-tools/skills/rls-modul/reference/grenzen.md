# Grenzen — was der Stack heute nicht trägt

Dieser Text ist dazu da, den Nutzer zu **begrenzen**. Ein Modul, das eine dieser Grenzen überschreitet, wird nicht dadurch machbar, dass man es sorgfältiger baut — es wird zu einer Baustelle, die den Stack umbaut. Das ist eine Entscheidung für Anton, nicht für dich und nicht für den Nutzer.

Wenn ein Wunsch hier anschlägt: **sag es früh, sag es freundlich, und biete den kleineren Schnitt an**, der heute funktioniert.

## Woher diese Grenzen kommen

Ein Modul läuft nicht gegen *ein* Backend, sondern gegen **jeden Connector** — heute mindestens `local`, `mock`, `supabase`, `graphql` und `wot`. Die Grenzen unten sind darum meist keine Aussage darüber, was technisch irgendwo möglich ist, sondern darüber, **was ein Modul voraussetzen darf**.

Der Vertrag ist das `DataInterface` plus die optionalen Capabilities. Was ein einzelner Connector darüber hinaus kann (der Supabase-Connector schränkt `bbox` z.B. serverseitig ein), ist seine Sache und bleibt für das Modul unsichtbar. Ein Modul, das die Fähigkeiten eines bestimmten Backends braucht, ist kein RLS-Modul mehr — es läuft in genau einer Konfiguration und bricht in allen anderen.

Der WoT-Connector ist dabei die **strengste** Konfiguration: Ende-zu-Ende verschlüsselt, CRDT-synchronisiert, kein Server, der den Inhalt sieht. Er setzt den Maßstab, weil ein Modul, das dort funktioniert, überall funktioniert — umgekehrt nicht.

Prüf im Zweifel mit `inventur.sh`, welche Capabilities es gibt, und behandle jede als optional.

## 1. Abfragen sind einfach

Abgefragt werden kann nur nach `type`, `hasField`, `hasTag`, `createdBy`, `source`, `bbox` und `limit`/`offset`. Alles andere passiert clientseitig auf der bereits geladenen Menge.

Nicht im Vertrag: Volltextsuche, Sortierung, Bereichsabfragen („alle Termine zwischen X und Y"), Joins über Relationen, Aggregationen (Summen, Durchschnitte, Gruppierungen), Clustering.

Heißt praktisch: Ein Modul, dessen Nutzen an einer Auswertung über zehntausend Items hängt, geht heute nicht. Eines, das ein paar hundert Items im Space sortiert und gruppiert darstellt, geht gut.

## 2. Kein Modul darf einen Server voraussetzen

Ob es eine rechnende Serverseite gibt, hängt am Connector — im WoT-Betrieb gibt es sie nicht, und dort sind die Daten für jeden Server ohnehin undurchsichtig. Ein Modul kann sich also auf keine verlassen.

Nicht im Vertrag: serverseitige Berechnungen, zeitgesteuerte Jobs, E-Mail- oder Push-Versand aus einem Modul heraus, Webhooks, Auswertung über alle Spaces hinweg, „der Server erinnert dich".

Heißt praktisch: Alles, was ein Modul tut, tut es im Client eines Menschen, der gerade hinschaut.

## 3. Ohne Netz muss es tragen

Der WoT-Connector arbeitet lokal-first, und die Reference-App läuft auch als native App. Ein Modul muss darum ohne Netz sinnvoll bleiben und darf keinen externen Dienst als Voraussetzung haben. Externe Daten sind Anreicherung, nie Fundament.

## 4. Autorisierung ist grob und optional

`AuthorizationCapable` ist eine **optionale** Capability: Manche Connectoren bieten sie, andere nicht — ein Modul muss beides aushalten. Wo es sie gibt, greift sie pro Ressource für Erstellen, Bearbeiten und Löschen.

Nicht im Vertrag: Rechte pro Feld, Rollen-Matrizen, Freigabe-Workflows, „nur der Kassenwart darf den Betrag sehen".

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
5. **Ist der Kern des Wunsches in Wahrheit Sichtbarkeit?** Dann löst ihn ein eigener Space, kein Modul — das ist eine Feststellung, die du triffst, keine Frage, die du dem Nutzer stellst. Frag ihn nie, in welchem Space sein Modul laufen soll: Das Modul wird für den Stack gebaut, die Aktivierung entscheidet später jeder Space für sich.

Ein gutes Ergebnis dieser Phase ist oft: **ein kleineres Modul als gewünscht, plus eine notierte Liste dessen, was bewusst nicht drin ist.** Diese Liste gehört in die Spec unter „Nicht-Ziele" und in den PR.
