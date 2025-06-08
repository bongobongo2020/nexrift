# .gitignore

```
# Byte-compiled / optimized / DLL files
__pycache__/
*.py[cod]
*$py.class

# C extensions
*.so

# Distribution / packaging
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
share/python-wheels/
*.egg-info/
.installed.cfg
*.egg
MANIFEST

# PyInstaller
#  Usually these files are written by a python script from a template
#  before PyInstaller builds the exe, so as to inject date/other infos into it.
*.manifest
*.spec

# Installer logs
pip-log.txt
pip-delete-this-directory.txt

# Unit test / coverage reports
htmlcov/
.tox/
.nox/
.coverage
.coverage.*
.cache
nosetests.xml
coverage.xml
*.cover
*.py,cover
.hypothesis/
.pytest_cache/
cover/

# Translations
*.mo
*.pot

# Django stuff:
*.log
local_settings.py
db.sqlite3
db.sqlite3-journal

# Flask stuff:
instance/
.webassets-cache

# Scrapy stuff:
.scrapy

# Sphinx documentation
docs/_build/

# PyBuilder
.pybuilder/
target/

# Jupyter Notebook
.ipynb_checkpoints

# IPython
profile_default/
ipython_config.py

# pyenv
#   For a library or package, you might want to ignore these files since the code is
#   intended to run in multiple environments; otherwise, check them in:
# .python-version

# pipenv
#   According to pypa/pipenv#598, it is recommended to include Pipfile.lock in version control.
#   However, in case of collaboration, if having platform-specific dependencies or dependencies
#   having no cross-platform support, pipenv may install dependencies that don't work, or not
#   install all needed dependencies.
#Pipfile.lock

# PEP 582; used by e.g. github.com/David-OConnor/pyflow
__pypackages__/

# Celery stuff
celerybeat-schedule
celerybeat.pid

# SageMath parsed files
*.sage.py

# Environments
.env
.venv
env/
venv/
ENV/
env.bak/
venv.bak/

# Spyder project settings
.spyderproject
.spyproject

# Rope project settings
.ropeproject

# mkdocs documentation
/site

# mypy
.mypy_cache/
.dmypy.json
dmypy.json

# Pyre type checker
.pyre/

# pytype static type analyzer
.pytype/

# Cython debug symbols
cython_debug/

# Project specific
temp_uploads/
dist
models
build
app_manager_env
.aidigestignore
```

# app_manager.py

