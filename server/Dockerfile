# Übungsplaner-Server als Container (z. B. auf NAS oder Raspberry Pi).
#   docker build -t uebungsplaner-server server/
#   docker run -d -p 8080:8080 -v uebungsplaner-daten:/daten uebungsplaner-server
FROM dart:stable AS build
WORKDIR /src
COPY pubspec.* ./
RUN dart pub get
COPY . .
RUN dart pub get --offline && dart build cli -o /out

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates && rm -rf /var/lib/apt/lists/* \
    && useradd --system --home /daten uebungsplaner && mkdir -p /daten && chown uebungsplaner /daten
COPY --from=build /out/bundle /app
USER uebungsplaner
ENV UEBUNGSPLANER_DATA=/daten UEBUNGSPLANER_PORT=8080
VOLUME /daten
EXPOSE 8080
HEALTHCHECK CMD ["/bin/sh", "-c", "exec 3<>/dev/tcp/127.0.0.1/8080 || exit 1"]
CMD ["/app/bin/uebungsplaner_server"]
