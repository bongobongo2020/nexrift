const { app, BrowserWindow, Menu } = require('electron');
const path = require('path');

let mainWindow;
const isDev = process.argv.includes('--dev');

function createWindow() {
    console.log('Creating Electron window...');
    console.log('isDev:', isDev);
    console.log('__dirname:', __dirname);
    
    mainWindow = new BrowserWindow({
        width: 1200,
        height: 800,
        webPreferences: {
            nodeIntegration: false,
            contextIsolation: true,
            preload: path.join(__dirname, 'preload.js')
        },
        show: false
    });

    // Remove menu for cleaner look
    Menu.setApplicationMenu(null);

    // Load test file first
    const testFile = path.join(__dirname, '../test-electron.html');
    console.log('Loading test file:', testFile);
    
    mainWindow.loadFile(testFile);

    // Always show DevTools for debugging
    mainWindow.webContents.openDevTools();

    mainWindow.once('ready-to-show', () => {
        console.log('Window ready to show');
        mainWindow.show();
    });

    mainWindow.on('closed', () => {
        mainWindow = null;
    });

    // Debug events
    mainWindow.webContents.on('did-fail-load', (event, errorCode, errorDescription, validatedURL) => {
        console.error('Failed to load:', { errorCode, errorDescription, validatedURL });
    });

    mainWindow.webContents.on('did-finish-load', () => {
        console.log('Page loaded successfully!');
    });

    mainWindow.webContents.on('console-message', (event, level, message) => {
        console.log(`Renderer: ${message}`);
    });
}

app.whenReady().then(() => {
    console.log('Electron app ready');
    createWindow();
});

app.on('window-all-closed', () => {
    if (process.platform !== 'darwin') {
        app.quit();
    }
});

app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
        createWindow();
    }
});

console.log('Electron main process starting...');