```py
from flask import Flask, jsonify, request
from flask_cors import CORS
import subprocess
import psutil
import os
import json
import threading
import time
from datetime import datetime
import logging
import signal
import sys

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)  # Enable CORS for frontend communication

# Global storage for running processes
running_processes = {}
app_configs = {
    'chatterbox': {
        'name': 'Chatterbox',
        'environment': 'chatterbox-cuda',
        'path': 'e:/projects/chatterbox-gui/comprehensive_rebuild.py',
        'port': 5000,
        'description': 'AI Chatbot Application',
        'working_dir': 'e:/projects/chatterbox-gui',
        'type': 'conda'  # Uses conda environment
    },
    'comfyui': {
        'name': 'ComfyUI',
        'environment': None,  # Uses embedded python
        'path': 'python_embeded/python.exe',  # Relative path without ./
        'args': ['-s', 'ComfyUI/main.py', '--windows-standalone-build', '--fast', '--listen', '--enable-cors-header'],
        'port': 8188,
        'description': 'UI for Stable Diffusion',
        'working_dir': 'E:/comfy-chroma/ComfyUI_windows_portable',
        'type': 'executable'  # Uses direct executable
    },
    'swarmui': {
        'name': 'SwarmUI',
        'environment': None,  # Uses .NET
        'path': 'launch-windows.bat',  # Batch file launcher
        'args': [],  # No additional args needed
        'port': 7801,
        'description': 'Swarm UI for Stable Diffusion',
        'working_dir': 'D:/swarmui/swarmui',
        'type': 'batch'  # Uses batch file
    }
}

class AppManager:
    def __init__(self):
        self.processes = {}
        self.app_status = {}
        self.start_times = {}
        
    def start_app(self, app_id):
        """Start a Python application in its conda environment or as executable"""
        if app_id not in app_configs:
            return {'success': False, 'error': 'App not found'}
            
        if app_id in self.processes and self.is_process_running(app_id):
            return {'success': False, 'error': 'App is already running'}
            
        config = app_configs[app_id]
        
        try:
            # Set working directory
            working_dir = config.get('working_dir', os.path.dirname(config['path']))
            
            # Build command based on app type
            if config.get('type') == 'executable':
                # For ComfyUI - use embedded python directly
                # Build absolute path for the executable
                if os.path.isabs(config['path']):
                    executable_path = config['path']
                else:
                    executable_path = os.path.join(working_dir, config['path'])
                
                # Convert to Windows-style path and ensure it exists
                executable_path = os.path.normpath(executable_path)
                
                if not os.path.exists(executable_path):
                    raise FileNotFoundError(f"Executable not found: {executable_path}")
                
                cmd = [executable_path] + config.get('args', [])
                logger.info(f"Starting {config['name']} with executable: {executable_path}")
                
            elif config.get('type') == 'batch':
                # For SwarmUI - use batch file
                if os.path.isabs(config['path']):
                    batch_path = config['path']
                else:
                    batch_path = os.path.join(working_dir, config['path'])
                
                batch_path = os.path.normpath(batch_path)
                
                if not os.path.exists(batch_path):
                    raise FileNotFoundError(f"Batch file not found: {batch_path}")
                
                # Use cmd.exe to run the batch file
                cmd = ['cmd.exe', '/c', batch_path] + config.get('args', [])
                logger.info(f"Starting {config['name']} with batch file: {batch_path}")
                
            elif config.get('type') == 'conda' or config.get('environment'):
                # For conda environments
                if os.name == 'nt':  # Windows
                    conda_cmd = 'conda.exe'
                    python_cmd = 'python.exe'
                else:  # Unix-like systems
                    conda_cmd = 'conda'
                    python_cmd = 'python'
                
                if config['environment'] and config['environment'] != 'base':
                    # For non-base environments, use conda run
                    cmd = [
                        conda_cmd, 'run', '-n', config['environment'],
                        python_cmd, config['path']
                    ]
                else:
                    # For base environment, just use python directly
                    cmd = [python_cmd, config['path']]
                    
            else:
                # Default: direct python execution
                cmd = ['python', config['path']]
            
            logger.info(f"Starting {config['name']} in directory: {working_dir}")
            logger.info(f"Command: {' '.join(cmd)}")
            
            # Start the process
            process = subprocess.Popen(
                cmd,
                cwd=working_dir,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                creationflags=subprocess.CREATE_NEW_PROCESS_GROUP if os.name == 'nt' else 0,
                text=True,  # Enable text mode for easier logging
                bufsize=1   # Line buffered
            )
            
            self.processes[app_id] = process
            self.app_status[app_id] = 'running'
            self.start_times[app_id] = datetime.now()
            
            logger.info(f"Started {config['name']} (PID: {process.pid})")
            
            # Start a thread to monitor the process
            monitor_thread = threading.Thread(target=self._monitor_process, args=(app_id,))
            monitor_thread.daemon = True
            monitor_thread.start()
            
            return {
                'success': True, 
                'pid': process.pid,
                'started_at': self.start_times[app_id].isoformat(),
                'command': ' '.join(cmd)
            }
            
        except Exception as e:
            logger.error(f"Failed to start {config['name']}: {str(e)}")
            return {'success': False, 'error': str(e)}
    
    def stop_app(self, app_id):
        """Stop a running Python application"""
        if app_id not in self.processes:
            return {'success': False, 'error': 'App is not running'}
            
        try:
            process = self.processes[app_id]
            
            if os.name == 'nt':  # Windows
                # Use taskkill to terminate the process tree
                subprocess.run(['taskkill', '/F', '/T', '/PID', str(process.pid)], 
                             check=False, capture_output=True)
            else:  # Unix-like systems
                # Send SIGTERM first, then SIGKILL if needed
                try:
                    process.terminate()
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()
            
            # Clean up
            del self.processes[app_id]
            self.app_status[app_id] = 'stopped'
            if app_id in self.start_times:
                del self.start_times[app_id]
                
            config = app_configs[app_id]
            logger.info(f"Stopped {config['name']}")
            
            return {'success': True}
            
        except Exception as e:
            logger.error(f"Failed to stop {app_id}: {str(e)}")
            return {'success': False, 'error': str(e)}
    
    def get_app_status(self, app_id):
        """Get the current status of an application"""
        if app_id not in app_configs:
            return {'error': 'App not found'}
            
        config = app_configs[app_id]
        is_running = self.is_process_running(app_id)
        
        status = {
            'id': app_id,
            'name': config['name'],
            'status': 'running' if is_running else 'stopped',
            'environment': config['environment'],
            'path': config['path'],
            'port': config['port'],
            'description': config['description']
        }
        
        if is_running and app_id in self.start_times:
            uptime = (datetime.now() - self.start_times[app_id]).total_seconds()
            status['uptime'] = int(uptime)
            status['started_at'] = self.start_times[app_id].isoformat()
            status['pid'] = self.processes[app_id].pid
            
        return status
    
    def get_all_apps_status(self):
        """Get status of all configured applications"""
        return [self.get_app_status(app_id) for app_id in app_configs.keys()]
    
    def is_process_running(self, app_id):
        """Check if a process is still running"""
        if app_id not in self.processes:
            return False
            
        process = self.processes[app_id]
        return process.poll() is None
    
    def _monitor_process(self, app_id):
        """Monitor a process and update status when it exits"""
        process = self.processes[app_id]
        config = app_configs[app_id]
        
        # Wait for process to exit and capture output
        stdout, stderr = process.communicate()
        
        # Log the output for debugging (already strings due to text=True)
        if stdout:
            logger.info(f"{config['name']} stdout: {stdout}")
        if stderr:
            logger.error(f"{config['name']} stderr: {stderr}")
        
        # Process has exited, clean up
        exit_code = process.returncode
        logger.info(f"{config['name']} process exited with code: {exit_code}")
        
        if app_id in self.processes:
            del self.processes[app_id]
        self.app_status[app_id] = 'stopped'
        if app_id in self.start_times:
            del self.start_times[app_id]

# Initialize the app manager
app_manager = AppManager()

# API Routes
@app.route('/api/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'server': '192.168.1.227'
    })

@app.route('/api/apps', methods=['GET'])
def get_all_apps():
    """Get status of all applications"""
    return jsonify(app_manager.get_all_apps_status())

@app.route('/api/apps/<app_id>', methods=['GET'])
def get_app_status(app_id):
    """Get status of a specific application"""
    status = app_manager.get_app_status(app_id)
    if 'error' in status:
        return jsonify(status), 404
    return jsonify(status)

@app.route('/api/apps/<app_id>/start', methods=['POST'])
def start_app(app_id):
    """Start an application"""
    result = app_manager.start_app(app_id)
    status_code = 200 if result['success'] else 400
    return jsonify(result), status_code

@app.route('/api/apps/<app_id>/stop', methods=['POST'])
def stop_app(app_id):
    """Stop an application"""
    result = app_manager.stop_app(app_id)
    status_code = 200 if result['success'] else 400
    return jsonify(result), status_code

@app.route('/api/apps/<app_id>/logs', methods=['GET'])
def get_app_logs(app_id):
    """Get recent logs for an application"""
    if app_id not in app_configs:
        return jsonify({'error': 'App not found'}), 404
        
    config = app_configs[app_id]
    
    # Check if process is running
    is_running = app_manager.is_process_running(app_id)
    
    logs = []
    if app_id in app_manager.processes:
        process = app_manager.processes[app_id]
        
        # Try to read available output without blocking
        try:
            # Check if process has terminated and read final output
            if process.poll() is not None:
                stdout, stderr = process.communicate(timeout=1)
                if stdout:
                    logs.append({'type': 'stdout', 'content': stdout})
                if stderr:
                    logs.append({'type': 'stderr', 'content': stderr})
        except subprocess.TimeoutExpired:
            # Process is still running, can't get output easily without blocking
            logs.append({'type': 'info', 'content': 'Process is running, logs available after termination'})
        except Exception as e:
            logs.append({'type': 'error', 'content': f'Error reading logs: {str(e)}'})
    
    return jsonify({
        'app_id': app_id,
        'name': config['name'],
        'is_running': is_running,
        'logs': logs,
        'pid': app_manager.processes[app_id].pid if app_id in app_manager.processes else None
    })

@app.route('/api/apps/<app_id>/status/detailed', methods=['GET'])
def get_detailed_app_status(app_id):
    """Get detailed status including process health check"""
    if app_id not in app_configs:
        return jsonify({'error': 'App not found'}), 404
        
    status = app_manager.get_app_status(app_id)
    config = app_configs[app_id]
    
    # Additional checks for running processes
    if status['status'] == 'running' and app_id in app_manager.processes:
        process = app_manager.processes[app_id]
        
        # Check if process is actually running
        process_running = process.poll() is None
        
        # Try to check if the port is accessible (basic health check)
        port_accessible = False
        try:
            import socket
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(2)
            result = sock.connect_ex(('localhost', config['port']))
            port_accessible = result == 0
            sock.close()
        except Exception:
            port_accessible = False
        
        status.update({
            'process_running': process_running,
            'port_accessible': port_accessible,
            'health_check': 'healthy' if (process_running and port_accessible) else 'unhealthy',
            'return_code': process.returncode
        })
    
    return jsonify(status)

@app.route('/api/apps/<app_id>/test', methods=['GET'])
def test_app_config(app_id):
    """Test app configuration without starting it"""
    if app_id not in app_configs:
        return jsonify({'error': 'App not found'}), 404
        
    config = app_configs[app_id]
    working_dir = config.get('working_dir', os.path.dirname(config['path']))
    
    # Build the command that would be executed
    try:
        if config.get('type') == 'executable':
            cmd = [config['path']] + config.get('args', [])
        elif config.get('type') == 'conda' or config.get('environment'):
            if os.name == 'nt':
                conda_cmd = 'conda.exe'
                python_cmd = 'python.exe'
            else:
                conda_cmd = 'conda'
                python_cmd = 'python'
            
            if config['environment'] and config['environment'] != 'base':
                cmd = [conda_cmd, 'run', '-n', config['environment'], python_cmd, config['path']]
            else:
                cmd = [python_cmd, config['path']]
        else:
            cmd = ['python', config['path']]
        
        # Check if working directory exists
        working_dir_exists = os.path.exists(working_dir)
        
        # Check if main executable/script exists
        main_path_exists = os.path.exists(config['path']) if config.get('type') != 'executable' else os.path.exists(os.path.join(working_dir, config['path']))
        
        return jsonify({
            'app_id': app_id,
            'name': config['name'],
            'type': config.get('type', 'conda'),
            'command': cmd,
            'working_dir': working_dir,
            'working_dir_exists': working_dir_exists,
            'main_path_exists': main_path_exists,
            'full_config': config
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/apps/<app_id>/restart', methods=['POST'])
def restart_app(app_id):
    """Restart an application"""
    # Stop first
    stop_result = app_manager.stop_app(app_id)
    if not stop_result['success'] and 'not running' not in stop_result.get('error', ''):
        return jsonify(stop_result), 400
    
    # Wait a moment for cleanup
    time.sleep(2)
    
    # Start again
    start_result = app_manager.start_app(app_id)
    status_code = 200 if start_result['success'] else 400
    return jsonify(start_result), status_code

@app.route('/api/server/status', methods=['GET'])
def server_status():
    """Get server system information"""
    try:
        cpu_percent = psutil.cpu_percent(interval=1)
        memory = psutil.virtual_memory()
        disk = psutil.disk_usage('/')
        
        return jsonify({
            'cpu_usage': cpu_percent,
            'memory_usage': memory.percent,
            'memory_total': memory.total,
            'memory_used': memory.used,
            'disk_usage': disk.percent,
            'disk_total': disk.total,
            'disk_used': disk.used,
            'running_apps': len([app for app in app_manager.get_all_apps_status() if app['status'] == 'running'])
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

def signal_handler(sig, frame):
    """Handle shutdown signals gracefully"""
    logger.info('Shutting down server...')
    
    # Stop all running applications
    for app_id in list(app_manager.processes.keys()):
        logger.info(f'Stopping {app_id}...')
        app_manager.stop_app(app_id)
    
    sys.exit(0)

# Register signal handlers for graceful shutdown
signal.signal(signal.SIGINT, signal_handler)
signal.signal(signal.SIGTERM, signal_handler)

if __name__ == '__main__':
    logger.info("Starting Python App Management Server...")
    logger.info("Configured applications:")
    for app_id, config in app_configs.items():
        logger.info(f"  - {config['name']} ({app_id}): {config['path']}")
    
    # Run the server
    app.run(
        host='0.0.0.0',  # Listen on all interfaces
        port=8000,
        debug=False,
        threaded=True
    )
```

