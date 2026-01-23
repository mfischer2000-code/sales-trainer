const { contextBridge, ipcRenderer } = require('electron');

// Expose geschützte APIs an den Renderer-Prozess
contextBridge.exposeInMainWorld('electronAPI', {
  // Plattform-Info
  platform: process.platform,

  // Prüfe ob wir in Electron laufen
  isElectron: true
});
