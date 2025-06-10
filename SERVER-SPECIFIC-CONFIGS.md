# Server-Specific Configuration System

## Overview
The NexRift app manager now uses server-specific configuration files to ensure each server only shows and manages its own applications.

## 🎯 How It Works

### First Time Setup
When `app_manager.py` runs for the first time on a new computer:

1. **Checks for existing config**: Looks for `apps_config.json`
2. **Server detection**: Identifies the server by hostname
3. **Creates appropriate config**:
   - **Known servers** (proxmox-comfy): Gets default AI apps
   - **New servers**: Starts with empty configuration
4. **Saves to file**: Creates `apps_config.json` automatically

### Server Recognition
- **proxmox-comfy**: Gets default AI apps (Chatterbox, ComfyUI, SwarmUI)
- **alien/beelink**: Starts empty (clean slate)
- **Other servers**: Starts empty (clean slate)

## 📁 File Structure

### apps_config.json
Each server maintains its own configuration file:

```json
{
    "chatterbox": {
        "name": "Chatterbox",
        "description": "AI Chatbot Application",
        "working_dir": "e:/projects/chatterbox-gui",
        "path": "comprehensive_rebuild.py",
        "port": 5000,
        "type": "conda",
        "environment": "chatterbox-cuda",
        "output_folder": "outputs"
    }
}
```

### Automatic Backup
- Creates `.backup` files when saving changes
- Prevents configuration loss during updates

## 🚀 Migration Instructions

### Step 1: Update Backend Code
The updated `app_manager.py` includes:
- ✅ Server-specific configuration loading
- ✅ Automatic config file creation
- ✅ Persistent storage for added/removed apps
- ✅ Hostname-based defaults

### Step 2: Migrate Existing Servers

#### Option A: Automatic Migration (Recommended)
```bash
# Run on each server:
python migrate-to-server-configs.py
```

#### Option B: Manual Migration
1. **On proxmox-comfy server**:
   - Keep existing apps or let system create defaults
   
2. **On other servers** (alien, beelink, etc.):
   - Delete or rename existing `app_manager.py` app_configs
   - Let system start with empty configuration

### Step 3: Restart Servers
```bash
# Stop current backend
# Restart app_manager.py on each server
python app_manager.py
```

## 🔍 Verification

### Check Configuration Loading
Server logs should show:
```
INFO:root:No configuration file found. Creating default config for server: ALIEN
INFO:root:Created empty configuration for new server: ALIEN
INFO:root:Saved 0 app configurations to apps_config.json for server: ALIEN
```

or:
```
INFO:root:Loaded app configurations from apps_config.json
INFO:root:Found 3 apps configured for server: proxmox-comfy
```

### Dashboard Testing
1. **Connect to proxmox-comfy**: Should show AI apps
2. **Connect to other servers**: Should show no apps (or only local apps)
3. **Add new app**: Should save to server's config file
4. **Remove app**: Should update server's config file

## 🎯 Expected Results

### Before Fix
- ❌ **All servers showed same apps**
- ❌ **Wrong hostnames displayed**
- ❌ **Confusing app locations**

### After Fix
- ✅ **Each server shows only its apps**
- ✅ **Correct hostnames displayed**
- ✅ **Clear app ownership**
- ✅ **Persistent configurations**

## 🛠️ Advanced Configuration

### Adding Server-Specific Defaults
Edit the `load_app_configs()` function in `app_manager.py`:

```python
if hostname.lower() in ['your-server-name']:
    app_configs = {
        'your-app': {
            'name': 'Your App',
            # ... configuration
        }
    }
```

### Custom Configuration Location
Change the `CONFIG_FILE` variable:
```python
CONFIG_FILE = '/path/to/custom/apps_config.json'
```

## 🔧 Troubleshooting

### Issue: Apps still appear on wrong servers
**Solution**: Delete `apps_config.json` on affected servers and restart

### Issue: Apps not saving
**Solution**: Check file permissions and disk space

### Issue: Wrong default apps
**Solution**: Verify hostname detection in logs

### Issue: Configuration not loading
**Solution**: Check JSON syntax in `apps_config.json`

## 📊 File Locations

### Configuration Files
- `apps_config.json` - Main configuration
- `apps_config.json.backup` - Automatic backup

### Log Messages
- App loading: `Loaded app configurations from apps_config.json`
- App saving: `Saved X app configurations to apps_config.json`
- First run: `Created default configuration for server: hostname`

## 🔄 Maintenance

### Backup Configurations
```bash
# Manual backup
cp apps_config.json apps_config_$(date +%Y%m%d).json
```

### Reset Server Configuration
```bash
# Remove config file to reset
rm apps_config.json
# Restart app_manager.py to recreate defaults
```

### Sync Between Servers (if needed)
```bash
# Copy config from one server to another
scp server1:/path/apps_config.json server2:/path/apps_config.json
```

This system ensures clean separation between servers while maintaining flexibility for future expansion! 🎯