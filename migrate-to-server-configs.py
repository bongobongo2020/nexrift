#!/usr/bin/env python3
"""
Migration script to convert existing app_manager.py installations 
to use server-specific configuration files.

Run this script on each server to create initial apps_config.json files.
"""

import json
import socket
import platform
import os

def migrate_server_config():
    """Create initial apps_config.json based on server hostname"""
    
    try:
        hostname = socket.gethostname()
    except Exception:
        hostname = platform.node()
    
    print(f"🔧 Migrating server: {hostname}")
    
    config_file = 'apps_config.json'
    
    if os.path.exists(config_file):
        print(f"✅ Configuration file {config_file} already exists")
        with open(config_file, 'r') as f:
            existing_config = json.load(f)
        print(f"📋 Found {len(existing_config)} existing apps")
        return
    
    # Create server-specific configurations
    if hostname.lower() in ['proxmox-comfy', 'proxmox']:
        # Main AI server configuration
        app_configs = {
            'chatterbox': {
                'name': 'Chatterbox',
                'environment': 'chatterbox-cuda',
                'path': 'e:/projects/chatterbox-gui/comprehensive_rebuild.py',
                'port': 5000,
                'description': 'AI Chatbot Application',
                'working_dir': 'e:/projects/chatterbox-gui',
                'type': 'conda',
                'output_folder': 'e:/projects/chatterbox-gui/outputs'
            },
            'comfyui': {
                'name': 'ComfyUI',
                'environment': None,
                'path': 'python_embeded/python.exe',
                'args': ['-s', 'ComfyUI/main.py', '--windows-standalone-build', '--fast', '--listen', '--enable-cors-header'],
                'port': 8188,
                'description': 'UI for Stable Diffusion',
                'working_dir': 'E:/comfy-chroma/ComfyUI_windows_portable',
                'type': 'executable',
                'output_folder': 'E:/comfy-chroma/ComfyUI_windows_portable/output'
            },
            'swarmui': {
                'name': 'SwarmUI',
                'environment': None,
                'path': 'launch-windows.bat',
                'args': [],
                'port': 7801,
                'description': 'Swarm UI for Stable Diffusion',
                'working_dir': 'D:/swarmui/swarmui',
                'type': 'batch',
                'output_folder': 'D:/swarmui/swarmui/Output'
            }
        }
        print(f"🎯 Created configuration for AI server with {len(app_configs)} apps")
        
    elif hostname.lower() in ['alien', 'beelink', 'beelink2024']:
        # Secondary servers - start empty
        app_configs = {}
        print(f"🆕 Created empty configuration for secondary server")
        
    else:
        # Unknown server - start empty
        app_configs = {}
        print(f"❓ Unknown server '{hostname}' - created empty configuration")
    
    # Save configuration
    try:
        with open(config_file, 'w') as f:
            json.dump(app_configs, f, indent=4)
        
        print(f"✅ Saved configuration to {config_file}")
        print(f"📊 Server: {hostname}")
        print(f"📊 Apps: {len(app_configs)}")
        
        if app_configs:
            print("📋 Configured apps:")
            for app_id, config in app_configs.items():
                print(f"   - {config['name']} (port {config['port']})")
        else:
            print("📋 No apps configured (clean start)")
            
    except Exception as e:
        print(f"❌ Failed to save configuration: {e}")

def show_migration_instructions():
    """Show instructions for completing the migration"""
    print("\n" + "="*60)
    print("🚀 MIGRATION COMPLETE")
    print("="*60)
    print()
    print("📋 Next Steps:")
    print("1. 🔄 Restart the app_manager.py backend server")
    print("2. 🔍 Check the dashboard - should only show apps from this server")
    print("3. ➕ Use 'Add Apps' to add server-specific applications")
    print()
    print("🌐 Multi-Server Setup:")
    print("- Run this script on each server running app_manager.py")
    print("- Each server will have its own apps_config.json file")
    print("- Dashboard will show correct apps for each server")
    print()
    print("🔧 Troubleshooting:")
    print("- If apps still appear on wrong servers, delete their apps_config.json")
    print("- Check server hostnames match the logic in the migration script")
    print("- Verify each server has the updated app_manager.py")

if __name__ == "__main__":
    print("🔧 NexRift Server Configuration Migration")
    print("=" * 50)
    print()
    
    migrate_server_config()
    show_migration_instructions()