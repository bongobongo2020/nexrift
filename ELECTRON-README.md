# NexRift Electron App

Convert your NexRift web dashboard into a native Windows 11 application.

## 🚀 Quick Start

### Prerequisites
- **Node.js 18+** - Download from [nodejs.org](https://nodejs.org/)
- **Python 3.8+** - Your existing Python setup
- **Git** (optional)

### Option 1: Development Mode (Recommended for testing)
```bash
# Install dependencies
npm install

# Start in development mode (connects to existing backend)
npm run dev
# OR use the batch file:
./electron-dev.bat
```

### Option 2: Build Standalone App
```bash
# Build Windows installer
npm run build-win
# OR use the batch file:
./build-electron.bat
```

## 📱 App Features

### Native Windows Integration
- **System Tray**: Minimize to tray, right-click menu
- **Native File Opening**: Folder links open in Windows Explorer
- **Auto-start Backend**: Python backend starts automatically
- **Windows Notifications**: Error alerts and status updates

### Enhanced Dashboard
- **Auto-detection**: Automatically connects to local or network backend
- **Resource Monitoring**: Real-time per-app CPU, RAM, GPU usage
- **Output Folders**: Native folder opening for app outputs
- **Responsive Design**: Optimized for desktop window

## 🏗️ Architecture

### Development Mode
```
Electron App → Your existing Python backend (192.168.1.227:8000)
```

### Production Mode  
```
Electron App → Bundled Python backend (127.0.0.1:8000)
```

## 📁 Project Structure

```
nexrift/
├── src/
│   ├── main.js          # Main Electron process
│   └── preload.js       # Renderer-main bridge
├── dashboard/           # Your existing dashboard
├── app_manager.py       # Your existing backend
├── package.json         # Electron config
├── electron-dev.bat     # Development launcher
├── build-electron.bat   # Build script
└── dist/               # Built app output
```

## ⚙️ Configuration

### Backend Integration
The app automatically:
- Starts Python backend on launch
- Handles backend crashes/restarts
- Routes dashboard to correct endpoint

### Build Customization
Edit `package.json` build section:
```json
{
  "build": {
    "appId": "com.nexrift.app",
    "productName": "NexRift",
    "win": {
      "target": "nsis",
      "icon": "assets/icon.ico"
    }
  }
}
```

## 🎯 Getting Icons
Create these files in `assets/`:
- `icon.ico` - Main app icon (256x256)
- `icon.png` - Window icon (512x512)  
- `tray-icon.png` - System tray icon (16x16)

Use tools like [ICO Convert](https://icoconvert.com/) to create .ico files.

## 🐛 Troubleshooting

### "Backend failed to start"
1. Check Python is in PATH
2. Verify `app_manager.py` location
3. Install dependencies: `pip install -r requirements.txt`

### "Cannot connect to backend"
1. Check if port 8000 is available
2. Disable firewall/antivirus temporarily
3. Try development mode first

### Build fails
1. Update Node.js to latest LTS
2. Clear cache: `npm cache clean --force`
3. Delete `node_modules` and reinstall

## 🚀 Distribution

### Installer Output
After building, find in `dist/`:
- `NexRift-1.0.0-Setup.exe` - Windows installer
- `win-unpacked/` - Portable app folder

### Sharing Your App
1. Upload installer to GitHub releases
2. Users download and run installer
3. App installs to Program Files
4. Creates desktop shortcut and start menu entry

## 🔧 Advanced Features

### Auto-updater (Future)
```javascript
// Add to main.js
const { autoUpdater } = require('electron-updater');
autoUpdater.checkForUpdatesAndNotify();
```

### Custom Protocols
```javascript
// Register nexrift:// protocol
app.setAsDefaultProtocolClient('nexrift');
```

### Windows Store Packaging
```bash
# Convert to APPX
npm install electron-builder-appx
npm run build -- --win --appx
```

## 📊 Performance

### App Size
- **Installer**: ~150MB (includes Electron runtime)
- **Installed**: ~200MB 
- **Memory Usage**: ~100MB (typical for Electron apps)

### Startup Time
- **Cold Start**: 2-3 seconds
- **Backend Start**: 1-2 seconds
- **Dashboard Load**: <1 second

## 🛠️ Development Tips

### Debug Mode
```bash
npm run dev
# Opens DevTools automatically
```

### Backend Logs
Check console for Python backend output:
```
Backend stdout: Starting Python App Management Server...
Backend stdout: * Running on http://0.0.0.0:8000
```

### Hot Reload
Modify dashboard files and refresh (Ctrl+R) to see changes.

## 🎯 Next Steps

1. **Test Development Mode**: Use `electron-dev.bat`
2. **Create Icons**: Add proper app icons
3. **Build Installer**: Use `build-electron.bat`
4. **Test Installation**: Install and verify functionality
5. **Distribute**: Share installer with users

Your NexRift dashboard is now a proper Windows 11 application! 🎉