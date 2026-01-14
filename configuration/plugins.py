# plugins.py
# ===========
# Plugin configuration for Netbox with netbox-branching plugin
#
# This file is mounted at /etc/netbox/config/plugins.py in the
# Netbox Docker container for CI integration testing.
#
# The netbox-branching plugin requires:
# 1. PLUGINS list with "netbox_branching"
# 2. DynamicSchemaDict wrapper for DATABASES
# 3. BranchAwareRouter in DATABASE_ROUTERS

import os

# Enable the branching plugin
PLUGINS = ["netbox_branching"]

# Optional: Plugin-specific configuration
PLUGINS_CONFIG = {
    "netbox_branching": {
        # Default plugin settings
    }
}

# ============================================================
# Database configuration for branching plugin
# ============================================================
# The branching plugin creates PostgreSQL schemas for each branch.
# We must wrap DATABASES in DynamicSchemaDict and add BranchAwareRouter.

from netbox_branching.utilities import DynamicSchemaDict

DATABASES = DynamicSchemaDict({
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.environ.get('DB_NAME', 'netbox'),
        'USER': os.environ.get('DB_USER', 'netbox'),
        'PASSWORD': os.environ.get('DB_PASSWORD', 'netbox'),
        'HOST': os.environ.get('DB_HOST', 'postgres'),
        'PORT': os.environ.get('DB_PORT', ''),
        'CONN_MAX_AGE': 300,
    }
})

# Add the branch-aware database router
DATABASE_ROUTERS = [
    'netbox_branching.database.BranchAwareRouter',
]
