const { app, BrowserWindow, Menu, Tray, shell, ipcMain, dialog } = require('electron');
const path = require('path');
const { spawn } = require('child_process');
const fs = require('fs');
const Store = require('electron-store');

// Initialize settings store
const store = new Store({
    defaults: {
        servers: [
            {
                id: 'local',
                name: 'Local Server',
                address: '127.0.0.1:8000',
                active: true,
                autoConnect: true
            },
            {
                id: 'network',
                name: 'Network Server',
                address: '192.168.1.227:8000',
                active: false,
                autoConnect: false
            }
        ],
        activeServerId: 'local',
        theme: 'dark',
        autoStart: true
    }
});

// Keep a global reference of the window object
let mainWindow;
let tray = null;
let backendProcess = null;
const isDev = process.argv.includes('--dev');

// Backend configuration
const BACKEND_PORT = 8000;
const DASHBOARD_PORT = 8080;
const SERVER_HOST = '127.0.0.1';

function createWindow() {
    // Create the browser window
    mainWindow = new BrowserWindow({
        width: 1400,
        height: 900,
        minWidth: 1200,
        minHeight: 700,
        webPreferences: {
            nodeIntegration: false,
            contextIsolation: true,
            enableRemoteModule: false,
            allowRunningInsecureContent: false,
            experimentalFeatures: false,
            webSecurity: true,
            preload: path.join(__dirname, 'preload.js')
        },
        icon: path.join(__dirname, '../assets/icon.png'),
        titleBarStyle: 'default',
        show: false // Don't show until ready
    });

    // Remove default menu
    Menu.setApplicationMenu(null);

    // Load the dashboard
    // Windows path fix: ensure we're using the correct path separators
    const dashboardPath = path.resolve(__dirname, '../dashboard/dashboard.html');
    console.log('Attempting to load dashboard from:', dashboardPath);
    console.log('Current working directory:', process.cwd());
    console.log('__dirname:', __dirname);
    console.log('Platform:', process.platform);
    
    // Check if file exists
    const fs = require('fs');
    if (fs.existsSync(dashboardPath)) {
        console.log('✓ Dashboard file found, loading...');
        mainWindow.loadFile(dashboardPath);
    } else {
        console.error('❌ Dashboard file not found at:', dashboardPath);
        
        // Try alternative paths
        const altPaths = [
            path.resolve(process.cwd(), 'dashboard', 'dashboard.html'),
            path.resolve(__dirname, '..', '..', 'dashboard', 'dashboard.html'),
            path.resolve(__dirname, 'dashboard', 'dashboard.html'),
            path.resolve(process.cwd(), 'dashboard.html'), // In case it's in root
        ];
        
        let loaded = false;
        for (const altPath of altPaths) {
            console.log('Trying alternative path:', altPath);
            if (fs.existsSync(altPath)) {
                console.log('✓ Found dashboard at:', altPath);
                mainWindow.loadFile(altPath);
                loaded = true;
                break;
            }
        }
        
        if (!loaded) {
            console.error('❌ Could not find dashboard.html in any expected location');
            // Load a simple error page
            mainWindow.loadURL('data:text/html,<h1>Dashboard not found</h1><p>Could not locate dashboard/dashboard.html</p><p>Expected at: ' + dashboardPath + '</p>');
        }
    }
    
    // Open DevTools for debugging in development
    if (isDev) {
        mainWindow.webContents.openDevTools();
    }

    // Show window when ready
    mainWindow.once('ready-to-show', () => {
        mainWindow.show();
        
        // Focus window
        if (process.platform === 'win32') {
            mainWindow.setSkipTaskbar(false);
        }
    });

    // Handle window closed
    mainWindow.on('closed', () => {
        mainWindow = null;
    });

    // Debug: Log when page fails to load
    mainWindow.webContents.on('did-fail-load', (event, errorCode, errorDescription, validatedURL) => {
        console.error('Failed to load page:', {
            errorCode,
            errorDescription,
            validatedURL
        });
    });

    // Debug: Log when page finishes loading
    mainWindow.webContents.on('did-finish-load', () => {
        console.log('Page loaded successfully');
    });

    // Debug: Log console messages from renderer
    mainWindow.webContents.on('console-message', (event, level, message, line, sourceId) => {
        console.log(`Renderer console.${level}: ${message}`);
    });

    // Prevent navigation away from the app
    mainWindow.webContents.on('will-navigate', (event, navigationUrl) => {
        const parsedUrl = new URL(navigationUrl);
        
        // Allow navigation within our app
        if (parsedUrl.hostname === SERVER_HOST || parsedUrl.hostname === 'localhost') {
            return;
        }
        
        // Open external links in default browser
        event.preventDefault();
        shell.openExternal(navigationUrl);
    });

    // Handle new window requests (open in external browser)
    mainWindow.webContents.setWindowOpenHandler(({ url }) => {
        shell.openExternal(url);
        return { action: 'deny' };
    });
}

