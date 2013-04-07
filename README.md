# Nerdkunde

Die Nerdkunde Webseite

[http://nerdkunde.de](http://nerdkunde.de)

# Benutzung

Zuerst die Gems installieren:

``` bash
bundle
```

Um alle auf Auphonic vorliegenden Files zu
sehen, muss zuerst der Account von Auphonic
auf dem System hinterlegt werden:

``` bash
echo '{"user": "joe@example.com", "pass": "secret"}' > ~/.auphonic
```

Jetzt die Liste an Produktionen ansehen mit

``` bash
gst-kitchen list
```

und dann die Produktion hinzufügen mit

``` bash
gst-kitchen process --uuid=<PRODUCTION-UUID>
```

Jetzt sollte diese in `episodes` abgelegt worden sein.

Um die Seite zu generieren, jetzt nur noch folgendes
ausführen:

``` bash
thor nerdkunde:generate
```
