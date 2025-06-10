# Update Remote Server Instructions

## Problem
The remote server at `192.168.1.227:8000` doesn't have the latest API endpoints for app management.

## Solution: Update Remote Server

### Option 1: Copy Updated app_manager.py
1. **Copy the updated app_manager.py to the remote server**:
   ```bash
   scp app_manager.py user@192.168.1.227:/path/to/nexrift/app_manager.py
   ```

2. **Restart the backend server** on 192.168.1.227:
   ```bash
   # Stop the current server (Ctrl+C or kill process)
   # Then restart:
   python app_manager.py
   ```

### Option 2: Manual Update
1. **Remote into 192.168.1.227**
2. **Open the app_manager.py file**
3. **Add these new API endpoints** at the end (before `if __name__ == '__main__':`):

```python
@app.route('/api/apps/config', methods=['GET'])
def get_app_configs():
    """Get all app configurations"""
    return jsonify(app_configs)

@app.route('/api/apps/config', methods=['POST'])
def add_app_config():
    """Add a new app configuration"""
    try:
        data = request.get_json()
        app_id = data.get('id')
        config = data.get('config')
        
        if not app_id or not config:
            return jsonify({'success': False, 'error': 'Missing app ID or config'}), 400
        
        if app_id in app_configs:
            return jsonify({'success': False, 'error': 'App already exists'}), 400
        
        # Validate required config fields
        required_fields = ['name', 'path', 'port', 'description', 'working_dir', 'type']
        for field in required_fields:
            if field not in config:
                return jsonify({'success': False, 'error': f'Missing required field: {field}'}), 400
        
        app_configs[app_id] = config
        logger.info(f"Added new app configuration: {config['name']} ({app_id})")
        
        return jsonify({'success': True, 'message': 'App configuration added successfully'})
    
    except Exception as e:
        logger.error(f"Error adding app config: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/apps/config/<app_id>', methods=['DELETE'])
def remove_app_config(app_id):
    """Remove an app configuration"""
    try:
        if app_id not in app_configs:
            return jsonify({'success': False, 'error': 'App not found'}), 404
        
        # Stop the app if it's running
        if app_id in running_processes:
            stop_app(app_id)
        
        app_name = app_configs[app_id]['name']
        del app_configs[app_id]
        logger.info(f"Removed app configuration: {app_name} ({app_id})")
        
        return jsonify({'success': True, 'message': 'App configuration removed successfully'})
    
    except Exception as e:
        logger.error(f"Error removing app config: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/apps/templates', methods=['GET'])
def get_app_templates():
    """Get popular app templates"""
    templates = {
        'comfyui': {
            'name': 'ComfyUI',
            'description': 'UI for Stable Diffusion',
            'type': 'executable',
            'port': 8188,
            'defaultPath': 'python_embeded/python.exe',
            'defaultArgs': ['-s', 'ComfyUI/main.py', '--windows-standalone-build', '--fast', '--listen', '--enable-cors-header'],
            'outputFolder': 'output',
            'environment': None
        },
        'chatterbox': {
            'name': 'Chatterbox',
            'description': 'AI Chatbot Application',
            'type': 'conda',
            'port': 5000,
            'defaultPath': 'comprehensive_rebuild.py',
            'defaultArgs': [],
            'outputFolder': 'outputs',
            'environment': 'chatterbox-cuda'
        },
        'swarmui': {
            'name': 'SwarmUI',
            'description': 'Swarm UI for Stable Diffusion',
            'type': 'executable',
            'port': 7801,
            'defaultPath': 'launch-windows.bat',
            'defaultArgs': [],
            'outputFolder': 'Output',
            'environment': None
        },
        'automatic1111': {
            'name': 'Automatic1111',
            'description': 'Web UI for Stable Diffusion',
            'type': 'executable',
            'port': 7860,
            'defaultPath': 'webui-user.bat',
            'defaultArgs': [],
            'outputFolder': 'outputs',
            'environment': None
        },
        'invokeai': {
            'name': 'InvokeAI',
            'description': 'InvokeAI Stable Diffusion Toolkit',
            'type': 'conda',
            'port': 9090,
            'defaultPath': 'scripts/invokeai-web.py',
            'defaultArgs': [],
            'outputFolder': 'outputs',
            'environment': 'invokeai'
        }
    }
    return jsonify(templates)
```

4. **Save and restart** the backend server

## Verification
After updating, test the new endpoints:
```bash
curl http://192.168.1.227:8000/api/apps/templates
curl http://192.168.1.227:8000/api/apps/config
```

Both should return JSON responses instead of errors.

## Current Status
- ✅ **Hostname Display**: Fixed to show correct server name and IP
- ✅ **Error Messages**: Improved to explain server compatibility
- ❌ **App Management**: Requires server update for full functionality