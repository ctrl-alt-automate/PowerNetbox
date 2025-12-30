#!/bin/bash
# Setup script for Netbox on exe.dev VMs
# Usage: ./setup-netbox-vm.sh <netbox-version>
# Example: ./setup-netbox-vm.sh v4.4.9-3.3.0

set -e

NETBOX_VERSION="${1:-v4.4.9-3.3.0}"
NETBOX_PORT="${2:-8080}"

echo "=== Setting up Netbox ${NETBOX_VERSION} ==="

# Install Docker if not present
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com | sh
    sudo usermod -aG docker $USER
    echo "Docker installed. You may need to log out and back in."
fi

# Install Docker Compose plugin if not present
if ! docker compose version &> /dev/null; then
    echo "Installing Docker Compose..."
    sudo apt-get update
    sudo apt-get install -y docker-compose-plugin
fi

# Create netbox directory
mkdir -p ~/netbox
cd ~/netbox

# Download docker-compose from netbox-docker
echo "Downloading netbox-docker configuration..."
curl -sL "https://raw.githubusercontent.com/netbox-community/netbox-docker/release/docker-compose.yml" -o docker-compose.yml
curl -sL "https://raw.githubusercontent.com/netbox-community/netbox-docker/release/docker-compose.override.yml.example" -o docker-compose.override.yml

# Set Netbox version
echo "NETBOX_DOCKER_IMAGE_VERSION=${NETBOX_VERSION}" > .env
echo "Setting Netbox version to ${NETBOX_VERSION}"

# Configure port in override
cat > docker-compose.override.yml << EOF
services:
  netbox:
    ports:
      - "${NETBOX_PORT}:8080"
EOF

# Pull and start
echo "Pulling Netbox Docker images..."
docker compose pull

echo "Starting Netbox..."
docker compose up -d

# Wait for Netbox to be ready
echo "Waiting for Netbox to start (this may take 2-3 minutes)..."
for i in {1..60}; do
    if curl -s "http://localhost:${NETBOX_PORT}/api/" > /dev/null 2>&1; then
        echo "Netbox is ready!"
        break
    fi
    echo -n "."
    sleep 5
done

# Create superuser and API token
echo ""
echo "Creating superuser and API token..."
docker compose exec -T netbox /opt/netbox/netbox/manage.py shell << 'PYTHON'
from django.contrib.auth import get_user_model
from users.models import Token

User = get_user_model()

# Create admin user if not exists
if not User.objects.filter(username='admin').exists():
    admin = User.objects.create_superuser('admin', 'admin@example.com', 'admin')
    print(f"Created admin user")
else:
    admin = User.objects.get(username='admin')
    print(f"Admin user already exists")

# Create API token
token, created = Token.objects.get_or_create(
    user=admin,
    defaults={'key': '0123456789abcdef0123456789abcdef01234567'}
)
if created:
    print(f"Created API token: {token.key}")
else:
    print(f"Existing API token: {token.key}")
PYTHON

# Print connection info
echo ""
echo "=== Netbox Setup Complete ==="
echo "Version:  ${NETBOX_VERSION}"
echo "URL:      http://localhost:${NETBOX_PORT}"
echo "Username: admin"
echo "Password: admin"
echo "API Token: 0123456789abcdef0123456789abcdef01234567"
echo ""
echo "To connect from PowerNetbox:"
echo "  \$token = ConvertTo-SecureString '0123456789abcdef0123456789abcdef01234567' -AsPlainText -Force"
echo "  \$cred = [PSCredential]::new('api', \$token)"
echo "  Connect-NBAPI -Hostname '<vm-hostname>' -Port ${NETBOX_PORT} -Credential \$cred -Scheme http"