# dashboard/dashboard.html

```html

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Python App Dashboard</title>
    <script src="https://unpkg.com/react@18/umd/react.production.min.js"></script>
    <script src="https://unpkg.com/react-dom@18/umd/react-dom.production.min.js"></script>
    <script src="https://unpkg.com/@babel/standalone/babel.min.js"></script>
    <script src="https://cdn.tailwindcss.com"></script>
    <style>
        /* Fallback styles if Tailwind doesn't load */
        .fallback-container { max-width: 1200px; margin: 0 auto; padding: 20px; }
        .fallback-card { background: rgba(255,255,255,0.1); border-radius: 12px; padding: 20px; margin: 10px 0; }
        .fallback-button { background: #3b82f6; color: white; padding: 10px 20px; border: none; border-radius: 6px; cursor: pointer; margin: 5px; }
        .fallback-button:hover { background: #2563eb; }
        .fallback-button:disabled { background: #6b7280; cursor: not-allowed; }
    </style>
</head>
<body style="margin: 0; background: linear-gradient(135deg, #1e293b, #7c3aed, #1e293b); min-height: 100vh; font-family: system-ui, -apple-system, sans-serif;">
    <div id="root">
        <!-- Loading fallback -->
        <div style="display: flex; justify-content: center; align-items: center; height: 100vh; color: white;">
            <div>Loading dashboard...</div>
        </div>
    </div>

    <script type="text/babel">
        const { useState, useEffect, createElement: h } = React;

        // Simple icon components (fallback if Lucide doesn't load)
        const PlayIcon = () => h('svg', { width: 16, height: 16, viewBox: '0 0 24 24', fill: 'currentColor' },
            h('path', { d: 'M8 5v14l11-7z' })
        );
        
        const StopIcon = () => h('svg', { width: 16, height: 16, viewBox: '0 0 24 24', fill: 'currentColor' },
            h('rect', { x: 6, y: 6, width: 12, height: 12 })
        );
        
        const RefreshIcon = () => h('svg', { width: 16, height: 16, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: 2 },
            h('path', { d: 'M3 12a9 9 0 0 1 9-9 9.75 9.75 0 0 1 6.74 2.74L21 8' }),
            h('path', { d: 'M21 3v5h-5' }),
            h('path', { d: 'M21 12a9 9 0 0 1-9 9 9.75 9.75 0 0 1-6.74-2.74L3 16' }),
            h('path', { d: 'M3 21v-5h5' })
        );
        
        const ServerIcon = () => h('svg', { width: 16, height: 16, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: 2 },
            h('rect', { x: 2, y: 3, width: 20, height: 4, rx: 1 }),
            h('rect', { x: 2, y: 9, width: 20, height: 4, rx: 1 }),
            h('rect', { x: 2, y: 15, width: 20, height: 4, rx: 1 }),
            h('line', { x1: 6, y1: 5, x2: 6, y2: 5 }),
            h('line', { x1: 6, y1: 11, x2: 6, y2: 11 }),
            h('line', { x1: 6, y1: 17, x2: 6, y2: 17 })
        );

        const CheckIcon = () => h('svg', { width: 16, height: 16, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: 2 },
            h('path', { d: 'M9 12l2 2 4-4' }),
            h('circle', { cx: 12, cy: 12, r: 10 })
        );

        const ClockIcon = () => h('svg', { width: 16, height: 16, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: 2 },
            h('circle', { cx: 12, cy: 12, r: 10 }),
            h('polyline', { points: '12,6 12,12 16,14' })
        );

        const Dashboard = () => {
            const [apps, setApps] = useState([]);
            const [serverStatus, setServerStatus] = useState('disconnected');
            const [loading, setLoading] = useState(true);
            const [error, setError] = useState(null);
            const serverAddress = '192.168.1.227:8000';

            const fetchAppsStatus = async () => {
                try {
                    const response = await fetch(`http://${serverAddress}/api/apps`);
                    if (!response.ok) throw new Error(`HTTP ${response.status}: ${response.statusText}`);
                    const data = await response.json();
                    setApps(data);
                    setServerStatus('connected');
                    setError(null);
                } catch (err) {
                    console.error('Failed to fetch apps:', err);
                    setServerStatus('disconnected');
                    setError(`Cannot connect to backend server at ${serverAddress}. Make sure it's running.`);
                }
            };

            useEffect(() => {
                fetchAppsStatus();
                setLoading(false);
                
                const interval = setInterval(fetchAppsStatus, 5000);
                return () => clearInterval(interval);
            }, []);

            const formatUptime = (seconds) => {
                if (!seconds) return '00:00:00';
                const hours = Math.floor(seconds / 3600);
                const minutes = Math.floor((seconds % 3600) / 60);
                const secs = seconds % 60;
                return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
            };

            const handleAppAction = async (appId, action) => {
                try {
                    setApps(prevApps => 
                        prevApps.map(app => 
                            app.id === appId 
                                ? { ...app, status: action === 'start' ? 'starting' : 'stopping' }
                                : app
                        )
                    );

                    const response = await fetch(`http://${serverAddress}/api/apps/${appId}/${action}`, {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                    });

                    const result = await response.json();
                    
                    if (!result.success) {
                        throw new Error(result.error || `Failed to ${action} app`);
                    }

                    setTimeout(fetchAppsStatus, 2000);
                    
                } catch (err) {
                    console.error(`Failed to ${action} app:`, err);
                    setError(`Failed to ${action} ${appId}: ${err.message}`);
                    fetchAppsStatus();
                }
            };

            const getStatusIcon = (status) => {
                const className = "w-5 h-5";
                const style = { 
                    color: status === 'running' ? '#10b981' : 
                           status === 'stopped' ? '#6b7280' : '#f59e0b' 
                };
                
                if (status === 'running') return h(CheckIcon, { className, style });
                if (status === 'starting' || status === 'stopping') {
                    return h('div', { 
                        className: className + ' animate-pulse',
                        style: { ...style, animation: 'pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite' }
                    }, '●');
                }
                return h(StopIcon, { className, style });
            };

            const getStatusColor = (status) => {
                switch (status) {
                    case 'running': return { background: '#dcfce7', color: '#166534', border: '1px solid #bbf7d0' };
                    case 'stopped': return { background: '#f3f4f6', color: '#374151', border: '1px solid #d1d5db' };
                    case 'starting':
                    case 'stopping': return { background: '#fef3c7', color: '#92400e', border: '1px solid #fde68a' };
                    default: return { background: '#fee2e2', color: '#991b1b', border: '1px solid #fecaca' };
                }
            };

            if (loading) {
                return h('div', {
                    className: "min-h-screen bg-gradient-to-br from-slate-900 via-purple-900 to-slate-900 flex items-center justify-center"
                }, h('div', { className: "text-white text-xl" }, 'Loading dashboard...'));
            }

            return h('div', { className: "min-h-screen bg-gradient-to-br from-slate-900 via-purple-900 to-slate-900" },
                h('div', { className: "container mx-auto px-6 py-8" },
                    // Header
                    h('div', { className: "mb-8" },
                        h('div', { className: "flex items-center justify-between mb-6" },
                            h('div', null,
                                h('h1', { className: "text-4xl font-bold text-white mb-2" }, 'App Dashboard'),
                                h('p', { className: "text-slate-300" }, 'Manage Python applications on your server')
                            ),
                            h('div', { className: "flex items-center space-x-4" },
                                h('button', {
                                    onClick: fetchAppsStatus,
                                    className: "flex items-center space-x-2 bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg transition-colors"
                                },
                                    h(RefreshIcon, { className: "w-4 h-4" }),
                                    h('span', null, 'Refresh')
                                ),
                                h('div', { className: "flex items-center space-x-2 bg-white/10 backdrop-blur-sm rounded-lg px-4 py-2" },
                                    h(ServerIcon, { className: "w-5 h-5 text-blue-400" }),
                                    h('span', { className: "text-white font-medium" }, '192.168.1.227'),
                                    h('div', { 
                                        className: `w-3 h-3 rounded-full ${serverStatus === 'connected' ? 'bg-green-400' : 'bg-red-400'}`,
                                        style: { animation: 'pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite' }
                                    })
                                )
                            )
                        ),
                        error && h('div', { 
                            className: "bg-red-500/10 border border-red-500/20 rounded-lg p-4 mb-4",
                            style: { background: 'rgba(239, 68, 68, 0.1)', border: '1px solid rgba(239, 68, 68, 0.2)' }
                        },
                            h('p', { className: "text-red-400", style: { color: '#f87171' } }, `⚠️ ${error}`)
                        )
                    ),

                    // App Cards
                    h('div', { className: "grid grid-cols-1 lg:grid-cols-2 gap-6" },
                        apps.map((app) =>
                            h('div', {
                                key: app.id,
                                className: "bg-white/10 backdrop-blur-sm rounded-xl border border-white/20 p-6 hover:bg-white/15 transition-all duration-300",
                                style: { 
                                    background: 'rgba(255, 255, 255, 0.1)', 
                                    border: '1px solid rgba(255, 255, 255, 0.2)',
                                    borderRadius: '12px'
                                }
                            },
                                h('div', { className: "flex items-start justify-between mb-4" },
                                    h('div', { className: "flex items-center space-x-3" },
                                        h('div', { 
                                            className: "p-2 bg-blue-500/20 rounded-lg",
                                            style: { background: 'rgba(59, 130, 246, 0.2)', borderRadius: '8px' }
                                        },
                                            h('div', { 
                                                className: "w-6 h-6 text-blue-400",
                                                style: { color: '#60a5fa', fontSize: '24px' }
                                            }, '⚡')
                                        ),
                                        h('div', null,
                                            h('h3', { className: "text-xl font-semibold text-white" }, app.name),
                                            h('p', { className: "text-slate-300 text-sm", style: { color: '#cbd5e1' } }, app.description)
                                        )
                                    ),
                                    h('div', { className: "flex items-center space-x-2" },
                                        getStatusIcon(app.status),
                                        h('span', {
                                            className: "px-3 py-1 rounded-full text-xs font-medium",
                                            style: {
                                                ...getStatusColor(app.status),
                                                borderRadius: '999px',
                                                padding: '4px 12px',
                                                fontSize: '12px'
                                            }
                                        }, app.status.charAt(0).toUpperCase() + app.status.slice(1))
                                    )
                                ),

                                h('div', { className: "space-y-3 mb-6" },
                                    h('div', { className: "flex items-center justify-between" },
                                        h('span', { className: "text-slate-300 text-sm", style: { color: '#cbd5e1' } }, 'Environment:'),
                                        h('span', { 
                                            className: "text-white font-mono text-sm bg-slate-800/50 px-2 py-1 rounded",
                                            style: { 
                                                color: 'white', 
                                                fontFamily: 'monospace',
                                                background: 'rgba(30, 41, 59, 0.5)',
                                                padding: '4px 8px',
                                                borderRadius: '4px'
                                            }
                                        }, app.environment)
                                    ),
                                    h('div', { className: "flex items-center justify-between" },
                                        h('span', { className: "text-slate-300 text-sm", style: { color: '#cbd5e1' } }, 'Port:'),
                                        h('span', { 
                                            className: "text-white font-mono text-sm",
                                            style: { color: 'white', fontFamily: 'monospace' }
                                        }, app.port)
                                    ),
                                    h('div', { className: "flex items-center justify-between" },
                                        h('span', { className: "text-slate-300 text-sm", style: { color: '#cbd5e1' } }, 'Path:'),
                                        h('span', { 
                                            className: "text-white font-mono text-xs bg-slate-800/50 px-2 py-1 rounded truncate",
                                            style: { 
                                                color: 'white', 
                                                fontFamily: 'monospace',
                                                background: 'rgba(30, 41, 59, 0.5)',
                                                padding: '4px 8px',
                                                borderRadius: '4px',
                                                maxWidth: '200px',
                                                overflow: 'hidden',
                                                textOverflow: 'ellipsis'
                                            },
                                            title: app.path
                                        }, app.path)
                                    ),
                                    app.status === 'running' && app.uptime !== undefined && h('div', { className: "flex items-center justify-between" },
                                        h('span', { className: "text-slate-300 text-sm flex items-center", style: { color: '#cbd5e1' } },
                                            h(ClockIcon, { className: "w-4 h-4 mr-1" }),
                                            'Uptime:'
                                        ),
                                        h('span', { 
                                            className: "text-green-400 font-mono text-sm",
                                            style: { color: '#4ade80', fontFamily: 'monospace' }
                                        }, formatUptime(app.uptime))
                                    ),
                                    app.started_at && h('div', { className: "flex items-center justify-between" },
                                        h('span', { className: "text-slate-300 text-sm", style: { color: '#cbd5e1' } }, 'Last Started:'),
                                        h('span', { className: "text-white text-sm" }, new Date(app.started_at).toLocaleTimeString())
                                    )
                                ),

                                h('div', { className: "flex space-x-3" },
                                    h('button', {
                                        onClick: () => handleAppAction(app.id, 'start'),
                                        disabled: app.status === 'running' || app.status === 'starting',
                                        className: "flex-1 flex items-center justify-center space-x-2 bg-green-600 hover:bg-green-700 disabled:bg-gray-600 disabled:cursor-not-allowed text-white font-medium py-3 px-4 rounded-lg transition-colors duration-200",
                                        style: {
                                            background: (app.status === 'running' || app.status === 'starting') ? '#6b7280' : '#16a34a',
                                            color: 'white',
                                            padding: '12px 16px',
                                            borderRadius: '8px',
                                            border: 'none',
                                            cursor: (app.status === 'running' || app.status === 'starting') ? 'not-allowed' : 'pointer',
                                            flex: 1,
                                            display: 'flex',
                                            alignItems: 'center',
                                            justifyContent: 'center',
                                            gap: '8px'
                                        }
                                    },
                                        h(PlayIcon, { className: "w-4 h-4" }),
                                        h('span', null, 'Start')
                                    ),
                                    h('button', {
                                        onClick: () => handleAppAction(app.id, 'stop'),
                                        disabled: app.status === 'stopped' || app.status === 'stopping',
                                        className: "flex-1 flex items-center justify-center space-x-2 bg-red-600 hover:bg-red-700 disabled:bg-gray-600 disabled:cursor-not-allowed text-white font-medium py-3 px-4 rounded-lg transition-colors duration-200",
                                        style: {
                                            background: (app.status === 'stopped' || app.status === 'stopping') ? '#6b7280' : '#dc2626',
                                            color: 'white',
                                            padding: '12px 16px',
                                            borderRadius: '8px',
                                            border: 'none',
                                            cursor: (app.status === 'stopped' || app.status === 'stopping') ? 'not-allowed' : 'pointer',
                                            flex: 1,
                                            display: 'flex',
                                            alignItems: 'center',
                                            justifyContent: 'center',
                                            gap: '8px'
                                        }
                                    },
                                        h(StopIcon, { className: "w-4 h-4" }),
                                        h('span', null, 'Stop')
                                    )
                                ),

                                app.status === 'running' && h('div', { 
                                    className: "mt-4 p-3 bg-green-500/10 border border-green-500/20 rounded-lg",
                                    style: {
                                        marginTop: '16px',
                                        padding: '12px',
                                        background: 'rgba(34, 197, 94, 0.1)',
                                        border: '1px solid rgba(34, 197, 94, 0.2)',
                                        borderRadius: '8px'
                                    }
                                },
                                    h('p', { className: "text-green-400 text-sm", style: { color: '#4ade80' } },
                                        'Application is accessible at: ',
                                        h('a', {
                                            href: `http://192.168.1.227:${app.port}`,
                                            target: '_blank',
                                            rel: 'noopener noreferrer',
                                            className: "ml-2 underline hover:text-green-300",
                                            style: { marginLeft: '8px', textDecoration: 'underline', color: '#4ade80' }
                                        }, `192.168.1.227:${app.port}`)
                                    )
                                )
                            )
                        )
                    ),

                    // Footer
                    h('div', { className: "mt-12 text-center" },
                        h('p', { className: "text-slate-400 text-sm", style: { color: '#94a3b8' } },
                            'Server Dashboard • Managing applications on 192.168.1.227'
                        )
                    )
                )
            );
        };

        // Render the dashboard
        ReactDOM.render(React.createElement(Dashboard), document.getElementById('root'));
    </script>

    <style>
        @keyframes pulse {
            0%, 100% { opacity: 1; }
            50% { opacity: .5; }
        }
        .animate-pulse { animation: pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite; }
    </style>
