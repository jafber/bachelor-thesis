<!-- Source: https://osm.hpi.de/theses/tipps -->

# Tipps für schriftliche Ausarbeitungen & Dokumentvorlagen

Um die Herangehensweise bei der Planung und Erstellung einer wissenschaftlichen Ausarbeitung zu erleichtern und vor allem die Form zu vereinheitlichen, fassen wir in diesem Leitfaden die aus unserer Sicht wichtigsten Aspekte einer schriftlichen Ausarbeitung zusammen.

Kontaktiert uns gern mit konkreten Änderungsvorschlägen. Alle [Mitarbeiter:innen der Professur für Betriebssysteme und Middleware](https://osm.hpi.de/people) können diese Webseite editieren und freuen sich über Konkretisierungen und Ergänzungen.

## Dokumentvorlagen (LaTeX)

Zur Gewährleistung eines einheitlichen Erscheinungsbildes und Vereinfachung der Arbeit an schriftlichen Ausarbeitungen bieten wir eine LaTeX-Vorlage für Bachelor- und Masterarbeiten mit Einstellungen zu Makrotypographie (wie Papiergröße, allgemeines Layout) und auch zur Detailtypographie (wie Schriftwahl) an.

### Einzelarbeiten/Monographien

Die Dokumentenvorlage *osm-thesis* enthält Struktur- und Formatierungsvorgaben sowie Hinweise zur Erstellung von formal korrekten Abschlussarbeiten nach den Vorgaben des Studienreferats und Ansprüchen der Professur Betriebssysteme & Middleware.

### **LaTeX-Vorlage „osm-thesis“ für Bachelor- und Masterarbeiten**

Coverpage, Titelseite, Inhaltsverzeichnis, Textteil mit Beispielen und Blindtext, Anhang, Literaturverzeichnis, Eigenständigkeitserklärung deutsch/englisch, Druckversion/Bildschirmversion sind formal korrekt nach den Vorgaben des HPI-Studienreferats.

Verbesserungsvorschläge sind sehr willkommen und können im [GitLab-Repositorium](https://gitlab.com/hpi-potsdam/osm/thesis-template) vorgeschlagen werden.

[LaTeX-Vorlage (ZIP) ZIP-Archiv vom Repositorium, ca. 1,5 MB](https://gitlab.com/hpi-potsdam/osm/thesis-template/-/jobs/artifacts/master/download?job=build) [LaTeX-Vorlage (Overleaf) kollaborativer Online-LaTeX-Editor](https://www.overleaf.com/latex/templates/osm-thesis-template/kpzhrwkmhbgq) [Beispieldokument PDF, ca. 800 kB](https://gitlab.com/hpi-potsdam/osm/thesis-template/-/jobs/artifacts/master/raw/thesis.pdf?job=build) <img src="https://gitlab.com/hpi-potsdam/osm/thesis-template/-/jobs/artifacts/master/raw/preview-1.png?job=previews" style="width: 100%" /> <img src="https://gitlab.com/hpi-potsdam/osm/thesis-template/-/jobs/artifacts/master/raw/preview-2.png?job=previews" style="width: 100%" /> <img src="https://gitlab.com/hpi-potsdam/osm/thesis-template/-/jobs/artifacts/master/raw/preview-4.png?job=previews" style="width: 100%" /> <img src="https://gitlab.com/hpi-potsdam/osm/thesis-template/-/jobs/artifacts/master/raw/preview-5.png?job=previews" style="width: 100%" /> <img src="https://gitlab.com/hpi-potsdam/osm/thesis-template/-/jobs/artifacts/master/raw/preview-6.png?job=previews" style="width: 100%" /> <img src="https://gitlab.com/hpi-potsdam/osm/thesis-template/-/jobs/artifacts/master/raw/preview-8.png?job=previews" style="width: 100%" />

Innerhalb der Vorlage *osm-thesis* stehen zwei Dokumentklassen zur Verfügung. Das Layout des Textbereiches ist in beiden Dokumentklassen identisch. **scrbook** ist die *Druckversion*; sie enthält eine Zusatzseite für den Einband und ist für den Zweiseitendruck formatiert. (u. a. Seitenränder, Kopf- & Fußzeilen, Leerseiten). **scrreprt** ist die *Bildschirmversion*; sie enthält keine unnötigen (Leer-)Seiten und ist für die Einzelseitenansicht formatiert.

### Sammlungsartige Berichte

Für Berichte, die sich aus mehreren Einzelbeiträgen zusammensetzen (z. B. Seminarzusammenfassungen) wird üblicherweise die [Vorlage für technische Berichte am HPI (hpitr)](https://github.com/HPI-SWA-Lab/hpitr/releases/latest) verwendet. Da für sammlungsartige Berichte zusätzliche Informationen und Metadaten bereitgestellt werden müssen, werden die jeweiligen Dokumentvorlagen von den Editoren und der Betreuung der Lehrveranstaltungen individuell vorbereitet und bereitgestellt.

## Anforderungen an Bachelor- und Masterarbeiten

Eine **Bachelorarbeit** soll demonstrieren, dass der Ingenieursprozess rund um verschiedene Aspekte des Entwurfs, der Implementierung und des Betriebs von komplexen IT-Systemen entsprechend des im Studium erlernten Wissens erfolgreich angewendet werden kann. Eine **Masterarbeit** besitzt eine forschungsorientierte Problemstellung, die umfassendes Fach- und Detailwissen aufzeigt und die gewissenhafte Anwendung der wissenschaftlichen Methoden aufweist. In beiden Fällen wird der Kontext eines Problems absteckt, das Ziel und die Durchführung genau beschrieben und in einer überzeugenden Schlussfolgerung bewertet.

### Bachelorarbeiten

Die Studien- und Prüfungsordnung besagt folgendes:

> Die Bachelorarbeit \[…\] soll zeigen, dass die Kandidatin oder der Kandidat in der Lage ist, innerhalb begrenzter Zeit ein Problem aus einem Fach ihres oder seines Studiengangs mit wissenschaftlichen Methoden selbstständig zu bearbeiten und die Ergebnisse sachgerecht darzustellen.
>
> \[26 Abs. 1 SPO BAMA-O, AmBek Nr. 3, 2013, S. 35-55\]

> Themen für Bachelorarbeiten bilden anwendungsbezogene und/oder theoretische Aspekte aus dem Gebiet IT-Systems Engineering. Die Themenstellung einer Bachelorarbeit erwächst in der Regel aus der Softwareprojekttätigkeit und beinhaltet typische softwaresystemtechnische Prozesse und Ergebnisse (z. B. Prototypenbau, Implementierungen, Modellierungen).
>
> \[8 Abs. 3 SPO IT-Systems Engineering, AmBek Nr. 14, 2016, S. 1378-1383\]

*Diese Anforderungen können auf vielfältige Weise erreicht werden. Bachelorarbeiten, die von den folgenden Ratschlägen abweichen, können selbstverständlich ebenso zu einem erfolgreichen Ergebnis führen.*

Aus Sicht der Professur Betriebssysteme & Middleware geht es bei einer Bachelorarbeit grundsätzlich darum, *Ingenieurskompetenz unter Beweis zu stellen*. Das bedeutet:

1.  Ein Problem **identifizieren** und **analysieren**.
2.  Verschiedene Lösungsansätze **identifizieren**, **gegenüberstellen** und bezüglich des Problems **bewerten**.
3.  Den gewählten Lösungsansatz **umsetzen** und **dokumentieren**.

Dabei steht nicht das Ziel im Mittelpunkt, sondern der Weg dorthin. Statt die Features des Endproduktes aufzulisten soll bewertet werden, welche Konzepte der Lösung auf welche Art die ursprünglichen Probleme lösen. Besonders wichtig ist es, die Anwendung des ingenieursmäßigen Prozesses zu demonstrieren. Wir wollen sehen, dass ihr ingenieursmäßig arbeiten könnt – nicht einfach blind den erstbesten Lösungsweg stumpf implementieren, der einem gerade so einfällt, sondern auch mal über den Tellerrand blicken, Alternativen anschauen und vor allem über alle möglichen Implikationen nachdenken, die mit so einer Entwurfsentscheidung einhergehen.

- ⚠️ Nicht sofort/nur Implementierungen beschreiben, sondern vorher unbedingt auch ausreichend darlegen, was, wie, und vor allem warum genau so implementiert wird.
- ⚠️ Gegenüberstellungen von Alternativen sind viel spannender und wichtiger als Detailwissen über ein bestimmtes Tool oder Framework, das in ein paar Jahren schon wieder "out" sein wird. Lieber diskutieren, welche Trade-Offs es gab, was die überraschenden/herausragenden Aspekte an einem Werkzeug sind.
- ⚠️ Nicht nur das beschreiben, was ihr gemacht habt, sondern unbedingt auch, wieso ihr es genau so (und nicht anders) gemacht habt. Erklärungen und Tutorials für Werkzeuge findet man im Internet, aber was ihr euch bei euren Entscheidungen gedacht habt, nicht!
- ⚠️ Unter Beweis stellen, dass eure Implementierung durchdacht ist – also ihr euch sowohl mit Vor- als auch Nachteilen der Werkzeuge und auch mit deren Alternativen beschäftigt habt!
- ⚠️ Klar und deutlich eure eigene Leistung herüberbringen. (Beispielsweise durch Aufzählen, was vorher alles nicht ging und jetzt – dank eurer Arbeit – möglich ist.)
- ⚠️ Keine Schönfärberei und Verharmlosung von eher unliebsamen Eigenschaften! Sachverhalte kritisch hinterfragen und differenziert analysieren. Wenn irgendwas als besser, schneller, weiter, etc. gelobt wird, dann muss das auch entsprechend begründet und mit Fakten untermauert werden.

<!-- -->

- In der Gliederung der Arbeit darauf achten, dass einzelne Phasen (z. B. Entwurf, Implementierung, Betrieb) getrennt voneinander behandelt werden ("durcheinander erzählen" vermeiden).
- Nicht vergessen, zu zeigen, dass Anforderungen erfüllt werden, wie das gemessen wurde und warum Variante X besser ist als Variante Y.
- Obwohl ihr separate Werke verfassen sollt, ist es in Ordnung und sogar wünschenswert, wenn ihr euch bei gemeinsamen Abschnitten (Motivation, Domäne, Architektur) absprecht und auch Querbezüge aufbaut.
- Falls es ums Kürzen geht – unbedingt Abschnitte zu z. B. Alternativtechnologien, die ihr nicht verwendet habt, drin lassen und stattdessen die Erklärungen für die Werkzeuge, die ihr tatsächlich verwendet habt, kürzen.
- Ihr solltet auch den Ablauf des Projektes, die Rollenverteilung und auch die arbeitsteilige Vorgehensweise im Team beschreiben. Wie wurden Teilaufgaben im Team verteilt? Welche Rolle haben die einzelnen Kommilitonen gespielt? Wer hatte die Teamleitung inne? Hat sich die Rollenverteilung im Laufe des Projektes geändert? Wie war die Kommunikation mit dem Auftraggeber? Wer hat welchen Anteil an Design, Implementierung und experimenteller Evaluierung?

⚠️ Beim Inhalt und Aufbau achten wir besonders darauf, dass die folgenden Punkte nicht nur irgendwo in der Arbeit wiederzufinden sind, sondern auch, dass diese Punkte eindeutig erkennbar sind:

- Abgrenzung der eigenen Arbeit (Was genau habt ihr gemacht? Was geht dank euch jetzt, was vorher nicht ging? Insbesondere auch das, was ihr mit Absicht nicht gemacht habt)
- Analyse der vorhandenen Mittel/Bestandsanalyse (Was gab es schon? Welche Anforderungen gibt es? Welche verschiedenen Wege gibt es, das Problem zu lösen? Wurden verwandte Arbeiten ausreichend beschrieben?)
- Plausibilität der Lösungswahl (Welcher konkrete Lösungsweg wurde gewählt und warum?)
- Evaluierung der Lösung (Wie ist der Nachher-Stand? Zeigen, dass die Lösung funktioniert!)

Die Länge der Bachelorarbeit sollte zwischen 30 und 50 Textseiten betragen (darin *nicht* enthalten sind: Titelei, Kurzfassung, Anhang, Literaturverzeichnis).

### Masterarbeiten

Die Studien- und Prüfungsordnung besagt folgendes:

> Die Masterarbeit soll zeigen, dass die Kandidatin bzw. der Kandidat \[...\] erweiterte und vertiefte Fachkompetenzen erworben hat, Theorie und Empirie zu verbinden vermag und fähig ist, eine stärker forschungs- oder stärker anwendungsorientierte Problemstellung auf fachwissenschaftlicher Grundlage mit fachwissenschaftlichen Methoden innerhalb einer vorgegebenen Frist zu bearbeiten und die Ergebnisse in formal, sprachlich und sachlich überzeugender Weise darzustellen.
>
> \[30 Abs. 1 SPO BAMA-O, AmBek Nr. 3, 2013, S. 35-55\]

*Diese Anforderungen können auf vielfältige Weise erreicht werden. Masterarbeiten, die von den folgenden Ratschlägen abweichen, können selbstverständlich ebenso zu einem erfolgreichen Ergebnis führen.*

Aus Sicht der Professur Betriebssysteme & Middleware wird in einer Masterarbeit ein größerer Fokus auf eine wissenschaftliche Vorgehensweise gelegt – die methodisch systematische Tätigkeit mit dem Ziel, in nachprüfbarer Weise neue Erkenntnisse zu gewinnen. Im Gegensatz zu einer Bachelorarbeit wird auch ein höheres Maß an Selbstständigkeit erwartet. Die Masterarbeit soll:

1.  **Neue spezielle Erkenntnisse** liefern.
2.  Diese Erkenntnisse **begründen** und **objektiv nachvollziehbar beschreiben**.
3.  Diese Erkenntnisse **bewerten**.

In der Masterarbeit sollen neue Problemlösungen gefunden bzw. vorhandene Lösungen verbessert werden. Im Optimalfall leistet die Masterarbeit einen wichtigen Beitrag zur Weiterentwicklung des Wissenschaftsgebietes, indem sie beispielsweise aus laufenden oder abgeschlossenen wissenschaftlichen Arbeiten *bekannte Lösungen vertieft, verbreitert, bestätigt oder widerlegt* oder *aus einem neuen Blickwinkel betrachtet* bzw. *an einen neuen Anwendungsfall anpasst*.

Zusätzlich zu den Anforderungen an Bachelorarbeiten gilt bei Masterarbeiten:

- ⚠️ Zu einem frühen Punkt der Arbeit sollten eine oder mehrere *Forschungshypothesen* ([Wie wird Hypothese aufgestellt?](http://de.wikihow.com/Eine-Hypothese-aufstellen)) aufgestellt werden. Im Laufe der Arbeit sollten diese Hypothesen durch Beobachtungen oder Experimente getestet werden. Die gesammelten Daten dienen dazu, die Nullhypothese zu widerlegen und damit die Forschungsthesen zu unterstützen.
- ⚠️ Ein Überblick über die in der Literatur vorhandenen Methoden bzw. Lösungsansätze, den aktuellen Stand der Technik sowie verwandte Arbeiten sind zwingend erforderlich.
- ⚠️ Alle Aussagen müssen belegt werden: Entweder durch Quellen/Zitate, getestete Forschungshypothesen oder durch eine gewissenhafte Argumentation bzw. einen Beweis.
- ⚠️ Für die Durchführung von Messungen ist es zwingend erforderlich, die verwendete Testumgebung (Hardware wie auch Software) zu dokumentieren sowie Messparameter gewissenhaft zu wählen. Zu den wichtigsten Parametern gehören die Anzahl der Messwiederholungen, die Anwendung von Warmup-Läufen sowie die Identifikation und Vermeidung möglicher störender Einflüsse.
- ⚠️ Ebenso wichtig sind die Auswertung und Präsentation der Messdaten: Durchschnittswerte ohne die Angabe von Standardabweichung sind nicht aussagekräftig. Um Messresultate für Tests der Hypothesen heranzuziehen, ist die Anwendung von statistischen Methoden wie dem *t-Test* oder der *Varianzanalyse (ANOVA)* dringend anzuraten.
- ⚠️ Eigene Leistungen sollten immer deutlich von Fremdleistungen unterschieden werden. Dies gilt insbesondere für Masterarbeiten, welche auf vorhandenen Arbeiten oder Technologien aufbauen oder zeitgleich zu thematisch ähnlichen Masterarbeiten bearbeitet werden.

<!-- -->

- Bei der Gegenüberstellung der verwandten Arbeiten sollte herausgestellt werden, dass der Forschungsschwerpunkt der Arbeit relevant und noch zu bearbeiten ist.
- Die Konzepte der Lösung stehen im Mittelpunkt. Die entwickelten Softwareprototypen dienen nur zur Bewertung der Konzepte.
- Bei Nutzung vorhandener oder selbst entwickelter Softwareprototypen müssen diese so ausführlich beschrieben werden, dass Lesende von der Verlässlichkeit der Ergebnisse unter den zu erläuternden Anwendungsbedingungen überzeugt ist.
- Bei Experimenten müssen die eingesetzten Technologien, Systeme und Verfahren so beschrieben werden, dass Lesende von der ordentlichen Planung und Glaubwürdigkeit überzeugt sind. Es müssen ausreichend Details angegeben werden, um eine Wiederholung der Experimente und die Beobachtung der gleichen Ergebnisse zu ermöglichen.
- Im Ausblick den Nutzen der neuen Problemlösung bzw. der neuen Erkenntnisse mit Bezug auf den derzeitigen Stand der Wissenschaft und mögliche zukünftige Probleme oder vergleichbare Problemdomänen diskutieren.
- Die Bewertung eurer Lösung und der verwandten Arbeiten sollte anhand von einheitlichen, vorher definierten Metriken erfolgen. Sollte die Kategorisierung der verwandten Arbeiten anhand dieser Metriken größere Lücken aufweisen, sind diese unter Hinzunahme entsprechender weiterer verwandter Arbeiten zu schließen.
- Eine entsprechende Gliederung *könnte* wie folgt aussehen: *Einleitung (Domäne, Problem & Beitrag der Arbeit), Problemhintergrund/Motivation, verwandte Arbeiten, Abgrenzung, Entwurf, Umsetzung, Evaluierung, abschließende Auswertung & Bewertung*

Die Länge der Masterarbeit sollte zwischen 60 und 80 Textseiten betragen (darin *nicht* enthalten sind: Titelei, Kurzfassung, Anhang, Literaturverzeichnis).

Für Masterarbeiten gibt es außerdem ein paar [Tipps bezüglich des organisatorischen Prozesses](https://osm.hpi.de/theses/masters/prozess).

## Der strukturelle Aufbau einer schriftlichen Ausarbeitung

Im Allgemeinen ist eine schriftliche Ausarbeitung nach dem folgenden Schema aufgebaut: Nach der Titelei (*Titelseite, Kurzfassung, ggf. Danksagung, Inhaltsverzeichnis*) beginnt der Textteil, der die eigentlichen Inhalte der Arbeit umfasst. Dieser besteht üblicherweise aus einer *Motivation der Problemstellung*, einem *Grundlagenteil*, der eigentlichen *Behandlung der Problemstellung* sowie einer *Zusammenfassung der zentralen Ergebnisse*. Dem Textteil folgt ein Anhang mit dem *Literaturverzeichnis*, ggf. ergänzenden *Bild- und Quelltextmaterialien* und der *Eigenständigkeitserklärung*.

- Die **Kurzfassung** ("Abstract") stellt die wichtigsten Inhalte dar. Sie muss objektiv und so kurz wie möglich sein. Sprache und Struktur müssen klar und nachvollziehbar sein. Es müssen alle wesentlichen Fragestellungen, Ansätze und Erkenntnisse enthalten der gesamten Ausarbeitung wiedergeben werden.
- Im Zentrum der **Einleitung** stehen die *Vorstellung und Motivation des Themas der Arbeit* und die genaue Auflistung der Fragestellungen (Wieso ist das Thema relevant?). Ebenso sollten schon einzelne Aspekte des Problems herausgearbeitet werden. Dabei ist es hilfreich, die zentralen Fragen aufzulisten, die im Rahmen der Arbeit beantwortet werden sollen. Außerdem sollte ein knapper Überblick gegeben werden, in welchen Schritten die Problembehandlung erfolgt: Hinführung zum Thema, Herleitung und Ausformulierung der Fragestellung, Abgrenzung des Themas (Angabe von Aspekten, die zum Thema gehören, aber ausgeklammert werden) und Aufbau der Arbeit (Begründung der Gliederung).
- Im **Grundlagen**-Teil sollen *zentrale Begriffe definiert und eingeordnet* werden. Es geht dabei nicht darum, Definitionen aus Lexika zu suchen; stattdessen sollen problemorientierte Definitionen gegeben werden. Häufig können einzelne Begriffe unterschiedlich weit oder eng definiert werden, sodass auch eine Diskussion unterschiedlicher Definitionsansätze hilfreich sein kann, bevor eine für die weitere Arbeit verbindliche Definition gewählt wird. ⚠️ Zudem sollte ein Überblick über die in der Literatur vorhandenen Methoden bzw. Lösungsansätze, der aktuelle Stand der Technik und verwandte Arbeiten gegeben werden.
- Im **Hauptteil** der Arbeit erfolgt die eigentliche Auseinandersetzung mit der Problemstellung. Hier kommt es darauf an, die *Problemstellung reflektiert in logischen, nachvollziehbaren Schritten zu bearbeiteten*. Aussagen müssen durch herangezogene Literatur gestützt und belegt werden. Siehe auch Anforderungen an [Bachelorarbeiten](#bachelorarbeiten) und Anforderungen an [Masterarbeiten](#masterarbeiten).
- In der **Schlussbetrachtung** gibt es einen *Rückblick*, in dem Motivation und Thesen aus der Einleitung wieder aufgegriffen und abgerundet werden. Antworten auf in der Problemstellung aufgeworfene Fragen werden *kurz und prägnant zusammengefasst*. Ebenso sollte ein *Ausblick* auf offen gebliebene Fragen sowie auf interessante Fragestellungen, die sich aus der Arbeit ergeben, gegeben werden. Ein persönlich begründetes Fazit aus eigener Perspektive ist an dieser Stelle ebenfalls sinnvoll.

Die einzelnen Teile der Arbeit sind üblicherweise folgendermaßen aufgebaut:

### Kurzfassung ("Abstract")

Die Kurzfassung ist die *tl;dr-Version* der Ausarbeitung. Sie muss Lesenden genügen, um den Inhalt der Arbeit wiedergeben zu können. Nur wenn sie die Details benötigen, sollten sie die Arbeit lesen müssen. Üblicherweise genügen *ein bis zwei Sätze pro Kapitel* der Arbeit.

- ⚠️ Die Kurzfassung ist keine Einleitung. Sie muss unabhängig von der Arbeit betrachtet werden. Ein gedankliches Werkzeug kann sein, die Kurzfassung so zu schreiben, als gäbe es den Rest der Arbeit nicht.
- ⚠️ Die Zusammenfassung ist kein *Teaser*, sondern ein *Spoiler*. Sie muss alle (!) wichtigen Inhalte der Arbeit prägnant beinhalten.
- ⚠️ Nicht nur abstrakt "verschiedene Methoden", "ausgewählte Algorithmen" o. ä. schreiben, sondern genau die betrachteten Methoden, die konkret ausgewählten Algorithmen o. ä. nennen!

<!-- -->

- Nur die Kernaussagen der Ausarbeitung gehören – kurz und klar formuliert – in die Kurzfassung.
- Keine Worte verschwenden. Keine Meta-Formulierungen verwenden ("In dieser Ausarbeitungen wird auf …", "Inhalt des Artikels ist …"). Nicht die Überschrift wiederholen. Nicht "labern".
- Quellenangaben in der Kurzfassung sind eher unüblich.
- Den Inhalt der Kurzfassung auch entsprechend des Inhalts in der eigentlichen Ausarbeitung aufteilen. Wenn Kapitel 4 die Hälfte des Dokuments ausmacht, sollte auch ca. die Hälfte der Kurzfassung mit Kapitel 4 zu tun haben.
- Die Kurzfassung darf sich nicht wie ein Inhaltsverzeichnis lesen, sondern muss kommunizieren, was Lesende aus den Kapiteln mitnehmen würden.
- Es dürfen Sätze und Formulierungen aus der Arbeit wiederverwendet werden.

### Einleitung

Die Einleitung eurer Arbeit muss kurz ins Thema einführen, die Domäne erklären und die Motivation darstellen, wozu ihr die Ausarbeitung geschrieben habt, und möglichst noch genügend Hintergrundinformationen geben; also kurz alle Grundlagen schaffen, um auch mit wenigen Vorkenntnissen die kommenden Abschnitte zu verstehen. Die Motivation umfasst die knappe Einführung in die *Problemdomäne*, die Beschreibung des *Problems* sowie des *Vorgehens* der Arbeit zur Bearbeitung des Problems mit einem Überblick über den Aufbau der Arbeit\*. Die Einleitung schafft den Kontext der Ausarbeitung.

- ⚠️ Die Motivation darf nicht auf der Kurzfassung aufbauen, sondern muss als Startpunkt der Ausarbeitung dienen.
- ⚠️ Die zentralen Fragen aufzulisten, die im Rahmen der Arbeit beantwortet werden.
- ⚠️ Es muss für die an der Durchführung der Arbeit unbeteiligten Lesenden verständlich und nachvollziehbar sein – lieber etwas mehr Kontext und Hintergrundwissen vermitteln.

<!-- -->

- Das Problem und die Forschungsfragestellung als relevant und aktuell darstellen – ggf. mit Verweis auf aktuelle Veröffentlichungen, Vorträge, Geschehnisse oder Presseberichte.
- Ergebnisse der Arbeit dürfen auch hier erwähnt werden.
- Wenn nötig, kann die Terminologie hier schon eingeführt werden.
- Die Problemdomäne kurz anreißen und ggf. auf weiterführende Literatur verwiesen.

### Grundlagen

Der Grundlagenteil definiert *zentrale Begriffe (Terminologie)* und führt *wichtige Konzepte und Technologien* ein, die für die Arbeit relevant sind. Allgemeines wird sehr knapp formuliert, die *problembezogenen Aspekte* werden hervorgehoben und ggf. ausführlicher diskutiert. Der *Fokus/Kontext* der Arbeit wird klar kommuniziert – dazu werden *Problemaspekte*, *Annahmen* und *Einschränkungen* diskutiert. Dazu zählen neben den Möglichkeiten auch die *Herausforderungen und Limitierungen* der Konzepte/Technologien.

- ⚠️ Allgemeine Grundlagen durch Zitate aus Lehrbüchern abdecken, statt dieses Kapitel aufzublähen.
- ⚠️ Detaillierte Beschreibungen nur für die Aspekte der Grundlagen, die für die Arbeit notwendig sind. Alles weitere durch Zitate abdecken.
- ⚠️ Keine Lücken! Alles Hintergrundwissen muss vom Text und der verwiesenen Literatur abgedeckt sein.
- ⚠️ Keinen Platz für Werbematerial wie Logos verschwenden. Lieber Architekturdiagramme, falls sie für das Verständnis wichtig sind.
- ⚠️ Keine Definitionen aus dem Lexikon paraphrasieren, sondern eigene problemorientierte Definitionen verwenden.

<!-- -->

- Eine Diskussion alternativer Definitionsansätze kann hilfreich sein, bevor eine für die weitere Arbeit verbindliche Definition gewählt wird.
- Zur Abgrenzung des Themas sollten auch Aspekten identifiziert werden, die zum Thema gehören, aber ausgeklammert werden.

### Hauptteil

Die Gliederung bzw. Gestaltung des Hauptteils hängt weitestgehend vom Thema und der gewählten Vorgehensweise der Arbeit ab. Bestandteile sind beispielsweise die Beschreibung eines Entwurfs, dessen Umsetzung und die Erläuterung von Umsetzungsalternativen sowie die Evaluierung und Bewertung. Für die Evaluierung gibt es verschiedene Möglichkeiten: Implementierung eines Prototyps, Vergleich mit bestehenden/anderen Lösungen, Benutzerstudie, etc.

Die unterschiedlichen Anforderungen an den Hauptteil können in Anforderungen an [Bachelorarbeiten](#bachelorarbeiten) und Anforderungen an [Masterarbeiten](#masterarbeiten) nachgelesen werden.

### Schlussteil

Der Schluss liefert die Kernaussagen der Arbeit. Die abschließenden Worte fassen die Antwort(en) auf die in der Problemstellung aufgeworfenen Fragen prägnant zusammen. Es erfolgt eine *kritische Betrachtung* der Möglichkeiten und Limitierung der eigenen Arbeit. Es ist üblich, offen gebliebene Fragen und interessante Fragestellungen, die sich aus der Arbeit ergeben, zu diskutieren und einen Ausblick auf zukünftige (Folge-)Arbeiten zu geben.

- ⚠️ Die zentralen Ergebnisse zusammenfassen.
- ⚠️ Die ermittelten Vor- und Nachteile der betrachteten Sachverhalte bewerten.
- ⚠️ Einen Ausblick auf mögliche Anknüpfungspunkte geben.

<!-- -->

- Es gibt hier üblicherweise keine Quellenangaben, da man das bisher Betrachtete zusammenfasst.
- Hier ist (der einzige) Platz dafür, um eigene Sichtweisen und Meinungen in einer Arbeit unterbringen. Aber nicht zu sehr aus dem Fenster lehnen und beim Thema der Arbeit bleiben!

### Literaturverzeichnis, Zitate und Quellenangaben

Grundsätzlich sind die in der Arbeit verwendeten Quellen – aus denen zur Stützung der Argumentation zitiert oder auf die man sich sinngemäß bezieht – in einem Literaturverzeichnis anzugeben. Literatur, die nicht zitiert wird, gehört auch nicht in das Literaturverzeichnis.

- ⚠️ Zitate sind in geeigneter Form zu kennzeichnen. Es muss erkennbar sein, ob ein ganzer Text übernommen oder nur sinngemäß den Inhalt in eigenen Worten wiedergegeben wurde.
- ⚠️ Verwendet Programme zum Verwalten eurer Quellen und Erstellen von bib-Dateien! (Tipp: [Zotero](https://www.zotero.org))
- ⚠️ Einträge im Literaturverzeichnis müssen mit allen zur Verfügung stehenden Daten (Titel, Autor\[en\], Herausgeber, Verlag, Jahr, ISBN, Ausgabe, Seitenzahlen, Konferenzname, Ort, DOI, URL, Abrufdatum, Publikationsstatus, …) erstellt werden.
- ⚠️ Verweise auf Quellen müssen einheitlich formatiert sein; vor oder nach dem Satzzeichen, mit oder ohne Leerzeichen – Hauptsache im ganzen Text einheitlich!
- ⚠️ **Fußnoten** sollten für allgemeine Sachen verwendet werden, die einem helfen, weitere Infos zu finden (z. B. Produktwebseiten), die aber sonst nicht weiter wichtig sind bzw. die nicht als Quelle eines Zitats dienen. Quellen von Zitaten – sowohl wörtlich, bildlich als auch sinngemäß – sind immer wichtig und gehören ins Literaturverzeichnis.

<!-- -->

- Aussagen sollten primär aus der klassischen Literatur belegen lassen. Bei Internetquellen ist deren Verlässlichkeit, Wahrheit und Reife zu bewerten.
- Bei Webseiten als Quelle muss zumindest die konkrete URL angeben werden. Besser: Zusätzlich auch Seitentitel und Abrufdatum.
- Nicht vergessen: Bilder, die ihr nicht selbst erstellt habt, entsprechend mit einer Quellenangabe versehen.
- Die Grafiken nicht alle einzeln referenzieren, sondern das Dokument, in dem sie vorkommen.
- Nicht nur allgemeine "Sammel"-Quellen referenzieren (z. B. gesamte Vorlesungsreihen). Das ist nicht hinreichend; es ist besser, die in der Vorlesung verwendete Literatur als Quellenangaben zu verwenden.
- Immer klar abgrenzen, was tatsächlich in der Literatur gesagt wurde, und was persönliche Auslegung ist.
- Falls immer wieder die gleiche Quelle für unterschiedliche Aussagen verwendet wird: Die Originalzitate als Quelle heraussuchen und diese (getrennt) referenzieren.
- Falls Quellen aus Wikipedia sind: Damit die Ausarbeitung von Wissenschaftlern ernst genommen würde, wäre es besser, richtige Papers, die bei Springer, IEEE, ACM etc. indiziert sind, zu zitieren. Hack: Die Quellen unter den Wikipedia-Artikeln zurate ziehen. Vielleicht sind da seriöse Veröffentlichungen dabei…
- Man kann bei Verweisen auch gern den Autorennamen verwenden – "Müllermeierschmidt untersucht in \[42\] …" (statt nur "\[42\] schreibt …").

## Inhalt & roter Faden

Der Inhalt muss so dargestellt werden, dass Lesende der Argumentation folgen können. Lesenden muss jederzeit klar sein, weshalb alles, was sie lesen, wichtig für das Ergebnis ist. Argumente sind aus verschiedenen Positionen zu betrachten und deren Gemeinsamkeiten sowie Unterschiede herauszuarbeiten. Inhalte müssen relevant, richtig, sachlich und nachvollziehbar sein und zueinander in Bezug gesetzt werden. Ihr solltet erkennen lassen, dass ihr zwischen Wichtigem und Unwichtigem sowohl in der eigenen Arbeit als auch in den Arbeiten anderer unterscheiden könnt.

Der rote Faden muss auf mehreren Ebenen sichtbar werden: Auf der Gliederungsebene (Grobstruktur & Ausgestaltung der einzelnen Gliederungspunkte), auf der der gedanklichen Ebene (Verknüpfung der Argumente) und auf der der sprachlichen Ebene (Verbindungswörter, ein- und überleitende Textpassagen).

### Gliederung

Die Ausarbeitung darf nicht so aussehen, als ob ihr wahllos verschiedene Absätze aneinandergeklebt habt, sondern es muss ein roter Faden ersichtlich sein.

- ⚠️ Ein roter Faden ist essentiell! Alles muss aufeinander aufbauen; keine zusammengewürfelten Absätze.
- ⚠️ Die Gliederung muss logisch aufgebaut sein. Inhaltliche Schwerpunkte müssen darin zum Ausdruck kommen.
- ⚠️ Struktur herausarbeiten mit `\section`, `\subsection`, `\paragraph`. ABER: Die Gliederung darf nicht durch zu viele Gliederungspunkte zergliedert sein bzw. zu tief gliedert sein.
- ⚠️ Bei Untergliederungen muss bei gleicher Gliederungstiefe auch der gleiche Abstraktionslevel herrschen.

<!-- -->

- Der Bezug zur eigentlichen Fragestellung darf nicht aus den Augen gelassen und sollte immer mitformuliert werden. Hilfreich sind dabei Anfang und Schluss eines Kapitels.
- [State the problem before describing the solution](https://www.microsoft.com/en-us/research/publication/state-problem-describing-solution/) & [Problem-Solution Ordering Issues](http://mkremins.github.io/blog/doors-headaches-intellectual-need/).
- Auch die einzelnen Abschnitte sollten Einleitung, Hauptteil, Schluss enthalten. Die Einleitung und Schluss sollten dabei die Überleitung zu den umschließenden Abschnitten realisieren.
- Absätze sollten aufeinander aufbauen. Wenn man Absätze (Kapitel, Abschnitte, etc.) beliebig vertauschen kann, gibt es keinen roten Faden.
- Vermeidet "Micro-Absätze", die nur aus wenigen bzw. einem einzigen Satz bestehen. Das deutet darauf hin, dass die behandelten Gedanken nicht vollständig ausgeführt und entwickelt wurden.
- Die Strukturierung in Einleitung+Hauptteil+Schluss nicht nur im gesamten Dokument verwenden, sondern (mind.) auch jeweils in den einzelnen Kapiteln.

### Argumentation

Ein wichtiges Merkmal einer wissenschaftlichen Arbeit ist, dass Aussagen für Dritte objektiv nachprüfbar sein müssen. Jede Entscheidung muss sachlich begründet werden. Thesen, Argumente und Beispiele müssen korrekt, genau und vollständig sowie aufeinander bezogen sein. Inhaltlich kommt es besonders auf eine sachliche Darstellung und kritische Diskussion des Problems an. Das bedeutet auch, dass mögliche Nachteile des gewählten Lösungsansatzes angesprochen und betrachtet werden müssen.

- ⚠️ Verwendete Argumente sollten in ausreichender Menge vorhanden und müssen relevant, korrekt und aktuell sein.
- ⚠️ Informationen zueinander in Beziehung setzen. Am Ende jedes Kapitels sollten die erarbeiteten Gedanken in ihrer Bedeutung für die Beantwortung der Fragestellung zusammengefasst werden.
- ⚠️ Allaussagen und Pauschalisierungen vermeiden. Alle Allaussagen sind falsch! Nicht unnötig angreifbar machen. Gelten Aussagen wirklich immer? Oder nur "in der Regel", "größtenteils", "überwiegend", etc.
- ⚠️ Nicht einfach nur Dinge behaupten (xyz ist jetzt besser, stabil, etc.) – sondern nachvollziehbar (messbar!) begründen bzw. Quellen dafür angeben.
- ⚠️ Nicht leichtfertig Werbebegriffe übernehmen (z. B. "instantaneous recovery", "vollständig flexibel", "skalierbar", "hochverfügbar"). Solche Eigenschaften gelten in der Regel nur unter bestimmten Voraussetzungen bzw. Einschränkungen.

### Gewichtung

Wichtige Aussagen sollten mehr Platz in der Ausarbeitung erhalten; weniger wichtige weniger; unwichtige keinen.

- ⚠️ Keinen Platz verschwenden. Wiederholungen reduzieren. Trivialitäten minimieren.
- ⚠️ Dinge, über die geneigte Lesende alles selbst herausfinden können, ohne eure Arbeiten zu lesen, müssen nicht detailliert auf vielen Seiten erklärt werden. Viel besser ist, einfach auf eine Quelle zu verweisen, in der das gut erklärt wird. Diese Quelle ist auch wichtig!

<!-- -->

- (Forschungs-)Tätigkeiten, die viel Zeit in Anspruch genommen haben, dürfen gern auch entsprechend in der Arbeit gewürdigt werden. Dazu bietet es sich an, diese detaillierter zu diskutieren – dazu ist es möglicherweise notwendig die Forschungsfragen auszuweiten.
- Lesende mögen keine anderthalb Seiten, die keinen Beitrag liefern (z. B. halbseitige Screenshots von Twitter-Posts).

## Sprachlich-formale Aspekte

Wissenschaftliche Ausarbeitungen dienen der Wissensvermittlung – es ist überaus wichtig, Lesenden die Informationsaufnahme möglichst einfach zu machen, Inhalte logisch zu gliedern und in guter sprachlicher Form darzustellen.

### Textverständlichkeit

Der Text ist logisch aufzubauen und so zu formulieren, dass er auch für den nicht an der Durchführung der Arbeit beteiligten Lesenden verständlich und nachvollziehbar ist. Die behandelten Themen müssen leicht erkennbar sein. Größere Abschnitte sollten einen kurzen Überblick über ihre Inhalte geben. Die Verständlichkeit des Textes kann durch die Verwendung von kurzen Sätzen, einer einfachen, aber fachsprachlich korrekten Wortwahl und durch die Vermeidung von Füllworten und überflüssigen Fremdworten wesentlich erhöht werden.

- ⚠️ Keine Prosa, sondern präzise Begriffe und Sätze!
- ⚠️ Eine einheitliche Terminologie verwenden, damit Begriffe wiedererkannt werden können.
- ⚠️ Zentrale Begriffe klären und die Arbeit für interessierte Laien verständlich halten.
- ⚠️ Pure Textblöcke, die sich über mehrere Seiten erstrecken, sind ein Zeichen für mangelnde strukturelle Leseunterstützung. Weiter unterteilen oder variantenreichere Inhaltsarten (Schriftarten, Listen, Diagramme, Tabellen, ...) einsetzen.
- ⚠️ Das schnelle überfliegen des Textes und das Springen in der Arbeit muss aktiv unterstützt werden. Lesende müssen jederzeit die wesentlichen gerade diskutierten Themen schnell erkennen und auch bestimmte vorher schon einmal gelesene Fakten schnell wiederfinden können.
- ⚠️ Kurz einen Gesamtüberblick (Einordnung ins "große Bild", eine Tabelle) geben und dann tiefer in die Details. Z. B. vor dem Start einer Reihe von Subsections die verschiedenen Ausprägungen eines Sachverhalts diskutieren, diese Sachverhalte vorher alle aufzählen und kurz erläutern.
- ⚠️ Fremdworte/Fachbegriffe nicht einfach ohne weitere Erläuterung verwenden und als bekannt voraussetzen. Selbst wenn der Begriff etabliert und bekannt scheint – das ist oft auch nur in einem Teilgebiet (der Informatik) so. Deshalb generell Fachbegriffe und Fremdworte erläutern.

<!-- -->

- Die einzelnen Abschnitte sollten entsprechend aufeinander verweisen. Überleitungen und Zusammenfassungen zwischen Kapiteln sind hilfreich.
- Zu Beginn eines Kapitels ist eine Übersicht über dessen Inhalt sinnvoll. Am Ende eines Kapitels kann eine Überleitung zum nächsten Kapitel helfen, den roten Faden aufzuzeigen.
- Gute Überschriften, vielseitige Präsentation der Inhalte (Diagramme, Tabellen, Auflistungen, ...) und aussagekräftige Inhaltsunterschriften verwenden.
- Durch eine Kombination aus Text und Bild lassen sich komplexe Sachverhalte vereinfacht darstellen und verständlich vermitteln.
- Verwendet sprechende Titel für Kapitel, Abschnitte, etc. Nicht einfach nur "Aufbau", "Mechanismen", "Dritter Schritt", etc. Man sollte nicht erst den Text lesen müssen, um den Kontext zu verstehen. Viel besser: "Aufbau einer Ausführungsumgebung für Microservices", "Mechanismen zur Fehlervermeidung und Fehlerbeseitigung", "Dritter Schritt: Implementierung der Schnittstellen zwischen Diensten".
- Statt in der Textform z. B. "mittels einerseits … andererseits", "erstens… zweitens… drittens" o. ä. lieber Aufzählungszeichen verwenden. Dies unterstützt die Lesbarkeit teilweise enorm.
- Möglichkeiten zur Hervorhebung (z. B. Fettdruck) und Textstrukturierung (Gedankenstriche, Klammern, Semikolon, Doppelpunkt, ...) nutzen.

### Ausdruck & Stil

Eine wissenschaftliche Ausdrucksweise ist sachlich, präzise und bemüht sich um Objektivität. Die Verwendung umgangssprachlicher Ausdrücke, schwammiger Formulierungen und übertriebener literarischer Stilmittel (z. B. Verwendung von Synonymen) stören die wissenschaftliche Ausdrucksweise.

- ⚠️ Umgangssprachliche Formulierungen vermeiden ("von vorneherein", "wird es teuer", "ziemlich simpel", "Gehen wir das ganze einmal durch", "zum Laufen zu bringen", "bauen"/"gebaut", "sprich …", "Fazit: …", "Ich habe mir gedacht, …")
- ⚠️ Komponenten nicht personifizieren ("der JBoss/er", "die Apaches", "JBosse", nicht so schlimm aber vermeiden: "Der Server …. Er ….").

<!-- -->

- Vermeidet Wörter wie "offensichtlich". Diese wirken, als hieltet ihr die Lesenden für dumm.
- Vermeidet Füllwörter wie "sehr". Wenn etwas "sehr wichtig" ist, dann sind in der Schriftsprache Worte wie "zentral", "fundamental", "essentiell", etc. eleganter.
- Worte wie "sehr", "relativ", "ziemlich", "quasi", "gewissermaßen" sind in den allermeisten Fällen überflüssig und ungenau.
- Die Begriffe, für die Demonstrativpronomen (dieser/jener/welcher) Stellvertreter sind, müssen eindeutig erkennbar sein.
- Nicht zu umständliche Stellvertreterausdrücke verwenden ("der zur Diskussion stehende Sachverhalt", "die vorbezeichneten Gegenstände", etc.) – da müssen Lesende viel zu viel nachdenken (und erstmal den Lesefluss stoppen und nachgucken, welche drei Sachen eigentlich gemeint sind).
- Nicht verschiedenste Synonyme für ein und denselben Begriff verwenden – insbesondere, wenn der Begriff etabliert ist (Negativbeispiel: "künstliche neuronale Netze", "artifizielle Netze", "die in Rede stehenden Netze", "ebenjene Netze", "die beschriebenen Netze")

### Rechtschreibung & Grammatik

Mindestens ebenso wichtig wie die Verständlichkeit ist die sprachliche Korrektheit. Ausarbeitungen müssen hinsichtlich Rechtschreibung, Grammatik, Satzbau und Zeichensetzung ohne Fehler sein. Ein nennenswerter Fehleranteil wird oft als Indikator für mangelnde Sorgfalt und Ernsthaftigkeit der Arbeit gewertet. Solche Arbeiten werden nicht anerkannt (⚠️ auch nicht als Vor-Version!).

- ⚠️ Alles, was die Rechtschreibkontrolle nicht kennt, ist entweder falsch geschrieben oder muss als Fremdwort, Eigenname, `\code` bzw. `\lstinline` etc. hervorgehoben sein.
- ⚠️ Es empfiehlt sich generell, Freunde, Kommilitonen, und eine Software zur Prüfung der Rechtschreibung & Grammatik nochmal auf den Text schauen zu lassen. Als Autor bekommt man schnell einen Tunnelblick und sieht die Fehler nicht mehr.
- ⚠️ Beachtet [schwierige Wörter](https://www.duden.de/Rechtschreiblich-schwierige-Woerter).
  - zum **e**inen zum **a**nderen, des **W**eiteren
- ⚠️ Regeln für das Setzen von Bindestrichen: Deutsch → immer ("Hasso-Plattner-Institut"), Englisch → in der Regel nicht ("Hasso Plattner Institute"), Deutsch+Englisch → prinzipiell wird der Bindestrich in Fremdwörtern nach denselben Regeln gesetzt wie in heimischen Wörtern ("Java-EE-Sicherheitsmodell", "Download-Modus" oder auch "Downloadmodus").
- ⚠️ Zu einem "einerseits" muss es ein "andererseits" geben, zu einem "erstens" auch ein "zweitens", zu einem "sowohl" auch ein "als auch", usw.
- Schreibung von Zahlen (deutsch):
  - ⚠️ Zahlen von eins bis zwölf werden in der Regel ausgeschrieben; ansonsten nur ein- und zweisilbige Zahlwörter (hundert, tausend, …). Das gilt nicht, wenn sie den Charakter einer Nummer haben "(auf Seite 10)" oder mit anderen in Ziffern geschriebenen Zahlen verglichen werden "(von 2,8 auf 3 gestiegen)".
  - Vor Zeichen, Abkürzungen von Maßen, Gewichten, Geldsorten usw. ist die Zahl in Ziffern zu schreiben: 3 km; 7,4 kg; 6 EUR. Steht statt der Abkürzung die entsprechende Vollform, kann man sowohl in Ziffern als auch in Buchstaben schreiben: 11 Kilometer/elf Kilometer; 2 Euro/zwei Euro.
  - Die Zahlen ab 13 können – sofern sie Übersichtlich sind – auch ausgeschrieben werden.
  - Im IT-Bereich gibt es sehr oft einen Unterschied zwischen *0* (dem Zahlenwert) und *null* (dem Nullwert/NIL, Fehlen eines Wertes)!
  - Zahlen sollten zur besseren Lesbarkeit in Dreiergruppen gegliedert werden, und zwar sowohl links als auch rechts des Dezimaltrennzeichens. Laut ISO 80000 soll das Tausendertrennzeichen ein schmales Leerzeichen sein, niemals ein Komma, Punkt oder irgendein anderes Zeichen. Zahlen sollten (außer bei tabellarischer Darstellung) erst ab fünf Stellen untergliedert werden.
- Schreibung von Zahlen (englisch):
  - Zahlen am Satzanfang werden grundsätzlich ausgeschrieben.
  - Größere Zahlen können auch ausgeschrieben werden, es ist viel Geschmackssache und sollte vor allem konsistent und lesbar sein.
  - Nicht durch zehn teilbare Zahlen zwischen 21 und 99 sollten mit Bindestrich geschrieben werden ("forty-two").
  - Zahlen mit vier oder mehr Dezimalstellen sollten – anders als im Deutschen – mit Kommata versehen werden, und zwar alle drei Stellen: 299,792,458 m/s
- Sätze nie mit Konjunktionen ("und", "oder", "aber", sondern) beginnen. Konjunktionen sind – wie der Name schon sagt – Verbindungswörter und stellen die syntaktische Verbindung zwischen Wörtern, Satzteilen oder Sätzen her.

### Grafiken, Tabellen & Codeausschnitte

Jede Fließumgebung (Grafiken, Graphen, Diagramme, Tabellen, Codeausschnitte, ...) muss beschriftet sein ("captions").

- ⚠️ Die Beschreibungen der Abbildungen, Tabellen, Diagramme, Quellcode, etc. müssen jene auch ohne Kontext beschreiben – erläutern, was man alles sehen und erkennen kann. So muss man beim Betrachten nicht zurück in den Fließtext springen.
- ⚠️ In jeder Beschriftung müssen folgende Fragen beantwortet werden: Was ist dargestellt? Welche Besonderheiten sind zu erkennen? Welche Rückschlüsse ergeben sich daraus für den momentan behandelten Sachverhalt? Ein sehr gutes Beispiel für gute Beschriftungen von Abbildungen findet ihr im folgenden [Nature-Artikel](https://www.nature.com/articles/s41467-019-08987-4).
- ⚠️ Die Achsen von Diagrammen ordentlich beschriften (Metrik und Einheiten). Bei Vergleichen angeben, ob große oder ob kleine Werte besser sind. Fehlerbalken verwenden.

<!-- -->

- Bilder vorzugsweise als Vektorgrafiken einbinden (PDF, PostScript, ggf. SVG zu PDF konvertiert, etc.). Grafiken sind dadurch nicht nur "unendlich scharf", sondern die Suche findet auch Begriffe darin.
- In Betracht ziehen Grafiken selbst neu zu erstellen (mit Quellenverweis). So können Begriffe übersetzt und an das Vokabular des eigenen Textes angepasst werden, außerdem haben die Grafiken dann einen einheitlichen Stil.
- Bilder so skalieren, dass die Textgrößen verschiedener Abbildungen etwa konsistent groß sind und nicht sehr viel größer (oder kleiner) als die normale Textschriftgröße.
- Wenn Text in den Abbildungen auf Englisch ist, man aber einen deutschen Text schreibt: Entweder den Text in der Abbildung übersetzen, oder die Bildunterschrift so gestalten, dass man das auch verstehen kann, wenn man kein Englisch kann.
- Grafiken, Tabellen etc. müssen auch im Text referenziert werden um die Verbindung zwischen Text und Abbildungen herzustellen.

### Begriffe und Abkürzungen

Bei den folgenden Formalien gibt es teilweise verschiedene Möglichkeiten der Umsetzung. Es kann auch sinnvoll sein, in Ausnahmen von den Regeln abzuweichen. Wichtig sind Konsistenz und Übersichtlichkeit.

- ⚠️ Können fremdsprachige Begriffe leicht in die Sprache des Textes übersetzt werden, dies bitte tun (z. B. "Schnittstelle" statt "Interface", "Schaltfläche" statt "Button").
- ⚠️ Fremdsprachige Begriffe, Produkt- und Eigennamen und (z. B. *Java EE*, *Python*, *Design Thinking*) bei der ersten Verwendung kenntlich machen (z. B. mittels `\emph`) *und* eine kurze Erläuterung hinzufügen.
- Eine Erläuterung bei der ersten Verwendung kann (in grober Reihenfolge der Präferenz:) in einem Nebensatz, in einem Nachsatz, in Klammern oder in einer Fußnote erfolgen.
- ⚠️ Abkürzungen sparsam verwenden. Nur übliche Abkürzungen benutzen. Keine Abkürzungen am Satzanfang verwenden. Abkürzungen sind bei ihrer ersten Verwendung auszuschreiben.
- ⚠️ Enthalten Abkürzungen in ausgeschriebener Form Leerzeichen, müssen sie auch entsprechende Leerzeichen in abgekürzter Form beinhalten ("unter anderem" → "u. a."). Idealerweise schmale geschützte Leerzeichen (in LaTeX z. B. `z.\,B.`).
- Im Glossar erwähnte Begriffe sind auch bei ihrer ersten Verwendung kurz zu erläutern (siehe "Erläuterung bei der ersten Verwendung")
- Ein Glossar beinhaltet Begriffe, die einer Erläuterung bedürfen. Eine Erläuterung kann nötig sein, weil ein Begriff weniger bekannt ist, weil keine allgemein akzeptierte Definition existiert, weil der Begriff im Text mit einer unüblichen Definition verwendet wird.
- Ein Glossar beinhaltet streng genommen keine Abkürzungen. Es ist jedoch möglich, das Glossar in bspw. "Glossar und Abkürzungsverzeichnis" umzubenennen.
- Die Nutzung des Pakets [glossaries](https://www.ctan.org/pkg/glossaries) erleichtert konsistentes Einführen von Begriffen/Abkürzungen und deren konsistente Verwendung. Beim Schreiben auf Deutsch können sich jedoch auch Umständlichkeiten bzgl. der Kasus ergeben.

### weitere wichtige Formalien

- ⚠️ Bei Verwendung von Unterpunkten müssen mindestens zwei Unterpunkte vorhanden sein (also "2." "2.1" "2.2" … "3." statt "2" "2.1" "3").
- ⚠️ Zwischen aufeinanderfolgenden Überschriften sollte stets Text stehen.
  - "Topic Sentences": Am Anfang eines Abschnitts erklärt ihr Lesenden kurz und präzise in einem Satz, worum es in dem gesamten Abschnitt gehen wird, ehe ihr Unterabschnitte eröffnet.
  - Inhalt des ersten Unterabschnitts als Topic Sentences verwenden (erste *Subsection*-Überschrift weglassen) oder den ersten Absatz des ersten Unterabschnitts als Einleitungstext des gesamten Abschnitts verwenden (erste *Subsection*-Überschrift nach hinten schieben).
- Bei Nennung von Produkten die URL der Bezugsquelle als Fußnote angeben.
- URLs nicht in den Fließtext integrieren, sondern als Fußnote oder ggf. als Referenz darauf verweisen (sonst unterbrechen sie durch ihre Länge den Lesefluss). Bei Verwendung von LaTeX die URLs immer auch in die `\url`-Umgebung einfügen.
- Schreiben in der ersten Person Singular vermeiden. "Ich" ist üblicherweise nur akzeptabel, wenn es um eigene Leistungen/Beiträge geht.
- Aufzählung einzelner Begriffe nur machen, wenn sie in der Auflistung noch etwas genauer erklärt werden. Ansonsten einfach als Fließtext hintereinander aufschreiben.
- Sind Subsections wirklich immer nötig? Oder tut es vielleicht auch eine einfache Auflistung?
- Keine zusätzlichen Formatierungen in Überschriften verwenden.

### spezielle Hinweise für das Arbeiten LaTeX

- ⚠️ Absätze nicht mit `\\` trennen, sondern durch eine Leerzeile. Die beiden Sachen sehen im erstellten Dokument unterschiedlich aus (sonst werden z. B. die Absätze nicht eingerückt).
- ⚠️ Für Gedankenstriche bitte `--` benutzen (doppeltes Minus).
- Mithilfe einer `~` (Tilde) kann ein geschütztes Leerzeichen (engl. no-break space) eingefügt werden, dass einen automatischen Zeilenumbruch an dieser Position verhindert (bzw. verzögert) und dadurch die Lesbarkeit verbessert (z. B. `123~kg`, `3~Liter`, `DB~Systel`, `S.~42~ff.` oder auch zur Umbruchsteuerung bei Titel-Angaben).
- ⚠️ Bei allen Quellen, die im Quellenverzeichnis auftauchen sollen, muss irgendwo eine Referenz darauf existieren (kein `\NoCite`!).
- URLs bitte in die `\url`-Umgebung einfügen, möglichst in eine Fußnote (`\footnote`) packen, den Seitentitel nennen und ggf. das Abrufdatum angeben.
- Kein `\emph` o. ä. in Überschriften verwenden.
- Literaturverzeichnis:
  - Als \*.bib-Datei!
  - ⚠️ Bei Firmen-/Organisationsbezeichnungen im `author`-Feld die sich aus mehreren Wörtern zusammensetzen (und die keine Vornamen/Nachnamen sind) diese separat in `{}` packen. Zum Beispiel `{{Microsoft Corporation}}` (damit sie nicht als Vor-/Nachname formatiert werden).
  - ⚠️ Bei mehreren Autoren diese nicht mit Komma voneinander trennen, sondern mit `and`.
- Einige bevorzugen, im Quelltext einen Satz pro Zeile zu schreiben. So können Sätze leichter sortiert werden, Änderungen können von der Versionskontrolle besser verarbeitet werden (Darstellung, *merge*) und die Länge einzelner Sätze ist leichter zu erfassen.

## Korrektur

⚠️ Eine gute schriftliche Ausarbeitung braucht eine gute Argumentation und eine gute Schlussüberarbeitung. Diese sind jedoch nicht nach der ersten Niederschrift fertig – daher sind **mehrere Überarbeitungen vor Abgabe der Endfassung** unbedingt notwendig. Kurze und präzise Formulierungen entwickelt man nicht beim ersten Nachdenken über ein Problem. Logikfehler oder fehlende Argumente fallen nicht sofort auf.

- ⚠️ Den Text mehrfach lesen und überarbeiten.
- ⚠️ Wiederholungen beseitigen, Abschnitte eventuell umstellen, umformulieren, Brüche glätten, Teile verbinden, Aussagen präzisieren, an der Sprache feilen.
- ⚠️ Den roten Faden durchgängig kenntlich machen, die Fragestellung und Argumentation schärfen, deren Nachvollziehbarkeit überprüfen.
- ⚠️ Möglichst auch noch einmal eine (externe) Rechtschreibkontrolle zu Rate ziehen – eine korrekte Rechtschreibung und Grammatik sind ein Muss!
- ⚠️ Ebenfalls solltet ihr vor der Abgabe eines Dokuments noch einmal (gründlich) nachschauen, ob alles so aussieht, wie es soll passt das Layout, wurden alle (gravierenden) overfull-Boxes beseitigt, sind die Referenzen ordentlich gesetzt, ist das Literaturverzeichnis vorhanden usw.
- ⚠️ Wichtig ist auch, dass ihr euch jeden einzelnen Eintrag im Literaturverzeichnis noch einmal anschaut – sind notwendigen Angaben alle dargestellt, ist die Autorenliste korrekt, sieht man bei Online-Quellen auch die Adresse etc.

## Abgabe

Bis zum Ende der Bearbeitungszeit muss die Arbeit abgegeben werden. Nach Vorgabe der Universität Potsdam müssen Abschlussarbeiten (Bachelor & Master) ausschließlich elektronisch übermittelt werden. Am HPI werden Abschlussarbeiten über den [Moodle-Kurs "Abschlussarbeiten/Final Thesis"](https://moodle.hpi.de/mod/assign/view.php?id=22910) eingereicht. Mit Anmeldung der Abschlussarbeit werden Studierende vom Studienreferat für diesen Kurs registriert. Da die Eigenständigkeit im Moodle-Kurs mittels Setzen eines Hakens erklärt wird, entfällt bei diesem Modus der Abgabe die Pflicht eine Eigenständigkeitserklärung der Arbeit beizufügen.

## Drucken & Binden

Seit dem 1. November 2023 entfällt seitens der Studierenden die Pflicht physische, gebundene Exemplare der Arbeit abzugeben. Einige Studierende wollen dennoch Drucke der Arbeit herstellen, z. B. für eigene Archivierung, Verwandte, Arbeitgeber:innen, oder für die Bibliothek der Betreuenden. Damit das Resultat möglichst hochwertig, schnell und preiswert entsteht, solltet ihr folgende Dinge beachten:

- **Papierstärke** Für den Ausdruck bitte ordentliches Papier verwenden (so, dass man die Rückseite nicht durchschimmern sieht). Um professionell zu wirken, sollte Papier mit mind. 100 g/m² gewählt werden.
- **Bindung** Wir raten dazu, beim Binden ein "Softcover mit Aufdruck auf der Vorderseite" zu wählen; ein Hardcover geht natürlich auch, ist allerdings etwas teurer. Beide Bindungsmöglichkeiten haben ein professionelles Aussehen und sind sehr langlebig. Falls zum Binden ein Plastikbinderücken verwendet werden sollte – bitte auch einen Binderücken wählen, der zur Papierstärke passt. Das sieht sonst lächerlich aus. Die Plastikbindung ist eine günstige Lösung; im Gegensatz zu anderen Bindungsmöglichkeiten wirkt es allerdings weniger professionell. Denkt schon vor dem Drucken ggf. an eine Bindungskorrektur (diese kann in der Vorlage *osm-thesis* mittels `\bcor` eingestellt werden).
- **Kosten & Dauer** Je nach Kopierservice kann die Arbeit in wenigen Stunden gedruckt werden. Ruft ggf. vorher an und erfragt die voraussichtliche Bearbeitungszeit. Das Drucken kostet je nach Seitenanzahl und Anteil von farbigen Seiten ca. 10 € pro Exemplar. Das Binden kostet zusätzlich, z. B. Klebebindung mit Softcover (Tipp: schwarz) und Aufdruck auf der Vorderseite (Tipp: silber) ca. 10 € pro Exemplar. *Spar-Tipp*: Die Arbeit selbst drucken (ordentliches Papier besorgen, *sauber druckenden Drucker* suchen, z. B. im HPI in A-1 oder H-E\]) und beim Kopierservice nur binden lassen. Selbstverständlich kann die Arbeit zu Hause mit dem eigenen Drucker gedruckt werden. Das setzt allerdings voraus, dass der Drucker sehr gute Druckergebnisse liefert.

## Aufnahme der Abschlussarbeiten in die digitale Fachgebiets-Bibliothek

Mit der Abgabe der Arbeit wird diese ausschließlich für die Begutachtung und wissenschaftliche Besprechung vor der Benotung zugänglich gemacht - Darüber hinaus kann die Arbeit nicht weiterverwendet werden. Die Universität/die Fakultät/das Institut erwirbt mit der Entgegennahme der Arbeit nur das Eigentum am Papier und das Recht zur Archivierung aber kein über die Begutachtung hinausgehendes, weiteres Nutzungsrecht.

Damit eine Abschlussarbeit also z. B. anderen Mitgliedern des Fachgebiets zugänglich gemacht werden und auch sonst weiterverwendet werden kann, bedarf es dem Einverständnis der Autorin bzw. des Autors. Es würde uns sehr freuen, wenn wir Abschlussarbeiten in unsere Fachgebiets-Bibliothek aufnehmen könnten: Das kann ganz einfach unter <https://osm.hpi.de/bookshelf/SubmitThesis> getan werden.
