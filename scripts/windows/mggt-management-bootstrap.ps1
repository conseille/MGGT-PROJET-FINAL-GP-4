param(
    [ValidateSet("master","worker1","worker2")]
    [string]$Node = "master",

    [int]$ListenPort = 22022
)

$ErrorActionPreference = "Stop"

$RepoRoot   = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$VagrantDir = Join-Path $RepoRoot "infra\vagrant"

Write-Host "===== MGGT MANAGEMENT BOOTSTRAP ====="

# Exiger PowerShell administrateur.
$Principal = New-Object Security.Principal.WindowsPrincipal(
    [Security.Principal.WindowsIdentity]::GetCurrent()
)

if (-not $Principal.IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)) {
    throw "Exécuter ce script dans PowerShell Administrateur."
}

# Détecter automatiquement l'adresse Windows vue depuis WSL.
$Route = (& wsl.exe sh -lc "ip route show default" | Select-Object -First 1)

if (-not $Route) {
    throw "Impossible de détecter la route par défaut WSL."
}

$Parts = $Route.Trim() -split "\s+"
$WslGateway = $Parts[2]

if (-not $WslGateway) {
    throw "Impossible de déterminer l'adresse Windows/WSL."
}

Write-Host "WSL_GATEWAY=$WslGateway"

# Activer le service requis par portproxy.
Set-Service iphlpsvc -StartupType Automatic
Start-Service iphlpsvc

# Recréer proprement le proxy Ansible.
& netsh interface portproxy delete v4tov4 `
    listenaddress=$WslGateway `
    listenport=$ListenPort 2>$null | Out-Null

& netsh interface portproxy add v4tov4 `
    listenaddress=$WslGateway `
    listenport=$ListenPort `
    connectaddress=127.0.0.1 `
    connectport=2222

if ($LASTEXITCODE -ne 0) {
    throw "Échec de création du portproxy."
}

# Firewall : uniquement l'adresse WSL détectée.
$RuleName = "MGGT-WSL-Ansible-$ListenPort"

Get-NetFirewallRule -DisplayName $RuleName -ErrorAction SilentlyContinue |
    Remove-NetFirewallRule

New-NetFirewallRule `
    -DisplayName $RuleName `
    -Direction Inbound `
    -Action Allow `
    -Protocol TCP `
    -LocalPort $ListenPort `
    -LocalAddress $WslGateway | Out-Null

# Créer une clé Ansible dédiée dans WSL si elle n'existe pas.
& wsl.exe sh -lc '
umask 077
mkdir -p "$HOME/.ssh"

if [ ! -f "$HOME/.ssh/mggt_gp4_ansible" ]; then
    ssh-keygen -q \
        -t ed25519 \
        -N "" \
        -C "mggt-gp4-ansible" \
        -f "$HOME/.ssh/mggt_gp4_ansible"
fi

chmod 600 "$HOME/.ssh/mggt_gp4_ansible"
chmod 644 "$HOME/.ssh/mggt_gp4_ansible.pub"
'

if ($LASTEXITCODE -ne 0) {
    throw "Échec de préparation de la clé Ansible WSL."
}

$PubKey = (
    & wsl.exe sh -lc 'cat "$HOME/.ssh/mggt_gp4_ansible.pub"'
).Trim()

if (-not $PubKey.StartsWith("ssh-ed25519 ")) {
    throw "Clé publique Ansible invalide."
}

$PubKeyB64 = [Convert]::ToBase64String(
    [Text.Encoding]::UTF8.GetBytes($PubKey)
)

Push-Location $VagrantDir

try {
    # Vérifier le canal Vagrant avant toute modification distante.
    & vagrant ssh $Node -c "echo VAGRANT_SSH_OK"

    if ($LASTEXITCODE -ne 0) {
        throw "Le SSH Vagrant du noeud $Node n'est pas disponible."
    }

    # Installer idempotemment la clé PUBLIQUE Ansible.
    # Aucune clé privée n'est transmise à la VM.
    $RemoteCommand = @"
umask 077
mkdir -p ~/.ssh
touch ~/.ssh/authorized_keys
grep -v 'mggt-gp4-ansible$' ~/.ssh/authorized_keys > ~/.ssh/authorized_keys.mggt || true
printf '%s' '$PubKeyB64' | base64 -d >> ~/.ssh/authorized_keys.mggt
printf '\n' >> ~/.ssh/authorized_keys.mggt
mv ~/.ssh/authorized_keys.mggt ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
echo ANSIBLE_KEY_INSTALLED=YES
"@

    & vagrant ssh $Node -c $RemoteCommand

    if ($LASTEXITCODE -ne 0) {
        throw "Échec d'installation de la clé publique Ansible."
    }
}
finally {
    Pop-Location
}

# Test de bout en bout depuis WSL.
$TestCommand = @"
ssh-keygen -R '[$WslGateway]:$ListenPort' >/dev/null 2>&1 || true
ssh \
  -o IdentitiesOnly=yes \
  -o StrictHostKeyChecking=accept-new \
  -o BatchMode=yes \
  -o ConnectTimeout=10 \
  -i `$HOME/.ssh/mggt_gp4_ansible \
  -p $ListenPort \
  vagrant@$WslGateway \
  'echo ANSIBLE_MANAGEMENT_READY; hostname'
"@

& wsl.exe sh -lc $TestCommand

if ($LASTEXITCODE -ne 0) {
    throw "Le canal WSL -> Ansible n'est pas opérationnel."
}

Write-Host "MGGT_MANAGEMENT_OK=YES"
