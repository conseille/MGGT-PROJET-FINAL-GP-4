# Phase 2 - Smart City

Applications personnalisées :

- App 1 : Node-RED avec une API de démonstration `/smart-city`.
- App 2 : Eclipse Mosquitto sur MQTT 1883 et WebSocket 9001.
- Interface App 2 : client Web MQTT sur le port 8088.

## Test

```bash
docker compose -f app/docker-compose.yml up -d --build
docker compose -f app/docker-compose.yml ps
curl http://localhost:1880/smart-city
```
