# NexRift Dashboard - New Features Update

## 🎯 **Implemented Features**

### 1. **⚙️ Settings System**
- **Settings Icon**: Added gear icon in header for easy access
- **Multiple Backend Servers**: Support for unlimited backend servers
- **Server Management**: Add, remove, and switch between servers
- **Persistent Storage**: Settings saved in Electron app storage
- **Server Validation**: Real-time server status checking

### 2. **🖥️ Computer Name Display**
- **Server Identification**: Shows hostname and platform info
- **Server Info Card**: Enhanced header with computer name display
- **Dynamic Updates**: Server info updates automatically
- **Tooltip Details**: Hover for full server information

### 3. **📊 Enhanced Resource Monitoring**
- **VRAM Usage**: GPU memory consumption per application
- **CPU Usage**: Real-time CPU percentage per app
- **RAM Usage**: Memory consumption in MB and percentage
- **Mini Resource Widgets**: Compact resource display in each app card
- **Color-coded Indicators**: Visual feedback for resource usage levels

### 4. **🔄 Independent Frontend Operation**
- **Standalone Dashboard**: Frontend runs independently of backend
- **Multiple Server Support**: Connect to any backend server
- **Graceful Fallback**: Works when backend is offline
- **Auto-reconnection**: Attempts to reconnect to servers

## 📱 **User Interface Updates**

### **Header Enhancements**
```
┌─ NexRift Dashboard ──────────────────────────────────┐
│ [Settings] [Refresh] [Server: DESKTOP-ABC (Online)] │
└──────────────────────────────────────────────────────┘
```

### **Settings Modal**
- **Backend Server List**: Visual list of all configured servers
- **Active Server Selection**: Radio buttons for server switching
- **Add New Server**: Form to add custom servers
- **Server Removal**: Delete unwanted servers
- **Real-time Status**: Shows which servers are online/offline

### **App Cards with Resources**
```
┌─ ComfyUI ──────────────── [Running] ─┐
│ Environment: comfyui-env             │
│ Port: 8188                           │
│ Uptime: 01:23:45                     │
│ Output: [📁 Open Folder]             │
│                                      │
│ ┌─ RESOURCE USAGE ─────────────────┐ │
│ │ CPU  [████████░░] 82%            │ │
│ │ RAM  [███░░░░░░░] 234MB          │ │
│ │ VRAM [██████░░░░] 1024MB         │ │
│ └──────────────────────────────────┘ │
│                                      │
│ [Start] [Stop]                       │
└──────────────────────────────────────┘
```

## 🔧 **Backend API Enhancements**

### **New Endpoints**
- **Enhanced Health Check**: `/api/health` now includes hostname, platform
- **System Metrics**: Improved with computer name and detailed info
- **App Resources**: Per-app CPU, RAM, VRAM monitoring

### **New Response Fields**
```json
{
  "hostname": "DESKTOP-ABC123",
  "platform": "Windows",
  "platform_version": "10.0.22631",
  "resources": {
    "cpu_percent": 15.3,
    "memory_mb": 234.7,
    "memory_percent": 2.1,
    "gpu_memory_mb": 512.0,
    "gpu_percent": 45.2
  }
}
```

## ⚙️ **Settings Configuration**

### **Default Server Configuration**
```json
{
  "servers": [
    {
      "id": "local",
      "name": "Local Server", 
      "address": "127.0.0.1:8000",
      "active": true
    },
    {
      "id": "network",
      "name": "Network Server",
      "address": "192.168.1.227:8000", 
      "active": false
    }
  ],
  "activeServerId": "local"
}
```

### **Adding New Servers**
1. Click **Settings** button in header
2. Scroll to "Add New Server" section
3. Enter server name and address (e.g., `192.168.1.100:8000`)
4. Click **Add Server**
5. Select new server as active
6. Click **Save Settings**

## 🚀 **Usage Instructions**

### **Switching Between Servers**
1. **Open Settings**: Click gear icon in header
2. **Select Server**: Choose radio button for desired server
3. **Save**: Click "Save Settings"
4. **Auto-refresh**: Dashboard automatically connects to new server

### **Monitoring Resources**
- **Per-App Monitoring**: Each running app shows mini resource widget
- **System Overview**: Left sidebar shows overall system metrics
- **Real-time Updates**: Resources update every 5 seconds
- **Color Coding**: Green < 50%, Yellow < 80%, Red ≥ 80%

### **Server Management**
- **Add Servers**: Use settings modal to add unlimited servers
- **Remove Servers**: Click trash icon next to unwanted servers
- **Server Status**: Header shows current server and online status
- **Automatic Detection**: Dashboard detects Electron vs web mode

## 🎯 **Benefits**

### **For Users**
- **Multi-Server Management**: Manage multiple computers from one dashboard
- **Resource Awareness**: See exactly what each app is consuming
- **Better Organization**: Clear server identification and status
- **Flexibility**: Use as web app or native desktop app

### **For Development**
- **Independent Frontend**: Dashboard works without backend dependency
- **Scalable Architecture**: Easy to add more servers and features
- **Persistent Settings**: User preferences saved automatically
- **Enhanced Monitoring**: Better visibility into system performance

Your NexRift dashboard is now a powerful multi-server application manager! 🎉