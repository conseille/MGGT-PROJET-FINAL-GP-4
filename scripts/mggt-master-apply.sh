#!/usr/bin/env bash
set -eu

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"

WIN_HOST="$(ip route show default | awk '{print $3; exit}')"

KEY="${HOME}/.ssh/mggt_gp4_ansible"
ANSIBLE="${ROOT}/.venv-ansible/bin/ansible-playbook"
INVENTORY="${ROOT}/ansible/inventory.ini"
ANSIBLE_CFG="${ROOT}/ansible/ansible.cfg"

[ -f "${KEY}" ] ||
  {
    echo "ERROR: clé Ansible absente: ${KEY}" >&2
    exit 1
  }

[ -x "${ANSIBLE}" ] ||
  {
    echo "ERROR: environnement Ansible absent: ${ANSIBLE}" >&2
    exit 1
  }

PLAYBOOK="${ROOT}/ansible/setup-cluster.yml"

if [ ! -f "${PLAYBOOK}" ]; then
  PLAYBOOK="$(find "${ROOT}/ansible" \
    -type f \
    -name 'setup-cluster.yml' \
    -print -quit)"
fi

[ -n "${PLAYBOOK}" ] && [ -f "${PLAYBOOK}" ] ||
  {
    echo "ERROR: setup-cluster.yml introuvable" >&2
    exit 1
  }

echo "===== MGGT MASTER APPLY ====="
echo "Management : ${WIN_HOST}:22022"
echo "Fabric     : eth1 / 10.44.0.10"
echo "Playbook   : ${PLAYBOOK}"

ssh \
  -o IdentitiesOnly=yes \
  -o BatchMode=yes \
  -o ConnectTimeout=10 \
  -i "${KEY}" \
  -p 22022 \
  "vagrant@${WIN_HOST}" \
  'echo SSH_PREFLIGHT=OK; hostname; ip -4 -br addr show dev eth1'

echo "===== ANSIBLE ====="

exec env ANSIBLE_CONFIG="${ANSIBLE_CFG}" \
  "${ANSIBLE}" \
  -i "${INVENTORY}" \
  "${PLAYBOOK}" \
  --limit master_node \
  --ask-vault-pass \
  -e "ansible_host=${WIN_HOST}" \
  -e "ansible_port=22022" \
  -e "ansible_user=vagrant" \
  -e "ansible_ssh_private_key_file=${KEY}" \
  -e "ansible_become_method=sudo" \
  -e "ansible_become_flags=-n"