function createTray() {
    const trayIconPath = path.join(__dirname, '../assets/tray-icon.png');
    
    // Create tray icon (use a simple icon if file doesn't exist)
    try {
        tray = new Tray(trayIconPath);
    } catch (error) {
        // Fallback: create a simple tray without icon
        console.log('Tray icon not found, creating without icon');
        return;
    }

    const contextMenu = Menu.buildFromTemplate([
        {
            label: 'Show NexRift',
            click: () => {
                if (mainWindow) {
                    mainWindow.show();
                    mainWindow.focus();
                }
            }
        },
        {
            label: 'Open Dashboard',
            click: () => {
                shell.openExternal(`http://${SERVER_HOST}:${DASHBOARD_PORT}/dashboard.html`);
            }
        },
        { type: 'separator' },
        {
            label: 'Restart Backend',
            click: () => {
                restartBackend();
            }
        },
        { type: 'separator' },
        {
            label: 'Quit',
            click: () => {
                app.quit();
            }
        }
    ]);

    tray.setToolTip('NexRift - Python App Manager');
    tray.setContextMenu(contextMenu);

    // Show/hide window on tray click
    tray.on('click', () => {
        if (mainWindow) {
            if (mainWindow.isVisible()) {
                mainWindow.hide();
            } else {
                mainWindow.show();
                mainWindow.focus();
            }
        }
    });
}

function startBackend() {
    if (backendProcess) {
        return;
    }

    console.log('Starting Python backend...');

    let pythonPath = 'python';
    let scriptPath = path.join(__dirname, '../app_manager.py');

    // In production, look for bundled Python or system Python
    if (!isDev) {
        // Try to find Python in various locations
        const possiblePaths = [
            path.join(process.resourcesPath, 'backend', 'app_manager.py'),
            path.join(__dirname, '../app_manager.py')
        ];

        for (const possiblePath of possiblePaths) {
            if (fs.existsSync(possiblePath)) {
                scriptPath = possiblePath;
                break;
            }
        }
    }

    console.log(`Starting backend: ${pythonPath} ${scriptPath}`);

    backendProcess = spawn(pythonPath, [scriptPath], {
        cwd: path.dirname(scriptPath),
        stdio: ['pipe', 'pipe', 'pipe']
    });

    backendProcess.stdout.on('data', (data) => {
        console.log(`Backend stdout: ${data}`);
    });

    backendProcess.stderr.on('data', (data) => {
        console.error(`Backend stderr: ${data}`);
    });

    backendProcess.on('close', (code) => {
        console.log(`Backend process exited with code ${code}`);
        backendProcess = null;
        
        // Notify main window if backend crashes
        if (mainWindow && code !== 0) {
            mainWindow.webContents.send('backend-error', `Backend exited with code ${code}`);
        }
    });

    backendProcess.on('error', (error) => {
        console.error('Failed to start backend:', error);
        backendProcess = null;
        
        if (mainWindow) {
            mainWindow.webContents.send('backend-error', `Failed to start backend: ${error.message}`);
        }
    });
}

function stopBackend() {
    if (backendProcess) {
        console.log('Stopping Python backend...');
        backendProcess.kill('SIGTERM');
        
        // Force kill after 5 seconds
        setTimeout(() => {
            if (backendProcess) {
                backendProcess.kill('SIGKILL');
            }
        }, 5000);
        
        backendProcess = null;
    }
}

function restartBackend() {
    stopBackend();
    setTimeout(() => {
        startBackend();
    }, 1000);
}

// App event handlers
app.whenReady().then(() => {
    createWindow();
    createTray();
    
    // Start backend unless in dev mode
    if (!isDev) {
        startBackend();
    }

    app.on('activate', () => {
        if (BrowserWindow.getAllWindows().length === 0) {
            createWindow();
        }
    });
});

app.on('window-all-closed', () => {
    // On macOS, keep app running even when all windows are closed
    if (process.platform !== 'darwin') {
        stopBackend();
        app.quit();
    }
});

app.on('before-quit', () => {
    stopBackend();
});

// IPC handlers
ipcMain.handle('get-app-path', () => {
    return app.getAppPath();
});

ipcMain.handle('show-error-dialog', async (event, title, content) => {
    const result = await dialog.showMessageBox(mainWindow, {
        type: 'error',
        title: title,
        message: content,
        buttons: ['OK']
    });
    return result;
});

ipcMain.handle('open-folder', async (event, folderPath) => {
    shell.openPath(folderPath);
});

ipcMain.handle('select-folder', async (event) => {
    const result = await dialog.showOpenDialog(mainWindow, {
        properties: ['openDirectory'],
        title: 'Select App Folder'
    });
    
    if (!result.canceled && result.filePaths.length > 0) {
        return result.filePaths[0];
    }
    return null;
});

ipcMain.handle('get-settings', () => {
    return store.store;
});

ipcMain.handle('save-settings', (event, settings) => {
    store.store = settings;
    return true;
});

// Handle certificate errors (for development)
app.on('certificate-error', (event, webContents, url, error, certificate, callback) => {
    if (isDev) {
        // In development, ignore certificate errors
        event.preventDefault();
        callback(true);
    } else {
        // In production, use default behavior
        callback(false);
    }
});

console.log('NexRift Electron app starting...');
console.log('Development mode:', isDev);