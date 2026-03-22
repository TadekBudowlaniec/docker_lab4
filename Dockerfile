# ETAP 2 — zoptymalizowany Dockerfile (dobre praktyki)
#
# Zmiany względem ETAP 1:
# 1. Połączono apt-get update + install + clean w jedną warstwę RUN
#    → zmniejsza rozmiar obrazu (brak cache apt w warstwie)
# 2. Dodano --no-install-recommends → instaluje tylko niezbędne pakiety
# 3. Dodano rm -rf /var/lib/apt/lists/* → usuwa listy pakietów
# 4. Użyto LABEL zamiast przestarzałego MAINTAINER
# 5. Dodano .dockerignore (osobny plik) → szybszy build context
# 6. Dodano HEALTHCHECK → Docker może monitorować stan kontenera

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
