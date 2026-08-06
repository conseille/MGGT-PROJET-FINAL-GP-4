# hadolint ignore=DL3007
FROM nodered/node-red:latest

USER root
COPY --chown=node-red:node-red settings.js /data/settings.js
COPY --chown=node-red:node-red flows.json /data/flows.json
USER node-red

EXPOSE 1880
