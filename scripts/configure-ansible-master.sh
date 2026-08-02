#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="/mnt/c/MGGT1103/MGGT-PROJET-FINAL-GP-4"
MASTER_IP="${1:-192.168.1.122}"

SSH_CONFIG="$PROJECT_ROOT/infra/vagrant/.vagrant/ssh-config-master"
ANSIBLE_DIR="$PROJECT_ROOT/ansible"
REPORT_DIR="$PROJECT_ROOT/reports"

KEY_DEST="$HOME/.ssh/mggt_gp4_master"
REPORT="$REPORT_DIR/ansible-master-$(date +%Y%m%d-%H%M%S).log"

mkdir -p "$REPORT_DIR"
mkdir -p "$HOME/.ssh"

exec > >(tee -a "$REPORT") 2>&1

echo "============================================================"
echo "CONFIGURATION ANSIBLE DU MASTER"
echo "============================================================"
echo
echo "Projet    : $PROJECT_ROOT"
echo "Master IP : $MASTER_IP"
echo "Rapport   : $REPORT"
echo

if ! grep -qi microsoft /proc/version 2>/dev/null; then
    echo "[ERREUR] Ce script doit être exécuté dans WSL."
    exit 1
fi

if ! command -v ansible >/dev/null 2>&1; then
    echo "[ERREUR] Ansible n'est pas installé dans WSL."
    exit 1
fi

if [[ ! -s "$SSH_CONFIG" ]]; then
    echo "[ERREUR] Configuration SSH Vagrant introuvable :"
    echo "$SSH_CONFIG"
    echo
    echo "Exécuter d'abord dans PowerShell :"
    echo "vagrant ssh-config master"
    exit 1
fi

echo "[1/6] Recherche de la clé SSH Vagrant"

KEY_SOURCE=""

while IFS= read -r KEY_WINDOWS; do
    KEY_WINDOWS="${KEY_WINDOWS%$'\r'}"
    KEY_WINDOWS="${KEY_WINDOWS#\"}"
    KEY_WINDOWS="${KEY_WINDOWS%\"}"

    KEY_WSL="$(wslpath -u "$KEY_WINDOWS" 2>/dev/null || true)"

    if [[ -n "$KEY_WSL" && -f "$KEY_WSL" ]]; then
        KEY_SOURCE="$KEY_WSL"
        break
    fi
done < <(
    awk '
        $1 == "IdentityFile" {
            sub(/^[[:space:]]*IdentityFile[[:space:]]+/, "")
            print
        }
    ' "$SSH_CONFIG"
)

if [[ -z "$KEY_SOURCE" ]]; then
    echo "[ERREUR] Aucune clé SSH existante trouvée."
    grep "IdentityFile" "$SSH_CONFIG" || true
    exit 1
fi

echo "[OK] Clé trouvée : $KEY_SOURCE"

echo
echo "[2/6] Installation sécurisée de la clé dans WSL"

install -m 600 "$KEY_SOURCE" "$KEY_DEST"

echo "[OK] Clé WSL : $KEY_DEST"
ls -l "$KEY_DEST"

echo
echo "[3/6] Test SSH direct WSL vers le Master"

ssh \
    -i "$KEY_DEST" \
    -o IdentitiesOnly=yes \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -o ConnectTimeout=20 \
    "vagrant@$MASTER_IP" \
    'echo SSH_WSL_OK; hostname; python3 --version'

echo
echo "[4/6] Création de ansible.cfg"

cat > "$ANSIBLE_DIR/ansible.cfg" <<'EOF'
[defaults]
inventory = inventory.ini
host_key_checking = False
retry_files_enabled = False
interpreter_python = auto_silent
timeout = 30
forks = 10

[ssh_connection]
pipelining = True
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o IdentitiesOnly=yes
EOF

echo
echo "[5/6] Création de inventory.ini"

cat > "$ANSIBLE_DIR/inventory.ini" <<EOF
[master]
master_node ansible_host=$MASTER_IP ansible_port=22 ansible_user=vagrant ansible_ssh_private_key_file=$KEY_DEST ansible_python_interpreter=/usr/bin/python3

[workers]
# worker1 sera ajouté lorsque son IP sera disponible.
# worker2 sera ajouté lorsque son IP sera disponible.

[k3s_cluster:children]
master
workers
EOF

echo
echo "Inventaire créé :"
cat "$ANSIBLE_DIR/inventory.ini"

echo
echo "[6/6] Validation Ansible"

export ANSIBLE_CONFIG="$ANSIBLE_DIR/ansible.cfg"

echo
echo "--- Graphe de l'inventaire ---"
ansible-inventory --graph

echo
echo "--- Test SSH Ansible avec le module raw ---"
ansible master \
    -m raw \
    -a 'echo ANSIBLE_RAW_OK; hostname; python3 --version'

echo
echo "--- Test Ansible ping ---"
ansible master -m ping

echo
echo "============================================================"
echo "CONFIGURATION TERMINÉE"
echo "============================================================"
echo
echo "Rapport : $REPORT"
