# PAwChO - Laboratorium 4: Budowanie i optymalizacja obrazów Docker

**Dane studenta:**
* **Imię i nazwisko:** Cezary Prusak
* **E-mail:** s101651@pollub.edu.pl
* **Grupa dziekańska:** 6.7
* **Data wykonania:** 2026-03-22

---

## ETAP 1: Utworzenie pliku Dockerfile (docker init)

Pracę rozpocząłem od wygenerowania podstawowych plików konfiguracyjnych przy pomocy polecenia `docker init`. Następnie przygotowałem prostą stronę HTML zawierającą imię, nazwisko oraz grupę dziekańską.

**Plik `index.html`:**
```html
<!DOCTYPE html>
<html lang="pl">
<head>
    <meta charset="UTF-8">
    <title>PAwChO - Cezary Prusak</title>
</head>
<body>
    <h1>Cezary Prusak</h1>
    <h2>Grupa dziekańska: 6.7</h2>
    <p>Projekt na laboratorium z konteneryzacji.</p>
</body>
</html>
```

**Podstawowy Dockerfile (wygenerowany przez `docker init`, przed optymalizacją):**
```dockerfile
FROM ubuntu:latest
LABEL maintainer="Cezary Prusak <s101651@pollub.edu.pl>"
RUN apt-get update && apt-get install -y apache2
COPY index.html /var/www/html/index.html
EXPOSE 80
CMD ["apachectl", "-D", "FOREGROUND"]
```

---

## ETAP 2: Optymalizacja Dockerfile zgodnie z dobrymi praktykami

Na podstawie wiadomości z wykładu oraz oficjalnych zaleceń Dockera dokonałem następujących modyfikacji:

| # | Zmiana | Uzasadnienie |
|---|--------|-------------|
| 1 | Połączenie `apt-get update`, `upgrade`, `install` i `rm` w jedną instrukcję `RUN` | Zmniejsza liczbę warstw i rozmiar obrazu — cache apt nie pozostaje w końcowym obrazie |
| 2 | Dodanie flagi `--no-install-recommends` | Instaluje tylko niezbędne zależności, co zmniejsza rozmiar obrazu |
| 3 | Dodanie `rm -rf /var/lib/apt/lists/*` | Usuwa listy pakietów po instalacji, dodatkowo redukując rozmiar |
| 4 | Dodanie `apt-get upgrade -y` | Aktualizacja systemu Ubuntu zgodnie z wymaganiami zadania |
| 5 | Użycie `LABEL` zamiast przestarzałego `MAINTAINER` | `MAINTAINER` jest deprecated, `LABEL` to zalecany sposób |
| 6 | Dodanie `HEALTHCHECK` | Docker może automatycznie monitorować stan kontenera |
| 7 | Utworzenie pliku `.dockerignore` | Wyklucza zbędne pliki (`.git`, `README.md`) z kontekstu budowania, przyspieszając build |

**Zoptymalizowany Dockerfile:**
```dockerfile
FROM ubuntu:latest

LABEL maintainer="Cezary Prusak <s101651@pollub.edu.pl>" \
      description="Serwer Apache z prostą stroną WWW — PAwChO Lab 4"

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends apache2 \
    && rm -rf /var/lib/apt/lists/*

COPY index.html /var/www/html/index.html

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s \
    CMD curl -f http://localhost/ || exit 1

CMD ["apachectl", "-D", "FOREGROUND"]
```

### Budowanie obrazu

```bash
docker build -t web100 .
```

### Liczba warstw obrazu

Sprawdzenie liczby warstw:
```bash
docker inspect web100 --format '{{len .RootFS.Layers}}'
```

Wynik: **3 warstwy**
1. Warstwa bazowa Ubuntu
2. Warstwa RUN (aktualizacja systemu + instalacja Apache)
3. Warstwa COPY (skopiowanie index.html)

Szczegółowy podgląd warstw (`docker history web100`):

```
IMAGE          CREATED BY                                      SIZE
8b3cc57f2ef2   CMD ["apachectl" "-D" "FOREGROUND"]             0B
<missing>      HEALTHCHECK ...                                 0B
<missing>      EXPOSE [80/tcp]                                 0B
<missing>      COPY index.html /var/www/html/index.html        256B
<missing>      RUN /bin/sh -c apt-get update && ...            120MB
<missing>      LABEL maintainer=...                            0B
<missing>      /bin/sh -c #(nop)  CMD ["/bin/bash"]            0B
<missing>      ADD file:... in /                               78.1MB
```

### Test kontenera

```bash
docker run -d -p 8080:80 --name test-web100 web100
curl http://localhost:8080
```

Strona została poprawnie wyświetlona z danymi studenta.

---

## ETAP 3: Przesłanie obrazu do DockerHub

Tagowanie i wysyłka obrazu do repozytorium DockerHub:

```bash
docker tag web100 <login-dockerhub>/web100:latest
docker login
docker push <login-dockerhub>/web100:latest
```

Repozytorium GitHub: https://github.com/TadekBudowlaniec/docker_lab4