</body>
</html>
```

# dashboard/serve_dashboard.py

```py
import http.server
import socketserver
import webbrowser
import os

PORT = 8080

class MyHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        super().end_headers()

if __name__ == "__main__":
    with socketserver.TCPServer(("", PORT), MyHTTPRequestHandler) as httpd:
        print(f"Dashboard server running at http://localhost:{PORT}")
        print("Press Ctrl+C to stop")
        webbrowser.open(f'http://localhost:{PORT}/dashboard.html')
        httpd.serve_forever()
```

# readme-md.md

```md
# Python App Manager

A modern web-based dashboard for managing Python applications running on a remote server. Start, stop, and monitor your applications with a beautiful, responsive interface.

## ✨ Features

- **🚀 Remote App Management** - Start and stop Python applications from anywhere
- **🎨 Modern Dashboard** - Beautiful, responsive web interface with real-time updates
- **🔧 Multiple App Types** - Support for conda environments, executables, and batch files
- **📊 Live Status** - Real-time app status, uptime tracking, and health monitoring
- **🖥️ Easy Setup** - One-click batch file launchers for Windows
- **🌐 Network Access** - Access your apps from any device on your network

## 📱 Screenshots

The dashboard provides:
- Real-time application status monitoring
- Start/Stop controls for each application
- Uptime tracking and last started timestamps
- Direct links to running applications
- Error handling and connection status

