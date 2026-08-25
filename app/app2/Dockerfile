# hadolint ignore=DL3007
FROM eclipse-mosquitto:latest

RUN apk upgrade --no-cache

COPY mosquitto.conf /mosquitto/config/mosquitto.conf

EXPOSE 1883 9001
