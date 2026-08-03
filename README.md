# MGGT-PROJET-FINAL-GP-4

Projet de Fin de Cours MGGT1103 :

**Conception et Automatisation d'une Plateforme Cloud-Native Distribuée**

## Équipe — Groupe 4

### Ir Albert

- Master ;
- Ansible ;
- coordination et intégration du cluster.

### Ir Pascal

- préparation de la machine physique Worker 1 ;
- création et intégration de `worker1`.

### Ir Tatiana

- préparation de la machine physique Worker 2 ;
- création et intégration de `worker2`.

### Ir Prescott

- préparation et vérification des outils et environnements ;
- VirtualBox et Vagrant ;
- WSL 2 et Ubuntu ;
- Git, Python, Ansible et SSH.

La répartition pourra évoluer, car le projet reste un travail collectif.
## Objectif

Construire un cluster K3s distribué composé de trois machines
virtuelles réparties sur trois ordinateurs physiques.

## Séparation des environnements

### Windows PowerShell

- VirtualBox
- Vagrant
- création et démarrage des machines virtuelles

### Ubuntu WSL

- Git
- Ansible
- Ansible Vault
- contrôle et automatisation de l'infrastructure
- préparation des fichiers Docker et Kubernetes

### Machines virtuelles Ubuntu

- Master K3s
- Worker 1
- Worker 2

Les machines virtuelles ne doivent pas être configurées manuellement
après leur premier démarrage. La configuration doit être réalisée
avec Ansible.

## Phases

1. Infrastructure, Ansible, hardening, Docker et K3s
2. Dockerfiles et Docker Compose
3. CI/CD, Hadolint, Trivy et Docker Hub
4. Kubernetes, Traefik et Keycloak
5. Prometheus, Grafana, Loki et Promtail
6. Rapport et préparation de la soutenance

## État actuel

La structure propre du dépôt a été créée.

La prochaine étape sera la configuration du Vagrantfile de la
machine Master.
