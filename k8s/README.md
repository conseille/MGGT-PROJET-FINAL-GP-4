# Phase 4 — Orchestration Smart City

Fichiers préparés :

- `namespace.yaml`
- `deployment.yaml`
- `service.yaml`
- `ingress.yaml`
- `keycloak.yaml`

Les applications ont chacune `replicas: 3`.

## Avant déploiement

1. Remplacer `REGISTRY_PLACEHOLDER` par le nom public du registre Docker retenu.
2. Vérifier que `master`, `worker1` et `worker2` sont `Ready`.
3. Créer le Secret Keycloak directement dans Kubernetes, sans mettre les valeurs dans Git.
4. Ajouter la protection SSO Traefik/oauth2-proxy après la configuration du Realm et du Client OIDC.

Ces manifests sont préparés mais ne doivent pas encore être déployés ni commités.
