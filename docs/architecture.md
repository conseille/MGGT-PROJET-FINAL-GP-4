# Architecture du projet

## Topologie cible

- Laptop 1 : VM Master K3s
- Laptop 2 : VM Worker 1
- Laptop 3 : VM Worker 2

## Réseau

Les trois ordinateurs et les trois VM doivent communiquer sur le même
réseau local.

Les cartes réseau VirtualBox seront configurées en mode Bridged Adapter.

## Séparation des environnements

- Windows : VirtualBox et Vagrant
- WSL : Git, Ansible et automatisation
- VM Ubuntu : services du cluster