## 🛠️ Installation

### Prerequisites

- **Python 3.8+** installed on your system
- **Git** (optional, for cloning)
- **Windows** (batch files are Windows-specific, but the app works on any OS)

### Step 1: Clone or Download

\`\`\`bash
git clone <repository-url>
cd python-app-manager
\`\`\`

Or download and extract the files to your desired directory (e.g., `E:\projects\pythonappmanager`).

### Step 2: Create Virtual Environment

**Option A: Using Conda (Recommended)**
\`\`\`bash
conda create -n app_manager_env python=3.9
conda activate app_manager_env
\`\`\`

**Option B: Using Python venv**
\`\`\`bash
python -m venv app_manager_env
app_manager_env\Scripts\activate  # Windows
source app_manager_env/bin/activate  # Linux/Mac
\`\`\`

### Step 3: Install Dependencies

\`\`\`bash
pip install Flask Flask-CORS psutil
\`\`\`

### Step 4: Configure Your Applications

Edit the `app_configs` dictionary in `app_manager.py` to match your applications:

\`\`\`python
app_configs = {
    'your_app': {
        'name': 'Your App Name',
        'environment': 'your-conda-env',  # or None
        'path': 'path/to/your/script.py',
        'port': 8000,
        'description': 'Your app description',
        'working_dir': 'path/to/working/directory',
        'type': 'conda'  # or 'executable', 'batch'
    }
}
\`\`\`

### Step 5: Set Up Dashboard

Create a `dashboard` directory and set up the frontend:

\`\`\`bash
mkdir dashboard
cd dashboard
python ../setup_dashboard.py  # This creates dashboard.html and serve_dashboard.py
\`\`\`

## 🚀 Quick Start

### Option 1: Using Batch Files (Windows - Recommended)

1. **Download the batch files** from the artifacts and save them:
   - `start_all.bat` → Save to your Desktop
   - `start_app_manager.bat` → Save to project directory
   - `start_dashboard.bat` → Save to dashboard directory

2. **Update paths** in the batch files:
   \`\`\`batch
   set PROJECT_DIR=E:\projects\pythonappmanager
   set DASHBOARD_DIR=E:\projects\pythonappmanager\dashboard
   set ENV_NAME=app_manager_env
   \`\`\`

3. **Double-click `start_all.bat`** from your desktop and choose:
   - `[3] Start Both (Backend + Dashboard)` for first-time setup

4. **Access your dashboard** at: `http://localhost:8080/dashboard.html`

