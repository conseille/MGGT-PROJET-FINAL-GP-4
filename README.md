# MGGT1103 — Conception et Automatisation d’une Plateforme Cloud-Native Distribuée

Projet final réalisé à l’**Université Espoir d’Afrique** dans le cadre du cours **MGGT1103**.

Le projet consiste en la conception et l’automatisation d’une plateforme **Cloud-Native distribuée Smart City / IoT**, déployée sur trois machines physiques participant à un cluster Kubernetes K3s.

## Équipe — Groupe 4

- **MUPINI KABWE ALBERT**
- **NGOMBE BIN KUMWIMBA PRESCOTT**
- **MWIMBA PASCAL ALPHANI**
- **TATIANE MUNYALI WANY**

## Architecture

La plateforme repose sur trois machines virtuelles Ubuntu distribuées sur trois ordinateurs physiques :

**Master K3s + Worker 1 + Worker 2**

L’infrastructure et les services sont automatisés et déployés selon les principes **Infrastructure as Code**, **Cloud-Native** et **DevSecOps**.

## Applications

### App1 — Smart City Operations
Application basée sur **Node-RED** pour l’automatisation, le traitement des flux et les services Smart City.

### App2 — Smart City IoT Console
Interface IoT basée sur **Eclipse Mosquitto / MQTT** pour la publication, la réception et la visualisation de données de télémétrie.

## Technologies principales

`Vagrant` • `Ansible` • `Docker` • `K3s` • `Kubernetes` • `Traefik` • `Node-RED` • `Eclipse Mosquitto` • `MQTT` • `Keycloak` • `OAuth2 Proxy` • `GitHub Actions` • `Hadolint` • `Trivy` • `Docker Hub` • `Prometheus` • `Grafana` • `Loki` • `Promtail`

## Fonctionnalités validées

- Infrastructure distribuée et automatisée
- Cluster K3s à trois nœuds
- Déploiement et réplication des applications
- Haute disponibilité et résilience
- Authentification centralisée avec Keycloak
- SSO réel entre App1 et App2
- Observabilité des nœuds et des applications
- Centralisation des logs
- Pipeline CI/CD DevSecOps
- Analyse Hadolint et Trivy
- Publication des images sur Docker Hub

## Sécurité et DevSecOps

Les informations sensibles ne sont pas stockées en clair dans le dépôt. La plateforme utilise notamment les mécanismes de secrets Kubernetes, les secrets GitHub Actions et l’authentification centralisée.

## Mots-clés

**Cloud-Native · Kubernetes · K3s · Infrastructure as Code · DevSecOps · CI/CD · SSO · Keycloak · Observabilité · Smart City · IoT · MQTT · Résilience**

---

**UNIVERSITÉ ESPOIR D’AFRIQUE — MGGT1103 — GROUPE 4**
