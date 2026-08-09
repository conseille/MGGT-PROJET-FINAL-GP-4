#!/usr/bin/env bash
set -eu

NETPLAN_DIR="/etc/netplan"
STATE_DIR="/var/lib/mggt-mrnf"
BACKUP_DIR="${STATE_DIR}/netplan-original"
MARKER="${STATE_DIR}/netplan-adopted"
MRNF_NETPLAN="${NETPLAN_DIR}/60-mggt-mrnf.yaml"
CLOUD_CFG="/etc/cloud/cloud.cfg.d/99-mggt-disable-network-config.cfg"

fail() {
  echo "MRNF ERROR: $*" >&2
  exit 1
}

[ "$(id -u)" -eq 0 ] || fail "ce bootstrap doit être exécuté en root"
command -v networkctl >/dev/null 2>&1 || fail "systemd-networkd indisponible"
command -v netplan >/dev/null 2>&1 || fail "netplan indisponible"

NODE_NAME="$(hostname -s)"

case "${NODE_NAME}" in
  master)
    FABRIC_IP="10.44.0.10"
    ;;
  worker1)
    FABRIC_IP="10.44.0.20"
    ;;
  worker2)
    FABRIC_IP="10.44.0.30"
    ;;
  *)
    fail "hostname non reconnu pour la Fabric MRNF: ${NODE_NAME}"
    ;;
esac

[ -e /sys/class/net/eth0 ] || fail "eth0 absente"
[ -e /sys/class/net/eth1 ] || fail "eth1 absente"

NAT_MAC="$(cat /sys/class/net/eth0/address)"
LAN_MAC="$(cat /sys/class/net/eth1/address)"

mkdir -p "${STATE_DIR}" "${BACKUP_DIR}"

# Conserver une copie unique de la configuration reçue avant adoption MRNF.
if [ ! -e "${MARKER}" ]; then
  cp -a "${NETPLAN_DIR}/." "${BACKUP_DIR}/"
  touch "${MARKER}"
fi

# Empêcher cloud-init de recréer une autorité réseau concurrente.
mkdir -p "$(dirname "${CLOUD_CFG}")"
printf '%s\n' 'network: {config: disabled}' > "${CLOUD_CFG}"

# Refuser de supprimer silencieusement une configuration inconnue.
UNEXPECTED=""
for FILE in "${NETPLAN_DIR}"/*.yaml; do
  [ -e "${FILE}" ] || continue
  BASE="$(basename "${FILE}")"

  case "${BASE}" in
    01-netcfg.yaml|50-cloud-init.yaml|50-vagrant.yaml|60-mggt-mrnf.yaml)
      ;;
    *)
      UNEXPECTED="${UNEXPECTED} ${BASE}"
      ;;
  esac
done

[ -z "${UNEXPECTED}" ] || \
  fail "configuration Netplan inconnue détectée:${UNEXPECTED}"

# Supprimer uniquement les anciennes autorités connues.
rm -f \
  "${NETPLAN_DIR}/01-netcfg.yaml" \
  "${NETPLAN_DIR}/50-cloud-init.yaml" \
  "${NETPLAN_DIR}/50-vagrant.yaml"

cat > "${MRNF_NETPLAN}" <<EOF_NETPLAN
network:
  version: 2
  renderer: networkd

  ethernets:
    nat0:
      match:
        macaddress: "${NAT_MAC}"
      set-name: eth0
      dhcp4: true
      dhcp4-overrides:
        route-metric: 100

    lan0:
      match:
        macaddress: "${LAN_MAC}"
      set-name: eth1

      # MRNF Fabric:
      # l'identité du cluster ne dépend plus du DHCP du LAN physique.
      addresses:
        - "${FABRIC_IP}/24"

      dhcp4: false
      accept-ra: false
      link-local: []
      optional: true
EOF_NETPLAN

chmod 0600 "${MRNF_NETPLAN}"

netplan generate

# Ne jamais réappliquer globalement le réseau :
# eth0 transporte la session Vagrant/SSH.
networkctl reload
networkctl reconfigure eth1 || true

# Une reconfiguration ciblée supplémentaire est autorisée sur eth1
# uniquement si l'adresse Fabric n'est pas encore présente.
if ! ip -4 -o addr show dev eth1 |
     awk '{print $4}' |
     grep -Fxq "${FABRIC_IP}/24"; then

  networkctl down eth1 || true
  sleep 1
  networkctl up eth1 || true
fi

TRIES=0
while [ "${TRIES}" -lt 10 ]; do
  if ip -4 -o addr show dev eth1 |
     awk '{print $4}' |
     grep -Fxq "${FABRIC_IP}/24"; then
    break
  fi

  TRIES=$((TRIES + 1))
  sleep 1
done

ip -4 -o addr show dev eth1 |
  awk '{print $4}' |
  grep -Fxq "${FABRIC_IP}/24" ||
  fail "adresse Fabric ${FABRIC_IP}/24 absente de eth1"

DEFAULT_ROUTES="$(ip -4 route show default)"
DEFAULT_COUNT="$(printf '%s\n' "${DEFAULT_ROUTES}" |
  sed '/^[[:space:]]*$/d' |
  wc -l)"

[ "${DEFAULT_COUNT}" -eq 1 ] ||
  fail "nombre de routes par défaut IPv4 incorrect: ${DEFAULT_COUNT}"

printf '%s\n' "${DEFAULT_ROUTES}" |
  grep -q ' dev eth0 ' ||
  fail "la route par défaut n'utilise pas eth0"

if ip -4 route show default dev eth1 | grep -q .; then
  fail "eth1 possède encore une route par défaut"
fi

echo "===== MRNF v2 RESULT ====="
echo "MRNF_NODE=${NODE_NAME}"
echo "MRNF_FABRIC_IP=${FABRIC_IP}"
ip -br -4 addr
ip -4 route
echo "MRNF_DHCP_DEPENDENCY=NONE"
echo "MRNF_OK=YES"
