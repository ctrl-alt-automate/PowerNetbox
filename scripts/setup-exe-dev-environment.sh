#!/bin/bash
# Setup PowerNetbox development environment on exe.dev
# Prerequisites: exe CLI installed and authenticated

set -e

echo "=== PowerNetbox exe.dev Environment Setup ==="
echo ""

# Check if exe CLI is available
if ! command -v exe &> /dev/null; then
    echo "Error: 'exe' CLI not found. Install from https://exe.dev"
    exit 1
fi

# Define VM configurations
declare -A VMS=(
    ["netbox-stable"]="v4.4.9-3.3.0"
    ["netbox-beta"]="v4.5.0-3.3.0"
    ["netbox-minimum"]="v4.1.11-3.3.0"
)

# Create VMs
echo "=== Creating VMs ==="
for vm_name in "${!VMS[@]}"; do
    echo "Creating VM: $vm_name"
    exe new --name="$vm_name" --no-email 2>/dev/null || echo "  (VM may already exist)"
done

echo ""
echo "=== Waiting for VMs to be ready ==="
sleep 10

# Setup Netbox on each VM
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for vm_name in "${!VMS[@]}"; do
    netbox_version="${VMS[$vm_name]}"
    echo ""
    echo "=== Setting up $vm_name with Netbox $netbox_version ==="

    # Copy setup script to VM
    exe ssh "$vm_name" "cat > /tmp/setup-netbox.sh" < "$SCRIPT_DIR/setup-netbox-vm.sh"

    # Run setup script
    exe ssh "$vm_name" "chmod +x /tmp/setup-netbox.sh && /tmp/setup-netbox.sh $netbox_version"
done

echo ""
echo "=== Environment Setup Complete ==="
echo ""
echo "VMs created:"
exe ls
echo ""
echo "Connection info for PowerNetbox testing:"
echo ""
for vm_name in "${!VMS[@]}"; do
    echo "  $vm_name (${VMS[$vm_name]}):"
    echo "    exe ssh $vm_name"
    echo "    URL: https://$vm_name.exe.dev (or check 'exe ls' for exact URL)"
    echo ""
done

echo "To test connectivity from PowerShell:"
cat << 'EOF'

$vms = @{
    'netbox-stable'  = 'v4.4.9'
    'netbox-beta'    = 'v4.5.0'
    'netbox-minimum' = 'v4.1.11'
}

$token = ConvertTo-SecureString '0123456789abcdef0123456789abcdef01234567' -AsPlainText -Force
$cred = [PSCredential]::new('api', $token)

foreach ($vm in $vms.Keys) {
    Write-Host "Testing $vm..." -ForegroundColor Cyan
    try {
        Connect-NBAPI -Hostname "$vm.exe.dev" -Credential $cred -Scheme https
        $version = Get-NBVersion
        Write-Host "  OK: $($version.'netbox-version')" -ForegroundColor Green
    } catch {
        Write-Host "  Failed: $_" -ForegroundColor Red
    }
}

EOF
