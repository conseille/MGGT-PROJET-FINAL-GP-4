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

[ "$(id -u)" -eq 0 ] || fail "ce script doit être exécuté en root"

systemctl is-active --quiet systemd-networkd \
  || fail "systemd-networkd n'est pas actif"

for iface in eth0 eth1; do
  [ -r "/sys/class/net/${iface}/address" ] \
    || fail "interface ${iface} introuvable"
done

NAT_MAC="$(cat /sys/class/net/eth0/address)"
LAN_MAC="$(cat /sys/class/net/eth1/address)"

install -d -m 0755 \
  "${NETPLAN_DIR}" \
  "${STATE_DIR}" \
  "${BACKUP_DIR}" \
  /etc/cloud/cloud.cfg.d

# Sauvegarde unique des configurations présentes avant adoption MRNF.
if [ ! -e "${MARKER}" ]; then
  for file in "${NETPLAN_DIR}"/*.yaml; do
    [ -e "${file}" ] || continue
    [ "$(basename "${file}")" = "$(basename "${MRNF_NETPLAN}")" ] && continue
    cp -a "${file}" "${BACKUP_DIR}/"
  done

  touch "${MARKER}"
fi

# Cloud-init ne doit plus recréer une configuration réseau concurrente.
cat > "${CLOUD_CFG}" <<'CFG'
network: {config: disabled}
CFG
chmod 0644 "${CLOUD_CFG}"

# Refuser toute configuration Netplan inconnue plutôt que la supprimer.
UNEXPECTED="$(
  find "${NETPLAN_DIR}" -maxdepth 1 -type f -name '*.yaml' \
    ! -name '01-netcfg.yaml' \
    ! -name '50-cloud-init.yaml' \
    ! -name '50-vagrant.yaml' \
    ! -name "$(basename "${MRNF_NETPLAN}")" \
    -print
)"

if [ -n "${UNEXPECTED}" ]; then
  echo "MRNF ERROR: configuration Netplan inattendue détectée :" >&2
  echo "${UNEXPECTED}" >&2
  exit 1
fi

# Retirer uniquement les configurations concurrentes connues.
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
      dhcp4: true
      accept-ra: false
      dhcp4-overrides:
        use-routes: false
        use-dns: false
      optional: true
EOF_NETPLAN

chmod 0600 "${MRNF_NETPLAN}"

netplan generate

# IMPORTANT :
# ne pas reconfigurer eth0 pendant que Vagrant utilise SSH via NAT.
networkctl reload
networkctl reconfigure eth1

sleep 3

echo "===== MRNF RESULT ====="
ip -br -4 addr
ip -4 route

DEFAULT_ROUTES="$(ip -4 route show default)"

echo "${DEFAULT_ROUTES}" | grep -Eq ' dev eth0( |$)' \
  || fail "eth0 ne possède pas la route IPv4 par défaut"

if echo "${DEFAULT_ROUTES}" | grep -Eq ' dev eth1( |$)'; then
  fail "eth1 possède encore une route IPv4 par défaut"
fi

ip -4 -o addr show dev eth1 scope global | grep -q 'inet ' \
  || fail "eth1 n'a pas obtenu d'adresse IPv4 LAN"

echo "MRNF_OK=YES"
