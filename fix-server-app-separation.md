# Fix: Server-Specific App Configurations

## Current Problem
Both servers (proxmox-comfy and ALIEN/beelink) have identical app configurations, causing:
- ❌ Apps created on proxmox-comfy show up on beelink server
- ❌ Apps display wrong hostnames when switching servers
- ❌ Confusing user experience about where apps actually run

## Root Cause
The `app_configs` dictionary in `app_manager.py` is hardcoded with the same apps on all servers.

## Solution Options

### Option 1: Use Separate Configuration Files (Recommended)
Create server-specific config files:

1. **Create `apps_config.json` on each server:**
```json
// On proxmox-comfy (192.168.1.227):
{
    "chatterbox": {
        "name": "Chatterbox",
        "description": "AI Chatbot Application",
        "working_dir": "e:/projects/chatterbox-gui",
        "path": "comprehensive_rebuild.py",
        "port": 5000,
        "type": "conda",
        "environment": "chatterbox-cuda",
        "output_folder": "e:/projects/chatterbox-gui/outputs"
    },
    "comfyui": {...},
    "swarmui": {...}
}

// On beelink/ALIEN (192.168.1.136):
{
    // Only apps actually installed on this machine
}
```

2. **Update app_manager.py to load from file:**
```python
import json
import os

# Load server-specific configurations
config_file = 'apps_config.json'
if os.path.exists(config_file):
    with open(config_file, 'r') as f:
        app_configs = json.load(f)
else:
    app_configs = {}  # Empty by default
```

### Option 2: Environment-Based Configuration
Use environment variables or hostname detection:

```python
import socket

hostname = socket.gethostname().lower()

if hostname == 'proxmox-comfy':
    app_configs = {
        'chatterbox': {...},
        'comfyui': {...},
        'swarmui': {...}
    }
elif hostname == 'alien':
    app_configs = {
        # Only apps on this machine
    }
else:
    app_configs = {}  # Empty for unknown servers
```

### Option 3: Quick Fix - Clear Configs on Wrong Servers
For immediate fix, manually edit `app_manager.py` on the beelink server:

```python
# On beelink/ALIEN server, set empty configs:
app_configs = {}
```

## Implementation Steps

### Immediate Fix (5 minutes):
1. **On beelink server (192.168.1.136)**:
   - Edit `/path/to/nexrift/app_manager.py`
   - Replace `app_configs = {...}` with `app_configs = {}`
   - Restart the backend server

2. **Test**:
   - Dashboard → Local Server: Should show no apps
   - Dashboard → Proxmox Server: Should show chatterbox, comfyui, swarmui

### Long-term Solution (Option 1):
1. **Create JSON config files on each server**
2. **Update app_manager.py to load from JSON**
3. **Apps added via dashboard save to JSON file**

## Expected Results After Fix
- ✅ **Proxmox Server**: Shows chatterbox, comfyui, swarmui (all with "proxmox-comfy" hostname)
- ✅ **Beelink Server**: Shows only local apps (or empty if none installed)
- ✅ **No confusion**: Each server only shows its own apps
- ✅ **Correct hostnames**: Apps always show the server they actually exist on