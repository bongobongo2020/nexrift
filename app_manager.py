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

class SystemMonitor:
    def __init__(self):
        self.gpu_available = self._check_gpu_availability()
        
    def _check_gpu_availability(self):
        """Check if GPU monitoring is available"""
        try:
            # Try importing pynvml first (most accurate)
            import pynvml
            pynvml.nvmlInit()
            return True
        except ImportError:
            # Try nvidia-smi command as fallback
            try:
                subprocess.run(['nvidia-smi'], capture_output=True, check=True)
                return True
            except (subprocess.CalledProcessError, FileNotFoundError):
                return False
        except Exception:
            return False
    
    def _format_bytes(self, bytes_value):
        """Convert bytes to human readable format"""
        for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
            if bytes_value < 1024.0:
                return f"{bytes_value:.1f} {unit}"
            bytes_value /= 1024.0
        return f"{bytes_value:.1f} PB"
    
    def _get_gpu_info_pynvml(self):
        """Get GPU info using pynvml library"""
        try:
            import pynvml
            pynvml.nvmlInit()
            device_count = pynvml.nvmlDeviceGetCount()
            
            if device_count == 0:
                return None
                
            # Get info for first GPU
            handle = pynvml.nvmlDeviceGetHandleByIndex(0)
            name = pynvml.nvmlDeviceGetName(handle).decode('utf-8')
            
            # GPU utilization
            utilization = pynvml.nvmlDeviceGetUtilizationRates(handle)
            gpu_util = utilization.gpu
            
            # Memory info
            memory_info = pynvml.nvmlDeviceGetMemoryInfo(handle)
            memory_used = memory_info.used
            memory_total = memory_info.total
            memory_percent = (memory_used / memory_total) * 100
            
            # Temperature
            try:
                temperature = pynvml.nvmlDeviceGetTemperature(handle, pynvml.NVML_TEMPERATURE_GPU)
            except:
                temperature = None
                
            return {
                'name': name,
                'utilization': gpu_util,
                'memory_used': memory_used,
                'memory_total': memory_total,
                'memory_percent': memory_percent,
                'temperature': temperature
            }
        except Exception as e:
            logger.debug(f"pynvml GPU info failed: {e}")
            return None
    
    def _get_gpu_info_nvidia_smi(self):
        """Get GPU info using nvidia-smi command"""
        try:
            result = subprocess.run([
                'nvidia-smi', 
                '--query-gpu=name,utilization.gpu,memory.used,memory.total,temperature.gpu',
                '--format=csv,noheader,nounits'
            ], capture_output=True, text=True, check=True)
            
            line = result.stdout.strip().split('\n')[0]
            parts = [p.strip() for p in line.split(',')]
            
            if len(parts) >= 5:
                name = parts[0]
                gpu_util = float(parts[1])
                memory_used = float(parts[2]) * 1024 * 1024  # Convert MB to bytes
                memory_total = float(parts[3]) * 1024 * 1024  # Convert MB to bytes
                memory_percent = (memory_used / memory_total) * 100
                temperature = float(parts[4]) if parts[4] != '[Not Supported]' else None
                
                return {
                    'name': name,
                    'utilization': gpu_util,
                    'memory_used': memory_used,
                    'memory_total': memory_total,
                    'memory_percent': memory_percent,
                    'temperature': temperature
                }
        except Exception as e:
            logger.debug(f"nvidia-smi GPU info failed: {e}")
            return None
        
        return None
    
    def get_system_metrics(self):
        """Get comprehensive system metrics"""
        try:
            # CPU metrics
            cpu_percent = psutil.cpu_percent(interval=0.1)
            cpu_count = psutil.cpu_count()
            
            # Memory metrics
            memory = psutil.virtual_memory()
            
            # Disk metrics (using the main drive)
            disk_path = '/' if os.name != 'nt' else 'C:\\'
            disk = psutil.disk_usage(disk_path)
            
            # Process count
            process_count = len(psutil.pids())
            
            # GPU metrics
            gpu_info = None
            if self.gpu_available:
                # Try pynvml first, fallback to nvidia-smi
                gpu_info = self._get_gpu_info_pynvml()
                if gpu_info is None:
                    gpu_info = self._get_gpu_info_nvidia_smi()
            
            metrics = {
                'cpu': {
                    'percent': round(cpu_percent, 1),
                    'cores': cpu_count,
                    'color': self._get_usage_color(cpu_percent)
                },
                'memory': {
                    'used': memory.used,
                    'total': memory.total,
                    'percent': round(memory.percent, 1),
                    'used_formatted': self._format_bytes(memory.used),
                    'total_formatted': self._format_bytes(memory.total),
                    'color': self._get_usage_color(memory.percent)
                },
                'disk': {
                    'used': disk.used,
                    'total': disk.total,
                    'percent': round((disk.used / disk.total) * 100, 1),
                    'used_formatted': self._format_bytes(disk.used),
                    'total_formatted': self._format_bytes(disk.total),
                    'color': self._get_usage_color((disk.used / disk.total) * 100)
                },
                'processes': {
                    'total': process_count
                },
                'timestamp': datetime.now().isoformat()
            }
            
            # Add GPU metrics if available
            if gpu_info:
                metrics['gpu'] = {
                    'name': gpu_info['name'],
                    'utilization': round(gpu_info['utilization'], 1),
                    'memory_used': gpu_info['memory_used'],
                    'memory_total': gpu_info['memory_total'],
                    'memory_percent': round(gpu_info['memory_percent'], 1),
                    'memory_used_formatted': self._format_bytes(gpu_info['memory_used']),
                    'memory_total_formatted': self._format_bytes(gpu_info['memory_total']),
                    'temperature': gpu_info['temperature'],
                    'utilization_color': self._get_usage_color(gpu_info['utilization']),
                    'memory_color': self._get_usage_color(gpu_info['memory_percent'])
                }
            
            return metrics
            
        except Exception as e:
            logger.error(f"Failed to get system metrics: {e}")
            return {
                'error': str(e),
                'timestamp': datetime.now().isoformat()
            }
    
    def _get_usage_color(self, percent):
        """Get color based on usage percentage"""
        if percent < 50:
            return 'green'
        elif percent < 80:
            return 'yellow'
        else:
            return 'red'

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

# Initialize the app manager and system monitor
app_manager = AppManager()
system_monitor = SystemMonitor()

# API Routes
@app.route('/api/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'server': '192.168.1.227'
    })

@app.route('/api/system/metrics', methods=['GET'])
def get_system_metrics():
    """Get real-time system metrics"""
    metrics = system_monitor.get_system_metrics()
    
    # Add running apps count
    running_apps = len([app for app in app_manager.get_all_apps_status() if app['status'] == 'running'])
    metrics['processes']['running_apps'] = running_apps
    
    return jsonify(metrics)

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
    logger.info("Starting Python App Management Server with System Monitoring...")
    logger.info("Configured applications:")
    for app_id, config in app_configs.items():
        logger.info(f"  - {config['name']} ({app_id}): {config['path']}")
    
    # Check GPU availability
    if system_monitor.gpu_available:
        logger.info("GPU monitoring enabled")
    else:
        logger.info("GPU monitoring not available (install pynvml for detailed GPU metrics)")
    
    # Run the server
    app.run(
        host='0.0.0.0',  # Listen on all interfaces
        port=8000,
        debug=False,
        threaded=True
    )