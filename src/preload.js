const { contextBridge, ipcRenderer } = require('electron');

// Expose protected methods that allow the renderer process to use
// the ipcRenderer without exposing the entire object
contextBridge.exposeInMainWorld('electronAPI', {
    // App info
    getAppPath: () => ipcRenderer.invoke('get-app-path'),
    
    // Dialog functions
    showErrorDialog: (title, content) => ipcRenderer.invoke('show-error-dialog', title, content),
    
    // File system functions
    openFolder: (folderPath) => ipcRenderer.invoke('open-folder', folderPath),
    selectFolder: () => ipcRenderer.invoke('select-folder'),
    
    // Settings management
    getSettings: () => ipcRenderer.invoke('get-settings'),
    saveSettings: (settings) => ipcRenderer.invoke('save-settings', settings),
    
    // Backend events
    onBackendError: (callback) => ipcRenderer.on('backend-error', callback),
    removeBackendErrorListener: (callback) => ipcRenderer.removeListener('backend-error', callback),
    
    // Platform info
    platform: process.platform
});

// Enhanced console for debugging
window.addEventListener('DOMContentLoaded', () => {
    console.log('NexRift Electron App - Preload script loaded');
    console.log('Platform:', process.platform);
    console.log('Electron version:', process.versions.electron);
    console.log('Chrome version:', process.versions.chrome);
    console.log('Node version:', process.versions.node);
});