### Option 2: Manual Start

**Terminal 1 - Backend Server:**
\`\`\`bash
cd /path/to/pythonappmanager
conda activate app_manager_env  # or activate your venv
python app_manager.py
\`\`\`

**Terminal 2 - Dashboard Server:**
\`\`\`bash
cd /path/to/pythonappmanager/dashboard
python serve_dashboard.py
\`\`\`

## 🔧 Configuration

### Application Types

**Conda/Virtual Environment Apps:**
\`\`\`python
'my_python_app': {
    'type': 'conda',
    'environment': 'my-conda-env',
    'path': '/path/to/script.py',
    'working_dir': '/path/to/working/dir'
}
\`\`\`

**Executable Apps (like ComfyUI):**
\`\`\`python
'comfyui': {
    'type': 'executable',
    'path': 'python_embeded/python.exe',
    'args': ['-s', 'ComfyUI/main.py', '--listen'],
    'working_dir': '/path/to/ComfyUI'
}
\`\`\`

**Batch File Apps (like SwarmUI):**
\`\`\`python
'swarmui': {
    'type': 'batch',
    'path': 'launch-windows.bat',
    'working_dir': '/path/to/swarmui'
}
\`\`\`

### Network Configuration

By default, the system uses:
- **Backend**: `192.168.1.227:5000`
- **Dashboard**: `localhost:8080`

To change the server IP, update the `serverAddress` variable in `dashboard.html`:
\`\`\`javascript
const serverAddress = 'YOUR_IP:5000';
\`\`\`

## 📡 API Endpoints

The backend provides a REST API:

- `GET /api/health` - Health check
- `GET /api/apps` - List all applications
- `GET /api/apps/{app_id}` - Get app status
- `POST /api/apps/{app_id}/start` - Start application
- `POST /api/apps/{app_id}/stop` - Stop application
- `POST /api/apps/{app_id}/restart` - Restart application
- `GET /api/apps/{app_id}/test` - Test app configuration

## 🔍 Troubleshooting

### Common Issues

**Backend won't start:**
- Check if the correct environment is activated
- Verify all dependencies are installed: `pip list`
- Check if port 5000 is available

**Apps won't start:**
- Use the test endpoint: `curl http://192.168.1.227:5000/api/apps/YOUR_APP/test`
- Check paths in the configuration
- Verify conda environments exist: `conda env list`

