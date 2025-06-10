# Start Local Backend for Full App Management

## Current Issue
When switching to "Local Server" in settings, you get a 400 error because there's no backend running at 127.0.0.1:8000.

## Solution: Start Local Backend

### Option 1: Use Existing Batch File
```bash
# From the nexrift directory, run:
start_app_manager.bat
```

This will start the backend server at 127.0.0.1:8000 (or 0.0.0.0:8000)

### Option 2: Direct Python Command
```bash
# Make sure you're in the nexrift directory
cd /path/to/nexrift

# Activate environment (if using virtual env)
source app_manager_env/bin/activate
# OR for conda:
conda activate app_manager_env

# Start the server
python app_manager.py
```

### Option 3: Quick Test (No Environment)
```bash
# If you just want to test without environment setup:
python3 app_manager.py
```

## Verification
After starting the local backend, test it:
```bash
curl http://127.0.0.1:8000/api/health
curl http://127.0.0.1:8000/api/apps
curl http://127.0.0.1:8000/api/apps/templates
```

All should return JSON responses.

## Dashboard Settings
1. **Open Settings** in the dashboard
2. **Select "Local Server"** (127.0.0.1:8000)
3. **Click "Save Settings"**
4. **Click "Refresh"** to update the connection

Now you should see:
- ✅ **Correct hostname** for the local machine
- ✅ **App management** working (add/remove apps)
- ✅ **Green connection indicator**

## Benefits of Local Backend
- ✅ **Full app management** (add/remove apps)
- ✅ **Folder picker** works in Electron
- ✅ **Real-time updates** without network latency
- ✅ **No server compatibility issues**