**Dashboard shows connection error:**
- Ensure backend is running on the correct IP/port
- Check firewall settings
- Verify the `serverAddress` in dashboard.html

**Permission errors:**
- Run batch files as Administrator if needed
- Check file permissions on scripts and working directories

### Debug Commands

\`\`\`bash
# Test backend health
curl http://192.168.1.227:5000/api/health

# Check app configuration
curl http://192.168.1.227:5000/api/apps/YOUR_APP/test

# View app status
curl http://192.168.1.227:5000/api/apps

# Check detailed app status
curl http://192.168.1.227:5000/api/apps/YOUR_APP/status/detailed
\`\`\`

## 🎯 Batch File Reference

### Master Launcher (`start_all.bat`)
Interactive menu with options:
- Start Backend Server Only
- Start Dashboard Only
- Start Both Services
- Open Dashboard in Browser
- Check Server Status

### Individual Launchers
- `start_app_manager.bat` - Backend server with environment activation
- `start_dashboard.bat` - Dashboard web server with auto-browser opening

## 🔗 Access URLs

Once running, access your services at:
- **Dashboard**: `http://localhost:8080/dashboard.html`
- **Backend API**: `http://192.168.1.227:5000`
- **Your Apps**: Links provided in dashboard when running

## 📝 Example Applications

The system comes pre-configured with examples for:
- **Chatterbox** - Python app with conda environment
- **ComfyUI** - Portable app with embedded Python
- **SwarmUI** - .NET app with batch file launcher

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is open source. See LICENSE file for details.

## 🆘 Support

If you encounter issues:
1. Check the troubleshooting section
2. Use the debug commands to diagnose
3. Check the batch file error messages
4. Ensure all paths and configurations are correct

---

**Made with ❤️ for easy Python app management**
```

# start_all.bat

```bat
@echo off
setlocal enabledelayedexpansion

rem ============================================================================
rem Python App Manager - Master Launcher
rem This script provides options to start the backend, dashboard, or both
rem ============================================================================

title Python App Manager - Master Launcher

:menu
cls
echo.
echo ===============================================
echo     Python App Manager - Master Launcher
echo ===============================================
echo.
echo Select an option:
echo.
echo [1] Start Backend Server Only
echo [2] Start Dashboard Only  
echo [3] Start Both (Backend + Dashboard)
echo [4] Open Dashboard in Browser
echo [5] Check Server Status
echo [6] Exit
echo.
echo ===============================================

set /p choice="Enter your choice (1-6): "

if "%choice%"=="1" goto start_backend
if "%choice%"=="2" goto start_dashboard
if "%choice%"=="3" goto start_both
if "%choice%"=="4" goto open_dashboard
if "%choice%"=="5" goto check_status
if "%choice%"=="6" goto exit
goto invalid_choice

:start_backend
echo.
echo Starting Backend Server...
echo ===============================================
start "App Manager Backend" cmd /k "cd /d E:\projects\pythonappmanager && start_app_manager.bat"
echo Backend server started in a new window
echo.
pause
goto menu

:start_dashboard
echo.
echo Starting Dashboard...
echo ===============================================
start "App Manager Dashboard" cmd /k "cd /d E:\projects\pythonappmanager\dashboard && start_dashboard.bat"
echo Dashboard started in a new window
echo.
pause
goto menu

:start_both
echo.
echo Starting Backend Server...
echo ===============================================
start "App Manager Backend" cmd /k "cd /d E:\projects\pythonappmanager && start_app_manager.bat"
timeout /t 3 /nobreak >nul
echo.
echo Starting Dashboard...
echo ===============================================
start "App Manager Dashboard" cmd /k "cd /d E:\projects\pythonappmanager\dashboard && start_dashboard.bat"
echo.
echo Both services started in separate windows
echo   - Backend: http://192.168.1.227:5000
echo   - Dashboard: http://localhost:8080/dashboard.html
echo.
pause
goto menu

:open_dashboard
echo.
echo Opening dashboard in browser...
start http://localhost:8080/dashboard.html
timeout /t 2 /nobreak >nul
goto menu

:check_status
echo.
echo Checking Server Status...
echo ===============================================
echo.
echo Testing Backend Server (192.168.1.227:5000)...
curl -s http://192.168.1.227:5000/api/health >nul 2>&1
if errorlevel 1 (
    echo ❌ Backend server is NOT running
) else (
    echo ✅ Backend server is running
)

echo.
echo Testing Dashboard Server (localhost:8080)...
curl -s http://localhost:8080/dashboard.html >nul 2>&1
if errorlevel 1 (
    echo ❌ Dashboard server is NOT running
) else (
    echo ✅ Dashboard server is running
)

echo.
echo Testing Application Status:
echo ---------------------------
curl -s http://192.168.1.227:5000/api/apps 2>nul | findstr "name" >nul 2>&1
if errorlevel 1 (
    echo ❌ Cannot retrieve app status (backend may be down)
) else (
    echo ✅ Apps API is responding
    echo.
    echo Current app status:
    curl -s http://192.168.1.227:5000/api/apps 2>nul
)

echo.
pause
goto menu

:invalid_choice
echo.
echo Invalid choice. Please enter a number between 1-6.
timeout /t 2 /nobreak >nul
goto menu

:exit
echo.
echo Goodbye!
timeout /t 1 /nobreak >nul
exit /b 0
```

# start_app_manager.bat

```bat
@echo off
setlocal enabledelayedexpansion

rem ============================================================================
rem Python App Manager Launcher
rem This script starts the Python App Manager backend server
rem ============================================================================

title Python App Manager Server

echo.
echo ===============================================
echo    Python App Manager Server Launcher
echo ===============================================
echo.

rem Set the path to your project directory
set PROJECT_DIR=E:\projects\pythonappmanager
set ENV_NAME=app_manager_env
set SERVER_SCRIPT=app_manager.py

rem Change to project directory
echo Changing to project directory: %PROJECT_DIR%
cd /d "%PROJECT_DIR%"
if errorlevel 1 (
    echo ERROR: Could not change to project directory: %PROJECT_DIR%
    echo Please check if the path exists and update the PROJECT_DIR variable in this script.
    pause
    exit /b 1
)

rem Check if the app_manager.py file exists
if not exist "%SERVER_SCRIPT%" (
    echo ERROR: %SERVER_SCRIPT% not found in %PROJECT_DIR%
    echo Please make sure the app_manager.py file is in the correct location.
    pause
    exit /b 1
)

rem Activate the conda/virtual environment
echo Activating environment: %ENV_NAME%
if exist "%ENV_NAME%\Scripts\activate.bat" (
    rem Virtual environment
    call "%ENV_NAME%\Scripts\activate.bat"
    if errorlevel 1 (
        echo ERROR: Failed to activate virtual environment
        goto :env_error
    )
    echo Virtual environment activated successfully
) else (
    rem Try conda environment
    call conda activate %ENV_NAME% 2>nul
    if errorlevel 1 (
        echo ERROR: Failed to activate conda environment
        goto :env_error
    )
    echo Conda environment activated successfully
)

rem Display environment info
echo.
echo Environment Information:
echo ------------------------
python --version 2>nul || echo Python not found in PATH
echo Environment: %ENV_NAME%
echo Project Directory: %PROJECT_DIR%
echo Server Script: %SERVER_SCRIPT%
echo.

rem Check required packages
echo Checking required packages...
python -c "import flask, flask_cors, psutil; print('✓ All required packages found')" 2>nul
if errorlevel 1 (
    echo WARNING: Some required packages may be missing
    echo Installing required packages...
    pip install Flask Flask-CORS psutil
    if errorlevel 1 (
        echo ERROR: Failed to install required packages
        pause
        exit /b 1
    )
)

echo.
echo ===============================================
echo    Starting Python App Manager Server
echo ===============================================
echo.
echo Server will be available at:
echo   - Local:   http://localhost:5000
echo   - Network: http://192.168.1.227:5000
echo.
echo Dashboard can be accessed at:
echo   - http://localhost:8080/dashboard.html (if dashboard server is running)
echo.
echo Press Ctrl+C to stop the server
echo ===============================================
echo.

rem Start the server
python %SERVER_SCRIPT%

rem Check exit code
if errorlevel 1 (
    echo.
    echo ERROR: Server exited with an error
    echo Check the error messages above
    pause
    exit /b 1
)

echo.
echo Server stopped normally
pause
exit /b 0

:env_error
echo.
echo ENVIRONMENT SETUP FAILED
echo ========================
echo.
echo The script could not activate the environment '%ENV_NAME%'.
echo.
echo Please check:
echo 1. Environment exists: %ENV_NAME%
echo 2. If using conda: conda env list
echo 3. If using venv: check if %PROJECT_DIR%\%ENV_NAME%\Scripts\activate.bat exists
echo.
echo To create the environment manually:
echo.
echo For conda:
echo   conda create -n %ENV_NAME% python=3.9
echo   conda activate %ENV_NAME%
echo   pip install Flask Flask-CORS psutil
echo.
echo For virtual environment:
echo   cd %PROJECT_DIR%
echo   python -m venv %ENV_NAME%
echo   %ENV_NAME%\Scripts\activate
echo   pip install Flask Flask-CORS psutil
echo.
pause
exit /b 1
```

# start_dashboard.bat

```bat
@echo off
setlocal enabledelayedexpansion

rem ============================================================================
rem Python App Manager Dashboard Launcher
rem This script starts the dashboard web server
rem ============================================================================

title Python App Manager Dashboard

echo.
echo ===============================================
echo    Python App Manager Dashboard Launcher
echo ===============================================
echo.

rem Set the path to your dashboard directory
set DASHBOARD_DIR=E:\projects\pythonappmanager\dashboard
set DASHBOARD_SCRIPT=serve_dashboard.py
set DASHBOARD_HTML=dashboard.html

rem Change to dashboard directory
echo Changing to dashboard directory: %DASHBOARD_DIR%
cd /d "%DASHBOARD_DIR%"
if errorlevel 1 (
    echo ERROR: Could not change to dashboard directory: %DASHBOARD_DIR%
    echo Please check if the path exists and update the DASHBOARD_DIR variable in this script.
    pause
    exit /b 1
)

rem Check if required files exist
if not exist "%DASHBOARD_SCRIPT%" (
    echo ERROR: %DASHBOARD_SCRIPT% not found in %DASHBOARD_DIR%
    echo Please make sure the serve_dashboard.py file is in the correct location.
    pause
    exit /b 1
)

if not exist "%DASHBOARD_HTML%" (
    echo ERROR: %DASHBOARD_HTML% not found in %DASHBOARD_DIR%
    echo Please make sure the dashboard.html file is in the correct location.
    pause
    exit /b 1
)

rem Display info
echo.
echo Dashboard Information:
echo ----------------------
python --version 2>nul || echo Python not found in PATH
echo Dashboard Directory: %DASHBOARD_DIR%
echo Dashboard Script: %DASHBOARD_SCRIPT%
echo Dashboard HTML: %DASHBOARD_HTML%
echo.

echo.
echo ===============================================
echo    Starting Dashboard Web Server
echo ===============================================
echo.
echo Dashboard will be available at:
echo   - Local:   http://localhost:8080/dashboard.html
echo   - Network: http://192.168.1.227:8080/dashboard.html
echo.
echo Make sure the App Manager backend is running at:
echo   - http://192.168.1.227:5000
echo.
echo The dashboard will open automatically in your browser
echo Press Ctrl+C to stop the dashboard server
echo ===============================================
echo.

rem Start the dashboard server
python %DASHBOARD_SCRIPT%

rem Check exit code
if errorlevel 1 (
    echo.
    echo ERROR: Dashboard server exited with an error
    echo Check the error messages above
    pause
    exit /b 1
)

echo.
echo Dashboard server stopped normally
pause
exit /b 0
```

